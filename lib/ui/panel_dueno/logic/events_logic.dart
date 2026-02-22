import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Mixin que contiene la lógica de negocio para la gestión de eventos
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
mixin EventsLogicMixin<T extends StatefulWidget> on State<T> {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Obtiene el stream de eventos ordenados por fecha
  Stream<QuerySnapshot> getEventsStream() {
    return FirebaseFirestore.instance
        .collection('events')
        .where('placeId', isEqualTo: placeId)
        .orderBy('date', descending: false)
        .snapshots();
  }

  /// Elimina un evento con confirmación y borra su imagen de Storage si existe
  Future<void> deleteEvent(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          "¿Borrar anuncio?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Esto lo eliminará de la agenda de los clientes.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Borrar",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Primero obtenemos el documento para verificar si tiene imagen
        final ref = FirebaseFirestore.instance.collection('events').doc(id);
        final snap = await ref.get();
        final data = snap.data();

        // Si tiene imagen, la borramos de Storage
        if (data != null && data['imagePath'] != null) {
          try {
            await FirebaseStorage.instance
                .ref(data['imagePath'] as String)
                .delete();
          } catch (e) {
            debugPrint("Error borrando imagen: $e");
            // Continuamos aunque falle el borrado de imagen
          }
        }

        // Borramos el documento de Firestore
        await ref.delete();
      } catch (e) {
        debugPrint("Error borrando evento: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al borrar evento: $e"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
