import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/staff/staff_empty_state.dart';
import '../../widgets/staff/staff_member_tile.dart';
import '../../widgets/staff/modals/add_member_dialog.dart';

/// Layout móvil para la gestión de staff
class StaffMobileLayout extends StatelessWidget {
  final String placeId;
  final Stream<QuerySnapshot> staffStream;
  final Function(String uid, String? email) onDelete;

  const StaffMobileLayout({
    super.key,
    required this.placeId,
    required this.staffStream,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_add_staff_mobile",
        onPressed: () => AddMemberDialog.show(context, placeId),
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.person_add, color: Colors.black),
        label: const Text(
          "Agregar",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: staffStream,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const StaffEmptyState(
              message: "Tu equipo está vacío.\nInvita mozos o cocineros.",
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final uid = docs[i].id;

              return StaffMemberTile(
                uid: uid,
                email: data['email'] ?? 'Usuario',
                rol: data['rol'],
                placeId: placeId,
                staffData: data,
                onDelete: () => onDelete(uid, data['email']),
              );
            },
          );
        },
      ),
    );
  }
}
