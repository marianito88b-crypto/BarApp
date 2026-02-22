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

/// Layout desktop para PlaceDetailScreen
/// 
/// Muestra info y menú a la izquierda, mapa y reseñas en columna derecha fija
class PlaceDetailDesktopLayout extends StatelessWidget {
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

  const PlaceDetailDesktopLayout({
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

        // CONTENIDO PRINCIPAL: DOS COLUMNAS
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // COLUMNA IZQUIERDA: Info y Menú
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INFO BÁSICA
                      VenueInfoSection(
                        placeId: place.id,
                        description: placeData['descripcion'] as String?,
                        distanceInMeters: distanceInMeters,
                        formatDistance: formatDistance,
                        placeData: placeData,
                        onLaunchUrl: onLaunchUrl,
                      ),
                      const SizedBox(height: 24),

                      // HORARIOS
                      SocialHoursCard(
                        placeData: placeData,
                      ),
                      const SizedBox(height: 24),

                      // BOTONES DE ACCIÓN
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

                      // BOTÓN PEDIR ONLINE (DESTACADO)
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
                      const SizedBox(height: 32),

                      // GALERÍA
                      GallerySection(
                        gallery: gallery,
                        onImageTap: (url, name) => onShowDishImage(context, url, name),
                      ),

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
                    ],
                  ),
                ),

                const SizedBox(width: 32),

                // COLUMNA DERECHA FIJA: Mapa y Reseñas
                SizedBox(
                  width: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // MAPA
                      Container(
                        height: 300,
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
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Center(
                          child: Text(
                            place.address,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // OPINIONES (Scroll independiente con altura máxima)
                      Expanded(
                        child: SingleChildScrollView(
                          child: ReviewsSection(
                            placeId: place.id,
                            accentColor: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

}
