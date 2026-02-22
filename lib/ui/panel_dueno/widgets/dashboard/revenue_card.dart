import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:barapp/services/dashboard/dashboard_metrics_service.dart';
import 'revenue_detail_modal.dart';

/// Tarjeta de ingresos (caja vs banco) del dashboard.
class RevenueCard extends StatelessWidget {
  final List<QueryDocumentSnapshot> salesDocs;
  final bool isDesktop;

  const RevenueCard({
    super.key,
    required this.salesDocs,
    required this.isDesktop,
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
    final efectivoPct =
        totalGeneral == 0 ? 0 : (totalEfectivo / totalGeneral);
    final digitalPct = totalGeneral == 0 ? 0 : (totalDigital / totalGeneral);

    Widget content = Container(
      height: isDesktop ? 180 : null,
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CAJA VS BANCO (HOY)",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Icon(
                Icons.monetization_on_outlined,
                color: Colors.greenAccent.withValues(alpha: 0.8),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              "\$${NumberFormat("#,##0", "es_AR").format(totalGeneral)}",
              style: TextStyle(
                color: Colors.white,
                fontSize: isDesktop ? 34 : 32,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (totalGeneral > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  Expanded(
                    flex: (efectivoPct * 100).round(),
                    child: Container(
                      height: 6,
                      color: Colors.greenAccent,
                    ),
                  ),
                  Expanded(
                    flex: (digitalPct * 100).round(),
                    child: Container(
                      height: 6,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.moped, color: Colors.purpleAccent, size: 12),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  "Envíos: \$${NumberFormat.compact(locale: "es_AR").format(totalEnviosHoy)}",
                  style: TextStyle(
                    color: Colors.purpleAccent.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.money,
                          color: Colors.greenAccent,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            "Efectivo",
                            style: TextStyle(
                              color: Colors.greenAccent.withValues(alpha: 0.8),
                              fontSize: 9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "\$${NumberFormat.compact(locale: "es_AR").format(totalEfectivo)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 30, width: 1, color: Colors.white10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            "Digital",
                            style: TextStyle(
                              color: Colors.blueAccent.withValues(alpha: 0.8),
                              fontSize: 9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.credit_card,
                          color: Colors.blueAccent,
                          size: 12,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        "\$${NumberFormat.compact(locale: "es_AR").format(totalDigital)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => RevenueDetailModal(salesDocs: salesDocs),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}
