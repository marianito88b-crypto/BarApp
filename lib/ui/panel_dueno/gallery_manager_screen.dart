import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:barapp/ui/panel_dueno/widgets/gallery/gallery_image_card.dart';
import 'logic/gallery_logic.dart';

class GalleryManagerScreen extends StatefulWidget {
  final String placeId;
  const GalleryManagerScreen({super.key, required this.placeId});

  @override
  State<GalleryManagerScreen> createState() => _GalleryManagerScreenState();
}

class _GalleryManagerScreenState extends State<GalleryManagerScreen>
    with GalleryLogicMixin {
  @override
  String get placeId => widget.placeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Galería del Local"),
        backgroundColor: const Color(0xFF151515),
      ),
      body: Column(
        children: [
          // INDICADOR DE PROGRESO DE SUBIDA
          if (isLoading)
            const LinearProgressIndicator(
              backgroundColor: Color(0xFF1E1E1E),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          
          // HEADER EXPLICATIVO
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Sube las mejores fotos de tu ambiente, platos y tragos. ¡Estas fotos aparecerán en tu perfil!",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
              ],
            ),
          ),

          // GRILLA DE FOTOS
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('places')
                      .doc(widget.placeId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final List<dynamic> gallery = data?['gallery'] ?? [];
                final String? coverImageUrl = data?['coverImageUrl'];

                if (gallery.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 60,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No hay fotos aún",
                          style: TextStyle(color: Colors.white24),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: uploadPhoto,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text("SUBIR LA PRIMERA"),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 columnas
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: gallery.length,
                  itemBuilder: (context, index) {
                    final imgUrl = gallery[index];
                    return GalleryImageCard(
                      imageUrl: imgUrl,
                      isCoverImage: imgUrl == coverImageUrl,
                      onDelete: () => deletePhoto(imgUrl),
                      onToggleFavorite: () => setCoverImage(imgUrl),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isLoading ? null : uploadPhoto,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add_a_photo, color: Colors.black),
      ),
    );
  }
}
