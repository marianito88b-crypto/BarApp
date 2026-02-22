import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:barapp/ui/panel_dueno/advanced_metrics_screen.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/live_stat_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/recent_sales_list.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/reservas_hoy_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/revenue_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/top_products_card.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/ratings_history_card.dart';
import 'package:barapp/services/dashboard/dashboard_metrics_service.dart';
import 'package:barapp/ui/settings/printer_settings_screen.dart';
import 'package:barapp/ui/panel_dueno/widgets/staff/modals/clock_in_dialog.dart';

/// Layout móvil del dashboard. El footer total usa Stack para quedar por encima
/// del contenido scrolleable, sin interferir con la barra de navegación del dueño
/// (que tiene padding bottom en el padre).
class DashboardMobileLayout extends StatelessWidget {
  final String placeId;
  final List<QueryDocumentSnapshot> salesDocs;
  final String filtroActual;
  final DateTime startOfDay;
  final Widget filterButtons;
  final Function(String tabName)? onNavigateToTab;

  const DashboardMobileLayout({
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Contenido scrolleable (con padding inferior para el footer + barra del dueño)
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100, // Footer (~60) + margen para nav bar del dueño (~40)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, "Tablero Móvil"),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: RevenueCard(salesDocs: salesDocs, isDesktop: false),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.orangeAccent.withValues(alpha: 0.05),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdvancedMetricsScreen(placeId: placeId),
                      ),
                    ),
                    icon: const Icon(Icons.bar_chart, size: 20),
                    label: const Text(
                      "VER REPORTE MENSUAL",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LiveStatCard(
                        placeId: placeId,
                        type: 'mesas_ocupadas',
                        onNavigateToTab: onNavigateToTab,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ReservasHoyDetailedCard(
                        placeId: placeId,
                        onNavigateToTab: onNavigateToTab,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LiveStatCard(
                        placeId: placeId,
                        type: 'pedidos_web',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildClockInButton(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Top Productos Hoy",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TopProductsCard(salesDocs: salesDocs),
                const SizedBox(height: 24),
                RatingsHistoryCard(placeId: placeId),
                const SizedBox(height: 24),
                const Text(
                  "Últimos Cobros (Auditoría)",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                filterButtons,
                const SizedBox(height: 12),
                RecentSalesList(
                  salesDocs: salesDocs,
                  filtro: filtroActual,
                  placeId: placeId,
                ),
              ],
            ),
          ),
          // 2. Footer fijo en la parte inferior (por encima del scroll, sin tapar nav del dueño)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildTotalFooter(salesDocs),
            ),
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
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
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

  /// Botón de acceso rápido para fichar asistencia
  Widget _buildClockInButton(BuildContext context) {
    return InkWell(
      onTap: () => ClockInDialog.show(context, placeId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.orangeAccent,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Fichar",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Asistencia",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
