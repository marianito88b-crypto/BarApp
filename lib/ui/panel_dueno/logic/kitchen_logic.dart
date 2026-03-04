import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Mixin que contiene la lógica de negocio para el monitor de cocina
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin KitchenLogicMixin<T extends StatefulWidget> on State<T> {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  // 🔊 Audio y Lógica
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription? _ordersSubscription;
  Timer? _monitorTimer;

  // 🧠 Memoria local para saber qué es nuevo y qué ya avisamos
  Set<String> _knownOrderIds = {};
  final Set<String> _alertedDelayedIds = {};
  bool _isFirstLoad = true; // Para no sonar como locos al abrir la app

  /// Inicializa el listener de nuevos pedidos y el monitor de demoras
  ///
  /// Debe ser llamado desde initState() del State que usa este Mixin
  void initKitchenLogic() {
    _initOrderListener();
    _startDelayMonitor();
  }

  /// Limpia todos los recursos del Mixin (Timer, StreamSubscription, AudioPlayer)
  ///
  /// MEJORA CRÍTICA: Debe ser llamado desde dispose() del State para evitar
  /// sonidos fantasmas o fugas de memoria cuando el cocinero cierra el monitor
  void disposeKitchenLogic() {
    _ordersSubscription?.cancel();
    _monitorTimer?.cancel();
    _audioPlayer.dispose();
  }

  // ===========================================================================
  // 👂 1. ESCUCHAR NUEVOS PEDIDOS (Sonido "DING")
  // ===========================================================================
  void _initOrderListener() {
    _ordersSubscription = FirebaseFirestore.instance
        .collection("places")
        .doc(placeId)
        .collection("orders")
        .where('estado', isEqualTo: 'pendiente')
  
        .snapshots()
        .listen((snapshot) {
          // Lista actual de IDs en la base de datos
          final currentIds = snapshot.docs.map((d) => d.id).toSet();

          // Detectar nuevos (Están en current pero no en known)
          final newOrders = currentIds.difference(_knownOrderIds);

          if (newOrders.isNotEmpty && !_isFirstLoad) {
            // 🔥 ¡NUEVO PEDIDO DETECTADO!
            _playNewOrderSound();
            _mostrarNotificacionVisual("¡Nueva Comanda Entrante!");
          }

          // Actualizamos nuestra memoria
          _knownOrderIds = currentIds;
          _isFirstLoad = false;
        });
  }

  // ===========================================================================
  // ⏰ 2. MONITOR DE DEMORAS (Sonido "ALERTA" a los 15 min)
  // ===========================================================================
  void _startDelayMonitor() {
    // Revisar cada 1 minuto
    _monitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!mounted) return;

      final snapshot = await FirebaseFirestore.instance
          .collection("places")
          .doc(placeId)
          .collection("orders")
          .where('estado', isEqualTo: 'pendiente')
          // 🔥 QUITAMOS EL FILTRO AQUÍ TAMBIÉN
          .get();

      bool hayDemorasGraves = false;
      final now = DateTime.now();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // 🔑 Timestamp OFICIAL del sistema
        final Timestamp? ts = data['createdAt'] ?? data['timestamp']; // Soporte doble nombre
        if (ts == null) continue;

        final diferencia = now.difference(ts.toDate()).inMinutes;

        // ⏰ Si pasó 15 minutos y NO avisamos aún
        if (diferencia >= 15 && !_alertedDelayedIds.contains(doc.id)) {
          hayDemorasGraves = true;
          _alertedDelayedIds.add(doc.id); // Anti-spam por pedido
        }
      }

      if (hayDemorasGraves) {
        _playDelaySound(); // 🚨 Alerta sonora
        _mostrarNotificacionVisual(
          "⚠️ ATENCIÓN: Pedidos demorados (+15 min)",
        );
      }
    });
  }

  /// Reproduce el sonido de nuevo pedido
  Future<void> _playNewOrderSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(
        AssetSource('sounds/ding.mp3'),
      );
    } catch (e) {
      debugPrint("Error audio nuevo pedido: $e");
    }
  }

  /// Reproduce el sonido de alerta por demoras
  Future<void> _playDelaySound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/ding.mp3'));
    } catch (e) {
      debugPrint("Error audio delay: $e");
    }
  }

  /// Muestra una notificación visual (SnackBar) al usuario
  void _mostrarNotificacionVisual(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.orangeAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
