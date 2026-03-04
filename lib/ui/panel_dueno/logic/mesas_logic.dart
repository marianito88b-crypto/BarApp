import 'package:cloud_firestore/cloud_firestore.dart';

/// Mixin que proporciona la lógica de negocio para la gestión de mesas.
/// 
/// Este mixin maneja:
/// - Comparación natural de nombres (para ordenamiento inteligente)
/// - Agrupación de mesas por sector
mixin MesasLogicMixin {
  /// Compara dos strings de forma natural, respetando números dentro del texto.
  /// 
  /// Ejemplo: "Mesa 2" < "Mesa 10" (en lugar de "Mesa 10" < "Mesa 2")
  /// 
  /// Retorna:
  /// - Valor negativo si `a` < `b`
  /// - Cero si `a` == `b`
  /// - Valor positivo si `a` > `b`
  int compareNatural(String a, String b) {
    final RegExp regExp = RegExp(r'(\d+)|(\D+)');
    final Iterable<Match> matchesA = regExp.allMatches(a);
    final Iterable<Match> matchesB = regExp.allMatches(b);
    final Iterator<Match> iteratorA = matchesA.iterator;
    final Iterator<Match> iteratorB = matchesB.iterator;

    while (iteratorA.moveNext() && iteratorB.moveNext()) {
      final String partA = iteratorA.current.group(0)!;
      final String partB = iteratorB.current.group(0)!;
      final int? numA = int.tryParse(partA);
      final int? numB = int.tryParse(partB);
      if (numA != null && numB != null) {
        final int compare = numA.compareTo(numB);
        if (compare != 0) return compare;
      } else {
        final int compare = partA.compareTo(partB);
        if (compare != 0) return compare;
      }
    }
    return a.length.compareTo(b.length);
  }

  /// Normaliza el nombre del sector para consistencia (Patio/patio -> Patio).
  static String _normalizeSectorKey(String s) {
    if (s.isEmpty) return s;
    return s.trim().split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
  }

  /// Agrupa documentos de Firebase por su campo 'sector'.
  /// 
  /// Si un documento no tiene campo 'sector' o está vacío, se agrupa bajo la clave 'Sin Sector'.
  /// Nota: En la UI se convierte 'Sin Sector' a 'General' para mejor UX.
  /// Usa normalización para que 'Patio' y 'patio' se traten como el mismo sector.
  Map<String, List<DocumentSnapshot>> agruparPorSector(
      List<DocumentSnapshot> docs) {
    final Map<String, List<DocumentSnapshot>> grupos = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>?;
      final String? sectorRaw = data?['sector']?.toString().trim();
      final String sector = (sectorRaw == null || sectorRaw.isEmpty)
          ? 'Sin Sector'
          : _normalizeSectorKey(sectorRaw);

      if (!grupos.containsKey(sector)) {
        grupos[sector] = [];
      }
      grupos[sector]!.add(doc);
    }

    return grupos;
  }

  /// Marca como cancelado por mozo los pedidos que estaban en cocina para esta mesa.
  /// Debe llamarse cuando el mozo libera/resetea una mesa con pedidos pendientes.
  static Future<void> cancelarOrdenesPendientesCocina({
    required String placeId,
    required String mesaId,
  }) async {
    final ordersSnap = await FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('orders')
        .where('mesaId', isEqualTo: mesaId)
        .where('estado', whereIn: ['pendiente', 'en_preparacion'])
        .get();
    if (ordersSnap.docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in ordersSnap.docs) {
      batch.update(doc.reference, {
        'estado': 'cancelado_por_mozo',
        'canceladoAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
