import 'package:flutter/material.dart';

import 'dashboard_section_overlay.dart';

/// Contenitore visuale delle procedure di una sezione dashboard.
/// Mantiene separati sfondo, velo di contrasto, contenuto e pulsante di ritorno.
class DashboardSectionContent extends StatelessWidget {
  const DashboardSectionContent({
    super.key,
    required this.background,
    required this.header,
    required this.procedureCards,
    required this.footer,
  });

  final Widget background;
  final Widget header;
  final List<Widget> procedureCards;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: background),
          const Positioned.fill(child: DashboardSectionOverlay()),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              header,
              const SizedBox(height: 20),
              ...procedureCards,
              const SizedBox(height: 12),
              footer,
            ],
          ),
        ],
      );
}
