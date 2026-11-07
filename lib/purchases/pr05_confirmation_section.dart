part of '../main.dart';

class Pr05ConfirmationSection extends StatelessWidget {
  const Pr05ConfirmationSection({
    super.key,
    required this.busy,
    required this.confirmed,
    required this.lastResult,
    required this.purchaseCode,
    required this.date,
    required this.description,
    required this.itemCount,
    required this.currentTotal,
    required this.allocated,
    required this.onPreview,
    required this.onConfirmedChanged,
    required this.onSave,
  });

  final bool busy;
  final bool confirmed;
  final Map<String, dynamic>? lastResult;
  final String purchaseCode;
  final String date;
  final String description;
  final int itemCount;
  final double currentTotal;
  final double allocated;
  final VoidCallback onPreview;
  final ValueChanged<bool> onConfirmedChanged;
  final VoidCallback onSave;

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
      FilledButton(
        onPressed: busy ? null : onPreview,
        child: const Text('MOSTRA RIEPILOGO'),
      ),
      if (lastResult != null)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RIEPILOGO MODIFICA', style: TextStyle(fontWeight: FontWeight.bold)),
                _line('Codice acquisto', purchaseCode),
                _line('Data', date),
                _line('Descrizione', description),
                _line('Oggetti collegati', itemCount.toString()),
                _line('Totale acquisto', '€ ${currentTotal.toStringAsFixed(2)}'),
                _line('Somma allocazioni', '€ ${allocated.toStringAsFixed(2)}'),
                const Text('I codici degli oggetti collegati vengono conservati. Il salvataggio aggiorna cassa e storico tramite runtime.'),
              ],
            ),
          ),
        ),
      CheckboxListTile(
        value: confirmed,
        title: const Text('Confermo il riepilogo e autorizzo il salvataggio.'),
        onChanged: busy || lastResult == null ? null : (value) => onConfirmedChanged(value ?? false),
      ),
      FilledButton(
        onPressed: busy || !confirmed || lastResult == null ? null : onSave,
        child: Text(busy ? 'ATTENDI…' : 'SALVA MODIFICA E TERMINA'),
      ),
    ],
  );
}
