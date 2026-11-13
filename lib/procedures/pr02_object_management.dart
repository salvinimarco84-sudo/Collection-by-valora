part of '../main.dart';

// Gestione completa dell'oggetto in PR-02: pagina, scheda, selezione,
// preparazione dati, conferma, persistenza e binding del controller.

/// Composizione della schermata dedicata PR-02.
extension _Pr02PageWorkflow on _ObjectRuntimePageState {
  Widget _buildPr02Page() {
    return Pr02Page(
      sectionColor: sectionColor,
      userLabel: Supabase.instance.client.auth.currentUser?.email ?? 'sessione autenticata',
      lockHeld: _lockHeld,
      status: _output,
      scrollController: _pr02ScrollController,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1 · CERCA OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _search,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _run(_searchPr02Objects),
                    decoration: InputDecoration(
                      labelText: 'Codice oggetto o descrizione',
                      hintText: 'Codice esatto o parte della descrizione',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: 'Cerca',
                        onPressed: _loading ? null : () => _run(_searchPr02Objects),
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  if (_loading) const LinearProgressIndicator(),
                  if (_pr02SearchCompleted && _pr02SearchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Nessun risultato. Verifica il codice o prova una descrizione più breve.'),
                    ),
                  if (_pr02SearchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Risultati: ${_pr02SearchResults.length}. Tocca il record da modificare.'),
                    ..._pr02SearchResults.map((item) => Card(
                      margin: const EdgeInsets.only(top: 6),
                      child: ListTile(
                        title: Text('${item['codice_oggetto'] ?? ''} · ${item['descrizione_oggetto'] ?? item['descrizione'] ?? item['nome'] ?? 'Senza descrizione'}'),
                        subtitle: Text('Stato: ${item['stato'] ?? 'Non indicato'}'),
                        trailing: const Icon(Icons.chevron_right),
                        selected: _currentObject?['codice_oggetto']?.toString() == item['codice_oggetto']?.toString(),
                        onTap: _loading ? null : () => _run(() => _selectPr02Object(item)),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          if (_pr02PendingChanges.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Blocco provvisorio: ${_pr02PendingChanges.length} oggetti confermati',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (_currentObject != null && !_pr02AwaitingNextChoice) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2 · DATI OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _pr02MetadataCard(_currentObject!),
                    if (_destination == 'COLLEZIONE') _collectionCategoryField(),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('SCHEDA OGGETTO'), icon: Icon(Icons.edit_note)),
                        ButtonSegment(value: true, label: Text('DATI TECNICI'), icon: Icon(Icons.info_outline)),
                      ],
                      selected: {_showPr02TechnicalTab},
                      onSelectionChanged: (value) => setState(() => _showPr02TechnicalTab = value.first),
                    ),
                    const SizedBox(height: 10),
                    if (_showPr02TechnicalTab)
                      _pr02TechnicalCard(_currentObject!)
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 620) {
                            return Column(
                              children: [
                                _pr02Side(oldValues: true),
                                _pr02Side(oldValues: false),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _pr02Side(oldValues: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _pr02Side(oldValues: false)),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : () => _run(_confirmPr02Changes),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('CONFERMA DATI E AGGIUNGI AL BLOCCO'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_pr02AwaitingNextChoice)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3 · MODIFICA CONFERMATA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Ultima modifica salvata e verificata. Modifiche in attesa: ${_pr02PendingChanges.length}.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _continuePr02WithAnotherObject,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('SÌ, MODIFICA UN ALTRO OGGETTO'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('NO, TERMINA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Presentazione della scheda, dei metadati e del confronto valori PR-02.
extension _Pr02ObjectPresentation on _ObjectRuntimePageState {
  Widget _pr02MetadataCard(Map<String, dynamic> object) {
    const imageKeys = [
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    ];
    String valueFor(List<String> keys) {
      for (final key in keys) {
        final value = object[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
      }
      return 'Non disponibile';
    }
    final imageUrl = valueFor(imageKeys);
    final hasImage = imageUrl != 'Non disponibile' &&
        (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'));
    final producer = valueFor(['produttore']);
    final year = valueFor(['anno_uscita', 'data_uscita', 'data_di_uscita']);
    final productCode = valueFor(['codice_prodotto']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('METADATI DEL PRODOTTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(_valoraImageProxyUrl(imageUrl), fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined, color: ValoraAppearance.instance.textFaint, size: 36))
                  : Icon(Icons.image_outlined, color: ValoraAppearance.instance.textFaint, size: 36),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _metadataValue('Produttore', producer),
              const SizedBox(height: 8),
              _metadataValue('Data di uscita', year),
              const SizedBox(height: 8),
              _metadataValue('Codice prodotto', productCode),
            ])),
          ]),
          const SizedBox(height: 8),
          Text('Metadati informativi, non modificabili da questa scheda.',
            style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _metadataValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: sectionColor, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: ValoraAppearance.instance.textPrimary, fontSize: 13)),
    ],
  );

  Widget _pr02TechnicalCard(Map<String, dynamic> object) {
    const operationalKeys = {
      'codice_oggetto', 'descrizione_oggetto', 'descrizione', 'produttore',
      'anno_uscita', 'data_uscita', 'data_di_uscita', 'codice_prodotto',
      'condizione', 'completezza', 'destinazione', 'quantita',
      'valore_oggetto', 'valore', 'note', 'stato',
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    };
    final technicalEntries = object.entries
        .where((entry) => !operationalKeys.contains(entry.key))
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DATI TECNICI · SOLA LETTURA',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Divider(height: 24),
          if (technicalEntries.isEmpty)
            Text('Nessun altro dato tecnico presente nel record.',
              style: TextStyle(color: ValoraAppearance.instance.textMuted))
          else
            ...technicalEntries.map((entry) => _detailFieldCard(entry.key, entry.value)),
        ]),
      ),
    );
  }

  Widget _pr02Side({required bool oldValues}) {
    final object = _currentObject ?? <String, dynamic>{};
    final title = oldValues ? 'VECCHI VALORI · SOLA LETTURA' : 'NUOVI VALORI · MODIFICABILI';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (oldValues) ...[
            _detailFieldCard('codice_oggetto', object['codice_oggetto']),
            _detailFieldCard('descrizione_oggetto', object['descrizione_oggetto']),
            _detailFieldCard('produttore', object['produttore']),
            _detailFieldCard('anno_uscita', object['anno_uscita']),
            _detailFieldCard('codice_prodotto', object['codice_prodotto']),
            _detailFieldCard('fonte_dati_prodotto', object['fonte_dati_prodotto']),
            _detailFieldCard('condizione', object['condizione']),
            _detailFieldCard('completezza', object['completezza']),
            _detailFieldCard('destinazione', object['destinazione']),
            _detailFieldCard('quantita', object['quantita']),
            _detailFieldCard('valore_oggetto', object['valore_oggetto']),
            _detailFieldCard('note', object['note']),
            _detailFieldCard('stato', object['stato']),
          ] else ...[
            _field(_description, 'Descrizione oggetto', focusNode: _descriptionFocus),
            _field(_producer, 'Produttore'),
            _field(_line, 'Anno di uscita', type: TextInputType.number),
            _field(_family, 'Codice prodotto'),
            _detailFieldCard('fonte_dati_prodotto', _metadataSourceUrl ?? object['fonte_dati_prodotto']),
            _detailFieldCard('stato_verifica_dati', object['stato_verifica_dati'] ?? 'DA_VERIFICARE'),
            _dropdown('Condizione', _condition, const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], (v) => setState(() => _condition = v!)),
            _dropdown('Completezza', _completeness, const ['SIGILLATO','COMPLETO','COMPLETO CON ISTRUZIONI','COMPLETO CON SCATOLA E ISTRUZIONI','INCOMPLETO'], (v) => setState(() => _completeness = v!)),
            _dropdown('Destinazione', _destination, const ['COLLEZIONE','RIVENDITA','ALTRO'], (v) => setState(() => _destination = v!)),
            _field(_quantity, 'Quantità', type: TextInputType.number),
            _field(_value, 'Prezzo unitario (€)', type: const TextInputType.numberWithOptions(decimal: true)),
            _field(_notes, 'Note', lines: 2),
            const SizedBox(height: 8),
            _imageField(),
          ],
        ]),
      ),
    );
  }
}

