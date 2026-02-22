import 'package:barapp/ui/home/widgets/events_edge_button_left.dart';
import 'package:flutter/material.dart';
import 'package:barapp/models/categories.dart';

// --- Imports de Widgets ---
import 'widgets/community_edge_button_left.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/feed/home_top_header.dart';
import 'widgets/feed/home_filter_chip.dart';
import 'widgets/feed/settings_bottom_sheet.dart';
import 'widgets/feed/home_stories_row.dart';
import 'widgets/feed/home_places_list.dart';
import 'logic/media_picker_logic.dart';
import 'logic/home_logic.dart';

// --- Imports de Pantallas ---
import 'package:barapp/screens/story_viewer_screen.dart' show StoryViewerScreen;
import '../chat/online_users_screen.dart';
import 'package:barapp/ui/client/client_orders_screen.dart';
import 'package:barapp/ui/events/events_screen.dart';
import 'package:barapp/services/guest_guard.dart';


// ... (Constantes y constructor de HomeFeedScreen no cambian) ...
// [Immersive content redacted for brevity.]
// --- CONSTANTES DE LAYOUT ---
const double _kLeftGutter = 52.0; // Ancho del "borde" izquierdo
const double _kTopHeaderHeight = 60.0;
const double _kSearchBarHeight = 56.0;
const double _kStoriesHeight = 84.0; // Alto para la fila de historias
// ---

class HomeFeedScreen extends StatefulWidget {
  final Category category;
  final VoidCallback onOpenWall;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenChat;

  const HomeFeedScreen({
    super.key,
    required this.category,
    required this.onOpenWall,
    required this.onOpenProfile,
    required this.onOpenSettings,
    required this.onOpenChat,
  });

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> with HomeLogicMixin {
  String _sortBy = 'popular'; // opciones: 'popular', 'distance'
  bool _showOpenOnly = false; // Toggle para "Abierto ahora"

  @override
  void initState() {
    super.initState();
    initHomeLogic();
  }

  @override
  void dispose() {
    disposeHomeLogic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF7F50);
    final size = MediaQuery.of(context).size;
    final double listMaxWidth = size.width < 700 ? size.width - _kLeftGutter - 24 : 520;

    final double listTopPadding = _kTopHeaderHeight + _kSearchBarHeight + _kStoriesHeight + 16;

    return Scaffold(
      // 1. Color de fondo base (por si la imagen no carga o tiene transparencias)
      backgroundColor: Colors.black, 
      // 2. Extendemos el cuerpo para que el patrón llegue hasta arriba de todo
      extendBodyBehindAppBar: true, 
      
      body: Container(
        // 🔥 AQUI ESTÁ LA MAGIA DEL FONDO CON PATRÓN
        decoration: const BoxDecoration(
          color: Colors.black, 
          image: DecorationImage(
            // Asegurate de tener esta imagen en tus assets y declarada en pubspec.yaml
            image: AssetImage('assets/images/pattern_bg.png'), 
            repeat: ImageRepeat.repeat, // Esto crea el efecto mosaico infinito
            opacity: 0.15, // Opacidad baja para que sea sutil y no moleste la lectura
          ),
        ),
        
        // El contenido original de tu pantalla va aquí adentro
        child: Stack(
          children: [
            // --- 1. LISTA CENTRAL DE BARES ---
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(_kLeftGutter + 12, listTopPadding, 12, 24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: listMaxWidth),
                    child: HomePlacesList(
                      places: places,
                      followingIds: followingIds,
                      searchQuery: searchQuery,
                      sortBy: _sortBy,
                      onlyOpen: _showOpenOnly,
                      userLat: userLat,
                      userLng: userLng,
                      isLoading: isLoading,
                      isVenueOpen: isVenueOpen,
                      onFollowToggle: handleFollow,
                    ),
                  ),
                ),
              ),
            ),

            // --- 2. HEADER SUPERIOR ---
            Positioned(
              top: 0, left: 8, right: 8, height: _kTopHeaderHeight,
              child: SafeArea( // Agregamos SafeArea solo arriba para el header
                bottom: false,
                child: HomeTopHeader(
                  onOpenProfile: widget.onOpenProfile,
                  onOpenChat: widget.onOpenChat,
                  onOpenSettings: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (_) => const SettingsBottomSheet(),
                    );
                  },
                  onOpenConnected: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineUsersScreen())),
                  onOpenOrders: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrdersScreen())),
                ),
              ),
            ),

            // --- 🔥 3. FILA FUSIONADA: BUSCADOR + CHIPS ---
            Positioned(
              top: _kTopHeaderHeight + MediaQuery.of(context).padding.top, // Ajuste por SafeArea
              left: _kLeftGutter + 12,
              right: 0,
              height: _kSearchBarHeight,
              child: Row(
                children: [
                  // A. BUSCADOR
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SearchBarWidget(
                        initialQuery: searchQuery,
                        onSearch: updateSearchQuery,
                        onFilterTap: () {},
                      ),
                    ),
                  ),

                  // B. CHIPS
                  Expanded(
                    flex: 6,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                      children: [
                        HomeFilterChip(
                          label: _sortBy == 'popular' ? '🔥 Populares' : '📍 Cercanía',
                          isActive: _sortBy == 'distance',
                          onTap: () {
                            setState(() {
                              _sortBy = _sortBy == 'popular' ? 'distance' : 'popular';
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        HomeFilterChip(
                          label: 'Abierto',
                          isActive: _showOpenOnly,
                          icon: Icons.access_time_rounded,
                          onTap: () {
                            setState(() {
                              _showOpenOnly = !_showOpenOnly;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        HomeFilterChip(
                          label: 'Filtros',
                          isActive: false,
                          icon: Icons.tune_rounded,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente...")));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. HISTORIAS ---
            Positioned(
              top: _kTopHeaderHeight + _kSearchBarHeight + 4 + MediaQuery.of(context).padding.top, // Ajuste por SafeArea
              left: 8.0,
              right: 0.0,
              height: _kStoriesHeight,
              child: HomeStoriesRow(
                accent: accent,
                onAdd: () => MediaPickerLogic.pickStory(context),
                onTapStory: (story, index, allStories) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, _, _) => StoryViewerScreen(
                        stories: allStories,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- 5. BOTONES LATERALES ---
            // Ajustamos el top para que bajen un poco si hay notch/isla dinámica
           Positioned(
  left: -10, 
  top: MediaQuery.of(context).padding.top, 
  bottom: 0, 
  child: Center(
    child: CommunityEdgeButtonLeft(
      onTap: () {
        // 🔥 APLICAMOS EL GUARD
        GuestGuard.run(context, action: widget.onOpenWall);
      },
    )
  )
),

Positioned(
  left: -10, 
  top: 470 + MediaQuery.of(context).padding.top, 
  child: EventsEdgeButtonLeft(
    onTap: () {
      // 🔥 APLICAMOS EL GUARD
      GuestGuard.run(context, action: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EventsScreen()));
      });
    }
  )
),
          ],
        ),
      ),
    );
  }
}

// --- WIDGETS INTERNOS DE LA PANTALLA ---