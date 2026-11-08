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
          if (_pendingSales.isNotEmpty) _buildPr06PendingSalesSection(sectionColor),
          const SizedBox(height: 12),
          Text('1. TIPO DI VENDITA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: _lotMode,
            title: const Text('Vendi più oggetti come LOTTO UNICO'),
            subtitle: Text(_lotMode ? 'Un solo prezzo complessivo per tutti gli oggetti selezionati.' : 'Modalità standard: prezzo separato per ciascun oggetto.'),
            onChanged: _busy || _pendingSales.isNotEmpty ? null : (v) => setState(() { _lotMode = v; _selectedLotObjects.clear(); _lotTotalPrice.clear(); _invalidate(); }),
          ),
          const SizedBox(height: 8),
          ..._buildPr06ObjectSelectionSection(filtered, sectionColor),
          const SizedBox(height: 16),
          ..._buildPr06SaleDetailsSection(sectionColor),
          FilledButton.icon(onPressed: _busy || _loading || _objects.isEmpty ? null : _previewSale,
            icon: const Icon(Icons.fact_check_outlined), label: const Text('CONTROLLA E MOSTRA RIEPILOGO')),
          const SizedBox(height: 12),
          if (_preview != null) _buildPr06PreviewConfirmationSection(sectionColor),
          const SizedBox(height: 12),
          ..._buildPr06StatusSection(sectionColor),
      ]);
  }
}
