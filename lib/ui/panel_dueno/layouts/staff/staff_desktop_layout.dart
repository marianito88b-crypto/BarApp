import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/staff/staff_role_badge.dart';
import '../../widgets/staff/staff_empty_state.dart';
import '../../widgets/staff/staff_helpers.dart';
import '../../widgets/staff/modals/add_member_dialog.dart';
import '../../widgets/staff/modals/attendance_history_dialog.dart';

/// Layout desktop para la gestión de staff
/// 
/// Incluye una DataTable con scroll horizontal para pantallas pequeñas
/// y mantiene el estilo oscuro consistente.
class StaffDesktopLayout extends StatelessWidget {
  final String placeId;
  final Stream<QuerySnapshot> staffStream;
  final Function(String uid, String? email) onDelete;

  const StaffDesktopLayout({
    super.key,
    required this.placeId,
    required this.staffStream,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y botón
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Equipo de Trabajo",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Gestiona los permisos de acceso al panel.",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => AddMemberDialog.show(context, placeId),
                  icon: const Icon(Icons.person_add),
                  label: const Text(
                    "Agregar Miembro al Staff",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Tabla de staff
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Theme(
                    // Tema oscuro para la DataTable
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.white10,
                      dataTableTheme: DataTableThemeData(
                        headingRowColor: WidgetStateProperty.all(Colors.black26),
                        dataRowColor: WidgetStateProperty.all(Colors.transparent),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        dataTextStyle: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: staffStream,
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orangeAccent,
                            ),
                          );
                        }

                        final docs = snap.data!.docs;

                        if (docs.isEmpty) {
                          return const StaffEmptyState(
                            message: "Aún no hay colaboradores.",
                          );
                        }

                        // Scroll horizontal para pantallas pequeñas
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 800),
                              child: DataTable(
                                horizontalMargin: 30,
                                columnSpacing: 40,
                                columns: const [
                                  DataColumn(
                                    label: Text("Colaborador"),
                                  ),
                                  DataColumn(
                                    label: Text("Rol Asignado"),
                                  ),
                                  DataColumn(
                                    label: Text("Fecha Ingreso"),
                                  ),
                                  DataColumn(
                                    label: Text("Acciones"),
                                  ),
                                ],
                                rows: docs.map((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  String fecha = "-";
                                  // Usar fechaUnion como campo principal, con fallback a agregadoEl para compatibilidad
                                  final timestamp = data['fechaUnion'] ?? data['agregadoEl'];
                                  if (timestamp != null && timestamp is Timestamp) {
                                    final date = timestamp.toDate();
                                    fecha = "${date.day}/${date.month}/${date.year}";
                                  }

                                  // Obtener nombre a mostrar (apodo si existe, sino nombre completo)
                                  final nombreCompleto = data['nombre'] ?? data['nombreCompleto'] ?? data['email'] ?? 'Usuario';
                                  final apodo = data['apodo'] as String?;
                                  final nombreAMostrar = apodo != null && apodo.isNotEmpty ? apodo : nombreCompleto;
                                  final fotoUrl = data['fotoUrl'] as String?;
                                  final rolValue = data['rol'] ?? 'mozo';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: getColorRol(rolValue).withValues(alpha: 0.2),
                                              backgroundImage: fotoUrl != null && fotoUrl.isNotEmpty
                                                  ? NetworkImage(fotoUrl)
                                                  : null,
                                              child: fotoUrl == null || fotoUrl.isEmpty
                                                  ? Icon(
                                                      getIconRol(rolValue),
                                                      size: 18,
                                                      color: getColorRol(rolValue),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  nombreAMostrar,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (apodo != null && apodo.isNotEmpty)
                                                  Text(
                                                    nombreCompleto,
                                                    style: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(
                                        RoleBadge(rol: data['rol'] ?? 'mozo'),
                                      ),
                                      DataCell(Text(fecha)),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.history,
                                                color: Colors.orangeAccent,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  AttendanceHistoryDialog.show(
                                                context,
                                                placeId,
                                                doc.id,
                                                data['email'] ?? 'Usuario',
                                              ),
                                              tooltip: "Ver historial",
                                              splashRadius: 20,
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  onDelete(doc.id, data['email']),
                                              tooltip: "Eliminar acceso",
                                              splashRadius: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
