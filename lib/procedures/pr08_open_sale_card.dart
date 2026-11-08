part of '../main.dart';

class Pr08OpenSaleCard extends StatelessWidget {
  const Pr08OpenSaleCard({
    super.key,
    required this.row,
    required this.id,
    required this.selected,
    required this.loading,
    required this.outcome,
    required this.date,
    required this.amount,
    required this.platformCode,
    required this.today,
    required this.requestedPrice,
    required this.platforms,
    required this.onSelectionChanged,
    required this.onOutcomeChanged,
    required this.onPickDate,
    required this.onAmountChanged,
    required this.onPlatformChanged,
  });

  final Map<String, dynamic> row;
  final int id;
  final bool selected;
  final bool loading;
  final String? outcome;
  final String? date;
  final String? amount;
  final String? platformCode;
  final String today;
  final String requestedPrice;
  final List<Map<String, dynamic>> platforms;
  final ValueChanged<bool?> onSelectionChanged;
  final ValueChanged<String?> onOutcomeChanged;
  final VoidCallback onPickDate;
  final ValueChanged<String> onAmountChanged;
  final ValueChanged<String?> onPlatformChanged;

  @override
  Widget build(BuildContext context) {
    final linked = row['piattaforme_associate'] is List
        ? (row['piattaforme_associate'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: selected,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Vendita aperta #$id',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Oggetto #${row['codice_oggetto'] ?? 'n/d'} · ${row['descrizione_oggetto'] ?? 'Senza descrizione'}',
              ),
              onChanged: loading ? null : onSelectionChanged,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 42, bottom: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('In vendita dal ${row['data_inizio_vendita'] ?? 'n/d'}'),
                  Text('Prezzo richiesto: $requestedPrice'),
                  if (linked.isNotEmpty)
                    Text('Piattaforme: ${linked.map((e) => e['nome_piattaforma']).join(', ')}'),
                  if (row['codice_lotto'] != null) const Text('Parte di un lotto'),
                ],
              ),
            ),
            if (selected) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 42, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: outcome,
                      decoration: const InputDecoration(labelText: 'Esito della chiusura *'),
                      items: const [
                        DropdownMenuItem(value: 'VENDITA EFFETTIVA', child: Text('Vendita effettiva')),
                        DropdownMenuItem(value: 'CHIUSURA SENZA VENDITA', child: Text('Chiusura senza vendita')),
                      ],
                      onChanged: loading ? null : onOutcomeChanged,
                    ),
                    if (outcome == 'VENDITA EFFETTIVA') ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('date-$id-${date ?? ''}'),
                        initialValue: date ?? today,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Data vendita *',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: loading ? null : onPickDate,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('amount-$id-${amount ?? ''}'),
                        initialValue: amount ?? '${row['prezzo_di_vendita'] ?? ''}',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Importo effettivo *', suffixText: 'EUR'),
                        onChanged: onAmountChanged,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: platformCode,
                        decoration: const InputDecoration(labelText: 'Piattaforma effettiva *'),
                        items: platforms.map((p) => DropdownMenuItem<String>(
                          value: '${p['codice_piattaforma']}',
                          child: Text('${p['nome_piattaforma']}'),
                        )).toList(),
                        onChanged: loading ? null : onPlatformChanged,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
