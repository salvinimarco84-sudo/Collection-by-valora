import 'package:flutter/material.dart';

class DashboardSectionFooter extends StatelessWidget {
  const DashboardSectionFooter({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onPressed,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor.withValues(alpha: 0.55)),
      ),
      child: Text(label),
    );
  }
}
