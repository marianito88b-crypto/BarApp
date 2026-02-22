// lib/ui/home/widgets/place_card_assets.dart
import 'package:barapp/models/categories.dart';
import 'package:barapp/models/place.dart';

/// Si estás en el tab "Todos", devuelve un asset según la/s categoría/s del lugar.
/// Si pasás `selectedTab`, fuerza ese asset (uniforma las tarjetas dentro del tab).
String assetForPlace(Place p, {Category? selectedTab}) {
  // Si hay tab seleccionado (≠ todos), forzamos ese asset
  if (selectedTab != null && selectedTab != Category.todos) {
    return _assetForCategoryEnum(selectedTab);
  }

  // Sin tab seleccionado (o es "todos"): usamos la primaria del lugar
  final primary = _primaryCategoryOf(p);
  return _assetForCategoryEnum(primary);
}

/// Decide la categoría "principal" del lugar:
/// 1) Si incluye bar/pub/cervecería, prioriza bar (más visualmente representativo)
/// 2) Si incluye restaurante, luego cafetería, luego heladería
/// 3) Si no hay nada, vuelve a `todos`
Category _primaryCategoryOf(Place p) {
  final cats = p.categories;

  bool has(Category c) => cats.contains(c);

  if (has(Category.bar) || has(Category.pub) || has(Category.cerveceria)) {
    return Category.bar; // agrupamos nocturnos bajo bar
  }
  if (has(Category.restaurants)) return Category.restaurants;
  if (has(Category.cafes)) return Category.cafes;
  if (has(Category.icecream)) return Category.icecream;

  return Category.todos;
}

/// Enum → asset local (estandaricemos nombres de archivos)
String _assetForCategoryEnum(Category c) {
  switch (c) {
    case Category.restaurants:
      return 'assets/places/restaurantes.png';
    case Category.bar: // también representa pub/cervecería cuando se agrupan
      return 'assets/places/bar.png';
    case Category.cafes:
      return 'assets/places/cafes.png';
    case Category.icecream:
      return 'assets/places/heladerias.png';
    case Category.pub:
      return 'assets/places/pub.png';
    case Category.cerveceria:
      return 'assets/places/cerveceria.png';
    case Category.todos:
      return 'assets/places/restaurantes.png'; // fallback
  }
}