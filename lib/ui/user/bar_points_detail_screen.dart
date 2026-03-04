import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/barpoints_service.dart';
import '../../utils/barpoints_logic.dart';
import 'widgets/barpoints/historial_row.dart';
import 'widgets/barpoints/medalla_hito.dart';
import 'widgets/barpoints/reward_card.dart';

/// Pantalla de detalle de BarPoints: billetera virtual con historial,
/// educación del programa, grid de canje y bases legales.
class BarPointsDetailScreen extends StatefulWidget {
  final String? userId;

  const BarPointsDetailScreen({
    super.key,
    this.userId,
  });

  @override
  State<BarPointsDetailScreen> createState() => _BarPointsDetailScreenState();
}

class _BarPointsDetailScreenState extends State<BarPointsDetailScreen> {
  late ConfettiController _confettiController;
  late final Future<String>? _resolveCollectionFuture;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _resolveCollectionFuture = uid != null ? _resolveUserCollection(uid) : null;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  static const String _legalText =
      'Los BarPoints son un programa de fidelización de BarApp. '
      'Los puntos no son canjeables por dinero en efectivo. '
      'Los descuentos están sujetos a disponibilidad y condiciones de cada comercio adherido. '
      'Los BarPoints solo son canjeables los días aceptados por el local. Su uso está sujeto a la configuración de cada comercio. '
      'BarApp se reserva el derecho de modificar o cancelar el programa con previo aviso.';

  static const String _avisoDisponibilidad =
      'Los BarPoints solo son canjeables los días aceptados por el local. Su uso está sujeto a la configuración de cada comercio.';

  @override
  Widget build(BuildContext context) {
    final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BarPoints')),
        body: const Center(child: Text('Debes iniciar sesión')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
            title: const Text(
              'BarPoints',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          // ── Contenido ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<String>(
              future: _resolveCollectionFuture,
              builder: (context, colSnap) {
                if (!colSnap.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: Colors.orangeAccent),
                    ),
                  );
                }
                final collection = colSnap.data!;
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(collection)
                      .doc(uid)
                      .snapshots(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return const SizedBox.shrink();
                    }
                    final userData = userSnap.data!.data() as Map<String, dynamic>?;
                    final totalPuntos = (userData?['barPoints'] as num?)?.toInt() ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, totalPuntos),
                        const SizedBox(height: 20),
                        _buildProgressBar(totalPuntos),
                        const SizedBox(height: 20),
                        _buildHookPhrase(),
                        const SizedBox(height: 20),
                        _buildAvisoDisponibilidad(),
                        const SizedBox(height: 32),
                        _buildComoFunciona(),
                        const SizedBox(height: 32),
                        _buildHistorialSection(context, uid, collection),
                        const SizedBox(height: 28),
                        _buildCanjeSection(context, uid, totalPuntos, _confettiController),
                        const SizedBox(height: 28),
                        _buildLegalSection(context),
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                Colors.orangeAccent,
                Colors.deepOrange,
                Colors.amber,
                Colors.yellow,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _resolveUserCollection(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();
    return snap.exists ? 'usuarios' : 'users';
  }

