import 'package:flutter/material.dart';

/// Banner grafico mostrato quando il catalogo della collezione non è disponibile.
class DashboardCollectionErrorBanner extends StatelessWidget {
  const DashboardCollectionErrorBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B1717),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      );
}
