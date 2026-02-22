
class VentaExterna {
  final String placeId;
  final DateTime fecha;
  final String canal; // pedidosya | whatsapp | telefono | otro
  final double total;
  final List<Map<String, dynamic>> pagos;
  final List<Map<String, dynamic>> items; // vacío si es rápida
  final String? nota;
  final bool externa;

  VentaExterna({
    required this.placeId,
    required this.fecha,
    required this.canal,
    required this.total,
    required this.pagos,
    this.items = const [],
    this.nota,
    this.externa = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha,
      'canal': canal,
      'total': total,
      'pagos': pagos,
      'items': items,
      'nota': nota,
      'externa': true,
      'origen': 'externa', // 🔥 clave para filtros futuros
    };
  }
}