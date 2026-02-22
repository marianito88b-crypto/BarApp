// (Crea este archivo en la carpeta 'lib/models/')

import 'package:cloud_firestore/cloud_firestore.dart';

class UnifiedPost {
  final DocumentReference reference;
  final Map<String, dynamic> map;
  final bool destacado;
  final Timestamp ts;

  UnifiedPost({
    required this.reference,
    required this.map,
    required this.destacado,
    required this.ts,
  });
}