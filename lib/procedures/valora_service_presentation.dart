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
          Text('FOTO E FILE', style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: _analyzingPhotos ? null : () => _pickImage(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Fotocamera')),
            OutlinedButton.icon(onPressed: _analyzingPhotos ? null : () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galleria')),
            OutlinedButton.icon(onPressed: _pickFiles, icon: const Icon(Icons.attach_file), label: const Text('Scegli file')),
          ]),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _analyzingPhotos ? null : _analyzeSelectedPhotos,
              icon: _analyzingPhotos ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
              label: Text(_analyzingPhotos ? 'RICERCA FOTO IN CORSO…' : 'USA LE FOTO PER LA RICERCA PR-12'),
            ),
            SizedBox(height: 112, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = _selectedImages[index];
                return Stack(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(image.path), width: 100, height: 100, fit: BoxFit.contain)),
                  Positioned(right: 0, top: 0, child: IconButton.filledTonal(onPressed: () => _removeImage(image), icon: const Icon(Icons.close, size: 16))),
                ]);
              },
            )),
          ],
          if (_selectedFiles.isNotEmpty) ..._selectedFiles.map((file) => ListTile(
            dense: true, contentPadding: EdgeInsets.zero, leading: const Icon(Icons.attach_file),
            title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(onPressed: () => _removeFile(file), icon: const Icon(Icons.close)),
          )),
          if (_photoSearchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('RISULTATI RICERCA DA FOTO', style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
            ..._photoSearchResults.map((result) {
              final clues = Map<String, dynamic>.from(result['identificazione'] as Map);
              final candidates = (result['risultati'] as List).whereType<Map>().toList();
              final photoIndex = _photoSearchResults.indexOf(result);
              final selectedUrl = _selectedPhotoCandidates[photoIndex];
              return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Identificazione: ${clues['descrizione_provvisoria'] ?? 'Non determinata'}'),
                if ((clues['marchio'] ?? '').toString().isNotEmpty) Text('Marchio: ${clues['marchio']}'),
                Text('Candidati trovati: ${candidates.length}'),
                if (candidates.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nessuna corrispondenza verificabile in questo tentativo. Puoi ampliare la ricerca senza ripetere i risultati già esaminati.'),
                  ),
                ...candidates.map((candidate) {
                  final url = (candidate['url'] ?? '').toString();
                  final isSelected = selectedUrl != null && selectedUrl == url;
                  return Card(
                    margin: const EdgeInsets.only(top: 6),
                    child: ListTile(
                      leading: candidate['image_url'] is String && (candidate['image_url'] as String).startsWith('http')
                        ? Image.network(candidate['image_url'], width: 48, height: 58, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined))
                        : const Icon(Icons.inventory_2_outlined),
                      title: Text((candidate['title'] ?? 'Candidato senza titolo').toString()),
                      subtitle: Text([
                        if ((candidate['editore'] ?? candidate['produttore'] ?? '').toString().isNotEmpty) (candidate['editore'] ?? candidate['produttore']).toString(),
                        if ((candidate['anno_uscita'] ?? '').toString().isNotEmpty) 'Anno: ${candidate['anno_uscita']}',
                        if (url.isNotEmpty) Uri.tryParse(url)?.host ?? url,
                      ].join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFFD9B45B) : null),
                      selected: isSelected,
                      onTap: url.isEmpty ? null : () => setState(() {
                        _selectedPhotoCandidates[photoIndex] = url;
                      }),
                    ),
                  );
                }),
                if (selectedUrl != null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Candidato selezionato. La scelta resta in attesa di conferma e non salva ancora nulla nel database.'),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _analyzingPhotos ? null : () => _retryPhotoSearch(photoIndex),
                  icon: const Icon(Icons.manage_search),
                  label: const Text('NESSUNO CORRISPONDE: NUOVA RICERCA'),
                ),
              ])));
            }),
          ],
          const SizedBox(height: 18),
          Text('CERCA NELLA COLLEZIONE', style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
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
          if (_descriptionQuery.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            if (matches.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(ValoraI18n.tr('Nessun oggetto trovato nella collezione con questa descrizione.')),
              )
            else ...matches.map((object) {
              final id = (object['codice_oggetto'] as num).toInt();
              final isSelected = id == _selectedId;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  selected: isSelected,
                  leading: Icon(isSelected ? Icons.check_circle : Icons.inventory_2_outlined),
                  title: Text((object['descrizione_oggetto'] ?? 'Senza descrizione').toString()),
                  subtitle: Text('Codice oggetto #$id'),
                  trailing: isSelected ? const Icon(Icons.check_circle) : null,
                  onTap: () => setState(() { _selectedId = id; _prepared = null; }),
                ),
              );
            }),
          ],
          if (selected != null) Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(selected['descrizione_oggetto']?.toString() ?? 'Oggetto selezionato', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Codice oggetto: #${selected['codice_oggetto']}'),
              if ((selected['stato'] ?? '').toString().isNotEmpty) Text('Stato: ${selected['stato']}'),
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
