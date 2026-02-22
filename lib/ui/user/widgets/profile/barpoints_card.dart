import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barapp/services/barpoints_service.dart';
import 'package:barapp/ui/user/bar_points_detail_screen.dart';

/// Tarjeta destacada de BarPoints con efecto glass y sombreado iluminado.
/// Resalta los puntos acumulados sobre el resto de menús.
class BarPointsCard extends StatefulWidget {
  final String? userId;

  const BarPointsCard({
    super.key,
    this.userId,
  });

  @override
  State<BarPointsCard> createState() => _BarPointsCardState();
}

class _BarPointsCardState extends State<BarPointsCard> {
  int _barPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBarPoints();
  }

  Future<void> _loadBarPoints() async {
    final userId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final points = await BarPointsService.obtenerBarPoints(userId);
      if (mounted) {
        setState(() {
          _barPoints = points;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final uid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: uid != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BarPointsDetailScreen(userId: uid),
                    ),
                  )
              : null,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orangeAccent.withValues(alpha: 0.25),
                      Colors.orangeAccent.withValues(alpha: 0.08),
                      Colors.orangeAccent.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orangeAccent.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    // Sombra iluminada exterior (glow)
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.35),
                      blurRadius: 28,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: -2,
                      offset: const Offset(0, 2),
                    ),
                    // Sombra sutil interna
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.orangeAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "BarPoints",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_barPoints puntos",
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: Colors.orangeAccent.withValues(alpha: 0.9),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "Acumulá y canjeá descuentos",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.orangeAccent,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
