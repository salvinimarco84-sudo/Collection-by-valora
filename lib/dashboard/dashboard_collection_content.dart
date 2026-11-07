part of '../main.dart';

/// Maschera grafica autonoma del blocco COLLEZIONE.
/// I dati e la navigazione restano coordinati da HomeDashboard.
class DashboardCollectionContent extends StatelessWidget {
  const DashboardCollectionContent({
    super.key,
    required this.catalogLoading,
    required this.catalogError,
    required this.catalogRows,
    required this.categories,
    required this.categoryCounts,
    required this.categoryFor,
    required this.imageUrlFor,
    required this.onCategoryTap,
  });

  final bool catalogLoading;
  final String? catalogError;
  final List<Map<String, dynamic>> catalogRows;
  final List<Map<String, dynamic>> categories;
  final Map<String, int> categoryCounts;
  final String Function(Map<String, dynamic>) categoryFor;
  final String? Function(Map<String, dynamic>) imageUrlFor;
  final void Function(String name, String code) onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final sortedCategories = List<Map<String, dynamic>>.from(categories);
    sortedCategories.sort((a, b) {
      final codeA = (a['codice_categoria'] ?? '').toString();
      final codeB = (b['codice_categoria'] ?? '').toString();
      final countA = categoryCounts[codeA] ?? 0;
      final countB = categoryCounts[codeB] ?? 0;
      final byCount = countB.compareTo(countA);
      if (byCount != 0) return byCount;
      final orderA = int.tryParse((a['ordine_menu'] ?? '').toString()) ?? 999999;
      final orderB = int.tryParse((b['ordine_menu'] ?? '').toString()) ?? 999999;
      final byOrder = orderA.compareTo(orderB);
      if (byOrder != 0) return byOrder;
      return (a['descrizione'] ?? '').toString().compareTo((b['descrizione'] ?? '').toString());
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        DashboardCollectionHeader(
          title: ValoraI18n.tr('COLLEZIONE'),
          subtitle: ValoraI18n.tr('Seleziona un tema per consultare i relativi oggetti.'),
          countLabel: catalogLoading ? '…' : '${catalogRows.length}',
        ),
        if (catalogError != null)
          DashboardCollectionErrorBanner(message: 'Catalogo non disponibile: $catalogError'),
        if (!catalogLoading) ...[
          if (categories.isEmpty) const DashboardCollectionEmptyNotice(),
          ...sortedCategories.map((category) {
            final name = (category['descrizione'] ?? '').toString();
            final hex = (category['colore_hex'] ?? '#D6B15E').toString().replaceFirst('#', '');
            final parsed = int.tryParse(hex, radix: 16) ?? 0xD6B15E;
            final color = Color(0xFF000000 | parsed);
            final rawIcon = (category['icona'] ?? '').toString();
            final icon = rawIcon.contains('extension') ? Icons.extension
                : rawIcon.contains('menu_book') ? Icons.menu_book_outlined
                : rawIcon.contains('two_wheeler') ? Icons.two_wheeler
                : rawIcon.contains('shield') ? Icons.shield_outlined
                : rawIcon.contains('smart_toy') ? Icons.smart_toy_outlined
                : Icons.category_outlined;
            final code = (category['codice_categoria'] ?? '').toString();
            final count = categoryCounts[code] ?? 0;
            final categoryKey = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
            final previewRows = catalogRows.where((row) {
              final categoryKeyForRow = categoryFor(row).toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
              final rawCategory = (row['categoria'] ?? row['codice_categoria'] ?? '')
                  .toString().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
              return categoryKeyForRow == categoryKey || rawCategory == categoryKey;
            }).take(5).toList();

            return DashboardCollectionCategoryCard(
              code: code,
              name: name,
              subtitle: 'Apri la categoria e consulta gli oggetti',
              color: color,
              icon: icon,
              count: count,
              logoUrl: (category['logo_url'] ?? '').toString(),
              previewImageUrls: previewRows.map(imageUrlFor).toList(),
              onTap: () => onCategoryTap(name, code),
            );
          }),
        ],
      ],
    );
  }
}
