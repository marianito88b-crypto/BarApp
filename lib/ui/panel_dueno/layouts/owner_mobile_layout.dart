import 'package:flutter/material.dart';

import 'package:barapp/ui/panel_dueno/widgets/owner_nav_bar.dart';

/// Layout móvil del panel de dueño con barra de navegación flotante.
class OwnerMobileLayout extends StatelessWidget {
  final List<NavItem> navItems;
  final int currentIndex;
  final Map<String, dynamic> placeData;
  final int daysLeft;
  final String userRole;
  final bool audioEnabled;
  final bool Function(String, Map<String, dynamic>) isFeatureEnabled;
  final VoidCallback onToggleAudio;
  final void Function(int) onNavTap;

  const OwnerMobileLayout({
    super.key,
    required this.navItems,
    required this.currentIndex,
    required this.placeData,
    required this.daysLeft,
    required this.userRole,
    required this.audioEnabled,
    required this.isFeatureEnabled,
    required this.onToggleAudio,
    required this.onNavTap,
  });

  String _getTitle(String role) {
    if (role == 'cocinero') return "Panel Cocina";
    if (role == 'mozo') return "Panel Mozo";
    if (role == 'cajero') return "Panel Caja";
    return "Administración";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              _getTitle(userRole),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              daysLeft == -1
                  ? "PLAN PRO"
                  : daysLeft > 0
                      ? "$daysLeft días de prueba"
                      : "MODO GRATUITO",
              style: TextStyle(
                fontSize: 10,
                color: daysLeft == -1
                    ? Colors.greenAccent
                    : daysLeft > 0
                        ? Colors.orangeAccent
                        : Colors.grey,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF151515),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: onToggleAudio,
            icon: Icon(
              audioEnabled ? Icons.volume_up : Icons.volume_off,
              color: audioEnabled ? Colors.greenAccent : Colors.redAccent,
            ),
            tooltip: "Activar/Desactivar Sonido",
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: IndexedStack(
              index: currentIndex,
              children: navItems.map((e) => e.widget).toList(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              child: OwnerNavBar(
                items: navItems,
                currentIndex: currentIndex,
                placeData: placeData,
                isFeatureEnabled: isFeatureEnabled,
                onTap: onNavTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
