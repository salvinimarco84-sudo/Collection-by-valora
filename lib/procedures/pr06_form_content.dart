part of '../main.dart';

extension _Pr06FormContent on _NewSalePageState {
  Widget _buildPr06FormContent(BuildContext context) {
    final sectionColor = ValoraAppearance.instance.colorFor('VENDITE');
    final filtered = _filteredObjects;
    return Pr06NewSalePageFrame(children: [
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(
            'AMBIENTE TEST · La vendita non viene registrata finché non confermi esplicitamente il riepilogo. Sono selezionabili solo oggetti destinati alla RIVENDITA e disponibili.',
            style: TextStyle(color: ValoraAppearance.instance.textSecondary)))),
          const SizedBox(height: 12),
          if (_pendingSales.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VENDITE IN ATTESA: '+_pendingSales.length.toString(), style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_pendingSales.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text((i + 1).toString()+'. '+_pendingDescriptions[i]+' · €'+_pendingSales[i]['prezzo_di_vendita'].toString()),
              )),
              Text('Totale prezzi richiesti: €'+_pendingSales.fold<double>(0, (sum, row) => sum + ((row['prezzo_di_vendita'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)),
              OutlinedButton.icon(onPressed: _busy ? null : _saveSale, icon: const Icon(Icons.save_outlined), label: const Text('TERMINA E SALVA IL LOTTO ORA')),
            ]))),
          const SizedBox(height: 12),
          Text('1. TIPO DI VENDITA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: _lotMode,
            title: const Text('Vendi più oggetti come LOTTO UNICO'),
            subtitle: Text(_lotMode ? 'Un solo prezzo complessivo per tutti gli oggetti selezionati.' : 'Modalità standard: prezzo separato per ciascun oggetto.'),
            onChanged: _busy || _pendingSales.isNotEmpty ? null : (v) => setState(() { _lotMode = v; _selectedLotObjects.clear(); _lotTotalPrice.clear(); _invalidate(); }),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
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
          FilledButton.icon(onPressed: _busy || _loading || _objects.isEmpty ? null : _previewSale,
            icon: const Icon(Icons.fact_check_outlined), label: const Text('CONTROLLA E MOSTRA RIEPILOGO')),
          const SizedBox(height: 12),
          if (_preview != null) Card(color: ValoraAppearance.instance.card, child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('3. RIEPILOGO PRIMA DEL SALVATAGGIO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(const JsonEncoder.withIndent('  ').convert(_preview)),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero, value: _confirmed,
                title: Text(_lotMode ? 'Confermo oggetti, prezzo totale del lotto e piattaforme.' : 'Confermo che oggetto, prezzo e piattaforme sono corretti.'),
                onChanged: _busy ? null : (v) => setState(() => _confirmed = v == true),
              ),
              FilledButton.icon(onPressed: _busy || !_confirmed ? null : _saveSale,
                icon: const Icon(Icons.save_outlined), label: const Text('SALVA LOTTO')),
            ]))),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh), label: const Text('AGGIORNA OGGETTI DISPONIBILI')),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(_status.contains('non riuscito') || _status.contains('non confermato') ? Icons.error_outline : Icons.info_outline, color: sectionColor),
              const SizedBox(width: 8), Expanded(child: Text(_status)),
            ]))),
          if (_preview != null) const SizedBox(height: 8),
          if (_preview != null) SelectableText(const JsonEncoder.withIndent('  ').convert(_preview!)),
      ]);
  }
}
