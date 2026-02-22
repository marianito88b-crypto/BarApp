import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:barapp/ui/panel_dueno/advanced_metrics_screen.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/live_stat_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/recent_sales_table.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/reservas_hoy_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/revenue_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/top_products_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/ratings_history_card.dart';
import 'package:barapp/services/dashboard/dashboard_metrics_service.dart';
import 'package:barapp/ui/settings/printer_settings_screen.dart';
import 'package:barapp/ui/panel_dueno/widgets/staff/modals/clock_in_dialog.dart';

/// Layout desktop del dashboard.
class DashboardDesktopLayout extends StatelessWidget {
  final String placeId;
  final List<QueryDocumentSnapshot> salesDocs;
  final String filtroActual;
  final DateTime startOfDay;
  final Widget filterButtons;
  final Function(String tabName)? onNavigateToTab;

  const DashboardDesktopLayout({
    super.key,
    required this.placeId,
    required this.salesDocs,
    required this.filtroActual,
    required this.startOfDay,
    required this.filterButtons,
    this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double tableHeight = (screenHeight * 0.8).clamp(500.0, 1500.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, "Centro de Control"),
          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AdvancedMetricsScreen(placeId: placeId),
                  ),
                ),
                icon: const Icon(Icons.insights),
                label: const Text(
                  "MÉTRICAS AVANZADAS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: () => ClockInDialog.show(context, placeId),
                icon: const Icon(Icons.access_time),
                label: const Text(
                  "FICHAR ASISTENCIA",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: RevenueCard(salesDocs: salesDocs, isDesktop: true),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: LiveStatCard(
                    placeId: placeId,
                    type: 'mesas_ocupadas',
                    isDesktop: true,
                    onNavigateToTab: onNavigateToTab,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ReservasHoyDetailedCard(
                    placeId: placeId,
                    isDesktop: true,
                    onNavigateToTab: onNavigateToTab,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: LiveStatCard(
                    placeId: placeId,
                    type: 'pedidos_web',
                    isDesktop: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ranking de Platos (Hoy)",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TopProductsCard(
                      salesDocs: salesDocs,
                      height: tableHeight * 0.7,
                    ),
                    const SizedBox(height: 24),
                    RatingsHistoryCard(placeId: placeId),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Container(
                  height: tableHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF151515),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Transacciones",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Flexible(child: filterButtons),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),
                      Expanded(
                        child: ClipRect(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: RecentSalesTable(
                              salesDocs: salesDocs,
                              filtro: filtroActual,
                              placeId: placeId,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white10),
                          ),
                          color: Color(0xFF151515),
                        ),
                        child: _buildTotalFooter(salesDocs),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "JORNADA DEL ${DateFormat("EEEE d 'de' MMMM", 'es_ES').format(startOfDay).toUpperCase()}",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(
            Icons.settings_applications,
            color: Colors.orangeAccent,
            size: 30,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrinterSettingsScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalFooter(List<QueryDocumentSnapshot> docs) {
    final metrics = DashboardMetricsService.calculate(
      docs: docs,
      filtro: filtroActual,
    );
    final total = metrics.total;

    Color colorTotal;
    IconData iconTotal;
    switch (filtroActual) {
      case 'EFECTIVO':
        colorTotal = Colors.greenAccent;
        iconTotal = Icons.money;
        break;
      case 'TARJETA':
        colorTotal = Colors.blueAccent;
        iconTotal = Icons.credit_card;
        break;
      case 'MERCADOPAGO':
        colorTotal = Colors.lightBlueAccent;
        iconTotal = Icons.qr_code;
        break;
      case 'TRANSFERENCIA':
        colorTotal = Colors.purpleAccent;
        iconTotal = Icons.account_balance;
        break;
      default:
        colorTotal = Colors.white;
        iconTotal = Icons.attach_money;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
        color: Color(0xFF151515),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "TOTAL FILTRADO ($filtroActual)",
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(iconTotal, color: colorTotal, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    "Sumatoria:",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            "\$${NumberFormat("#,##0", "es_AR").format(total)}",
            style: TextStyle(
              color: colorTotal,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
