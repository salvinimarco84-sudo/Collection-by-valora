import 'package:flutter/material.dart';

import 'dashboard_category_brand_mark.dart';

/// Intestazione grafica di una categoria nella dashboard della collezione.
class DashboardCategoryPanelHeader extends StatelessWidget {
  const DashboardCategoryPanelHeader({
    super.key,
    required this.category,
    required this.subtitle,
    required this.color,
    required this.fallbackIcon,
    required this.recordCount,
    required this.onViewAll,
  });

  final String category;
  final String subtitle;
  final Color color;
  final IconData fallbackIcon;
  final int recordCount;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          DashboardCategoryBrandMark(
            category: category,
            color: color,
            fallbackIcon: fallbackIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$recordCount record',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 7),
            ),
            child: const Text('VEDI TUTTI', style: TextStyle(fontSize: 10)),
          ),
        ],
      );
}
