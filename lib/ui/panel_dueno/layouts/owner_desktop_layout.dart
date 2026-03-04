import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:barapp/ui/panel_dueno/widgets/owner_nav_bar.dart';

/// Layout desktop del panel de dueño con sidebar.
class OwnerDesktopLayout extends StatefulWidget {
  final List<NavItem> navItems;
  final int currentIndex;
  final Map<String, dynamic> placeData;
  final int daysLeft;
  final String userRole;
  final String placeId;
  final bool audioEnabled;
  final bool Function(String, Map<String, dynamic>) isFeatureEnabled;
  final VoidCallback onToggleAudio;
  final void Function(int) onNavTap;
  final VoidCallback onShowLockedDialog;

  const OwnerDesktopLayout({
    super.key,
    required this.navItems,
    required this.currentIndex,
    required this.placeData,
    required this.daysLeft,
    required this.userRole,
    required this.placeId,
    required this.audioEnabled,
    required this.isFeatureEnabled,
    required this.onToggleAudio,
    required this.onNavTap,
    required this.onShowLockedDialog,
  });

  @override
  State<OwnerDesktopLayout> createState() => _OwnerDesktopLayoutState();
}

class _OwnerDesktopLayoutState extends State<OwnerDesktopLayout> {
  late final Stream<QuerySnapshot> _cajaStream;

  @override
  void initState() {
    super.initState();
    _cajaStream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('caja_sesiones')
        .where('estado', isEqualTo: 'abierta')
        .limit(1)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.orangeAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  "BAR APP POS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    widget.userRole.toUpperCase(),
                    style: TextStyle(
                      color: accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.daysLeft > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${widget.daysLeft} días de prueba",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.daysLeft == 0)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Prueba finalizada",
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.daysLeft == -1)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "PLAN PRO ACTIVO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: widget.onToggleAudio,
                  style: TextButton.styleFrom(
                    backgroundColor: widget.audioEnabled
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  icon: Icon(
                    widget.audioEnabled ? Icons.volume_up : Icons.volume_off,
                    color: widget.audioEnabled ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  label: Text(
                    widget.audioEnabled ? "SONIDO ON" : "ACTIVAR SONIDO",
                    style: TextStyle(
                      color: widget.audioEnabled ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (widget.userRole == 'admin' || widget.userRole == 'cajero')
                  StreamBuilder<QuerySnapshot>(
                    stream: _cajaStream,
                    builder: (context, snapshot) {
                      bool isAbierta =
                          snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                      bool isCajaLocked =
                          !widget.isFeatureEnabled('Caja', widget.placeData);

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAbierta
                                ? const Color(0xFF1E3A25)
                                : const Color(0xFF3A251E),
                            foregroundColor: isAbierta
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            alignment: Alignment.centerLeft,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isAbierta
                                    ? Colors.greenAccent.withValues(alpha: 0.5)
                                    : Colors.orangeAccent.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          icon: Icon(
                            isAbierta ? Icons.lock_open : Icons.lock_outline,
                            size: 20,
                          ),
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAbierta ? "CAJA ABIERTA" : "CAJA CERRADA",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                isAbierta ? "Ver Arqueo" : "Iniciar Turno",
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          onPressed: () {
                            if (isCajaLocked) {
                              widget.onShowLockedDialog();
                              return;
                            }
                            int cajaIndex =
                                widget.navItems.indexWhere((item) => item.label == "Caja");
                            if (cajaIndex != -1) widget.onNavTap(cajaIndex);
                          },
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: widget.navItems.length,
                    itemBuilder: (_, i) {
                      final bool isSelected = i == widget.currentIndex;
                      final item = widget.navItems[i];
                      bool isLocked =
                          !widget.isFeatureEnabled(item.label, widget.placeData);

                      return InkWell(
                        onTap: isLocked
                            ? widget.onShowLockedDialog
                            : () => widget.onNavTap(i),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isLocked
                                    ? Icons.lock
                                    : (isSelected
                                        ? item.iconSelected
                                        : item.iconOutlined),
                                color: isLocked
                                    ? Colors.grey
                                    : (isSelected
                                        ? Colors.black
                                        : Colors.white54),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                item.label,
                                style: TextStyle(
                                  color: isLocked
                                      ? Colors.grey
                                      : (isSelected
                                          ? Colors.black
                                          : Colors.white70),
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (isLocked) const Spacer(),
                              if (isLocked)
                                const Text(
                                  "PRO",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "v2.2 Desktop",
                    style: TextStyle(color: Colors.white24, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: widget.currentIndex,
              children: widget.navItems.map((e) => e.widget).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
