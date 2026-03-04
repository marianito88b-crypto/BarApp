import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Mixin que contiene la lógica de negocio para la configuración del local
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Métodos: setState, mounted (de State)
/// - Propiedad: context (de State)
mixin ConfigLogicMixin<T extends StatefulWidget> on State<T> {
  // Controladores de texto
  late final TextEditingController nombreController;
  late final TextEditingController direccionController;
  late final TextEditingController descripcionController;
  late final TextEditingController cbuController;
  late final TextEditingController aliasController;
  late final TextEditingController bancoController;
  late final TextEditingController titularController;
  late final TextEditingController envioBaseController;
  late final TextEditingController envioKmExtraController;

  // Estado de carga de datos
  bool _dataLoaded = false;

  // Estado de ubicación GPS
  double? latitudBar;
  double? longitudBar;
  bool obteniendoUbicacion = false;

  // Estado de doble turno
  bool tieneDobleTurno = false;
  String horarioApertura2 = '';
  String horarioCierre2 = '';

  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Inicializa los controladores y carga los datos desde Firestore
  void initConfigLogic(Map<String, dynamic> data) {
    // Inicializar controladores solo una vez
    if (!_dataLoaded) {
      nombreController = TextEditingController();
      direccionController = TextEditingController();
      descripcionController = TextEditingController();
      cbuController = TextEditingController();
      aliasController = TextEditingController();
      bancoController = TextEditingController();
      titularController = TextEditingController();
      envioBaseController = TextEditingController();
      envioKmExtraController = TextEditingController();

      // Cargar datos iniciales desde Firestore
      nombreController.text = data['nombre'] ?? data['name'] ?? '';
      direccionController.text = data['direccion'] ?? '';
      descripcionController.text = data['descripcion'] ?? '';
      cbuController.text = data['cbu'] ?? '';
      aliasController.text = data['alias'] ?? '';
      bancoController.text = data['banco'] ?? '';
      titularController.text = data['titularCuenta'] ?? '';
      envioBaseController.text = (data['envioCostoBase'] ?? 2000).toString();
      envioKmExtraController.text = (data['envioCostoKmExtra'] ?? 500).toString();

      latitudBar = (data['lat'] as num?)?.toDouble();
      longitudBar = (data['lng'] as num?)?.toDouble();

      // Cargar datos de doble turno
      tieneDobleTurno = data['tieneDobleTurno'] ?? false;
      horarioApertura2 = data['horarioApertura2'] ?? '';
      horarioCierre2 = data['horarioCierre2'] ?? '';

      _dataLoaded = true;
    } else {
      // Actualizar valores de doble turno en cada rebuild si cambian en Firestore
      // Usamos addPostFrameCallback para evitar setState durante build
      final nuevoDoble = data['tieneDobleTurno'] ?? false;
      final nuevoAp2 = data['horarioApertura2'] ?? '';
      final nuevoCi2 = data['horarioCierre2'] ?? '';
      if (nuevoDoble != tieneDobleTurno ||
          nuevoAp2 != horarioApertura2 ||
          nuevoCi2 != horarioCierre2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              tieneDobleTurno = nuevoDoble;
              horarioApertura2 = nuevoAp2;
              horarioCierre2 = nuevoCi2;
            });
          }
        });
      }
    }
  }

  /// Actualiza datos en Firestore en tiempo real
  Future<void> updateRealTime(Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection("places")
          .doc(placeId)
          .update(data);
    } catch (e) {
      debugPrint('❌ Error actualizando config: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  /// Guarda los datos generales del negocio
  Future<void> guardarDatosGenerales() async {
    try {
      final nombre = nombreController.text.trim();
      await updateRealTime({
        'nombre': nombre,
        'name': nombre, // 👈 SAFETY CHECK: Guardamos ambos
        'descripcion': descripcionController.text.trim(),
        'direccion': direccionController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Info general actualizada"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      // updateRealTime ya muestra el error
    }
  }

  /// Guarda la ubicación GPS del local
  Future<void> guardarUbicacionGPS() async {
    setState(() => obteniendoUbicacion = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Permisos de ubicación denegados";
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await updateRealTime({
        'lat': position.latitude,
        'lng': position.longitude,
      });

      if (mounted) {
        setState(() {
          latitudBar = position.latitude;
          longitudBar = position.longitude;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📍 Ubicación del local guardada"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error GPS: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => obteniendoUbicacion = false);
      }
    }
  }

  /// Guarda los datos bancarios para transferencias
  Future<void> guardarDatosBancarios() async {
    try {
      await updateRealTime({
        'cbu': cbuController.text.trim(),
        'alias': aliasController.text.trim(),
        'banco': bancoController.text.trim(),
        'titularCuenta': titularController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Datos bancarios actualizados"),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (_) {
      // updateRealTime ya muestra el error
    }
  }

  /// Guarda los costos de envío
  Future<void> guardarCostosEnvio() async {
    try {
      await updateRealTime({
        'envioCostoBase': double.tryParse(envioBaseController.text) ?? 2000,
        'envioCostoKmExtra': double.tryParse(envioKmExtraController.text) ?? 500,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tarifas de envío actualizadas"),
            backgroundColor: Colors.purpleAccent,
          ),
        );
      }
    } catch (_) {
      // updateRealTime ya muestra el error
    }
  }

  /// Muestra un diálogo para editar un campo de texto
  void editarCampoTexto(
    String titulo,
    String valorActual,
    String fieldKey,
    TextInputType teType,
  ) {
    final ctrl = TextEditingController(text: valorActual);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          titulo,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: teType,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Escribe aquí...",
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              updateRealTime({fieldKey: ctrl.text.trim()});
              Navigator.pop(ctx);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  /// Muestra un selector de hora y guarda el valor
  /// 
  /// [fieldKey]: Clave del campo en Firestore (ej: 'horarioApertura', 'horarioCierre', 'horarioApertura2', 'horarioCierre2')
  /// [horaInicial]: Hora inicial a mostrar en el selector (opcional, intenta leer desde el estado o usa hora actual)
  /// [valorActual]: Valor actual del campo en formato 'HH:mm' (opcional, para campos que no están en el estado)
  Future<void> seleccionarHora(
    String fieldKey, {
    TimeOfDay? horaInicial,
    String? valorActual,
  }) async {
    // Determinar hora inicial basada en el valor actual si existe
    TimeOfDay initialTime = horaInicial ?? TimeOfDay.now();
    
    // Intentar parsear desde valorActual si se proporciona
    if (valorActual != null && valorActual.isNotEmpty) {
      final parts = valorActual.split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          initialTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    } else {
      // Si no hay valorActual, intentar leer desde el estado local
      String? valorDesdeEstado;
      if (fieldKey == 'horarioApertura2') {
        valorDesdeEstado = horarioApertura2;
      } else if (fieldKey == 'horarioCierre2') {
        valorDesdeEstado = horarioCierre2;
      }
      
      if (valorDesdeEstado != null && valorDesdeEstado.isNotEmpty) {
        final parts = valorDesdeEstado.split(':');
        if (parts.length == 2) {
          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour != null && minute != null && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
            initialTime = TimeOfDay(hour: hour, minute: minute);
          }
        }
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.amber,
            onSurface: Colors.white,
          ), dialogTheme: DialogThemeData(backgroundColor: const Color(0xFF1E1E1E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final String formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      await updateRealTime({fieldKey: formatted});
      
      // Actualizar estado local si es necesario
      if (mounted) {
        setState(() {
          if (fieldKey == 'horarioApertura2') {
            horarioApertura2 = formatted;
          } else if (fieldKey == 'horarioCierre2') {
            horarioCierre2 = formatted;
          }
        });
      }
    }
  }

  /// Actualiza el estado de doble turno en Firestore en tiempo real
  /// 
  /// [valor]: Nuevo valor del switch de doble turno
  /// 
  /// Si se desactiva el doble turno, opcionalmente se pueden limpiar los campos del segundo turno
  /// pasando [limpiarHorarios] como true.
  Future<void> actualizarDobleTurno(bool valor, {bool limpiarHorarios = false}) async {
    try {
      final Map<String, dynamic> updateData = {'tieneDobleTurno': valor};
      
      if (!valor && limpiarHorarios) {
        updateData['horarioApertura2'] = FieldValue.delete();
        updateData['horarioCierre2'] = FieldValue.delete();
      }
      
      await updateRealTime(updateData);
      
      if (mounted) {
        setState(() {
          tieneDobleTurno = valor;
          if (!valor && limpiarHorarios) {
            horarioApertura2 = '';
            horarioCierre2 = '';
          }
        });
      }
    } catch (_) {
      // updateRealTime ya muestra el error
    }
  }

  /// Muestra una advertencia al activar el cobro en efectivo
  void mostrarAdvertenciaEfectivo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Text("Responsabilidad", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "Al activar el cobro en efectivo, aceptas los riesgos del manejo de dinero físico.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              updateRealTime({'aceptaEfectivo': true});
              Navigator.pop(ctx);
            },
            child: const Text("Acepto"),
          ),
        ],
      ),
    );
  }

  /// Limpia los recursos del Mixin (debe llamarse desde dispose del State)
  void disposeConfigLogic() {
    nombreController.dispose();
    direccionController.dispose();
    descripcionController.dispose();
    cbuController.dispose();
    aliasController.dispose();
    bancoController.dispose();
    titularController.dispose();
    envioBaseController.dispose();
    envioKmExtraController.dispose();
  }
}
