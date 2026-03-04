import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Widget que muestra la barra de estado del monitor de cocina
/// 
/// Muestra el número de comandas pendientes con colores dinámicos:
/// - Verde: Sin comandas (COCINA AL DÍA)
/// - Naranja: 1-5 comandas pendientes
/// - Rojo: Más de 5 comandas pendientes
class KitchenStatusBar extends StatefulWidget {
  final String placeId;

  const KitchenStatusBar({
    super.key,
    required this.placeId,
  });

  @override
  State<KitchenStatusBar> createState() => _KitchenStatusBarState();
}

class _KitchenStatusBarState extends State<KitchenStatusBar> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection("places")
        .doc(widget.placeId)
        .collection("orders")
        .where('estado', whereIn: ['en_preparacion', 'pendiente'])
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (c, s) {
        final count = s.data?.docs.length ?? 0;
        Color badgeColor = count > 5 ? Colors.redAccent : (count > 0 ? Colors.orangeAccent : Colors.green);
        Color textColor = count > 0 ? Colors.black : Colors.white;

        return Container(
          width: double.infinity,
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.only(bottom: 10),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    count == 0 ? Icons.check : Icons.local_fire_department,
                    size: 16,
                    color: textColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count == 0 ? "COCINA AL DÍA" : "$count PENDIENTES",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
