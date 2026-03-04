import 'dart:io';
import 'dart:ui'; // <--- AGREGADO para el efecto de Blur
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

// Importamos el selector de lugar que YA TIENES
import 'place_selector_screen.dart';
import '../../services/moderation/text_filter_service.dart';

class NuevaPublicacionScreen extends StatefulWidget {
  const NuevaPublicacionScreen({super.key});

  @override
  State<NuevaPublicacionScreen> createState() => _NuevaPublicacionScreenState();
}

class _NuevaPublicacionScreenState extends State<NuevaPublicacionScreen> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  bool _isUploading = false;

  String? _selectedPlaceId;
  String? _selectedPlaceName;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectPlace() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PlaceSelectorScreen()),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _selectedPlaceId = result['id'] as String?;
        _selectedPlaceName = result['name'] as String?;
      });
    }
  }

  Future<void> _publicar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tenés que iniciar sesión para publicar')),
      );
      return;
    }

    final texto = _textController.text.trim();
    if (texto.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribí algo o agregá una imagen')),
      );
      return;
    }

    try {
      setState(() => _isUploading = true);

      final String textoLimpio = TextFilterService.sanitizeText(texto);

      String imageUrl = '';
      if (_pickedImage != null) {
        final fileName =
            'comunidad_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('comunidad')
            .child(fileName);
        await ref.putFile(_pickedImage!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('comunidad').add({
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Usuario',
        'authorPhotoUrl': user.photoURL ?? '',
        'comentario': textoLimpio,
        'imageUrl': imageUrl,
        'placeId': _selectedPlaceId ?? '',
        'placeName': _selectedPlaceName ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'reacciones': <String, dynamic>{},
        'reaccionesUsuarios': <String, dynamic>{},
        'destacado': false,
      });

      if (mounted) {
         Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // --- ¡CORRECCIÓN RECORTE LIBRE! ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (picked == null) return;

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        // ELIMINAMOS aspectRatio fijo 1/1 para permitir cualquier formato
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar foto',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false, // <--- LIBERAMOS EL RECORTE
          ),
          IOSUiSettings(
            title: 'Ajustar foto',
            aspectRatioLockEnabled: false, // <--- LIBERAMOS EL RECORTE
          ),
        ],
      );

      if (cropped == null) return;

      setState(() {
        _pickedImage = File(cropped.path);
      });
    } catch (e) {
      debugPrint('Error cargando imagen: $e');
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Galería', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.white),
                title: const Text('Cámara', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Nueva publicación'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _publicar,
            child: Text(
              _isUploading ? 'Publicando...' : 'Publicar',
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _textController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Contanos algo...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: _showImageSourceSheet,
                        icon: const Icon(Icons.image, color: Colors.orangeAccent),
                        label: const Text(
                          'Agregar foto',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                      if (_pickedImage != null)
                        Text(
                          '1 foto seleccionada',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- CORRECCIÓN PREVISUALIZACIÓN COMPLETA (STORY STYLE) ---
                  if (_pickedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 350, // Altura fija para el muro
                        width: double.infinity,
                        color: Colors.black,
                        child: Stack(
                          children: [
                            // 1. Fondo con Blur
                            Positioned.fill(
                              child: Image.file(_pickedImage!, fit: BoxFit.cover),
                            ),
                            Positioned.fill(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(color: Colors.black.withValues(alpha: 0.3)),
                              ),
                            ),
                            // 2. Imagen Real sin recortar
                            Positioned.fill(
                              child: Image.file(
                                _pickedImage!,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Botón para quitar la foto por si el usuario se arrepiente
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _pickedImage = null),
                                child: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close, color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_selectedPlaceName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.orangeAccent, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _selectedPlaceName!,
                            style: const TextStyle(color: Colors.white70),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _selectPlace,
                          child: const Text(
                            'Cambiar',
                            style: TextStyle(color: Colors.orangeAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _selectPlace,
                        icon: const Icon(Icons.place_outlined, color: Colors.orangeAccent),
                        label: const Text(
                          'Agregar lugar',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _publicar,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isUploading ? 'Publicando...' : 'Publicar'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}