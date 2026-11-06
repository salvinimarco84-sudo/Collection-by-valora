import 'package:flutter/material.dart';

/// Intestazione grafica della pagina Collezione.
class DashboardCollectionHeader extends StatelessWidget {
  const DashboardCollectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.countLabel,
  });

  final String title;
  final String subtitle;
  final String countLabel;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFFD6B15E), size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFD6B15E),
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              countLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}
