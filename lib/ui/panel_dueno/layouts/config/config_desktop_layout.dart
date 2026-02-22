import 'package:flutter/material.dart';
import '../../widgets/config/config_tile.dart';
import '../../widgets/config/config_switch.dart';
import '../../widgets/config/business_info_card.dart';
import '../../widgets/config/payment_info_card.dart';
import '../../widgets/config/delivery_pricing_card.dart';
import '../../widgets/config/operational_status_card.dart';
import '../../sections/staff_mobile.dart';
import '../../gallery_manager_screen.dart';
import '../../pos/printer_config_screen.dart';

/// Layout desktop para la pantalla de configuración
class ConfigDesktopLayout extends StatelessWidget {
  final String placeId;
  final Map<String, dynamic> data;
  final TextEditingController nombreController;
  final TextEditingController descripcionController;
  final TextEditingController direccionController;
  final double? latitud;
  final double? longitud;
  final bool obteniendoUbicacion;
  final VoidCallback onGuardarDatosGenerales;
  final VoidCallback onGuardarUbicacionGPS;
  final TextEditingController cbuController;
  final TextEditingController aliasController;
  final TextEditingController bancoController;
  final TextEditingController titularController;
  final VoidCallback onGuardarDatosBancarios;
  final TextEditingController envioBaseController;
  final TextEditingController envioKmExtraController;
  final VoidCallback onGuardarCostosEnvio;
  final Function(Map<String, dynamic>) onUpdateRealTime;
  final VoidCallback onMostrarAdvertenciaEfectivo;
  final Function(String, String, String, TextInputType) onEditarCampoTexto;
  final Function(String, {String? valorActual}) onSeleccionarHora;
  final Function(bool) onActualizarDobleTurno;

  const ConfigDesktopLayout({
    super.key,
    required this.placeId,
    required this.data,
    required this.nombreController,
    required this.descripcionController,
    required this.direccionController,
    required this.latitud,
    required this.longitud,
    required this.obteniendoUbicacion,
    required this.onGuardarDatosGenerales,
    required this.onGuardarUbicacionGPS,
    required this.cbuController,
    required this.aliasController,
    required this.bancoController,
    required this.titularController,
    required this.onGuardarDatosBancarios,
    required this.envioBaseController,
    required this.envioKmExtraController,
    required this.onGuardarCostosEnvio,
    required this.onUpdateRealTime,
    required this.onMostrarAdvertenciaEfectivo,
    required this.onEditarCampoTexto,
    required this.onSeleccionarHora,
    required this.onActualizarDobleTurno,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configuración General",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // COLUMNA IZQUIERDA (Info y Gestión)
                  Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          BusinessInfoCard(
                            nombreController: nombreController,
                            descripcionController: descripcionController,
                            direccionController: direccionController,
                            latitud: latitud,
                            longitud: longitud,
                            obteniendoUbicacion: obteniendoUbicacion,
                            onGuardar: onGuardarDatosGenerales,
                            onGuardarUbicacionGPS: onGuardarUbicacionGPS,
                          ),
                          const SizedBox(height: 20),
                          PaymentInfoCard(
                            cbuController: cbuController,
                            aliasController: aliasController,
                            bancoController: bancoController,
                            titularController: titularController,
                            onGuardar: onGuardarDatosBancarios,
                          ),
                          const SizedBox(height: 20),

                          ConfigTile(
                            label: "Imagen principal del Local",
                            icon: Icons.image,
                            trailing: const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 18,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GalleryManagerScreen(
                                  placeId: placeId,
                                ),
                              ),
                            ),
                          ),

