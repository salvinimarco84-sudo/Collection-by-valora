part of '../main.dart';

class Pr04ItemEditor extends StatelessWidget {
  const Pr04ItemEditor({
    super.key,
    required this.index,
    required this.item,
    required this.busy,
    required this.categories,
    required this.categoriesLoading,
    required this.onChanged,
    required this.onPhoto,
    this.suggestedMarketValue,
  });

  final int index;
  final _PurchaseItemDraft item;
  final bool busy;
  final List<Map<String, dynamic>> categories;
  final bool categoriesLoading;
  final VoidCallback onChanged;
  final VoidCallback onPhoto;
  final double? suggestedMarketValue;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OGGETTO ${index + 1}', style: TextStyle(
          color: ValoraAppearance.instance.colorFor('ACQUISTI'),
          fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: item.description,
          decoration: const InputDecoration(labelText: 'Descrizione oggetto *'),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 6),
        Pr04PurchasePhotoField(
          busy: busy,
          photoUrl: item.photoUrl,
          photoBytes: item.photoBytes,
          photoStatus: item.photoStatus,
          onPhoto: onPhoto,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: item.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Prezzo di acquisto (€) *',
            hintText: 'Es. 25,00',
            helperText: suggestedMarketValue != null && suggestedMarketValue! > 0
                ? 'Valore di mercato indicativo: € ${suggestedMarketValue!.toStringAsFixed(2)}. Non è il costo di acquisto.'
                : 'Inserisci il costo effettivamente sostenuto. Il valore di mercato è un dato distinto.',
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: item.destination,
          decoration: const InputDecoration(labelText: 'Destinazione'),
          items: const [
            DropdownMenuItem(value: 'COLLEZIONE', child: Text('COLLEZIONE')),
            DropdownMenuItem(value: 'RIVENDITA', child: Text('RIVENDITA')),
          ],
          onChanged: busy ? null : (v) {
            item.destination = v ?? item.destination;
            if (item.destination != 'COLLEZIONE') item.collectionCategoryCode = null;
            onChanged();
          },
        ),
        if (item.destination == 'COLLEZIONE') ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: categories.any((e) => e['codice_categoria'] == item.collectionCategoryCode)
              ? item.collectionCategoryCode : null,
            decoration: InputDecoration(
              labelText: 'Categoria COLLEZIONE *',
              helperText: categoriesLoading ? 'Caricamento categorie…' : 'Categoria principale dell’oggetto',
            ),
            items: categories.map((e) => DropdownMenuItem<String>(
              value: e['codice_categoria'].toString(),
              child: Text((e['descrizione'] ?? e['codice_categoria']).toString()),
            )).toList(),
            onChanged: busy ? null : (v) { item.collectionCategoryCode = v; onChanged(); },
          ),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: item.condition,
            decoration: const InputDecoration(labelText: 'Condizione'),
            items: const [
              DropdownMenuItem(value: 'NUOVO', child: Text('NUOVO')),
              DropdownMenuItem(value: 'USATO', child: Text('USATO')),
              DropdownMenuItem(value: 'DA RIPARARE', child: Text('DA RIPARARE')),
            ],
            onChanged: busy ? null : (v) { item.condition = v ?? item.condition; onChanged(); },
          )),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(
            value: item.completeness,
            decoration: const InputDecoration(labelText: 'Completezza'),
            items: const [
              DropdownMenuItem(value: 'COMPLETO', child: Text('COMPLETO')),
              DropdownMenuItem(value: 'COMPLETO CON ISTRUZIONI', child: Text('COMPLETO CON ISTRUZIONI')),
              DropdownMenuItem(value: 'COMPLETO CON SCATOLA E ISTRUZIONI', child: Text('COMPLETO CON SCATOLA E ISTRUZIONI')),
              DropdownMenuItem(value: 'INCOMPLETO', child: Text('INCOMPLETO')),
              DropdownMenuItem(value: 'SOLO PARTI', child: Text('SOLO PARTI')),
            ],
            onChanged: busy ? null : (v) { item.completeness = v ?? item.completeness; onChanged(); },
          )),
        ]),
        const SizedBox(height: 8),
        TextField(
          controller: item.notes,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Note (facoltative)',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => onChanged(),
        ),
      ]),
    ),
  );
}


class Pr04ValoraPurchaseContent extends StatelessWidget {
  const Pr04ValoraPurchaseContent({
    super.key,
    required this.dateLabel,
    required this.description,
    required this.total,
    required this.busy,
    required this.previewReady,
    required this.itemEditor,
    required this.onPickDate,
    required this.onPreview,
    required this.onSave,
    required this.onEdit,
  });

  final String dateLabel;
  final String description;
  final double total;
  final bool busy;
  final bool previewReady;
  final Widget itemEditor;
  final VoidCallback onPickDate;
  final VoidCallback onPreview;
  final VoidCallback onSave;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        previewReady ? 'CONFERMA ACQUISTO VALORA' : 'NUOVO ACQUISTO DA VALORA',
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      Text(
        previewReady
          ? 'Controlla il riepilogo verificato. Il salvataggio avviene solo dopo la conferma.'
          : 'I dati identificativi trovati da VALORA sono già compilati. Completa solo i dati dell’acquisto.',
        style: TextStyle(color: ValoraAppearance.instance.textSecondary),
      ),
      const SizedBox(height: 12),
      if (!previewReady) ...[
        Card(child: ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Data acquisto'),
          subtitle: Text(dateLabel),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: busy ? null : onPickDate,
        )),
        const SizedBox(height: 10),
        itemEditor,
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const Expanded(child: Text('TOTALE ACQUISTO', style: TextStyle(fontWeight: FontWeight.bold))),
            Text('€ ' + total.toStringAsFixed(2).replaceAll('.', ','),
              style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
        )),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: busy ? null : onPreview,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('CONTROLLA E MOSTRA RIEPILOGO'),
        ),
      ] else ...[
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ACQUISTO SINGOLO', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Data acquisto: $dateLabel'),
            Text('Oggetto: $description'),
            const SizedBox(height: 8),
            Text('Totale: € ' + total.toStringAsFixed(2).replaceAll('.', ','),
              style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Anteprima completata. Nessuna scrittura è stata eseguita.'),
          ]),
        )),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: busy ? null : onSave,
          icon: const Icon(Icons.save_outlined),
          label: const Text('CONFERMA E REGISTRA ACQUISTO'),
        ),
        OutlinedButton(
          onPressed: busy ? null : onEdit,
          child: const Text('MODIFICA DATI'),
        ),
      ],
    ],
  );
}
