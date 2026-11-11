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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD9B45B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9B45B)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFD9B45B), size: 34),
              const SizedBox(height: 8),
              const Text('ASSISTENTE VALORA', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFFD9B45B))),
              const SizedBox(height: 6),
              const Text('Cerca un oggetto già presente nella tua collezione oppure inserisci foto dalla fotocamera, dalla galleria o file di riferimento. Le foto vengono utilizzate per il riconoscimento e la ricerca PR-12, non vengono salvate nella scheda. L’immagine definitiva dell’oggetto proviene dai metadati verificati.'),
            ]),
          ),
          const SizedBox(height: 16),
          buildPhotoInputSection(context),
          const SizedBox(height: 18),
          buildCollectionSearchSection(selected: selected, matches: matches),
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
          if (_prepared != null) Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton.icon(onPressed: _preparing ? null : _continueToPr06Valora, icon: const Icon(Icons.sell_outlined), label: const Text('VALUTAZIONE COMPLETATA · CONTINUA A PR06 VALORA'))),
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
          if (_selectedId != null && selected != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _preparing || (selected['stato'] ?? '').toString().trim().toUpperCase() != 'DISPONIBILE'
                  ? null
                  : _openCatalogObjectForSale,
              icon: const Icon(Icons.sell_outlined),
              label: const Text('AVVIA PROCEDURA DI VENDITA'),
            ),
            const SizedBox(height: 6),
            Text(
              'La vendita è indipendente dalla valutazione. Se esiste già un valore di mercato, verrà proposto come prezzo iniziale; altrimenti potrai inserirlo nella procedura di vendita.',
              style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _loadObjects, icon: const Icon(Icons.refresh), label: Text(ValoraI18n.tr('AGGIORNA OGGETTI'))),
        ]),
    );
  }
}
