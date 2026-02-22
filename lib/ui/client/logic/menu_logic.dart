import 'package:flutter/material.dart';

/// Mixin que contiene la lógica de negocio para el menú del cliente
///
/// Requiere que la clase que lo use implemente:
/// - Método: setState (de State)
mixin ClientMenuLogicMixin<T extends StatefulWidget> on State<T> {
  // Estado local del carrito
  final Map<String, Map<String, dynamic>> cart = {};
  String selectedCategory = 'Todos';

  // Orden de prioridad para mostrar las categorías (Lo que no esté aquí, va al final alfabéticamente)
  final List<String> categoryOrder = [
    'Entradas',
    'Minutas',
    'Hamburguesas',
    'Pizzas',
    'Platos Principales',
    'Postres',
    'Bebidas Sin Alcohol',
    'Cervezas',
    'Tragos',
    'Vinos',
  ];

  /// Ordena las categorías disponibles según la prioridad definida
  /// 
  /// - 'Todos' siempre va primero
  /// - Las categorías en categoryOrder mantienen su orden
  /// - Las categorías custom van al final en orden alfabético
  List<String> sortCategories(Set<String> availableCategories) {
    List<String> sortedCategories = availableCategories.toList();

    sortedCategories.sort((a, b) {
      if (a == 'Todos') return -1; // Todos siempre primero
      if (b == 'Todos') return 1;

      int indexA = categoryOrder.indexOf(a);
      int indexB = categoryOrder.indexOf(b);

      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB); // Ambas en lista
      }
      if (indexA != -1) return -1; // Solo A en lista
      if (indexB != -1) return 1; // Solo B en lista
      return a.compareTo(b); // Ninguna en lista, orden alfabético
    });

    return sortedCategories;
  }

  /// Agrega un producto al carrito o incrementa su cantidad
  void addToCart(String prodId, Map<String, dynamic> data) {
    setState(() {
      if (cart.containsKey(prodId)) {
        cart[prodId]!['cantidad']++;
      } else {
        // Usamos ?? false para que si el campo no existe en Firebase, no rompa la app
        bool controla = data['controlaStock'] ?? false;

        cart[prodId] = {
          'nombre': data['nombre'] ?? 'Producto',
          'precio': data['precio'] ?? 0,
          'cantidad': 1,
          'producto_id': prodId,
          'controlaStock': controla, // <--- Aquí pasamos el booleano
        };
      }
    });
  }

  /// Remueve un producto del carrito o decrementa su cantidad
  void removeFromCart(String prodId) {
    setState(() {
      if (cart.containsKey(prodId)) {
        if (cart[prodId]!['cantidad'] > 1) {
          cart[prodId]!['cantidad']--;
        } else {
          cart.remove(prodId);
        }
      }
    });
  }

  /// Obtiene la cantidad de un producto en el carrito
  int getQuantityInCart(String prodId) {
    return cart[prodId]?['cantidad'] ?? 0;
  }

  /// Verifica si la categoría seleccionada sigue existiendo y la ajusta si es necesario
  void validateSelectedCategory(List<String> sortedCategories) {
    if (!sortedCategories.contains(selectedCategory)) {
      setState(() {
        selectedCategory = 'Todos';
      });
    }
  }
}
