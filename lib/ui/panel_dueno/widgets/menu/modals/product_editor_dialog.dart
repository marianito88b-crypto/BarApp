import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:barapp/models/menu_categories.dart';
import 'package:flutter/foundation.dart';

/// Diálogo para crear o editar un producto del menú
/// 
/// Maneja la lógica híbrida de categorías (Dropdown + Categoría Nueva)
/// y la subida de imágenes a Firebase Storage tanto para Web como para Móvil
class ProductEditorDialog extends StatefulWidget {
  final String placeId;
  final String? docId;
  final Map<String, dynamic>? initialData;

  const ProductEditorDialog({
    super.key,
    required this.placeId,
    this.docId,
    this.initialData,
  });

  @override
  State<ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<ProductEditorDialog> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _stockCtrl;

  // 🔥 Controlador para categoría personalizada
  late TextEditingController _customCategoryCtrl;
  bool _isCustomCategory = false; // Switch para saber si mostramos Dropdown o Input

  bool _controlaStock = false;
  String? _selectedCategory;
  String? _currentFotoUrl;

  File? _newFotoFile;
  Uint8List? _newFotoBytes;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialData?['nombre'] ?? '');
    _descCtrl = TextEditingController(text: widget.initialData?['descripcion'] ?? '');
    _precioCtrl = TextEditingController(text: widget.initialData?['precio']?.toString() ?? '');
    _stockCtrl = TextEditingController(text: widget.initialData?['stock']?.toString() ?? '0');

    // --- LÓGICA DE CATEGORÍA INTELIGENTE ---
    String? catInicial = widget.initialData?['categoria'];
    _customCategoryCtrl = TextEditingController();

    // Si hay categoría y NO está en la lista predefinida, es personalizada
    if (catInicial != null && !MenuCategories.list.contains(catInicial)) {
      _isCustomCategory = true;
      _customCategoryCtrl.text = catInicial;
      _selectedCategory = null;
    } else {
      _isCustomCategory = false;
      _selectedCategory = catInicial;
    }
    // ----------------------------------------

    _controlaStock = widget.initialData?['controlaStock'] ?? false;
    _currentFotoUrl = widget.initialData?['fotoUrl'];
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _customCategoryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (kIsWeb && _newFotoBytes != null) {
      imageProvider = MemoryImage(_newFotoBytes!);
    } else if (!kIsWeb && _newFotoFile != null) {
      imageProvider = FileImage(_newFotoFile!);
    } else if (_currentFotoUrl != null) {
      imageProvider = NetworkImage(_currentFotoUrl!);
    }

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(
        widget.docId == null ? "Nuevo Plato" : "Editar Plato",
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // FOTO PICKER
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    image: (imageProvider != null)
                        ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                        : null,
                  ),
                  child: (imageProvider == null)
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                color: Colors.orangeAccent, size: 40),
                            SizedBox(height: 8),
                            Text("Toca para subir foto",
                                style: TextStyle(color: Colors.white54)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 15),

              // 🔥 SELECTOR DE CATEGORÍA HÍBRIDO (DROPDOWN O TEXTO)
              _buildCategorySelector(),

              const SizedBox(height: 10),

              // INPUTS BASICOS
              _inputContainer(
                TextField(
                  controller: _nombreCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Nombre del plato",
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _inputContainer(
                TextField(
                  controller: _precioCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Precio (\$)",
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // SECCIÓN STOCK
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.orangeAccent,
                      title: const Text(
                        "Controlar Stock",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      subtitle: const Text(
                        "Activar para bebidas o kiosco",
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      value: _controlaStock,
                      onChanged: (val) => setState(() => _controlaStock = val),
                    ),
                    if (_controlaStock)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        child: TextField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Stock Inicial",
                            border: InputBorder.none,
                            labelStyle: TextStyle(color: Colors.white70),
                            icon: Icon(Icons.inventory_2,
                                color: Colors.orangeAccent, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
              _inputContainer(
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Descripción",
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!_uploading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar",
                style: TextStyle(color: Colors.white54)),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
          ),
          onPressed: _uploading ? null : _saveProduct,
          child: _uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text("Guardar"),
        ),
      ],
    );
  }

  // 🔥 WIDGET LOGICA CATEGORÍA
  Widget _buildCategorySelector() {
    if (_isCustomCategory) {
      // MODO TEXTO (Personalizado)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customCategoryCtrl,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  labelText: "Nombre de Categoría Nueva",
                  border: InputBorder.none,
                  labelStyle: TextStyle(color: Colors.orangeAccent),
                  hintText: "Ej: Empanadas, Promos...",
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              tooltip: "Volver a lista",
              onPressed: () {
                setState(() {
                  _isCustomCategory = false;
                  _customCategoryCtrl.clear();
                  _selectedCategory = null;
                });
              },
            ),
          ],
        ),
      );
    } else {
      // MODO LISTA (Dropdown)
      return _inputContainer(
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          hint: const Text("Selecciona Categoría",
              style: TextStyle(color: Colors.white54)),
          dropdownColor: const Color(0xFF2C2C2C),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Categoría",
            labelStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          items: [
            ...MenuCategories.list.map(
              (String cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ),
            ),
            // Opción especial al final
            const DropdownMenuItem(
              value: "CUSTOM_NEW",
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      color: Colors.orangeAccent, size: 18),
                  SizedBox(width: 8),
                  Text("Nueva / Personalizada...",
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val == "CUSTOM_NEW") {
              setState(() {
                _isCustomCategory = true;
                _selectedCategory = null;
              });
            } else {
              setState(() => _selectedCategory = val);
            }
          },
        ),
      );
    }
  }

  // 📸 PICKER HÍBRIDO (Web y Móvil)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _newFotoBytes = bytes);
      } else {
        setState(() => _newFotoFile = File(image.path));
      }
    }
  }

  // ☁️ GUARDAR (CON LÓGICA DE CATEGORÍA PERSONALIZADA)
  Future<void> _saveProduct() async {
    // Validar categoría
    String finalCategory = '';
    if (_isCustomCategory) {
      finalCategory = _customCategoryCtrl.text.trim();
      // Forzamos primera letra mayúscula para que quede lindo
      if (finalCategory.isNotEmpty) {
        finalCategory = finalCategory[0].toUpperCase() +
            finalCategory.substring(1);
      }
    } else {
      finalCategory = _selectedCategory ?? '';
    }

    // Validar precio
    final double? precio = double.tryParse(_precioCtrl.text);
    if (_nombreCtrl.text.isEmpty ||
        _precioCtrl.text.isEmpty ||
        precio == null ||
        precio <= 0 ||
        finalCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Faltan datos obligatorios (Nombre, Precio válido o Categoría)",
          ),
        ),
      );
      return;
    }

    setState(() => _uploading = true);
    String? finalUrl = _currentFotoUrl;

    bool hasNewImage =
        (kIsWeb && _newFotoBytes != null) || (!kIsWeb && _newFotoFile != null);

    if (hasNewImage) {
      try {
        final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
        final ref = FirebaseStorage.instance
            .ref()
            .child('places/${widget.placeId}/products/$fileName');

        if (kIsWeb) {
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          await ref.putData(_newFotoBytes!, metadata);
        } else {
          await ref.putFile(_newFotoFile!);
        }

        finalUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint("Error subiendo foto: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al subir la imagen: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _uploading = false);
        return;
      }
    }

    try {
      final payload = {
        "nombre": _nombreCtrl.text.trim(),
        "descripcion": _descCtrl.text.trim(),
        "categoria": finalCategory,
        "precio": precio,
        "fotoUrl": finalUrl,
        "controlaStock": _controlaStock,
        "stock": _controlaStock ? (int.tryParse(_stockCtrl.text) ?? 0) : 0,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      final ref = FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("menu");
      if (widget.docId == null) {
        await ref.add(payload);
      } else {
        await ref.doc(widget.docId).update(payload);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error guardando producto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al guardar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _inputContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}
