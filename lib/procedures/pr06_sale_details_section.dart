part of '../main.dart';

extension _Pr06SaleDetailsSection on _NewSalePageState {
  List<Widget> _buildPr06SaleDetailsSection(Color sectionColor) => [
Text(_lotMode ? '3. PREZZO UNICO DEL LOTTO' : '3. DATI DI VENDITA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
if (_lotMode) TextField(controller: _lotTotalPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: const InputDecoration(labelText: 'Prezzo totale per tutti gli oggetti (€) *', prefixIcon: Icon(Icons.euro)),
  onChanged: (_) => setState(_invalidate)),
if (!_lotMode) TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: const InputDecoration(labelText: 'Prezzo di vendita richiesto (€) *', prefixIcon: Icon(Icons.euro)),
  onChanged: (_) => setState(_invalidate)),
const SizedBox(height: 8),
const Text('Piattaforme di vendita *'),
if (_platforms.isEmpty) const Text('Non sono riuscito a caricare le piattaforme. Riprova il caricamento.'),
..._platforms.map((p) {
  final id = int.tryParse((p['codice_piattaforma'] ?? '').toString());
  if (id == null) return const SizedBox.shrink();
  return CheckboxListTile(
    contentPadding: EdgeInsets.zero, value: _selectedPlatforms.contains(id),
    title: Text((p['nome_piattaforma'] ?? 'Piattaforma $id').toString()),
    onChanged: _busy ? null : (v) => setState(() { if (v == true) { _selectedPlatforms.add(id); } else { _selectedPlatforms.remove(id); } _invalidate(); }),
  );
}),
const SizedBox(height: 8),
TextField(controller: _notes, minLines: 2, maxLines: 4,
  decoration: const InputDecoration(labelText: 'Note (facoltative)', alignLabelWithHint: true),
  onChanged: (_) => setState(_invalidate)),
const SizedBox(height: 16),
  ];
}
