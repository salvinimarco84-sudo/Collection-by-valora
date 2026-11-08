import 'package:flutter/material.dart';
import '../utils/valora_image_proxy.dart';

/// Striscia orizzontale delle immagini di anteprima di una categoria.
class DashboardCollectionCategoryPreviewStrip extends StatelessWidget {
  const DashboardCollectionCategoryPreviewStrip({
    super.key,
    required this.imageUrls,
    required this.icon,
    required this.color,
  });

  final List<String?> imageUrls;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 86,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          scrollDirection: Axis.horizontal,
          itemCount: imageUrls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final url = imageUrls[index];
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
                        valoraImageProxyUrl(url),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 30),
                      ),
              ),
            );
          },
        ),
      );
}