/// Selezione del record e caricamento della scheda per PR-02.
extension _Pr02SelectionWorkflow on _ObjectRuntimePageState {
  Future<void> _selectPr02Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null) throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text = id.toString();
    _showPr02TechnicalTab = false;
    await _loadObject();
    if (!mounted || _currentObject == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_descriptionFocus);
    });
  }
}

/// Costruzione e validazione del payload di modifica PR-02.
extension _Pr02PayloadWorkflow on _ObjectRuntimePageState {
  Map<String, dynamic> _buildPr02Payload() {
    final id = int.tryParse(_code.text.trim());
    if (id == null || id <= 0) throw Exception('Inserisci un codice oggetto valido.');
    if (_loadedObjectId != id) throw Exception('Carica la scheda completa del codice selezionato prima di procedere.');
  final item = <String, dynamic>{'codice_oggetto': id};
  if (_description.text.trim() != (_currentObject?['descrizione_oggetto'] ?? _currentObject?['descrizione'] ?? '').toString()) {
    item['descrizione'] = _description.text.trim();
  }
  if (_condition != (_currentObject?['condizione'] ?? _condition)) item['condizione'] = _condition;
  if (_completeness != (_currentObject?['completezza'] ?? _completeness)) item['completezza'] = _completeness;
  if (_destination != (_currentObject?['destinazione'] ?? _destination)) item['destinazione'] = _destination;
  if (_destination == 'COLLEZIONE') {
    if (_selectedCollectionCategory == null || !_collectionCategories.any((e) => e['codice_categoria'] == _selectedCollectionCategory)) throw Exception('Seleziona una categoria COLLEZIONE valida.');
    item['categoria_collezione_selezionata'] = _selectedCollectionCategory;
  } else {
    item['categoria_collezione_selezionata'] = null;
  }
  if (_notes.text.trim() != (_currentObject?['note'] ?? '').toString()) item['note'] = _notes.text.trim().isEmpty ? null : _notes.text.trim();
  if (_quantity.text.trim() != (_currentObject?['quantita'] ?? '1').toString()) {
    final q = int.tryParse(_quantity.text.trim());
    if (q == null || q < 1) throw Exception('La quantità deve essere un intero maggiore di zero.');
    item['quantita'] = q;
  }
  if (_producer.text.trim() != (_currentObject?['produttore'] ?? '').toString()) item['produttore'] = _producer.text.trim().isEmpty ? null : _producer.text.trim();
  if (_line.text.trim() != (_currentObject?['anno_uscita'] ?? '').toString()) {
    final year = _line.text.trim().isEmpty ? null : int.tryParse(_line.text.trim());
    if (_line.text.trim().isNotEmpty && year == null) throw Exception('Anno di uscita non valido.');
    item['anno_uscita'] = year;
  }
  if (_family.text.trim() != (_currentObject?['codice_prodotto'] ?? '').toString()) item['codice_prodotto'] = _family.text.trim().isEmpty ? null : _family.text.trim();
  final currentSource = (_currentObject?['fonte_dati_prodotto'] ?? '').toString().trim();
  final proposedSource = (_metadataSourceUrl ?? '').trim();
  if (proposedSource.isNotEmpty && proposedSource != currentSource) {
    item['fonte_dati_prodotto'] = proposedSource;
    item['stato_verifica_dati'] = 'DA_VERIFICARE';
  }
  final currentValueRaw = _currentObject?['valore_oggetto'] ?? _currentObject?['valore'];
  final currentValueText = currentValueRaw == null ? '' : currentValueRaw.toString().trim();
  final proposedValueText = _value.text.trim().replaceAll(',', '.');
  if (proposedValueText != currentValueText.replaceAll(',', '.')) {
    if (proposedValueText.isEmpty) {
      item['valore_oggetto'] = null;
    } else {
      final n = double.tryParse(proposedValueText);
      if (n == null || n < 0) throw Exception('Valore oggetto non valido.');
      item['valore_oggetto'] = n;
    }
  }
  if (item.length == 1 && (_selectedImageBytes == null || _selectedImageName == null)) throw Exception('Nessuna modifica rilevata.');
  return {'oggetti': [item]};
  }
}

