import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../logic/staff_logic.dart';
import '../layouts/staff/staff_mobile_layout.dart';
import '../layouts/staff/staff_desktop_layout.dart';

class StaffMobile extends StatefulWidget {
  final String placeId;
  const StaffMobile({super.key, required this.placeId});

  @override
  State<StaffMobile> createState() => _StaffMobileState();
}

class _StaffMobileState extends State<StaffMobile> with StaffLogicMixin {
  @override
  String get placeId => widget.placeId;

  late final Stream<QuerySnapshot> _staffStream;

  @override
  void initState() {
    super.initState();
    _staffStream = getStaffStream();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return StaffDesktopLayout(
            placeId: widget.placeId,
            staffStream: _staffStream,
            onDelete: confirmarEliminar,
          );
        } else {
          return StaffMobileLayout(
            placeId: widget.placeId,
            staffStream: _staffStream,
            onDelete: confirmarEliminar,
          );
        }
      },
    );
  }
}