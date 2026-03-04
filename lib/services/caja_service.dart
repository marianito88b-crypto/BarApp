import 'package:cloud_firestore/cloud_firestore.dart';

class CajaService {
  final String placeId;

  CajaService(this.placeId);

  // 1. Obtener la sesión actual (Si hay una abierta)
  Stream<QuerySnapshot> getSesionAbiertaStream() {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('caja_sesiones')
        .where('estado', isEqualTo: 'abierta')
        .limit(1)
        .snapshots();
  }

  // 2. Abrir Caja (con verificación de sesión existente)
  Future<void> abrirCaja(double montoInicial, String usuario) async {
    // Verificar que no haya una sesión ya abierta antes de crear otra
    final existing = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('caja_sesiones')
        .where('estado', isEqualTo: 'abierta')
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Ya existe una sesión de caja abierta');
    }

    await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('caja_sesiones')
        .add({
      'fecha_apertura': FieldValue.serverTimestamp(),
      'monto_inicial': montoInicial,
      'usuario_apertura': usuario,
      'estado': 'abierta',
      
      // Campos futuros para el cierre
      'fecha_cierre': null,
      'monto_final_real': 0,
      'monto_sistema_calculado': 0,
      'diferencia': 0,
    });
  }

  // 3. Cerrar Caja (con transacción para evitar cierre doble)
  Future<void> cerrarCaja(String sesionId, double montoRealEnCajon, double montoSistema) async {
    double diferencia = montoRealEnCajon - montoSistema;

    final sesionRef = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('caja_sesiones')
        .doc(sesionId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(sesionRef);
      if (!snap.exists) {
        throw Exception('La sesión de caja no existe');
      }
      if (snap.data()?['estado'] != 'abierta') {
        throw Exception('La sesión de caja ya fue cerrada');
      }

      transaction.update(sesionRef, {
        'fecha_cierre': FieldValue.serverTimestamp(),
        'monto_final_real': montoRealEnCajon,
        'monto_sistema_calculado': montoSistema,
        'diferencia': diferencia,
        'estado': 'cerrada',
      });
    });
  }
}