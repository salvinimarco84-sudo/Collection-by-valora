part of '../main.dart';

/// Sezione di ricerca e selezione degli oggetti già presenti nella collezione.
extension _ValoraCollectionSearchPresentation on _ValoraServicePageState {
  Widget buildCollectionSearchSection({
    required Map<String, dynamic>? selected,
    required List<Map<String, dynamic>> matches,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CERCA NELLA COLLEZIONE',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: ValoraAppearance.instance.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionQuery,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: ValoraI18n.tr('Cerca per descrizione'),
            hintText: ValoraI18n.tr('Inserisci una parte della descrizione'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _descriptionQuery.text.isEmpty
                ? null
                : IconButton(
                    tooltip: ValoraI18n.tr('Cancella ricerca'),
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _descriptionQuery.clear()),
                  ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_descriptionQuery.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                ValoraI18n.tr(
                  'Nessun oggetto trovato nella collezione con questa descrizione.',
                ),
              ),
            ),
          if (matches.isNotEmpty)
            ...matches.map((object) {
              final id = (object['codice_oggetto'] as num).toInt();
              final isSelected = id == _selectedId;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  selected: isSelected,
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.inventory_2_outlined,
                  ),
                  title: Text(
                    (object['descrizione_oggetto'] ?? 'Senza descrizione')
                        .toString(),
                  ),
                  subtitle: Text('Codice oggetto #$id'),
                  trailing:
                      isSelected ? const Icon(Icons.check_circle) : null,
                  onTap: () => setState(() {
                    _selectedId = id;
                    _prepared = null;
                  }),
                ),
              );
            }),
        ],
        if (_descriptionQuery.text.trim().isNotEmpty &&
            selected != null &&
            matches.any((object) => object['codice_oggetto'] == _selectedId))
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected['descrizione_oggetto']?.toString() ??
                        'Oggetto selezionato',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Codice oggetto: #${selected['codice_oggetto']}'),
                  if ((selected['stato'] ?? '').toString().isNotEmpty)
                    Text('Stato: ${selected['stato']}'),
                  if ((selected['produttore'] ?? '').toString().isNotEmpty)
                    Text('Produttore: ${selected['produttore']}'),
                  if ((selected['codice_prodotto'] ?? '').toString().isNotEmpty)
                    Text('Codice prodotto: ${selected['codice_prodotto']}'),
                  Text('Condizione: ${selected['condizione'] ?? 'Non indicata'}'),
                  Text('Completezza: ${selected['completezza'] ?? 'Non indicata'}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
