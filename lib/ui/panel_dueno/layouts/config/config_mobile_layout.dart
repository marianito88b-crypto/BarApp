import 'package:flutter/material.dart';
import '../../widgets/config/config_tile.dart';
import '../../widgets/config/config_switch.dart';
import '../../widgets/config/business_info_card.dart';
import '../../widgets/config/payment_info_card.dart';
import '../../widgets/config/operational_status_card.dart';
import '../../sections/staff_mobile.dart';
import '../../gallery_manager_screen.dart';
import '../../pos/printer_config_screen.dart';

/// Layout móvil para la pantalla de configuración
class ConfigMobileLayout extends StatelessWidget {
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
  final Function(Map<String, dynamic>) onUpdateRealTime;
  final VoidCallback onMostrarAdvertenciaEfectivo;
  final Function(String, String, String, TextInputType) onEditarCampoTexto;
  final Function(String, {String? valorActual}) onSeleccionarHora;
  final Function(bool) onActualizarDobleTurno;

  const ConfigMobileLayout({
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle("Estado del Local"),
          const SizedBox(height: 10),
          OperationalStatusCard(
            data: data,
            onUpdateRealTime: onUpdateRealTime,
            onMostrarAdvertenciaEfectivo: onMostrarAdvertenciaEfectivo,
          ),

          const SizedBox(height: 20),
          _buildSectionTitle("BarPoints"),
          const SizedBox(height: 10),
          ConfigSwitch(
            label: "Local adherido a BarPoints",
            subLabel: (data['aceptaBarpoints'] ?? false)
                ? "Los clientes pueden canjear puntos acá"
                : "Activar para que aparezca el sello BarPoint",
            value: data['aceptaBarpoints'] ?? false,
            icon: Icons.loyalty_rounded,
            activeColor: Colors.deepOrange,
            onChanged: (v) => onUpdateRealTime({'aceptaBarpoints': v}),
          ),
          const SizedBox(height: 10),
          ConfigSwitch(
            label: "Canje disponible hoy",
            subLabel: (data['barpointsDisponiblesHoy'] ?? false)
                ? "Los clientes pueden canjear en pedidos online"
                : "Activar en días de poco movimiento para incentivar",
            value: data['barpointsDisponiblesHoy'] ?? false,
            icon: Icons.today_rounded,
            activeColor: Colors.orangeAccent,
            onChanged: (v) => onUpdateRealTime({'barpointsDisponiblesHoy': v}),
          ),

          const SizedBox(height: 30),
          _buildSectionTitle("Datos del Negocio"),
          const SizedBox(height: 10),
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

          const SizedBox(height: 30),
          _buildSectionTitle("Datos de Cobro (Transferencias)"),
          const SizedBox(height: 10),
          PaymentInfoCard(
            cbuController: cbuController,
            aliasController: aliasController,
            bancoController: bancoController,
            titularController: titularController,
            onGuardar: onGuardarDatosBancarios,
          ),

          const SizedBox(height: 30),
          _buildSectionTitle("Horarios y Contacto"),
          const SizedBox(height: 10),
          _buildSocialsAndHours(context),

          const SizedBox(height: 30),
          _buildSectionTitle("Gestión Visual y Staff"),
          const SizedBox(height: 10),

          ConfigTile(
            label: "Imagen principal del Local",
            icon: Icons.image,
            trailing: const Icon(Icons.star, color: Colors.amber, size: 18),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GalleryManagerScreen(placeId: placeId),
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
                builder: (_) => GalleryManagerScreen(placeId: placeId),
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
                builder: (_) => StaffMobile(placeId: placeId),
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
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSocialsAndHours(BuildContext context) {
    final bool tieneDobleTurno = data['tieneDobleTurno'] ?? false;

    return Column(
      children: [
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
        const SizedBox(height: 16),
        
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
        
        const SizedBox(height: 16),
        
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
    );
  }
}
