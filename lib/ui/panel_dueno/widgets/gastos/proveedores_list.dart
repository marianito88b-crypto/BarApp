import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../sections/proveedor_detalle_screen.dart';

/// Lista de proveedores
class ProveedoresList extends StatefulWidget {
  final String placeId;

  const ProveedoresList({
    super.key,
    required this.placeId,
  });

  @override
  State<ProveedoresList> createState() => _ProveedoresListState();
}

class _ProveedoresListState extends State<ProveedoresList> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('proveedores')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var prov = snapshot.data!.docs[index];

            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProveedorDetalleScreen(
                      placeId: widget.placeId,
                      provId: prov.id,
                      nombre: prov['nombre'],
                    ),
                  ),
                );
              },
              leading: CircleAvatar(
                backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.local_shipping,
                  color: Colors.orangeAccent,
                ),
              ),
              title: Text(
                prov['nombre'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Rubro: ${prov['rubro']}",
                style: const TextStyle(color: Colors.white54),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.white24,
              ),
            );
          },
        );
      },
    );
  }
}
