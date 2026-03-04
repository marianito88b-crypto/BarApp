import 'package:flutter/material.dart';
import '../widgets/pos/pos_utils.dart';
import '../logic/toma_pedido_logic.dart';
import '../layouts/pos/toma_pedido_mobile_layout.dart';
import '../layouts/pos/toma_pedido_desktop_layout.dart';

class TomaPedidoScreen extends StatefulWidget {
  final String placeId;
  final String mesaId;
  final String mesaNombre;

  const TomaPedidoScreen({
    super.key,
    required this.placeId,
    required this.mesaId,
    required this.mesaNombre,
  });

  @override
  State<TomaPedidoScreen> createState() => _TomaPedidoScreenState();
}

class _TomaPedidoScreenState extends State<TomaPedidoScreen>
    with TomaPedidoLogicMixin {
  // Estado del Pedido
  List<Map<String, dynamic>> _pedidoNuevo = [];
  List<Map<String, dynamic>> _pedidoHistorico = [];
  String _busqueda = '';
  bool _guardando = false;
  double _totalHistorico = 0.0;

  // Getters requeridos por el Mixin
  @override
  String get placeId => widget.placeId;

  @override
  String get mesaId => widget.mesaId;

  @override
  String get mesaNombre => widget.mesaNombre;

  // Getters y setters para el estado (requeridos por el Mixin)
  @override
  List<Map<String, dynamic>> get pedidoNuevo => _pedidoNuevo;

  @override
  List<Map<String, dynamic>> get pedidoHistorico => _pedidoHistorico;

  @override
  bool get guardando => _guardando;

  @override
  double get totalHistorico => _totalHistorico;

  @override
  void setPedidoNuevo(List<Map<String, dynamic>> value) {
    _pedidoNuevo = value;
  }

  @override
  void setPedidoHistorico(List<Map<String, dynamic>> value) {
    _pedidoHistorico = value;
  }

  @override
  void setGuardando(bool value) {
    _guardando = value;
  }

  @override
  void setTotalHistorico(double value) {
    _totalHistorico = value;
  }

  double get _totalNuevo => _pedidoNuevo.fold(
      0,
      (acc, item) =>
          acc +
          (PosUtils.safeDouble(item['precio']) *
              PosUtils.safeInt(item['cantidad'])));
  double get _totalGeneral => _totalHistorico + _totalNuevo;

  @override
  void initState() {
    super.initState();
    initTomaPedidoLogic();
  }

  @override
  void dispose() {
    disposeTomaPedidoLogic();
    super.dispose();
  }

  // ===========================================================================
  // ⚙️ LÓGICA DE NEGOCIO (UI LOCAL)
  // ===========================================================================

  void _agregarProducto(Map<String, dynamic> producto) {
    setState(() {
      final index = _pedidoNuevo.indexWhere((p) => p['productoId'] == producto['id']);
      
      if (index != -1) {
        _pedidoNuevo[index]['cantidad'] =
            PosUtils.safeInt(_pedidoNuevo[index]['cantidad']) + 1;
      } else {
        // 🔥 BLINDAJE: Guardamos datos limpios desde el principio
        _pedidoNuevo.add({
          'productoId': producto['id'],
          'nombre': producto['nombre'] ?? 'Sin Nombre',
          'precio': PosUtils.safeDouble(producto['precio']),
          'cantidad': 1,
          'controlaStock': producto['controlaStock'] == true, // Aseguramos bool
        });
      }
    });
  }

  void _restarProducto(int index) {
    setState(() {
      int current = PosUtils.safeInt(_pedidoNuevo[index]['cantidad']);
      if (current > 1) {
        _pedidoNuevo[index]['cantidad'] = current - 1;
      } else {
        _pedidoNuevo.removeAt(index);
      }
    });
  }


  // ===========================================================================
  // 🖥️ UI BUILDERS
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return TomaPedidoDesktopLayout(
            placeId: placeId,
            mesaId: mesaId,
            mesaNombre: mesaNombre,
            pedidoHistorico: _pedidoHistorico,
            pedidoNuevo: _pedidoNuevo,
            totalGeneral: _totalGeneral,
            guardando: _guardando,
            busqueda: _busqueda,
            menuStream: menuStream,
            mesaStream: mesaStream,
            onBusquedaChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
            onAgregarProducto: _agregarProducto,
            onRestarProducto: _restarProducto,
            onEliminarItemHistorico: eliminarItemHistorico,
            onMarcharPedido: marcharPedido,
            onImprimirComandaCocina: imprimirComandaCocina,
            onImprimirCuentaCliente: imprimirCuentaCliente,
            onCobrarCuenta: cobrarCuenta,
            onLiberarMesa: liberarMesa,
          );
        } else {
          return TomaPedidoMobileLayout(
            placeId: placeId,
            mesaId: mesaId,
            mesaNombre: mesaNombre,
            pedidoHistorico: _pedidoHistorico,
            pedidoNuevo: _pedidoNuevo,
            totalGeneral: _totalGeneral,
            guardando: _guardando,
            busqueda: _busqueda,
            menuStream: menuStream,
            mesaStream: mesaStream,
            onBusquedaChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
            onAgregarProducto: _agregarProducto,
            onRestarProducto: _restarProducto,
            onEliminarItemHistorico: eliminarItemHistorico,
            onMarcharPedido: marcharPedido,
            onImprimirComandaCocina: imprimirComandaCocina,
            onImprimirCuentaCliente: imprimirCuentaCliente,
            onCobrarCuenta: cobrarCuenta,
            onLiberarMesa: liberarMesa,
          );
        }
      },
    );
  }
}