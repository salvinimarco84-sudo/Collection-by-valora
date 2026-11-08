import 'package:flutter/material.dart';

import 'dashboard_category_object_image_fallback.dart';

/// Anteprima compatta di un oggetto nella striscia orizzontale della categoria.
class DashboardCategoryObjectPreview extends StatelessWidget {
  final String description;
  final String? imageUrl;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCategoryObjectPreview({
    super.key,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 98,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          height: 75,
          width: 98,
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: Colors.white24),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl == null
              ? DashboardCategoryObjectImageFallback(icon: icon, color: color.withValues(alpha: 0.9))
              : Image.network(
                  _valoraImageProxyUrl(imageUrl!),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => DashboardCategoryObjectImageFallback(icon: icon, color: color),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.1),
        ),
      ]),
    ),
  );
}
