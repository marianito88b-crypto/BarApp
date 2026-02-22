import 'dart:async'; // ⬅️ Necesario para el Timer
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService with WidgetsBindingObserver {
  final String userId;
  bool _isInitialized = false;
  Timer? _heartbeatTimer; // ⏱️ El corazón del servicio

  PresenceService({required this.userId});

  void init() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    
    // 1. Nos ponemos Online ya
    setOnline(true);
    
    // 2. Iniciamos el latido: Cada 2 minutos actualiza que seguimos vivos
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      // Solo actualizamos si la app está en primer plano
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        setOnline(true);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline(true);
    } else {
      // Si la app pasa a segundo plano, avisamos (pero el sistema puede matar el proceso antes)
      setOnline(false);
    }
  }

  Future<void> setOnline(bool isOnline) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('usuarios').doc(userId);
      
      await userDoc.set({ 
        'estado': isOnline ? 'online' : 'offline',
        'ultimaVezOnline': FieldValue.serverTimestamp(), // Esto es clave
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint('Error actualizando presencia: $e');
    }
  }

  void dispose() {
    if (!_isInitialized) return;
    _heartbeatTimer?.cancel(); // 🛑 Paramos el corazón
    setOnline(false); 
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }
}