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

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label)),
      Flexible(child: Text(value, textAlign: TextAlign.end)),
    ]),
  );

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
            FilledButton(onPressed: busy ? null : onPreview, child: const Text('MOSTRA RIEPILOGO')),
            if (lastResult != null) Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('RIEPILOGO MODIFICA', style: TextStyle(fontWeight: FontWeight.bold)),
                _line('Codice acquisto', purchaseCode),
                _line('Data', dateController.text.trim()),
                _line('Descrizione', descriptionController.text.trim()),
                _line('Oggetti collegati', items.length.toString()),
                _line('Totale acquisto', '€ ${currentTotal.toStringAsFixed(2)}'),
                _line('Somma allocazioni', '€ ${allocated.toStringAsFixed(2)}'),
                const Text('I codici degli oggetti collegati vengono conservati. Il salvataggio aggiorna cassa e storico tramite runtime.'),
              ]),
            )),
            CheckboxListTile(
              value: confirmed,
              title: const Text('Confermo il riepilogo e autorizzo il salvataggio.'),
              onChanged: busy || lastResult == null ? null : (v) => onConfirmedChanged(v ?? false),
            ),
            FilledButton(
              onPressed: busy || !confirmed || lastResult == null ? null : onSave,
              child: Text(busy ? 'ATTENDI…' : 'SALVA MODIFICA E TERMINA'),
            ),
          ],
          if (busy) const LinearProgressIndicator(),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(status))),
        ]),
      ))),
    );
  }
}
