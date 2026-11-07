import 'package:flutter/material.dart';

import 'dashboard_grid_menu_card.dart';

/// Griglia responsiva delle schede principali della dashboard.
class DashboardBlockMenuGrid extends StatelessWidget {
  const DashboardBlockMenuGrid({
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 600
                  ? 3
                  : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: entries.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: constraints.maxWidth < 600 ? 0.98 : 1.18,
            ),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final title = entry['title'] as String;
              final sectionKey = (entry['sectionKey'] ?? title).toString();
              final color = entry['color'] as Color;
              final icon = entry['icon'] as IconData;
              return DashboardGridMenuCard(
                title: title,
                color: color,
                icon: icon,
                onTap: entry['tap'] as VoidCallback,
                imageUrl: imageUrlFor(title),
                imageFit: (sectionKey == 'RICERCHE' || sectionKey == 'VALUTAZIONI')
                    ? BoxFit.cover
                    : BoxFit.contain,
                footerText: title == 'COLLEZIONE'
                    ? (catalogLoading ? '…' : '$catalogCount record')
                    : null,
              );
            },
          );
        },
      );
}
