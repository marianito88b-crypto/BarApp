import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';

import 'package:barapp/models/place.dart';
import 'package:barapp/ui/panel_dueno/panel_dueno_screen.dart';
import 'package:barapp/ui/client/client_menu_screen.dart';

import '../widgets/detail/place_detail_header.dart';
import '../widgets/detail/venue_info_section.dart';
import '../widgets/detail/social_hours_card.dart';
import '../widgets/detail/modals/client_menu_modal.dart';
import '../widgets/detail/modals/reservation_status_banner.dart';
import '../widgets/detail/gallery_section.dart';
import '../widgets/detail/reviews_section.dart';
import '../widgets/detail/order_button_floating.dart';
import '../widgets/detail/action_chip_button.dart';

/// Layout móvil para PlaceDetailScreen
class PlaceDetailMobileLayout extends StatelessWidget {
  final Place place;
  final Map<String, dynamic> placeData;
  final Color accentColor;
  final String? portadaUrl;
  final double? distanceInMeters;
  final String Function(double) formatDistance;
  final Future<void> Function(String) onLaunchUrl;
  final Stream<QuerySnapshot> menuStream;
  final List<String> categoryOrder;
  final bool aceptaPedidos;
  final bool deliveryDisponible;
  final bool aceptaReservas;
  final bool menuVisible;
  final bool canRate;
  final CameraPosition placeCameraPosition;
  final bool placeHasCoords;
  final void Function(Place) onShowRatingDialog;
  final void Function(BuildContext, Place) onCheckAndOpenReservation;
  final void Function(BuildContext, String, String) onShowDishImage;
  final void Function() onShowRegistrationDialog;
  final ConfettiController confettiController;

  const PlaceDetailMobileLayout({
    super.key,
    required this.place,
    required this.placeData,
    required this.accentColor,
    required this.portadaUrl,
    required this.distanceInMeters,
    required this.formatDistance,
    required this.onLaunchUrl,
    required this.menuStream,
    required this.categoryOrder,
    required this.aceptaPedidos,
    required this.deliveryDisponible,
    required this.aceptaReservas,
    required this.menuVisible,
    required this.canRate,
    required this.placeCameraPosition,
    required this.placeHasCoords,
    required this.onShowRatingDialog,
    required this.onCheckAndOpenReservation,
    required this.onShowDishImage,
    required this.onShowRegistrationDialog,
    required this.confettiController,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null || user.isAnonymous;
    final List<String> gallery =
        List<String>.from(placeData['gallery'] ?? placeData['fotos'] ?? []);

    return CustomScrollView(
      slivers: [
        // HEADER
        PlaceDetailHeader(
          placeId: place.id,
          placeName: place.name,
          coverImageUrl: portadaUrl,
          accentColor: accentColor,
        ),

        // SECTOR 1: INFO Y CONTACTO
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VenueInfoSection(
                  placeId: place.id,
                  description: placeData['descripcion'] as String?,
                  distanceInMeters: distanceInMeters,
                  formatDistance: formatDistance,
                  placeData: placeData,
                  onLaunchUrl: onLaunchUrl,
                ),
                const SizedBox(height: 16),
                SocialHoursCard(
                  placeData: placeData,
                ),
              ],
            ),
          ),
        ),

