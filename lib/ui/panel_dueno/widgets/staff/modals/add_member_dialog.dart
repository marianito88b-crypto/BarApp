import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../logic/staff_logic.dart';

/// Diálogo modernizado para agregar un nuevo miembro al equipo de staff
/// 
/// Permite buscar usuarios existentes por nombre o displayName y agregarlos al staff.
/// Incluye búsqueda en tiempo real con resultados limitados y campo DNI opcional.
class AddMemberDialog extends StatefulWidget {
  final String placeId;

  const AddMemberDialog({
    super.key,
    required this.placeId,
  });

  /// Método estático para mostrar el diálogo de forma conveniente
  static Future<void> show(BuildContext context, String placeId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddMemberDialog(placeId: placeId),
    );
  }

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> with StaffLogicMixin {
  final _searchController = TextEditingController();
  final _dniController = TextEditingController();
  final _nombreCompletoController = TextEditingController();
  final _apodoController = TextEditingController();
  String _selectedRol = 'mozo';
  bool _isSearching = false;
  bool _isAdding = false;
  
  // Resultados de búsqueda
  List<QueryDocumentSnapshot> _searchResults = [];
  StreamSubscription<QuerySnapshot>? _searchSubscription;
  
  // UIDs de usuarios que ya están en el staff (cargado una vez al inicio)
  Set<String> _existingStaffUids = {};

  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadExistingStaff();
  }

  /// Carga los UIDs de usuarios que ya están en el staff una sola vez
  Future<void> _loadExistingStaff() async {
    try {
      final staffSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('staff')
          .get();
      
      if (mounted) {
        setState(() {
          _existingStaffUids = staffSnapshot.docs.map((doc) => doc.id).toSet();
        });
      }
    } catch (e) {
      debugPrint("Error cargando staff existente: $e");
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _dniController.dispose();
    _nombreCompletoController.dispose();
    _apodoController.dispose();
    _searchSubscription?.cancel();
    super.dispose();
  }

  /// Escucha cambios en el campo de búsqueda y actualiza los resultados
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _searchSubscription?.cancel();
      return;
    }

    if (query.length < 2) {
      // Esperar al menos 2 caracteres antes de buscar
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Cancelar búsqueda anterior
    _searchSubscription?.cancel();

    // Normalizar query para búsqueda case-insensitive
    // Firestore requiere que busquemos con el primer carácter en mayúscula
    final queryLower = query.toLowerCase();
    final queryUpper = queryLower.isEmpty 
        ? '' 
        : queryLower[0].toUpperCase() + (queryLower.length > 1 ? queryLower.substring(1) : '');
    final queryEnd = queryLower.isEmpty 
        ? '' 
        : '${queryLower[0].toUpperCase()}${queryLower.length > 1 ? queryLower.substring(1) : ''}\uf8ff';

    setState(() => _isSearching = true);

    // Buscar usuarios por nombre (Firestore es case-sensitive, así que buscamos con primera mayúscula)
    // Limitamos a 15 resultados iniciales para tener margen después del filtrado
    _searchSubscription = FirebaseFirestore.instance
        .collection('usuarios')
        .where('nombre', isGreaterThanOrEqualTo: queryUpper)
        .where('nombre', isLessThanOrEqualTo: queryEnd)
        .limit(15)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        // Filtrar resultados en el cliente:
        // 1. Por nombre/displayName que contenga la query
        // 2. Excluir usuarios que ya están en el staff
        final queryLowerForFilter = queryLower;
        final filteredDocs = snapshot.docs.where((doc) {
          // Excluir si ya está en el staff
          if (_existingStaffUids.contains(doc.id)) {
            return false;
          }
          
          // Filtrar por nombre o displayName
          final data = doc.data();
          final nombre = (data['nombre'] ?? '').toString().toLowerCase();
          final displayName = (data['displayName'] ?? '').toString().toLowerCase();
          return nombre.contains(queryLowerForFilter) || 
                 displayName.contains(queryLowerForFilter);
        }).toList();
        
        if (mounted) {
          setState(() {
            _searchResults = filteredDocs.take(8).toList(); // Limitar a 8 resultados finales
            _isSearching = false;
          });
        }
      }
    }, onError: (error) {
      debugPrint("Error en búsqueda: $error");
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    });
  }

  /// Maneja la selección de un usuario de los resultados
  Future<void> _handleUserSelection(QueryDocumentSnapshot userDoc) async {
    final userData = userDoc.data() as Map<String, dynamic>;
    final String uid = userDoc.id;
    final String nombre = userData['nombre'] ?? userData['displayName'] ?? 'Usuario';
    final String email = userData['email'] ?? 'Sin email';
    final String? fotoUrl = userData['fotoUrl'] as String?;

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Agregar al Equipo",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información del usuario
              Row(
                children: [
                  // Foto de perfil
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                    backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                        ? NetworkImage(fotoUrl)
                        : null,
                    child: fotoUrl == null || fotoUrl.isEmpty
                        ? const Icon(Icons.person, color: Colors.orangeAccent, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Campo Nombre y Apellido (OBLIGATORIO)
              TextField(
                controller: _nombreCompletoController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nombre y Apellido *",
                  hintText: "Ej: Mariano Benitez",
                  helperText: "Nombre completo del colaborador",
                  helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Campo Apodo (OPCIONAL)
              TextField(
                controller: _apodoController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Apodo (Opcional)",
                  hintText: "Ej: Marian",
                  helperText: "Si tiene apodo, se mostrará en vez del nombre completo",
                  helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                  prefixIcon: const Icon(Icons.alternate_email, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              
              // Campo DNI (OBLIGATORIO)
              TextField(
                controller: _dniController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "DNI *",
                  hintText: "Ej: 12345678",
                  helperText: "Obligatorio para el sistema de asistencia",
                  helperStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                  prefixIcon: const Icon(Icons.badge_outlined, color: Colors.orangeAccent),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Selector de rol
              DropdownButtonFormField<String>(
                initialValue: _selectedRol,
                dropdownColor: const Color(0xFF2C2C2C),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Rol Asignado",
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: Colors.orangeAccent,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'mozo',
                    child: Text("Mozo / Camarero"),
                  ),
                  DropdownMenuItem(
                    value: 'cajero',
                    child: Text("Cajero / Encargado"),
                  ),
                  DropdownMenuItem(
                    value: 'cocinero',
                    child: Text("Cocinero"),
                  ),
                  DropdownMenuItem(
                    value: 'repartidor',
                    child: Text("Repartidor / Delivery"),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text("Administrador (Socio)"),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRol = value;
                    });
                  }
                },
              ),
            ],
          ),
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
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Agregar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isAdding = true);
      
      final dni = _dniController.text.trim();
      final nombreCompleto = _nombreCompletoController.text.trim();
      final apodo = _apodoController.text.trim();
      
      // Validar campos obligatorios
      if (nombreCompleto.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El nombre y apellido es obligatorio"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      
      if (dni.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El DNI es obligatorio para el sistema de asistencia"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
      
      final success = await agregarUsuarioAlStaff(
        uid: uid,
        email: email,
        nombre: nombreCompleto, // Usar el nombre completo ingresado
        rol: _selectedRol,
        dni: dni,
        apodo: apodo.isNotEmpty ? apodo : null,
      );

      if (mounted) {
        setState(() => _isAdding = false);
        
        if (success) {
          Navigator.of(context).pop(); // Cerrar diálogo principal
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Agregar Miembro al Staff",
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de búsqueda
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Buscar usuario",
                hintText: "Escribe el nombre del usuario...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.orangeAccent,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de resultados
            if (_searchController.text.trim().isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Escribe al menos 2 caracteres para buscar usuarios.",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(
                    color: Colors.orangeAccent,
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.person_search,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "No se encontraron usuarios con ese nombre.",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, _) => const Divider(
                    color: Colors.white10,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final userDoc = _searchResults[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final String nombre = userData['nombre'] ?? userData['displayName'] ?? 'Usuario';
                    final String email = userData['email'] ?? 'Sin email';
                    final String? fotoUrl = userData['fotoUrl'] as String?;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                        backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                            ? NetworkImage(fotoUrl)
                            : null,
                        child: fotoUrl == null || fotoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.orangeAccent,
                              )
                            : null,
                      ),
                      title: Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.orangeAccent,
                        size: 16,
                      ),
                      onTap: () => _handleUserSelection(userDoc),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isAdding
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text(
            "Cancelar",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}
