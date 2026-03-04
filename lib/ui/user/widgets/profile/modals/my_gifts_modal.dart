import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:barapp/services/barpoints_service.dart';
import 'package:barapp/services/notification_service.dart';
import 'package:barapp/ui/user/bar_points_detail_screen.dart';

/// Modal para "Mis Regalos": muestra código para copiar si tiene canje activo,
/// o CTA para canjear BarPoints si no tiene.
class MyGiftsModal extends StatefulWidget {
  final String userId;

  const MyGiftsModal({super.key, required this.userId});

  static void show(BuildContext context, String userId) {
    NotificationService.clearBadge();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MyGiftsModal(userId: userId),
    );
  }

  @override
  State<MyGiftsModal> createState() => _MyGiftsModalState();
}

class _MyGiftsModalState extends State<MyGiftsModal> {
  late final Future<String> _collectionFuture;

  @override
  void initState() {
    super.initState();
    _collectionFuture = _resolveCollection();
  }

  Future<String> _resolveCollection() async {
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.userId)
        .get();
    return snap.exists ? 'usuarios' : 'users';
  }

  static bool _esCuponValido(Map<String, dynamic> data) {
    final now = Timestamp.now();
    final fechaVenc = data['fechaVencimiento'] as Timestamp?;
    final validoHasta = data['validoHasta'] as Timestamp?;
    if (fechaVenc != null) return fechaVenc.compareTo(now) > 0;
    if (validoHasta != null) return validoHasta.compareTo(now) > 0;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.purpleAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Mis Regalos",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Cupones y códigos de descuento",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            Flexible(
              child: FutureBuilder<String>(
                future: _collectionFuture,
                builder: (context, colSnap) {
                  if (!colSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.purpleAccent),
                      ),
                    );
                  }
                  final collection = colSnap.data!;
                  final userRef = FirebaseFirestore.instance
                      .collection(collection)
                      .doc(widget.userId);
                  return StreamBuilder<QuerySnapshot>(
                    stream: userRef
                        .collection('mis_cupones')
                        .where('usado', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.purpleAccent,
                            ),
                          ),
                        );
                      }
                      final docs = snapshot.data!.docs;
                      final cupones = docs
                          .where((d) => _esCuponValido(
                                d.data() as Map<String, dynamic>,
                              ))
                          .toList();

                      if (cupones.isEmpty) {
                        return _EmptyGiftsState(
                          userId: widget.userId,
                          onCanjearTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BarPointsDetailScreen(userId: widget.userId),
                              ),
                            );
                          },
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        shrinkWrap: true,
                        children: cupones
                            .map((doc) => _buildCouponTile(
                                  context,
                                  doc.data() as Map<String, dynamic>,
                                ))
                            .toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponTile(BuildContext context, Map<String, dynamic> data) {
    final codigo = data['codigo'] as String? ?? 'SIN CÓDIGO';
    final descripcion =
        data['descripcion'] as String? ?? 'Cupón de regalo';
    final descuento =
        (data['descuentoPorcentaje'] as num?)?.toDouble() ?? 10.0;
    final esBarpoints = data['origenBarpoints'] == true;
    final venueName =
        data['venueName'] as String? ?? data['placeName'] as String? ?? '';
    final fechaVenc =
        (data['fechaVencimiento'] as Timestamp?)?.toDate();
    final validoHasta = (data['validoHasta'] as Timestamp?)?.toDate();

    final String mensajePrincipal = esBarpoints
        ? descripcion
        : (venueName.isNotEmpty
            ? '¡$venueName te premia por ser un cliente destacado!'
            : descripcion);
    final String subtituloEmisor = !esBarpoints && venueName.isNotEmpty
        ? 'Regalo de: $venueName'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esBarpoints
              ? Colors.greenAccent.withValues(alpha: 0.4)
              : Colors.purpleAccent.withValues(alpha: 0.3),
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
                  color: esBarpoints
                      ? Colors.greenAccent.withValues(alpha: 0.2)
                      : Colors.purpleAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  esBarpoints ? Icons.workspace_premium : Icons.card_giftcard,
                  color: esBarpoints ? Colors.greenAccent : Colors.purpleAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtituloEmisor.isNotEmpty)
                      Text(
                        subtituloEmisor,
                        style: TextStyle(
                          color: (esBarpoints
                                  ? Colors.greenAccent
                                  : Colors.purpleAccent)
                              .withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    if (subtituloEmisor.isNotEmpty) const SizedBox(height: 2),
                    Text(
                      mensajePrincipal,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "${descuento.toInt()}% de descuento",
                      style: TextStyle(
                        color: esBarpoints
                            ? Colors.greenAccent
                            : Colors.purpleAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: esBarpoints
                      ? Colors.greenAccent.withValues(alpha: 0.2)
                      : Colors.purpleAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${descuento.toInt()}% OFF",
                  style: TextStyle(
                    color: esBarpoints ? Colors.greenAccent : Colors.purpleAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer_rounded,
                  color: esBarpoints ? Colors.greenAccent : Colors.purpleAccent,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    codigo,
                    style: TextStyle(
                      color: esBarpoints ? Colors.greenAccent : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      try {
                        await Clipboard.setData(ClipboardData(text: codigo));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text("¡Código copiado! Usalo en el checkout."),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF2C2C2C),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Error al copiar"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (esBarpoints)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                "Válido 24hs • Usalo en locales adheridos a BarPoints",
                style: TextStyle(
                  color: Colors.greenAccent.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
            )
          else ...[
            if (venueName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.store_rounded,
                      size: 14,
                      color: Colors.purpleAccent.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Válido exclusivamente en este local",
                      style: TextStyle(
                        color: Colors.purpleAccent.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (fechaVenc != null || validoHasta != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "Válido hasta: ${DateFormat('dd/MM/yy').format((fechaVenc ?? validoHasta)!)}",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _EmptyGiftsState extends StatelessWidget {
  final String userId;
  final VoidCallback onCanjearTap;

  const _EmptyGiftsState({
    required this.userId,
    required this.onCanjearTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: BarPointsService.obtenerBarPoints(userId),
      builder: (context, snap) {
        final puntos = snap.data ?? 0;
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                size: 56,
                color: Colors.purpleAccent.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                "Canjeá tus BarPoints por regalos",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                puntos > 0
                    ? "Tenés $puntos puntos acumulados. Canjealos por descuentos."
                    : "Acumulá puntos con tus pedidos y canjealos por descuentos exclusivos.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCanjearTap,
                icon: const Icon(Icons.stars_rounded),
                label: const Text("Ver BarPoints y canjear"),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
