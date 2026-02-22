import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'place_detail_admin_screen.dart';

class ManagePlacesScreen extends StatelessWidget {
  const ManagePlacesScreen({super.key});

  // Lógica centralizada: ¿Está activo el periodo de prueba?
  bool _isTrialActive(dynamic fechaInicio) {
    if (fechaInicio == null) return false;
    if (fechaInicio is! Timestamp) return false;
    DateTime inicio = fechaInicio.toDate();
    DateTime fin = inicio.add(const Duration(days: 30));
    return DateTime.now().isBefore(fin);
  }

  @override
  Widget build(BuildContext context) {
    // 1. StreamBuilder PRIMERO para tener los datos antes de armar los Tabs
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('places').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final docs = snap.data!.docs;

        // 2. Filtramos las listas en memoria
        final activeDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _isTrialActive(data['fechaInicioPrueba']);
        }).toList();

        final inactiveDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return !_isTrialActive(data['fechaInicioPrueba']);
        }).toList();

        // 3. Construimos la UI con los contadores calculados
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('🏪 Gestión de Bares'),
              backgroundColor: Colors.black,
              bottom: TabBar(
                indicatorColor: Colors.orangeAccent,
                labelColor: Colors.orangeAccent,
                unselectedLabelColor: Colors.white54,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16),
                        const SizedBox(width: 8),
                        Text('Activos (${activeDocs.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text('Inactivos (${inactiveDocs.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PlacesList(places: activeDocs, isTrialList: true),
                _PlacesList(places: inactiveDocs, isTrialList: false),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlacesList extends StatelessWidget {
  final List<QueryDocumentSnapshot> places;
  final bool isTrialList;

  const _PlacesList({required this.places, required this.isTrialList});

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isTrialList ? Icons.store : Icons.no_meeting_room, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              isTrialList ? 'No hay bares en prueba' : 'No hay bares vencidos',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final doc = places[i];
        final data = doc.data() as Map<String, dynamic>;
        
        final name = data['name'] ?? data['nombre'] ?? 'Sin nombre';
        final coverImage = data['coverImageUrl'];

        // Lógica visual simple para la lista
        // Si está en la lista de inactivos, asumimos que requiere atención
        final statusColor = isTrialList ? Colors.green : Colors.redAccent;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Pasamos solo el ID para que la otra pantalla cargue datos frescos
                builder: (_) => PlaceDetailAdminScreen(placeId: doc.id), 
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[900],
                backgroundImage: coverImage != null ? NetworkImage(coverImage) : null,
                child: coverImage == null ? const Icon(Icons.store, color: Colors.white54) : null,
              ),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(
                isTrialList ? '✅ En periodo de prueba' : '⚠️ Periodo de prueba finalizado',
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
            ),
          ),
        );
      },
    );
  }
}