import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';

class StoryUploadScreen extends StatefulWidget {
  final XFile file;
  final String mediaType;

  const StoryUploadScreen({
    super.key,
    required this.file,
    required this.mediaType,
  });

  @override
  State<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen> {
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isFeatured = false;
  double _uploadProgress = 0.0; // Progreso de subida (0.0 a 1.0)
  String _uploadStatus = ''; // Estado actual de la subida

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == "video") {
      _videoController = VideoPlayerController.file(File(widget.file.path))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Debes iniciar sesión para subir una historia.");
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparando archivo...';
    });

    try {
      String? currentPhotoUrl = user.photoURL;
      String currentUserName = user.displayName ?? 'Usuario Anónimo';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users') 
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data.containsKey('photoUrl')) {
             currentPhotoUrl = data['photoUrl']; 
          }
          if (data != null && data.containsKey('displayName')) {
             currentUserName = data['displayName'];
          }
        }
      } catch (e) {
        debugPrint("Error obteniendo datos de usuario: $e");
      }

      // Preparar archivo con progreso
      if (mounted) {
        setState(() => _uploadStatus = widget.mediaType == 'video' 
            ? 'Comprimiendo video...' 
            : 'Optimizando imagen...');
      }

      final File fileToUpload = await _prepareFileForUpload();
      final fileExtension = fileToUpload.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExtension';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('stories')
          .child(user.uid)
          .child(fileName);

      // Subir con seguimiento de progreso
      if (mounted) {
        setState(() => _uploadStatus = 'Subiendo a la nube...');
      }

      final uploadTask = storageRef.putFile(fileToUpload);
      
      // Escuchar progreso de subida
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'Subiendo... ${(progress * 100).toStringAsFixed(0)}%';
          });
        }
      });

      // Esperar a que termine la subida
      await uploadTask;
      
      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
          _uploadStatus = 'Finalizando...';
        });
      }

      final mediaUrl = await storageRef.getDownloadURL();

      final storyData = {
        'authorId': user.uid,
        'authorName': currentUserName,
        'authorPhotoUrl': currentPhotoUrl,
        'mediaUrl': mediaUrl,
        'mediaType': widget.mediaType,
        'thumbnailUrl': widget.mediaType == 'image' ? mediaUrl : null,
        'isFeatured': _isFeatured, // <-- Ahora usa el valor del toggle
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'reactions': {},
        'reactionsUsers': {},
        'commentsCount': 0,
        'viewers': [], // Inicializamos la lista de vistas
      };
      
      await FirebaseFirestore.instance.collection('stories').add(storyData);

      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      _showError("Error al subir la historia: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<File> _prepareFileForUpload() async {
    final original = File(widget.file.path);
    
    if (widget.mediaType == "video") {
      try {
        // Comprimir video con mejor calidad y tamaño optimizado
        final info = await VideoCompress.compressVideo(
          original.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
          frameRate: 30, // Limitar FPS para reducir tamaño
        );
        
        if (info != null && info.file != null) {
          // Verificar tamaño del archivo comprimido
          final compressedFile = info.file!;
          final fileSize = await compressedFile.length();
          final sizeMB = fileSize / (1024 * 1024);
          
          // Si aún es muy grande, comprimir más
          if (sizeMB > 10) {
            debugPrint('Video aún grande ($sizeMB MB), comprimiendo más...');
            final info2 = await VideoCompress.compressVideo(
              compressedFile.path,
              quality: VideoQuality.LowQuality,
              deleteOrigin: true,
              includeAudio: true,
              frameRate: 24,
            );
            if (info2 != null && info2.file != null) {
              return info2.file!;
            }
          }
          
          return compressedFile;
        }
      } catch (e) {
        debugPrint('Error comprimiendo video: $e');
      }
      return original;
    } else {
      // Para imágenes, ya están optimizadas por image_picker con imageQuality: 80
      // Pero podemos verificar el tamaño y comprimir más si es necesario
      try {
        final fileSize = await original.length();
        final sizeMB = fileSize / (1024 * 1024);
        
        // Si la imagen es mayor a 2MB, podría optimizarse más
        // Pero por ahora confiamos en la compresión de image_picker
        if (sizeMB > 5) {
          debugPrint('Imagen grande ($sizeMB MB), pero usando compresión del picker');
        }
      } catch (e) {
        debugPrint('Error verificando tamaño de imagen: $e');
      }
      
      return original;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsualizar Historia'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleUpload,
            child: Text(
              _isLoading ? 'Subiendo...' : 'Subir', 
              style: const TextStyle(color: Colors.white)
            ),
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Previsualización (CORREGIDO EL FIT)
          Center(
            child: widget.mediaType == "image"
                ? Image.file(
                    File(widget.file.path),
                    fit: BoxFit.contain, // <-- Cambio clave para verla completa
                  )
                : (_videoController != null && _videoController!.value.isInitialized)
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const CircularProgressIndicator(),
          ),

          // 2. Botón para Destacar (Solo visible si no está cargando)
          if (!_isLoading)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: FilterChip(
                  label: Text(
                    _isFeatured ? "¡HISTORIA DESTACADA! ⭐" : "Destacar esta historia",
                    style: TextStyle(color: _isFeatured ? Colors.black : Colors.white),
                  ),
                  selected: _isFeatured,
                  selectedColor: const Color(0xFFFFD700), // Dorado
                  checkmarkColor: Colors.black,
                  backgroundColor: Colors.white10,
                  onSelected: (bool selected) {
                    setState(() {
                      _isFeatured = selected;
                    });
                  },
                ),
              ),
            ),

          // 3. Indicador de carga con progreso
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _uploadStatus.isNotEmpty ? _uploadStatus : 'Subiendo historia...',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}