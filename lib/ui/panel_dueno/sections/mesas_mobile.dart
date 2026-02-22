// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../pos/toma_pedido_screen.dart';
import '../widgets/mesas/mesa_card.dart';
import '../widgets/mesas/estado_button.dart';
import '../logic/mesas_logic.dart'; 

class MesasMobile extends StatefulWidget {
  final String placeId;
  const MesasMobile({super.key, required this.placeId});

  @override
  State<MesasMobile> createState() => _MesasMobileState();
}

class _MesasMobileState extends State<MesasMobile> with MesasLogicMixin {
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

  // ===========================================================================
  // 📱 LAYOUT MÓVIL
  // ===========================================================================
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_agregar_mesa",
        onPressed: () => _abrirModalGestionMesa(),
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _buildMesasGrid(isDesktop: false),
    );
  }

  // ===========================================================================
  // 🖥️ LAYOUT DESKTOP
  // ===========================================================================
  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Mapa de Mesas",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                icon: const Icon(Icons.add),
                label: const Text("Agregar Mesa", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _abrirModalGestionMesa(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildMesasGrid(isDesktop: true)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🧱 GRID INTELIGENTE POR SECTORES (Estilo Fudo)
  // ===========================================================================
  Widget _buildMesasGrid({required bool isDesktop}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("mesas")
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent));
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.table_restaurant, size: 60, color: Colors.grey[800]),
                const SizedBox(height: 16),
                Text(
                  isDesktop
                      ? "No hay mesas. Agrega una arriba a la derecha."
                      : "Tocá + para agregar mesas.",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Calcular información de grupos de reservas
        // 1. Contar cuántas mesas tiene cada reservaIdActiva
        final Map<String, int> mesasPorReserva = {};
        final Map<String, String> reservaIdPorMesaId = {};
        
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final reservaIdActiva = data['reservaIdActiva'] as String?;
          if (reservaIdActiva != null) {
            mesasPorReserva[reservaIdActiva] = (mesasPorReserva[reservaIdActiva] ?? 0) + 1;
            reservaIdPorMesaId[doc.id] = reservaIdActiva;
          }
        }
        
        // 2. Identificar reservas activas únicas y asignarles números
        final reservasActivas = mesasPorReserva.keys.toList();
        final Map<String, int> numeroGrupoPorReserva = {};
        int grupoCounter = 1;
        for (final reservaId in reservasActivas) {
          // Solo numerar si hay 2+ reservas activas diferentes
          if (reservasActivas.length > 1) {
            numeroGrupoPorReserva[reservaId] = grupoCounter++;
          }
        }

        // Agrupar por sectores usando el Mixin
        final gruposPorSector = agruparPorSector(docs);
        
        // Convertir 'Sin Sector' a 'General' para mejor UX
        if (gruposPorSector.containsKey('Sin Sector')) {
          final mesasSinSector = gruposPorSector.remove('Sin Sector')!;
          gruposPorSector['General'] = mesasSinSector;
        }

        // Ordenar los sectores alfabéticamente, pero 'General' al final
        final sectoresOrdenados = gruposPorSector.keys.toList()
          ..sort((a, b) {
            if (a == 'General') return 1;
            if (b == 'General') return -1;
            return a.compareTo(b);
          });

        // Ordenar mesas dentro de cada sector usando ordenamiento natural
        for (final sector in sectoresOrdenados) {
          gruposPorSector[sector]!.sort((a, b) {
            final nombreA =
                (a.data() as Map<String, dynamic>)['nombre'].toString();
            final nombreB =
                (b.data() as Map<String, dynamic>)['nombre'].toString();
            return compareNatural(nombreA, nombreB);
          });
        }

        return ListView.builder(
          padding: isDesktop ? const EdgeInsets.all(0) : const EdgeInsets.all(16),
          itemCount: sectoresOrdenados.length,
          itemBuilder: (context, sectorIndex) {
            final sector = sectoresOrdenados[sectorIndex];
            final mesasDelSector = gruposPorSector[sector]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado del Sector con estilo neón sutil
                Padding(
                  padding: EdgeInsets.only(
                    top: sectorIndex > 0 ? 32 : 0,
                    bottom: 16,
                    left: isDesktop ? 0 : 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orangeAccent.withValues(alpha: 0.1),
                          Colors.orangeAccent.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orangeAccent.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.orangeAccent.withValues(alpha: 0.8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sector.toUpperCase(),
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.orangeAccent.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${mesasDelSector.length}",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // GridView de mesas del sector
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: isDesktop ? 220 : 180,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: mesasDelSector.length,
                  itemBuilder: (_, i) {
                    final data = mesasDelSector[i].data() as Map<String, dynamic>;
                    final id = mesasDelSector[i].id;
                    final reservaIdActiva = data['reservaIdActiva'] as String?;
                    
                    // Determinar si mostrar badge y qué número de grupo
                    bool showGrupoBadge = false;
                    int? grupoNumber;
                    
                    if (reservaIdActiva != null) {
                      // Solo mostrar badge si hay 2+ mesas con la misma reserva
                      final cantidadMesasConEstaReserva = mesasPorReserva[reservaIdActiva] ?? 0;
                      if (cantidadMesasConEstaReserva >= 2) {
                        showGrupoBadge = true;
                        // Solo asignar número si hay múltiples reservas activas diferentes
                        if (reservasActivas.length > 1) {
                          grupoNumber = numeroGrupoPorReserva[reservaIdActiva];
                        }
                      }
                    }

                    return MesaCard(
                      data: data,
                      isDesktop: isDesktop,
                      showGrupoBadge: showGrupoBadge,
                      grupoNumber: grupoNumber,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TomaPedidoScreen(
                              placeId: widget.placeId,
                              mesaId: id,
                              mesaNombre: data['nombre'] ?? 'Mesa',
                            ),
                          ),
                        );
                      },
                      onLongPress: () => _abrirModalGestionMesa(id: id, data: data),
                      onEditDesktop: () => _abrirModalGestionMesa(id: id, data: data),
                      onDeleteDesktop: () => _confirmarEliminar(id),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }


  // ===========================================================================
  // 🛠️ MODALES Y GESTIÓN (Con Traba de Seguridad)
  // ===========================================================================
  void _abrirModalGestionMesa({String? id, Map<String, dynamic>? data}) {
    final nombreCtrl = TextEditingController(text: data?['nombre'] ?? '');
    final capCtrl = TextEditingController(text: data?['capacidad']?.toString() ?? '2');
    final sectorCtrl = TextEditingController(text: data?['sector']?.toString() ?? '');
    String estadoActual = data?['estado'] ?? 'libre';
    bool guardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: Text(id == null ? "Nueva Mesa" : "Gestionar Mesa", style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nombreCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Nombre (ej: Mesa 5)", labelStyle: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: capCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: "Capacidad", labelStyle: TextStyle(color: Colors.white70)),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: sectorCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: "Sector (ej: Patio, VIP, Planta Alta)",
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: "Dejar vacío para 'General'",
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text("Estado Manual:", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                              child: EstadoButton(
                                  label: "LIBRE",
                                  color: Colors.greenAccent,
                                  isSelected: estadoActual == 'libre',
                                  onTap: () =>
                                      setDialogState(() => estadoActual = 'libre'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: EstadoButton(
                                  label: "OCUPADA",
                                  color: Colors.redAccent,
                                  isSelected: estadoActual == 'ocupada',
                                  onTap: () =>
                                      setDialogState(() => estadoActual = 'ocupada'))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                              child: EstadoButton(
                                  label: "PAGADA",
                                  color: Colors.blueAccent,
                                  isSelected: estadoActual == 'pagada',
                                  onTap: () =>
                                      setDialogState(() => estadoActual = 'pagada'))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: EstadoButton(
                                  label: "RESERVADA",
                                  color: Colors.orangeAccent,
                                  isSelected: estadoActual == 'reservada',
                                  onTap: () =>
                                      setDialogState(() => estadoActual = 'reservada'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (id != null && !guardando)
                  TextButton(
                    onPressed: () => _confirmarEliminar(id),
                    child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent)),
                  ),
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(ctx), 
                  child: const Text("Cancelar", style: TextStyle(color: Colors.white70))
                ),
                // Reemplazamos la lógica del botón "Guardar" en _abrirModalGestionMesa

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orangeAccent,
    foregroundColor: Colors.black,
  ),
  onPressed: guardando ? null : () async {
    if (nombreCtrl.text.isEmpty) return;

    // 🚨 BLOQUEO DE SEGURIDAD CRÍTICO
    // Si el usuario quiere poner "LIBRE" pero el documento de Firebase dice que hay un cliente
    if (estadoActual == 'libre' && data?['clienteActivo'] != null) {
      
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text("¡Mesa Ocupada!", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            "Esta mesa tiene una cuenta activa.\n\n"
            "Si la liberas ahora, el pedido quedará 'huérfano' y podrías perder el registro del cobro.\n\n"
            "¿Estás ABSOLUTAMENTE seguro de forzar la liberación?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("SÍ, FORZAR LIBERACIÓN"),
            ),
          ],
        ),
      );

      // Si el usuario no confirmó el "Forzado", detenemos el guardado
      if (proceed != true) return;
    }

    // Si pasó el bloqueo o el estado no es libre, procedemos a guardar
    setDialogState(() => guardando = true);

    try {
      final Map<String, dynamic> payload = {
        "nombre": nombreCtrl.text.trim(),
        "capacidad": int.tryParse(capCtrl.text) ?? 2,
        "estado": estadoActual,
        "sector": sectorCtrl.text.trim().isEmpty ? null : sectorCtrl.text.trim(),
      };
      
      // Al liberar, limpiamos los campos de sesión
      if (estadoActual == 'libre' && id != null) {
        payload["clienteActivo"] = FieldValue.delete();
        payload["reservaIdActiva"] = FieldValue.delete();
        payload["fechaOcupacion"] = FieldValue.delete();
        // payload["pedidoId"] = FieldValue.delete(); // Si manejas el ID del pedido aquí también
      }

      final ref = FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("mesas");

      if (id == null) {
        await ref.add(payload);
      } else {
        await ref.doc(id).update(payload);
      }

      if (!mounted) return;
      Navigator.pop(ctx);

    } catch (e) {
      setDialogState(() => guardando = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
      );
    }
  },
  child: guardando 
    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
    : const Text("Guardar"),
),
              ],
            );
          }
        );
      },
    );
  }


  void _confirmarEliminar(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("¿Eliminar mesa?", style: TextStyle(color: Colors.white)),
        content: const Text("Esta acción borrará el historial asociado a esta mesa física.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              FirebaseFirestore.instance.collection("places").doc(widget.placeId).collection("mesas").doc(id).delete();
              Navigator.pop(context); // Cierra confirmación
              Navigator.pop(context); // Cierra modal gestión
            },
            child: const Text("Eliminar"),
          ),
        ],
      )
    );
  }
}