/// Persistenza e verifica delle modifiche confermate da PR-02.
extension _Pr02SaveWorkflow on _ObjectRuntimePageState {
  Future<void> _savePr02PendingChanges({bool closeOnComplete = true}) async {
    final pending = _pr02PendingChanges
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    for (final item in pending) {
      final categoryCode = item['categoria_collezione_selezionata']?.toString();
      final objectPayload = Map<String, dynamic>.from(item)..remove('categoria_collezione_selezionata');
      final objectHasChanges = objectPayload.keys.any((key) => key != 'codice_oggetto');
      final payload = <String, dynamic>{
        'oggetti': [objectPayload],
        'dati_confermati': true,
        'altra_operazione': false,
        'conferma_finale': true,
      };
      final pendingImage = _pr02PendingImages[item['codice_oggetto'].toString()];
      if (objectHasChanges) await _acquireLock();
      try {
        if (objectHasChanges) {
        final preview = await _ValoraRuntimeApi.procedure(
          'PR-02', 'preview', payload, sessionId: _sessionId);
        if (preview['errore'] != null) {
          throw Exception(preview['errore'].toString());
        }
        await _ValoraRuntimeApi.procedure(
          'PR-02', 'review', payload, sessionId: _sessionId);
        final result = await _ValoraRuntimeApi.procedure(
          'PR-02', 'save', payload, sessionId: _sessionId, requestId: _uuid.v4());
        if (result['scrittura_eseguita'] != true) {
          throw Exception('Salvataggio non confermato per oggetto ${item['codice_oggetto']}.');
        }
        if (result['blocco_rilasciato_automaticamente'] == true) {
          setState(() => _lockHeld = false);
        } else {
          throw Exception('Salvataggio eseguito ma rilascio del blocco non confermato.');
        }
        }
        final objectIdForCategory = int.tryParse(item['codice_oggetto'].toString());
        if (objectIdForCategory != null) {
          if (categoryCode != null && categoryCode.isNotEmpty) {
            await Supabase.instance.client.schema('collection').from('oggetto_collezione_categoria').upsert({
              'codice_oggetto': objectIdForCategory, 'codice_categoria': categoryCode,
              'fonte_assegnazione': 'MANUALE', 'stato_verifica': 'VERIFICATO',
              'aggiornato_il': DateTime.now().toIso8601String(),
            }, onConflict: 'codice_oggetto');
          } else {
            await Supabase.instance.client.schema('collection').from('oggetto_collezione_categoria')
              .delete().eq('codice_oggetto', objectIdForCategory);
          }
        }
        if (pendingImage != null) {
          final signedUrl = await _uploadAndRegisterImage(
            objectId: int.parse(item['codice_oggetto'].toString()), bytes: pendingImage['bytes'] as Uint8List,
            fileName: pendingImage['name'] as String, acquisition: pendingImage['acquisition'] as String, procedure: 'PR-02');
          _pr02PendingImages.remove(item['codice_oggetto'].toString());
          if (_loadedObjectId == int.tryParse(item['codice_oggetto'].toString()) && mounted) {
            setState(() { _existingImageUrl = signedUrl; _imageStatus = 'Immagine associata e verificata.'; });
          }
        }
      } catch (_) {
        if (_lockHeld) {
          try { await _releaseLock(); } catch (_) {}
        }
        rethrow;
      }
    }
    _pr02PendingChanges.clear();
    if (!mounted || !closeOnComplete) return;
    Navigator.of(context).pop();
  }
}

