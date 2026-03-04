// (Crea la carpeta 'widgets' dentro de 'lib/ui/muro/' y pon este archivo allí)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. IMPORTAR EL SERVICIO DE FILTRO
import '../../../../services/moderation/text_filter_service.dart'; 
// (Ajusta la cantidad de "../" según donde guardaste este archivo, 
// si está en lib/ui/community/widgets/comment_modal.dart serían 4 hacia atrás)

class CommentModal extends StatefulWidget {
  final DocumentReference postRef;
  const CommentModal({super.key, required this.postRef});

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _commentsStream;

  @override
  void initState() {
    super.initState();
    _commentsStream = widget.postRef.collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Comentarios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),

            // Lista
            Flexible(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _commentsStream,
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Sé el primero en comentar',
                          style: TextStyle(color: Colors.white70)),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    reverse: true,
                    itemCount: docs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final d = docs[i].data();
                      final photoUrl = d['authorPhotoUrl'] ?? '';
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF222222),
                          backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                          child: photoUrl.isEmpty
                            ? const Icon(Icons.person, size: 16)
                            : null,
                        ),
                        title: Text(
                          (d['authorName'] ?? 'Usuario').toString(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text((d['text'] ?? '').toString()),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Escribí un comentario...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending
                      ? null
                      : () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final text = _ctrl.text.trim();
                          if (text.isEmpty) return;

                          // 2. 🧹 APLICAMOS EL FILTRO AQUÍ
                          final textClean = TextFilterService.sanitizeText(text);

                          setState(() => _sending = true);
                          
                          await widget.postRef.collection('comments').add({
                            'authorId': user.uid,
                            'authorName': user.displayName ?? 'Usuario',
                            'authorPhotoUrl': user.photoURL ?? '',
                            'text': textClean, // <--- ENVIAMOS EL LIMPIO
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          
                          _ctrl.clear();
                          setState(() => _sending = false);
                        },
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}