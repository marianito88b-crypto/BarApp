// lib/ui/place/place_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// TUS MODELOS
import 'package:barapp/models/categories.dart';
import 'package:barapp/models/place.dart';
import 'package:barapp/theme.dart';

// PANELES DE DUEÑO

// WIDGETS MODULARES
import 'widgets/detail/modals/reservation_form_modal.dart';

// LAYOUTS ADAPTATIVOS
import 'layouts/place_detail_mobile.dart';
import 'layouts/place_detail_desktop.dart';

// LÓGICA DE NEGOCIO
import 'logic/place_detail_logic.dart';




class PlaceDetailScreen extends StatefulWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}



class _PlaceDetailScreenState extends State<PlaceDetailScreen>
    with PlaceDetailLogicMixin {
  double _distanceToPlace = double.infinity;
  static const double _ratingGeofenceThreshold = 150.0;
  late Stream<QuerySnapshot> _menuStream;

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _placeStream;
  final List<String> _categoryOrder = [
    'Entradas', 'Minutas', 'Hamburguesas', 'Pizzas', 
    'Platos Principales', 'Postres', 'Bebidas Sin Alcohol', 
    'Cervezas', 'Tragos', 'Vinos'
  ];

  @override
  void initState() {
    super.initState();
    initConfettiController();
    _placeStream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .snapshots();
    _menuStream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('menu')
        .snapshots();
  }

  @override
  void dispose() {
    disposeConfettiController(); // 🔥 Crucial para que no explote la memoria
    super.dispose();
  }


  // ===========================================================================
  // 🔒 1. LÓGICA BOTÓN RESERVAR (CON DIÁLOGO DE DECISIÓN)
  // ===========================================================================
  Future<void> _checkAndOpenReservation(BuildContext context, Place place) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes iniciar sesión para reservar")),
      );
      return;
    }

    // Consultamos si ya existe una reserva activa
    final activeReservations = await FirebaseFirestore.instance
        .collection('places')
        .doc(place.id)
        .collection('reservas')
        .where('userId', isEqualTo: user.uid)
        .where('estado', whereIn: ['pendiente', 'confirmada'])
        .get();

    if (activeReservations.docs.isNotEmpty) {
      if (context.mounted) {
        // 🔥 CAMBIO AQUÍ: Diálogo con opciones
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Text("Ya tienes una reserva", style: TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            content: const Text(
              "Ya tienes una reserva activa para este lugar. ¿Deseas generar una nueva reserva adicional?",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cierra y no hace nada
                child: const Text("Volver", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black),
                onPressed: () {
                  Navigator.pop(context); // Cierra el alerta
                  ReservationFormModal.show(context, place); // Abre el formulario
                },
                child: const Text("Nueva Reserva"),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Si no tiene reserva, abrimos el modal directo
    if (context.mounted) ReservationFormModal.show(context, place);
  }


  void _showDishImage(BuildContext context, String imageUrl, String nombrePlato) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nombrePlato,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    // 🎊 Envolvemos todo en un Stack para que el confetti vuele por encima de la UI
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _placeStream,
          builder: (context, snapshot) {
            // Manejo de estados de carga y error
            if (snapshot.hasError) return const Scaffold(body: Center(child: Text('Error')));
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(color: Colors.orangeAccent)),
              );
            }

            final placeData = snapshot.data!.data();
            if (placeData == null) return const Scaffold(body: Center(child: Text('Lugar no encontrado')));

            // --- VARIABLES DE CONFIGURACIÓN ---
            final bool aceptaPedidos = placeData['aceptaPedidos'] ?? true;
            final bool deliveryDisponible = placeData['deliveryDisponible'] ?? false;
            final bool aceptaReservas = placeData['aceptaReservas'] ?? true;
            final bool menuVisible = placeData['menuVisible'] ?? true;

            // --- INSTANCIAR OBJETO PLACE ---
            final Place place = Place.fromMap(id: snapshot.data!.id, data: placeData);
            final Category category = place.categories.isNotEmpty ? place.categories.first : Category.todos;
            final accent = colorForCategory(category);

            // --- FOTOS ---
            final List<String> fotos = List<String>.from(placeData['fotos'] ?? []);
            final String? portadaUrl = fotos.isNotEmpty ? fotos.first : null;

            // --- DISTANCIA ---
            if (_distanceToPlace == double.infinity && place.hasValidCoords) {
              checkAndCalculateDistance(
                place,
                (position, distance) {
                  setState(() {
                    _distanceToPlace = distance;
                  });
                },
              );
            }

            final bool canRate = _distanceToPlace.isFinite && _distanceToPlace <= _ratingGeofenceThreshold;
            final bool placeHasCoords = place.hasValidCoords;
            final CameraPosition placeCameraPosition = CameraPosition(
              target: placeHasCoords ? LatLng(place.lat, place.lng) : const LatLng(-27.45, -58.98),
              zoom: placeHasCoords ? 15 : 12,
            );

            // Seleccionar layout según el ancho de pantalla
            final screenWidth = MediaQuery.of(context).size.width;
            final isDesktop = screenWidth > 900;

            return Scaffold(
              body: isDesktop
                  ? PlaceDetailDesktopLayout(
                      place: place,
                      placeData: placeData,
                      accentColor: accent,
                      portadaUrl: portadaUrl,
                      distanceInMeters:
                          _distanceToPlace.isFinite ? _distanceToPlace : null,
                      formatDistance: formatDistanceMeters,
                      onLaunchUrl: (url) => launchSocialUrl(url),
                      menuStream: _menuStream,
                      categoryOrder: _categoryOrder,
                      aceptaPedidos: aceptaPedidos,
                      deliveryDisponible: deliveryDisponible,
                      aceptaReservas: aceptaReservas,
                      menuVisible: menuVisible,
                      canRate: canRate,
                      placeCameraPosition: placeCameraPosition,
                      placeHasCoords: placeHasCoords,
                      onShowRatingDialog: (p) => showRatingDialog(p),
                      onCheckAndOpenReservation: _checkAndOpenReservation,
                      onShowDishImage: _showDishImage,
                      onShowRegistrationDialog: showRegistrationDialog,
                      confettiController: confettiController,
                    )
                  : PlaceDetailMobileLayout(
                      place: place,
                      placeData: placeData,
                      accentColor: accent,
                      portadaUrl: portadaUrl,
                      distanceInMeters:
                          _distanceToPlace.isFinite ? _distanceToPlace : null,
                      formatDistance: formatDistanceMeters,
                      onLaunchUrl: (url) => launchSocialUrl(url),
                      menuStream: _menuStream,
                      categoryOrder: _categoryOrder,
                      aceptaPedidos: aceptaPedidos,
                      deliveryDisponible: deliveryDisponible,
                      aceptaReservas: aceptaReservas,
                      menuVisible: menuVisible,
                      canRate: canRate,
                      placeCameraPosition: placeCameraPosition,
                      placeHasCoords: placeHasCoords,
                      onShowRatingDialog: (p) => showRatingDialog(p),
                      onCheckAndOpenReservation: _checkAndOpenReservation,
                      onShowDishImage: _showDishImage,
                      onShowRegistrationDialog: showRegistrationDialog,
                      confettiController: confettiController,
                    ),
            );
          },
        ),
      ],
    );
  }

}

