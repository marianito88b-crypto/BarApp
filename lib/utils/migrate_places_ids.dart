import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Script de migración para normalizar IDs de documentos en la colección 'places'
/// 
/// Este script:
/// 1. Recorre todos los documentos de 'places'
/// 2. Genera un slug basado en el campo 'name'
/// 3. Crea el nuevo documento con el slug como ID
/// 4. Copia todas las subcolecciones
/// 5. Elimina el documento antiguo
/// 
/// IMPORTANTE: Ejecutar solo una vez. Incluye validaciones para evitar bucles infinitos.
class PlacesIdMigration {
  /// Genera un slug limpio a partir de un nombre
  /// 
  /// Ejemplo: "Bar Los Amigos" -> "bar-los-amigos"
  static String _generateSlug(String name) {
    if (name.isEmpty) return 'sin-nombre';
    
    // Convertir a minúsculas
    String slug = name.toLowerCase().trim();
    
    // Reemplazar espacios y caracteres especiales por guiones
    slug = slug.replaceAll(RegExp(r'[^\w\s-]'), ''); // Eliminar caracteres especiales
    slug = slug.replaceAll(RegExp(r'\s+'), '-'); // Espacios por guiones
    slug = slug.replaceAll(RegExp(r'-+'), '-'); // Múltiples guiones por uno solo
    
    // Eliminar guiones al inicio y final
    slug = slug.replaceAll(RegExp(r'^-+|-+$'), '');
    
    // Si quedó vacío, usar un valor por defecto
    if (slug.isEmpty) {
      slug = 'sin-nombre';
    }
    
    return slug;
  }
  
  /// Verifica si un ID ya está correctamente formateado (es un slug válido)
  static bool _isIdAlreadyNormalized(String docId) {
    // Un ID normalizado solo contiene letras minúsculas, números y guiones
    // No debe tener espacios, mayúsculas ni caracteres especiales
    final normalizedPattern = RegExp(r'^[a-z0-9-]+$');
    return normalizedPattern.hasMatch(docId) && 
           !docId.startsWith('-') && 
           !docId.endsWith('-') &&
           !docId.contains('--');
  }
  
  /// Copia una subcolección completa de un documento a otro
  static Future<void> _copySubcollection(
    String sourcePlaceId,
    String targetPlaceId,
    String subcollectionName,
  ) async {
    try {
      final sourceRef = FirebaseFirestore.instance
          .collection('places')
          .doc(sourcePlaceId)
          .collection(subcollectionName);
      
      final targetRef = FirebaseFirestore.instance
          .collection('places')
          .doc(targetPlaceId)
          .collection(subcollectionName);
      
      // Obtener todos los documentos de la subcolección
      final snapshot = await sourceRef.get();
      
      if (snapshot.docs.isEmpty) {
        debugPrint('  ✓ Subcolección $subcollectionName vacía, saltando...');
        return;
      }
      
      // Copiar documentos en batches de 500 (límite de Firestore)
      final batches = <WriteBatch>[];
      WriteBatch? currentBatch = FirebaseFirestore.instance.batch();
      int docCount = 0;
      
      for (final doc in snapshot.docs) {
        if (docCount >= 500) {
          batches.add(currentBatch!);
          currentBatch = FirebaseFirestore.instance.batch();
          docCount = 0;
        }
        
        final data = doc.data();
        currentBatch!.set(targetRef.doc(doc.id), data);
        docCount++;
      }
      
      if (docCount > 0) {
        batches.add(currentBatch!);
      }
      
      // Ejecutar todos los batches
      for (final batch in batches) {
        await batch.commit();
      }
      
      debugPrint('  ✓ Subcolección $subcollectionName copiada: ${snapshot.docs.length} documentos');
    } catch (e) {
      debugPrint('  ✗ Error copiando subcolección $subcollectionName: $e');
      rethrow;
    }
  }
  
  /// Lista todas las subcolecciones conocidas de un documento place
  static Future<List<String>> _getSubcollections(String placeId) async {
    // Lista de subcolecciones conocidas basadas en el código del proyecto
    final knownSubcollections = [
      'menu',
      'events',
      'staff',
      'orders',
      'reservas',
      'ventas',
      'gastos',
      'caja_sesiones',
      'asistencias',
      'gallery',
      'reviews',
      'ratings',
      'followers',
      'mesas',
      'proveedores',
      'movimientos_caja_fuerte',
    ];
    
    // Verificar cuáles existen realmente
    final existingSubcollections = <String>[];
    
    for (final subcolName in knownSubcollections) {
      try {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(placeId)
            .collection(subcolName)
            .limit(1)
            .get();
        
        // Si la consulta no falla, la subcolección existe (aunque esté vacía)
        // Nota: Firestore no permite listar subcolecciones vacías directamente,
        // así que intentamos con las conocidas
        existingSubcollections.add(subcolName);
      } catch (e) {
        // Si hay error, probablemente la subcolección no existe, la omitimos
        debugPrint('  ⚠ Subcolección $subcolName no accesible o no existe');
      }
    }
    
    return existingSubcollections;
  }
  
