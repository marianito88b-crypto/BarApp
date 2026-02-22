import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Servicio profesional de mantenimiento y limpieza de base de datos y archivos basura
class MaintenanceService {
  /// Resultado de una operación de limpieza
  static const int maxBatchSize = 500;

  /// Limpia historias con más de 24 horas de antigüedad
  /// IMPORTANTE: Borra primero el archivo en Storage y luego el documento en Firestore
  static Future<MaintenanceResult> cleanOldStories({
    required Function(String status) onProgress,
  }) async {
    int storiesDeleted = 0;
    int filesDeleted = 0;
    int errors = 0;

    try {
      final now = DateTime.now();

      onProgress('Buscando historias expiradas...');

      // Buscar historias expiradas (usamos expiresAt como en el backend)
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .where('expiresAt', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .limit(maxBatchSize)
          .get();

      if (snapshot.docs.isEmpty) {
        return MaintenanceResult(
          storiesDeleted: 0,
          usersDeleted: 0,
          ordersDeleted: 0,
          filesDeleted: 0,
          errors: 0,
        );
      }

      onProgress('Procesando ${snapshot.docs.length} historias...');

      // Procesar en batches
      for (int i = 0; i < snapshot.docs.length; i += maxBatchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final batchDocs = snapshot.docs.skip(i).take(maxBatchSize).toList();

        for (var doc in batchDocs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final mediaUrl = data['mediaUrl'] as String?;

            // 1. PRIMERO: Borrar archivo en Storage
            if (mediaUrl != null && mediaUrl.isNotEmpty) {
              try {
                await FirebaseStorage.instance.refFromURL(mediaUrl).delete();
                filesDeleted++;
                debugPrint('✅ Archivo Storage eliminado: $mediaUrl');
              } catch (storageError) {
                // Si el archivo ya no existe, no es crítico
                debugPrint('⚠️ Archivo Storage no encontrado (puede que ya fue eliminado): $mediaUrl');
              }
            }

            // 2. SEGUNDO: Borrar documento en Firestore
            batch.delete(doc.reference);
            storiesDeleted++;
          } catch (e) {
            errors++;
            debugPrint('❌ Error procesando historia ${doc.id}: $e');
          }
        }

        // Ejecutar batch
        if (batchDocs.isNotEmpty) {
          await batch.commit();
          onProgress('Historia ${i + batchDocs.length}/${snapshot.docs.length} procesadas...');
        }
      }

      debugPrint('✅ Limpieza de historias: $storiesDeleted historias borradas, $filesDeleted archivos eliminados');
      return MaintenanceResult(
        storiesDeleted: storiesDeleted,
        usersDeleted: 0,
        ordersDeleted: 0,
        filesDeleted: filesDeleted,
        errors: errors,
      );
    } catch (e) {
      debugPrint('❌ Error crítico en limpieza de historias: $e');
      return MaintenanceResult(
        storiesDeleted: storiesDeleted,
        usersDeleted: 0,
        ordersDeleted: 0,
        filesDeleted: filesDeleted,
        errors: errors + 1,
      );
    }
  }

