import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/events/admin_event_card.dart';
import '../../widgets/events/modals/event_editor_dialog.dart';

/// Layout móvil para la pantalla de gestión de eventos
class EventsMobileLayout extends StatelessWidget {
  final String placeId;
  final Stream<QuerySnapshot> eventsStream;
  final Function(String) onDeleteEvent;

  const EventsMobileLayout({
    super.key,
    required this.placeId,
    required this.eventsStream,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: eventsStream,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint("ERROR FIREBASE: ${snap.error}");
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Error de carga (Posible falta de índice):\n${snap.error}",
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 70, color: Colors.white10),
                SizedBox(height: 16),
                Text(
                  "No tienes eventos ni promos activas.",
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1.6,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: docs.length,
          itemBuilder: (_, i) => AdminEventCard(
            doc: docs[i],
            onEdit: () => EventEditorDialog.show(
              context: context,
              placeId: placeId,
              doc: docs[i],
            ),
            onDelete: () => onDeleteEvent(docs[i].id),
          ),
        );
      },
    );
  }
}
