import 'package:flutter/material.dart';

class FiltersBottomSheet extends StatefulWidget {
  final Function(List<String> selectedFilters) onApply;
  final List<String> initialSelected;

  const FiltersBottomSheet({
    super.key,
    required this.onApply,
    required this.initialSelected,
  });

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  late List<String> selected;

  final List<String> allFilters = const [
    'Abiertos ahora',
    'Con música en vivo',
    'Terraza',
    'Delivery',
    'Happy hour',
    'Acepta reservas',
  ];

  @override
  void initState() {
    super.initState();
    selected = List.from(widget.initialSelected);
  }

  void toggle(String filter) {
    setState(() {
      if (selected.contains(filter)) {
        selected.remove(filter);
      } else {
        selected.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allFilters.map((f) {
                final isSelected = selected.contains(f);
                return FilterChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) => toggle(f),
                  selectedColor: Colors.green.withValues(alpha: .3),
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? Colors.greenAccent : Colors.white30,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onApply(selected);
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}