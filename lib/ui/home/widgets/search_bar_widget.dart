import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final ValueChanged<String> onSearch;      // se dispara al enviar/teclear
  final VoidCallback onFilterTap;           // se dispara al tocar el icono de filtros
  final String initialQuery;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onFilterTap,
    this.initialQuery = '',
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSearch(_ctrl.text.trim());
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          // campo de búsqueda
          Expanded(
            child: TextField(
              controller: _ctrl,
              onSubmitted: (_) => _submit(),
              onChanged: widget.onSearch, // live search (si querés podés comentar esta línea y dejar solo onSubmitted)
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar bares, cafés, restaurantes…',
                hintStyle: const TextStyle(color: Colors.white54),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                prefixIcon: IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white70),
                  onPressed: _submit,
                ),
                filled: true,
                fillColor: const Color(0xFF151515),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white38),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
        ],
      ),
    );
  }
}