import 'package:flutter/material.dart';

/// Fallback grafico uniforme per un'immagine oggetto non disponibile.
class DashboardCategoryObjectImageFallback extends StatelessWidget {
  const DashboardCategoryObjectImageFallback({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Icon(
        icon,
        color: color,
        size: 34,
      );
}
