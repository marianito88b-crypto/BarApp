import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Widget que permite seleccionar múltiples mesas para una reserva de grupo grande
class MultiMesaSelector extends StatefulWidget {
  final String placeId;
  final int personasRequeridas;
  final List<String>? mesasYaSeleccionadas;

  const MultiMesaSelector({
    super.key,
    required this.placeId,
    required this.personasRequeridas,
    this.mesasYaSeleccionadas,
  });

  @override
  State<MultiMesaSelector> createState() => _MultiMesaSelectorState();
}

class _MultiMesaSelectorState extends State<MultiMesaSelector> {
  final Set<String> _mesasSeleccionadas = {};
  List<Map<String, dynamic>> _mesasDisponibles = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    if (widget.mesasYaSeleccionadas != null) {
      _mesasSeleccionadas.addAll(widget.mesasYaSeleccionadas!);
    }
    _cargarMesas();
  }

  Future<void> _cargarMesas() async {
    try {
      final mesasSnap = await FirebaseFirestore.instance
          .collection("places")
          .doc(widget.placeId)
          .collection("mesas")
          .get();

      final mesas = mesasSnap.docs.map((doc) {
        final data = doc.data();
        return {
          "id": doc.id,
          "nombre": data['nombre'] ?? 'Mesa',
          "capacidad": (data['capacidad'] as num?)?.toInt() ?? 2,
          "estado": data['estado'] ?? 'libre',
        };
      }).toList();

      setState(() {
        _mesasDisponibles = mesas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      debugPrint("Error cargando mesas: $e");
    }
  }

  int _calcularCapacidadTotal() {
    return _mesasSeleccionadas.fold<int>(0, (acc, mesaId) {
      final mesa = _mesasDisponibles.firstWhere(
        (m) => m['id'] == mesaId,
        orElse: () => {"capacidad": 0},
      );
      return acc + (mesa['capacidad'] as int);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      );
    }

    final capacidadTotal = _calcularCapacidadTotal();
    final mesasLibres = _mesasDisponibles
        .where((m) => m['estado'] == 'libre' || _mesasSeleccionadas.contains(m['id']))
        .toList();

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text(
        "Seleccionar Mesas",
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Personas requeridas: ${widget.personasRequeridas}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Capacidad seleccionada: $capacidadTotal",
              style: TextStyle(
                color: capacidadTotal >= widget.personasRequeridas
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Mesas disponibles:",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mesasLibres.length,
                itemBuilder: (context, index) {
                  final mesa = mesasLibres[index];
                  final mesaId = mesa['id'] as String;
                  final nombre = mesa['nombre'] as String;
                  final capacidad = mesa['capacidad'] as int;
                  final isSelected = _mesasSeleccionadas.contains(mesaId);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _mesasSeleccionadas.add(mesaId);
                        } else {
                          _mesasSeleccionadas.remove(mesaId);
                        }
                      });
                    },
                    title: Text(
                      nombre,
                      style: TextStyle(
                        color: isSelected ? Colors.orangeAccent : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      "$capacidad personas",
                      style: const TextStyle(color: Colors.white54),
                    ),
                    activeColor: Colors.orangeAccent,
                    tileColor: isSelected
                        ? Colors.orangeAccent.withValues(alpha: 0.1)
                        : null,
                  );
                },
              ),
            ),
            if (capacidadTotal < widget.personasRequeridas)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "⚠️ Capacidad insuficiente. Selecciona más mesas.",
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.black,
          ),
          onPressed: capacidadTotal >= widget.personasRequeridas
              ? () => Navigator.pop(context, _mesasSeleccionadas.toList())
              : null,
          child: const Text("Confirmar"),
        ),
      ],
    );
  }
}
