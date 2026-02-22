// ignore_for_file: use_build_context_synchronously, dead_code
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/reservas/reserva_card_mobile.dart';
import '../widgets/reservas/reserva_estado_badge.dart';
import '../widgets/reservas/multi_mesa_selector.dart';
import '../logic/reservas_logic.dart';

class ReservasMobile extends StatefulWidget {
  final String placeId;
  const ReservasMobile({super.key, required this.placeId});

  @override
  State<ReservasMobile> createState() => _ReservasMobileState();
}

class _ReservasMobileState extends State<ReservasMobile>
    with ReservasLogicMixin {
  // Estado compartido
  String _filtro =
      "pendiente"; // Valores: 'pendiente', 'confirmada', 'en_curso', 'rechazada', 'no_asistio', 'todas'

  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    // Configurar callback para cambiar filtro desde alertas
    onFiltroChanged = (filtro) {
      setState(() => _filtro = filtro);
    };
    // Inicializar lógica de reservas
    initReservasLogic();
  }

  @override
  void dispose() {
    disposeReservasLogic(); // 🛑 Limpiar recursos del Mixin
    super.dispose();
  }


  // ===========================================================================
  // 🏗️ BUILD & LAYOUTS
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  // 📱 LAYOUT MÓVIL
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.black),
        
        onPressed: () => _mostrarCrearEditar(context),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Alertas sonoras",
                style: TextStyle(color: Colors.white)),
            value: alertasSonorasActivas,
            activeThumbColor: Colors.orangeAccent,
            onChanged: (v) => setState(() => alertasSonorasActivas = v),
          ),
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                    filterChipMobile("Hoy", "hoy"),
                const SizedBox(width: 8),
                filterChipMobile("Pendientes", "pendiente"),
                const SizedBox(width: 8),
                filterChipMobile("Confirmadas", "confirmada"),
                const SizedBox(width: 8),
                filterChipMobile("En Curso", "en_curso"),
                const SizedBox(width: 8),
                filterChipMobile("Finalizadas", "completada"),
                const SizedBox(width: 8),
                filterChipMobile("Ausentes", "no_asistio"), // 🔥 Nuevo Filtro
                const SizedBox(width: 8),
                filterChipMobile("Todas", "todas"),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamReservas(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                    child: Text(
                      "Error al cargar",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = _filtrarDocsLocalmente(snap.data?.docs ?? []);

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 60,
                          color: Colors.grey[800],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No hay reservas ($_filtro)",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: docs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    return ReservaCardMobile(
                      id: id,
                      data: data,
                      placeId: widget.placeId,
                      onEdit:
                          () =>
                              _mostrarCrearEditar(context, id: id, data: data),
                      onDelete: () => _confirmarEliminar(context, id, data),
                      onUpdateStatus: (status) async {
                        // Si es confirmar y no tiene mesa asignada, mostrar selector
                        if (status == "confirmada" &&
                            data['mesaId'] == null &&
                            (data['personas'] as int? ?? 0) > 0) {
                          final mesasSeleccionadas =
                              await showDialog<List<String>>(
                            context: context,
                            builder: (ctx) => MultiMesaSelector(
                              placeId: widget.placeId,
                              personasRequeridas: data['personas'] as int? ?? 0,
                            ),
                          );
                          if (!mounted) return;
                          if (mesasSeleccionadas != null &&
                              mesasSeleccionadas.isNotEmpty) {
                            await _confirmarConMultiplesMesas(
                              context,
                              id,
                              data,
                              mesasSeleccionadas,
                            );
                            return;
                          }
                        }
                        // Confirmar normalmente o actualizar estado
                        updateEstado(context, id, data, status);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget filterChipMobile(String label, String value) {
    final isSelected = _filtro == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) setState(() => _filtro = value);
      },
      selectedColor: Colors.orangeAccent,
      backgroundColor: const Color(0xFF1E1E1E),
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
    );
  }

  // 🖥️ LAYOUT DESKTOP
  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Gestión de Reservas",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: const Color(0xFF1E1E1E),
                      value: _filtro,
                      icon: const Icon(
                        Icons.filter_list,
                        color: Colors.white70,
                      ),
                      items:
                          [
                            "pendiente",
                            "confirmada",
                            "en_curso",
                            "completada",
                            "no_asistio",
                            "todas",
                          ].map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text(
                                e.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                      onChanged: (v) => setState(() => _filtro = v!),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => _mostrarCrearEditar(context),
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: const Text(
                    "Nueva reserva",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamReservas(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  );
                }

                final docs = _filtrarDocsLocalmente(snap.data!.docs);

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No se encontraron reservas.",
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.white12),
                      dataRowColor: WidgetStateProperty.all(Colors.transparent),
                      columns: const [
                        DataColumn(
                          label: Text(
                            "Cliente",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Pers.",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Fecha / Hora",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Mesa",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Estado",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            "Acciones",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                      rows:
                          docs.map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            final fecha = (data["fecha"] as Timestamp).toDate();
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    data["cliente"] ?? "Anon",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    "${data["personas"]}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat("dd MMM HH:mm").format(fecha),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _obtenerTextoMesasDesktop(data),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  ReservaEstadoBadge(
                                    estado: data["estado"] ?? "pendiente",
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Colors.blueAccent,
                                        ),
                                        onPressed:
                                            () => _mostrarCrearEditar(
                                              context,
                                              id: d.id,
                                              data: data,
                                            ),
                                      ),

                                      if (data["estado"] == "pendiente")
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check,
                                            size: 20,
                                            color: Colors.greenAccent,
                                          ),
                                          onPressed: () async {
                                            // Si no tiene mesa asignada y requiere múltiples mesas
                                            final mesaId = data["mesaId"];
                                            final personas = data["personas"] as int? ?? 0;
                                            if (mesaId == null && personas > 0) {
                                              // Mostrar selector de múltiples mesas
                                              final mesasSeleccionadas =
                                                  await showDialog<List<String>>(
                                                context: context,
                                                builder: (ctx) =>
                                                    MultiMesaSelector(
                                                  placeId: widget.placeId,
                                                  personasRequeridas: personas,
                                                ),
                                              );
                                              if (!mounted) return;
                                              if (mesasSeleccionadas != null &&
                                                  mesasSeleccionadas.isNotEmpty) {
                                                // Actualizar con múltiples mesas
                                                await _confirmarConMultiplesMesas(
                                                  context,
                                                  d.id,
                                                  data,
                                                  mesasSeleccionadas,
                                                );
                                              }
                                            } else {
                                              // Confirmar normalmente
                                              updateEstado(
                                                context,
                                                d.id,
                                                data,
                                                "confirmada",
                                              );
                                            }
                                          },
                                        ),
                                      if (data["estado"] == "confirmada")
                                        IconButton(
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            size: 20,
                                            color: Colors.orangeAccent,
                                          ),
                                          onPressed:
                                              () => updateEstado(
                                                context,
                                                d.id,
                                                data,
                                                "en_curso",
                                              ),
                                        ),
                                      if (data["estado"] == "en_curso")
                                        IconButton(
                                          icon: const Icon(
                                            Icons.stop,
                                            size: 20,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed:
                                              () => updateEstado(
                                                context,
                                                d.id,
                                                data,
                                                "completada",
                                              ),
                                        ),

                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed:
                                            () => _confirmarEliminar(
                                              context,
                                              d.id,
                                              data,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ⚙️ LÓGICA CRUD + STREAMS
  // ===========================================================================

 Stream<QuerySnapshot> _streamReservas() {
  // 1. Definimos el punto de corte (hoy a las 00:00:00)
  final now = DateTime.now();
  final inicioHoy = DateTime(now.year, now.month, now.day);

  return FirebaseFirestore.instance
      .collection("places")
      .doc(widget.placeId)
      .collection("reservas")
      // 2. Filtramos en el servidor: solo lo de hoy en adelante
      .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
      .orderBy('fecha', descending: false)
      .snapshots();
}

List<DocumentSnapshot> _filtrarDocsLocalmente(List<DocumentSnapshot> docs) {
  if (_filtro == "todas" || _filtro == "hoy") return docs; 
  // 'hoy' ya viene implícito en el stream ahora
  
  return docs
      .where((d) => (d.data() as Map<String, dynamic>)['estado'] == _filtro)
      .toList();
}



  /// Confirma una reserva asignando múltiples mesas
  Future<void> _confirmarConMultiplesMesas(
    BuildContext context,
    String reservaId,
    Map<String, dynamic> data,
    List<String> mesasIds,
  ) async {
    try {
      // Obtener nombres de las mesas
      final mesasSnap = await FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("mesas")
          .get();

      final mesasNombres = mesasIds.map((id) {
        final doc = mesasSnap.docs.firstWhere((d) => d.id == id);
        return doc.data()['nombre'] ?? 'Mesa';
      }).toList();

      final batch = FirebaseFirestore.instance.batch();
      final reservaRef = FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("reservas")
          .doc(reservaId);

      // Actualizar reserva con múltiples mesas
      batch.update(reservaRef, {
        "estado": "confirmada",
        "mesaId": mesasIds,
        "mesaNombre": mesasNombres,
      });

      // Marcar todas las mesas como reservadas
      for (final mesaId in mesasIds) {
        final mesaRef = FirebaseFirestore.instance
            .collection("places")
            .doc(widget.placeId)
            .collection("mesas")
            .doc(mesaId);

        batch.update(mesaRef, {
          "estado": "reservada",
          "reservaIdActiva": reservaId,
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Reserva confirmada con ${mesasIds.length} mesa(s) asignada(s)"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error confirmando con múltiples mesas: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              "Eliminar Reserva",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "¿Estás seguro? Esto liberará la mesa asociada.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Eliminar",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();
    batch.delete(
      FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("reservas")
          .doc(id),
    );

    // Liberar mesa(s) y limpiar cliente - Soporta múltiples mesas
    final mesaId = data['mesaId'];
    List<String> mesasIds = [];

    if (mesaId != null) {
      if (mesaId is List) {
        mesasIds = List<String>.from(mesaId);
      } else {
        mesasIds = [mesaId.toString()];
      }

      // Liberar todas las mesas asociadas
      for (final mesaIdStr in mesasIds) {
        final mesaRef = FirebaseFirestore.instance
            .collection("places")
            .doc(widget.placeId)
            .collection("mesas")
            .doc(mesaIdStr);

        final mesaSnap = await mesaRef.get();
        final reservaActiva = mesaSnap.data()?['reservaIdActiva'];

        // 🔒 Liberar SOLO si corresponde
        if (reservaActiva == id) {
          batch.update(mesaRef, {
            "estado": "libre",
            "clienteActivo": FieldValue.delete(),
            "reservaIdActiva": FieldValue.delete(),
          });
        }
      }
    }

    await batch.commit();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Reserva eliminada"),
        backgroundColor: Colors.red,
      ),
    );
  }

 Future<void> _mostrarCrearEditar(
  BuildContext context, {
  String? id,
  Map<String, dynamic>? data,
}) async {
  final isEdit = id != null;
  final clienteCtrl = TextEditingController(text: data?["cliente"] ?? "");
  final personasCtrl =
      TextEditingController(text: data?["personas"]?.toString() ?? "2");

  DateTime fechaSeleccionada = data?["fecha"] != null
      ? (data!["fecha"] as Timestamp).toDate()
      : DateTime.now().add(const Duration(hours: 1));

  // Manejar mesas: puede ser String (una mesa) o List<String> (múltiples mesas)
  String? mesaSeleccionadaId;
  String? mesaSeleccionadaNombre;
  List<String>? mesasSeleccionadasIds;
  List<String>? mesasSeleccionadasNombres;

  // Obtener datos existentes
  if (data != null) {
    if (data["mesaId"] is List) {
      mesasSeleccionadasIds = List<String>.from(data["mesaId"]);
      mesasSeleccionadasNombres = data["mesaNombre"] != null
          ? List<String>.from(data["mesaNombre"])
          : null;
    } else if (data["mesaId"] != null) {
      mesaSeleccionadaId = data["mesaId"].toString();
      mesaSeleccionadaNombre = data["mesaNombre"]?.toString();
    }
  }

  // Obtener mesas
  final mesasSnap = await FirebaseFirestore.instance
      .collection("places")
      .doc(widget.placeId)
      .collection("mesas")
      .get();

  List<Map<String, dynamic>> mesasDisponibles = [];
  int capacidadMaxima = 0;

  for (var d in mesasSnap.docs) {
    final mesa = d.data();
    final mesaId = d.id;
    final estadoMesa = mesa['estado'];
    final capacidad = (mesa['capacidad'] as num?)?.toInt() ?? 2;
    if (capacidad > capacidadMaxima) capacidadMaxima = capacidad;

    if (estadoMesa == 'libre') {
      mesasDisponibles.add({
        "id": mesaId,
        "nombre": mesa['nombre'],
        "capacidad": capacidad,
        "label": mesa['nombre'],
      });
    } else if (isEdit) {
      // Incluir mesas ya asignadas en edición
      final esMesaActual = mesaId == mesaSeleccionadaId ||
          (mesasSeleccionadasIds?.contains(mesaId) ?? false);
      if (esMesaActual) {
        mesasDisponibles.add({
          "id": mesaId,
          "nombre": mesa['nombre'],
          "capacidad": capacidad,
          "label": "${mesa['nombre']} (Actual)",
        });
      }
    }
  }

  // Si no hay mesa seleccionada y hay mesas disponibles, seleccionar la primera
  if (mesaSeleccionadaId == null &&
      mesasSeleccionadasIds == null &&
      mesasDisponibles.isNotEmpty) {
    mesaSeleccionadaId = mesasDisponibles.first['id'];
    mesaSeleccionadaNombre = mesasDisponibles.first['nombre'];
  }

  if (!mounted) return;

 showDialog(
  context: context,
  barrierDismissible: false, // 🔒 Evita que cierren el diálogo mientras guarda
  builder: (ctx) => StatefulBuilder(
    builder: (context, setDialogState) {
      // 1. Definimos la variable de estado dentro del Dialog
      bool cargando = false; 

      return AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          isEdit ? "Editar Reserva" : "Nueva Reserva",
          style: const TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min, // 📏 Ajuste fino de tamaño
              children: [
                  _inputStyle(
                    TextField(
                      controller: clienteCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Nombre Cliente",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _inputStyle(
                    TextField(
                      controller: personasCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: "Cantidad Personas",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mostrar selector de mesa o indicador de "Sin mesa"
                  if (mesasSeleccionadasIds != null && mesasSeleccionadasIds!.isNotEmpty)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orangeAccent),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.table_restaurant,
                                  color: Colors.orangeAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${mesasSeleccionadasIds!.length} mesa(s) asignada(s)",
                                  style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final personas = int.tryParse(personasCtrl.text) ?? 2;
                              final mesasSeleccionadas =
                                  await showDialog<List<String>>(
                                context: context,
                                builder: (ctx) => MultiMesaSelector(
                                  placeId: widget.placeId,
                                  personasRequeridas: personas,
                                  mesasYaSeleccionadas: mesasSeleccionadasIds,
                                ),
                              );
                              if (mesasSeleccionadas != null &&
                                  mesasSeleccionadas.isNotEmpty) {
                                final mesasNombres = mesasSeleccionadas
                                    .map<String>((id) {
                                      final mesa = mesasDisponibles.firstWhere(
                                        (m) => m['id'] == id,
                                        orElse: () => {"nombre": "Mesa"},
                                      );
                                      return mesa['nombre'] as String;
                                    })
                                    .toList();
                                
                                setDialogState(() {
                                  mesasSeleccionadasIds = mesasSeleccionadas;
                                  mesasSeleccionadasNombres = mesasNombres;
                                  mesaSeleccionadaId = null;
                                  mesaSeleccionadaNombre = null;
                                });
                              } else if (mesasSeleccionadas != null && mesasSeleccionadas.isEmpty) {
                                // Si se canceló o se deseleccionaron todas, limpiar
                                setDialogState(() {
                                  mesasSeleccionadasIds = null;
                                  mesasSeleccionadasNombres = null;
                                });
                              }
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Editar Mesas"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orangeAccent,
                              side: const BorderSide(color: Colors.orangeAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2C),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF2C2C2C),
                          isExpanded: true,
                          value: mesaSeleccionadaId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text(
                                "Sin mesa asignada",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                            ...mesasDisponibles.map((m) {
                              return DropdownMenuItem<String>(
                                value: m['id'],
                                child: Text(
                                  "${m['label']} (${m['capacidad']} pers.)",
                                  style: const TextStyle(color: Colors.white),
                                ),
                                onTap: () =>
                                    mesaSeleccionadaNombre = m['nombre'],
                              );
                            }),
                          ],
                          onChanged: (v) => setDialogState(() {
                            mesaSeleccionadaId = v;
                            if (v != null) {
                              final mesa = mesasDisponibles.firstWhere(
                                  (m) => m['id'] == v);
                              mesaSeleccionadaNombre = mesa['nombre'];
                              // Limpiar múltiples mesas si se selecciona una sola
                              mesasSeleccionadasIds = null;
                              mesasSeleccionadasNombres = null;
                            } else {
                              mesaSeleccionadaNombre = null;
                            }
                          }),
                        ),
                      ),
                    ),
                  // Mostrar advertencia y botón si las personas superan la capacidad
                  Builder(
                    builder: (context) {
                      final personasIngresadas = int.tryParse(personasCtrl.text) ?? 0;
                      final capacidadMesaSeleccionada = mesaSeleccionadaId != null
                          ? (mesasDisponibles.firstWhere(
                                (m) => m['id'] == mesaSeleccionadaId,
                                orElse: () => {"capacidad": 0},
                              )['capacidad'] as int)
                          : 0;
                      
                      final necesitaMultiplesMesas = personasIngresadas > capacidadMaxima ||
                          (mesaSeleccionadaId != null && personasIngresadas > capacidadMesaSeleccionada);
                      
                      if (personasIngresadas > 0 &&
                          necesitaMultiplesMesas &&
                          mesasSeleccionadasIds == null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.orangeAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mesaSeleccionadaId != null
                                        ? "La mesa seleccionada no tiene suficiente capacidad (${personasCtrl.text} pers.). "
                                            "Asigna múltiples mesas para cubrir la capacidad requerida."
                                        : "Grupo grande (${personasCtrl.text} pers.). "
                                            "Asigna múltiples mesas para cubrir la capacidad.",
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final personas = int.tryParse(personasCtrl.text) ?? 2;
                                final mesasSeleccionadas =
                                    await showDialog<List<String>>(
                                  context: context,
                                  builder: (ctx) => MultiMesaSelector(
                                    placeId: widget.placeId,
                                    personasRequeridas: personas,
                                    mesasYaSeleccionadas: mesasSeleccionadasIds,
                                  ),
                                );
                                if (mesasSeleccionadas != null &&
                                    mesasSeleccionadas.isNotEmpty) {
                                  // Obtener nombres de las mesas
                                  final mesasNombres = mesasSeleccionadas
                                      .map<String>((id) {
                                        final mesa = mesasDisponibles.firstWhere(
                                          (m) => m['id'] == id,
                                          orElse: () => {"nombre": "Mesa"},
                                        );
                                        return mesa['nombre'] as String;
                                      })
                                      .toList();
                                  
                                  setDialogState(() {
                                    mesasSeleccionadasIds = mesasSeleccionadas;
                                    mesasSeleccionadasNombres = mesasNombres;
                                    mesaSeleccionadaId = null;
                                    mesaSeleccionadaNombre = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.table_restaurant, size: 18),
                              label: const Text("Asignar Múltiples Mesas"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: const Color(0xFF2C2C2C),
                    title: Text(
                      DateFormat("dd/MM/yyyy HH:mm")
                          .format(fechaSeleccionada),
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.calendar_today,
                        color: Colors.orangeAccent),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: fechaSeleccionada,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (!mounted) return;
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay.fromDateTime(fechaSeleccionada),
                        );
                        if (!mounted) return;
                        if (time != null) {
                          setDialogState(() {
                            fechaSeleccionada = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
         actions: [
          TextButton(
            // 🚫 Deshabilitamos cancelar si está guardando
            onPressed: cargando ? null : () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              minimumSize: const Size(100, 45), // Un poco más de cuerpo
            ),
            // 2. Lógica del botón con bloqueo
            onPressed: cargando
              ? null
              : () async {
                final personas = int.tryParse(personasCtrl.text) ?? 2;

                // VALIDACIONES
                if (clienteCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ingresá el nombre del cliente")),
                  );
                  return;
                }

                // 3. Activamos el estado de carga
                setDialogState(() => cargando = true);

                try {
                  final batch = FirebaseFirestore.instance.batch();
                  final docRef = isEdit
                      ? FirebaseFirestore.instance
                          .collection("places")
                          .doc(widget.placeId)
                          .collection("reservas")
                          .doc(id)
                      : FirebaseFirestore.instance
                          .collection("places")
                          .doc(widget.placeId)
                          .collection("reservas")
                          .doc();

                  // Preparar payload con soporte para múltiples mesas
                  final payload = <String, dynamic>{
                    "cliente": clienteCtrl.text,
                    "personas": personas,
                    "fecha": Timestamp.fromDate(fechaSeleccionada),
                    "estado": data?['estado'] ?? 'pendiente',
                    "alerta15minEnviada": false,
                    if (!isEdit) "creadoEn": FieldValue.serverTimestamp(),
                  };

                  // Manejar mesas: puede ser una sola o múltiples
                  if (mesasSeleccionadasIds != null &&
                      mesasSeleccionadasIds!.isNotEmpty) {
                    // Múltiples mesas
                    payload["mesaId"] = mesasSeleccionadasIds;
                    payload["mesaNombre"] = mesasSeleccionadasNombres ??
                        mesasSeleccionadasIds!
                            .map((id) {
                              final mesa = mesasDisponibles.firstWhere(
                                (m) => m['id'] == id,
                                orElse: () => {"nombre": "Mesa"},
                              );
                              return mesa['nombre'];
                            })
                            .toList();
                  } else if (mesaSeleccionadaId != null) {
                    // Una sola mesa
                    payload["mesaId"] = mesaSeleccionadaId;
                    payload["mesaNombre"] = mesaSeleccionadaNombre;
                  } else {
                    // Sin mesa asignada - permitir guardar sin mesa
                    payload["mesaId"] = null;
                    payload["mesaNombre"] = null;
                  }

                  if (isEdit) {
                    batch.update(docRef, payload);
                  } else {
                    batch.set(docRef, payload);
                    // Si hay mesas asignadas, marcarlas como reservadas
                    if (mesasSeleccionadasIds != null &&
                        mesasSeleccionadasIds!.isNotEmpty) {
                      for (final mesaId in mesasSeleccionadasIds!) {
                        batch.update(
                          FirebaseFirestore.instance
                              .collection("places")
                              .doc(widget.placeId)
                              .collection("mesas")
                              .doc(mesaId),
                          {
                            "estado": "reservada",
                            "reservaIdActiva": docRef.id,
                          },
                        );
                      }
                    } else if (mesaSeleccionadaId != null) {
                      batch.update(
                        FirebaseFirestore.instance
                            .collection("places")
                            .doc(widget.placeId)
                            .collection("mesas")
                            .doc(mesaSeleccionadaId),
                        {
                          "estado": "reservada",
                          "reservaIdActiva": docRef.id,
                        },
                      );
                    }
                  }

                  await batch.commit();
                  if (!mounted) return;
                  Navigator.pop(ctx);
                } catch (e) {
                  // 4. Si falla, liberamos el botón para reintentar
                  setDialogState(() => cargando = false);
                  debugPrint("Error al guardar: $e");
                }
              },
            // 5. Cambio visual: Texto o Spinner
            child: cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                : Text(
                    isEdit ? "Guardar" : "Crear",
                    style: const TextStyle(color: Colors.black),
                  ),
          ),
        ],
        );
      },
    ),
  );
}

  String _obtenerTextoMesasDesktop(Map<String, dynamic> data) {
    final mesaNombre = data["mesaNombre"];
    final mesaId = data["mesaId"];
    final estado = data["estado"] ?? "pendiente";

    if (mesaId == null) {
      return estado == "pendiente" 
          ? "Pendiente asignación" 
          : "Sin mesa asignada";
    }

    if (mesaId is List) {
      final ids = List<String>.from(mesaId);
      if (ids.isEmpty) return "Sin mesa";
      if (ids.length == 1) {
        return mesaNombre is List
            ? List<String>.from(mesaNombre).first
            : (mesaNombre?.toString() ?? "Mesa Asignada");
      }
      return "${ids.length} mesas";
    }

    return mesaNombre?.toString() ?? "Mesa Asignada";
  }

  Widget _inputStyle(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