                          ConfigTile(
                            label: "Galería de Fotos",
                            icon: Icons.photo_library,
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.purpleAccent,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GalleryManagerScreen(
                                  placeId: placeId,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ConfigTile(
                            label: "Gestión de Personal (Staff)",
                            icon: Icons.people_alt,
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.orangeAccent,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StaffMobile(
                                  placeId: placeId,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ConfigTile(
                            label: "Configurar Impresora",
                            icon: Icons.print,
                            trailing: const Icon(
                              Icons.settings_bluetooth,
                              size: 16,
                              color: Colors.blueAccent,
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrinterConfigScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // COLUMNA DERECHA (Operatividad)
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Operatividad en Vivo",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                OperationalStatusCard(
                                  data: data,
                                  onUpdateRealTime: onUpdateRealTime,
                                  onMostrarAdvertenciaEfectivo:
                                      onMostrarAdvertenciaEfectivo,
                                ),
                                const SizedBox(height: 16),
                                ConfigSwitch(
                                  label: "Local adherido a BarPoints",
                                  subLabel: (data['aceptaBarpoints'] ?? false)
                                      ? "Los clientes pueden canjear puntos"
                                      : "Activar para sello BarPoint",
                                  value: data['aceptaBarpoints'] ?? false,
                                  icon: Icons.loyalty_rounded,
                                  activeColor: Colors.deepOrange,
                                  onChanged: (v) => onUpdateRealTime({'aceptaBarpoints': v}),
                                ),
                                const SizedBox(height: 10),
                                ConfigSwitch(
                                  label: "Canje disponible hoy",
                                  subLabel: (data['barpointsDisponiblesHoy'] ?? false)
                                      ? "Acepta canje en pedidos online"
                                      : "Activar en días de poco movimiento",
                                  value: data['barpointsDisponiblesHoy'] ?? false,
                                  icon: Icons.today_rounded,
                                  activeColor: Colors.orangeAccent,
                                  onChanged: (v) => onUpdateRealTime({'barpointsDisponiblesHoy': v}),
                                ),
                                const Divider(
                                  color: Colors.white10,
                                  height: 40,
                                ),
                                _buildDurationSlider(context),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          DeliveryPricingCard(
                            data: data,
                            envioBaseController: envioBaseController,
                            envioKmExtraController: envioKmExtraController,
                            onEnvioGratisChanged: (v) =>
                                onUpdateRealTime({'envioGratis': v}),
                            onGuardarCostos: onGuardarCostosEnvio,
                          ),
                          const SizedBox(height: 20),
                          _buildSocialsAndHours(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSlider(BuildContext context) {
    final int duracionPromedio = data['duracionPromedio'] ?? 120;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white70),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Duración promedio de mesa",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$duracionPromedio min",
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Tiempo estimado que el sistema bloqueará la mesa por cada reserva.",
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.orangeAccent,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.white,
              overlayColor: Colors.orangeAccent.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: duracionPromedio.toDouble(),
              min: 30,
              max: 240,
              divisions: 14,
              label: "$duracionPromedio min",
              onChanged: (double value) =>
                  onUpdateRealTime({'duracionPromedio': value.toInt()}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialsAndHours(BuildContext context) {
    final bool tieneDobleTurno = data['tieneDobleTurno'] ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Horarios y Contacto",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ConfigTile(
            label: "WhatsApp (Pedidos/Reservas)",
            icon: Icons.chat_bubble,
            trailing: Text(
              data['whatsapp'] ?? "Sin configurar",
              style: const TextStyle(color: Colors.green, fontSize: 12),
            ),
            onTap: () => onEditarCampoTexto(
              "WhatsApp (Num con código país ej: 549362...)",
              data['whatsapp'] ?? '',
              'whatsapp',
              TextInputType.phone,
            ),
          ),
          const SizedBox(height: 10),
          ConfigTile(
            label: "Instagram",
            icon: Icons.camera_alt,
            trailing: Text(
              data['instagram'] == null
                  ? "Sin configurar"
                  : "@${data['instagram']}",
              style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
            ),
            onTap: () => onEditarCampoTexto(
              "Usuario de Instagram (sin @)",
              data['instagram'] ?? '',
              'instagram',
              TextInputType.text,
            ),
          ),
          const SizedBox(height: 20),
          
          // Switch para habilitar segundo turno
          ConfigSwitch(
            label: "Habilitar Segundo Turno",
            subLabel: tieneDobleTurno
                ? "Turnos partidos activos (Mañana y Tarde/Noche)"
                : "Un solo turno continuo",
            value: tieneDobleTurno,
            icon: Icons.access_time,
            activeColor: Colors.orangeAccent,
            onChanged: onActualizarDobleTurno,
          ),
          
          const SizedBox(height: 20),
          
          // Fila 1: Turno Mañana/Principal
          Row(
            children: [
              Expanded(
                child: ConfigTile(
                  label: "Apertura 1",
                  icon: Icons.wb_sunny,
                  trailing: Text(
                    data['horarioApertura'] ?? '--:--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => onSeleccionarHora(
                    'horarioApertura',
                    valorActual: data['horarioApertura'],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ConfigTile(
                  label: "Cierre 1",
                  icon: Icons.nightlight_round,
                  trailing: Text(
                    data['horarioCierre'] ?? '--:--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => onSeleccionarHora(
                    'horarioCierre',
                    valorActual: data['horarioCierre'],
                  ),
                ),
              ),
            ],
          ),
          
          // Fila 2: Turno Tarde/Noche (solo si tieneDobleTurno es true)
          if (tieneDobleTurno) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ConfigTile(
                    label: "Apertura 2",
                    icon: Icons.wb_sunny_outlined,
                    trailing: Text(
                      data['horarioApertura2'] ?? '--:--',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => onSeleccionarHora(
                      'horarioApertura2',
                      valorActual: data['horarioApertura2'],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ConfigTile(
                    label: "Cierre 2",
                    icon: Icons.nightlight_round_outlined,
                    trailing: Text(
                      data['horarioCierre2'] ?? '--:--',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => onSeleccionarHora(
                      'horarioCierre2',
                      valorActual: data['horarioCierre2'],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
