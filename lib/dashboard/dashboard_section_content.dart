import 'package:flutter/material.dart';

import 'dashboard_section_overlay.dart';

/// Contenitore visuale delle procedure di una sezione dashboard.
/// Mantiene separati sfondo, velo di contrasto, contenuto e pulsante di ritorno.
class DashboardSectionContent extends StatelessWidget {
  const DashboardSectionContent({
    super.key,
    required this.background,
    required this.header,
    this.showHeader = true,
    required this.procedureCards,
    required this.footer,
  });

  final Widget background;
  final Widget header;
  final bool showHeader;
  final List<Widget> procedureCards;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: background),
          const Positioned.fill(child: DashboardSectionOverlay()),
          ListView(
            padding: EdgeInsets.fromLTRB(16, showHeader ? 20 : 8, 16, 28),
            children: [
              if (showHeader) ...[
                header,
                const SizedBox(height: 20),
              ]
              ...procedureCards,
              const SizedBox(height: 12),
              footer,
            ],
          ),
        ],
      );
}
