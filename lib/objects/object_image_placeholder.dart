import 'package:flutter/material.dart';

/// Segnaposto uniforme per immagini oggetto non disponibili.
class ObjectImagePlaceholder extends StatelessWidget {
  const ObjectImagePlaceholder({
    super.key,
    this.size = 88,
    required this.backgroundColor,
    required this.iconColor,
  });

  final double size;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: iconColor,
          size: 30,
        ),
      );
}
