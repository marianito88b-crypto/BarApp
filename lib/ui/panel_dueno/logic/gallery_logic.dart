import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Mixin que contiene la lógica de negocio para la gestión de galería
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin GalleryLogicMixin<T extends StatefulWidget> on State<T> {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  final ImagePicker _picker = ImagePicker();

  /// Variable de estado para controlar el loading
  bool isLoading = false;

  /// Setter para actualizar el estado de loading
  void setLoading(bool value) {
    if (mounted) {
      setState(() {
        isLoading = value;
      });
    }
  }

  /// Sube una foto a Firebase Storage y la agrega a la galería (compatible con Web y Mobile)
  ///
  /// Usa `kIsWeb` para determinar si usar `putData` (Web) o `putFile` (Mobile)
  Future<void> uploadPhoto() async {
    try {
      // 1. Elegir foto
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) return;

      setLoading(true);

      // 2. Referencia en Storage
      final String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('places')
          .child(placeId)
          .child('gallery')
          .child(fileName);

      // 3. Subir archivo (compatible Web/Mobile)
      if (kIsWeb) {
        // 🌐 MODO WEB: Leemos los bytes y usamos putData
        final bytes = await image.readAsBytes();
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        await ref.putData(bytes, metadata);
      } else {
        // 📱 MODO MÓVIL: Usamos File y putFile
        await ref.putFile(File(image.path));
      }

      // 4. Obtener URL
      final String downloadUrl = await ref.getDownloadURL();

      // 5. Guardar URL en Firestore (Array)
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .update({
        'gallery': FieldValue.arrayUnion([downloadUrl]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Foto subida con éxito"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error subiendo foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Error al subir"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Establece una imagen como imagen principal (coverImageUrl)
  ///
  /// [imageUrl]: URL de la imagen a establecer como principal
  Future<void> setCoverImage(String imageUrl) async {
    setLoading(true);
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .update({'coverImageUrl': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("⭐ Imagen principal actualizada"),
            backgroundColor: Colors.amber,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error estableciendo imagen principal: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  /// Muestra el diálogo de confirmación y borra una foto de la galería
  ///
  /// [imageUrl]: URL de la imagen a borrar
  /// 
  /// MEJORA: Borra tanto de Firestore como de Firebase Storage para evitar basura
  Future<void> deletePhoto(String imageUrl) async {
    if (!mounted) return;

    // Preguntar confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text(
          "¿Borrar foto?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Esta acción no se puede deshacer.",
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
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setLoading(true);
    try {
      // 1. Borrar del Array en Firestore
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .update({
        'gallery': FieldValue.arrayRemove([imageUrl]),
      });

      // 2. MEJORA: Borrar el archivo físico de Firebase Storage
      try {
        // Usar refFromURL para obtener la referencia desde la URL completa
        final Reference storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
        debugPrint("✅ Archivo borrado de Storage: $imageUrl");
      } catch (storageError) {
        // Si falla el borrado de Storage, no es crítico, solo logueamos
        debugPrint("⚠️ No se pudo borrar de Storage (puede que ya no exista): $storageError");
      }

      // 3. Si esta imagen era la imagen principal, limpiar coverImageUrl
      final placeDoc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .get();

      final placeData = placeDoc.data();
      if (placeData?['coverImageUrl'] == imageUrl) {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .update({'coverImageUrl': FieldValue.delete()});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Foto eliminada"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error borrando foto: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al borrar: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }
}
