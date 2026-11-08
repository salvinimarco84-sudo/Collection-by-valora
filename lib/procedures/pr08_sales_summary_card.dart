part of '../main.dart';

class Pr08SalesSummaryCard extends StatelessWidget {
  const Pr08SalesSummaryCard({
    super.key,
    required this.totalSales,
    required this.selectedSales,
    required this.headerColor,
    required this.secondaryTextColor,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final int totalSales;
  final int selectedSales;
  final Color headerColor;
  final Color secondaryTextColor;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VENDITE APERTE', style: TextStyle(color: headerColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              '$totalSales vendite aperte caricate dal database TEST. Seleziona una o più righe: le altre resteranno aperte.',
              style: TextStyle(color: secondaryTextColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSelectAll,
                    icon: const Icon(Icons.select_all),
                    label: const Text('SELEZIONA TUTTE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDeselectAll,
                    child: const Text('DESELEZIONA TUTTE'),
                  ),
                ),
              ],
            ),
            Text(
              'Selezionate: $selectedSales / $totalSales',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
