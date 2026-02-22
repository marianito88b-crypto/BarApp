import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barapp/ui/community/post_card_general.dart'; // Asegúrate de que esta ruta sea correcta

class ReportsAdminScreen extends StatelessWidget {
  const ReportsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Moderación de Reportes"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error de permisos en Firestore", style: TextStyle(color: Colors.red)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No hay reportes pendientes 🙌", style: TextStyle(color: Colors.white54)));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final report = docs[index].data() as Map<String, dynamic>;
              final reportId = docs[index].id;
              final String reason = report['reason'] ?? 'Sin motivo';
              final String details = report['details'] ?? '';
              final String? postPath = report['postPath'];
              final Timestamp? ts = report['timestamp'] as Timestamp?;
              final String date = ts != null ? DateFormat('dd/MM HH:mm').format(ts.toDate()) : '--/--';

              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(4)),
                            child: Text(reason, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          Text(date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (details.isNotEmpty)
                        Text("Detalles: $details", style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 🔥 BOTÓN PARA VER EL POST
                          TextButton.icon(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            label: const Text("Ver Post"),
                            onPressed: () => _previewReportedPost(context, postPath),
                          ),
                          const SizedBox(width: 8),
                          // 🔥 BOTÓN PARA GESTIONAR
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => _showActionDialog(context, reportId, postPath),
                            child: const Text("Acciones"),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- 1. PREVISUALIZAR EL POST ---
  void _previewReportedPost(BuildContext context, String? path) async {
    if (path == null) return;

    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.doc(path).get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || !snap.data!.exists) {
            return const AlertDialog(title: Text("El post ya no existe"), content: Text("Parece que fue borrado por el usuario."));
          }

          final postData = snap.data!.data() as Map<String, dynamic>;
          
          return Dialog(
            backgroundColor: Colors.black,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Vista Previa del Post", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ),
                  // Usamos tu widget de PostCard pero en modo estático
                  PostCardGeneral(
                    data: postData,
                    postReference: snap.data!.reference,
                    isFeatured: postData['destacado'] ?? false,
                    onReact: (_) {}, 
                    onCommentTap: () {},
                    onDelete: null,
                    onPlaceTap: (_, _) {},
                  ),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar")),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 2. DIÁLOGO DE ACCIONES (Corregido) ---
  void _showActionDialog(BuildContext context, String reportId, String? postPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242526),
        title: const Text("¿Qué medidas tomar?", style: TextStyle(color: Colors.white)),
        content: const Text("Puedes desestimar el reporte si está todo bien, o borrar el post si infringe las reglas."),
        actions: [
          TextButton(
            onPressed: () async {
              // BORRAR SOLO EL REPORTE
              await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Desestimar (Borrar reporte)")
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              // BORRAR POST Y REPORTE
              if (postPath != null) {
                try {
                  await FirebaseFirestore.instance.doc(postPath).delete();
                } catch (e) {
                  debugPrint("Error borrando post: $e");
                }
              }
              await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("Borrar Post Definitivamente")
          ),
        ],
      ),
    );
  }
}