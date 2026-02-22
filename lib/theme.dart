import 'package:flutter/material.dart';
import 'package:barapp/models/categories.dart'; // 👈 Importa tu enum

/// 1. FUNCIÓN PRINCIPAL DEL TEMA
ThemeData buildBaseTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    
    // 🌑 CAMBIO 1: Negro Profundo (Casi OLED)
    primaryColor: const Color(0xFF050505),
    scaffoldBackgroundColor: const Color(0xFF050505), 
    
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF7F50), // Naranja Coral
      secondary: Colors.indigoAccent,
      surface: Color(0xFF151515), // Las tarjetas un pelín más claras
    ),

    // Estilos de botones
  filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFFF7F50),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    
    // Estilo de la barra de navegación (la nueva)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF151515),
      indicatorColor: const Color(0xFFFF7F50),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    ),

    // Estilo de los íconos
    iconTheme: const IconThemeData(color: Colors.white70),
    
    // Estilo del texto
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}


/// 2. HELPER DE ETIQUETAS
String labelForCategory(Category category) {
  switch (category) {
    case Category.todos:
      return 'Todos';
    case Category.bar:
      return 'Bares';
    case Category.cerveceria:
      return 'Cervecerías';
    case Category.pub:
      return 'Pubs';
    case Category.restaurants:
      return 'Restaurantes';
    case Category.cafes:
      return 'Cafés';
    case Category.icecream:
      return 'Heladerías';
  }
}

/// 3. HELPER DE ÍCONOS
IconData iconForCategory(Category category) {
  switch (category) {
    case Category.todos:
      return Icons.store_rounded;
    case Category.bar:
      return Icons.nightlife_rounded;
    case Category.cerveceria:
      return Icons.sports_bar_rounded; // 👈 ¡El ícono para la nueva categoría!
    case Category.pub:
      return Icons.music_note_rounded;
    case Category.restaurants:
      return Icons.restaurant_rounded;
    case Category.cafes:
      return Icons.coffee_rounded;
    case Category.icecream:
      return Icons.icecream_rounded;
  }
}

/// 4. HELPER DE COLORES
/// 4. HELPER DE COLORES (UNIFICADO)
Color colorForCategory(Category category) {
  // Ahora devolvemos SIEMPRE tu naranja coral de marca.
  // Esto genera consistencia visual profesional.
  return const Color(0xFFFF7F50); 
}