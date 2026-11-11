part of '../main.dart';

class Pr06ValoraListingDraftCard extends StatelessWidget {
  const Pr06ValoraListingDraftCard({
    super.key,
    required this.draft,
    required this.titleController,
    required this.descriptionController,
    required this.categoryController,
    required this.priceController,
    required this.saving,
    required this.onCopy,
    required this.onSave,
  });

  final Map<String, dynamic> draft;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController categoryController;
  final TextEditingController priceController;
  final bool saving;
  final VoidCallback onCopy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final accent = ValoraAppearance.instance.colorFor('VENDITE');
    final warnings = draft['avvisi'] is List
        ? (draft['avvisi'] as List).map((value) => value.toString()).toList()
        : <String>[];
    final images = draft['immagini'] is List ? draft['immagini'] as List : const [];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text((draft['nome_piattaforma'] ?? 'Marketplace').toString(),
              style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 17))),
            Text((draft['stato'] ?? 'BOZZA').toString(),
              style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Text('Oggetto #${draft['codice_oggetto']} · Vendita #${draft['codice_vendita_aperta']}'),
          const SizedBox(height: 10),
          TextField(controller: titleController, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Titolo inserzione')),
          const SizedBox(height: 10),
          TextField(controller: categoryController,
            decoration: const InputDecoration(labelText: 'Categoria sulla piattaforma')),
          const SizedBox(height: 10),
          TextField(controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Prezzo (€)', prefixIcon: Icon(Icons.euro))),
          const SizedBox(height: 10),
          TextField(controller: descriptionController, minLines: 5, maxLines: 12,
            decoration: const InputDecoration(labelText: 'Descrizione inserzione', alignLabelWithHint: true)),
          if (images.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${images.length} foto confermate disponibili come riferimenti. Le immagini non vengono caricate sul marketplace.'),
          ),
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('DA VERIFICARE', style: TextStyle(color: Colors.orange.shade300, fontWeight: FontWeight.bold)),
            ...warnings.map((warning) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('• $warning', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
            )),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: saving ? null : onCopy,
              icon: const Icon(Icons.copy_outlined), label: const Text('COPIA TESTO'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: const Icon(Icons.save_outlined),
              label: Text(saving ? 'SALVATAGGIO…' : 'SALVA BOZZA'))),
          ]),
        ]),
      ),
    );
  }
}
