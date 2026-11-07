import 'package:flutter/material.dart';

import 'dashboard_block_menu_grid.dart';

/// Contenuto della dashboard in modalità a blocchi.
/// Delega la resa della griglia mantenendo invariati dati e callback ricevuti.
class DashboardHomeBlockContent extends StatelessWidget {
  const DashboardHomeBlockContent({
    super.key,
    required this.entries,
    required this.catalogLoading,
    required this.catalogCount,
    required this.imageUrlFor,
  });

  final List<Map<String, dynamic>> entries;
  final bool catalogLoading;
  final int catalogCount;
  final String? Function(String title) imageUrlFor;

  @override
  Widget build(BuildContext context) => DashboardBlockMenuGrid(
        entries: entries,
        catalogLoading: catalogLoading,
        catalogCount: catalogCount,
        imageUrlFor: imageUrlFor,
      );
}
