import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../logic/menu_logic.dart';
import '../layouts/menu/menu_mobile_layout.dart';
import '../layouts/menu/menu_desktop_layout.dart';

class MenuMobile extends StatefulWidget {
  final String placeId;
  const MenuMobile({super.key, required this.placeId});

  @override
  State<MenuMobile> createState() => _MenuMobileState();
}

class _MenuMobileState extends State<MenuMobile> with MenuLogicMixin {
  @override
  String get placeId => widget.placeId;

  late final Stream<QuerySnapshot> _menuStream;

  @override
  void initState() {
    super.initState();
    _menuStream = getMenuStream();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "fab_menu_mobile",
            onPressed: () => showProductEditor(),
            backgroundColor: Colors.orangeAccent,
            icon: Icon(
              isDesktop ? Icons.add : Icons.add_a_photo,
              color: Colors.black,
            ),
            label: Text(
              isDesktop ? "Agregar Producto" : "Nuevo Plato",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: isDesktop
              ? MenuDesktopLayout(
                  placeId: placeId,
                  menuStream: _menuStream,
                  onEditProduct: (docId, data) => showProductEditor(
                    docId: docId,
                    data: data,
                  ),
                  onDeleteProduct: eliminarProducto,
                )
              : MenuMobileLayout(
                  placeId: placeId,
                  menuStream: _menuStream,
                  onEditProduct: (docId, data) => showProductEditor(
                    docId: docId,
                    data: data,
                  ),
                  onDeleteProduct: eliminarProducto,
                ),
        );
      },
    );
  }
}

