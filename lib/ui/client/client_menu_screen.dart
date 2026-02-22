import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'client_checkout_screen.dart';
import 'widgets/menu/category_chip_bar.dart';
import 'widgets/menu/client_product_item.dart';
import 'widgets/menu/cart_bottom_bar.dart';
import 'logic/menu_logic.dart';
import 'package:barapp/utils/venue_utils.dart';

class ClientMenuScreen extends StatefulWidget {
  final String placeId;
  final String? mesaId;

  const ClientMenuScreen({super.key, required this.placeId, this.mesaId});

  @override
  State<ClientMenuScreen> createState() => _ClientMenuScreenState();
}

class _ClientMenuScreenState extends State<ClientMenuScreen>
    with ClientMenuLogicMixin {

  @override
  Widget build(BuildContext context) {
    // 1. PRIMERO VERIFICAMOS EL ESTADO DEL LOCAL (Apertura/Cierre)
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .snapshots(),
      builder: (context, placeSnapshot) {
        // Pantalla de carga mientras conecta
        if (!placeSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          );
        }

        final placeData = placeSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        // Verificar si el local está abierto usando VenueUtils
        final isOpen = VenueUtils.isVenueOpen(placeData);
        
        // Si está cerrado, mostrar pantalla de cierre
        if (!isOpen) {
          return _buildClosedScreen(placeData);
        }

        // 2. SI ESTÁ ABIERTO, CARGAMOS EL MENÚ
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('places')
              .doc(widget.placeId)
              .collection('menu')
              .snapshots(),
          builder: (context, menuSnapshot) {
            // Pantalla de carga mientras conecta
            if (!menuSnapshot.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFF121212),
                body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
              );
            }

            final docs = menuSnapshot.data!.docs;
            
            // 3. PROCESAMOS LAS CATEGORÍAS DISPONIBLES EN TIEMPO REAL
            Set<String> availableCategories = {'Todos'};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['categoria'] != null) {
                availableCategories.add(data['categoria']);
              }
            }

            // Ordenamos las categorías usando el Mixin
            List<String> sortedCategories = sortCategories(availableCategories);

            // Verificamos que la categoría seleccionada siga existiendo (por si borran productos)
            validateSelectedCategory(sortedCategories);

            // Obtener horarios formateados para mostrar en la cabecera
            final formattedHours = VenueUtils.getFormattedHours(placeData);

            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: 140.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF1E1E1E),
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Menú Digital",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedHours,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.deepPurple.shade900, const Color(0xFF121212)],
                              ),
                            ),
                          ),
                          const Center(child: Icon(Icons.restaurant, size: 50, color: Colors.white10)),
                        ],
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white70),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
                body: Column(
                  children: [
                    // Pasamos las categorías procesadas al selector
                    CategoryChipBar(
                      categories: sortedCategories,
                      selectedCategory: selectedCategory,
                      onCategorySelected: (cat) {
                        setState(() {
                          selectedCategory = cat;
                        });
                      },
                    ),
                    
                    // Pasamos los docs y las categorías ordenadas a la lista
                    Expanded(child: _buildProductList(docs, sortedCategories)),
                  ],
                ),
              ),
              bottomNavigationBar: cart.isNotEmpty
                  ? CartBottomBar(
                      cart: cart,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientCheckoutScreen(
                              placeId: widget.placeId,
                              cart: cart,
                            ),
                          ),
                        );
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }


  // ---------------------------------------------------------------------------
  // 🍔 LISTA DE PRODUCTOS (Lógica de Agrupación Visual)
  // ---------------------------------------------------------------------------
  Widget _buildProductList(List<QueryDocumentSnapshot> docs, List<String> sortedCats) {
    if (docs.isEmpty) {
      return const Center(child: Text("El menú está vacío", style: TextStyle(color: Colors.white54)));
    }

    // 1. Si hay filtro específico, mostramos lista simple
    if (selectedCategory != 'Todos') {
      final filteredDocs = docs.where((d) => d['categoria'] == selectedCategory).toList();
      if (filteredDocs.isEmpty) return const Center(child: Text("No hay items aquí", style: TextStyle(color: Colors.white54)));
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredDocs.length,
        itemBuilder: (context, index) => _buildProductItem(filteredDocs[index]),
      );
    }

    // 2. Si es 'Todos', agrupamos respetando el orden de sortedCats
    Map<String, List<QueryDocumentSnapshot>> groupedMenu = {};
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      String cat = data['categoria'] ?? 'Varios';
      if (!groupedMenu.containsKey(cat)) groupedMenu[cat] = [];
      groupedMenu[cat]!.add(doc);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, left: 16, right: 16, top: 10),
      itemCount: sortedCats.length, // Usamos la lista ordenada
      itemBuilder: (context, index) {
        String categoryName = sortedCats[index];
        if (categoryName == 'Todos') return const SizedBox.shrink(); // Saltamos el tab 'Todos'
        
        List<QueryDocumentSnapshot>? products = groupedMenu[categoryName];
        if (products == null || products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER POTENTE
            _buildCategoryHeader(categoryName),
            
            // LISTA DE PRODUCTOS
            ...products.map((doc) => _buildProductItem(doc)),
            
            // ESPACIO PARA RESPIRAR
            const SizedBox(height: 24), 
          ],
        );
      },
    );
  }

  // ✨ Widget Visual para el Título de la Categoría (MÁS PRO)
  Widget _buildCategoryHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4, 
            height: 24, 
            decoration: BoxDecoration(
              color: Colors.purpleAccent, 
              borderRadius: BorderRadius.circular(2)
            )
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.purpleAccent, // Color llamativo
              fontSize: 22,
              fontWeight: FontWeight.w900, // Extra bold
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purpleAccent.withValues(alpha: 0.5), Colors.transparent]
                )
              ),
            )
          ),
        ],
      ),
    );
  }

  // 📦 Widget Individual del Producto
  Widget _buildProductItem(QueryDocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String prodId = doc.id;
    int qtyInCart = getQuantityInCart(prodId);

    return ClientProductItem(
      doc: doc,
      quantityInCart: qtyInCart,
      onAddToCart: () => addToCart(prodId, data),
      onRemoveFromCart: () => removeFromCart(prodId),
    );
  }

  /// Pantalla que se muestra cuando el local está cerrado
  Widget _buildClosedScreen(Map<String, dynamic> placeData) {
    final placeName = placeData['nombre'] ?? 'El local';
    final formattedHours = VenueUtils.getFormattedHours(placeData);
    final statusMessage = VenueUtils.getVenueStatusMessage(placeData);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text(
          "Local Cerrado",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  size: 80,
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "$placeName está cerrado",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                statusMessage,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.purpleAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Horarios de atención",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formattedHours,
                      style: const TextStyle(
                        color: Colors.purpleAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}