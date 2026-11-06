import 'package:flutter/material.dart';

import 'dashboard_category_object_preview.dart';

/// Elenco orizzontale dei record in anteprima nella scheda categoria.
class DashboardCategoryPreviewList extends StatelessWidget {
  const DashboardCategoryPreviewList({
    super.key,
    required this.rows,
    required this.icon,
    required this.color,
    required this.descriptionFor,
    required this.imageUrlFor,
    required this.onObjectTap,
  });

  final List<Map<String, dynamic>> rows;
  final IconData icon;
  final Color color;
  final String Function(Map<String, dynamic>) descriptionFor;
  final String? Function(Map<String, dynamic>) imageUrlFor;
  final ValueChanged<Map<String, dynamic>> onObjectTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 118,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: rows.length > 5 ? 5 : rows.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final row = rows[index];
            return DashboardCategoryObjectPreview(
              description: descriptionFor(row),
              imageUrl: imageUrlFor(row),
              icon: icon,
              color: color,
              onTap: () => onObjectTap(row),
            );
          },
        ),
      );
}
