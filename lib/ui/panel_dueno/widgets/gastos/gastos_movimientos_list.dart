import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Lista de movimientos de gastos recientes
class GastosMovimientosList extends StatefulWidget {
  final String placeId;

  const GastosMovimientosList({
    super.key,
    required this.placeId,
  });

  @override
  State<GastosMovimientosList> createState() => _GastosMovimientosListState();
}

class _GastosMovimientosListState extends State<GastosMovimientosList> {
  late final Stream<QuerySnapshot> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .collection('gastos')
        .orderBy('fecha', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orangeAccent),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                "Error al cargar movimientos: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: Text(
                "No hay movimientos registrados",
                style: TextStyle(color: Colors.white24, fontSize: 14),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var gasto = doc.data() as Map<String, dynamic>;

            DateTime fecha =
                (gasto['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();

            bool esPendiente = gasto['estado'] == 'pendiente';

            Color colorIconoBg =
                esPendiente ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1);
            Color colorIcono =
                esPendiente ? Colors.blueAccent : Colors.redAccent;
            IconData icono = esPendiente
                ? Icons.access_time_filled_rounded
                : Icons.arrow_downward_rounded;

            String montoTexto = esPendiente
                ? "DEUDA \$${NumberFormat("#,##0", "es_AR").format(gasto['monto'] ?? 0)}"
                : "- \$${NumberFormat("#,##0", "es_AR").format(gasto['monto'] ?? 0)}";

            Color colorMonto = esPendiente ? Colors.blueAccent : Colors.redAccent;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(12),
                border: esPendiente
                    ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.3))
                    : null,
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorIconoBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icono,
                    color: colorIcono,
                    size: 18,
                  ),
                ),
                title: Text(
                  gasto['descripcion'] ?? 'Movimiento',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Flexible(
                      child: Text(
                        "${DateFormat('dd/MM').format(fecha)} • ${gasto['categoria']}",
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (esPendiente) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "A PAGAR",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Tooltip(
                  message: esPendiente
                      ? "Saldo pendiente (No descontado de caja)"
                      : "Gasto realizado",
                  triggerMode: TooltipTriggerMode.tap,
                  child: Text(
                    montoTexto,
                    style: TextStyle(
                      color: colorMonto,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
