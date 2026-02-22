import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../logic/staff_logic.dart';

/// Diálogo para fichar asistencia de un colaborador usando su DNI
class ClockInDialog extends StatefulWidget {
  final String placeId;

  const ClockInDialog({
    super.key,
    required this.placeId,
  });

  /// Método estático para mostrar el diálogo de forma conveniente
  static Future<void> show(BuildContext context, String placeId) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ClockInDialog(placeId: placeId),
    );
  }

  @override
  State<ClockInDialog> createState() => _ClockInDialogState();
}

class _ClockInDialogState extends State<ClockInDialog> with StaffLogicMixin {
  final _dniController = TextEditingController();
  bool _isProcessing = false;
  bool _showSuccess = false;
  String? _successMessage;
  
  // Datos del usuario encontrado
  String? _usuarioNombre;
  String? _usuarioFotoUrl;
  bool _isSearchingUser = false;

  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    _dniController.addListener(_onDniChanged);
  }

  @override
  void dispose() {
    _dniController.removeListener(_onDniChanged);
    _dniController.dispose();
    super.dispose();
  }

  /// Busca al usuario cuando se ingresa el DNI
  void _onDniChanged() async {
    final dni = _dniController.text.trim();
    
    if (dni.isEmpty) {
      setState(() {
        _usuarioNombre = null;
        _usuarioFotoUrl = null;
        _isSearchingUser = false;
      });
      return;
    }

    // Esperar un poco para evitar búsquedas excesivas mientras el usuario escribe
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_dniController.text.trim() != dni) return; // El usuario siguió escribiendo

    setState(() => _isSearchingUser = true);

    try {
      final staffQuery = await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .collection('staff')
          .where('dni', isEqualTo: dni)
          .limit(1)
          .get();

      if (mounted) {
        if (staffQuery.docs.isNotEmpty) {
          final staffData = staffQuery.docs.first.data();
          // Buscar la foto del usuario en la colección usuarios
          final uidStaff = staffQuery.docs.first.id;
          final usuarioDoc = await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uidStaff)
              .get();
          
          final usuarioData = usuarioDoc.data();
          final fotoUrl = usuarioData?['fotoUrl'] as String?;
          
          setState(() {
            _usuarioNombre = staffData['nombre'] ?? 'Colaborador';
            _usuarioFotoUrl = fotoUrl;
            _isSearchingUser = false;
          });
        } else {
          setState(() {
            _usuarioNombre = null;
            _usuarioFotoUrl = null;
            _isSearchingUser = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error buscando usuario: $e");
      if (mounted) {
        setState(() {
          _isSearchingUser = false;
        });
      }
    }
  }

  /// Procesa el fichaje del colaborador
  Future<void> _processClockIn() async {
    final dni = _dniController.text.trim();

    if (dni.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor ingresa el DNI"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await registrarAsistencia(dni: dni);

      if (mounted) {
        setState(() {
          _isProcessing = false;
          if (result['success'] == true) {
            _showSuccess = true;
            _successMessage = result['message'] as String;
            // Cerrar después de 2 segundos
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] as String),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al procesar el fichaje"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Colors.orangeAccent,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            "Fichar Asistencia",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: _showSuccess
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _successMessage ?? "Asistencia registrada",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ingresa el DNI del colaborador",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  
                  // Mostrar foto y nombre si se encontró el usuario
                  if (_usuarioNombre != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orangeAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                            backgroundImage: _usuarioFotoUrl != null && _usuarioFotoUrl!.isNotEmpty
                                ? NetworkImage(_usuarioFotoUrl!)
                                : null,
                            child: _usuarioFotoUrl == null || _usuarioFotoUrl!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    color: Colors.orangeAccent,
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _usuarioNombre!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Listo para fichar",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  TextField(
                    controller: _dniController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      labelText: "DNI",
                      hintText: "Ej: 12345678",
                      prefixIcon: _isSearchingUser
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.badge,
                              color: Colors.orangeAccent,
                            ),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _processClockIn(),
                  ),
                ],
              ),
      ),
      actions: _showSuccess
          ? null
          : [
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _isProcessing ? null : _processClockIn,
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        "Confirmar",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
    );
  }
}
