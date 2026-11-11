part of '../main.dart';

/// Presentazione autonoma della sezione foto, file e candidati PR-12.
extension _ValoraPhotoInputPresentation on _ValoraServicePageState {
  Widget buildPhotoInputSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FOTO E FILE', style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(onPressed: _analyzingPhotos ? null : () => _pickImage(ImageSource.camera), icon: const Icon(Icons.photo_camera_outlined), label: const Text('Fotocamera')),
        OutlinedButton.icon(onPressed: _analyzingPhotos ? null : () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined), label: const Text('Galleria')),
        OutlinedButton.icon(onPressed: _pickFiles, icon: const Icon(Icons.attach_file), label: const Text('Scegli file')),
        ]),
        if (_selectedImages.isNotEmpty || _selectedFiles.isNotEmpty) ...[
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
        if (selectedUrl != null && _confirmedPhotoCandidates[photoIndex] != null)
        Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FilledButton.icon(
        onPressed: _analyzingPhotos ? null : () => _openUncataloguedCandidate(photoIndex),
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('OGGETTO NON IN CATALOGO · APRI PR-04'),
        ),
        ),
        if (selectedUrl != null)
        Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(_confirmedPhotoCandidates[photoIndex] != null
        ? 'Candidato confermato per questa sessione. Nessun record è stato creato o modificato.'
        : 'Candidato selezionato. Conferma la corrispondenza per proseguire. Nessun dato viene ancora salvato.'),
        ),
        if (_metadataValuationStatus.containsKey(photoIndex))
        Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
        _metadataValuationStatus[photoIndex]!.startsWith('PREPARAZIONE_NON_RIUSCITA')
        ? 'Preparazione valutazione non riuscita: ${_metadataValuationStatus[photoIndex]!.replaceFirst('PREPARAZIONE_NON_RIUSCITA: ', '')}'
        : 'Richiesta di valutazione mercato preparata per $_market. La ricerca dei comparabili e il calcolo del valore non sono ancora stati eseguiti.',
        ),
        ),
        if (selectedUrl != null && _confirmedPhotoCandidates[photoIndex] == null)
        Padding(
        padding: const EdgeInsets.only(top: 8),
        child: FilledButton.icon(
        onPressed: _analyzingPhotos ? null : () => _confirmPhotoCandidate(photoIndex),
        icon: const Icon(Icons.verified_outlined),
        label: const Text('CONFERMA QUESTO CANDIDATO'),
        ),
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
      ],
    );
  }
}