// ===========================================================================
// 🛵 WIDGET: ESTADO DEL DELIVERY / BOTÓN DE AVISO
// ===========================================================================
// ignore: unused_element
class _DeliveryStatusSection extends StatefulWidget {
  final String placeId;
  final bool habilitado; // <--- 1. NUEVA VARIABLE
  final VoidCallback onNotificarTap;

  const _DeliveryStatusSection({
    required this.placeId,
    required this.habilitado, // <--- 2. REQUERIDO
    required this.onNotificarTap,
  });

  @override
  State<_DeliveryStatusSection> createState() => _DeliveryStatusSectionState();
}

class _DeliveryStatusSectionState extends State<_DeliveryStatusSection> {
  Stream<QuerySnapshot>? _ordersStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (widget.habilitado && user != null) {
      _ordersStream = FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('estado', whereIn: ['pendiente', 'en_camino'])
          .limit(1)
          .snapshots();
    }
  }

 @override
  Widget build(BuildContext context) {
    // Si no está habilitado o no hay usuario, desaparece.
    if (!widget.habilitado) return const SizedBox.shrink();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        // Mientras carga, no mostramos nada para no dar saltos visuales
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;

        // --- CAMBIO CLAVE AQUÍ ---
        // Si NO hay pedido activo, devolvemos un widget invisible.
        // El botón de WhatsApp desaparece para siempre.
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // CASO B: HAY PEDIDO ACTIVO -> MANTENEMOS LA TARJETA DE ESTADO
        // (Esto es útil dejarlo porque si el usuario está mirando el local, 
        // le recuerda que tiene algo en camino).
        final data = docs.first.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pendiente';
        final driverName = data['driverName'] ?? 'Repartidor';

        Color statusColor = Colors.grey;
        String statusText = "ESPERANDO CONFIRMACIÓN...";
        IconData statusIcon = Icons.access_time;

        if (status == 'en_camino') {
          statusColor = Colors.greenAccent;
          statusText = "¡EN CAMINO!";
          statusIcon = Icons.delivery_dining;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: statusColor.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ESTADO DE TU PEDIDO",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (status == 'en_camino') ...[
                const Divider(color: Colors.white10, height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.two_wheeler,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Lo lleva: ",
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      driverName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
   }

// ignore: unused_element
   class _PoliticaReservaCard extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2010), // Fondo marrón/naranja muy oscuro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_off_outlined, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "IMPORTANTE: Tolerancia de 15 min",
                  style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                    children: [
                      TextSpan(text: "Tu mesa se guardará solo por 15 minutos. Pasado ese tiempo, el sistema "),
                      TextSpan(
                        text: "LIBERARÁ LA MESA AUTOMÁTICAMENTE",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: " para otros clientes.\n\nSi no puedes venir, por favor ayúdanos cancelando desde la app."),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
