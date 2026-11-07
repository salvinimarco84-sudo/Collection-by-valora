import 'package:flutter/material.dart';

import 'dashboard_collection_category_header.dart';
import 'dashboard_collection_category_preview_strip.dart';

/// Scheda categoria della collezione, con logo e anteprime degli oggetti.
class DashboardCollectionCategoryCard extends StatelessWidget {
  const DashboardCollectionCategoryCard({
    super.key,
    required this.code,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.count,
    required this.previewImageUrls,
    required this.onTap,
    this.logoUrl,
  });

  final String code;
  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;
  final int count;
  final String? logoUrl;
  final List<String?> previewImageUrls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.75)),
        ),
        child: Column(
          children: [
            DashboardCollectionCategoryHeader(
              name: name,
              subtitle: subtitle,
              color: color,
              icon: icon,
              count: count,
              logoUrl: logoUrl,
              onTap: onTap,
            ),
            if (previewImageUrls.isNotEmpty)
              DashboardCollectionCategoryPreviewStrip(
                imageUrls: previewImageUrls,
                icon: icon,
                color: color,
              ),
          ],
        ),
      );

}