/// Conferma della modifica e passaggio all'oggetto successivo in PR-02.
extension _Pr02ConfirmationWorkflow on _ObjectRuntimePageState {
  /// Estrae il record singolo dal payload PR-02 da confermare.
  Map<String, dynamic> _pr02ConfirmationPayload() {
    final payload = _payload();
    final rows = payload['oggetti'];
    if (rows is! List || rows.isEmpty || rows.first is! Map) {
      throw Exception('Non ci sono modifiche valide da confermare.');
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<void> _confirmPr02Changes() async {
    if (_currentObject == null || _loadedObjectId == null) {
      throw Exception('Seleziona prima un oggetto dalla ricerca.');
    }

    // Ogni oggetto viene salvato e verificato prima di consentire una nuova modifica.
    final item = _pr02ConfirmationPayload();
    final objectCode = item['codice_oggetto']?.toString();
    if (objectCode == null || objectCode.isEmpty) {
      throw Exception('Codice oggetto mancante: impossibile accodare la modifica.');
    }

    _pr02PendingChanges.removeWhere(
      (e) => e['codice_oggetto']?.toString() == objectCode,
    );
    _pr02PendingChanges.add(Map<String, dynamic>.from(item));

    if (_selectedImageBytes != null && _selectedImageName != null) {
      _pr02PendingImages[objectCode] = {
        'bytes': Uint8List.fromList(_selectedImageBytes!),
        'name': _selectedImageName!,
        'acquisition': _imageAcquisition,
      };
    }

    if (_lockHeld) await _releaseLock();
    if (!mounted) return;

    await _savePr02PendingChanges(closeOnComplete: false);
    if (!mounted) return;

    setState(() {
      _dataConfirmed = true;
      _finalReady = false;
      _pr02AwaitingNextChoice = true;
      _output = 'Oggetto $objectCode salvato e verificato. Puoi modificare un altro oggetto oppure terminare.';
    });
  }

  Future<void> _continuePr02WithAnotherObject() async {
      setState(() {
        _search.clear();
        _code.clear();
        _description.clear();
        _notes.clear();
        _producer.clear();
        _line.clear();
        _family.clear();
        _value.clear();
        _currentObject = null;
        _loadedObjectId = null;
        _pr02SearchResults = [];
        _pr02SearchCompleted = false;
        _metadataSourceUrl = null;
        _metadataSearchExecuted = false;
        _metadataResult = 'Inserisci una parola o parte della descrizione per iniziare.';
        _lastResult = null;
        _dataConfirmed = false;
        _finalReady = false;
        _showPr02TechnicalTab = false;
        _selectedImageBytes = null; _selectedImageName = null; _existingImageUrl = null;
        _imageStatus = 'Nessuna immagine selezionata.';
        _output = 'PR-02 pronta per una nuova ricerca.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
      });
      setState(() => _pr02AwaitingNextChoice = false);
      return;
  }

  Future<void> _finishPr02PendingChanges() async {
    if (_pr02PendingChanges.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await _savePr02PendingChanges();
  }
}

/// Accessori di stato PR-02 delegati al controller dedicato.
extension _Pr02ControllerBindings on _ObjectRuntimePageState {
  List<Map<String, dynamic>> get _pr02SearchResults =>
      _pr02Controller.searchResults;
  set _pr02SearchResults(List<Map<String, dynamic>> value) =>
      _pr02Controller.searchResults = value;

  bool get _showPr02TechnicalTab => _pr02Controller.showTechnicalTab;
  set _showPr02TechnicalTab(bool value) =>
      _pr02Controller.showTechnicalTab = value;

  bool get _pr02SearchCompleted => _pr02Controller.searchCompleted;
  set _pr02SearchCompleted(bool value) =>
      _pr02Controller.searchCompleted = value;

  List<Map<String, dynamic>> get _pr02PendingChanges =>
      _pr02Controller.pendingChanges;

  bool get _pr02AwaitingNextChoice =>
      _pr02Controller.awaitingNextChoice;
  set _pr02AwaitingNextChoice(bool value) =>
      _pr02Controller.awaitingNextChoice = value;

  ScrollController get _pr02ScrollController =>
      _pr02Controller.scrollController;

  Map<String, Map<String, dynamic>> get _pr02PendingImages =>
      _pr02Controller.pendingImages;
}