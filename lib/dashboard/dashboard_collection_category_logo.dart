import 'package:flutter/material.dart';
import '../utils/valora_image_proxy.dart';

import 'dashboard_category_brand_mark.dart';

/// Logo della categoria con ripiego sul marchio grafico se l'immagine non è disponibile.
class DashboardCollectionCategoryLogo extends StatelessWidget {
  const DashboardCollectionCategoryLogo({
    super.key,
    required this.category,
    required this.color,
    required this.fallbackIcon,
    this.logoUrl,
  });

  final String category;
  final Color color;
  final IconData fallbackIcon;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) => (logoUrl ?? '').trim().isNotEmpty
      ? ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Image.network(
            valoraImageProxyUrl(logoUrl!),
            width: 62,
            height: 46,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => DashboardCategoryBrandMark(
              category: category,
              color: color,
              fallbackIcon: fallbackIcon,
            ),
          ),
        )
      : DashboardCategoryBrandMark(
          category: category,
          color: color,
          fallbackIcon: fallbackIcon,
        );
}
