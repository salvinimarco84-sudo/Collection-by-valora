import 'package:flutter/material.dart';

class DashboardSectionBackground extends StatelessWidget {
  const DashboardSectionBackground({
    super.key,
    required this.customImage,
    required this.backgroundAsset,
    required this.backgroundColor,
    required this.imageUrlResolver,
  });

  final String? customImage;
  final String backgroundAsset;
  final Color backgroundColor;
  final String Function(String) imageUrlResolver;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: customImage != null && customImage!.isNotEmpty
        ? Image.network(
            imageUrlResolver(customImage!),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => backgroundAsset.isNotEmpty
                ? Image.asset(
                    backgroundAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(color: backgroundColor),
                  )
                : ColoredBox(color: backgroundColor),
          )
        : backgroundAsset.isNotEmpty
            ? Image.asset(
                backgroundAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => ColoredBox(color: backgroundColor),
              )
            : ColoredBox(color: backgroundColor),
  );
}
