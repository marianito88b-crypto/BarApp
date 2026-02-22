import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:barapp/services/dashboard/dashboard_metrics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modal detallado con información ampliada de ingresos y recaudación.
class RevenueDetailModal extends StatelessWidget {
  final List<QueryDocumentSnapshot> salesDocs;

  const RevenueDetailModal({
    super.key,
    required this.salesDocs,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = DashboardMetricsService.calculate(
      docs: salesDocs,
      filtro: 'TODOS',
    );

    final totalGeneral = metrics.total;
    final totalEfectivo = metrics.efectivo;
    final totalDigital = metrics.digital;
    final totalEnviosHoy = metrics.envios;
    final totalLocal = metrics.local;
    final totalOnline = metrics.online;

    // Calcular porcentajes
    final efectivoPct = totalGeneral == 0 ? 0 : (totalEfectivo / totalGeneral * 100);
    final digitalPct = totalGeneral == 0 ? 0 : (totalDigital / totalGeneral * 100);
    final localPct = totalGeneral == 0 ? 0 : (totalLocal / totalGeneral * 100);
    final onlinePct = totalGeneral == 0 ? 0 : (totalOnline / totalGeneral * 100);

    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.monetization_on,
                          color: Colors.greenAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "DETALLE DE RECAUDACIÓN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              // Total General
              _DetailSection(
                title: "TOTAL RECAUDADO HOY",
                amount: totalGeneral,
                color: Colors.white,
                fontSize: 32,
                showIcon: false,
              ),
              const SizedBox(height: 32),

              // Efectivo Caja Detallado
              _DetailSection(
                title: "EFECTIVO (CAJA)",
                amount: totalEfectivo,
                color: Colors.greenAccent,
                fontSize: 24,
                percentage: efectivoPct.toDouble(),
                showIcon: true,
                icon: Icons.money,
              ),
              const SizedBox(height: 20),

              // Digital/Bancos Detallado
              _DetailSection(
                title: "DIGITAL / BANCOS",
                amount: totalDigital,
                color: Colors.blueAccent,
                fontSize: 24,
                percentage: digitalPct.toDouble(),
                showIcon: true,
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white10),
              const SizedBox(height: 24),

              // Total Envíos
              _DetailSection(
                title: "TOTAL ENVÍOS HOY",
                amount: totalEnviosHoy,
                color: Colors.purpleAccent,
                fontSize: 22,
                showIcon: true,
                icon: Icons.moped,
              ),
              const SizedBox(height: 32),

              // Origen: Local vs Online
              Row(
                children: [
                  Expanded(
                    child: _DetailSection(
                      title: "VENTAS LOCAL",
                      amount: totalLocal,
                      color: Colors.orangeAccent,
                      fontSize: 20,
                      percentage: localPct.toDouble(),
                      showIcon: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _DetailSection(
                      title: "VENTAS ONLINE",
                      amount: totalOnline,
                      color: Colors.cyanAccent,
                      fontSize: 20,
                      percentage: onlinePct.toDouble(),
                      showIcon: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Barra de progreso visual
              if (totalGeneral > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (efectivoPct).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.greenAccent,
                                  Colors.greenAccent.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: (digitalPct).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blueAccent,
                                  Colors.blueAccent.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(
                      color: Colors.greenAccent,
                      label: "Efectivo ${efectivoPct.toStringAsFixed(1)}%",
                    ),
                    _LegendItem(
                      color: Colors.blueAccent,
                      label: "Digital ${digitalPct.toStringAsFixed(1)}%",
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final double fontSize;
  final double? percentage;
  final bool showIcon;
  final IconData? icon;

  const _DetailSection({
    required this.title,
    required this.amount,
    required this.color,
    required this.fontSize,
    this.percentage,
    this.showIcon = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showIcon && icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (percentage != null) ...[
                const Spacer(),
                Text(
                  "${percentage!.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: color.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "\$${NumberFormat("#,##0.00", "es_AR").format(amount)}",
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
