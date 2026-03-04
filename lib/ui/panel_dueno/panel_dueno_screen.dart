import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// --- IMPORTS ---
import 'package:barapp/ui/panel_dueno/layouts/owner_desktop_layout.dart';
import 'package:barapp/ui/panel_dueno/layouts/owner_mobile_layout.dart';
import 'package:barapp/ui/panel_dueno/logic/panel_dueno_logic.dart';
import 'package:barapp/ui/panel_dueno/widgets/owner_nav_bar.dart';
import 'sections/dashboard_mobile.dart';
import 'sections/reservas_mobile.dart';
import 'sections/mesas_mobile.dart';
import 'sections/config_mobile.dart';
import 'sections/menu_mobile.dart';
import 'sections/delivery_mobile.dart';
import 'sections/cocina_mobile.dart';
import 'sections/events_manager.dart';
import 'package:barapp/ui/panel_dueno/pos/control_caja_screen.dart';
import 'sections/gastos_mobile.dart';
import 'package:barapp/ui/panel_dueno/sections/qr_generator_mobile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barapp/ui/ventas_externas/ventas_externas_screen.dart';

class PanelDuenoScreen extends StatefulWidget {
  final String placeId;
  const PanelDuenoScreen({super.key, required this.placeId});

  @override
  State<PanelDuenoScreen> createState() => _PanelDuenoScreenState();
}

