import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../logic/config_logic.dart';
import '../layouts/config/config_mobile_layout.dart';
import '../layouts/config/config_desktop_layout.dart';

class ConfigMobile extends StatefulWidget {
  final String placeId;
  const ConfigMobile({super.key, required this.placeId});

  @override
  State<ConfigMobile> createState() => _ConfigMobileState();
}

class _ConfigMobileState extends State<ConfigMobile> with ConfigLogicMixin {
  @override
  String get placeId => widget.placeId;

  late final Stream<DocumentSnapshot> _placeStream;

  @override
  void initState() {
    super.initState();
    _placeStream = FirebaseFirestore.instance
        .collection("places")
        .doc(widget.placeId)
        .snapshots();
  }

  @override
  void dispose() {
    disposeConfigLogic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _placeStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text(
                'Error al cargar la configuración',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orangeAccent),
            );
          }

          final data = snap.data!.data() as Map<String, dynamic>? ?? {};

          // Inicializar controladores y cargar datos solo una vez
          initConfigLogic(data);

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return ConfigDesktopLayout(
                  placeId: widget.placeId,
                  data: data,
                  nombreController: nombreController,
                  descripcionController: descripcionController,
                  direccionController: direccionController,
                  latitud: latitudBar,
                  longitud: longitudBar,
                  obteniendoUbicacion: obteniendoUbicacion,
                  onGuardarDatosGenerales: guardarDatosGenerales,
                  onGuardarUbicacionGPS: guardarUbicacionGPS,
                  cbuController: cbuController,
                  aliasController: aliasController,
                  bancoController: bancoController,
                  titularController: titularController,
                  onGuardarDatosBancarios: guardarDatosBancarios,
                  envioBaseController: envioBaseController,
                  envioKmExtraController: envioKmExtraController,
                  onGuardarCostosEnvio: guardarCostosEnvio,
                  onUpdateRealTime: updateRealTime,
                  onMostrarAdvertenciaEfectivo: mostrarAdvertenciaEfectivo,
                  onEditarCampoTexto: editarCampoTexto,
                  onSeleccionarHora: (fieldKey, {valorActual}) => 
                      seleccionarHora(fieldKey, valorActual: valorActual),
                  onActualizarDobleTurno: actualizarDobleTurno,
                );
              } else {
                return ConfigMobileLayout(
                  placeId: widget.placeId,
                  data: data,
                  nombreController: nombreController,
                  descripcionController: descripcionController,
                  direccionController: direccionController,
                  latitud: latitudBar,
                  longitud: longitudBar,
                  obteniendoUbicacion: obteniendoUbicacion,
                  onGuardarDatosGenerales: guardarDatosGenerales,
                  onGuardarUbicacionGPS: guardarUbicacionGPS,
                  cbuController: cbuController,
                  aliasController: aliasController,
                  bancoController: bancoController,
                  titularController: titularController,
                  onGuardarDatosBancarios: guardarDatosBancarios,
                  onUpdateRealTime: updateRealTime,
                  onMostrarAdvertenciaEfectivo: mostrarAdvertenciaEfectivo,
                  onEditarCampoTexto: editarCampoTexto,
                  onSeleccionarHora: (fieldKey, {valorActual}) => 
                      seleccionarHora(fieldKey, valorActual: valorActual),
                  onActualizarDobleTurno: actualizarDobleTurno,
                );
              }
            },
          );
        },
      ),
    );
  }




}

