import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'historial_caja_screen.dart';
import '../widgets/caja/caja_info_detalle.dart';
import '../logic/caja_logic.dart';
import '../widgets/gastos/modals/retiro_modal.dart';

class ControlCajaScreen extends StatefulWidget {
  final String placeId;
  const ControlCajaScreen({super.key, required this.placeId});

  @override
  State<ControlCajaScreen> createState() => _ControlCajaScreenState();
}

class _ControlCajaScreenState extends State<ControlCajaScreen>
    with CajaLogicMixin {
  final TextEditingController _montoCtrl = TextEditingController();
  final TextEditingController _montoAjusteCtrl = TextEditingController();
  bool _loading = false;

  // 🔥 FIX: Cachear el Future para evitar recreación en cada rebuild
  Future<Map<String, double>>? _totalesFuture;
  String? _lastSesionId; // Para detectar cambio de sesión

  // 🔥 FIX: Cachear el stream de sesión abierta
  late final Stream<QuerySnapshot> _sesionStream;

  @override
  String get placeId => widget.placeId;

  @override
  void initState() {
    super.initState();
    _sesionStream = getSesionAbiertaStream();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _montoAjusteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Gestión de Caja", style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
               Navigator.push(
                 context, 
                 MaterialPageRoute(builder: (_) => HistorialCajaScreen(placeId: widget.placeId))
               );
            }, 
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: "Historial de Cierres",
          ),
        ],
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: _sesionStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return _buildPantallaApertura();
          } else {
            return _buildPantallaCierre(docs.first);
          }
        },
      ),
    );
  }

  // ===========================================================================
  // 🟢 PANTALLA DE APERTURA (Sin cambios, estaba perfecta)
  // ===========================================================================
  Widget _buildPantallaApertura() {
    final user = FirebaseAuth.instance.currentUser;
    final String operador = user?.email?.split('@')[0].toUpperCase() ?? "DESCONOCIDO";
    final String fecha = DateFormat("dd/MM/yyyy").format(DateTime.now());
    final String hora = DateFormat("HH:mm").format(DateTime.now());

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.storefront, size: 60, color: Colors.greenAccent),
            const SizedBox(height: 20),
            
            const Text(
              "INICIAR TURNO",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            
            const SizedBox(height: 30),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  CajaInfoDetalle(icon: Icons.calendar_today, label: "Fecha:", value: fecha),
                  const Divider(color: Colors.white10),
                  CajaInfoDetalle(icon: Icons.access_time, label: "Hora Apertura:", value: hora),
                  const Divider(color: Colors.white10),
                  CajaInfoDetalle(icon: Icons.person_pin, label: "Operador:", value: operador, valueColor: Colors.orangeAccent),
                ],
              ),
            ),

            const SizedBox(height: 30),
            
            const Text(
              "Fondo de Cambio Inicial",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                prefixText: "\$ ",
                prefixStyle: TextStyle(color: Colors.greenAccent, fontSize: 36),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                hintText: "0",
                hintStyle: TextStyle(color: Colors.white12)
              ),
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              onPressed: _loading ? null : () async {
                if (_montoCtrl.text.isEmpty) return;
                
                setState(() => _loading = true);
                double monto = double.tryParse(_montoCtrl.text) ?? 0;
                if (monto < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresá un monto válido")));
                  setState(() => _loading = false);
                  return;
                }
                
                final String responsableEmail = user?.email ?? "Desconocido";
                try {
                  await abrirCaja(monto, responsableEmail);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error al abrir caja: $e"), backgroundColor: Colors.red),
                    );
                  }
                }
                
                if (mounted) {
                  setState(() { _loading = false; _montoCtrl.clear(); });
                }
              },
              child: _loading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login),
                      SizedBox(width: 10),
                      Text("CONFIRMAR APERTURA", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeEstado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        "CAJA ABIERTA / SESIÓN ACTIVA",
        style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  // ===========================================================================
  // 🔴 PANTALLA DE CIERRE (MEJORADA CON UX CLARA)
  // ===========================================================================
  Widget _buildPantallaCierre(QueryDocumentSnapshot sesionDoc) {
    final dataSesion = sesionDoc.data() as Map<String, dynamic>;
    final double saldoInicial = (dataSesion['monto_inicial'] as num?)?.toDouble() ?? 0.0;
    final Timestamp? fechaAperturaTS = dataSesion['fecha_apertura'] as Timestamp?;

    // Si el serverTimestamp todavía no se resolvió, mostrar spinner
    if (fechaAperturaTS == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 🔥 FIX: Solo recrear el Future si cambió la sesión
    if (_totalesFuture == null || _lastSesionId != sesionDoc.id) {
      _lastSesionId = sesionDoc.id;
      _totalesFuture = procesarTotalesCaja(fechaAperturaTS, saldoInicial);
    }

    return FutureBuilder<Map<String, double>>(
      future: _totalesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final totales = snapshot.data!;
        final double ventasTotal = totales['ventasTotal']!;
        final double ventasEfectivoTemp = totales['ventasEfectivo']!;
        final double ventasDigital = totales['ventasDigital']!;
        final double gastosEfectivoTemp = totales['gastosEfectivo']!;
        final double totalCajaFuerte = totales['totalCajaFuerte'] ?? 0.0;
        final double totalEsperadoEnCaja = totales['totalEsperadoEnCaja']!;

        // Usar valores locales directamente (sin mutar state en builder)
        final double ventasEfectivo = ventasEfectivoTemp;
        final double gastosEfectivo = gastosEfectivoTemp;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildBadgeEstado(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Operador: ${dataSesion['usuario_apertura']?.split('@')[0].toUpperCase()}",
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  // Botón de refrescar totales
                  InkWell(
                    onTap: () => setState(() => _totalesFuture = null),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.white38, size: 14),
                          SizedBox(width: 4),
                          Text("Actualizar", style: TextStyle(color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- MONTO INICIAL (CAJA CHICA) - DESTACADO PERO SEPARADO ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.blueAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "CAJA CHICA / MONTO INICIAL",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "\$${NumberFormat("#,##0", "es_AR").format(saldoInicial)}",
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Este monto no forma parte de las ventas del día",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bloque de Ingresos Cash (MEJORADO VISUALMENTE)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "INGRESOS EN EFECTIVO",
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CajaInfoRow(label: "+ Ventas en Efectivo", amount: ventasEfectivo, color: Colors.greenAccent, isBold: true, scale: 1.1),
                    const SizedBox(height: 8),
                    CajaInfoRow(label: "Ventas Digitales (Info)", amount: ventasDigital, color: Colors.white38, scale: 0.85),
                    CajaInfoRow(label: "Total Ventas", amount: ventasTotal, color: Colors.white54, scale: 0.85),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bloque Salidas Cash (MEJORADO VISUALMENTE)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "SALIDAS EN EFECTIVO",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CajaInfoRow(label: "- Gastos / Retiros", amount: gastosEfectivo, color: Colors.redAccent, isBold: true, scale: 1.1),
                    if (totalCajaFuerte > 0) ...[                      
                      const SizedBox(height: 4),
                      CajaInfoRow(label: "- Retiros a Caja Fuerte", amount: totalCajaFuerte, color: Colors.amberAccent, isBold: true, scale: 1.1),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // RESULTADO FINAL ESPERADO (MUY RESALTADO)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.orangeAccent, size: 28),
                        const SizedBox(width: 10),
                        const Text(
                          "SALDO ESPERADO EN CAJA",
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "\$${NumberFormat("#,##0", "es_AR").format(totalEsperadoEnCaja)}",
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Caja Chica (\$${NumberFormat("#,##0", "es_AR").format(saldoInicial)}) + "
                        "Ventas Efectivo (\$${NumberFormat("#,##0", "es_AR").format(ventasEfectivo)}) - "
                        "Gastos/Retiros (\$${NumberFormat("#,##0", "es_AR").format(gastosEfectivo)})",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botones de retiros
              Row(
                children: [
                  // Botón Retiro - Gasto Casual
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF151515),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) => RetiroModal(
                            placeId: widget.placeId,
                            tipoRetiro: 'gasto_casual',
                          ),
                        ).then((_) {
                          if (mounted) setState(() => _totalesFuture = null);
                        });
                      },
                      icon: const Icon(Icons.money_off, color: Colors.redAccent, size: 18),
                      label: const Text(
                        "Gasto Casual",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón Retiro a Caja Fuerte
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF151515),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (ctx) => RetiroModal(
                            placeId: widget.placeId,
                            tipoRetiro: 'caja_fuerte',
                          ),
                        ).then((_) {
                          if (mounted) setState(() => _totalesFuture = null);
                        });
                      },
                      icon: const Icon(Icons.account_balance, color: Colors.amberAccent, size: 18),
                      label: const Text(
                        "A Caja Fuerte",
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.amberAccent, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Campo para ajustar monto inicial al cierre (opcional)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueAccent, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          "Ajuste de Caja Chica (Opcional)",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _montoAjusteCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "Monto final de caja chica",
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        prefixText: "\$ ",
                        prefixStyle: const TextStyle(color: Colors.blueAccent, fontSize: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Si hubo problemas de cambio, ajustá el monto que quedó en caja chica",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Monto real en caja (arqueo)",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _montoCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  prefixText: "\$ ",
                  prefixStyle: TextStyle(color: Colors.orangeAccent, fontSize: 32),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.orangeAccent),
                  ),
                  hintText: "0",
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          if (_montoCtrl.text.isEmpty) return;
                          _confirmarCierre(
                            sesionDoc.id,
                            totalEsperadoEnCaja,
                            ventasEfectivo,
                            gastosEfectivo,
                            totalCajaFuerte,
                          );
                        },
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "CERRAR TURNO",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _confirmarCierre(String sesionId, double esperado, double ventasEfectivo, double gastosEfectivo, double totalCajaFuerte) {
    // Calcular ajuste de caja chica si fue ingresado
    double ajusteCajaChica = 0;
    if (_montoAjusteCtrl.text.trim().isNotEmpty) {
      ajusteCajaChica = double.tryParse(_montoAjusteCtrl.text) ?? 0;
    }

    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("¿Confirmar Cierre?", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Una vez cerrada, se generará el reporte y no podrás editar esta sesión.", style: TextStyle(color: Colors.white70)),
            if (_montoAjusteCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Ajuste de caja chica: \$${NumberFormat("#,##0", "es_AR").format(ajusteCajaChica)}",
                  style: const TextStyle(color: Colors.blueAccent, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _loading = true);
              
              double real = double.tryParse(_montoCtrl.text) ?? 0;
              
              // Si hay ajuste de caja chica, ajustamos el esperado
              // El esperado original es: monto inicial + ventas efectivo - gastos efectivo - retiros caja fuerte
              // Si ajustamos la caja chica, el nuevo esperado usa el monto ajustado
              double esperadoAjustado = esperado;
              if (_montoAjusteCtrl.text.trim().isNotEmpty) {
                final montoAjuste = double.tryParse(_montoAjusteCtrl.text) ?? 0;
                esperadoAjustado = montoAjuste + ventasEfectivo - gastosEfectivo - totalCajaFuerte;
              }
              
              double diferencia = real - esperadoAjustado;

              try {
                await cerrarCaja(sesionId, real, esperadoAjustado);
                if(mounted) {
                  setState(() { 
                    _loading = false; 
                    _montoCtrl.clear(); 
                    _montoAjusteCtrl.clear();
                  });
                  _mostrarResultadoCierre(diferencia);
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _loading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al cerrar caja: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            }, 
            child: const Text("CERRAR TURNO")
          )
        ],
      )
    );
  }

  void _mostrarResultadoCierre(double diferencia) {
    bool perfecto = diferencia.abs() < 10;
    Color color = perfecto ? Colors.green : (diferencia > 0 ? Colors.blue : Colors.red);
    String titulo = perfecto ? "¡CAJA PERFECTA!" : (diferencia > 0 ? "SOBRANTE" : "FALTANTE");
    IconData icono = perfecto ? Icons.check_circle : (diferencia > 0 ? Icons.trending_up : Icons.trending_down);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, color: color, size: 60),
            const SizedBox(height: 20),
            Text(titulo, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "Diferencia: \$${NumberFormat("#,##0", "es_AR").format(diferencia)}", 
              style: const TextStyle(color: Colors.white, fontSize: 18)
            ),
            const SizedBox(height: 20),
            const Text("El turno ha sido cerrado correctamente.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("ENTENDIDO")
          )
        ],
      )
    );
  }
}
