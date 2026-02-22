import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tarjeta que muestra el historial de una sesión de caja
class CajaHistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CajaHistoryCard({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Datos básicos
    final String estado = data['estado'] ?? 'cerrada';
    final bool isAbierta = estado == 'abierta';
    final String responsable = data['usuario_apertura'] ?? 'Desconocido';

    // Fechas
    final Timestamp? tsApertura = data['fecha_apertura'];
    final Timestamp? tsCierre = data['fecha_cierre'];
    final String fechaStr = tsApertura != null
        ? DateFormat("dd/MM/yyyy HH:mm").format(tsApertura.toDate())
        : "-";
    final String horaCierreStr = tsCierre != null
        ? DateFormat("HH:mm").format(tsCierre.toDate())
        : "En curso...";

    // Montos
    final double diferencia = (data['diferencia'] as num?)?.toDouble() ?? 0;
    final double real = (data['monto_final_real'] as num?)?.toDouble() ?? 0;
    final double esperado = (data['monto_sistema_calculado'] as num?)?.toDouble() ?? 0;

    // Colores según auditoría
    Color colorEstado;
    IconData iconEstado;

    if (isAbierta) {
      colorEstado = Colors.blueAccent;
      iconEstado = Icons.timelapse;
    } else if (diferencia.abs() < 10) {
      // Margen de error pequeño
      colorEstado = Colors.green;
      iconEstado = Icons.check_circle;
    } else if (diferencia > 0) {
      colorEstado = Colors.blue; // Sobrante
      iconEstado = Icons.trending_up;
    } else {
      colorEstado = Colors.redAccent; // Faltante
      iconEstado = Icons.trending_down;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: colorEstado, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: Colors.white54,
        collapsedIconColor: Colors.white24,
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconEstado, color: colorEstado, size: 24),
          ],
        ),
        title: Text(
          isAbierta ? "TURNO ACTUAL" : "Cierre $fechaStr",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  responsable.split('@')[0],
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            if (!isAbierta)
              Text(
                diferencia == 0
                    ? "Caja Perfecta"
                    : (diferencia > 0
                        ? "Sobra: \$${diferencia.toStringAsFixed(0)}"
                        : "Falta: \$${diferencia.toStringAsFixed(0)}"),
                style: TextStyle(
                  color: colorEstado,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black26,
            child: Column(
              children: [
                CajaRowDetalle("Fondo Inicial:", data['monto_inicial']),
                if (!isAbierta) ...[
                  const Divider(color: Colors.white10),
                  CajaRowDetalle("Sistema calculó:", esperado),
                  CajaRowDetalle("Responsable contó:", real, isBold: true),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Resultado:", style: TextStyle(color: Colors.white54)),
                      Text(
                        diferencia == 0 ? "OK" : "\$ ${diferencia.toStringAsFixed(0)}",
                        style: TextStyle(
                          color: colorEstado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Cerrado a las $horaCierreStr",
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Turno en curso... el arqueo se verá al cerrar.",
                      style: TextStyle(color: Colors.blueAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar una fila de detalle en el historial
class CajaRowDetalle extends StatelessWidget {
  final String label;
  final dynamic valor;
  final bool isBold;

  const CajaRowDetalle(
    this.label,
    this.valor, {
    super.key,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    double val = (valor as num?)?.toDouble() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            "\$${NumberFormat("#,##0", "es_AR").format(val)}",
            style: TextStyle(
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
