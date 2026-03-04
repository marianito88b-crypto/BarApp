import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barapp/services/barpoints_service.dart';
import 'reward_client_dialog.dart';

/// Widget que muestra el ranking de mejores clientes
/// 
/// Permite filtrar por BarPoints o Reputación
class TopClientsRanking extends StatefulWidget {
  final String placeId;
  final String? placeName;

  const TopClientsRanking({
    super.key,
    required this.placeId,
    this.placeName,
  });

  @override
  State<TopClientsRanking> createState() => _TopClientsRankingState();
}

class _TopClientsRankingState extends State<TopClientsRanking> {
  String _filterType = 'barpoints'; // 'barpoints' o 'reputacion'
  bool _isLoading = true;
  List<Map<String, dynamic>> _clients = [];
  String? _placeName;

  @override
  void initState() {
    super.initState();
    _loadPlaceName();
    _loadTopClients();
  }

  Future<void> _loadPlaceName() async {
    try {
      final placeDoc = await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .get();
      if (!mounted) return;
      final data = placeDoc.exists ? placeDoc.data() : null;
      setState(() {
        _placeName = data?['nombre'] ?? widget.placeName ?? 'El Local';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _placeName = widget.placeName ?? 'El Local';
        });
      }
    }
  }

  Future<void> _loadTopClients() async {
    setState(() => _isLoading = true);

    try {
      // Obtener todos los pedidos del lugar para identificar clientes únicos
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .collection('orders')
          .where('estado', isEqualTo: 'entregado')
          .get();

      // Agrupar por userId y calcular estadísticas
      final Map<String, Map<String, dynamic>> clientsMap = {};

      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        final userId = orderData['userId'] as String?;
        if (userId == null || userId.isEmpty) continue;

        if (!clientsMap.containsKey(userId)) {
          clientsMap[userId] = {
            'userId': userId,
            'nombre': orderData['clienteNombre'] ?? 'Cliente',
            'totalGastado': 0.0,
            'totalPedidos': 0,
            'barPoints': 0,
          };
        }

        final total = (orderData['total'] as num?)?.toDouble() ?? 0.0;
        clientsMap[userId]!['totalGastado'] =
            (clientsMap[userId]!['totalGastado'] as num).toDouble() + total;
        clientsMap[userId]!['totalPedidos'] =
            (clientsMap[userId]!['totalPedidos'] as num).toInt() + 1;
      }

      // Obtener BarPoints y reputación en paralelo (un batch por cliente, no secuencial)
      final clientsToProcess = clientsMap.values.toList();
      await Future.wait(
        clientsToProcess.map((clientData) async {
          final userId = clientData['userId'] as String;
          // BarPoints + doc de usuario en paralelo
          final results = await Future.wait<dynamic>([
            BarPointsService.obtenerBarPoints(userId),
            FirebaseFirestore.instance.collection('usuarios').doc(userId).get(),
          ]);
          clientData['barPoints'] = (results[0] as num?)?.toInt() ?? 0;
          var userDoc = results[1] as DocumentSnapshot;
          // Fallback a colección legacy 'users' si no existe en 'usuarios'
          if (!userDoc.exists) {
            userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .get();
          }
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            final rep = userData?['reputacion_cliente'] as Map<String, dynamic>?;
            clientData['promedioEstrellas'] =
                (rep?['promedioEstrellas'] as num?)?.toDouble() ?? 0.0;
            clientData['imageUrl'] = userData?['imageUrl'] ?? userData?['photoUrl'];
          } else {
            clientData['promedioEstrellas'] = 0.0;
          }
        }),
      );
      final clientsList = clientsToProcess;

      // Ordenar según el filtro seleccionado
      clientsList.sort((a, b) {
        if (_filterType == 'barpoints') {
          return (b['barPoints'] as num).compareTo(a['barPoints'] as num);
        } else {
          return (b['promedioEstrellas'] as num)
              .compareTo(a['promedioEstrellas'] as num);
        }
      });

      // Limitar a top 10
      if (mounted) {
        setState(() {
          _clients = clientsList.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando top clientes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    "TOP CLIENTES (MVP)",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildFilterChip('BarPoints', 'barpoints'),
                      _buildFilterChip('Reputación', 'reputacion'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                ),
              )
            else if (_clients.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No hay clientes para mostrar",
                  style: TextStyle(color: Colors.white30),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _clients.length,
                itemBuilder: (context, index) {
                  return _buildClientRow(_clients[index], index + 1);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _filterType = value);
        _loadTopClients();
      },
      selectedColor: Colors.orangeAccent.withValues(alpha: 0.2),
      checkmarkColor: Colors.orangeAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.orangeAccent : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      side: BorderSide(
        color: isSelected ? Colors.orangeAccent : Colors.white24,
      ),
    );
  }

  Widget _buildClientRow(Map<String, dynamic> client, int position) {
    final nombre = client['nombre'] ?? 'Cliente';
    final imageUrl = client['imageUrl'] as String?;
    final promedioEstrellas = (client['promedioEstrellas'] as num?)?.toDouble() ?? 0.0;
    final barPoints = (client['barPoints'] as num?)?.toInt() ?? 0;
    final totalGastado = (client['totalGastado'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orangeAccent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Posición
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: position <= 3
                  ? Colors.orangeAccent.withValues(alpha: 0.2)
                  : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  color: position <= 3 ? Colors.orangeAccent : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Foto
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white10,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white54)
                : null,
          ),
          const SizedBox(width: 12),
          // Datos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_filterType == 'reputacion' && promedioEstrellas > 0) ...[
                        const Icon(
                          Icons.star,
                          color: Colors.orangeAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          promedioEstrellas.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (_filterType == 'barpoints') ...[
                        const Icon(
                          Icons.workspace_premium,
                          color: Colors.orangeAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$barPoints pts',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Total gastado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalGastado.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${client['totalPedidos']} pedidos',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Botón Premiar
          IconButton(
            onPressed: () => _mostrarDialogoPremio(client),
            icon: const Icon(Icons.card_giftcard, color: Colors.orangeAccent),
            tooltip: "Premiar cliente",
            style: IconButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoPremio(Map<String, dynamic> client) {
    final userId = client['userId'] as String?;
    final clienteNombre = client['nombre'] ?? 'Cliente';
    
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se puede premiar: usuario no identificado"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => RewardClientDialog(
        userId: userId,
        clienteNombre: clienteNombre.toString(),
        placeId: widget.placeId,
        placeName: _placeName ?? 'El Local',
      ),
    );
  }
}
