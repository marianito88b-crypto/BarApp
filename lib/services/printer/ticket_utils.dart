import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketUtils {
  static const format58 = PdfPageFormat(
    58 * PdfPageFormat.mm, 
    double.infinity, 
    marginAll: 2 * PdfPageFormat.mm,
  );

  // =======================================================
  // 1. COMANDA DE COCINA (CON NOTAS GIGANTES)
  // =======================================================
  static Future<Uint8List> generatePdfComanda(Map<String, dynamic> pedido) async {
    final pdf = pw.Document();
    final items = (pedido['items'] as List<dynamic>?) ?? [];
    
    // Extracción de datos
    final bool esApp = pedido['origen'] == 'app' || pedido['origen'] == 'delivery';
    final String canal = esApp ? "NUEVO PEDIDO: BARAPP" : "NUEVO PEDIDO: SALON";
    final String horaImpresion = DateFormat('dd/MM - HH:mm').format(DateTime.now());
    
    // 🔥 CAPTURAMOS LA NOTA
    final String notas = pedido['notas']?.toString() ?? '';

    pdf.addPage(
      pw.Page(
        pageFormat: format58,
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // TITULO PRINCIPAL
              pw.Text(canal, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              
              // HORA DE IMPRESIÓN
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 2),
                child: pw.Text('Hora: $horaImpresion', style: const pw.TextStyle(fontSize: 10)),
              ),
                
              pw.Divider(thickness: 1),
              
              // MESA / RETIRO / DELIVERY
              pw.Text('INFO: ${pedido['mesaNombre'] ?? "S/M"}', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              
              pw.Divider(),

              // 🔥🔥🔥 SECCIÓN DE NOTAS (NUEVO) 🔥🔥🔥
              if (notas.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 2), // Borde grueso
                    color: PdfColors.grey200,        // Fondo gris para resaltar
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text("!!! LEER NOTA !!!", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        notas.toUpperCase(), 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16), 
                        textAlign: pw.TextAlign.center
                      ),
                    ]
                  )
                ),
                pw.Divider(),
              ],
              // 🔥🔥🔥 FIN SECCIÓN DE NOTAS 🔥🔥🔥
              
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  children: items.map((item) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('${item['cantidad']}x ', 
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Expanded(child: pw.Text(item['nombre'], 
                          style: pw.TextStyle(fontSize: 14))),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              
              pw.SizedBox(height: 15),
              pw.Text('--- FIN COMANDA ---', style: const pw.TextStyle(fontSize: 8)),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // =======================================================
  // 2. TICKET DE CUENTA (CON PRECIOS)
  // =======================================================
  static Future<Uint8List> generatePdfCuenta(Map<String, dynamic> datos) async {
    final pdf = pw.Document();
    final items = (datos['items'] as List<dynamic>?) ?? [];
    final total = (datos['total'] as num?)?.toDouble() ?? 0.0;
    
    // Usar fecha original del pedido si está disponible, sino usar fecha actual
    DateTime fechaPedido = DateTime.now();
    if (datos['fecha'] != null) {
      if (datos['fecha'] is Timestamp) {
        fechaPedido = (datos['fecha'] as Timestamp).toDate();
      } else if (datos['fecha'] is DateTime) {
        fechaPedido = datos['fecha'] as DateTime;
      }
    } else if (datos['timestamp'] != null) {
      if (datos['timestamp'] is Timestamp) {
        fechaPedido = (datos['timestamp'] as Timestamp).toDate();
      } else if (datos['timestamp'] is DateTime) {
        fechaPedido = datos['timestamp'] as DateTime;
      }
    }
    
    final fecha = DateFormat('dd/MM HH:mm').format(fechaPedido);

    pdf.addPage(
      pw.Page(
        pageFormat: format58,
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('BAR APP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('Ticket de Control', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Mesa: ${datos['mesaNombre']}', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(fecha, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              ...items.map((item) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text('${item['cantidad']}x ${item['nombre']}', 
                        style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Text('\$${(item['precio'] * item['cantidad']).toStringAsFixed(0)}', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),
              )),

              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('\$${total.toStringAsFixed(0)}', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('¡Gracias por elegirnos!', style: const pw.TextStyle(fontSize: 9)),
              pw.Text('NO VALIDO COMO FACTURA', style: const pw.TextStyle(fontSize: 7)),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // =======================================================
  // 3. FICHA DE RESERVA (Diseño PRO)
  // =======================================================
  static Future<Uint8List> generatePdfReserva(Map<String, dynamic> datos) async {
    final pdf = pw.Document();
    
    // Manejo de fecha seguro
    final DateTime fechaObj = datos['fechaReserva'] is DateTime 
        ? datos['fechaReserva'] 
        : (datos['fechaReserva'] as dynamic).toDate();
    
    final fechaStr = DateFormat('dd/MM HH:mm').format(fechaObj);

    pdf.addPage(
      pw.Page(
        pageFormat: format58,
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Text('RESERVA BARAPP', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.SizedBox(height: 8),
              pw.Text('FECHA: $fechaStr', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Divider(),
              
              pw.Text('CLIENTE:', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(datos['cliente']?.toString().toUpperCase() ?? 'SIN NOMBRE', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
              
              pw.SizedBox(height: 10),
              
              pw.Text('MESA ASIGNADA:', style: const pw.TextStyle(fontSize: 9)),
              pw.Text(datos['mesaNombre']?.toString() ?? 'A DEFINIR', 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PERSONAS:', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('${datos['personas']}', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                ],
              ),

              if (datos['total'] > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Monto Seña:', style: const pw.TextStyle(fontSize: 11)),
                    pw.Text('\$${datos['total']}', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  ],
                ),

              pw.SizedBox(height: 20),
              
              // Cuadro de Check
              pw.Container(
                height: 40,
                width: 40,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                child: pw.Center(child: pw.Text('OK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10))),
              ),
              pw.SizedBox(height: 5),
              pw.Text('Verificar en el panel de reservas', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  // =======================================================
  // 4. TICKET DETALLADO CLIENTE WEB (CON ENVÍO DETALLADO)
  // =======================================================
  static Future<Uint8List> generatePdfPedidoWeb(Map<String, dynamic> datos) async {
    final pdf = pw.Document();
    final items = (datos['items'] as List<dynamic>?) ?? [];
    final double totalFinal = (datos['total'] as num?)?.toDouble() ?? 0.0;
    
    // 🔥 EXTRAEMOS EL COSTO DE ENVÍO Y DESCUENTO
    final double costoEnvio = (datos['costoEnvio'] as num? ?? 0.0).toDouble();
    final double descuentoAplicado = (datos['descuentoAplicado'] as num?)?.toDouble() ?? 0.0;
    final String? codigoDescuento = datos['codigoDescuento'] as String?;
    final bool origenBarpoints = datos['origenBarpoints'] == true;
    final double? descuentoPorcentaje = (datos['descuentoPorcentaje'] as num?)?.toDouble();
    // Subtotal = total final + descuento - envío (para mostrar correctamente)
    final double subtotalComida = totalFinal + descuentoAplicado - costoEnvio;

    final String metodo = (datos['metodoEntrega'] == 'delivery') ? "🚚 ENTREGA DELIVERY" : "🥡 RETIRO LOCAL";
    
    // Usar fecha original del pedido si está disponible, sino usar fecha actual
    DateTime fechaPedido = DateTime.now();
    if (datos['fecha'] != null) {
      if (datos['fecha'] is Timestamp) {
        fechaPedido = (datos['fecha'] as Timestamp).toDate();
      } else if (datos['fecha'] is DateTime) {
        fechaPedido = datos['fecha'] as DateTime;
      }
    } else if (datos['timestamp'] != null) {
      if (datos['timestamp'] is Timestamp) {
        fechaPedido = (datos['timestamp'] as Timestamp).toDate();
      } else if (datos['timestamp'] is DateTime) {
        fechaPedido = datos['timestamp'] as DateTime;
      }
    }
    
    final String fechaStr = DateFormat('dd/MM HH:mm').format(fechaPedido);

    pdf.addPage(
      pw.Page(
        pageFormat: format58,
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('PEDIDO BARAPP', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text(metodo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text('Fecha: $fechaStr', style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(),

              // INFO CLIENTE
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('CLIENTE: ${datos['cliente']?.toString().toUpperCase()}', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('TEL: ${datos['telefono']}', style: const pw.TextStyle(fontSize: 10)),
                    if (datos['metodoEntrega'] == 'delivery')
                      pw.Text('DIR: ${datos['direccion']}', 
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  ],
                ),
              ),
              
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // ITEMS
              ...items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(child: pw.Text('${item['cantidad']}x ${item['nombre']}', style: const pw.TextStyle(fontSize: 9))),
                  pw.Text('\$${(item['precio'] * item['cantidad']).toStringAsFixed(0)}', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                ],
              )),

              pw.Divider(),

              // 🔥 DESGLOSE FINAL ESPECTACULAR
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('\$${subtotalComida.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              
              // Descuento por promoción (si existe)
              if (descuentoAplicado > 0 && codigoDescuento != null)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      origenBarpoints && descuentoPorcentaje != null
                          ? 'Descuento BarPoints (${descuentoPorcentaje.toInt()}%):'
                          : 'Descuento ($codigoDescuento):',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.green),
                    ),
                    pw.Text('-\$${descuentoAplicado.toStringAsFixed(0)}', 
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.green)),
                  ],
                ),
              
              if (costoEnvio > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Costo de Envío:', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('\$${costoEnvio.toStringAsFixed(0)}', 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  ],
                ),

              pw.SizedBox(height: 5),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL A COBRAR:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('\$${totalFinal.toStringAsFixed(0)}', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              
              pw.SizedBox(height: 10),
              pw.Text('¡Muchas gracias por su compra!', style: const pw.TextStyle(fontSize: 8)),
              pw.Text('--- BAR APP ---', style: const pw.TextStyle(fontSize: 7)),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }
}