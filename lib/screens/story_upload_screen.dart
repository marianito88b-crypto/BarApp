import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:barapp/ui/home/logic/media_constants.dart';

class StoryUploadScreen extends StatefulWidget {
  final XFile? file;
  final String mediaType;
  final List<XFile>? files;

  StoryUploadScreen({
    super.key,
    this.file,
    this.mediaType = 'image',
    this.files,
  }) : assert(file != null || (files != null && files.isNotEmpty),
         'Debe proporcionar file o files');

  @override
  State<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen> {
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isFeatured = false;
  double _uploadProgress = 0.0; // Progreso de subida (0.0 a 1.0)
  String _uploadStatus = ''; // Estado actual de la subida
  int _uploadedCount = 0; // Cuántas se subieron en multi-upload

  bool get _isMultiUpload => widget.files != null && widget.files!.length > 1;

  @override
  void initState() {
    super.initState();
    _initPreview();
  }

  void _initPreview() {
    if (_isMultiUpload) return;
    final xfile = widget.file!;
    final mediaType = _detectMediaType(xfile);
    if (mediaType == "video") {
      _videoController = VideoPlayerController.file(File(xfile.path))
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

  String _detectMediaType(XFile xfile) {
    final mimeType = xfile.mimeType ?? '';
    final pathLower = xfile.path.toLowerCase();
    final isVideo = mimeType.startsWith('video/') ||
        pathLower.endsWith('.mp4') ||
        pathLower.endsWith('.mov') ||
        pathLower.endsWith('.m4v');
    return isVideo ? 'video' : 'image';
  }

  Future<bool> _validateVideo(XFile xfile) async {
    try {
      final info = await VideoCompress.getMediaInfo(xfile.path);
      if (info.duration == null) return false;
      final durationSec = info.duration! / 1000.0;
      if (durationSec > MediaConstants.maxStoryVideoSeconds) return false;
      if (info.filesize != null) {
        final sizeMB = info.filesize! / (1024 * 1024);
        if (sizeMB > MediaConstants.maxStoryVideoSizeMB) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleUpload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Debes iniciar sesión para subir una historia.");
      return;
    }

    if (_isMultiUpload) {
      await _handleMultiUpload(user);
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Preparando archivo...';
    });

    try {
      final currentPhotoUrl = await _getUserPhotoUrl(user);
      final currentUserName = await _getUserName(user);

      if (mounted) {
        setState(() => _uploadStatus = widget.mediaType == 'video'
            ? 'Comprimiendo video...'
            : 'Optimizando imagen...');
      }

      final File fileToUpload = await _prepareFileForUpload(widget.file!, widget.mediaType);
      await _uploadSingleStory(user, fileToUpload, widget.mediaType, currentPhotoUrl, currentUserName);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError("Error al subir la historia: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleMultiUpload(dynamic user) async {
    final files = widget.files!;
    final currentPhotoUrl = await _getUserPhotoUrl(user);
    final currentUserName = await _getUserName(user);

    setState(() {
      _isLoading = true;
      _uploadedCount = 0;
      _uploadStatus = 'Preparando ${files.length} archivos...';
    });

    int successCount = 0;
    for (int i = 0; i < files.length; i++) {
      if (!mounted) return;
      final xfile = files[i];
      final mediaType = _detectMediaType(xfile);

      if (mediaType == 'video') {
        final valid = await _validateVideo(xfile);
        if (!valid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Video ${i + 1} excede duración o tamaño. Se omite.')),
            );
          }
          continue;
        }
      }

      setState(() {
        _uploadStatus = 'Procesando ${i + 1}/${files.length}...';
      });

      try {
        final fileToUpload = await _prepareFileForUpload(xfile, mediaType);
        await _uploadSingleStory(user, fileToUpload, mediaType, currentPhotoUrl, currentUserName);
        successCount++;
        if (mounted) setState(() => _uploadedCount = successCount);
      } catch (e) {
        debugPrint('Error subiendo archivo ${i + 1}: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error en archivo ${i + 1}. Se continúa con el resto.')),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (successCount > 0) Navigator.of(context).pop();
      if (successCount == 0) _showError('No se pudo subir ninguna historia.');
    }
  }

  Future<String?> _getUserPhotoUrl(dynamic user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          return data['imageUrl'] ?? data['photoUrl'] ?? data['fotoPerfilUrl'];
        }
      }
    } catch (_) {}
    return user.photoURL;
  }