  Widget _buildHeader(BuildContext context, int totalPuntos) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orangeAccent,
            Colors.deepOrange.shade700,
            Colors.orange.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'TUS PUNTOS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalPuntos',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'BarPoints',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            totalPuntos >= BarPointsService.maxBarPoints
                ? '¡Llegaste al tope! Gastá puntos para seguir sumando. 🎉'
                : '¡Estás cada vez más cerca de tu próximo beneficio! 🚀',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int totalPuntos) {
    final niveles = BarPointsService.nivelesCanje.keys.toList()..sort();
    if (totalPuntos >= 500) {
      return _buildProgressBarMaxReached(niveles);
    }
    final progreso = BarPointsLogic.progresoHaciaHito(totalPuntos);
    final textoProgreso = BarPointsLogic.textoProgreso(totalPuntos) ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Progreso al siguiente nivel',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  textoProgreso,
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: niveles.map((pts) {
                final alcanzado = totalPuntos >= pts;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: MedallaHito(
                    puntos: pts,
                    descuento: BarPointsService.nivelesCanje[pts]!,
                    alcanzado: alcanzado,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarMaxReached(List<int> niveles) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¡Nivel máximo alcanzado!',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.diamond, color: Color(0xFF4DD0E1), size: 24),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 1.0,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: niveles.map((pts) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: MedallaHito(
                    puntos: pts,
                    descuento: BarPointsService.nivelesCanje[pts]!,
                    alcanzado: true,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvisoDisponibilidad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.amber.shade400, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _avisoDisponibilidad,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHookPhrase() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified_rounded,
              color: Colors.orangeAccent,
              size: 28,
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Tus puntos equivalen a beneficios reales.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComoFunciona() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cómo funciona',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaso(
            icon: Icons.add_circle_outline_rounded,
            titulo: 'Sumá',
            texto: 'Por cada \$1.000 de compra, ganás 1 punto (al completarse la entrega).',
          ),
          const SizedBox(height: 14),
          _buildPaso(
            icon: Icons.star_rounded,
            titulo: 'Bonificá',
            texto: 'Cada 3 calificaciones que los bares te dejen, sumás 10 puntos extra.',
          ),
          const SizedBox(height: 14),
          _buildPaso(
            icon: Icons.account_balance_wallet_outlined,
            titulo: 'Acumulá',
            texto: 'Tus puntos se guardan en tu perfil.',
          ),
          const SizedBox(height: 14),
          _buildPaso(
            icon: Icons.card_giftcard_rounded,
            titulo: 'Canjeá',
            texto: 'Usalos para obtener descuentos en locales adheridos.',
          ),
        ],
      ),
    );
  }

  Widget _buildPaso({
    required IconData icon,
    required String titulo,
    required String texto,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.orangeAccent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCanjeSection(
    BuildContext context,
    String uid,
    int totalPuntos,
    ConfettiController confettiController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Canjeá tus beneficios',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: BarPointsService.nivelesCanje.entries.map((e) {
              final pts = e.key;
              final desc = e.value;
              final desbloqueado = totalPuntos >= pts;
              return RewardCard(
                puntos: pts,
                descuento: desc,
                desbloqueado: desbloqueado,
                totalPuntos: totalPuntos,
                onCanjear: () => _showCanjeDialog(context, uid, pts, desc, confettiController),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showExitoCanjeDialog(BuildContext context, String codigoCupon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.orangeAccent, size: 28),
            const SizedBox(width: 12),
            const Text('¡Canje exitoso!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tu código de descuento:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orangeAccent, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      codigoCupon,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () async {
                      try {
                        await Clipboard.setData(ClipboardData(text: codigoCupon));
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Código copiado! 📋'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.copy_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.orangeAccent),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Felicidades! Desbloqueaste tu beneficio. Tenés 24hs para usar este código antes de que expire.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              'Podés usarlo en locales adheridos a BarPoints.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          FilledButton.icon(
            onPressed: () async {
              try {
                await Clipboard.setData(ClipboardData(text: codigoCupon));
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Código copiado! 📋'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {}
            },
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar Código'),
            style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _showCanjeDialog(
    BuildContext context,
    String uid,
    int puntos,
    int descuento,
    ConfettiController confettiController,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Confirmar canje?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Seguro que querés canjear $puntos puntos por un $descuento% de descuento?',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Canjear'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final result = await BarPointsService.canjearPuntos(
      userId: uid,
      puntos: puntos,
      descuentoPorcentaje: descuento,
    );

    if (!context.mounted) return;
    if (result['success'] == true) {
      confettiController.play();
      _showExitoCanjeDialog(context, result['codigoCupon'] as String);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error']?.toString() ?? 'Error al canjear'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildHistorialSection(
    BuildContext context,
    String uid,
    String collection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Historial de movimientos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(collection)
              .doc(uid)
              .collection('historial_puntos')
              .orderBy('fecha', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                ),
              );
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aún no tenés movimientos',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cada compra y calificación suma puntos acá',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final concepto = d['concepto'] as String? ?? 'Movimiento';
                final monto = (d['monto'] as num?)?.toInt() ?? 0;
                final fecha = d['fecha'] as Timestamp?;
                return HistorialRow(
                  concepto: concepto,
                  monto: monto,
                  fecha: fecha?.toDate(),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _showLegalModal(context),
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text('Ver bases y condiciones'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bases y condiciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _legalText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

