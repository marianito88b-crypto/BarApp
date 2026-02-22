import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../user/user_profile_screen.dart';

class OnlineUsersScreen extends StatefulWidget {
  const OnlineUsersScreen({super.key});

  @override
  State<OnlineUsersScreen> createState() => _OnlineUsersScreenState();
}

class _OnlineUsersScreenState extends State<OnlineUsersScreen> {
  String _searchText = '';
  final Set<String> _preloadedImages = {};
  bool _isPreloading = false;

  // Header simple
  Widget _buildHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Precarga las primeras N imágenes para mostrar inmediatamente
  Future<void> _preloadImages(List<UserItemModel> users, {int count = 10}) async {
    if (_isPreloading) return;
    _isPreloading = true;

    final imagesToPreload = users
        .where((u) => u.imageUrl.isNotEmpty && !_preloadedImages.contains(u.imageUrl))
        .take(count)
        .toList();

    if (imagesToPreload.isEmpty) {
      _isPreloading = false;
      return;
    }

    // Precargar imágenes en segundo plano
    for (final user in imagesToPreload) {
      if (user.imageUrl.isNotEmpty) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(user.imageUrl),
            context,
          );
          _preloadedImages.add(user.imageUrl);
        } catch (e) {
          debugPrint('Error precargando imagen: $e');
        }
      }
    }

    _isPreloading = false;
    if (mounted) {
      setState(() {}); // Actualizar UI para mostrar imágenes precargadas
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Usuarios Conectados'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchText = value.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // LISTA DE USUARIOS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  // Opcional: Podrías ordenar por última vez conectado
                  .orderBy('ultimaVezOnline', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data!.docs;
                final now = DateTime.now();

                // 1. MAPEO Y LÓGICA DE ESTADO "REAL"
                final processedUsers = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  
                  // Recuperar nombre
                  String name = (data['displayName'] ?? '').toString().trim();
                  if (name.isEmpty || name.toLowerCase() == 'sin nombre') {
                     name = (data['nombre'] ?? 'Usuario').toString().trim();
                  }
                  
                  // Filtro de búsqueda
                  if (_searchText.isNotEmpty && !name.toLowerCase().contains(_searchText)) {
                    return null; // Lo descartamos
                  }

                  // 🕵️ LÓGICA ANTI-FANTASMA
                  // Si dice 'online' pero el timestamp es viejo (> 5 min), asumimos que crasheó/cerró forzado.
                  bool isOnline = data['estado'] == 'online';
                  final Timestamp? ts = data['ultimaVezOnline'] as Timestamp?;
                  
                  if (isOnline && ts != null) {
                    final diff = now.difference(ts.toDate());
                    if (diff.inMinutes > 5) {
                      isOnline = false; // Lo marcamos offline forzosamente
                    }
                  }

                  return UserItemModel(
                    id: doc.id,
                    displayName: name,
                    imageUrl: (data['imageUrl'] ?? '').toString(),
                    isOnline: isOnline,
                  );
                }).whereType<UserItemModel>().toList(); // Filtramos los nulos

                // 2. SEPARACIÓN EN LISTAS
                final onlineUsers = processedUsers.where((u) => u.isOnline).toList();
                final offlineUsers = processedUsers.where((u) => !u.isOnline).toList();

                if (processedUsers.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron usuarios', style: TextStyle(color: Colors.white70)),
                  );
                }

                // 3. PRECARGAR PRIMERAS 10 IMÁGENES (priorizando online)
                final usersToPreload = [
                  ...onlineUsers.take(10),
                  ...offlineUsers.take(10 - onlineUsers.length.clamp(0, 10)),
                ];
                _preloadImages(usersToPreload, count: 10);

                // 4. CONSTRUCCIÓN DE LA LISTA UNIFICADA
                final totalItems = onlineUsers.length + offlineUsers.length + 2; 

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: totalItems,
                  itemBuilder: (ctx, i) {
                    // Headers
                    if (i == 0) return _buildHeader('🟢 En línea (${onlineUsers.length})', Colors.white);
                    if (i == onlineUsers.length + 1) return _buildHeader('⚪ Desconectados', Colors.grey);

                    // Items
                    final isOnlineSection = i <= onlineUsers.length;
                    final user = isOnlineSection 
                        ? onlineUsers[i - 1] 
                        : offlineUsers[i - (onlineUsers.length + 2)];

                    return Column(
                      children: [
                        UserStatusTile(
                          user: user,
                          heroTagIndex: i,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  externalUserId: user.id,
                                  externalUserName: user.displayName,
                                  externalUserPhotoUrl: user.imageUrl,
                                ),
                              ),
                            );
                          },
                        ),
                        // Separador sutil
                        if (i < totalItems - 1) 
                          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- CLASE AUXILIAR PARA ORDENAR DATA ---
class UserItemModel {
  final String id;
  final String displayName;
  final String imageUrl;
  final bool isOnline;

  UserItemModel({
    required this.id,
    required this.displayName,
    required this.imageUrl,
    required this.isOnline,
  });
}

// --- WIDGET DE LA FILA (Tile) ---
class UserStatusTile extends StatelessWidget {
  final UserItemModel user;
  final int heroTagIndex;
  final VoidCallback onTap;

  const UserStatusTile({
    super.key,
    required this.user,
    required this.heroTagIndex,
    required this.onTap,
  });

  Widget _buildAvatar() {
    if (user.imageUrl.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: user.isOnline 
              ? Border.all(color: Colors.greenAccent, width: 2) 
              : null,
        ),
        child: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[800],
          child: Icon(Icons.person, color: Colors.grey[400], size: 20),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: user.isOnline 
            ? Border.all(color: Colors.greenAccent, width: 2) 
            : null,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: user.imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          // Optimizar tamaño en memoria (40 * 2 para retina = 80)
          memCacheWidth: 80,
          memCacheHeight: 80,
          // Placeholder con shimmer mientras carga
          placeholder: (context, url) => Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              width: 40,
              height: 40,
              color: Colors.grey[800],
            ),
          ),
          // Error widget
          errorWidget: (context, url, error) => Container(
            width: 40,
            height: 40,
            color: Colors.grey[800],
            child: Icon(Icons.person, color: Colors.grey[400], size: 20),
          ),
          // Fade-in animation suave
          fadeInDuration: const Duration(milliseconds: 300),
          fadeOutDuration: const Duration(milliseconds: 100),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Hero(
        tag: 'avatar_online_users_$heroTagIndex',
        child: _buildAvatar(),
      ),
      title: Text(
        user.displayName,
        style: TextStyle(
          color: user.isOnline ? Colors.white : Colors.grey,
          fontWeight: user.isOnline ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      // Subtítulo limpio: Solo "Online" o nada
      subtitle: user.isOnline
          ? const Text(
              'Online',
              style: TextStyle(color: Colors.greenAccent, fontSize: 12),
            )
          : null,
      
      // Puntito verde a la derecha solo si es online
      trailing: user.isOnline
          ? const Icon(Icons.circle, color: Colors.greenAccent, size: 10)
          : null,
    );
  }
}