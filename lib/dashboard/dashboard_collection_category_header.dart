import 'package:flutter/material.dart';

import 'dashboard_category_brand_mark.dart';

/// Intestazione della scheda categoria con marchio, descrizione e conteggio.
class DashboardCollectionCategoryHeader extends StatelessWidget {
  const DashboardCollectionCategoryHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.count,
    required this.onTap,
    this.logoUrl,
  });

  final String name;
  final String subtitle;
  final Color color;
  final IconData icon;
  final int count;
  final String? logoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: (logoUrl ?? '').trim().isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.network(
                  logoUrl!,
                  width: 62,
                  height: 46,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DashboardCategoryBrandMark(
                    category: name,
                    color: color,
                    fallbackIcon: icon,
                  ),
                ),
              )
            : DashboardCategoryBrandMark(
                category: name,
                color: color,
                fallbackIcon: icon,
              ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
        onTap: onTap,
      );
}
