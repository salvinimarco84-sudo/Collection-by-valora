import 'package:flutter/material.dart';

import 'dashboard_category_brand_mark.dart';

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
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              leading: (logoUrl ?? '').trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.network(
                        logoUrl!,
                        width: 62,
                        height: 46,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => DashboardCategoryBrandMark(category: name, color: color, fallbackIcon: icon),
                      ),
                    )
                  : DashboardCategoryBrandMark(category: name, color: color, fallbackIcon: icon),
              title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
              onTap: onTap,
            ),
            if (previewImageUrls.isNotEmpty)
              SizedBox(
                height: 86,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: previewImageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final url = previewImageUrls[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: url == null
                            ? Icon(icon, color: color, size: 30)
                            : Image.network(
                                url,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 30),
                              ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );

}
