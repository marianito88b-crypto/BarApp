import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Asegurate de tener intl en pubspec.yaml o usa formanteo manual

class PlaceDetailAdminScreen extends StatelessWidget {
  final String placeId;

  const PlaceDetailAdminScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
    // Usamos StreamBuilder aquí para que CUALQUIER cambio (pago, dueño) se vea INSTANTÁNEO
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('places').doc(placeId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final data = snap.data!.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? data['nombre'] ?? 'Sin nombre';
        
        // --- LÓGICA DE ESTADO FINANCIERO ---
        final now = DateTime.now();
        
        // 1. Fecha de inicio de prueba
        DateTime? inicioPrueba;
        if (data['fechaInicioPrueba'] is Timestamp) {
          inicioPrueba = (data['fechaInicioPrueba'] as Timestamp).toDate();
        }
        
        // 2. Fecha hasta donde pagó (si existe)
        DateTime? paidUntil;
        if (data['validUntil'] is Timestamp) {
          paidUntil = (data['validUntil'] as Timestamp).toDate();
        }

        // 3. Determinar Estado
        String statusText = 'Desconocido';
        Color statusColor = Colors.grey;
        bool hasDebt = false;

        bool isTrial = false;
        if (inicioPrueba != null) {
          final finPrueba = inicioPrueba.add(const Duration(days: 30));
          if (now.isBefore(finPrueba)) {
            isTrial = true;
            statusText = '🟢 EN PERIODO DE PRUEBA';
            statusColor = Colors.greenAccent;
          }
        }

        if (!isTrial) {
          // Si no es prueba, chequeamos si pagó
          if (paidUntil != null && paidUntil.isAfter(now)) {
            statusText = '✅ AL DÍA (Pagó)';
            statusColor = Colors.blueAccent;
          } else {
            statusText = '🔴 DEUDA PENDIENTE';
            statusColor = Colors.redAccent;
            hasDebt = true;
          }
        }
        
        // Si ni siquiera empezó la prueba
        if (inicioPrueba == null) {
           statusText = '⚪ INACTIVO (Sin iniciar)';
           statusColor = Colors.grey;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(name),
            backgroundColor: Colors.black,
            actions: [
               if (hasDebt)
                 const Padding(
                   padding: EdgeInsets.only(right: 16.0),
                   child: Icon(Icons.warning, color: Colors.redAccent),
                 )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // === TARJETA DE ESTADO ===
                Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (isTrial && inicioPrueba != null)
                        Text('La prueba vence el: ${_formatDate(inicioPrueba.add(const Duration(days: 30)))}',
                            style: const TextStyle(color: Colors.white70)),
                      if (paidUntil != null && !isTrial)
                         Text('Vencimiento del pago: ${_formatDate(paidUntil)}',
                            style: const TextStyle(color: Colors.white70)),
                      
                      const SizedBox(height: 16),
                      
                      // BOTÓN DE ACCIÓN INTELIGENTE
                      if (hasDebt || !isTrial) 
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.attach_money),
                          label: const Text('Registrar Pago (+30 días)'),
                          onPressed: () => _registerPayment(context, paidUntil ?? DateTime.now()),
                        ),
                        
                       if (inicioPrueba == null)
                        ElevatedButton(
                          onPressed: () => _startTrial(context),
                          child: const Text('Iniciar Prueba Ahora'),
                        )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // === DUEÑO DEL BAR ===
                _buildSectionTitle('Propietario'),
                _buildOwnerCard(context, data['ownerId']),

                const SizedBox(height: 30),

                // === STAFF ===
                _buildSectionTitle('Staff'),
                _buildStaffList(placeId),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _buildOwnerCard(BuildContext context, String? ownerId) {
    if (ownerId == null) {
      return InkWell(
        onTap: () => _showOwnerPicker(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orangeAccent, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Asignar Dueño', style: TextStyle(color: Colors.orangeAccent)),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('usuarios').doc(ownerId).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final user = snap.data!.data() as Map<String, dynamic>? ?? {};
        
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: user['imageUrl'] != null ? NetworkImage(user['imageUrl']) : null,
              child: user['imageUrl'] == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user['displayName'] ?? 'Sin nombre', style: const TextStyle(color: Colors.white)),
            subtitle: Text(user['email'] ?? 'ID: ${ownerId.substring(0, 5)}...', 
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => _showOwnerPicker(context),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStaffList(String placeId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').where('placeId', isEqualTo: placeId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final staff = snap.data!.docs;
        
        if (staff.isEmpty) {
           return const Padding(
             padding: EdgeInsets.all(8.0),
             child: Text('No hay empleados registrados.', style: TextStyle(color: Colors.white38)),
           );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: staff.length,
          itemBuilder: (ctx, i) {
             final emp = staff[i].data() as Map<String, dynamic>;
             return ListTile(
               leading: const Icon(Icons.badge, color: Colors.white54),
               title: Text(emp['displayName'] ?? 'Staff', style: const TextStyle(color: Colors.white)),
               subtitle: Text(emp['role'] ?? 'Empleado', style: const TextStyle(color: Colors.white38)),
             );
          },
        );
      },
    );
  }

  // --- FUNCIONES LÓGICAS ---

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _registerPayment(BuildContext context, DateTime currentExpiration) async {
    // Si la fecha actual ya venció, empezamos a contar desde HOY. Si no, sumamos a la fecha futura.
    DateTime baseDate = currentExpiration.isBefore(DateTime.now()) ? DateTime.now() : currentExpiration;
    DateTime newDate = baseDate.add(const Duration(days: 30));

    await FirebaseFirestore.instance.collection('places').doc(placeId).update({
      'validUntil': Timestamp.fromDate(newDate),
    });
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('💰 Pago registrado. Vencimiento actualizado.')));
    }
  }

  Future<void> _startTrial(BuildContext context) async {
    await FirebaseFirestore.instance.collection('places').doc(placeId).update({
      'fechaInicioPrueba': FieldValue.serverTimestamp(),
    });
  }

  // --- BUSCADOR DE DUEÑOS (Reciclado) ---
  void _showOwnerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _UserSearchSheet(placeId: placeId, scrollController: scrollController);
          },
        );
      }
    );
  }
}

// Widget interno del buscador
class _UserSearchSheet extends StatefulWidget {
  final String placeId;
  final ScrollController scrollController;

  const _UserSearchSheet({required this.placeId, required this.scrollController});

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar usuario...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('usuarios').limit(100).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final allDocs = snap.data!.docs;
              
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['displayName'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || email.contains(_searchQuery);
              }).toList();

              return ListView.separated(
                controller: widget.scrollController,
                itemCount: filteredDocs.length,
                separatorBuilder: (_, _) => const Divider(color: Colors.white10),
                itemBuilder: (context, i) {
                  final userDoc = filteredDocs[i];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final dName = userData['displayName'] ?? 'Sin nombre';
                  final email = userData['email'] ?? 'Sin email';

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(dName, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    onTap: () async {
                      await FirebaseFirestore.instance.collection('places').doc(widget.placeId).update({
                        'ownerId': userDoc.id
                      });
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}