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

  // 2. Abrir Caja
  Future<void> abrirCaja(double montoInicial, String usuario) async {
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

  // 3. Cerrar Caja (El momento de la verdad)
  Future<void> cerrarCaja(String sesionId, double montoRealEnCajon, double montoSistema) async {
    double diferencia = montoRealEnCajon - montoSistema;

    await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('caja_sesiones')
        .doc(sesionId)
        .update({
      'fecha_cierre': FieldValue.serverTimestamp(),
      'monto_final_real': montoRealEnCajon, // Lo que el humano contó
      'monto_sistema_calculado': montoSistema, // Lo que la máquina calculó
      'diferencia': diferencia, // Sobrante (+) o Faltante (-)
      'estado': 'cerrada',
    });
  }
}