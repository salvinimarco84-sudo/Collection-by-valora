import 'package:flutter/material.dart';

import 'dashboard_home_footer.dart';

/// Contenuto della dashboard in modalità lista.
/// Mantiene ordine, spaziatura e widget ricevuti dalla schermata principale.
class DashboardHomeListContent extends StatelessWidget {
  const DashboardHomeListContent({
    super.key,
    required this.header,
    required this.collectionCard,
    required this.sectionCards,
    required this.catalogError,
    required this.footer,
  });

  final Widget header;
  final Widget collectionCard;
  final List<Widget> sectionCards;
  final Widget? catalogError;
  final Widget footer;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          header,
          collectionCard,
          ...sectionCards,
          if (catalogError != null) catalogError!,
          const SizedBox(height: 12),
          footer,
        ],
      );
}
