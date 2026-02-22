import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersAdminScreen extends StatelessWidget {
  const UsersAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Usuarios · Control Global'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .limit(300) // Aumenté un poco el límite de visualización
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay usuarios registrados.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 HEADER: CONTADOR TOTAL
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '👥 Total visible: ${docs.length}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 🔥 BOTÓN: LIMPIAR USUARIOS FANTASMA
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cleaning_services_outlined, color: Colors.white),
                    onPressed: () => _cleanGhostUsers(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    label: const Text('Limpiar usuarios fantasma (Auto)', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),

              // 🔥 LISTA
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;

                    // 🔥 AUTO-FIX createdAt
                    if (!data.containsKey('createdAt')) {
                      FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(doc.id)
                          .update({'createdAt': FieldValue.serverTimestamp()});
                    }

                    final uid = doc.id;
                    final name = data['displayName'] ?? 'Usuario';
                    final image = data['imageUrl'];
                    final role = data['role'] ?? 'user';
                    final isBanned = data['isBanned'] == true;
                    final isWarning = data['isWarning'] == true;
                    final reports = data['reportsCount'] ?? 0;
                    final hasCompletedProfile = data['hasCompletedProfile'] == true;

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isBanned
                              ? Colors.redAccent
                              : isWarning
                                  ? Colors.amber
                                  : Colors.white10,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: image != null ? NetworkImage(image) : null,
                          backgroundColor: Colors.grey[900],
                          child: image == null
                              ? const Icon(Icons.person, color: Colors.white54)
                              : null,
                        ),
                        title: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rol: $role', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            if (!hasCompletedProfile)
                              const Text('Perfil incompleto', style: TextStyle(color: Colors.redAccent, fontSize: 11)),
                            if (reports > 0)
                              Text('🚩 Reportes: $reports', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleAction(context, uid, value, name),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'warn', child: Text('⚠️ Advertir')),
                            PopupMenuItem(value: 'ban', child: Text('⛔ Banear')),
                            PopupMenuItem(value: 'unban', child: Text('✅ Desbanear')),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete_manual', 
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              )
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String uid, String action, String name) async {
    final ref = FirebaseFirestore.instance.collection('usuarios').doc(uid);

    if (action == 'delete_manual') {
      // ⚠️ Confirmación antes de borrar
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('¿Eliminar usuario?', style: TextStyle(color: Colors.white)),
          content: Text('Estás a punto de eliminar a "$name". Esta acción no se puede deshacer.', 
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx), 
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.delete();
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Usuario eliminado correctamente')));
                }
              }, 
              child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
            ),
          ],
        )
      );
      return; // Salimos para no ejecutar el resto
    }

    // Acciones normales
    if (action == 'warn') await ref.set({'isWarning': true}, SetOptions(merge: true));
    if (action == 'ban') await ref.set({'isBanned': true}, SetOptions(merge: true));
    if (action == 'unban') await ref.set({'isBanned': false, 'isWarning': false}, SetOptions(merge: true));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Acción aplicada: $action')));
    }
  }

  Future<void> _cleanGhostUsers(BuildContext context) async {
    final collection = FirebaseFirestore.instance.collection('usuarios');
    // Buscamos sin límite para limpiar todo (Ojo: si son miles, esto debería ser paginado)
    final snapshot = await collection.limit(500).get(); 
    
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      bool isGuest = data['isGuest'] == true;
      bool incomplete = data['hasCompletedProfile'] == false;
      
      // Lógica de limpieza
      if (isGuest || (incomplete && (data['displayName'] == null || data['displayName'] == 'Usuario'))) {
        batch.delete(doc.reference);
        count++;
      }
    }

    if (count > 0) {
      await batch.commit();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🔥 Se eliminaron $count usuarios fantasma')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ No se encontraron usuarios fantasma')),
        );
      }
    }
  }
}