  /// Elimina usuarios invitados con más de 24 horas desde su creación
  static Future<MaintenanceResult> cleanGuestUsers({
    required Function(String status) onProgress,
  }) async {
    int usersDeleted = 0;
    int errors = 0;

    try {
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(hours: 24));

      onProgress('Buscando usuarios invitados antiguos...');

      // Buscar en la colección 'users'
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(maxBatchSize)
          .get();

      // Buscar en la colección 'usuarios' también
      QuerySnapshot usuariosSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(maxBatchSize)
          .get();

      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(usersSnapshot.docs);
      allDocs.addAll(usuariosSnapshot.docs);

      if (allDocs.isEmpty) {
        return MaintenanceResult(
          storiesDeleted: 0,
          usersDeleted: 0,
          ordersDeleted: 0,
          filesDeleted: 0,
          errors: 0,
        );
      }

      onProgress('Procesando ${allDocs.length} usuarios...');

      // Filtrar usuarios invitados
      final guestDocs = allDocs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final displayName = (data['displayName'] ?? '').toString();
        final isGuest = data['isGuest'] == true;
        
        return isGuest || displayName == 'Usuario' || displayName == 'Invitado';
      }).toList();

      if (guestDocs.isEmpty) {
        return MaintenanceResult(
          storiesDeleted: 0,
          usersDeleted: 0,
          ordersDeleted: 0,
          filesDeleted: 0,
          errors: 0,
        );
      }

      // Procesar en batches
      for (int i = 0; i < guestDocs.length; i += maxBatchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final batchDocs = guestDocs.skip(i).take(maxBatchSize).toList();

        for (var doc in batchDocs) {
          try {
            batch.delete(doc.reference);
            usersDeleted++;
          } catch (e) {
            errors++;
            debugPrint('❌ Error eliminando usuario ${doc.id}: $e');
          }
        }

        if (batchDocs.isNotEmpty) {
          await batch.commit();
          onProgress('Usuario ${i + batchDocs.length}/${guestDocs.length} procesados...');
        }
      }

      debugPrint('✅ Limpieza de usuarios: $usersDeleted usuarios invitados eliminados');
      return MaintenanceResult(
        storiesDeleted: 0,
        usersDeleted: usersDeleted,
        ordersDeleted: 0,
        filesDeleted: 0,
        errors: errors,
      );
    } catch (e) {
      debugPrint('❌ Error crítico en limpieza de usuarios: $e');
      return MaintenanceResult(
        storiesDeleted: 0,
        usersDeleted: usersDeleted,
        ordersDeleted: 0,
        filesDeleted: 0,
        errors: errors + 1,
      );
    }
  }

  /// Limpia pedidos antiguos según el tipo de usuario
  /// - Clientes: pedidos con más de 30 días
  /// - Locales: pedidos con más de 90 días (3 meses)
  /// IMPORTANTE: Valida que hayan pasado al menos 3 meses antes de borrar
  static Future<MaintenanceResult> cleanOldOrders({
    required String placeId,
    required bool isClient,
    required Function(String status) onProgress,
  }) async {
    int ordersDeleted = 0;
    int errors = 0;

    try {
      final now = DateTime.now();
      final daysThreshold = isClient ? 30 : 90; // 3 meses para locales
      
      // Validación de seguridad para locales: asegurar que siempre sean 90 días mínimo
      if (!isClient && daysThreshold < 90) {
        throw Exception(
          'Seguridad: Los pedidos de locales solo se pueden eliminar después de 90 días (3 meses). '
          'Esta validación previene la pérdida accidental de datos operativos recientes.',
        );
      }
      
      final cutoffDate = now.subtract(Duration(days: daysThreshold));

      onProgress('Buscando pedidos antiguos (más de $daysThreshold días)...');

      // Buscar pedidos antiguos en la colección 'orders'
      QuerySnapshot ordersSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('orders')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(maxBatchSize)
          .get();

      // También buscar en 'ventas' si es necesario
      QuerySnapshot ventasSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('ventas')
          .where('fecha', isLessThan: Timestamp.fromDate(cutoffDate))
          .limit(maxBatchSize)
          .get();

      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(ordersSnapshot.docs);
      allDocs.addAll(ventasSnapshot.docs);

      if (allDocs.isEmpty) {
        return MaintenanceResult(
          storiesDeleted: 0,
          usersDeleted: 0,
          ordersDeleted: 0,
          filesDeleted: 0,
          errors: 0,
        );
      }

      onProgress('Procesando ${allDocs.length} pedidos...');

      // Procesar en batches
      for (int i = 0; i < allDocs.length; i += maxBatchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final batchDocs = allDocs.skip(i).take(maxBatchSize).toList();

        for (var doc in batchDocs) {
          try {
            batch.delete(doc.reference);
            ordersDeleted++;
          } catch (e) {
            errors++;
            debugPrint('❌ Error eliminando pedido ${doc.id}: $e');
          }
        }

        if (batchDocs.isNotEmpty) {
          await batch.commit();
          onProgress('Pedido ${i + batchDocs.length}/${allDocs.length} procesados...');
        }
      }

      debugPrint('✅ Limpieza de pedidos: $ordersDeleted pedidos eliminados');
      return MaintenanceResult(
        storiesDeleted: 0,
        usersDeleted: 0,
        ordersDeleted: ordersDeleted,
        filesDeleted: 0,
        errors: errors,
      );
    } catch (e) {
      debugPrint('❌ Error crítico en limpieza de pedidos: $e');
      return MaintenanceResult(
        storiesDeleted: 0,
        usersDeleted: 0,
        ordersDeleted: ordersDeleted,
        filesDeleted: 0,
        errors: errors + 1,
      );
    }
  }

  /// Limpia pedidos antiguos de todos los locales (más de 90 días / 3 meses)
  /// Solo para Superadmin - Valida que hayan pasado al menos 3 meses
  static Future<MaintenanceResult> cleanAllPlacesOrders({
    required Function(String status) onProgress,
  }) async {
    int totalOrdersDeleted = 0;
    int totalErrors = 0;
    int placesProcessed = 0;

    try {
      onProgress('Obteniendo lista de locales...');
      
      // Obtener todos los lugares
      final placesSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .get();

      if (placesSnapshot.docs.isEmpty) {
        return MaintenanceResult(
          storiesDeleted: 0,
          usersDeleted: 0,
          ordersDeleted: 0,
          filesDeleted: 0,
          errors: 0,
        );
      }

      final totalPlaces = placesSnapshot.docs.length;
      onProgress('Procesando $totalPlaces locales...');

      // Procesar cada lugar
      for (var placeDoc in placesSnapshot.docs) {
        try {
          placesProcessed++;
          final placeId = placeDoc.id;
          final placeName = placeDoc.data()['name'] ?? placeId;
          
          onProgress('Limpiando pedidos de: $placeName ($placesProcessed/$totalPlaces)...');

          final result = await cleanOldOrders(
            placeId: placeId,
            isClient: false, // Siempre false para locales
            onProgress: (status) {
              // No actualizamos el progreso aquí para evitar spam
            },
          );

          totalOrdersDeleted += result.ordersDeleted;
          totalErrors += result.errors;
        } catch (e) {
          totalErrors++;
          debugPrint('❌ Error limpiando pedidos del lugar ${placeDoc.id}: $e');
        }
      }

      debugPrint(
        '✅ Limpieza de pedidos de locales completada: '
        '$totalOrdersDeleted pedidos eliminados de $placesProcessed locales',
      );

      return MaintenanceResult(
        storiesDeleted: 0,
        usersDeleted: 0,
        ordersDeleted: totalOrdersDeleted,
        filesDeleted: 0,
        errors: totalErrors,
      );
    } catch (e) {
      debugPrint('❌ Error crítico en limpieza de pedidos de locales: $e');
      return MaintenanceResult(
        storiesDeleted: 0,
        usersDeleted: 0,
        ordersDeleted: totalOrdersDeleted,
        filesDeleted: 0,
        errors: totalErrors + 1,
      );
    }
  }

  /// Ejecuta limpieza general (historias + usuarios invitados)
  static Future<MaintenanceResult> executeGeneralCleanup({
    required Function(String status) onProgress,
  }) async {
    int totalStories = 0;
    int totalUsers = 0;
    int totalFiles = 0;
    int totalErrors = 0;

    // Limpiar historias
    onProgress('Limpiando historias antiguas...');
    final storiesResult = await cleanOldStories(onProgress: onProgress);
    totalStories += storiesResult.storiesDeleted;
    totalFiles += storiesResult.filesDeleted;
    totalErrors += storiesResult.errors;

    // Limpiar usuarios invitados
    onProgress('Limpiando usuarios invitados...');
    final usersResult = await cleanGuestUsers(onProgress: onProgress);
    totalUsers += usersResult.usersDeleted;
    totalErrors += usersResult.errors;

    debugPrint(
      '✅ Limpieza General Completada: '
      '$totalStories historias borradas, '
      '$totalUsers usuarios limpiados, '
      '$totalFiles archivos de Storage eliminados',
    );

    return MaintenanceResult(
      storiesDeleted: totalStories,
      usersDeleted: totalUsers,
      ordersDeleted: 0,
      filesDeleted: totalFiles,
      errors: totalErrors,
    );
  }

  /// Ejecuta limpieza completa (historias + usuarios + pedidos de locales)
  static Future<MaintenanceResult> executeFullCleanup({
    required Function(String status) onProgress,
  }) async {
    int totalStories = 0;
    int totalUsers = 0;
    int totalOrders = 0;
    int totalFiles = 0;
    int totalErrors = 0;

    // Limpiar historias
    onProgress('Limpiando historias antiguas...');
    final storiesResult = await cleanOldStories(onProgress: onProgress);
    totalStories += storiesResult.storiesDeleted;
    totalFiles += storiesResult.filesDeleted;
    totalErrors += storiesResult.errors;

    // Limpiar usuarios invitados
    onProgress('Limpiando usuarios invitados...');
    final usersResult = await cleanGuestUsers(onProgress: onProgress);
    totalUsers += usersResult.usersDeleted;
    totalErrors += usersResult.errors;

    // Limpiar pedidos de todos los locales
    onProgress('Limpiando pedidos antiguos de locales...');
    final ordersResult = await cleanAllPlacesOrders(onProgress: onProgress);
    totalOrders += ordersResult.ordersDeleted;
    totalErrors += ordersResult.errors;

    debugPrint(
      '✅ Limpieza Completa Finalizada: '
      '$totalStories historias borradas, '
      '$totalUsers usuarios limpiados, '
      '$totalOrders pedidos eliminados, '
      '$totalFiles archivos de Storage eliminados',
    );

    return MaintenanceResult(
      storiesDeleted: totalStories,
      usersDeleted: totalUsers,
      ordersDeleted: totalOrders,
      filesDeleted: totalFiles,
      errors: totalErrors,
    );
  }
}

/// Resultado de una operación de mantenimiento
class MaintenanceResult {
  final int storiesDeleted;
  final int usersDeleted;
  final int ordersDeleted;
  final int filesDeleted;
  final int errors;

  MaintenanceResult({
    required this.storiesDeleted,
    required this.usersDeleted,
    required this.ordersDeleted,
    required this.filesDeleted,
    required this.errors,
  });

  int get totalDeleted => storiesDeleted + usersDeleted + ordersDeleted;
}
