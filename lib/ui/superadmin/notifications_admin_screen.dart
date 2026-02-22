import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsAdminScreen extends StatelessWidget {
  const NotificationsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔔 Control de Notificaciones'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notification_limits')
            .snapshots(),
        builder: (context, snap) {
  // 1. Cargando
  if (snap.connectionState == ConnectionState.waiting) {
    return const Center(child: CircularProgressIndicator());
  }

  // 2. Error real
  if (snap.hasError) {
    return Center(
      child: Text(
        'Error cargando notificaciones\n${snap.error}',
        style: const TextStyle(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }

  // 3. Sin datos
  if (!snap.hasData || snap.data!.docs.isEmpty) {
    return const Center(
      child: Text(
        'No hay registros de notificaciones aún.',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay registros de notificaciones aún.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              final placeId = data['placeId'] ?? '';
              final type = data['type'] ?? 'global';
              final plan = data['plan'] ?? 'basic';
              final count = data['count'] ?? 0;
              final allowOverride = data['allowOverride'] == true;

              final limit = _getLimit(plan, type);
              final remaining = limit - count;

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: allowOverride
                        ? Colors.amber
                        : remaining <= 0
                            ? Colors.redAccent
                            : Colors.white10,
                  ),
                ),
                child: ListTile(
                  title: Text(
  '🏪 ${data['placeName'] ?? placeId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Tipo: $type | Plan: $plan',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Usadas: $count / $limit  →  Restantes: $remaining',
                        style: TextStyle(
                          color: remaining <= 0
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: allowOverride,
                    activeThumbColor: Colors.amber,
                    onChanged: (value) async {
                      await FirebaseFirestore.instance
                          .collection('notification_limits')
                          .doc(doc.id)
                          .update({'allowOverride': value});

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? '🟡 Override activado'
                                  : '🔒 Override desactivado',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _getLimit(String plan, String type) {
    if (type == 'followers') return 1;

    switch (plan) {
      case 'basic_plus':
        return 2;
      case 'pro':
        return 5;
      case 'basic':
      default:
        return 1;
    }
  }
}