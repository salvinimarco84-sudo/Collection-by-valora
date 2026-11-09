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
          LayoutBuilder(
            builder: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Area superiore riservata al titolo/alle scritte dello sfondo.
                // Resta ferma mentre l'elenco delle procedure scorre sotto.
                SizedBox(
                  height: constraints.maxHeight * 0.44,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: showHeader ? header : const SizedBox.shrink(),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      ...procedureCards,
                      const SizedBox(height: 12),
                      footer,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
