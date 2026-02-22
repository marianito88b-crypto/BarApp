import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Mixin que contiene la lógica de negocio para la gestión de staff
///
/// Requiere que la clase que lo use implemente:
/// - Getter: placeId
/// - Propiedad: context (de State)
/// - Método: mounted (de State)
/// - Método: setState (de State)
mixin StaffLogicMixin<T extends StatefulWidget> on State<T> {
  /// Getter requerido para obtener el ID del lugar
  String get placeId;

  /// Obtiene el stream de staff ordenado por fecha de ingreso (más recientes primero)
  Stream<QuerySnapshot> getStaffStream() {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('staff')
        .orderBy('fechaUnion', descending: true)
        .snapshots();
  }

  /// Agrega un usuario al staff del lugar (método modernizado)
  ///
  /// [uid]: UID del usuario a agregar
  /// [email]: Email del usuario
  /// [nombre]: Nombre completo del usuario
  /// [rol]: Rol a asignar (mozo, cajero, cocinero, repartidor, admin)
  /// [dni]: DNI obligatorio para registro de asistencia
  /// [apodo]: Apodo opcional del colaborador
  ///
  /// Retorna `true` si se agregó exitosamente, `false` si hubo un error o duplicado.
  Future<bool> agregarUsuarioAlStaff({
    required String uid,
    required String email,
    required String nombre,
    required String rol,
    required String dni,
    String? apodo,
  }) async {
    try {
      // Verificar si el usuario ya está en el staff (prevenir duplicados)
      final staffDoc = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('staff')
          .doc(uid)
          .get();

      if (staffDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ $nombre ya forma parte del equipo."),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return false;
      }

      // Validar que el DNI esté presente (ahora es obligatorio)
      if (dni.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El DNI es obligatorio para agregar miembros al staff"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return false;
      }

      // Verificar que el DNI no esté duplicado en el staff
      final dniDuplicado = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('staff')
          .where('dni', isEqualTo: dni.trim())
          .limit(1)
          .get();

      if (dniDuplicado.docs.isNotEmpty && dniDuplicado.docs.first.id != uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Este DNI ya está registrado en el equipo"),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
        return false;
      }

      // Obtener foto del usuario desde la colección usuarios
      String? fotoUrl;
      try {
        final usuarioDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .get();
        fotoUrl = usuarioDoc.data()?['fotoUrl'] as String?;
      } catch (e) {
        debugPrint("Error obteniendo foto del usuario: $e");
      }

      // Preparar datos del staff member
      final Map<String, dynamic> staffData = {
        'uid': uid,
        'email': email,
        'nombre': nombre, // Nombre completo
        'nombreCompleto': nombre, // Alias para claridad
        'rol': rol,
        'dni': dni.trim(), // DNI obligatorio
        'fechaUnion': FieldValue.serverTimestamp(),
        // Mantener compatibilidad con código antiguo
        'agregadoEl': FieldValue.serverTimestamp(),
      };

      // Agregar apodo si fue proporcionado
      if (apodo != null && apodo.trim().isNotEmpty) {
        staffData['apodo'] = apodo.trim();
      }

      // Agregar foto si existe
      if (fotoUrl != null && fotoUrl.isNotEmpty) {
        staffData['fotoUrl'] = fotoUrl;
      }

      // Agregar al staff del lugar
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('staff')
          .doc(uid)
          .set(staffData);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $nombre agregado como ${rol.toUpperCase()}"),
            backgroundColor: Colors.green,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint("Error agregando miembro al staff: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error de conexión. Intenta nuevamente."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Busca un usuario por email y lo agrega al staff del lugar
  /// 
  /// MÉTODO LEGACY: Mantenido para compatibilidad con código antiguo.
  /// Se recomienda usar `agregarUsuarioAlStaff` en su lugar.
  ///
  /// [email]: Email del usuario a buscar
  /// [rol]: Rol a asignar (mozo, cajero, cocinero, repartidor, admin)
  /// [nombre]: Nombre real del usuario
  /// [dni]: DNI obligatorio del colaborador
  ///
  /// Retorna `true` si se agregó exitosamente, `false` si hubo un error.
  Future<bool> buscarYAgregar({
    required String email,
    required String rol,
    required String nombre,
    String? dni,
  }) async {
    try {
      // Validar que el DNI esté presente (ahora es obligatorio)
      if (dni == null || dni.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "El DNI es obligatorio para agregar miembros al staff. Por favor, usa el método de agregar miembro desde el panel.",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return false;
      }

      // Buscar usuario en la colección 'usuarios'
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Usuario no encontrado. Pídele que se registre primero.",
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return false;
      }

      final userDoc = query.docs.first;
      final uid = userDoc.id;

      // Usar el nuevo método con DNI requerido
      // El DNI ya fue validado arriba, así que sabemos que no es null
      return await agregarUsuarioAlStaff(
        uid: uid,
        email: email,
        nombre: nombre,
        rol: rol,
        dni: dni, // Non-null assertion porque ya validamos arriba
      );
    } catch (e) {
      debugPrint("Error agregando miembro al staff: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error de conexión"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Muestra un diálogo de confirmación y elimina un miembro del staff
  ///
  /// [uid]: ID del documento del staff a eliminar
  /// [email]: Email del miembro (para mostrar en el diálogo)
  Future<void> confirmarEliminar(String uid, String? email) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Eliminar Acceso",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "¿Estás seguro de quitar a $email del equipo?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _eliminarStaff(uid);
    }
  }

  /// Elimina un miembro del staff de Firestore
  ///
  /// [uid]: ID del documento del staff a eliminar
  Future<void> _eliminarStaff(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('staff')
          .doc(uid)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Acceso eliminado"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error eliminando miembro del staff: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al eliminar. Intenta nuevamente."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // SISTEMA DE FICHAJE (CONTROL DE ASISTENCIA)
  // ===========================================================================

  /// Registra una asistencia (entrada o salida) basándose en el DNI del colaborador
  ///
  /// [dni]: DNI del colaborador a fichar
  ///
  /// Retorna un mapa con:
  /// - 'success': bool indicando si fue exitoso
  /// - 'message': String con el mensaje a mostrar
  /// - 'tipo': String con el tipo de marca ('entrada' o 'salida')
  Future<Map<String, dynamic>> registrarAsistencia({required String dni}) async {
    try {
      // Buscar al colaborador por DNI en el staff del lugar
      final staffQuery = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('staff')
          .where('dni', isEqualTo: dni.trim())
          .limit(1)
          .get();

      if (staffQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'DNI no encontrado en el equipo de trabajo.',
        };
      }

      final staffDoc = staffQuery.docs.first;
      final staffData = staffDoc.data();
      final String uidStaff = staffDoc.id;
      final String nombre = staffData['nombre'] ?? 'Colaborador';
      final String email = staffData['email'] ?? '';

      // Obtener la fecha actual (solo fecha, sin hora)
      final ahora = DateTime.now();
      final inicioDelDia = DateTime(ahora.year, ahora.month, ahora.day);
      final finDelDia = inicioDelDia.add(const Duration(days: 1));

      // Buscar si ya hay una entrada hoy para este colaborador
      // Usamos solo uidStaff y orderBy timestamp, luego filtramos por fecha en memoria
      // Esto evita necesitar un índice compuesto
      final asistenciasQuery = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('asistencias')
          .where('uidStaff', isEqualTo: uidStaff)
          .orderBy('timestamp', descending: true)
          .limit(10) // Obtener las últimas 10 para filtrar en memoria
          .get();

      // Filtrar en memoria las asistencias de hoy
      final asistenciasHoy = asistenciasQuery.docs.where((doc) {
        final timestamp = doc.data()['timestamp'] as Timestamp?;
        if (timestamp == null) return false;
        final fecha = timestamp.toDate();
        return fecha.isAfter(inicioDelDia.subtract(const Duration(seconds: 1))) &&
               fecha.isBefore(finDelDia);
      }).toList();

      String tipo;
      String mensaje;

      if (asistenciasHoy.isEmpty) {
        // No hay registros hoy, es una ENTRADA
        tipo = 'entrada';
        mensaje = '✅ Entrada registrada: $nombre';
      } else {
        final ultimaAsistencia = asistenciasHoy.first.data();
        final ultimoTipo = ultimaAsistencia['tipo'] as String?;

        if (ultimoTipo == 'entrada') {
          // Ya hay una entrada, esta es una SALIDA
          tipo = 'salida';
          mensaje = '✅ Salida registrada: $nombre';
        } else {
          // Ya hay una salida, esta es una nueva ENTRADA (día siguiente o reingreso)
          tipo = 'entrada';
          mensaje = '✅ Entrada registrada: $nombre';
        }
      }

      // Registrar la asistencia
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('asistencias')
          .add({
        'uidStaff': uidStaff,
        'nombre': nombre,
        'email': email,
        'dni': dni.trim(),
        'tipo': tipo,
        'timestamp': FieldValue.serverTimestamp(),
        'fecha': FieldValue.serverTimestamp(), // Para filtros por día
      });

      return {
        'success': true,
        'message': mensaje,
        'tipo': tipo,
      };
    } catch (e) {
      debugPrint("Error registrando asistencia: $e");
      return {
        'success': false,
        'message': 'Error al registrar asistencia. Intenta nuevamente.',
      };
    }
  }

  /// Obtiene el stream de asistencias de un colaborador específico
  ///
  /// [uidStaff]: UID del miembro del staff
  ///
  /// Retorna un Stream de QuerySnapshot ordenado por timestamp descendente
  /// NOTA: Esta query requiere un índice compuesto en Firestore:
  /// Collection: places/{placeId}/asistencias
  /// Fields: uidStaff (Ascending), timestamp (Descending)
  Stream<QuerySnapshot> getAsistenciasStream(String uidStaff) {
    return FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('asistencias')
        .where('uidStaff', isEqualTo: uidStaff)
        .orderBy('timestamp', descending: true)
        .limit(50) // Últimas 50 asistencias
        .snapshots();
  }
}
