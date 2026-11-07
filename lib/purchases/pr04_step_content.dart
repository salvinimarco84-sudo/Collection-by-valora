part of '../main.dart';

class Pr04PurchaseStepContent extends StatelessWidget {
  const Pr04PurchaseStepContent({
    super.key,
    required this.step,
    required this.type,
    required this.dateLabel,
    required this.countController,
    required this.items,
    required this.total,
    required this.pendingPurchaseCount,
    required this.pendingTotal,
    required this.busy,
    required this.itemEditor,
    required this.onSelectSingle,
    required this.onSelectLot,
    required this.onContinue,
    required this.onBack,
    required this.onContinueToItems,
    required this.onContinueToSummary,
    required this.onRunPreview,
    required this.onQueueAnother,
    required this.onSaveAndExit,
    required this.onEditObjects,
    required this.onEditData,
  });

  final int step;
  final String type;
  final String dateLabel;
  final TextEditingController countController;
  final List<_PurchaseItemDraft> items;
  final double total;
  final int pendingPurchaseCount;
  final double pendingTotal;
  final bool busy;
  final Widget Function(int index) itemEditor;
  final VoidCallback onSelectSingle;
  final VoidCallback onSelectLot;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final VoidCallback onContinueToItems;
  final VoidCallback onContinueToSummary;
  final VoidCallback onRunPreview;
  final VoidCallback onQueueAnother;
  final VoidCallback onSaveAndExit;
  final VoidCallback onEditObjects;
  final VoidCallback onEditData;

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text(subtitle, style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
    ]),
  );

  Widget _choice(String title, String subtitle, IconData icon, bool selected, VoidCallback onTap) => Card(
    color: selected ? ValoraAppearance.instance.card : null,
    child: ListTile(
      leading: Icon(icon, color: selected ? goldColor : null),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
      onTap: busy ? null : onTap,
    ),
  );

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, color: bold ? goldColor : null))),
      const SizedBox(width: 8),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: bold ? goldColor : null))),
    ]),
  );

  Widget _purchaseItemsSummary() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < items.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((i + 1).toString() + '. ' + items[i].description.text.trim(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(items[i].destination + ' · ' + items[i].condition + ' · ' + items[i].completeness,
              style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
            if (items[i].notes.text.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('Note: ' + items[i].notes.text.trim(),
                  style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('€ ' + (items[i].amount ?? 0).toStringAsFixed(2).replaceAll('.', ',')),
            ),
          ]),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (step == 0) return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('Che tipo di acquisto vuoi registrare?', 'Una transazione può contenere uno o più oggetti.'),
        _choice('ACQUISTO SINGOLO', 'Una transazione · un oggetto', Icons.shopping_bag_outlined,
          type == 'SINGOLO', onSelectSingle),
        _choice('ACQUISTO MULTIPLO / LOTTO', 'Una transazione · più oggetti distinti', Icons.inventory_2_outlined,
          type == 'LOTTO', onSelectLot),
        const SizedBox(height: 12),
        FilledButton(onPressed: busy ? null : onContinue, child: const Text('CONTINUA')),
      ],
    );

    if (step == 1) return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('Dati dell’acquisto', 'La data è unica per tutta la transazione.'),
        Card(child: ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Data acquisto'),
          subtitle: Text(dateLabel),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: busy ? null : onBack,
        )),
        if (type == 'LOTTO') ...[
          const SizedBox(height: 10),
          TextField(
            controller: countController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Numero di oggetti distinti *',
              helperText: 'Quanti record oggetto devono essere creati nella stessa transazione?',
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(onPressed: busy ? null : onContinueToItems, child: const Text('CONTINUA AGLI OGGETTI')),
        OutlinedButton(onPressed: busy ? null : onBack, child: const Text('INDIETRO')),
      ],
    );

    if (step == 2) return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(type == 'SINGOLO' ? 'Descrivi l’oggetto acquistato' : 'Inserisci tutti gli oggetti del lotto',
          type == 'SINGOLO' ? 'Un oggetto, un record, un acquisto.' : 'Ogni oggetto ha il proprio prezzo e record; la transazione resta unica.'),
        for (var i = 0; i < items.length; i++) itemEditor(i),
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: _line('TOTALE ACQUISTO', '€ ' + total.toStringAsFixed(2).replaceAll('.', ','), bold: true),
        )),
        const SizedBox(height: 10),
        FilledButton(onPressed: busy ? null : onContinueToSummary, child: const Text('RIEPILOGO ACQUISTO')),
        OutlinedButton(onPressed: busy ? null : onBack, child: const Text('INDIETRO')),
      ],
    );

    if (step == 3) return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('Riepilogo acquisto', 'Controlla i dati prima di procedere. Nessuna scrittura è stata eseguita.'),
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _line('Tipo', type == 'SINGOLO' ? 'Acquisto singolo' : 'Acquisto multiplo / lotto'),
            _line('Data acquisto', dateLabel),
            _line('Oggetti distinti', items.length.toString()),
            const Divider(height: 22),
            _purchaseItemsSummary(),
            const Divider(height: 22),
            _line('TOTALE TRANSAZIONE', '€ ' + total.toStringAsFixed(2).replaceAll('.', ','), bold: true),
          ]),
        )),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: busy ? null : onRunPreview,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('CONTROLLA E MOSTRA RIEPILOGO'),
        ),
        OutlinedButton(onPressed: busy ? null : onEditObjects, child: const Text('MODIFICA OGGETTI')),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading('Riepilogo acquisti', 'SÌ aggiunge questo acquisto alla coda senza scrivere. NO salva insieme tutti gli acquisti in coda e quello corrente.'),
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _line('Tipo', type == 'SINGOLO' ? 'Acquisto singolo' : 'Acquisto multiplo / lotto'),
            _line('Data acquisto', dateLabel),
            _line('Oggetti distinti', items.length.toString()),
            const Divider(height: 22),
            _purchaseItemsSummary(),
            const Divider(height: 22),
            _line('TOTALE ACQUISTO CORRENTE', '€ ' + total.toStringAsFixed(2).replaceAll('.', ','), bold: true),
            if (pendingPurchaseCount > 0) ...[
              const Divider(height: 22),
              _line('TOTALE DI TUTTI GLI ACQUISTI', '€ ' + (pendingTotal + total).toStringAsFixed(2).replaceAll('.', ','), bold: true),
            ],
          ]),
        )),
        const SizedBox(height: 12),
        FilledButton(onPressed: busy ? null : onQueueAnother, child: const Text('SÌ · AGGIUNGI UN ALTRO ACQUISTO ALLA CODA')),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy ? null : onSaveAndExit,
          child: Text(busy ? 'ATTENDI…' : 'NO · SALVA E ESCI'),
        ),
        OutlinedButton(onPressed: busy ? null : onEditData, child: const Text('MODIFICA DATI')),
      ],
    );
  }
}
