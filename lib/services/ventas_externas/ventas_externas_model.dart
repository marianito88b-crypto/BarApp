import 'package:cloud_firestore/cloud_firestore.dart';

class VentaExterna {
  final String id;
  final DateTime fecha;
  final String canal; // pedidosya | whatsapp | manual | otro
  final String modo; // rapido | productos
  final String? descripcion;

  final List<Map<String, dynamic>> items; // mismo modelo que ventas normales
  final List<Map<String, dynamic>> pagos;

  final double total;
  final double totalEfectivo;
  final double totalDigital;
  final double totalTransferencia;

  final String usuario;
  final String? observaciones;

  VentaExterna({
    required this.id,
    required this.fecha,
    required this.canal,
    required this.modo,
    required this.items,
    required this.pagos,
    required this.total,
    required this.totalEfectivo,
    required this.totalDigital,
    required this.totalTransferencia,
    required this.usuario,
    this.descripcion,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    return {
      'fecha': Timestamp.fromDate(fecha),
      'canal': canal,
      'modo': modo,
      'descripcion': descripcion,
      'items': items,
      'pagos': pagos,
      'total': total,
      'totalEfectivo': totalEfectivo,
      'totalDigital': totalDigital,
      'totalTransferencia': totalTransferencia,
      'usuario': usuario,
      'observaciones': observaciones,
      'creadoEn': Timestamp.now(),
    };
  }

  static VentaExterna fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VentaExterna(
      id: doc.id,
      fecha: (data['fecha'] as Timestamp).toDate(),
      canal: data['canal'],
      modo: data['modo'],
      descripcion: data['descripcion'],
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      pagos: List<Map<String, dynamic>>.from(data['pagos'] ?? []),
      total: (data['total'] as num).toDouble(),
      totalEfectivo: (data['totalEfectivo'] as num?)?.toDouble() ?? 0,
      totalDigital: (data['totalDigital'] as num?)?.toDouble() ?? 0,
      totalTransferencia:
          (data['totalTransferencia'] as num?)?.toDouble() ?? 0,
      usuario: data['usuario'],
      observaciones: data['observaciones'],
    );
  }
}