        // SECTOR 2: BOTONES DE ACCIÓN
        SliverToBoxAdapter(
          child: Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    if (isGuest && menuVisible) ...[
                      const SizedBox(height: 15),
                      ActionChipButton(
                        label: "VER MENÚ / CARTA",
                        icon: Icons.menu_book_rounded,
                        accentColor: Colors.white,
                        isPrimary: false,
                        onTap: () => ClientMenuModal.show(
                          context,
                          placeId: place.id,
                          menuStream: menuStream,
                          categoryOrder: categoryOrder,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildGuestInvitationBanner(context),
                    ],

                    if (!isGuest) ...[
                      ReservationStatusBanner(placeId: place.id),
                      const SizedBox(height: 16),
                      
                      // Chips de acción (Reservar y Ver Carta)
                      if (menuVisible || aceptaReservas) ...[
                        Row(
                          children: [
                            if (menuVisible)
                              Expanded(
                                child: ActionChipButton(
                                  label: "Ver Carta",
                                  icon: Icons.restaurant_menu,
                                  accentColor: accentColor,
                                  isPrimary: false,
                                  onTap: () => ClientMenuModal.show(
                                    context,
                                    placeId: place.id,
                                    menuStream: menuStream,
                                    categoryOrder: categoryOrder,
                                  ),
                                ),
                              ),
                            if (menuVisible && aceptaReservas)
                              const SizedBox(width: 12),
                            if (aceptaReservas)
                              Expanded(
                                child: ActionChipButton(
                                  label: "Reservar",
                                  icon: Icons.calendar_today,
                                  accentColor: accentColor,
                                  isPrimary: true,
                                  onTap: () => onCheckAndOpenReservation(context, place),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],

                    // BOTÓN PEDIR ONLINE (FLOTANTE/DESTACADO) - Ocupa todo el ancho
                    OrderButtonFloating(
                      deliveryDisponible: deliveryDisponible,
                      aceptaPedidos: aceptaPedidos,
                      menuVisible: menuVisible,
                      isGuest: isGuest,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientMenuScreen(placeId: place.id),
                          ),
                        );
                      },
                      onGuestPressed: onShowRegistrationDialog,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // SECTOR 3: MAPA, CALIFICAR, GALERÍA, OPINIONES
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // MAPA
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      liteModeEnabled: true,
                      initialCameraPosition: placeCameraPosition,
                      markers: {
                        if (placeHasCoords)
                          Marker(
                            markerId: const MarkerId('p'),
                            position: LatLng(place.lat, place.lng),
                          )
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: Text(
                      place.address,
                      style: const TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // BOTÓN CALIFICAR
                if (canRate)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => onShowRatingDialog(place),
                        icon: const Icon(Icons.star_rate_rounded, color: Colors.amber),
                        label: const Text(
                          "Calificar este lugar",
                          style: TextStyle(color: Colors.amber),
                        ),
                      ),
                    ),
                  ),

                // GALERÍA
                GallerySection(
                  gallery: gallery,
                  onImageTap: (url, name) => onShowDishImage(context, url, name),
                ),

                // OPINIONES
                ReviewsSection(
                  placeId: place.id,
                  accentColor: accentColor,
                ),

                // PANEL DE GESTIÓN
                if (FirebaseAuth.instance.currentUser != null)
                  FutureBuilder<List<bool>>(
                    future: Future.wait([
                      FirebaseFirestore.instance
                          .collection("usuarios")
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get()
                          .then((doc) {
                        final data = doc.data();
                        return data?['role'] == true ||
                            data?['role'] == 'admin' ||
                            data?['esDueno'] == true;
                      }),
                      FirebaseFirestore.instance
                          .collection('places')
                          .doc(place.id)
                          .collection('staff')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get()
                          .then((doc) => doc.exists),
                    ]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      if (!snapshot.data![0] && !snapshot.data![1]) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(top: 20),
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: snapshot.data![0]
                                ? Colors.amber
                                : Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          icon: Icon(
                            snapshot.data![0]
                                ? Icons.shield
                                : Icons.admin_panel_settings,
                          ),
                          label: Text(
                            snapshot.data![0]
                                ? "PANEL SUPER ADMIN"
                                : "PANEL DE TRABAJO",
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PanelDuenoScreen(placeId: place.id),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestInvitationBanner(BuildContext context) {
    return InkWell(
      onTap: onShowRegistrationDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
          gradient: LinearGradient(
            colors: [Colors.orangeAccent.withValues(alpha: 0.05), Colors.transparent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.orangeAccent, size: 24),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ÚNETE A LA COMUNIDAD",
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    "Reserva, pide online y suma puntos.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

}
