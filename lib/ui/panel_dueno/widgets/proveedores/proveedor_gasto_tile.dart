import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget que representa un ítem del historial de gastos/remitos del proveedor
class ProveedorGastoTile extends StatelessWidget {
  final String gastoId;
  final Map<String, dynamic> gasto;
  final VoidCallback onUploadPhoto;
  final VoidCallback? onViewPhoto;

  const ProveedorGastoTile({
    super.key,
    required this.gastoId,
    required this.gasto,
    required this.onUploadPhoto,
    this.onViewPhoto,
  });

  @override
  Widget build(BuildContext context) {
    final bool esPendiente = gasto['estado'] == 'pendiente';
    final String? fotoUrl = gasto.containsKey('fotoUrl') ? gasto['fotoUrl'] : null;
    final DateTime fecha = (gasto['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
    final double monto = (gasto['monto'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(
          Icons.description_outlined,
          color: esPendiente ? Colors.redAccent : Colors.greenAccent,
        ),
        title: Text(
          gasto['descripcion'] ?? 'Sin descripción',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        subtitle: Text(
          "${DateFormat('dd/MM').format(fecha)} - Remito: ${gasto['nroRemito'] ?? 'S/N'}",
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "\$${monto.toStringAsFixed(0)}",
              style: TextStyle(
                color: esPendiente ? Colors.redAccent : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                Icons.camera_alt,
                color: fotoUrl != null ? Colors.orangeAccent : Colors.white24,
              ),
              onPressed: onUploadPhoto,
            ),
          ],
        ),
        onTap: fotoUrl != null ? onViewPhoto : null,
      ),
    );
  }
}
