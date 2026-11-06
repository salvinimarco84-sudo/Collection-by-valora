import 'package:flutter/material.dart';

/// Velo di contrasto applicato sopra lo sfondo delle sezioni dashboard.
/// Non intercetta i tocchi e non modifica l'immagine o il tema sottostante.
class DashboardSectionOverlay extends StatelessWidget {
  const DashboardSectionOverlay({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
        child: ColoredBox(
          color: Color.fromRGBO(0, 0, 0, 0.22),
        ),
      );
}
