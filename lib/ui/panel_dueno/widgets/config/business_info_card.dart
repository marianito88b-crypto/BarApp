import 'package:flutter/material.dart';

/// Tarjeta de información general del negocio
class BusinessInfoCard extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController descripcionController;
  final TextEditingController direccionController;
  final double? latitud;
  final double? longitud;
  final bool obteniendoUbicacion;
  final VoidCallback onGuardar;
  final VoidCallback onGuardarUbicacionGPS;

  const BusinessInfoCard({
    super.key,
    required this.nombreController,
    required this.descripcionController,
    required this.direccionController,
    required this.latitud,
    required this.longitud,
    required this.obteniendoUbicacion,
    required this.onGuardar,
    required this.onGuardarUbicacionGPS,
  });

  @override
  Widget build(BuildContext context) {
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
            "Información del Local",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _inputField("Nombre del Negocio", nombreController, Icons.store),
          const SizedBox(height: 12),
          TextField(
            controller: descripcionController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Descripción / Info del Lugar",
              prefixIcon: const Icon(Icons.info_outline, color: Colors.white54),
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _inputField("Dirección", direccionController, Icons.location_on),
          const SizedBox(height: 12),

          // SECCIÓN GPS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: latitud != null ? Colors.green : Colors.orangeAccent,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: latitud != null ? Colors.green : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        latitud != null
                            ? "Ubicación Configurada ✅\n(${latitud!.toStringAsFixed(4)}, ${longitud!.toStringAsFixed(4)})"
                            : "Ubicación NO Configurada ⚠️",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: obteniendoUbicacion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text("Establecer Ubicación Actual (GPS)"),
                    onPressed: obteniendoUbicacion ? null : onGuardarUbicacionGPS,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orangeAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Guardar Info"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                onGuardar();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
