import 'package:flutter/material.dart';

/// Widget que muestra el selector horizontal de categorías del menú
/// 
/// Diseño premium con gradientes púrpuras y efectos visuales elegantes.
class CategoryChipBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) => onCategorySelected(cat),
              selectedColor: Colors.purpleAccent.withValues(alpha: 0.9),
              backgroundColor: const Color(0xFF1E1E1E),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}
