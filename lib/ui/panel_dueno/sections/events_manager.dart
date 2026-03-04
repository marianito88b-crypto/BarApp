import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/events/notification_limits_banner.dart';
import '../widgets/events/modals/event_editor_dialog.dart';
import '../logic/events_logic.dart';
import '../layouts/events/events_mobile_layout.dart';
import '../layouts/events/events_desktop_layout.dart';

class EventsManagerScreen extends StatefulWidget {
  final String placeId;
  const EventsManagerScreen({super.key, required this.placeId});

  @override
  State<EventsManagerScreen> createState() => _EventsManagerScreenState();
}

class _EventsManagerScreenState extends State<EventsManagerScreen>
    with EventsLogicMixin {
  @override
  String get placeId => widget.placeId;

  late final Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = getEventsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_events_manager",
        onPressed: () => EventEditorDialog.show(
          context: context,
          placeId: placeId,
        ),
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(Icons.event, color: Colors.white),
        label: const Text(
          "Nuevo Evento",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          NotificationLimitsBanner(placeId: placeId),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                return isDesktop
                    ? EventsDesktopLayout(
                        placeId: placeId,
                        eventsStream: _eventsStream,
                        onDeleteEvent: deleteEvent,
                      )
                    : EventsMobileLayout(
                        placeId: placeId,
                        eventsStream: _eventsStream,
                        onDeleteEvent: deleteEvent,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
