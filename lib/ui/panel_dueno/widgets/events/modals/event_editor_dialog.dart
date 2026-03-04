import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../event_type_selector.dart';

/// Diálogo para crear o editar eventos/anuncios
/// 
/// Soporta tanto Web como Móvil con lógica híbrida para el manejo de imágenes.
class EventEditorDialog extends StatefulWidget {
  final String placeId;
  final DocumentSnapshot? doc;

  const EventEditorDialog({
    super.key,
    required this.placeId,
    this.doc,
  });

  @override
  State<EventEditorDialog> createState() => _EventEditorDialogState();

  /// Método estático para mostrar el diálogo fácilmente
  static void show({
    required BuildContext context,
    required String placeId,
    DocumentSnapshot? doc,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EventEditorDialog(
        placeId: placeId,
        doc: doc,
      ),
    );
  }
}

class _EventEditorDialogState extends State<EventEditorDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  late String _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _currentImageUrl;
  String _notificationScope = 'followers';

  File? _newImageFile;
  Uint8List? _newImageBytes;
  bool _uploading = false;

  bool get _isEditing => widget.doc != null;

  @override
  void initState() {
    super.initState();
    final data = _isEditing
        ? widget.doc!.data() as Map<String, dynamic>
        : <String, dynamic>{};

    _titleCtrl = TextEditingController(text: data['title'] ?? '');
    _descCtrl = TextEditingController(text: data['description'] ?? '');

    _selectedType = data['type'] ?? 'show';
    _selectedDate = data['date'] != null
        ? (data['date'] as Timestamp).toDate()
        : DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _currentImageUrl = data['imageUrl'];
    _notificationScope = data['notificationType'] ?? 'followers';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
    if (_titleCtrl.text.isEmpty) return;

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

    // Lógica de subida de imagen
    String? finalImageUrl = _currentImageUrl;
    String? imagePath;
    final data = _isEditing
        ? widget.doc!.data() as Map<String, dynamic>
        : <String, dynamic>{};
    final hasNewImage =
        (kIsWeb && _newImageBytes != null) || (!kIsWeb && _newImageFile != null);

    if (hasNewImage) {
      try {
        final fileName = "event_${DateTime.now().millisecondsSinceEpoch}.jpg";
        imagePath = 'places/${widget.placeId}/events/$fileName';
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

        // Borrar la imagen anterior de Storage si estamos editando
        final oldImagePath = data['imagePath'] as String?;
        if (_isEditing && oldImagePath != null && oldImagePath.isNotEmpty) {
          try {
            await FirebaseStorage.instance.ref(oldImagePath).delete();
          } catch (_) {
            // Ignorar: puede que ya no exista el archivo antiguo
          }
        }
      } catch (e) {
        debugPrint("Error img: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al subir la imagen: $e"), backgroundColor: Colors.red),
          );
          setState(() => _uploading = false);
        }
        return;
      }
    }

    // Data final con el tipo de notificación
    final eventData = {
      'placeId': widget.placeId,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': _selectedType,
      'imageUrl': finalImageUrl,
      'imagePath': hasNewImage ? imagePath : data['imagePath'],
      'date': Timestamp.fromDate(eventDateTime),
      // Solo actualizamos notificationType al crear, no al editar
      'notificationType':
          _isEditing ? data['notificationType'] : _notificationScope,
    };

    try {
      if (_isEditing) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.doc!.id)
            .update(eventData);
      } else {
        await FirebaseFirestore.instance.collection('events').add(eventData);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error guardando evento: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
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
      title: Text(
        _isEditing ? "Editar Anuncio" : "Nuevo Anuncio",
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                child: Builder(
                  builder: (context) {
                    final imgProvider = _getImageProvider();
                    return Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                        image: imgProvider != null
                            ? DecorationImage(
                                image: imgProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imgProvider == null
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
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              _buildInput("Título", _titleCtrl),
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

              const SizedBox(height: 20),

              // SELECTOR DE ALCANCE (NOTIFICACIONES)
              if (!_isEditing) ...[
                // Solo mostramos esto al crear, editar no debería reenviar notif
                const Text(
                  "📢 Alcance de la Notificación",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                RadioGroup<String>(
                  groupValue: _notificationScope,
                  onChanged: (val) =>
                      setState(() => _notificationScope = val ?? _notificationScope),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                        title: const Text(
                          "Solo Seguidores",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: const Text(
                          "Tus fans. Límite: 1 por día.",
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        value: 'followers',
                        activeColor: Colors.purpleAccent,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          "Global (Todos)",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: const Text(
                          "Todos los usuarios de la App. Límite: 1 por semana.",
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        value: 'global',
                        activeColor: Colors.amber,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                      ),
                      ],
                    ),
                  ),
                ),
              ],
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
              : const Text("Publicar"),
        ),
      ],
    );
  }
}
