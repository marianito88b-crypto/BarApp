import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'ticket_utils.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  /// Solo inicializar BlueThermalPrinter en Android (no soporta iOS correctamente)
  BlueThermalPrinter? get bluetooth {
    if (kIsWeb) return null;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return BlueThermalPrinter.instance;
    }
    return null;
  }

  /// Verifica si estamos en una plataforma que usa Bluetooth (Android)
  bool get _usaBluetooth =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  // Definimos el formato de 58mm manualmente para máxima compatibilidad
  final PdfPageFormat format58mm = const PdfPageFormat(
    58 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 2 * PdfPageFormat.mm,
  );

  // ===============================================================
  // 1. IMPRIMIR COMANDA (COCINA)
  // ===============================================================
  Future<void> printComanda(Map<String, dynamic> pedido) async {
    if (_usaBluetooth) {
      await _printComandaBluetooth(pedido);
    } else {
      // Web y iOS usan impresión por PDF/AirPrint
      await _printWebUsb(pedido, esTicketCliente: false);
    }
  }

  // ===============================================================
  // 2. IMPRIMIR TICKET (CLIENTE)
  // ===============================================================
  Future<void> printTicket(Map<String, dynamic> datosTicket) async {
    if (_usaBluetooth) {
      await _printTicketBluetooth(datosTicket);
    } else {
      // Web y iOS usan impresión por PDF/AirPrint
      await _printWebUsb(datosTicket, esTicketCliente: true);
    }
  }

  // ---------------------------------------------------------------
  // 💻 ESTRATEGIA WEB (USB / DRIVER)
  // ---------------------------------------------------------------
  Future<void> _printWebUsb(Map<String, dynamic> data, {required bool esTicketCliente}) async {
    try {
      Uint8List pdfBytes;
      
      // Identificar tipo de ticket basándose en los campos del documento
      final String? tipoTicket = data['tipoTicket']?.toString();
      final String? origen = data['origen']?.toString();
      
      if (tipoTicket == 'RESERVA') {
        pdfBytes = await TicketUtils.generatePdfReserva(data);
      } 
      // Si viene de la App/Delivery y es para el cliente (reimpresión o nueva)
      else if ((origen == 'app' || origen == 'delivery') && esTicketCliente) {
        pdfBytes = await TicketUtils.generatePdfPedidoWeb(data);
      } 
      // Si es ticket cliente de mesa (tiene campo 'mesa' y no es app/delivery)
      else if (esTicketCliente && (data['mesa'] != null || data['mesaNombre'] != null)) {
        pdfBytes = await TicketUtils.generatePdfCuenta(data);
      } 
      // Si es ticket cliente pero no tiene mesa identificada, intentar como cuenta
      else if (esTicketCliente) {
        pdfBytes = await TicketUtils.generatePdfCuenta(data);
      } 
      else {
        // Comanda de cocina (Recuerda actualizar TicketUtils también si usas web)
        pdfBytes = await TicketUtils.generatePdfComanda(data);
      }

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'BarApp_Print',
        format: format58mm,
        dynamicLayout: false,
      );
    } catch (e) {
      debugPrint("🔥 ERROR WEB PRINT: $e");
      rethrow;
    }
  }

  // ---------------------------------------------------------------
  // 📱 APP: BLUETOOTH (COCINA Y TICKET)
  // ---------------------------------------------------------------
  Future<void> _printComandaBluetooth(Map<String, dynamic> pedido) async {
    final bt = bluetooth;
    if (bt == null) return;
    if (!(await bt.isConnected ?? false)) return;
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      // ENCABEZADO
      bytes += generator.text('NUEVO PEDIDO', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
      
      // MESA O MÉTODO DE ENTREGA
      String mesa = pedido['mesaNombre'] ?? "S/M";
      bytes += generator.text('Mesa: $mesa', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
      
      bytes += generator.hr();

      // 🔥 SECCIÓN DE NOTAS (NUEVO)
      if (pedido['notas'] != null && pedido['notas'].toString().trim().isNotEmpty) {
        bytes += generator.feed(1);
        // "ATENCIÓN" en invertido (Negro con letras blancas)
        bytes += generator.text(
          '!!! LEER NOTA !!!', 
          styles: const PosStyles(
            align: PosAlign.center, 
            bold: true, 
            reverse: true // Invertido para resaltar
          )
        );
        // La nota en sí, GIGANTE
        bytes += generator.text(
          pedido['notas'].toString().toUpperCase(), 
          styles: const PosStyles(
            align: PosAlign.center, 
            bold: true, 
            height: PosTextSize.size2, 
            width: PosTextSize.size2 // Doble tamaño
          )
        );
        bytes += generator.feed(1);
        bytes += generator.hr();
      }
      
      // ITEMS
      final items = (pedido['items'] as List<dynamic>?) ?? [];
      for (var item in items) {
        bytes += generator.row([
          PosColumn(text: '${item['cantidad']}x', width: 2, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
          PosColumn(text: item['nombre'], width: 10, styles: const PosStyles(bold: true, height: PosTextSize.size2)),
        ]);
        
        // Si el item individual tiene nota (opcional, por si acaso)
        if (item['nota'] != null && item['nota'].toString().isNotEmpty) {
          // NOTA: No usar emoji aquí — las impresoras térmicas no soportan Unicode.
          bytes += generator.text('  (!! ${item['nota']})', styles: const PosStyles(bold: true));
        }

        bytes += generator.feed(1);
      }

      bytes += generator.feed(2);
      bytes += generator.cut();
      // Leer cantidad de copias de la preferencia (max 3 para no bloquear la cola)
      final prefsComanda = await SharedPreferences.getInstance();
      final int copiesComanda = (prefsComanda.getInt('cantidadCopias') ?? 1).clamp(1, 3);
      final Uint8List bytesComanda = Uint8List.fromList(bytes);
      for (int i = 0; i < copiesComanda; i++) {
        await bt.writeBytes(bytesComanda);
      }
    } catch (e) {
      debugPrint("Error Bluetooth Comanda: $e");
      rethrow;
    }
  }

  Future<void> _printTicketBluetooth(Map<String, dynamic> datos) async {
    final bt = bluetooth;
    if (bt == null) return;
    if (!(await bt.isConnected ?? false)) return;
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      final items = (datos['items'] as List<dynamic>?) ?? [];
      final total = (datos['total'] as num?)?.toDouble() ?? 0.0;
      final costoEnvio = (datos['costoEnvio'] as num?)?.toDouble() ?? 0.0;
      final descuentoAplicado = (datos['descuentoAplicado'] as num?)?.toDouble() ?? 0.0;
      final codigoDescuento = datos['codigoDescuento'] as String?;
      final bool origenBarpoints = datos['origenBarpoints'] == true;
      final double? descuentoPorcentaje = (datos['descuentoPorcentaje'] as num?)?.toDouble();

      bytes += generator.text('BAR APP', styles: const PosStyles(align: PosAlign.center, bold: true));
      bytes += generator.text('Ticket Cliente', styles: const PosStyles(align: PosAlign.center));
      
      // Info Cliente
      if (datos['cliente'] != null) {
        bytes += generator.text('Cliente: ${datos['cliente']}', styles: const PosStyles(align: PosAlign.center));
      }
      if (datos['direccion'] != null) {
        bytes += generator.text('Dir: ${datos['direccion']}', styles: const PosStyles(align: PosAlign.center));
      }

      bytes += generator.hr();

      for (var item in items) {
        // Casteo seguro: evita crash si precio/cantidad llegaron como null o String
        final itemPrecio = (item['precio'] as num?)?.toDouble() ?? 0.0;
        final itemCant = (item['cantidad'] as num?)?.toInt() ?? 1;
        final itemNombre = item['nombre']?.toString() ?? '?';
        bytes += generator.text(itemNombre, styles: const PosStyles(bold: true));
        bytes += generator.row([
          PosColumn(text: '$itemCant x \$${itemPrecio.toStringAsFixed(0)}', width: 7, styles: const PosStyles(fontType: PosFontType.fontB)),
          PosColumn(text: '\$${(itemPrecio * itemCant).toStringAsFixed(0)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);
      }

      bytes += generator.hr();
      
      // Subtotal (antes de descuento y envío)
      final subtotal = total + descuentoAplicado - costoEnvio;
      bytes += generator.row([
        PosColumn(text: 'Subtotal:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: '\$${subtotal.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      
      // Descuento por promoción (si existe)
      if (descuentoAplicado > 0 && codigoDescuento != null) {
        final descuentoLabel = origenBarpoints && descuentoPorcentaje != null
            ? 'Descuento BarPoints (${descuentoPorcentaje.toInt()}%):'
            : 'Descuento ($codigoDescuento):';
        bytes += generator.row([
          PosColumn(text: descuentoLabel, width: 6, styles: const PosStyles()),
          PosColumn(text: '-\$${descuentoAplicado.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
      
      if (costoEnvio > 0) {
         bytes += generator.row([
          PosColumn(text: 'Envio:', width: 6, styles: const PosStyles(bold: true)),
          PosColumn(text: '\$${costoEnvio.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]);
      }

      bytes += generator.hr();
      bytes += generator.row([
        PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(height: PosTextSize.size2, bold: true)),
        PosColumn(text: '\$${total.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size2, bold: true)),
      ]);

      bytes += generator.feed(2);
      bytes += generator.text('Gracias por su compra!', styles: const PosStyles(align: PosAlign.center));
      bytes += generator.feed(2);
      bytes += generator.cut();
      // Leer cantidad de copias de la preferencia (max 3 para no bloquear la cola)
      final prefsTicket = await SharedPreferences.getInstance();
      final int copiesTicket = (prefsTicket.getInt('cantidadCopias') ?? 1).clamp(1, 3);
      final Uint8List bytesTicket = Uint8List.fromList(bytes);
      for (int i = 0; i < copiesTicket; i++) {
        await bt.writeBytes(bytesTicket);
      }
    } catch (e) {
      debugPrint("Error Bluetooth Ticket: $e");
      rethrow;
    }
  }
}