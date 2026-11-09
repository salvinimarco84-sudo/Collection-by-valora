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
        ? Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Image.network(
                imageUrlResolver(customImage!),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => ColoredBox(color: backgroundColor),
              ),
              Image.network(
                imageUrlResolver(customImage!),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ],
          )
        : backgroundAsset.isNotEmpty
            ? Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    backgroundAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => ColoredBox(color: backgroundColor),
                  ),
                  Image.asset(
                    backgroundAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              )
            : ColoredBox(color: backgroundColor),
  );
}