class _PanelDuenoScreenState extends State<PanelDuenoScreen>
    with PanelDuenoLogic {
  int _currentIndex = 0;
  String _userRole = 'cargando';

  bool _trialSnackShown = false;

  List<NavItem>? _cachedNavItems;
  String? _cachedRole;

  late final Stream<DocumentSnapshot> _placesStream;

  @override
  List<NavItem> getNavItemsForCurrentRole() => _getCachedNavItems();

  @override
  void setCurrentNavIndex(int index) => setState(() => _currentIndex = index);

  @override
  void initState() {
    super.initState();
    _placesStream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .snapshots();
    _checkContextualRole();
    initPanelDuenoAudioAndListener();
  }

  @override
  void dispose() {
    disposePanelDuenoLogic();
    super.dispose();
  }

  Future<void> _checkContextualRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      var userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .get();
      if (!userDoc.exists) {
        userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
      }

      if (userDoc.exists) {
        final uData = userDoc.data();
        final roleValue = uData?['role'];
        if (roleValue == true ||
            roleValue == 'admin' ||
            roleValue.toString().toLowerCase() == 'true') {
          if (mounted) setState(() => _userRole = 'admin');
          return;
        }
      }

      final staffDoc =
          await FirebaseFirestore.instance
              .collection('places')
              .doc(widget.placeId)
              .collection('staff')
              .doc(uid)
              .get();

      if (staffDoc.exists) {
        final data = staffDoc.data()!;
        String rawRole = data['rol'] ?? data['role'] ?? 'mozo';
        if (mounted) setState(() => _userRole = rawRole.toLowerCase().trim());
      } else {
        final placeDoc =
            await FirebaseFirestore.instance
                .collection('places')
                .doc(widget.placeId)
                .get();
        final placeData = placeDoc.data();
        if (placeData?['userId'] == uid || placeData?['ownerId'] == uid) {
          if (mounted) setState(() => _userRole = 'admin');
        } else {
          if (mounted) setState(() => _userRole = 'error');
        }
      }
    } catch (e) {
      debugPrint("🔥 ERROR VERIFICANDO ROL: $e");
      if (mounted) setState(() => _userRole = 'error');
    }
  }

  Future<void> _contactarWhatsApp() async {
    const phoneNumber = '5493625163528'; // <-- TU NÚMERO
    final message = Uri.encodeComponent(
      'Hola! Quiero activar el Plan PRO de BarApp para mi local.',
    );

    final uri = Uri.parse('https://wa.me/$phoneNumber?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_person, color: Colors.orangeAccent),
                SizedBox(width: 10),
                Text("Función PRO", style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              "Tu periodo de prueba ha finalizado.\n\nPara acceder a Caja, Stock, Reservas y más, activá el plan PRO.\n\n¡Tu Carta Digital sigue siendo GRATIS para siempre!",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Entendido",
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _contactarWhatsApp();
                },
                child: const Text("Activar Ahora"),
              ),
            ],
          ),
    );
  }

  // --------------------------------------------------------------------------
  // 🏗️ BUILD PRINCIPAL CON STREAM
  // --------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_userRole == 'cargando') {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: CircularProgressIndicator(color: Colors.orangeAccent),
        ),
      );
    }
    if (_userRole == 'error') {
      return const Scaffold(
        backgroundColor: Color(0xFF0E0E0E),
        body: Center(
          child: Text(
            "No tienes permisos para acceder a este local.",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }


    return StreamBuilder<DocumentSnapshot>(
      stream: _placesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF0E0E0E),
            body: Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            ),
          );
        }

        final placeData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        final uid = FirebaseAuth.instance.currentUser?.uid;

        final bool isRealOwner = placeData['ownerId'] == uid;

        if (isRealOwner &&
            placeData['isPremium'] != true &&
            placeData['fechaInicioPrueba'] == null &&
            !_trialSnackShown) {
          _trialSnackShown = true;

          Future.microtask(() async {
            try {
              await FirebaseFirestore.instance
                  .collection('places')
                  .doc(widget.placeId)
                  .update({'fechaInicioPrueba': FieldValue.serverTimestamp()});

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "🚀 ¡Bienvenido! Arrancan tus 30 días de prueba PRO.",
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 4),
                ),
              );
            } catch (e) {
              debugPrint("Error activando prueba: $e");
            }
          });
        }

        // 🧮 CALCULAMOS PERMISOS EN TIEMPO REAL
        final int daysLeft = daysRemaining(placeData);

        final navItems = _getCachedNavItems();
        if (_currentIndex >= navItems.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = 0);
          });
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth >= 900;
            if (isDesktop) {
              return OwnerDesktopLayout(
                navItems: navItems,
                currentIndex: _currentIndex,
                placeData: placeData,
                daysLeft: daysLeft,
                userRole: _userRole,
                placeId: widget.placeId,
                audioEnabled: audioEnabled,
                isFeatureEnabled: isFeatureEnabled,
                onToggleAudio: togglePanelDuenoAudio,
                onNavTap: (index) {
                  final item = navItems[index];
                  bool isLocked =
                      !isFeatureEnabled(item.label, placeData);
                  if (isLocked) {
                    _showLockedDialog();
                  } else {
                    setState(() => _currentIndex = index);
                  }
                },
                onShowLockedDialog: _showLockedDialog,
              );
            } else {
              return OwnerMobileLayout(
                navItems: navItems,
                currentIndex: _currentIndex,
                placeData: placeData,
                daysLeft: daysLeft,
                userRole: _userRole,
                audioEnabled: audioEnabled,
                isFeatureEnabled: isFeatureEnabled,
                onToggleAudio: togglePanelDuenoAudio,
                onNavTap: (index) {
                  final item = navItems[index];
                  bool isLocked =
                      !isFeatureEnabled(item.label, placeData);
                  if (isLocked) {
                    _showLockedDialog();
                  } else {
                    setState(() => _currentIndex = index);
                  }
                },
              );
            }
          },
        );
      },
    );
  }

  // --- HELPERS Y CONFIGURACIÓN DE ROLES ---
  List<NavItem> _getCachedNavItems() {
    if (_cachedNavItems == null || _cachedRole != _userRole) {
      _cachedRole = _userRole;
      _cachedNavItems = _getNavItemsForRole(_userRole);
    }
    return _cachedNavItems!;
  }

  List<NavItem> _getNavItemsForRole(String role) {
    final String currentUserEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'sin-email@local.com';

    // 👨‍🍳 COCINERO
    if (role == 'cocinero') {
      return [
        NavItem(
          "Pedidos",
          Icons.soup_kitchen_outlined,
          Icons.soup_kitchen,
          CocinaMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Recetas",
          Icons.menu_book_outlined,
          Icons.menu_book,
          MenuMobile(placeId: widget.placeId),
        ),
      ];
    }
    // 🤵 MOZO
    else if (role == 'mozo') {
      return [
        NavItem(
          "Mesas",
          Icons.table_restaurant_outlined,
          Icons.table_restaurant,
          MesasMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Reservas",
          Icons.event_note_outlined,
          Icons.event_note,
          ReservasMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Carta",
          Icons.restaurant_menu_outlined,
          Icons.restaurant_menu,
          MenuMobile(placeId: widget.placeId),
        ),
      ];
    }
    // 🛵 REPARTIDOR
    else if (role == 'repartidor') {
      return [
        NavItem(
          "Delivery",
          Icons.delivery_dining_outlined,
          Icons.delivery_dining,
          DeliveryMobile(
            placeId: widget.placeId,
            userEmail: currentUserEmail,
            userRol: role,
          ),
        ),
      ];
    }
    // 💰 CAJERO
    else if (role == 'cajero') {
      return [
        NavItem(
          "Inicio",
          Icons.dashboard_outlined,
          Icons.dashboard,
          DashboardMobile(
            placeId: widget.placeId,
            onNavigateToTab: (tabName) {
              // Buscar el índice de la pestaña por nombre
              final navItems = _getNavItemsForRole(_userRole);
              final index = navItems.indexWhere((item) => item.label.toLowerCase() == tabName.toLowerCase());
              if (index != -1) {
                setState(() => _currentIndex = index);
              }
            },
          ),
        ),
        NavItem(
          "Caja",
          Icons.point_of_sale_outlined,
          Icons.point_of_sale,
          ControlCajaScreen(placeId: widget.placeId),
        ),
        NavItem(
          "Ventas Ext.",
          Icons.receipt_long_outlined,
          Icons.receipt_long,
          VentasExternasScreen(placeId: widget.placeId),
        ),
        NavItem(
          "Mesas",
          Icons.table_restaurant_outlined,
          Icons.table_restaurant,
          MesasMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Delivery",
          Icons.delivery_dining_outlined,
          Icons.delivery_dining,
          DeliveryMobile(
            placeId: widget.placeId,
            userEmail: currentUserEmail,
            userRol: role,
          ),
        ),
        NavItem(
          "Reservas",
          Icons.event_note_outlined,
          Icons.event_note,
          ReservasMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Carta",
          Icons.restaurant_menu_outlined,
          Icons.restaurant_menu,
          MenuMobile(placeId: widget.placeId),
        ),
      ];
    }
    // 👑 ADMIN (Dueño)
    else {
      return [
        NavItem(
          "Inicio",
          Icons.dashboard_outlined,
          Icons.dashboard,
          DashboardMobile(
            placeId: widget.placeId,
            onNavigateToTab: (tabName) {
              // Buscar el índice de la pestaña por nombre
              final navItems = _getNavItemsForRole(_userRole);
              final index = navItems.indexWhere((item) => item.label.toLowerCase() == tabName.toLowerCase());
              if (index != -1) {
                setState(() => _currentIndex = index);
              }
            },
          ),
        ),
        NavItem(
          "Mi QR",
          Icons.qr_code_2_outlined,
          Icons.qr_code_2,
          QRGeneratorMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Caja",
          Icons.point_of_sale_outlined,
          Icons.point_of_sale,
          ControlCajaScreen(placeId: widget.placeId),
        ),
        NavItem(
          "Ventas Ext.",
          Icons.receipt_long_outlined,
          Icons.receipt_long,
          VentasExternasScreen(placeId: widget.placeId),
        ),
        NavItem(
          "Gastos",
          Icons.request_quote_outlined,
          Icons.request_quote,
          GastosMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Reservas",
          Icons.event_note_outlined,
          Icons.event_note,
          ReservasMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Mesas",
          Icons.table_restaurant_outlined,
          Icons.table_restaurant,
          MesasMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Delivery",
          Icons.delivery_dining_outlined,
          Icons.delivery_dining,
          DeliveryMobile(
            placeId: widget.placeId,
            userEmail: currentUserEmail,
            userRol: role,
          ),
        ),
        NavItem(
          "Cocina",
          Icons.soup_kitchen_outlined,
          Icons.soup_kitchen,
          CocinaMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Carta",
          Icons.restaurant_menu_outlined,
          Icons.restaurant_menu,
          MenuMobile(placeId: widget.placeId),
        ),
        NavItem(
          "Eventos",
          Icons.local_activity_outlined,
          Icons.local_activity,
          EventsManagerScreen(placeId: widget.placeId),
        ),
        NavItem(
          "Config",
          Icons.settings_outlined,
          Icons.settings,
          ConfigMobile(placeId: widget.placeId),
        ),
      ];
    }
  }
}