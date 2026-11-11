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
          buildMarketValuationSection(),
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