  /// Migra un documento place individual
  static Future<bool> _migratePlaceDocument(
    DocumentSnapshot placeDoc,
    String newId,
  ) async {
    try {
      final oldId = placeDoc.id;
      final data = placeDoc.data() as Map<String, dynamic>;
      
      debugPrint('\n📦 Migrando: "$oldId" -> "$newId"');
      
      // 1. Crear el nuevo documento con los datos del original
      final newDocRef = FirebaseFirestore.instance
          .collection('places')
          .doc(newId);
      
      // Verificar si el nuevo documento ya existe
      final newDocExists = await newDocRef.get();
      if (newDocExists.exists) {
        debugPrint('  ⚠ El documento "$newId" ya existe. Saltando migración.');
        return false;
      }
      
      // Crear el nuevo documento
      await newDocRef.set(data);
      debugPrint('  ✓ Documento principal creado');
      
      // 2. Copiar todas las subcolecciones
      final subcollections = await _getSubcollections(oldId);
      debugPrint('  📁 Encontradas ${subcollections.length} subcolecciones');
      
      for (final subcolName in subcollections) {
        await _copySubcollection(oldId, newId, subcolName);
      }
      
      // 3. Eliminar el documento antiguo (esto también elimina sus subcolecciones)
      await FirebaseFirestore.instance
          .collection('places')
          .doc(oldId)
          .delete();
      
      debugPrint('  ✓ Documento antiguo eliminado');
      debugPrint('  ✅ Migración completada para "$oldId" -> "$newId"');
      
      return true;
    } catch (e) {
      debugPrint('  ✗ Error migrando documento: $e');
      return false;
    }
  }
  
  /// Ejecuta la migración completa de todos los documentos places
  /// 
  /// Retorna un mapa con estadísticas:
  /// - 'total': Total de documentos procesados
  /// - 'migrated': Documentos migrados exitosamente
  /// - 'skipped': Documentos saltados (ya normalizados o errores)
  /// - 'errors': Errores encontrados
  static Future<Map<String, int>> migrateAllPlaces() async {
    debugPrint('🚀 Iniciando migración de IDs de places...\n');
    
    int total = 0;
    int migrated = 0;
    int skipped = 0;
    int errors = 0;
    
    try {
      // Obtener todos los documentos de places
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .get();
      
      total = snapshot.docs.length;
      debugPrint('📊 Total de documentos encontrados: $total\n');
      
      if (total == 0) {
        debugPrint('⚠ No hay documentos para migrar.');
        return {
          'total': 0,
          'migrated': 0,
          'skipped': 0,
          'errors': 0,
        };
      }
      
      // Procesar cada documento
      for (final doc in snapshot.docs) {
        final currentId = doc.id;
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        
        // Verificar si el ID ya está normalizado
        if (_isIdAlreadyNormalized(currentId)) {
          debugPrint('⏭ Saltando "$currentId" (ya está normalizado)');
          skipped++;
          continue;
        }
        
        // Validar que tenga nombre
        if (name.isEmpty) {
          debugPrint('⚠ Saltando "$currentId" (no tiene campo "name")');
          skipped++;
          continue;
        }
        
        // Generar el nuevo ID basado en el nombre
        final newId = _generateSlug(name);
        
        // Si el nuevo ID es igual al actual (caso raro pero posible), saltar
        if (newId == currentId) {
          debugPrint('⏭ Saltando "$currentId" (slug generado es igual al ID actual)');
          skipped++;
          continue;
        }
        
        // Migrar el documento
        final success = await _migratePlaceDocument(doc, newId);
        
        if (success) {
          migrated++;
        } else {
          errors++;
        }
        
        // Pequeña pausa para no sobrecargar Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      // Resumen final
      debugPrint('\n${'=' * 50}');
      debugPrint('📊 RESUMEN DE MIGRACIÓN');
      debugPrint('=' * 50);
      debugPrint('Total procesados: $total');
      debugPrint('✅ Migrados exitosamente: $migrated');
      debugPrint('⏭ Saltados: $skipped');
      debugPrint('❌ Errores: $errors');
      debugPrint('=' * 50);
      
      return {
        'total': total,
        'migrated': migrated,
        'skipped': skipped,
        'errors': errors,
      };
    } catch (e) {
      debugPrint('\n❌ Error crítico durante la migración: $e');
      return {
        'total': total,
        'migrated': migrated,
        'skipped': skipped,
        'errors': errors + 1,
      };
    }
  }
  
  /// Función de prueba para migrar un solo documento (útil para testing)
  static Future<bool> migrateSinglePlace(String placeId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .get();
      
      if (!doc.exists) {
        debugPrint('❌ Documento "$placeId" no encontrado');
        return false;
      }
      
      final data = doc.data()!;
      final name = data['name'] as String? ?? '';
      
      if (name.isEmpty) {
        debugPrint('❌ El documento no tiene campo "name"');
        return false;
      }
      
      final newId = _generateSlug(name);
      
      if (_isIdAlreadyNormalized(placeId)) {
        debugPrint('⚠ El ID "$placeId" ya está normalizado');
        return false;
      }
      
      return await _migratePlaceDocument(doc, newId);
    } catch (e) {
      debugPrint('❌ Error: $e');
      return false;
    }
  }
}
