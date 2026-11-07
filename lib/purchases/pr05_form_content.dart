part of '../main.dart';

class Pr05EditPurchaseForm extends StatelessWidget {
  const Pr05EditPurchaseForm({
    super.key,
    required this.queryController,
    required this.dateController,
    required this.totalController,
    required this.descriptionController,
    required this.busy,
    required this.confirmed,
    required this.status,
    required this.found,
    required this.purchase,
    required this.items,
    required this.lastResult,
    required this.purchaseCode,
    required this.purchaseName,
    required this.foundSummary,
    required this.itemSummary,
    required this.allocated,
    required this.currentTotal,
    required this.onSearch,
    required this.onLoad,
    required this.onDateChanged,
    required this.onTotalChanged,
    required this.onPreview,
    required this.onSave,
    required this.onConfirmedChanged,
  });

  final TextEditingController queryController;
  final TextEditingController dateController;
  final TextEditingController totalController;
  final TextEditingController descriptionController;
  final bool busy;
  final bool confirmed;
  final String status;
  final List<Map<String, dynamic>> found;
  final Map<String, dynamic>? purchase;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? lastResult;
  final String purchaseCode;
  final String purchaseName;
  final String Function(Map<String, dynamic>) foundSummary;
  final (String, String, String) Function(Map<String, dynamic>) itemSummary;
  final double allocated;
  final double currentTotal;
  final VoidCallback onSearch;
  final ValueChanged<Map<String, dynamic>> onLoad;
  final VoidCallback onDateChanged;
  final VoidCallback onTotalChanged;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final ValueChanged<bool> onConfirmedChanged;


  @override
  Widget build(BuildContext context) {
    final color = ValoraAppearance.instance.colorFor('ACQUISTI');
    return Scaffold(
      appBar: AppBar(title: const Text('PR-05 · MODIFICA ACQUISTO')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('AMBIENTE TEST · Conserva codice acquisto e codici oggetto. Sono modificabili solo data e totale. Oggetti e descrizione restano in sola lettura. La quadratura deve restare invariata; cassa e storico sono gestiti dalla procedura SQL.'),
          )),
          Pr05PurchaseSearchSection(
            queryController: queryController,
            busy: busy,
            found: found,
            foundSummary: foundSummary,
            onSearch: onSearch,
            onLoad: onLoad,
          ),
          if (purchase != null) ...[
            const Divider(height: 24),
            Text('2 · MODIFICA SCHEDA ESISTENTE', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            Pr05PurchaseDetailsSection(
              purchaseCode: purchaseCode,
              descriptionController: descriptionController,
              dateController: dateController,
              totalController: totalController,
              allocated: allocated,
              currentTotal: currentTotal,
              items: items,
              itemSummary: itemSummary,
              onDateChanged: onDateChanged,
              onTotalChanged: onTotalChanged,
            ),
            Pr05ConfirmationSection(
              busy: busy,
              confirmed: confirmed,
              lastResult: lastResult,
              purchaseCode: purchaseCode,
              date: dateController.text.trim(),
              description: descriptionController.text.trim(),
              itemCount: items.length,
              currentTotal: currentTotal,
              allocated: allocated,
              onPreview: onPreview,
              onConfirmedChanged: onConfirmedChanged,
              onSave: onSave,
            ),
          ],
          if (busy) const LinearProgressIndicator(),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(status))),
        ]),
      ))),
    );
  }
}
