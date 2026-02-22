import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:barapp/ui/panel_dueno/widgets/events/event_type_selector.dart';

/// Diálogo simplificado para que superadmin cree eventos SIN notificaciones
/// 
/// Basado en EventEditorDialog pero sin selector de notificaciones
/// Siempre guarda con notificationType: 'none' para que NO notifique
class SuperAdminEventDialog extends StatefulWidget {
  const SuperAdminEventDialog({super.key});

  /// Método estático para mostrar el diálogo fácilmente
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const SuperAdminEventDialog(),
    );
  }

  @override
  State<SuperAdminEventDialog> createState() => _SuperAdminEventDialogState();
}

class _SuperAdminEventDialogState extends State<SuperAdminEventDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _placeSearchCtrl;

  late String _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _currentImageUrl;

  File? _newImageFile;
  Uint8List? _newImageBytes;
  bool _uploading = false;
  
  // Para el selector de locales
  String? _selectedPlaceId;
  String? _selectedPlaceName;
  List<Map<String, dynamic>> _allPlaces = [];
  List<Map<String, dynamic>> _filteredPlaces = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _placeSearchCtrl = TextEditingController();
    _selectedType = 'show';
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _loadPlaces();
    
    // Listener para búsqueda de locales
    _placeSearchCtrl.addListener(_onPlaceSearchChanged);
  }
  
  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _placeSearchCtrl.removeListener(_onPlaceSearchChanged);
    _placeSearchCtrl.dispose();
    super.dispose();
  }
  
  Future<void> _loadPlaces() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .orderBy('name')
          .limit(100)
          .get();
      
      if (mounted) {
        setState(() {
          _allPlaces = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['name'] ?? 'Sin nombre',
              'address': data['address'] ?? '',
            };
          }).toList();
          _filteredPlaces = _allPlaces;
        });
      }
    } catch (e) {
      debugPrint("Error cargando locales: $e");
    }
  }
  
  void _onPlaceSearchChanged() {
    final query = _placeSearchCtrl.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _filteredPlaces = _allPlaces;
      } else {
        _filteredPlaces = _allPlaces.where((place) {
          final name = (place['name'] ?? '').toString().toLowerCase();
          final address = (place['address'] ?? '').toString().toLowerCase();
          return name.contains(query) || address.contains(query);
        }).toList();
      }
    });
  }


  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.purpleAccent,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.purpleAccent,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() => _newImageBytes = bytes);
      } else {
        setState(() => _newImageFile = File(image.path));
      }
    }
  }

  ImageProvider? _getImageProvider() {
    if (kIsWeb && _newImageBytes != null) {
      return MemoryImage(_newImageBytes!);
    }
    if (!kIsWeb && _newImageFile != null) {
      return FileImage(_newImageFile!);
    }
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return NetworkImage(_currentImageUrl!);
    }
    return null;
  }

  Future<void> _saveEvent() async {
    if (_titleCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El título es obligatorio")),
      );
      return;
    }

    if (_selectedPlaceId == null || _selectedPlaceId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes seleccionar un local")),
      );
      return;
    }

    // Validación fecha
    final eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    if (eventDateTime.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La fecha del evento ya pasó")),
      );
      return;
    }

    setState(() => _uploading = true);

    final placeId = _selectedPlaceId!;

    // Lógica de subida de imagen
    String? finalImageUrl = _currentImageUrl;
    String? imagePath;
    final hasNewImage =
        (kIsWeb && _newImageBytes != null) || (!kIsWeb && _newImageFile != null);

    if (hasNewImage) {
      try {
        final fileName = "event_${DateTime.now().millisecondsSinceEpoch}.jpg";
        imagePath = 'places/$placeId/events/$fileName';
        final ref = FirebaseStorage.instance.ref(imagePath);
        if (kIsWeb) {
          await ref.putData(
            _newImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
        } else {
          await ref.putFile(_newImageFile!);
        }
        finalImageUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint("Error subiendo imagen: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al subir imagen: $e")),
          );
        }
        setState(() => _uploading = false);
        return;
      }
    }

    final eventData = {
      'placeId': placeId,
      'placeName': _selectedPlaceName ?? 'Local',
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'imageUrl': finalImageUrl,
      'imagePath': imagePath,
      'date': Timestamp.fromDate(eventDateTime),
      // 🔥 IMPORTANTE: notificationType: 'none' para que NO notifique
      'notificationType': 'none',
    };

    try {
      await FirebaseFirestore.instance.collection('events').add(eventData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Evento creado sin notificaciones"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error guardando evento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
        setState(() => _uploading = false);
      }
    }
  }

  Widget _buildInput(String label, TextEditingController ctrl,
      {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings, color: Colors.purpleAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Nuevo Evento (SuperAdmin)",
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje informativo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purpleAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Este evento NO enviará notificaciones a los usuarios",
                        style: TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TIPO DE EVENTO
              Row(
                children: [
                  Expanded(
                    child: EventTypeSelector(
                      label: "Show / Banda",
                      value: 'show',
                      groupValue: _selectedType,
                      onTap: () => setState(() => _selectedType = 'show'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: EventTypeSelector(
                      label: "Promo / Oferta",
                      value: 'promo',
                      groupValue: _selectedType,
                      onTap: () => setState(() => _selectedType = 'promo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // IMAGEN
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    image: _getImageProvider() != null
                        ? DecorationImage(
                            image: _getImageProvider()!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _getImageProvider() == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              color: Colors.purpleAccent,
                              size: 30,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Agregar Imagen (Opcional)",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 20),
              
              // SELECTOR DE LOCAL CON BÚSQUEDA
              const Text(
                "Local *",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Campo de búsqueda
                    TextField(
                      controller: _placeSearchCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Buscar local...",
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search, color: Colors.purpleAccent),
                        suffixIcon: _selectedPlaceId != null
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.white54),
                                onPressed: () {
                                  setState(() {
                                    _selectedPlaceId = null;
                                    _selectedPlaceName = null;
                                    _placeSearchCtrl.clear();
                                  });
                                  _loadPlaces();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    
                    // Lista de resultados
                    if (_filteredPlaces.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filteredPlaces.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: Colors.white10,
                          ),
                          itemBuilder: (context, index) {
                            final place = _filteredPlaces[index];
                            final isSelected = _selectedPlaceId == place['id'];
                            
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPlaceId = place['id'] as String;
                                  _selectedPlaceName = place['name'] as String;
                                  _placeSearchCtrl.text = place['name'] as String;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                color: isSelected
                                    ? Colors.purpleAccent.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.store,
                                      color: isSelected
                                          ? Colors.purpleAccent
                                          : Colors.white54,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            place['name'] as String,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                          if (place['address'] != null &&
                                              (place['address'] as String).isNotEmpty)
                                            Text(
                                              place['address'] as String,
                                              style: TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // Indicador de selección
                    if (_selectedPlaceId != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.purpleAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Seleccionado: $_selectedPlaceName",
                                style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildInput("Título *", _titleCtrl),
              const SizedBox(height: 10),
              _buildInput("Descripción breve", _descCtrl, maxLines: 2),
              const SizedBox(height: 20),

              // FECHA Y HORA
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.purpleAccent,
                      ),
                      label: Text(
                        DateFormat("dd/MM/yyyy").format(_selectedDate),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(
                        Icons.access_time,
                        color: Colors.purpleAccent,
                      ),
                      label: Text(
                        _selectedTime.format(context),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (!_uploading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.white54),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
          onPressed: _uploading ? null : _saveEvent,
          child: _uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Crear Evento"),
        ),
      ],
    );
  }
}
