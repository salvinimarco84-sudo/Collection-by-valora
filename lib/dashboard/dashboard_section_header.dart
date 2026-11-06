import 'package:flutter/material.dart';

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.secondaryTextColor,
  });

  final String title;
  final String description;
  final Color accentColor;
  final Color secondaryTextColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: accentColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        description,
        textAlign: TextAlign.center,
        style: TextStyle(color: secondaryTextColor),
      ),
    ],
  );
}
