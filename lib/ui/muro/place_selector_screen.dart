import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlaceSelectorScreen extends StatefulWidget {
  const PlaceSelectorScreen({super.key});

  @override
  State<PlaceSelectorScreen> createState() => _PlaceSelectorScreenState();
}

class _PlaceSelectorScreenState extends State<PlaceSelectorScreen> {
  // Stream para obtener los bares. 
  final Stream<QuerySnapshot> _placesStream = FirebaseFirestore.instance
      .collection('places') // 👈 ¿Es 'places' tu colección?
      .orderBy('name')       // 👈 ¿El campo es 'name'?
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar un Lugar'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot>(
        stream: _placesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los lugares', style: TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay lugares para mostrar', style: TextStyle(color: Colors.white70)),
            );
          }

          final places = snapshot.data!.docs;

          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final doc = places[index];
           
              final data = doc.data() as Map<String, dynamic>;
              final placeName = data['name'] ?? 'Nombre no disponible';
              final placeId = doc.id;

            
              final placeImageUrl = data['profileImageUrl'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF222222),
                  backgroundImage: placeImageUrl.isNotEmpty
                      ? NetworkImage(placeImageUrl)
                      : null,
                  child: placeImageUrl.isEmpty
                      ? const Icon(Icons.place, color: Colors.white70)
                      : null,
                ),
                title: Text(placeName, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  // 3. Al tocar, "devuelve" los datos a la pantalla anterior
                  Navigator.pop(
                    context,
                    {
                      'id': placeId,
                      'name': placeName,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}