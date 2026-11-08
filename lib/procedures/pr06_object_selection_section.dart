part of '../main.dart';

extension _Pr06ObjectSelectionSection on _NewSalePageState {
  List<Widget> _buildPr06ObjectSelectionSection(
    List<Map<String, dynamic>> filtered,
    Color sectionColor,
  ) => [
Text(_lotMode ? '2. SELEZIONA GLI OGGETTI DEL LOTTO' : '2. SELEZIONA L’OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
TextField(controller: _search, decoration: const InputDecoration(
  labelText: 'Cerca per descrizione, codice o produttore', prefixIcon: Icon(Icons.search)),
  onChanged: (_) => setState(_invalidate)),
const SizedBox(height: 8),
if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
if (!_loading && filtered.isEmpty) const Text('Nessun oggetto trovato. Verifica che sia disponibile per la rivendita.'),
if (!_loading && filtered.isNotEmpty && !_lotMode) DropdownButtonFormField<int>(
  value: filtered.any((o) => int.tryParse((o['codice_oggetto'] ?? '').toString()) == _selectedObject)
    ? _selectedObject : int.tryParse((filtered.first['codice_oggetto'] ?? '').toString()),
  isExpanded: true,
  decoration: const InputDecoration(labelText: 'Oggetto da mettere in vendita *'),
  items: filtered.map((o) {
    final id = int.tryParse((o['codice_oggetto'] ?? '').toString());
    final desc = (o['descrizione_oggetto'] ?? 'Oggetto senza descrizione').toString();
    return DropdownMenuItem<int>(value: id, child: Text('${id == null ? '' : '#$id · '}$desc', overflow: TextOverflow.ellipsis));
  }).toList(),
  onChanged: _busy ? null : (v) => setState(() { _selectedObject = v; _invalidate(); }),
),
if (_lotMode && !_loading && filtered.isNotEmpty) ...filtered.map((o) {
  final id = int.tryParse((o['codice_oggetto'] ?? '').toString());
  if (id == null) return const SizedBox.shrink();
  return CheckboxListTile(contentPadding: EdgeInsets.zero, value: _selectedLotObjects.contains(id),
    title: Text((o['descrizione_oggetto'] ?? 'Oggetto #$id').toString()),
    subtitle: Text('Codice oggetto: $id · Stato: ${o['stato'] ?? 'DISPONIBILE'}'),
    onChanged: _busy ? null : (v) => setState(() { if (v == true) { _selectedLotObjects.add(id); } else { _selectedLotObjects.remove(id); } _invalidate(); }),
  );
}),
if (_lotMode) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text('Oggetti selezionati nel lotto: ${_selectedLotObjects.length}', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold))),
if (!_lotMode && _chosenObject != null) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
  crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text((_chosenObject!['descrizione_oggetto'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text('Codice oggetto: ${_selectedObject} · Stato: ${_chosenObject!['stato'] ?? 'DISPONIBILE'}'),
    Text('Valore inventario: ${_chosenObject!['valore_oggetto'] ?? 'non indicato'} ${_chosenObject!['valuta_valore'] ?? 'EUR'}'),
  ]))),
  ];
}
