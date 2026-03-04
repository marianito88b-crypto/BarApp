import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:barapp/ui/panel_dueno/panel_dueno_screen.dart';
import 'package:barapp/ui/panel_dueno/widgets/owner_nav_bar.dart';

/// Mixin con la lógica de permisos PRO, audio y alertas del panel de dueño.
mixin PanelDuenoLogic on State<PanelDuenoScreen> {
  List<NavItem> getNavItemsForCurrentRole();
  void setCurrentNavIndex(int index);

  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _ordersSubscription;
  bool _audioEnabled = false;

  /// Mapeo entre label UI y key en Firestore.
  Map<String, String> get _featureKeys => const {
        'Caja': 'caja',
        'Ventas Ext.': 'ventasExternas',
        'Gastos': 'gastos',
        'Reservas': 'reservas',
        'Mesas': 'mesas',
        'Delivery': 'delivery',
        'Cocina': 'cocina',
        'Eventos': 'eventos',
        'Config': 'config',
      };

  bool get audioEnabled => _audioEnabled;

  void initPanelDuenoAudioAndListener() {
    _audioPlayer.setSource(AssetSource('sounds/ding.mp3'));

    _ordersSubscription = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('orders')
        .where('tipo', isEqualTo: 'delivery')
        .where('estado', isEqualTo: 'pendiente')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          triggerPanelDuenoAlert(change.doc);
        }
      }
    });
  }

  Future<void> triggerPanelDuenoAlert(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;

    if (data['tipo'] != 'delivery') return;
    if (data['estado'] != 'pendiente') return;

    final cliente = data['clienteNombre'] ?? 'Cliente';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text("¡NUEVO PEDIDO DE $cliente!")),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: "VER",
            textColor: Colors.white,
            onPressed: () {
              final navItems = getNavItemsForCurrentRole();
              final deliveryIndex =
                  navItems.indexWhere((item) => item.label == "Delivery");
              if (deliveryIndex != -1) {
                setCurrentNavIndex(deliveryIndex);
              }
            },
          ),
        ),
      );
    }

    if (_audioEnabled) {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
      } catch (e) {
        debugPrint("Error reproduciendo sonido: $e");
      }
    }
  }

  void togglePanelDuenoAudio() async {
    if (!_audioEnabled) {
      await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
      if (!mounted) return;
      setState(() => _audioEnabled = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔊 Sonido Activado"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _audioEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔇 Sonido Silenciado"),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void disposePanelDuenoLogic() {
    _ordersSubscription?.cancel();
    _audioPlayer.dispose();
  }

  // --------------------------------------------------------------------------
  // Lógica de permisos (Freemium)
  // --------------------------------------------------------------------------

  bool hasProAccess(Map<String, dynamic> placeData) {
    if (placeData['isPremium'] == true) return true;

    final Timestamp? trialStartTs = placeData['fechaInicioPrueba'];
    if (trialStartTs == null) return false;

    final trialEnd = trialStartTs.toDate().add(const Duration(days: 30));
    return DateTime.now().isBefore(trialEnd);
  }

  int daysRemaining(Map<String, dynamic> placeData) {
    if (placeData['isPremium'] == true) return -1;

    final Timestamp? trialStartTs = placeData['fechaInicioPrueba'];
    if (trialStartTs == null) return 0;

    final trialStart = trialStartTs.toDate();
    final trialEnd = trialStart.add(const Duration(days: 30));
    final now = DateTime.now();

    if (now.isAfter(trialEnd)) return 0;

    return trialEnd.difference(now).inDays + 1;
  }

  bool isFeatureEnabled(String label, Map<String, dynamic> placeData) {
    if (placeData['isPremium'] == true) return true;
    if (daysRemaining(placeData) > 0) return true;

    final key = _featureKeys[label];
    if (key == null) return true;

    final Map<String, dynamic> features =
        placeData['features'] as Map<String, dynamic>? ?? {};

    final Map<String, dynamic> expirations =
        placeData['featureExpirations'] as Map<String, dynamic>? ?? {};

    if (features[key] != true) return false;

    if (expirations[key] is Timestamp) {
      final expiresAt = (expirations[key] as Timestamp).toDate();
      return DateTime.now().isBefore(expiresAt);
    }

    return true;
  }
}
