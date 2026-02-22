import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:barapp/screens/story_upload_screen.dart';
import 'media_constants.dart';

/// Lógica para seleccionar y procesar medios (imágenes/videos) para historias
class MediaPickerLogic {
  /// Maneja la selección de imagen o video desde cámara o galería
  /// 
  /// Valida duración y tamaño de videos, comprime si es necesario,
  /// y navega a la pantalla de previsualización
  static Future<void> handleImagePick(
    BuildContext context,
    ImageSource source,
  ) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;

    try {
      // --- CORRECCIÓN CLAVE ---
      if (source == ImageSource.camera) {
        // La cámara nativa no deja elegir "foto o video" en la misma UI con este plugin.
        // Por defecto abrimos la cámara de FOTOS.
        file = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1920,
        );
      } else {
        // Para galería, sí usamos pickMedia (permite seleccionar foto O video)
        file = await picker.pickMedia(
          imageQuality: 80, // Esto solo comprime si el usuario elige una imagen
        );
      }
    } catch (e) {
      debugPrint('Error al abrir cámara/galería: $e');
      return;
    }

    if (file == null) return; // El usuario canceló

    // 2) Detectar bien si es video o imagen
    final mimeType = file.mimeType ?? '';
    final pathLower = file.path.toLowerCase();

    final bool isVideo = mimeType.startsWith('video/') ||
        pathLower.endsWith('.mp4') ||
        pathLower.endsWith('.mov') ||
        pathLower.endsWith('.m4v');

    final String mediaType = isVideo ? "video" : "image";

    XFile fileToUpload = file;

    // 3) Si es video, validamos duración y tamaño ANTES de comprimir
    if (isVideo) {
      try {
        // Info del video original
        final MediaInfo info = await VideoCompress.getMediaInfo(file.path);

        if (info.duration == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo leer la información del video. Intenta con otro.'),
              ),
            );
          }
          return;
        }

        // Duración en segundos
        final double durationSec = (info.duration! / 1000.0);
        if (durationSec > MediaConstants.maxStoryVideoSeconds) {
          if (context.mounted) {
            final segundos = durationSec.round();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'El video dura ${segundos}s y el máximo para historias es de '
                  '${MediaConstants.maxStoryVideoSeconds} segundos. Recortalo antes de subirlo.',
                ),
              ),
            );
          }
          return;
        }

        // Tamaño máximo en MB
        if (info.filesize != null) {
          final double sizeMB = info.filesize! / (1024 * 1024);
          if (sizeMB > MediaConstants.maxStoryVideoSizeMB) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'El video pesa ${sizeMB.toStringAsFixed(1)} MB y el máximo es '
                    '${MediaConstants.maxStoryVideoSizeMB} MB. Recortalo o bajale la calidad.',
                  ),
                ),
              );
            }
            return;
          }
        }

        // 4) Si pasó las validaciones, recién ahí comprimimos
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comprimiendo video...'),
              duration: Duration(days: 1), // lo cerramos nosotros después en el dismiss
            ),
          );
        }

        final MediaInfo? compressed = await VideoCompress.compressVideo(
          file.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );

        if (compressed == null || compressed.path == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo comprimir el video. Intenta con otro.'),
              ),
            );
          }
          return;
        }

        fileToUpload = XFile(compressed.path!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      } catch (e) {
        debugPrint('Error comprimiendo video de historia: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocurrió un error al procesar el video. Intenta con otro archivo.'),
            ),
          );
        }
        return;
      }
    }

    // 5) Para imágenes no hay drama: ya se comprimen con imageQuality: 80 al inicio

    if (!context.mounted) return;

    // 6) Navegamos a la pantalla de previsualización
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryUploadScreen(
          file: fileToUpload,
          mediaType: mediaType,
        ),
      ),
    );
  }

  /// Muestra el menú inferior para seleccionar fuente de media (galería o cámara)
  static void pickStory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Subir historia',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.image_rounded),
                title: const Text('Desde galería'),
                onTap: () {
                  Navigator.pop(context); // Cierra el bottom sheet
                  handleImagePick(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context); // Cierra el bottom sheet
                  handleImagePick(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
