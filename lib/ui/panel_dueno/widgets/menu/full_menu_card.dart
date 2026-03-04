import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Tarjeta para gestionar la carta digital completa (PDF o Imagen)
class FullMenuCard extends StatefulWidget {
  final String placeId;

  const FullMenuCard({
    super.key,
    required this.placeId,
  });

  @override
  State<FullMenuCard> createState() => _FullMenuCardState();
}

class _FullMenuCardState extends State<FullMenuCard> {
  bool _uploading = false;
  late final Stream<DocumentSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final String? menuUrl = data['fullMenuUrl'];
        final String? menuType = data['fullMenuType'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.file_copy, color: Colors.orangeAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Carta Digital Completa",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "PDF o Imagen del menú físico",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_uploading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (menuUrl != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        menuType == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Archivo cargado (${menuType?.toUpperCase()})",
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _eliminarArchivo(menuUrl),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _subirArchivo,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Subir PDF / JPG"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Sube un archivo PDF o imagen a Firebase Storage
  Future<void> _subirArchivo() async {
    // IMPORTANTE: En web, 'withData: true' es necesario para que cargue los bytes en memoria
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() => _uploading = true);

      PlatformFile pFile = result.files.single;
      String ext = pFile.extension ?? 'jpg';
      String type = (ext == 'pdf') ? 'pdf' : 'image';
      String mimeType = (ext == 'pdf') ? 'application/pdf' : 'image/jpeg';

      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('places/${widget.placeId}/full_menu/menu.$ext');

        if (kIsWeb) {
          // WEB: Usamos bytes
          if (pFile.bytes != null) {
            final metadata = SettableMetadata(contentType: mimeType);
            await ref.putData(pFile.bytes!, metadata);
          }
        } else {
          // MÓVIL: Usamos path
          if (pFile.path != null) {
            File file = File(pFile.path!);
            await ref.putFile(file);
          }
        }

        final url = await ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .update({'fullMenuUrl': url, 'fullMenuType': type});
      } catch (e) {
        debugPrint("Error subiendo menú completo: $e");
      } finally {
        setState(() => _uploading = false);
      }
    }
  }

  /// Elimina el archivo del menú completo
  Future<void> _eliminarArchivo(String url) async {
    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (_) {}
    await FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .update({
      'fullMenuUrl': FieldValue.delete(),
      'fullMenuType': FieldValue.delete(),
    });
  }
}
