import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../user/user_profile_screen.dart'; 
import '../../services/moderation/text_filter_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherDisplayName;

  const ChatScreen({super.key, required this.otherUserId, required this.otherDisplayName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _auth = FirebaseAuth.instance;
  late String _chatId;
  String? _otherUserPhoto;

  // NUEVAS VARIABLES PARA RESPUESTAS
  Map<String, dynamic>? _replyingTo;

  late final Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    final currentId = _auth.currentUser!.uid;
    final ids = [currentId, widget.otherUserId]..sort();
    _chatId = 'chat_${ids[0]}_${ids[1]}';
    _messagesStream = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('mensajes').orderBy('timestamp', descending: true).snapshots();
    _cargarFotoDelOtro();
  }

  Future<void> _cargarFotoDelOtro() async {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(widget.otherUserId).get();
    if (doc.exists && mounted) {
      setState(() => _otherUserPhoto = doc.data()?['imageUrl'] ?? '');
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final String textClean = TextFilterService.sanitizeText(text);
    final replyData = _replyingTo; // Guardamos la respuesta actual

    setState(() {
      _controller.clear();
      _replyingTo = null;
    });

    // 1. Guardar el mensaje
    final msgRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('mensajes')
        .doc();

    await msgRef.set({
      'texto': textClean,
      'timestamp': FieldValue.serverTimestamp(),
      'autorId': currentUser.uid,
      'leidoPor': [currentUser.uid],
      'replyTo': replyData, // 🔥 Aquí se guarda a quién respondes
      'reacciones': {}, // 🔥 Mapa vacío de reacciones
    });

    // 2. 🔥 ACTUALIZACIÓN BLINDADA DE RESÚMENES (Para ambos)
    _actualizarResumenGlobal(textClean);
    _scrollToBottom();
  }

  Future<void> _actualizarResumenGlobal(String ultimoTexto) async {
    final myUid = _auth.currentUser!.uid;
    final batch = FirebaseFirestore.instance.batch();

    // Resumen para MI
    final myRef = FirebaseFirestore.instance.collection('usuarios').doc(myUid).collection('chats').doc(_chatId);
    batch.set(myRef, {
      'chatId': _chatId,
      'con': widget.otherUserId,
      'displayName': widget.otherDisplayName,
      'imageUrl': _otherUserPhoto ?? '',
      'ultimoMensaje': ultimoTexto,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Resumen para el OTRO (Asegura que le aparezca si lo borró)
    final otherRef = FirebaseFirestore.instance.collection('usuarios').doc(widget.otherUserId).collection('chats').doc(_chatId);
    
    // Obtenemos mis datos para el otro
    final miDoc = await FirebaseFirestore.instance.collection('usuarios').doc(myUid).get();
    final miData = miDoc.data();

    batch.set(otherRef, {
      'chatId': _chatId,
      'con': myUid,
      'displayName': miData?['displayName'] ?? 'Usuario',
      'imageUrl': miData?['imageUrl'] ?? '',
      'ultimoMensaje': ultimoTexto,
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  void _reaccionar(String msgId, String emoji) async {
    final myUid = _auth.currentUser!.uid;
    final ref = FirebaseFirestore.instance.collection('chats').doc(_chatId).collection('mensajes').doc(msgId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) return;

      Map<String, dynamic> reacciones = Map<String, dynamic>.from(snapshot.data()?['reacciones'] ?? {});
      List<String> usuarios = List<String>.from(reacciones[emoji] ?? []);

      if (usuarios.contains(myUid)) {
        usuarios.remove(myUid);
      } else {
        usuarios.add(myUid);
      }

      if (usuarios.isEmpty) {
        reacciones.remove(emoji);
      } else {
        reacciones[emoji] = usuarios;
      }

      transaction.update(ref, {'reacciones': reacciones});
    });
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(externalUserId: widget.otherUserId, externalUserName: widget.otherDisplayName, externalUserPhotoUrl: _otherUserPhoto ?? ''))),
          child: Row(
            children: [
              CircleAvatar(radius: 16, backgroundImage: _otherUserPhoto != null && _otherUserPhoto!.isNotEmpty ? NetworkImage(_otherUserPhoto!) : null, child: _otherUserPhoto == null ? const Icon(Icons.person, size: 18) : null),
              const SizedBox(width: 10),
              Expanded(child: Text(widget.otherDisplayName, style: const TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final mensajes = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: mensajes.length,
                  itemBuilder: (ctx, i) {
                    final msgDoc = mensajes[i];
                    final data = msgDoc.data() as Map<String, dynamic>;
                    final esMio = data['autorId'] == _auth.currentUser!.uid;
                    
                    return _ChatBubble(
                      data: data,
                      esMio: esMio,
                      onReply: () => setState(() => _replyingTo = {'texto': data['texto'], 'autor': esMio ? 'Vos' : widget.otherDisplayName}),
                      onReact: (emoji) => _reaccionar(msgDoc.id, emoji),
                    );
                  },
                );
              },
            ),
          ),
          
          // BARRA DE RESPUESTA
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[900],
              child: Row(
                children: [
                  const Icon(Icons.reply, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Respondiendo a: ${_replyingTo!['texto']}", style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.white54), onPressed: () => setState(() => _replyingTo = null)),
                ],
              ),
            ),

          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(color: Color(0xFF1A1A1A)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Escribí un mensaje...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.orangeAccent,
            child: IconButton(icon: const Icon(Icons.send, color: Colors.black), onPressed: _sendMessage),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGET PARA LA BURBUJA CON REACCIONES ---
class _ChatBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool esMio;
  final VoidCallback onReply;
  final Function(String) onReact;

  const _ChatBubble({required this.data, required this.esMio, required this.onReply, required this.onReact});

  @override
  Widget build(BuildContext context) {
    final reacciones = data['reacciones'] as Map? ?? {};
    final replyTo = data['replyTo'] as Map?;

    return GestureDetector(
      onHorizontalDragEnd: (_) => onReply(),
      onLongPress: () => _showReactionSheet(context),
      child: Align(
        alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            crossAxisAlignment: esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Si es una respuesta...
              if (replyTo != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                  child: Text("${replyTo['autor']}: ${replyTo['texto']}", style: const TextStyle(color: Colors.white38, fontSize: 11), maxLines: 1),
                ),
              
              // El cuerpo del mensaje
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: esMio ? Colors.orangeAccent : Colors.grey[800],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(data['texto'], style: TextStyle(color: esMio ? Colors.black : Colors.white)),
              ),

              // Reacciones visuales
              if (reacciones.isNotEmpty)
                Wrap(
                  children: reacciones.keys.map<Widget>((e) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)),
                      child: Text("$e ${reacciones[e].length}", style: const TextStyle(fontSize: 10)),
                    ),
                  )).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['🔥', '😂', '🍻', '❤️', '👏'].map((e) => GestureDetector(
            onTap: () { onReact(e); Navigator.pop(context); },
            child: Text(e, style: const TextStyle(fontSize: 30)),
          )).toList(),
        ),
      ),
    );
  }
}