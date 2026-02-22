import 'package:flutter/material.dart';

/// Widget que muestra un encabezado de categoría con estilo neón
class CategoryHeader extends StatelessWidget {
  final String title;

  const CategoryHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, top: 5),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white10,
            ),
          ),
        ],
      ),
    );
  }
}
