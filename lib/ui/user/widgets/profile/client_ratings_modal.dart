import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal del CLIENTE: muestra lo que los BARES opinan de él.
///
/// RUTA B: Lee de {col}/{userId}/reputacion_recibida
/// Campos: placeNombre, estrellas, etiquetas, comentarios, timestamp.
///
/// Intenta primero 'usuarios', luego 'users' (colección legacy).
class ClientRatingsModal extends StatelessWidget {
  final String userId;

  const ClientRatingsModal({
    super.key,
    required this.userId,
  });

  static void show(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClientRatingsModal(userId: userId),
    );
  }

  /// Intenta la colección 'usuarios' primero; si no hay docs, 'users'.
  /// Se usa un FutureBuilder para resolver la colección correcta una vez.
  Future<String> _resolveCollection() async {
    final db = FirebaseFirestore.instance;
    // Si el doc en 'usuarios' existe, usar esa colección
    final snap = await db.collection('usuarios').doc(userId).get();
    return snap.exists ? 'usuarios' : 'users';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.blueAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Calificaciones de Bares",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Cómo te ven los restaurantes",
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Contenido ────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<String>(
              future: _resolveCollection(),
              builder: (context, futureSnap) {
                if (!futureSnap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  );
                }
                final collection = futureSnap.data!;
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection(collection)
                      .doc(userId)
                      .collection('reputacion_recibida')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.blueAccent,
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return _ErrorState(error: snap.error.toString());
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const _EmptyState();
                    }
                    return _RatingsList(docs: docs);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lista con promedio ──────────────────────────────────────────────────────
class _RatingsList extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  const _RatingsList({required this.docs});

  @override
  Widget build(BuildContext context) {
    double suma = 0;
    for (final d in docs) {
      suma += (d.data()['estrellas'] as num?)?.toDouble() ?? 0;
    }
    final promedio = docs.isNotEmpty ? suma / docs.length : 0.0;

    return Column(
      children: [
        // ── Promedio general ───────────────────────────────────────
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.withValues(alpha: 0.2),
                Colors.blueAccent.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.blueAccent, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Promedio de Calificaciones",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          promedio.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(5, (i) => Icon(
                          i < promedio.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.blueAccent,
                          size: 18,
                        )),
                      ],
                    ),
                    Text(
                      "${docs.length} ${docs.length == 1 ? 'calificación' : 'calificaciones'} de bares",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Items ──────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final placeNombre = data['placeNombre'] as String? ?? 'Bar';
              final placeId = data['placeId'] as String? ?? '';
              final estrellas = (data['estrellas'] as num?)?.toInt() ?? 0;
              final etiquetas = List<String>.from(
                data['etiquetas'] as List? ?? [],
              );
              final comentarios = data['comentarios'] as String?;
              final timestamp = data['timestamp'] as Timestamp?;

              return _RatingCard(
                placeNombre: placeNombre,
                placeId: placeId,
                estrellas: estrellas,
                etiquetas: etiquetas,
                comentarios: comentarios,
                fecha: timestamp?.toDate(),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de calificación ─────────────────────────────────────────────────
class _RatingCard extends StatelessWidget {
  final String placeNombre;
  final String placeId;
  final int estrellas;
  final List<String> etiquetas;
  final String? comentarios;
  final DateTime? fecha;

  const _RatingCard({
    required this.placeNombre,
    required this.placeId,
    required this.estrellas,
    required this.etiquetas,
    required this.comentarios,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: bar + estrellas + fecha
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placeNombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (fecha != null)
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(fecha!),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Estrellas
              Row(
                children: List.generate(5, (i) => Icon(
                  i < estrellas
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.blueAccent,
                  size: 18,
                )),
              ),
            ],
          ),

          // Etiquetas
          if (etiquetas.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: etiquetas
                  .map((tag) => _EtiquetaChip(label: tag))
                  .toList(),
            ),
          ],

          // Comentarios
          if (comentarios != null && comentarios!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    color: Colors.blueAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      comentarios!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EtiquetaChip extends StatelessWidget {
  final String label;
  const _EtiquetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.blueAccent, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Estados vacío / error ───────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            "Aún no tienes calificaciones",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Aparecerán aquí cuando los bares califiquen tus pedidos",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          const Text(
            "Error al cargar calificaciones",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
