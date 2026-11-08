import 'package:flutter/material.dart';

class DashboardGridMenuCard extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final String? imageUrl;
  final BoxFit imageFit;
  final String? footerText;

  const DashboardGridMenuCard({
    super.key,
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.imageUrl,
    required this.imageFit,
    this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          _valoraImageProxyUrl(imageUrl!),
                          fit: imageFit,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              Icon(icon, color: color, size: 42),
                        )
                      : Icon(icon, color: color, size: 42),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (footerText != null)
                Text(
                  footerText!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              Icon(Icons.chevron_right, color: color, size: 23),
            ],
          ),
        ),
      ),
    );
  }
}
