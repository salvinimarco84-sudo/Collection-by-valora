part of '../main.dart';

extension _ValoraPhotoSearchPresentation on _ValoraServicePageState {
  Widget _buildPhotoSearchResultsSection() {
    if (_photoSearchResults.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
  }
}