  Future<String> _getUserName(dynamic user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('displayName')) {
          return data['displayName'];
        }
      }
    } catch (_) {}
    return user.displayName ?? 'Usuario Anónimo';
  }

  Future<void> _uploadSingleStory(
    dynamic user,
    File fileToUpload,
    String mediaType,
    String? currentPhotoUrl,
    String currentUserName,
  ) async {
    final fileExtension = fileToUpload.path.split('.').last;
    final fileName = '${const Uuid().v4()}.$fileExtension';

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('stories')
        .child(user.uid)
        .child(fileName);

    if (mounted && !_isMultiUpload) {
      setState(() => _uploadStatus = 'Subiendo a la nube...');
    }

    final uploadTask = storageRef.putFile(fileToUpload);

    if (!_isMultiUpload) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            _uploadProgress = progress;
            _uploadStatus = 'Subiendo... ${(progress * 100).toStringAsFixed(0)}%';
          });
        }
      });
    }

    await uploadTask;
    final mediaUrl = await storageRef.getDownloadURL();

    final storyData = {
      'authorId': user.uid,
      'authorName': currentUserName,
      'authorPhotoUrl': currentPhotoUrl,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'thumbnailUrl': mediaType == 'image' ? mediaUrl : null,
      'isFeatured': _isFeatured,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(hours: 24)),
      ),
      'reactions': {},
      'reactionsUsers': {},
      'commentsCount': 0,
      'viewers': [],
    };

    await FirebaseFirestore.instance.collection('stories').add(storyData);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<File> _prepareFileForUpload(XFile xfile, String mediaType) async {
    final original = File(xfile.path);

    if (mediaType == "video") {
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
        title: Text(_isMultiUpload ? 'Previsualizar (${widget.files!.length} archivos)' : 'Previsualizar Historia'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleUpload,
            child: Text(
              _isLoading ? (_isMultiUpload ? 'Subiendo $_uploadedCount...' : 'Subiendo...') : 'Subir',
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Previsualización
          _isMultiUpload
              ? PageView.builder(
                  itemCount: widget.files!.length,
                  itemBuilder: (_, i) {
                    final xfile = widget.files![i];
                    final mediaType = _detectMediaType(xfile);
                    return mediaType == 'image'
                        ? Image.file(File(xfile.path), fit: BoxFit.contain)
                        : _VideoPreviewItem(path: xfile.path);
                  },
                )
              : Center(
                  child: widget.mediaType == "image"
                      ? Image.file(
                          File(widget.file!.path),
                          fit: BoxFit.contain,
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
                  selectedColor: const Color(0xFFFFD700),
                  checkmarkColor: Colors.black,
                  backgroundColor: Colors.white10,
                  onSelected: (bool selected) {
                    setState(() => _isFeatured = selected);
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
                        value: _isMultiUpload
                            ? (_uploadedCount / widget.files!.length).clamp(0.0, 1.0)
                            : _uploadProgress,
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
                    if (!_isMultiUpload)
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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

/// Preview de video para multi-upload (sin controlador persistente)
class _VideoPreviewItem extends StatefulWidget {
  final String path;

  const _VideoPreviewItem({required this.path});

  @override
  State<_VideoPreviewItem> createState() => _VideoPreviewItemState();
}

class _VideoPreviewItemState extends State<_VideoPreviewItem> {
  VideoPlayerController? _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _ctrl?.play();
          _ctrl?.setLooping(true);
        }
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ctrl == null || !_ctrl!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _ctrl!.value.aspectRatio,
        child: VideoPlayer(_ctrl!),
      ),
    );
  }
}