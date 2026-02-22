import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Widget que muestra un indicador de estrellas del cliente
/// 
/// Busca la reputación del cliente en su perfil y muestra las estrellas promedio
class ClientStarsIndicator extends StatelessWidget {
  final String userId;

  const ClientStarsIndicator({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _getUserRating(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final reputacion = userData?['reputacion_cliente'] as Map<String, dynamic>?;
        final promedioEstrellas = (reputacion?['promedioEstrellas'] as num?)?.toDouble() ?? 0.0;

        if (promedioEstrellas == 0.0) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 4),
            const Icon(
              Icons.star,
              color: Colors.orangeAccent,
              size: 14,
            ),
            const SizedBox(width: 2),
            Text(
              promedioEstrellas.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<DocumentSnapshot> _getUserRating() async {
    // Intentar primero en 'users'
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!doc.exists) {
      // Si no existe, intentar en 'usuarios'
      doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();
    }

    return doc;
  }
}
