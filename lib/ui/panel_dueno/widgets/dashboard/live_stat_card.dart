import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:barapp/ui/panel_dueno/sections/delivery_orders_screen.dart';
import 'package:barapp/ui/panel_dueno/sections/mesas_mobile.dart';

/// Tarjeta de estadística en vivo (mesas ocupadas, pedidos web).
class LiveStatCard extends StatefulWidget {
  final String placeId;
  final String type;
  final bool isDesktop;
  final Function(String tabName)? onNavigateToTab;

  const LiveStatCard({
    super.key,
    required this.placeId,
    required this.type,
    this.isDesktop = false,
    this.onNavigateToTab,
  });

  @override
  State<LiveStatCard> createState() => _LiveStatCardState();
}

class _LiveStatCardState extends State<LiveStatCard> {
  Stream<QuerySnapshot>? _mainStream;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'mesas_ocupadas') {
      _mainStream = FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("mesas")
          .snapshots();
    } else if (widget.type == 'pedidos_web') {
      _mainStream = FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("orders")
          .where('estado', whereIn: ['pendiente', 'confirmado', 'en_preparacion', 'en_camino'])
          .where('origen', isEqualTo: 'app')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;
    Color color;
    VoidCallback? onTap;

    if (widget.type == 'mesas_ocupadas') {
      label = "Mesas";
      icon = Icons.table_restaurant;
      color = Colors.orangeAccent;
      onTap = () {
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!('Mesas');
        } else {
          // Fallback: navegación tradicional si no hay callback
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MesasMobile(placeId: widget.placeId),
            ),
          );
        }
      };
    } else if (widget.type == 'pedidos_web') {
      label = "Pedidos Web";
      icon = Icons.delivery_dining;
      color = Colors.greenAccent;
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeliveryOrdersScreen(placeId: widget.placeId),
            ),
          );
    } else {
      return const SizedBox();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _mainStream,
      builder: (context, snap) {
        if (widget.type == 'mesas_ocupadas') {
          return _buildMesasCard(context, snap, color, icon, label, onTap);
        }

        // Lógica original para pedidos_web
        final count = snap.data?.docs.length ?? 0;

        int attentionCount = 0;
        if (snap.hasData && widget.type == 'pedidos_web') {
          attentionCount = snap.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final estado = data['estado'];
            return estado == 'pendiente' || estado == 'confirmado';
          }).length;
        }

        final displayColor = attentionCount > 0 ? Colors.orangeAccent : color;
        final displayIcon =
            attentionCount > 0 ? Icons.notifications_active : icon;
        final displayLabel = attentionCount > 0 ? "¡REVISAR!" : label;

        Widget content = Container(
          height: widget.isDesktop ? 140 : null,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: attentionCount > 0
                ? Colors.orangeAccent.withValues(alpha: 0.1)
                : const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: displayColor.withValues(alpha: attentionCount > 0 ? 0.8 : 0.3),
              width: attentionCount > 0 ? 2 : 1,
            ),
            boxShadow: [
              if (count > 0 && widget.type == 'pedidos_web')
                BoxShadow(
                  color: displayColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: widget.isDesktop
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: displayColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(displayIcon, color: displayColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            displayLabel,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "$count",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: displayColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(displayIcon, color: displayColor, size: 20),
                        ),
                        if (count > 0)
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: displayColor,
                            child: Text(
                              "$count",
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (count == 0)
                      Text(
                        "$count",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    Text(
                      attentionCount > 0 ? "¡NUEVOS!" : label,
                      style: TextStyle(
                        color: attentionCount > 0
                            ? Colors.orangeAccent
                            : Colors.white54,
                        fontSize: 12,
                        fontWeight:
                            attentionCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
        );

        if (onTap != null) {
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: content,
          );
        }
        return content;
      },
    );
  }

  Widget _buildMesasCard(
    BuildContext context,
    AsyncSnapshot<QuerySnapshot> snap,
    Color color,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    int total = 0;
    int ocupadas = 0;
    int libres = 0;

    if (snap.hasData) {
      total = snap.data!.docs.length;
      for (var doc in snap.data!.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final estado = data['estado'] ?? 'libre';
        if (estado == 'libre') {
          libres++;
        } else {
          ocupadas++; // incluye: ocupada, reservada, cualquier otro estado no-libre
        }
      }
    }

    // Las mesas reservadas ya están dentro de ocupadas (mismo loop).
    // NO sumar reservadas de nuevo — hacerlo causaba doble conteo.
    final int totalEnUso = ocupadas;

    Widget content = Container(
      height: widget.isDesktop ? 140 : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: widget.isDesktop
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MesaCounter(label: "Total", count: total, color: Colors.white70),
                    _MesaCounter(label: "Ocupadas", count: totalEnUso, color: Colors.orangeAccent),
                    _MesaCounter(label: "Libres", count: libres, color: Colors.greenAccent),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MesaRowMobile(label: "Total", count: total, color: Colors.white70),
                const SizedBox(height: 6),
                _MesaRowMobile(label: "Ocupadas", count: totalEnUso, color: Colors.orangeAccent),
                const SizedBox(height: 6),
                _MesaRowMobile(label: "Libres", count: libres, color: Colors.greenAccent),
              ],
            ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }
    return content;
  }
}

class _MesaCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MesaCounter({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "$count",
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _MesaRowMobile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MesaRowMobile({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 11,
          ),
        ),
        Text(
          "$count",
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
