part of '../main.dart';

class Pr05PurchaseDetailsSection extends StatelessWidget {
  const Pr05PurchaseDetailsSection({
    super.key,
    required this.purchaseCode,
    required this.descriptionController,
    required this.dateController,
    required this.totalController,
    required this.allocated,
    required this.currentTotal,
    required this.items,
    required this.itemSummary,
    required this.onDateChanged,
    required this.onTotalChanged,
  });

  final String purchaseCode;
  final TextEditingController descriptionController;
  final TextEditingController dateController;
  final TextEditingController totalController;
  final double allocated;
  final double currentTotal;
  final List<Map<String, dynamic>> items;
  final (String, String, String) Function(Map<String, dynamic>) itemSummary;
  final VoidCallback onDateChanged;
  final VoidCallback onTotalChanged;

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label)),
      Flexible(child: Text(value, textAlign: TextAlign.end)),
    ]),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
            _line('Codice acquisto', purchaseCode),
            TextField(controller: descriptionController, readOnly: true,
              decoration: const InputDecoration(labelText: 'Descrizione acquisto · sola lettura')),
            TextField(controller: dateController,
              decoration: const InputDecoration(labelText: 'Data acquisto (AAAA-MM-GG) *'),
              onChanged: (_) => onDateChanged()),
            TextField(controller: totalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Totale acquisto (€) *'),
              onChanged: (_) => onTotalChanged()),
            _line('Somma allocazioni', '€ ${allocated.toStringAsFixed(2)}'),
            _line('Totale', '€ ${currentTotal.toStringAsFixed(2)}'),
            if ((currentTotal - allocated).abs() > 0.009)
              const Text('QUADRATURA NON VALIDA: il salvataggio è bloccato.',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            for (final item in items) Card(child: ListTile(
              title: Text(itemSummary(item).$1),
              subtitle: Text(itemSummary(item).$2),
              trailing: Text(itemSummary(item).$3),
            )),
    ],
  );
}
