import 'package:flutter/material.dart';
import 'package:barapp/services/finanzas_service.dart';
import '../widgets/gastos/balance_general_card.dart';
import '../widgets/gastos/gastos_bar_chart.dart';
import '../widgets/gastos/gastos_pie_chart_view.dart';
import '../widgets/gastos/gastos_movimientos_list.dart';
import '../widgets/gastos/proveedores_list.dart';
import '../widgets/gastos/modals/add_gasto_modal.dart';
import '../widgets/gastos/modals/add_proveedor_modal.dart';
import '../widgets/gastos/modals/retiro_modal.dart';
import '../logic/gastos_logic.dart';

class GastosMobile extends StatefulWidget {
  final String placeId;
  const GastosMobile({super.key, required this.placeId});

  @override
  State<GastosMobile> createState() => _GastosMobileState();
}

class _GastosMobileState extends State<GastosMobile>
    with SingleTickerProviderStateMixin, GastosLogicMixin {
  late TabController _tabController;

  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: TabBar(
        controller: _tabController,
        indicatorColor: Colors.orangeAccent,
        labelColor: Colors.orangeAccent,
        unselectedLabelColor: Colors.white54,
        tabs: const [
          Tab(icon: Icon(Icons.money_off), text: "Gastos y Remitos"),
          Tab(icon: Icon(Icons.local_shipping), text: "Proveedores"),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildGastosView(), _buildProveedoresView()],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "fab_gastos_mobile",
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddGastoModal();
          } else {
            _showAddProveedorModal();
          }
        },
      ),
    );
  }

  Widget _buildGastosView() {
    // Detectamos el ancho de la pantalla
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600; // Si es menos de 600px, es mobile

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          BalanceGeneralCard(placeId: widget.placeId),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Wrap(
              spacing: 10, // Espacio horizontal entre gráficos
              runSpacing: 10, // Espacio vertical si se van abajo
              children: [
                // Gráfico de Barras
                SizedBox(
                  width: isMobile ? screenWidth - 30 : (screenWidth / 2) - 25,
                  child: _buildMiniCard(
                    title: "RENDIMIENTO SEMANAL",
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FinanzasService(placeId: widget.placeId)
                          .getComparativaSemanal(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox(height: 100);
                        }
                        return GastosBarChart(datos: snapshot.data!);
                      },
                    ),
                  ),
                ),

                // Gráfico de Torta
                SizedBox(
                  width: isMobile ? screenWidth - 30 : (screenWidth / 2) - 25,
                  child: _buildMiniCard(
                    title: "DISTRIBUCIÓN POR RUBRO",
                    child: GastosPieChartView(placeId: widget.placeId),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          
          // Botón de retiro - gasto casual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showRetiroModal,
                icon: const Icon(Icons.money_off, color: Colors.redAccent),
                label: const Text(
                  "Gasto Casual",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          
          _buildListaMovimientosHeader(),
          GastosMovimientosList(placeId: widget.placeId),
        ],
      ),
    );
  }

  // Helper para crear tarjetitas chicas para los gráficos
  Widget _buildMiniCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }


  Widget _buildProveedoresView() {
    return ProveedoresList(placeId: widget.placeId);
  }

  void _showAddGastoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddGastoModal(placeId: widget.placeId),
    );
  }

  void _showAddProveedorModal() {
    showDialog(
      context: context,
      builder: (context) => AddProveedorModal(placeId: widget.placeId),
    );
  }

  void _showRetiroModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RetiroModal(placeId: widget.placeId),
    );
  }

  // --- 1. EL HEADER DE LA LISTA ---
  Widget _buildListaMovimientosHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "ÚLTIMOS MOVIMIENTOS",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

}

