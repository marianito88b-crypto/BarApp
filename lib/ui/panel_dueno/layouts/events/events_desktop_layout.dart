import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/events/admin_event_card.dart';
import '../../widgets/events/modals/event_editor_dialog.dart';

/// Layout desktop para la pantalla de gestión de eventos
/// 
/// Optimizado para pantallas muy anchas con una galería de anuncios profesional
class EventsDesktopLayout extends StatelessWidget {
  final String placeId;
  final Stream<QuerySnapshot> eventsStream;
  final Function(String) onDeleteEvent;

  const EventsDesktopLayout({
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

        // Calculamos el maxCrossAxisExtent dinámicamente según el ancho de pantalla
        // Para pantallas muy anchas (>1400px), usamos un tamaño más grande para galería pro
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            double maxCrossAxisExtent;
            
            if (screenWidth > 1400) {
              // Pantallas muy anchas: galería profesional con tarjetas más grandes
              maxCrossAxisExtent = 450;
            } else if (screenWidth > 1000) {
              // Pantallas grandes: tamaño estándar
              maxCrossAxisExtent = 400;
            } else {
              // Pantallas medianas: tamaño compacto
              maxCrossAxisExtent = 350;
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: maxCrossAxisExtent,
                childAspectRatio: 1.6,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
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
      },
    );
  }
}
