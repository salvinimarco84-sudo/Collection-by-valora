part of '../main.dart';

extension _ObjectRuntimePagePr12Presentation on _ObjectRuntimePageState {
  Widget _buildPr12Screen() {

      return Scaffold(
        appBar: AppBar(title: const Text('PR-12 · RICERCA METADATI')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RICERCA MULTI-FONTE', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('PR-12 controlla il catalogo e individua tutti i record con almeno un metadato identificativo mancante. Questa fase è di sola lettura: i dati presenti non vengono modificati.'),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : () => _run(_ObjectRuntimePagePr12Catalog(this)._loadIncompleteMetadataCatalog),
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.manage_search),
                        label: Text(_loading ? 'ANALISI IN CORSO…' : 'ANALIZZA CATALOGO'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Record incompleti: ${_pr12IncompleteRecords.length}', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: FilledButton.icon(
                      onPressed: _loading || _pr12AiBatchRunning ? null : _ObjectRuntimePagePr12Runtime(this)._runPr12AiBatch,
                      icon: _pr12AiBatchRunning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
                      label: Text(_pr12AiBatchRunning ? 'RICERCA IN CORSO…' : 'AVVIA RICERCA MULTI-FONTE · LOTTO DA 10'),
                    )),
                    const SizedBox(height: 8),
                    SelectableText(_pr12RetryRunning ? 'Nuovo tentativo sui record irrisolti in corso…' : _pr12AiBatchStatus),
                    if (_pr12UnresolvedRecords.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('DA RIPROVARE: ${_pr12UnresolvedRecords.length}', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(
                        onPressed: _pr12AiBatchRunning ? null : () => _ObjectRuntimePagePr12Runtime(this)._runPr12AiBatch(retryUnresolved: true),
                        icon: const Icon(Icons.refresh),
                        label: Text(_pr12AiBatchRunning ? 'RICERCA IN CORSO…' : 'RIPROVA I PROSSIMI 10 IRRISOLTI'),
                      )),
                    ],
                    if (_pr12NextBatchOffset < _pr12IncompleteRecords.length) ...[
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(
                        onPressed: _pr12AiBatchRunning ? null : () => _ObjectRuntimePagePr12Runtime(this)._runPr12AiBatch(),
                        icon: const Icon(Icons.skip_next),
                        label: Text('ELABORA PROSSIMO LOTTO · ${(_pr12IncompleteRecords.length - _pr12NextBatchOffset).clamp(0, 10)} DI ${_pr12IncompleteRecords.length - _pr12NextBatchOffset} RECORD'),
                      )),
                    ],
                    if (_pr12AiResults.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('RISULTATI RICERCA (${_pr12AiResults.length})', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      ..._pr12AiResults.map((result) {
                        final candidates = result['risultati'];
                        final candidateList = candidates is List ? candidates : const [];
                        final objectId = (result['oggetto_id'] ?? '').toString();
                        final selectedIndex = _pr12SelectedCandidates[objectId];
                        return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('#${result['oggetto_id'] ?? ''} · ${result['descrizione'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(result['ok'] != true ? 'Errore tecnico: ${result['error'] ?? 'ricerca non riuscita'}' : (((result['numero_risultati'] as num?) ?? candidateList.length) == 0 ? 'Nessuna corrispondenza pertinente trovata' : '${result['numero_risultati'] ?? candidateList.length} candidati da verificare')),
                          ...candidateList.take(5).toList().asMap().entries.map((entry) {
                            final item = entry.value is Map
                                ? Map<String, dynamic>.from(entry.value as Map)
                                : <String, dynamic>{};
                            return Pr12CandidateCard(
                              item: item,
                              selected: selectedIndex == entry.key,
                              accentColor: sectionColor,
                              onSelect: () => setState(() => _pr12SelectedCandidates[objectId] = entry.key),
                              onApply: () => _ObjectRuntimePagePr12CandidateApply(this)
                                  ._pr12ApplySelectedCandidate(result, item),
                            );
                          }),
                        ])));
                      }),
                    ],                    if (_pr12IncompleteRecords.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('RECORD INCOMPLETI · PAGINA ${_pr12QueuePage + 1} DI ${(_pr12IncompleteRecords.length / 10).ceil()}', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Mostro 10 record alla volta. Puoi verificare un singolo oggetto oppure selezionarne fino a 10 per una ricerca combinata.', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || _pr12QueuePage == 0 ? null : () => setState(() { _pr12QueuePage--; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(ValoraI18n.tr('PRECEDENTE')),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || (_pr12QueuePage + 1) * 10 >= _pr12IncompleteRecords.length ? null : () => setState(() { _pr12QueuePage++; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(ValoraI18n.tr('SUCCESSIVA')),
                        )),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Text('Selezionati: ${_pr12SelectedRecordIds.length}/10', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold))),
                        TextButton(onPressed: _pr12SelectedRecordIds.isEmpty ? null : () => setState(() => _pr12SelectedRecordIds.clear()), child: const Text('ANNULLA SELEZIONE')),
                      ]),
                      SizedBox(width: double.infinity, child: FilledButton.icon(
                        onPressed: _pr12AiBatchRunning || _pr12SelectedRecordIds.isEmpty ? null : () {
                          final selected = _pr12IncompleteRecords.where((row) => _pr12SelectedRecordIds.contains((row['codice_oggetto'] ?? '').toString())).take(10).toList();
                          _ObjectRuntimePagePr12Runtime(this)._runPr12AiBatch(selectedRecords: selected);
                        },
                        icon: const Icon(Icons.travel_explore),
                        label: Text('VERIFICA ${_pr12SelectedRecordIds.length} SELEZIONATI'),
                      )),
                      const SizedBox(height: 8),
                      ..._pr12IncompleteRecords.skip(_pr12QueuePage * 10).take(10).map((row) {
                        final id = (row['codice_oggetto'] ?? '').toString();
                        final missing = <String>[
                          if ((row['produttore'] ?? '').toString().trim().isEmpty) 'produttore',
                          if (row['anno_uscita'] == null) 'anno',
                          if ((row['codice_prodotto'] ?? '').toString().trim().isEmpty) 'codice prodotto',
                        ];
                        final selected = _pr12SelectedRecordIds.contains(id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Checkbox(
                                value: selected,
                                activeColor: sectionColor,
                                onChanged: _pr12AiBatchRunning ? null : (value) => setState(() {
                                  if (value == true) {
                                    if (_pr12SelectedRecordIds.length < 10) {
                                      _pr12SelectedRecordIds.add(id);
                                      _pr12AiBatchStatus = 'Selezionato il record $id.';
                                    } else {
                                      _pr12AiBatchStatus = 'Puoi selezionare al massimo 10 record.';
                                    }
                                  } else {
                                    _pr12SelectedRecordIds.remove(id);
                                  }
                                }),
                              ),
                              Expanded(child: Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('#$id · ${row['descrizione_oggetto'] ?? 'Senza descrizione'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Mancano: ${missing.join(', ')}', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
                                ]),
                              )),
                              IconButton(
                                tooltip: ValoraI18n.tr('Verifica solo questo record'),
                                onPressed: _pr12AiBatchRunning ? null : () => _ObjectRuntimePagePr12Runtime(this)._runPr12AiBatch(singleRecord: row),
                                icon: const Icon(Icons.search),
                              ),
                            ]),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || _pr12QueuePage == 0 ? null : () => setState(() { _pr12QueuePage--; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(ValoraI18n.tr('INDIETRO')),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || (_pr12QueuePage + 1) * 10 >= _pr12IncompleteRecords.length ? null : () => setState(() { _pr12QueuePage++; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(ValoraI18n.tr('AVANTI')),
                        )),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATO DELLA RICERCA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(_metadataResult),
                    if (_producer.text.isNotEmpty || _line.text.isNotEmpty || _family.text.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text('METADATI SELEZIONATI', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _field(_producer, 'Produttore selezionato'),
                      _field(_line, 'Anno di uscita selezionato'),
                      _field(_family, 'Codice prodotto selezionato'),
                      const Text('I candidati qui sopra sono solo proposte. Il record viene aggiornato esclusivamente dopo aver selezionato un candidato e confermato l’operazione; gli altri campi già compilati vengono conservati.'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}
