// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // 🔥 IMPORTANTE
// Asegúrate de importar tu provider aquí abajo
import '../../providers/blocked_users_provider.dart'; // Chequea esta ruta

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Usuarios Bloqueados", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(_currentUser.uid)
            .collection('blockedUsers') // Esta es la colección correcta
            .orderBy('blockedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Datos
              final String name = data['displayName'] ?? 'Usuario';
              final String? photoUrl = data['photoUrl'];
              final Timestamp? timestamp = data['blockedAt'];
              final String blockedUid = doc.id; 

              String fecha = "-";
              if (timestamp != null) {
                fecha = DateFormat('dd/MM/yyyy').format(timestamp.toDate());
              }

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text("Desde el $fecha", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  trailing: TextButton(
                    onPressed: () => _confirmUnblock(context, blockedUid, name),
                    child: const Text("Desbloquear", style: TextStyle(color: Colors.orangeAccent)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmUnblock(BuildContext context, String uid, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("¿Desbloquear?", style: TextStyle(color: Colors.white)),
        content: Text("¿Quieres quitar el bloqueo a $name?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(ctx); // Cerrar diálogo

              // 🔥 CORRECCIÓN: Usamos el Provider para desbloquear
              await Provider.of<BlockedUsersProvider>(context, listen: false).unblock(uid);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usuario desbloqueado"), backgroundColor: Colors.green));
            }, 
            child: const Text("Sí, desbloquear")
          ),
        ],
      ),
    );
  }


  // 🌵 Estado vacío (Visual linda)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 60, color: Colors.greenAccent),
          ),
          const SizedBox(height: 20),
          const Text(
            "Todo limpio",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "No tienes usuarios bloqueados actualmente.",
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}