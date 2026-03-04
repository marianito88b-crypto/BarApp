import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/caja/caja_history_card.dart';

class HistorialCajaScreen extends StatefulWidget {
  final String placeId;

  const HistorialCajaScreen({super.key, required this.placeId});

  @override
  State<HistorialCajaScreen> createState() => _HistorialCajaScreenState();
}

class _HistorialCajaScreenState extends State<HistorialCajaScreen> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('places').doc(widget.placeId)
        .collection('caja_sesiones')
        .orderBy('fecha_apertura', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        title: const Text("Historial de Cierres", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF151515),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.white10),
                  SizedBox(height: 10),
                  Text("No hay historial de cajas aún.", style: TextStyle(color: Colors.white24)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return CajaHistoryCard(data: data);
            },
          );
        },
      ),
    );
  }
}