import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Banner que muestra los límites de notificaciones disponibles
class NotificationLimitsBanner extends StatefulWidget {
  final String placeId;

  const NotificationLimitsBanner({
    super.key,
    required this.placeId,
  });

  @override
  State<NotificationLimitsBanner> createState() => _NotificationLimitsBannerState();
}

class _NotificationLimitsBannerState extends State<NotificationLimitsBanner> {
  late final Stream<DocumentSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos al LOCAL para ver si tiene límites custom o plan especial
    return StreamBuilder<DocumentSnapshot>(
      stream: _stream,
      builder: (context, placeSnap) {
        // Valores por defecto
        int limitGlobal = 1;
        int limitFollowers = 1;

        if (placeSnap.hasData && placeSnap.data!.exists) {
          final data = placeSnap.data!.data() as Map<String, dynamic>;
          final plan = data['plan'] ?? 'basic';
          final customLimits =
              data['customLimits'] as Map<String, dynamic>? ?? {};

          // 1. Calculamos base según plan
          int baseGlobal = (plan == 'basic_plus') ? 2 : 1;

          // 2. Aplicamos Custom Limits si existen (LÓGICA FLEXIBLE)
          limitGlobal = customLimits['global'] is int
              ? customLimits['global']
              : baseGlobal;
          limitFollowers = customLimits['followers'] is int
              ? customLimits['followers']
              : 1;
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            children: [
              LimitRow(
                placeId: widget.placeId,
                type: 'global',
                label: "Notificación GLOBAL (Todos los usuarios)",
                limitReal: limitGlobal, // 🔥 PASAMOS EL LÍMITE CALCULADO
                icon: FontAwesomeIcons.earthAmericas,
                periodo: "semanal",
              ),
              const SizedBox(height: 10),
              LimitRow(
                placeId: widget.placeId,
                type: 'followers',
                label: "Notificación SEGUIDORES (Tus fans)",
                limitReal: limitFollowers, // 🔥 PASAMOS EL LÍMITE CALCULADO
                icon: FontAwesomeIcons.heart,
                periodo: "diario",
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fila individual que muestra el límite de un tipo de notificación
class LimitRow extends StatefulWidget {
  final String placeId;
  final String type;
  final String label;
  final int limitReal; // 🔥 RECIBIMOS EL DATO REAL
  final IconData icon;
  final String periodo;

  const LimitRow({
    super.key,
    required this.placeId,
    required this.type,
    required this.label,
    required this.limitReal,
    required this.icon,
    required this.periodo,
  });

  @override
  State<LimitRow> createState() => _LimitRowState();
}

class _LimitRowState extends State<LimitRow> {
  late final Stream<DocumentSnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('notification_limits')
        .doc('${widget.placeId}_${widget.type}')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _stream,
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final int used = data?['count'] ?? 0;

        // Cálculo visual
        final int remaining = (widget.limitReal - used).clamp(0, widget.limitReal);

        Color color = remaining > 0 ? Colors.greenAccent : Colors.grey;
        if (remaining == 0) color = Colors.white24;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          remaining > 0 ? "Disponibles: $remaining" : "Agotado",
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          " / ${widget.limitReal} (${widget.periodo})", // Muestra el total real (ej: / 10)
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (remaining > 0)
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
        );
      },
    );
  }
}
