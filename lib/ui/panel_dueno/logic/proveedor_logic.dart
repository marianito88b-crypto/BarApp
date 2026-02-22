import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/proveedores/modals/pago_proveedor_modal.dart';
import '../widgets/proveedores/modals/edit_proveedor_modal.dart';

/// Mixin que contiene la lógica de negocio para la gestión de proveedores
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Getter: provId
/// - Getter: nombreProveedor
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin ProveedorLogicMixin<T extends StatefulWidget> on State<T> {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Getter requerido para obtener el ID del proveedor
  String get provId;

  /// Getter requerido para obtener el nombre del proveedor
  String get nombreProveedor;

  /// Variable de estado para controlar el loading
  bool isLoading = false;

  /// Setter para actualizar el estado de loading
  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        isLoading = value;
      });
    }
  }

  /// Abre WhatsApp con el número formateado del proveedor
  ///
  /// Formatea el número agregando código de país si es necesario (Argentina: 549)
  Future<void> abrirWhatsApp(String numero) async {
    // Limpiamos el número: debe ser solo números y con código de país
    var cleanNumber = numero.replaceAll(RegExp(r'[^0-9]'), '');

    // Si el número no tiene código de país, agregamos el de Argentina (549)
    if (!cleanNumber.startsWith('54')) {
      cleanNumber = "549$cleanNumber";
    }

    // Construimos el link universal wa.me
    var url = "https://wa.me/$cleanNumber?text=${Uri.encodeComponent("Hola, te contacto desde el Bar.")}";

    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("Error al abrir WhatsApp: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No se pudo abrir WhatsApp o no está instalado"),
          ),
        );
      }
    }
  }

  /// Muestra el diálogo para registrar un pago parcial
  void showPagoParcialDialog() {
    if (!mounted) return;
    PagoProveedorModal.show(
      context,
      placeId: placeId,
      provId: provId,
      nombreProveedor: nombreProveedor,
      mixin: this,
    );
  }

  /// Liquida toda la deuda del proveedor usando Batch atómico
  Future<void> liquidarDeuda() async {
    String metodoPago = 'efectivo';

    // 1. Preguntamos confirmación Y método de pago
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              "¿Saldar cuenta total?",
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Se registrará la salida de dinero HOY y se marcarán todos los pendientes como pagados.",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Método de Pago:",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                DropdownButton<String>(
                  value: metodoPago,
                  dropdownColor: const Color(0xFF252525),
                  isExpanded: true,
                  underline: Container(height: 1, color: Colors.green),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  items: ['efectivo', 'digital'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setStateDialog(() => metodoPago = val!);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "CANCELAR",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("CONFIRMAR PAGO"),
              ),
            ],
          );
        },
      ),
    );

    if (confirm != true) return;

    setLoading(true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final placeRef =
          FirebaseFirestore.instance.collection('places').doc(placeId);

      // 2. Buscamos los gastos pendientes de este proveedor
      final gastosSnap = await placeRef
          .collection('gastos')
          .where('proveedorId', isEqualTo: provId)
          .where('estado', isEqualTo: 'pendiente')
          .get();

      if (gastosSnap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay deudas pendientes para saldar."),
            ),
          );
        }
        return;
      }

      // 3. Transformamos cada deuda en un GASTO REAL DE HOY
      for (var doc in gastosSnap.docs) {
        batch.update(doc.reference, {
          'estado': 'pagado',
          'metodoPago': metodoPago,
          'fecha': FieldValue.serverTimestamp(),
          'fechaOriginal': doc['fecha'],
        });
      }

      // 4. Reseteamos saldo del proveedor a 0
      batch.update(placeRef.collection('proveedores').doc(provId), {
        'saldoPendiente': 0.0,
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "💰 Cuenta saldada. Se registraron ${gastosSnap.docs.length} movimientos en caja.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al liquidar deuda: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al procesar el pago"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Sube una foto del remito a Firebase Storage (compatible con Web y Mobile)
  ///
  /// [gastoId]: ID del gasto al que se le asociará la foto
  Future<void> subirFotoRemito(String gastoId) async {
    final picker = ImagePicker();
    // En Web, Source.camera abre el selector de archivos
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    if (image == null) return;

    setLoading(true);
    try {
      // Leemos los bytes (compatible con Web y Mobile)
      Uint8List fileBytes = await image.readAsBytes();
      String fileName = "remito_$gastoId.jpg";

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('places/$placeId/remitos/$fileName');

      // Usamos putData para compatibilidad Web/Mobile
      UploadTask uploadTask = ref.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('gastos')
          .doc(gastoId)
          .update({'fotoUrl': url});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Foto del remito guardada"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error subiendo foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al subir foto: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Muestra el diálogo para editar los datos del proveedor
  Future<void> editProveedor() async {
    if (!mounted) return;
    await EditProveedorModal.show(
      context,
      placeId: placeId,
      provId: provId,
      mixin: this,
    );
  }

  /// Muestra el diálogo de confirmación y elimina el proveedor
  void deleteProveedor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "¿Eliminar proveedor?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Esta acción no se puede deshacer.",
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              setLoading(true);
              try {
                await FirebaseFirestore.instance
                    .collection('places')
                    .doc(placeId)
                    .collection('proveedores')
                    .doc(provId)
                    .delete();

                if (!context.mounted) return;
                Navigator.pop(context); // Cierra diálogo
                Navigator.pop(context); // Vuelve a la lista
              } catch (e) {
                debugPrint("Error eliminando proveedor: $e");
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                setLoading(false);
              }
            },
            child: const Text(
              "ELIMINAR",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

}
