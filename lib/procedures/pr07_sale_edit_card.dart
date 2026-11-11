part of '../main.dart';

class Pr07SaleEditCard extends StatelessWidget {
  const Pr07SaleEditCard({
    super.key,
    required this.row,
    required this.selected,
    required this.priceController,
    required this.notesController,
    required this.modifyDate,
    required this.modifyPrice,
    required this.modifyPlatforms,
    required this.modifyNotes,
    required this.selectedDate,
    required this.platforms,
    required this.selectedPlatformCodes,
    required this.loading,
    required this.onSelect,
    required this.onModifyDate,
    required this.onModifyPrice,
    required this.onModifyPlatforms,
    required this.onModifyNotes,
    required this.onDateTap,
    required this.onPlatformChanged,
    required this.onDraftChanged,
  });

  final Map<String, dynamic> row;
  final bool selected;
  final TextEditingController priceController;
  final TextEditingController notesController;
  final bool modifyDate, modifyPrice, modifyPlatforms, modifyNotes, loading;
  final DateTime? selectedDate;
  final List<Map<String, dynamic>> platforms;
  final Set<int> selectedPlatformCodes;
  final VoidCallback onSelect, onDateTap, onDraftChanged;
  final ValueChanged<bool> onModifyDate, onModifyPrice, onModifyPlatforms, onModifyNotes;
  final void Function(int id, bool checked) onPlatformChanged;

  @override
  Widget build(BuildContext context) {
    final color = ValoraAppearance.instance.colorFor('VENDITE');
    final id = (row['codice_vendita_aperta'] ?? 'N/D').toString();
    final objectCode = (row['codice_oggetto'] ?? 'N/D').toString();
    final description = (row['descrizione_oggetto'] ?? 'Oggetto senza descrizione').toString();
    final currentPlatforms = ((row['piattaforme_associate'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => (item['nome_piattaforma'] ?? '').toString())
        .where((name) => name.isNotEmpty)
        .join(' · ');
    final date = (row['data_inizio_vendita'] ?? 'Non indicata').toString();
    final price = (row['prezzo_di_vendita'] ?? 'Non indicato').toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Vendita #$id · Oggetto #$objectCode',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            subtitle: Text('$description\nAperta: $date · Prezzo richiesto: $price\nPiattaforme: ${currentPlatforms.isEmpty ? 'Non indicate' : currentPlatforms}'),
            isThreeLine: true,
            trailing: selected ? Icon(Icons.check_circle, color: color) : const Icon(Icons.edit_outlined),
            onTap: loading ? null : onSelect,
          ),
          if (selected) ...[
            const Divider(),
            const Text('SELEZIONA I CAMPI DA MODIFICARE',
                style: TextStyle(fontWeight: FontWeight.bold)),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: modifyDate,
              onChanged: loading ? null : (value) => onModifyDate(value == true),
              title: const Text('Data iniziale della vendita'),
            ),
            if (modifyDate)
              OutlinedButton.icon(
                onPressed: loading ? null : onDateTap,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(selectedDate == null
                    ? 'SELEZIONA DATA'
                    : 'NUOVA DATA: ${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: modifyPrice,
              onChanged: loading ? null : (value) => onModifyPrice(value == true),
              title: const Text('Prezzo richiesto'),
            ),
            if (modifyPrice)
              TextField(
                controller: priceController,
                enabled: !loading,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => onDraftChanged(),
                decoration: const InputDecoration(labelText: 'Nuovo prezzo richiesto (€)'),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: modifyPlatforms,
              onChanged: loading ? null : (value) => onModifyPlatforms(value == true),
              title: const Text('Piattaforme di vendita'),
            ),
            if (modifyPlatforms)
              ...platforms.map((platform) {
                final platformId = int.tryParse((platform['codice_piattaforma'] ?? '').toString());
                if (platformId == null) return const SizedBox.shrink();
                return CheckboxListTile(
                  contentPadding: const EdgeInsets.only(left: 12),
                  value: selectedPlatformCodes.contains(platformId),
                  onChanged: loading ? null : (value) => onPlatformChanged(platformId, value == true),
                  title: Text((platform['nome_piattaforma'] ?? 'Piattaforma $platformId').toString()),
                );
              }),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: modifyNotes,
              onChanged: loading ? null : (value) => onModifyNotes(value == true),
              title: const Text('Note'),
            ),
            if (modifyNotes)
              TextField(
                controller: notesController,
                enabled: !loading,
                minLines: 2,
                maxLines: 4,
                onChanged: (_) => onDraftChanged(),
                decoration: const InputDecoration(labelText: 'Nuove note', alignLabelWithHint: true),
              ),
          ],
        ]),
      ),
    );
  }
}
