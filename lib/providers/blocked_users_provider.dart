import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/moderation/block_service.dart';

class BlockedUsersProvider extends ChangeNotifier {
  // Aquí viven los IDs que no queremos ver (ni que nos vean)
  Set<String> _excludedIds = {};

  Set<String> get excludedIds => _excludedIds;

  // 1. Cargar la lista al iniciar la app
  Future<void> init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _excludedIds = await BlockService.getAllExcludedUserIds();
      notifyListeners(); // Avisa a toda la app que la lista cambió
    }
  }

  // 2. Función helper para saber si ocultar algo rápido
  bool shouldHide(String otherUserId) {
    return _excludedIds.contains(otherUserId);
  }

  // 3. Bloquear en tiempo real (ACTUALIZADO 🔥)
  // Ahora recibimos nombre y foto opcionales para pasarlos al servicio
  Future<void> block(String userId, {String? name, String? photoUrl}) async {
    // Pasamos los datos visuales al servicio para que guarde la ficha completa
    await BlockService.blockUser(userId, name: name, photoUrl: photoUrl);
    
    // Luego actualizamos la memoria local (aquí solo nos importa el ID para filtrar)
    _excludedIds.add(userId);
    notifyListeners();
  }

  // 4. Desbloquear
  Future<void> unblock(String userId) async {
    await BlockService.unblockUser(userId);
    _excludedIds.remove(userId);
    notifyListeners();
  }
}