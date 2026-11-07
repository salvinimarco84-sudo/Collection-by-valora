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
  });

  final int index;
  final _PurchaseItemDraft item;
  final bool busy;
  final List<Map<String, dynamic>> categories;
  final bool categoriesLoading;
  final VoidCallback onChanged;
  final VoidCallback onPhoto;

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
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: busy ? null : onPhoto,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('SCATTA FOTO · RICONOSCIMENTO PR-12'),
        )),
        if (item.photoUrl != null) Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item.photoUrl!, height: 130, width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => item.photoBytes != null
                ? Image.memory(item.photoBytes!, height: 130, width: double.infinity, fit: BoxFit.contain)
                : const Icon(Icons.broken_image_outlined),
            ),
          ),
        ) else if (item.photoBytes != null) Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(item.photoBytes!, height: 130, width: double.infinity, fit: BoxFit.contain),
          ),
        ),
        Text(item.photoStatus, style: TextStyle(
          fontSize: 12, color: ValoraAppearance.instance.textSecondary,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: item.price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Prezzo di acquisto (€) *', hintText: 'Es. 25,00'),
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
