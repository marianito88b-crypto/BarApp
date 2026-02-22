import 'package:flutter/material.dart';

/// Widget que muestra un estado vacío cuando no hay miembros del staff
class StaffEmptyState extends StatelessWidget {
  final String message;

  const StaffEmptyState({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.groups_outlined,
            size: 80,
            color: Colors.white10,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
