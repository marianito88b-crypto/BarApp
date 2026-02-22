import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart'; 
import '../../providers/blocked_users_provider.dart'; 

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final blockedProvider = Provider.of<BlockedUsersProvider>(context);
    final excludedIds = blockedProvider.excludedIds; 

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mis Mensajes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(currentUserId)
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error al cargar chats", style: TextStyle(color: Colors.white)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));

          final chatDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final otherId = data['con'];
            return otherId != null && !excludedIds.contains(otherId);
          }).toList();

          if (chatDocs.isEmpty) {
            return const Center(
              child: Text('No tenés chats activos aún',
                  style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chatDocs.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white10, indent: 70),
            itemBuilder: (ctx, index) {
              final chat = chatDocs[index].data() as Map<String, dynamic>;
              final chatId = chat['chatId'] ?? chatDocs[index].id;
              final otherUserId = chat['con'];
              final displayName = chat['displayName'] ?? 'Usuario';
              final imageUrl = chat['imageUrl'] ?? '';
              final lastMsg = chat['ultimoMensaje'] ?? '';
              final timestamp = chat['timestamp'] as Timestamp?;

              return ListTile(
                onLongPress: () => _confirmarEliminarChat(chatId),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: otherUserId,
                        otherDisplayName: displayName,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  backgroundColor: const Color(0xFF2C2C2C),
                  child: imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white54) : null,
                ),
                title: Text(displayName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  lastMsg,
                  style: const TextStyle(color: Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (timestamp != null)
                      Text(
                        _formatTime(timestamp.toDate()),
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    // Aquí podrías agregar un badge de "leído" si quisieras
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (now.day == date.day) return DateFormat('HH:mm').format(date);
    return DateFormat('dd/MM').format(date);
  }

  void _confirmarEliminarChat(String chatId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              title: const Text('Eliminar conversación', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Se borrará de tu lista. Si te escriben, volverá a aparecer.', style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(currentUserId)
                    .collection('chats')
                    .doc(chatId)
                    .delete();
              },
            ),
          ],
        ),
      ),
    );
  }
}