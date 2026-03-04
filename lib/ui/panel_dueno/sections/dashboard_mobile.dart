import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:barapp/ui/panel_dueno/layouts/dashboard/dashboard_desktop_layout.dart';
import 'package:barapp/ui/panel_dueno/layouts/dashboard/dashboard_mobile_layout.dart';
import 'package:barapp/ui/panel_dueno/logic/dashboard_logic.dart';
import 'package:barapp/ui/panel_dueno/widgets/dashboard/dashboard_filter_chip.dart';

class DashboardMobile extends StatefulWidget {
  final String placeId;
  final Function(String tabName)? onNavigateToTab;

  const DashboardMobile({
    super.key,
    required this.placeId,
    this.onNavigateToTab,
  });

  @override
  State<DashboardMobile> createState() => _DashboardMobileState();
}

class _DashboardMobileState extends State<DashboardMobile> with DashboardLogic {
  String _filtroActual =
      'TODOS'; // Posibles: TODOS, EFECTIVO, TARJETA, MERCADOPAGO

  // Widget de Botones de Filtro (AGREGAMOS TRANSFERENCIA)
  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          DashboardFilterChip(
            label: 'TODOS',
            icon: Icons.list,
            isSelected: _filtroActual == 'TODOS',
            onTap: () => setState(() => _filtroActual = 'TODOS'),
          ),
          const SizedBox(width: 10),
          DashboardFilterChip(
            label: 'EFECTIVO',
            icon: Icons.money,
            isSelected: _filtroActual == 'EFECTIVO',
            onTap: () => setState(() => _filtroActual = 'EFECTIVO'),
          ),
          const SizedBox(width: 10),
          DashboardFilterChip(
            label: 'TARJETA',
            icon: Icons.credit_card,
            isSelected: _filtroActual == 'TARJETA',
            onTap: () => setState(() => _filtroActual = 'TARJETA'),
          ),
          const SizedBox(width: 10),
          DashboardFilterChip(
            label: 'MP / QR',
            icon: Icons.qr_code,
            isSelected: _filtroActual == 'MERCADOPAGO',
            onTap: () => setState(() => _filtroActual = 'MERCADOPAGO'),
          ),
          const SizedBox(width: 10),
          // 🔥 NUEVO BOTÓN
          DashboardFilterChip(
            label: 'TRANSF.',
            icon: Icons.account_balance,
            isSelected: _filtroActual == 'TRANSFERENCIA',
            onTap: () => setState(() => _filtroActual = 'TRANSFERENCIA'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initDashboardLogic();
  }

  @override
  void dispose() {
    disposeDashboardLogic();
    super.dispose();
  }

  // ===========================================================================
  // 🏗️ BUILDER PRINCIPAL (CORREGIDO)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    if (!isDashboardLogicReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purpleAccent),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: salesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
        }

        final salesDocs = snapshot.data?.docs ?? [];

        return LayoutBuilder(
          builder: (context, constraints) {
            final filterButtons = _buildFilterButtons();
            if (constraints.maxWidth >= 900) {
              return DashboardDesktopLayout(
                placeId: widget.placeId,
                salesDocs: salesDocs,
                filtroActual: _filtroActual,
                startOfDay: startOfDay,
                filterButtons: filterButtons,
                onNavigateToTab: widget.onNavigateToTab,
              );
            } else {
              return DashboardMobileLayout(
                placeId: widget.placeId,
                salesDocs: salesDocs,
                filtroActual: _filtroActual,
                startOfDay: startOfDay,
                filterButtons: filterButtons,
                onNavigateToTab: widget.onNavigateToTab,
              );
            }
          },
        );
      },
    );
  }
}
