import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barapp/services/coupons_service.dart';
import 'widgets/checkout/summary_card.dart';
import 'widgets/checkout/option_card.dart';
import 'widgets/checkout/bank_data_card.dart';
import 'logic/checkout_logic.dart';

class ClientCheckoutScreen extends StatefulWidget {
  final String placeId;
  final Map<String, Map<String, dynamic>> cart;

  const ClientCheckoutScreen({
    super.key,
    required this.placeId,
    required this.cart,
  });

  @override
  State<ClientCheckoutScreen> createState() => _ClientCheckoutScreenState();
}

class _ClientCheckoutScreenState extends State<ClientCheckoutScreen>
    with CheckoutLogicMixin {
  // Estado local
  bool _userWantsDelivery = false;
  String _userPaymentSelection = 'efectivo';

  // Controladores
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _discountCodeCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isApplyingDiscount = false;
  String? _appliedDiscountCode;
  String? _cuponId;
  double _discountAmount = 0.0;
  double? _discountPorcentaje;
  bool _isBarPointsCupon = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _phoneCtrl.dispose();
    _discountCodeCtrl.dispose();
    super.dispose();
  }

  // Total
  double get _subtotal {
    double t = 0;
    widget.cart.forEach((key, value) {
      t += (value['precio'] * value['cantidad']);
    });
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('places')
                .doc(widget.placeId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              backgroundColor: Color(0xFF121212),
              body: Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            );
          }

          final placeData =
              snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Datos del Local
          final String placeName = placeData['nombre'] ?? 'Restaurante';
          final String placeWhatsapp = placeData['whatsapp'] ?? '';

          // Datos Bancarios
          final String aliasCbu = placeData['alias'] ?? '';
          final String cbu = placeData['cbu'] ?? '';
          final String banco = placeData['banco'] ?? '';

          final bool aceptaPedidos = placeData['aceptaPedidos'] ?? true;
          final bool deliveryDisponible =
              placeData['deliveryDisponible'] ?? false;
          final bool aceptaEfectivo = placeData['aceptaEfectivo'] ?? true;

          // PANTALLA CERRADO
          if (!aceptaPedidos) return _buildClosedScreen();

          // LÓGICA DE NEGOCIO (Sanitización)
          final bool isDeliveryEffective =
              deliveryDisponible && _userWantsDelivery;

          // Si no acepta efectivo, forzamos transferencia
          final String paymentMethodEffective =
              aceptaEfectivo ? _userPaymentSelection : 'transferencia';

          return FutureBuilder<double>(
            future:
                isDeliveryEffective
                    ? obtenerDistanciaEnKm(placeData)
                    : Future.value(0.0),
            builder: (context, snapshotDistancia) {
              // Mientras calcula, usamos 0 o un spinner (o el costo base por defecto)
              final double distanciaKm = snapshotDistancia.data ?? 0.0;

              // Aplicamos la fórmula de costo
              final double costoEnvioCalculado =
                  isDeliveryEffective
                      ? calcularCostoEnvio(
                          distanciaKm: distanciaKm,
                          configEnvio: placeData,
                        )
                      : 0.0;

              // Calcular descuento si hay código aplicado
              final double descuento = _discountAmount;
              final double totalFinal = (_subtotal - descuento) + costoEnvioCalculado;

              return Scaffold(
                backgroundColor: const Color(0xFF121212),
                appBar: AppBar(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: const Text(
                    "Confirmar Pedido",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  iconTheme: const IconThemeData(color: Colors.white),
                  elevation: 0,
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. RESUMEN
                      _buildSectionTitle("Resumen de pago"),
                      CheckoutSummaryCard(
                        subtotal: _subtotal,
                        discountAmount: _discountAmount > 0 ? _discountAmount : null,
                        discountPorcentaje: _discountPorcentaje,
                        isBarPointsCupon: _isBarPointsCupon,
                        shippingCost: isDeliveryEffective ? costoEnvioCalculado : null,
                        total: totalFinal,
                      ),
                      const SizedBox(height: 24),

                      // CÓDIGO DE DESCUENTO (BarPoints + cupones globales)
                      _buildSectionTitle("Código de Descuento"),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _discountCodeCtrl,
                              style: const TextStyle(color: Colors.white),
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 50,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9\s]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                hintText: "Ej: BIENVENIDA o código BarPoints",
                                filled: true,
                                fillColor: const Color(0xFF1E1E1E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                counterText: '',
                                prefixIcon: const Icon(
                                  Icons.local_offer,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: (_isLoading || _isApplyingDiscount)
                                ? null
                                : () => _aplicarDescuento(placeData),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Aplicar",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (_appliedDiscountCode != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Código '$_appliedDiscountCode' aplicado",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _appliedDiscountCode = null;
                                    _discountAmount = 0.0;
                                    _discountPorcentaje = null;
                                    _isBarPointsCupon = false;
                                    _discountCodeCtrl.clear();
                                  });
                                },
                                child: const Text(
                                  "Quitar",
                                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),

                      // 2. ENTREGA
                      _buildSectionTitle("¿Cómo lo recibís?"),
                      Row(
                        children: [
                          Expanded(
                            child: DeliveryOptionCard(
                              label: "Retiro en Local",
                              icon: Icons.storefront,
                              isSelected: !isDeliveryEffective,
                              onTap: () => setState(() => _userWantsDelivery = false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (deliveryDisponible)
                            Expanded(
                              child: DeliveryOptionCard(
                                label: "Delivery",
                                icon: Icons.delivery_dining,
                                isSelected: isDeliveryEffective,
                                onTap: () => setState(() => _userWantsDelivery = true),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),

                      if (isDeliveryEffective) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _addressCtrl,
                          style: const TextStyle(color: Colors.white),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            labelText: "Dirección exacta",
                            hintText: "Ej: Av. San Martín 1450, Piso 2",
                            helperText: "Calle y Altura obligatorios",
                            helperStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Colors.orangeAccent,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Tu Teléfono (Para el repartidor)",
                          hintText: "Ej: 9 362 4123456",
                          helperText: "El código de país (54) se agrega automáticamente",
                          helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                          prefixText: "54 ",
                          prefixStyle: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.greenAccent,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. PAGO
                      _buildSectionTitle("Método de Pago"),
                      Row(
                        children: [
                          if (aceptaEfectivo) ...[
                            Expanded(
                              child: DeliveryOptionCard(
                                label: "Efectivo",
                                icon: Icons.payments,
                                isSelected: paymentMethodEffective == 'efectivo',
                                onTap: () => setState(() => _userPaymentSelection = 'efectivo'),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: DeliveryOptionCard(
                              label: "Transferencia",
                              icon: Icons.account_balance,
                              isSelected: paymentMethodEffective == 'transferencia',
                              onTap: () => setState(() => _userPaymentSelection = 'transferencia'),
                            ),
                          ),
                        ],
                      ),

                      // Vista previa datos bancarios
                      if (paymentMethodEffective == 'transferencia') ...[
                        const SizedBox(height: 16),
                        BankDataCard(
                          alias: aliasCbu.isNotEmpty ? aliasCbu : null,
                          cbu: cbu.isNotEmpty ? cbu : null,
                          banco: banco.isNotEmpty ? banco : null,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // 4. NOTAS
                      _buildSectionTitle("Notas para la cocina"),
                      TextField(
                        controller: _notesCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: "Sin cebolla, mayonesa aparte...",
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 5. BOTÓN CONFIRMAR
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  // Validaciones
                                  if (isDeliveryEffective) {
                                    final address = _addressCtrl.text.trim();
                                    if (address.length < 6) {
                                      _mostrarAlertaError(
                                          "La dirección es muy corta. Ej: San Martín 1200.");
                                      return;
                                    }
                                    bool tieneNumeros =
                                        RegExp(r'[0-9]').hasMatch(address);
                                    if (!tieneNumeros) {
                                      _mostrarAlertaError(
                                          "Falta la altura (número de casa/edificio).");
                                      return;
                                    }
                                    if (paymentMethodEffective == 'efectivo') {
                                      bool confirmado =
                                          await _mostrarDialogoConfirmacion(
                                              address);
                                      if (!confirmado) return;
                                    }
                                  }

                                  // Validar teléfono antes de enviar
                                  final phoneText = _phoneCtrl.text.trim();
                                  if (phoneText.isEmpty) {
                                    _mostrarAlertaError(
                                        "El teléfono es obligatorio para contactarte.");
                                    return;
                                  }

                                  // Validación básica: debe tener al menos algunos dígitos
                                  final phoneDigitsOnly = phoneText.replaceAll(RegExp(r'[^\d]'), '');
                                  if (phoneDigitsOnly.length < 8) {
                                    _mostrarAlertaError(
                                        "El teléfono debe tener al menos 8 dígitos. Ej: 9 362 4123456");
                                    return;
                                  }

                                  setState(() => _isLoading = true);

                                  final orderId = await submitOrder(
                                    placeId: widget.placeId,
                                    cart: widget.cart,
                                    placeWhatsapp: placeWhatsapp,
                                    total: totalFinal,
                                    placeName: placeName,
                                    isDelivery: isDeliveryEffective,
                                    paymentMethod: paymentMethodEffective,
                                    bankData: {
                                      'alias': aliasCbu,
                                      'cbu': cbu,
                                      'banco': banco,
                                    },
                                    address: isDeliveryEffective
                                        ? _addressCtrl.text.trim()
                                        : '',
                                    phone: phoneText,
                                    notes: _notesCtrl.text.trim(),
                                    subtotal: _subtotal,
                                    shippingCost: costoEnvioCalculado,
                                    discountCode: _appliedDiscountCode,
                                    discountAmount: _discountAmount > 0 ? _discountAmount : null,
                                    discountPorcentaje: _discountPorcentaje,
                                    origenBarpoints: _isBarPointsCupon,
                                    cuponId: _cuponId,
                                  );

                                  // Registrar uso del cupón si se aplicó uno
                                  if (_appliedDiscountCode != null && orderId != null) {
                                    try {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user != null) {
                                        await CouponsService.registrarUsoCupon(
                                          userId: user.uid,
                                          codigo: _appliedDiscountCode!,
                                          orderId: orderId,
                                          placeId: widget.placeId,
                                          descuentoAplicado: _discountAmount,
                                        );
                                        // Marcar cupón como usado en mis_cupones
                                        if (_cuponId != null) {
                                          await CouponsService.marcarCuponComoUsado(
                                            userId: user.uid,
                                            cuponId: _cuponId!,
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('⚠️ Error registrando uso de cupón: $e');
                                      // No bloqueamos el flujo si falla el registro
                                    }
                                  }

                                  if (mounted) {
                                    setState(() => _isLoading = false);
                                  }
                                },
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : const Text(
                                    "CONFIRMAR PEDIDO",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              );
            },
          );
          // Aquí termina el StreamBuilder
        },
      ),
    );
  }

  // --- HELPERS Y UI ---

  Widget _buildClosedScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock,
                size: 80,
                color: Colors.redAccent.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 20),
              const Text(
                "Local Cerrado",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Lo sentimos, en este momento no estamos tomando pedidos por la App.",
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Volver atrás"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Aplica un código de descuento al pedido (BarPoints o cupones globales)
  Future<void> _aplicarDescuento(Map<String, dynamic> placeData) async {
    final codigoNorm = CouponsService.normalizarCodigo(_discountCodeCtrl.text);

    if (codigoNorm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ingresá un código de descuento o BarPoints"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Obtener usuario actual
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes iniciar sesión para usar códigos de descuento"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isApplyingDiscount = true);

    try {
      // Validar código: checkout siempre es pedido online (Delivery o Retiro)
      final resultado = await CouponsService.validarYCodigoCupon(
        userId: user.uid,
        codigo: codigoNorm,
        placeId: widget.placeId,
        placeData: placeData,
        isPedidoOnline: true, // Solo Delivery/Retiro desde esta pantalla
      );

      if (!mounted) return;
      if (resultado['valido'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['mensaje'] as String),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Código válido, aplicar descuento (guardamos código normalizado)
      final descuentoPorcentaje = (resultado['descuentoPorcentaje'] as num).toDouble();
      final descuento = _subtotal * (descuentoPorcentaje / 100);

      setState(() {
        _appliedDiscountCode = codigoNorm;
        _discountAmount = descuento;
        _discountPorcentaje = descuentoPorcentaje;
        _isBarPointsCupon = resultado['origenBarpoints'] == true;
        _cuponId = resultado['cuponId'] as String?;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Código aplicado: ${descuentoPorcentaje.toInt()}% de descuento (-\$${descuento.toStringAsFixed(0)})"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos validar el código. Verificá tu conexión e intentá de nuevo.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isApplyingDiscount = false);
      }
    }
  }


  void _mostrarAlertaError(String mensaje) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 10),
                Text(
                  "Dirección incompleta",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              mensaje,
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Corregir",
                  style: TextStyle(color: Colors.orangeAccent),
                ),
              ),
            ],
          ),
    );
  }

  Future<bool> _mostrarDialogoConfirmacion(String direccion) async {
    return await showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E1E1E),
                title: const Text(
                  "Confirmar Dirección",
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "El cadete irá a:",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        direccion,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "¿Es correcta y completa (Piso/Depto)?",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      "Revisar",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Sí, es correcta"),
                  ),
                ],
              ),
        ) ??
        false;
  }
}

