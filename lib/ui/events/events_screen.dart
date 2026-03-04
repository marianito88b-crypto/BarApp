import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barapp/ui/place/place_detail_screen.dart';
import 'package:barapp/ui/events/superadmin_event_dialog.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _isSuperAdmin = false;
  late final Stream<QuerySnapshot> _eventsStream;

  @override
  void initState() {
    super.initState();
    _eventsStream = FirebaseFirestore.instance
        .collection('events')
        .where('date', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(hours: 12)))
        .orderBy('date', descending: false)
        .snapshots();
    _checkSuperAdminRole();
  }

  Future<void> _checkSuperAdminRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isSuperAdmin = false);
      return;
    }

    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();
      
      if (!userDoc.exists) {
        userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
      }

      if (userDoc.exists) {
        final uData = userDoc.data();
        final roleValue = uData?['role'];
        final isAdmin = roleValue == true ||
            roleValue == 'admin' ||
            roleValue.toString().toLowerCase() == 'true';
        
        if (mounted) {
          setState(() => _isSuperAdmin = isAdmin);
        }
        return;
      }
    } catch (e) {
      debugPrint("Error verificando rol superadmin: $e");
    }

    if (mounted) {
      setState(() => _isSuperAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text("Promos & Shows", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                _LegendDot(color: Colors.amber, label: "Show"),
                const SizedBox(width: 12),
                _LegendDot(color: Colors.greenAccent, label: "Promo"),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: _isSuperAdmin
          ? FloatingActionButton(
              onPressed: () => SuperAdminEventDialog.show(context),
              backgroundColor: Colors.purpleAccent,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _eventsStream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orangeAccent));
          
          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 80, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text("No hay eventos próximos", style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              
              // Cabeceras de fecha
              final DateTime eventDate = (data['date'] as Timestamp).toDate();
              final bool showHeader = index == 0 || !_isSameDay((docs[index - 1].data() as Map)['date'].toDate(), eventDate);

              // Detectamos si tiene imagen para decidir el diseño
              final String? imageUrl = data['imageUrl'];
              final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showHeader) _buildDateHeader(eventDate),
                  
                  // 🔥 CAMBIO DE LÓGICA: Diseño basado en CONTENIDO (Foto vs Texto)
                  InkWell(
                    onTap: () => _showEventDetail(context, data), // Al tocar, abre detalle
                    borderRadius: BorderRadius.circular(16),
                    child: hasImage 
                      ? _BigEventCard(data: data) // Usamos tarjeta grande si hay foto (Sea Promo o Show)
                      : _SimpleEventCard(data: data), // Usamos tarjeta simple si es solo texto
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --- MODAL DE DETALLE COMPLETO CORREGIDO ---
  void _showEventDetail(BuildContext context, Map<String, dynamic> data) {
    final bool isShow = data['type'] == 'show';
    final Color color = isShow ? Colors.amber : Colors.greenAccent;
    final String? imageUrl = data['imageUrl'];
    final DateTime date = (data['date'] as Timestamp).toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Imagen Grande (Si existe)
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(20)),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Badge Tipo y Fecha (CORREGIDO)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color),
                              ),
                              child: Text(
                                isShow ? "SHOW EN VIVO" : "PROMO ESPECIAL",
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8), // Espacio de seguridad
                            // Usamos Flexible para que la fecha no empuje fuera de pantalla
                            Flexible(
                              child: Text(
                                DateFormat(
                                  "EEEE d 'de' MMMM • HH:mm",
                                  'es_ES',
                                ).format(date).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis, // Puntos suspensivos si es largo
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 3. Título y Local
                        Text(
                          data['title'] ?? 'Evento',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // --- AQUÍ ESTABA EL OVERFLOW PRINCIPAL ---
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            // Agregamos Expanded para que el texto ocupe solo lo disponible
                            Expanded(
                              child: Text(
                                data['placeName'] ?? 'Ubicación',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // ----------------------------------------
                        
                        const SizedBox(height: 16), 

                        // --- BLOQUE LOCAL CLICKEABLE ---
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx); 
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PlaceDetailScreen(
                                      placeId: data['placeId'],
                                    ),
                              ),
                            );
                            debugPrint(
                              "Navegar al local: ${data['placeName']} ID: ${data['placeId']}",
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    FontAwesomeIcons.store,
                                    color: Colors.purpleAccent,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['placeName']?.toUpperCase() ??
                                            'UBICACIÓN',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1, // Seguridad extra
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        (data['placeAddress'] != null &&
                                                data['placeAddress'].isNotEmpty)
                                            ? data['placeAddress']
                                            : "Toca para ver ubicación",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white24,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // --- FIN BLOQUE LOCAL ---
                        
                        const Divider(color: Colors.white10, height: 40),

                        // 4. Descripción COMPLETA
                        const Text(
                          "DETALLES",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data['description'] ?? 'Sin descripción adicional.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Botón cerrar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              "Entendido",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    String label;
    if (_isSameDay(date, now)) {
      label = "🔥 HOY";
    } else if (_isSameDay(date, now.add(const Duration(days: 1)))) {
      label = "🚀 MAÑANA";
    } else {
      label = DateFormat("EEEE d 'de' MMMM", 'es_ES').format(date).toUpperCase();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 15),
      child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
    );
  }
}

// =============================================================================
// 📸 TARJETA GRANDE (Se usa para Show O Promo SI TIENE FOTO)
// =============================================================================
class _BigEventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BigEventCard({required this.data});

  @override
  Widget build(BuildContext context) {
    // Definimos color según el tipo (No el contenido)
    final bool isShow = data['type'] == 'show';
    final Color color = isShow ? Colors.amber : Colors.greenAccent; // Dorado o Verde
    final String label = isShow ? "SHOW" : "PROMO";
    final IconData icon = isShow ? FontAwesomeIcons.music : Icons.local_offer;

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
      ),
      child: Stack(
        children: [
          // Gradiente para leer texto
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                stops: [0.1, 0.4, 0.7, 1.0]
              ),
            ),
          ),
          
          // Badge Superior
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Icon(icon, size: 10, color: Colors.black),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10)),
                ],
              ),
            ),
          ),

          // Info
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['placeName']?.toUpperCase() ?? "LUGAR",
                  style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  data['title'] ?? "Evento",
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.1),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(DateFormat("HH:mm").format((data['date'] as Timestamp).toDate()), style: const TextStyle(color: Colors.white70)),
                    const Spacer(),
                    const Text("Ver más", style: TextStyle(color: Colors.white54, fontSize: 12, decoration: TextDecoration.underline))
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 📝 TARJETA SIMPLE (Solo Texto - Sin imagen)
// =============================================================================
class _SimpleEventCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _SimpleEventCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isShow = data['type'] == 'show';
    final Color color = isShow ? Colors.amber : Colors.greenAccent;
    final IconData icon = isShow ? FontAwesomeIcons.music : Icons.local_offer;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? "Promo", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("${data['placeName']} • ${DateFormat("HH:mm").format((data['date'] as Timestamp).toDate())}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24)
        ],
      ),
    );
  }
}

// Dot para leyenda
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}