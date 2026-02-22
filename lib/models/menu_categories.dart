// lib/models/menu_categories.dart

class MenuCategories {
  // Esta es la lista oficial. Nadie puede inventar categorías nuevas.
  static const List<String> list = [
    "Entradas",
    "Principales",
    "Hamburguesas",
    "Pizzas",
    "Ensaladas",
    "Postres",
    "Bebidas sin Alcohol",
    "Cervezas",
    "Vinos",
    "Tragos",
    "Cafetería",
    "Promociones"
  ];

  // Helper para el chip "Todos" en el filtro del cliente
  static const String all = "Todos";
}