import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../widgets/menu/modals/product_editor_dialog.dart';

/// Mixin que contiene la lógica de negocio para la gestión del menú
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
mixin MenuLogicMixin<T extends StatefulWidget> on State<T> {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Muestra el diálogo de edición de productos
  void showProductEditor({String? docId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductEditorDialog(
        placeId: placeId,
        docId: docId,
        initialData: data,
      ),
    );
  }

  /// Elimina un producto del menú con confirmación
  Future<void> eliminarProducto(String docId, String nombreItem) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Eliminar", style: TextStyle(color: Colors.white)),
        content: Text(
          "¿Borrar '$nombreItem' del menú?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Borrar", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Leer fotoUrl antes de borrar el documento para limpiar Storage
      final docRef = FirebaseFirestore.instance
          .collection("places")
          .doc(placeId)
          .collection("menu")
          .doc(docId);
      final snap = await docRef.get();
      if (snap.exists) {
        final fotoUrl = snap.data()?['fotoUrl'] as String?;
        if (fotoUrl != null && fotoUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(fotoUrl).delete();
          } catch (_) {
            // Si ya no existe en Storage, ignorar el error
          }
        }
        await docRef.delete();
      }
    }
  }

  /// Obtiene el stream de productos del menú ordenados por categoría
  Stream<QuerySnapshot> getMenuStream() {
    return FirebaseFirestore.instance
        .collection("places")
        .doc(placeId)
        .collection("menu")
        .orderBy("categoria")
        .snapshots();
  }
}
