import 'package:flutter/material.dart';

import 'dashboard_category_panel_header.dart';

class DashboardCategoryPanel extends StatelessWidget {
  const DashboardCategoryPanel({
    super.key,
    required this.category,
    required this.subtitle,
    required this.color,
    required this.fallbackIcon,
    required this.recordCount,
    required this.onViewAll,
    required this.child,
  });

  final String category;
  final String subtitle;
  final Color color;
  final IconData fallbackIcon;
  final int recordCount;
  final VoidCallback onViewAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardCategoryPanelHeader(
              category: category,
              subtitle: subtitle,
              color: color,
              fallbackIcon: fallbackIcon,
              recordCount: recordCount,
              onViewAll: onViewAll,
            ),
            child,
          ],
        ),
      ),
    );
  }
}
