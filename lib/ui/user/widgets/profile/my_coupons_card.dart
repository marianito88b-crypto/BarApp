import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Widget que muestra los cupones/regalos del usuario
class MyCouponsCard extends StatefulWidget {
  final String? userId;

  const MyCouponsCard({
    super.key,
    this.userId,
  });

  @override
  State<MyCouponsCard> createState() => _MyCouponsCardState();
}

class _MyCouponsCardState extends State<MyCouponsCard> {
  late final String? _currentUserId;
  late final Future<String>? _collectionFuture;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _collectionFuture = _currentUserId != null
        ? _resolveUserCollection(_currentUserId)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) return const SizedBox.shrink();

    return FutureBuilder<String>(
      future: _collectionFuture,
      builder: (context, colSnap) {
        if (!colSnap.hasData) return const SizedBox.shrink();
        final collection = colSnap.data!;
        return StreamBuilder<QuerySnapshot>(
          stream: _getCouponsStream(_currentUserId, collection),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final todos = snapshot.data!.docs;
            final cupones = todos
                .where((d) => _esCuponValido(d.data() as Map<String, dynamic>))
                .toList();
            if (cupones.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.purpleAccent.withValues(alpha: 0.2),
                    Colors.purpleAccent.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.purpleAccent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_giftcard,
                          color: Colors.purpleAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Mis Regalos",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...cupones.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCouponItem(context, data);
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _resolveUserCollection(String userId) async {
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    return snap.exists ? 'usuarios' : 'users';
  }

  Stream<QuerySnapshot> _getCouponsStream(String userId, String collection) {
    final userRef = FirebaseFirestore.instance.collection(collection).doc(userId);
    return userRef.collection('mis_cupones')
        .where('usado', isEqualTo: false)
        .snapshots();
  }

  static bool _esCuponValido(Map<String, dynamic> data) {
    final now = Timestamp.now();
    final fechaVenc = data['fechaVencimiento'] as Timestamp?;
    final validoHasta = data['validoHasta'] as Timestamp?;
    if (fechaVenc != null) return fechaVenc.compareTo(now) > 0;
    if (validoHasta != null) return validoHasta.compareTo(now) > 0;
    return true;
  }

  Widget _buildCouponItem(BuildContext context, Map<String, dynamic> data) {
    final codigo = data['codigo'] ?? 'SIN CÓDIGO';
    final placeName = data['placeName'] ?? 'Local';
    final descuento = (data['descuentoPorcentaje'] as num?)?.toDouble() ?? 10.0;
    final descripcion = data['descripcion'] ?? 'Cupón de regalo';
    final esBarpoints = data['origenBarpoints'] == true;
    final fechaVenc = (data['fechaVencimiento'] as Timestamp?)?.toDate();
    final validoHasta = (data['validoHasta'] as Timestamp?)?.toDate();
    final codigoVerde = esBarpoints; // BarPoints activos = verde

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purpleAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeName,
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (esBarpoints)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Tenés 24hs para usar este código.',
                          style: TextStyle(
                            color: Colors.greenAccent.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${descuento.toInt()}% OFF",
                  style: const TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer,
                  color: Colors.purpleAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    codigo,
                    style: TextStyle(
                      color: codigoVerde ? Colors.greenAccent : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    color: Colors.white54,
                    onPressed: () async {
                      try {
                        await Clipboard.setData(ClipboardData(text: codigo));
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "¡Código copiado! 📋",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              duration: Duration(seconds: 1),
                              backgroundColor: Color(0xFF2C2C2C),
                              behavior: SnackBarBehavior.floating,
                              margin: EdgeInsets.only(
                                bottom: 20,
                                left: 16,
                                right: 16,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Error copiando código: $e');
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: const Text("Error al copiar código"),
                              duration: const Duration(seconds: 1),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    tooltip: "Copiar código",
                  ),
                ),
              ],
            ),
          ),
          if (fechaVenc != null || validoHasta != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Válido hasta: ${DateFormat('dd/MM/yy HH:mm').format((fechaVenc ?? validoHasta)!)}",
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
