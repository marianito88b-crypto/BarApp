import 'package:cloud_firestore/cloud_firestore.dart';

/// Mixin que contiene la lógica de negocio para la gestión de gastos
/// 
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
mixin GastosLogicMixin {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Obtiene el stream de proveedores
  Stream<QuerySnapshot> getProveedoresStream() {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('proveedores')
        .snapshots();
  }

  /// Obtiene el stream de gastos ordenados por fecha
  Stream<QuerySnapshot> getGastosStream({int limit = 50}) {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('gastos')
        .orderBy('fecha', descending: true)
        .limit(limit)
        .snapshots();
  }
}
