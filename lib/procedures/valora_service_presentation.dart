part of '../main.dart';

extension _ValoraServicePagePresentation on _ValoraServicePageState {
  Widget buildPage(BuildContext context) {
    final selected = _objects.where((o) => o['codice_oggetto'] == _selectedId).firstOrNull;
    final matches = _matchingObjects;
    return Scaffold(
      appBar: AppBar(title: Text(ValoraI18n.tr('VALORA'))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(18), children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF8556C7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8556C7)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8556C7), size: 38),
              SizedBox(height: 12),
              Text(ValoraI18n.tr('SERVIZIO VALORA'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8556C7))),
              SizedBox(height: 8),
              Text(ValoraI18n.tr('Seleziona un oggetto della collezione e prepara una richiesta di valutazione specialistica. La preparazione non equivale ancora a una stima di mercato conclusa.')), 
            ]),
          ),
          const SizedBox(height: 18),
          Text(ValoraI18n.tr('1. SELEZIONA L’OGGETTO'), style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionQuery,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: ValoraI18n.tr('Cerca per descrizione'),
              hintText: ValoraI18n.tr('Inserisci una parte della descrizione'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _descriptionQuery.text.isEmpty ? null : IconButton(
                tooltip: ValoraI18n.tr('Cancella ricerca'),
                icon: const Icon(Icons.clear),
                onPressed: () => setState(() => _descriptionQuery.clear()),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text('${matches.length} risultati', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
          if (_objects.isEmpty) Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(ValoraI18n.tr('Non risultano oggetti disponibili nella destinazione COLLEZIONE.')),
          ) else if (matches.isEmpty) Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(ValoraI18n.tr('Nessun oggetto trovato con questa descrizione.')),
          ) else ...matches.map((object) {
            final id = (object['codice_oggetto'] as num).toInt();
            final isSelected = id == _selectedId;
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                selected: isSelected,
                leading: Icon(isSelected ? Icons.check_circle : Icons.inventory_2_outlined),
                title: Text((object['descrizione_oggetto'] ?? 'Senza descrizione').toString()),
                subtitle: Text('#$id'),
                trailing: isSelected ? const Icon(Icons.chevron_right) : null,
                onTap: () => setState(() { _selectedId = id; _prepared = null; }),
              ),
            );
          }),
          if (selected != null) Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(selected['descrizione_oggetto']?.toString() ?? 'Oggetto selezionato', style: const TextStyle(fontWeight: FontWeight.bold)),
              if ((selected['produttore'] ?? '').toString().isNotEmpty) Text('Produttore: ${selected['produttore']}'),
              if ((selected['codice_prodotto'] ?? '').toString().isNotEmpty) Text('Codice prodotto: ${selected['codice_prodotto']}'),
              Text('Condizione: ${selected['condizione'] ?? 'Non indicata'}'),
              Text('Completezza: ${selected['completezza'] ?? 'Non indicata'}'),
            ]),
          )),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _market,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: ValoraI18n.tr('Mercato di riferimento')), 
            items: [
              DropdownMenuItem(value: 'ITALIA', child: Text(ValoraI18n.tr('Italia'))),
              DropdownMenuItem(value: 'EUROPA', child: Text(ValoraI18n.tr('Europa'))),
              DropdownMenuItem(value: 'MONDO', child: Text(ValoraI18n.tr('Mondo'))),
            ],
            onChanged: (value) => setState(() { _market = value ?? 'ITALIA'; _prepared = null; }),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _preparing || _selectedId == null ? null : _prepareValuation,
            icon: _preparing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
            label: Text(_preparing ? ValoraI18n.tr('Preparazione in corso…') : ValoraI18n.tr('PREPARA VALUTAZIONE')),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
          if (_prepared != null) Card(
            margin: const EdgeInsets.only(top: 16),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ValoraI18n.tr('ESITO PREPARAZIONE'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(ValoraI18n.tr('La richiesta è stata inviata al runtime. Questo esito non rappresenta ancora una valutazione di mercato definitiva né genera automaticamente inserzioni.')), 
                const SizedBox(height: 8),
                SelectableText(_prepared.toString()),
              ],
            )),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _loadObjects, icon: const Icon(Icons.refresh), label: Text(ValoraI18n.tr('AGGIORNA OGGETTI'))),
        ]),
    );
  }
}
