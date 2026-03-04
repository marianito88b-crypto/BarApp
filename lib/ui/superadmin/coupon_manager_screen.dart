import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/coupons_service.dart';

/// Pantalla de gestión de cupones para Superadmin
class CouponManagerScreen extends StatefulWidget {
  const CouponManagerScreen({super.key});

  @override
  State<CouponManagerScreen> createState() => _CouponManagerScreenState();
}

class _CouponManagerScreenState extends State<CouponManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  double _descuentoPorcentaje = 10.0;
  String _alcance = 'global'; // 'global' o 'especifico'
  bool _usoUnicoGlobal = true; // true = un solo uso en toda la app, false = un solo uso por bar
  final Set<String> _baresSeleccionados = {};
  bool _isLoading = false;
  late final Stream<QuerySnapshot> _placesStream;
  late final Stream<QuerySnapshot> _cuponesStream;

  @override
  void initState() {
    super.initState();
    _placesStream = FirebaseFirestore.instance.collection('places').snapshots();
    _cuponesStream = FirebaseFirestore.instance
        .collection('cupones_maestros')
        .where('activo', isEqualTo: true)
        .orderBy('creadoEn', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _crearCupon() async {
    if (!_formKey.currentState!.validate()) return;

    if (_alcance == 'especifico' && _baresSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Selecciona al menos un bar para cupones específicos"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await CouponsService.crearCuponMaestro(
        codigo: _codigoController.text.trim().toUpperCase(),
        descuentoPorcentaje: _descuentoPorcentaje,
        alcance: _alcance,
        placeIds: _alcance == 'especifico' ? _baresSeleccionados.toList() : null,
        usoUnicoGlobal: _usoUnicoGlobal,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Cupón creado exitosamente"),
            backgroundColor: Colors.green,
          ),
        );
        // Limpiar formulario
        _codigoController.clear();
        setState(() {
          _descuentoPorcentaje = 10.0;
          _alcance = 'global';
          _usoUnicoGlobal = true;
          _baresSeleccionados.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _desactivarCupon(String cuponId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Desactivar Cupón",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "¿Estás seguro de desactivar este cupón? Los usuarios ya no podrán usarlo.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Desactivar"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CouponsService.desactivarCuponMaestro(cuponId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Cupón desactivado"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Colors.orangeAccent),
            SizedBox(width: 12),
            Text('Centro de Mandos de Cupones'),
          ],
        ),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulario de creación
            _buildCreateForm(),
            const SizedBox(height: 32),
            // Lista de cupones activos
            _buildActiveCouponsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Crear Nuevo Cupón",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Código
            TextFormField(
              controller: _codigoController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "Código del cupón",
                hintText: "Ej: BIENVENIDA",
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orangeAccent),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return "Ingresa un código";
                }
                if (value.trim().length < 3) {
                  return "El código debe tener al menos 3 caracteres";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Descuento
            const Text(
              "Descuento (%):",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Slider(
              value: _descuentoPorcentaje,
              min: 5,
              max: 50,
              divisions: 9,
              label: "${_descuentoPorcentaje.toInt()}%",
              activeColor: Colors.orangeAccent,
              onChanged: (value) => setState(() => _descuentoPorcentaje = value),
            ),
            const SizedBox(height: 20),
            // Alcance
            const Text(
              "Alcance:",
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _alcance,
              onChanged: (value) => setState(() {
                if (value != null) {
                  _alcance = value;
                  if (value == 'global') _baresSeleccionados.clear();
                }
              }),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Global (Todos los bares)", style: TextStyle(color: Colors.white70)),
                      value: 'global',
                      activeColor: Colors.orangeAccent,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Específico (Seleccionar bares)", style: TextStyle(color: Colors.white70)),
                      value: 'especifico',
                      activeColor: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
            // Selector de bares (si es específico)
            if (_alcance == 'especifico') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Seleccionar bares:",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot>(
                      stream: _placesStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final places = snapshot.data!.docs;
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: places.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final nombre = data['nombre'] ?? data['name'] ?? 'Sin nombre';
                            final isSelected = _baresSeleccionados.contains(doc.id);
                            return FilterChip(
                              label: Text(nombre),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _baresSeleccionados.add(doc.id);
                                  } else {
                                    _baresSeleccionados.remove(doc.id);
                                  }
                                });
                              },
                              selectedColor: Colors.orangeAccent.withValues(alpha: 0.3),
                              checkmarkColor: Colors.orangeAccent,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Tipo de uso
            const Text(
              "Tipo de Uso:",
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: Text(
                _usoUnicoGlobal
                    ? "Un solo uso en toda la app"
                    : "Un solo uso por cada bar",
                style: const TextStyle(color: Colors.white70),
              ),
              value: _usoUnicoGlobal,
              activeThumbColor: Colors.orangeAccent,
              onChanged: (value) => setState(() => _usoUnicoGlobal = value),
            ),
            const SizedBox(height: 24),
            // Botón crear
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _crearCupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(
                  _isLoading ? "Creando..." : "Crear Cupón",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCouponsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cupones Activos",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _cuponesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final cupones = snapshot.data!.docs;
            if (cupones.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Text(
                    "No hay cupones activos",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              );
            }

            return Column(
              children: cupones.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildCouponCard(doc.id, data);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCouponCard(String cuponId, Map<String, dynamic> data) {
    final codigo = data['codigo'] ?? 'SIN CÓDIGO';
    final descuento = (data['descuentoPorcentaje'] as num?)?.toDouble() ?? 0.0;
    final alcance = data['alcance'] ?? 'global';
    final usoUnicoGlobal = data['usoUnicoGlobal'] == true;
    final placeIds = (data['placeIds'] as List?)?.cast<String>() ?? [];
    final creadoEn = (data['creadoEn'] as Timestamp?)?.toDate();
    final usadoCount = (data['usadoCount'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Información del cupón
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        codigo,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${descuento.toInt()}% OFF",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Alcance: ${alcance == 'global' ? 'Todos los bares' : '${placeIds.length} bar(es) específico(s)'}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "Uso: ${usoUnicoGlobal ? 'Un solo uso en toda la app' : 'Un solo uso por bar'}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (creadoEn != null)
                  Text(
                    "Creado: ${DateFormat('dd/MM/yyyy').format(creadoEn)}",
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                Text(
                  "Usado: $usadoCount vez(es)",
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          // Botón desactivar
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _desactivarCupon(cuponId),
            tooltip: "Desactivar cupón",
          ),
        ],
      ),
    );
  }
}
