part of '../main.dart';

class Pr09CompletedSaleCard extends StatelessWidget {
  const Pr09CompletedSaleCard({
    super.key,
    required this.row,
    required this.disposition,
    required this.amountLabel,
    required this.enabled,
    required this.onDispositionChanged,
  });

  final Map<String, dynamic> row;
  final bool? disposition;
  final String amountLabel;
  final bool enabled;
  final ValueChanged<bool?> onDispositionChanged;

  @override
  Widget build(BuildContext context) {
    final id = (row['codice_vendita'] ?? 'N/D').toString();
    final objectCode = (row['codice_oggetto'] ?? 'N/D').toString();
    final description = (row['descrizione_oggetto'] ?? 'Oggetto senza descrizione').toString();
    final date = (row['data_vendita'] ?? 'Data non disponibile').toString();
    final platform = (row['nome_piattaforma'] ?? row['canale_effettivo'] ?? 'Piattaforma non indicata').toString();
    final appearance = ValoraAppearance.instance;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: appearance.colorFor('VENDITE')),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vendita conclusa #' + id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  amountLabel,
                  style: TextStyle(
                    color: appearance.colorFor('VENDITE'),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Oggetto #' + objectCode + ' · Data: ' + date),
            Text('Piattaforma: ' + platform),
            const SizedBox(height: 10),
            DropdownButtonFormField<bool>(
              value: disposition,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'DESTINAZIONE DOPO L’ANNULLAMENTO',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Scegli cosa fare con l’oggetto'),
              items: const [
                DropdownMenuItem<bool>(
                  value: true,
                  child: Text('ANNULLA E RIMETTI IN VENDITA'),
                ),
                DropdownMenuItem<bool>(
                  value: false,
                  child: Text('ANNULLA E RIMETTI IN COLLEZIONE'),
                ),
              ],
              onChanged: enabled ? onDispositionChanged : null,
            ),
          ],
        ),
      ),
    );
  }
}
