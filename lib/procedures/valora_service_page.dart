part of '../main.dart';

class ValoraServicePage extends StatefulWidget {
  const ValoraServicePage({super.key});
  @override
  State<ValoraServicePage> createState() => _ValoraServicePageState();
}

class _ValoraServicePageState extends State<ValoraServicePage> {
  bool _loading = true;
  bool _preparing = false;
  bool _analyzingPhotos = false;
  final List<Map<String, dynamic>> _photoSearchResults = [];
  final Map<int, String> _selectedPhotoCandidates = {};
  final Map<int, Map<String, dynamic>> _confirmedPhotoCandidates = {};
  final Map<int, String> _metadataValuationStatus = {};
  final Set<String> _reviewedCandidateUrls = {};
  String? _error;
  final TextEditingController _descriptionQuery = TextEditingController();
  List<Map<String, dynamic>> _objects = [];
  final List<XFile> _selectedImages = [];
  final List<PlatformFile> _selectedFiles = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final images = await picker.pickMultiImage(imageQuality: 92);
        if (!mounted || images.isEmpty) return;
        setState(() {
          for (final image in images) {
            if (_selectedImages.every((item) => item.path != image.path)) {
              _selectedImages.add(image);
            }
          }
        });
      } else {
        final image = await picker.pickImage(source: source, imageQuality: 92);
        if (!mounted || image == null) return;
        setState(() => _selectedImages.add(image));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Selezione immagine non riuscita: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (!mounted || result == null) return;
      setState(() {
        for (final file in result.files) {
          if (_selectedFiles.every((item) => item.name != file.name || item.size != file.size)) {
            _selectedFiles.add(file);
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Selezione file non riuscita: $e');
    }
  }

  void _removeImage(XFile image) => setState(() => _selectedImages.remove(image));
  void _removeFile(PlatformFile file) => setState(() => _selectedFiles.remove(file));


  Future<Map<String, dynamic>> _analyzeImageBytes(Uint8List bytes, String fileName) async {
    if (bytes.isEmpty) throw Exception('Il file $fileName è vuoto o non leggibile.');
    if (bytes.length > 10 * 1024 * 1024) throw Exception('Il file $fileName supera il limite di 10 MB.');
    final name = fileName.toLowerCase();
    final mime = name.endsWith('.png') ? 'image/png' : name.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
    final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
      'azione': 'ANALIZZA_FOTO',
      'modalita_ia': 'TEST',
      'image_data_url': 'data:$mime;base64,${base64Encode(bytes)}',
      'mercato': _market,
    });
    final data = response.data;
    if (data is! Map || data['ok'] != true) {
      throw Exception(data is Map ? (data['error'] ?? 'Ricerca foto non riuscita').toString() : 'Risposta PR-12 non valida.');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<void> _analyzeSelectedPhotos() async {
    if (_selectedImages.isEmpty && _selectedFiles.isEmpty) {
      setState(() => _error = 'Seleziona almeno una foto o un file immagine da usare nella ricerca.');
      return;
    }
    setState(() { _analyzingPhotos = true; _error = null; _photoSearchResults.clear(); });
    try {
      final inputs = <({String name, Future<Uint8List> bytes})>[
        ..._selectedImages.map((image) => (name: image.name, bytes: image.readAsBytes())),
        ..._selectedFiles.map((file) => (name: file.name, bytes: Future.value(file.bytes ?? Uint8List(0)))),
      ];
      for (final input in inputs) {
        final data = await _analyzeImageBytes(await input.bytes, input.name);
        if (!mounted) return;
        setState(() => _photoSearchResults.add({
          'nome_foto': input.name,
          'identificazione': data['identificazione'] is Map ? Map<String, dynamic>.from(data['identificazione']) : <String, dynamic>{},
          'risultati': data['risultati'] is List ? List<dynamic>.from(data['risultati']) : <dynamic>[],
          'diagnostica': data['diagnostica_ricerca'],
          'query_eseguite': data['query_eseguite'] is List ? List<String>.from(data['query_eseguite']) : <String>[],
          'categoria': (data['identificazione'] is Map ? data['identificazione']['categoria'] : '').toString(),
          'tema': (data['identificazione'] is Map ? data['identificazione']['marchio'] : '').toString(),
          'ricerche_estese': 0,
          'scrittura_database': false,
        }));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Ricerca da foto non completata: $e');
    } finally {
      if (mounted) setState(() => _analyzingPhotos = false);
    }
  }

  void _confirmPhotoCandidate(int index) {
    final url = _selectedPhotoCandidates[index];
    if (url == null || index < 0 || index >= _photoSearchResults.length) return;
    final result = _photoSearchResults[index];
    final candidate = (result['risultati'] as List? ?? []).whereType<Map>()
        .cast<Map<String, dynamic>>().where((item) => (item['url'] ?? '').toString() == url).firstOrNull;
    if (candidate == null) {
      setState(() => _error = 'Il candidato selezionato non è più disponibile. Ripeti la ricerca.');
      return;
    }
    setState(() {
      _confirmedPhotoCandidates[index] = Map<String, dynamic>.from(candidate);
      _reviewedCandidateUrls.add(url);
      _error = null;
    });
  }

  Future<void> _retryPhotoSearch(int index) async {
    if (index < 0 || index >= _photoSearchResults.length) return;
    final current = _photoSearchResults[index];
    final clues = Map<String, dynamic>.from(current['identificazione'] as Map? ?? {});
    final candidates = (current['risultati'] as List? ?? []).whereType<Map>().toList();
    final excludedUrls = <String>{
      ..._reviewedCandidateUrls,
      ...candidates.map((item) => (item['url'] ?? '').toString()).where((url) => url.startsWith('http')),
    };
    final excludedQueries = (current['query_eseguite'] as List? ?? []).map((e) => e.toString()).toSet();
    setState(() { _analyzingPhotos = true; _error = null; });
    try {
      final response = await Supabase.instance.client.functions.invoke('pr-12-web-search-test', body: {
        'descrizione': (clues['descrizione_provvisoria'] ?? '').toString(),
        'categoria': (current['categoria'] ?? clues['categoria'] ?? '').toString(),
        'tema': (current['tema'] ?? clues['marchio'] ?? '').toString(),
        'mercato': _market,
        'ricerca_estesa': true,
        'escludi_url': excludedUrls.toList(),
        'escludi_query': excludedQueries.toList(),
      });
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['error'] ?? 'Nuova ricerca non riuscita').toString() : 'Risposta PR-12 non valida.');
      }
      final added = (data['risultati'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final old = candidates.map((e) => Map<String, dynamic>.from(e)).toList();
      final known = old.map((e) => (e['url'] ?? '').toString()).toSet();
      for (final item in added) {
        final url = (item['url'] ?? '').toString();
        if (url.isNotEmpty && known.add(url)) old.add(item);
      }
      if (!mounted) return;
      setState(() {
        current['risultati'] = old;
        current['query_eseguite'] = [
          ...excludedQueries,
          ...((data['query_eseguite'] as List? ?? []).map((e) => e.toString())),
        ].toSet().toList();
        current['ricerche_estese'] = ((current['ricerche_estese'] as int?) ?? 0) + 1;
        current['diagnostica'] = data['diagnostica'];
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Nuova ricerca PR-12 non completata: $e');
    } finally {
      if (mounted) setState(() => _analyzingPhotos = false);
    }
  }

  Future<void> _openUncataloguedCandidate(int index) async {
    if (index < 0 || index >= _photoSearchResults.length) return;
    final candidate = _confirmedPhotoCandidates[index];
    if (candidate == null) {
      setState(() => _error = 'Conferma prima il candidato PR-12. Nessun record verrà creato da un candidato non verificato.');
      return;
    }
    final result = _photoSearchResults[index];
    final clues = Map<String, dynamic>.from(result['identificazione'] as Map? ?? {});
    final title = (candidate['title'] ?? clues['descrizione_provvisoria'] ?? '').toString().trim();
    if (title.isEmpty) {
      setState(() => _error = 'Il candidato confermato non contiene una descrizione utilizzabile. Completa prima i metadati.');
      return;
    }
    final maker = (candidate['produttore'] ?? candidate['editore'] ?? clues['marchio'] ?? '').toString().trim();
    final code = (candidate['codice_prodotto'] ?? candidate['isbn'] ?? clues['codice_prodotto'] ?? '').toString().trim();
    final yearValue = candidate['anno_uscita'] ?? candidate['anno_pubblicazione'] ?? candidate['year'];
    final yearMatch = RegExp(r'(19\d{2}|20\d{2})').firstMatch(yearValue?.toString() ?? '');
    final sourceUrl = (candidate['url'] ?? '').toString().trim();
    final imageUrl = (candidate['image_url'] ?? candidate['immagine_url'] ?? candidate['url_immagine'] ?? '').toString().trim();
    final metadata = <String, dynamic>{
      'descrizione': title,
      if (maker.isNotEmpty) 'produttore': maker,
      if (code.isNotEmpty) 'codice_prodotto': code,
      if (yearMatch != null) 'anno_uscita': int.tryParse(yearMatch.group(1)!),
      if (sourceUrl.startsWith('https://') || sourceUrl.startsWith('http://')) 'fonte_dati_prodotto': sourceUrl,
      if (imageUrl.startsWith('https://') || imageUrl.startsWith('http://')) 'url_immagine_catalogo': imageUrl,
    };
    if (!mounted) return;
    setState(() { _error = null; _analyzingPhotos = true; });
    Map<String, dynamic>? valuation;
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'pr-18-valuation-test',
        body: {
          'metadati': metadata,
          'mercato_riferimento': _market,
        },
      );
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw Exception(data is Map
            ? (data['error'] ?? 'PR18 non ha completato la valutazione').toString()
            : 'Risposta PR18 non valida.');
      }
      valuation = Map<String, dynamic>.from(data);
      final marketValue = valuation['valore_mercato'];
      final reliability = (valuation['affidabilita'] ?? 'NON DISPONIBILE').toString();
      if (mounted) {
        setState(() => _metadataValuationStatus[index] = marketValue is num
            ? 'PR18: € ${marketValue.toStringAsFixed(2)} · affidabilità $reliability'
            : 'PR18: nessun prezzo verificabile · affidabilità $reliability');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _metadataValuationStatus[index] = 'PR18_NON_COMPLETATA: $e');
      }
    } finally {
      if (mounted) setState(() => _analyzingPhotos = false);
    }
    if (!mounted) return;
    final valuationText = valuation == null
        ? 'PR18 non ha restituito una valutazione. Puoi comunque inserire l’oggetto, ma il valore di mercato resterà da determinare.'
        : (valuation['valore_mercato'] is num
            ? 'Valore indicativo: € ${(valuation['valore_mercato'] as num).toStringAsFixed(2)}\\n'
                'Fascia: € ${valuation['fascia_minima'] ?? 'n.d.'} - € ${valuation['fascia_massima'] ?? 'n.d.'}\\n'
                'Affidabilità: ${valuation['affidabilita'] ?? 'NON DISPONIBILE'}\\n'
                'Comparabili con prezzo: ${valuation['numero_comparabili_con_prezzo_estratto'] ?? 0}. I prezzi estratti vanno verificati.'
            : 'PR18 ha completato la ricerca, ma non ha trovato prezzi verificabili. Non verrà inventato un valore.');
    final addObject = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Valutazione PR18'),
        content: Text('$valuationText\\n\\nVuoi procedere con PR-04 Nuovo Acquisto?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('PROCEDI A PR-04')),
        ],
      ),
    );
    if (addObject != true || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NewPurchasePage(
        initialMetadata: metadata,
        suggestedMarketValue: valuation?['valore_mercato'] is num
            ? (valuation!['valore_mercato'] as num).toDouble()
            : null,
      ),
    ));
    if (mounted) {
      setState(() {
        _descriptionQuery.text = title;
        _selectedId = null;
        _prepared = null;
      });
      await _loadObjects();
    }
  }

  List<Map<String, dynamic>> get _matchingObjects {
    final query = _descriptionQuery.text.trim().toLowerCase();
    if (query.isEmpty) return _objects;
    return _objects.where((object) =>
      (object['descrizione_oggetto'] ?? '').toString().toLowerCase().contains(query)
    ).toList();
  }

  @override
  void dispose() {
    _descriptionQuery.dispose();
    super.dispose();
  }
  int? _selectedId;
  String _market = 'ITALIA';
  Map<String, dynamic>? _prepared;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  Future<void> _loadObjects() async {
    setState(() { _loading = true; _error = null; });
    try {
      const pageSize = 500;
      var offset = 0;
      final rows = <Map<String, dynamic>>[];
      const excludedStatuses = {
        'VENDUTO', 'SOLD', 'PERSO', 'LOST', 'DISTRUTTO', 'DESTROYED',
        'USCITO', 'EXITED', 'ACCORPATO', 'MERGED',
      };

      // Legge tutte le pagine: il limite di una singola richiesta non deve
      // nascondere oggetti validi che si trovano oltre i primi 500 record.
      while (true) {
        final page = await Supabase.instance.client.schema('collection')
            .from('master_oggetti')
            .select('codice_oggetto,descrizione_oggetto,produttore,codice_prodotto,stato,destinazione,condizione,completezza,valore_mercato')
            .or('archiviato_test.is.null,archiviato_test.eq.false')
            .order('descrizione_oggetto')
            .order('codice_oggetto')
            .range(offset, offset + pageSize - 1);

        final pageRows = (page as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((row) => !excludedStatuses.contains(
                (row['stato'] ?? '').toString().trim().toUpperCase()))
            .toList();
        rows.addAll(pageRows);

        if (page.length < pageSize) break;
        offset += pageSize;
      }

      if (!mounted) return;
      setState(() { _objects = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossibile caricare gli oggetti della collezione: $e'; _loading = false; });
    }
  }


  double? _marketPriceFrom(dynamic value) {
    const keys = ['valore_mercato', 'valore_mercato_eur', 'valore_stimato', 'prezzo_suggerito'];
    if (value is Map) {
      for (final key in keys) {
        final parsed = double.tryParse((value[key] ?? '').toString().replaceAll(',', '.'));
        if (parsed != null && parsed.isFinite && parsed > 0) return parsed;
      }
      for (final nested in value.values) {
        final found = _marketPriceFrom(nested);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final nested in value) {
        final found = _marketPriceFrom(nested);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> _openCatalogObjectForSale() async {
    final id = _selectedId;
    final object = _objects.where((row) => row['codice_oggetto'] == id).firstOrNull;
    if (id == null || object == null) {
      setState(() => _error = 'Seleziona un oggetto della collezione.');
      return;
    }
    final state = (object['stato'] ?? '').toString().trim().toUpperCase();
    if (state != 'DISPONIBILE') {
      setState(() => _error = 'L’oggetto non è disponibile per la vendita (stato: ${state.isEmpty ? 'non indicato' : state}).');
      return;
    }
    // La vendita è indipendente dalla valutazione: usa il valore già registrato
    // solo come prezzo iniziale facoltativo. Se manca, l'utente lo inserirà in PR-06.
    final price = _marketPriceFrom(object['valore_mercato']);
    final session = _uuid.v4();
    var locked = false;
    var destinationChanged = false;
    setState(() { _preparing = true; _error = null; });
    try {
      final destination = (object['destinazione'] ?? '').toString().trim().toUpperCase();
      if (destination != 'RIVENDITA') {
        final lock = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': session});
        final lockData = lock['result'];
        if (lockData is! Map || lockData['acquisito'] != true) {
          throw StateError((lockData is Map ? lockData['messaggio'] : null)?.toString() ?? 'Blocco archivio non acquisito.');
        }
        locked = true;
        final payload = <String, dynamic>{
          'oggetti': [{'codice_oggetto': id, 'destinazione': 'RIVENDITA'}],
          'dati_confermati': true,
          'altra_operazione': false,
          'conferma_finale': true,
        };
        final preview = await _ValoraRuntimeApi.procedure('PR-02', 'preview', payload, sessionId: session);
        if (preview['errore'] != null || preview['scrittura_eseguita'] == true) {
          throw StateError((preview['errore'] ?? 'Anteprima PR-02 non valida.').toString());
        }
        await _ValoraRuntimeApi.procedure('PR-02', 'review', payload, sessionId: session);
        final saved = await _ValoraRuntimeApi.procedure('PR-02', 'save', payload,
          sessionId: session, requestId: _uuid.v4());
        if (saved['scrittura_eseguita'] != true || saved['blocco_rilasciato_automaticamente'] != true) {
          throw StateError('Cambio destinazione non verificato dal runtime.');
        }
        locked = false;
        destinationChanged = true;
      }
      if (!mounted) return;
      final saleSaved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => NewSalePage(initialObjectCode: id, initialSalePrice: price),
      ));
      if (destinationChanged && saleSaved != true) {
        final rollbackSession = _uuid.v4();
        final rollbackLock = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': rollbackSession});
        final rollbackLockData = rollbackLock['result'];
        if (rollbackLockData is Map && rollbackLockData['acquisito'] == true) {
          try {
            final rollbackPayload = <String, dynamic>{
              'oggetti': [{'codice_oggetto': id, 'destinazione': destination}],
              'dati_confermati': true,
              'altra_operazione': false,
              'conferma_finale': true,
            };
            final rollbackPreview = await _ValoraRuntimeApi.procedure('PR-02', 'preview', rollbackPayload, sessionId: rollbackSession);
            if (rollbackPreview['errore'] == null && rollbackPreview['scrittura_eseguita'] != true) {
              await _ValoraRuntimeApi.procedure('PR-02', 'review', rollbackPayload, sessionId: rollbackSession);
              final rollback = await _ValoraRuntimeApi.procedure('PR-02', 'save', rollbackPayload,
                sessionId: rollbackSession, requestId: _uuid.v4());
              if (rollback['scrittura_eseguita'] != true || rollback['blocco_rilasciato_automaticamente'] != true) {
                throw StateError('Ripristino destinazione non verificato.');
              }
            } else {
              throw StateError('Anteprima ripristino non valida.');
            }
          } finally {
            try { await _ValoraRuntimeApi.call('release_lock', {'session_id': rollbackSession}); } catch (_) {}
          }
        } else {
          throw StateError('Impossibile acquisire il blocco per ripristinare la destinazione originaria.');
        }
      }
      if (mounted) await _loadObjects();
    } catch (e) {
      if (locked) {
        try { await _ValoraRuntimeApi.call('release_lock', {'session_id': session}); } catch (_) {}
      }
      if (mounted) setState(() => _error = 'Avvio PR-06 non completato: $e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _prepareValuation() async {
    final id = _selectedId;
    final object = _objects.where((row) => row['codice_oggetto'] == id).firstOrNull;
    if (id == null || object == null) {
      setState(() => _error = 'Seleziona prima un oggetto della collezione.');
      return;
    }
    final state = (object['stato'] ?? '').toString().trim().toUpperCase();
    if (state.isEmpty || {'VENDUTO','SOLD','PERSO','LOST','DISTRUTTO','DESTROYED','USCITO','EXITED','ACCORPATO','MERGED'}.contains(state)) {
      setState(() => _error = 'L’oggetto non è idoneo alla valutazione VALORA.');
      return;
    }
    final metadata = <String, dynamic>{
      'descrizione': (object['descrizione_oggetto'] ?? '').toString(),
      'produttore': (object['produttore'] ?? '').toString(),
      'codice_prodotto': (object['codice_prodotto'] ?? '').toString(),
      'categoria': (object['categoria'] ?? '').toString(),
    };
    setState(() { _preparing = true; _error = null; _prepared = null; });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'pr-18-valuation-test',
        body: {
          'codice_oggetto': id,
          'metadati': metadata,
          'mercato_riferimento': _market,
        },
      );
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw StateError(data is Map
          ? (data['error'] ?? 'PR18 non ha completato la valutazione.').toString()
          : 'Risposta PR18 non valida.');
      }
      if (!mounted) return;
      setState(() => _prepared = Map<String, dynamic>.from(data));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Valutazione PR18 non riuscita: $e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _saveKnownObjectValuation(
    int objectId,
    Map<String, dynamic> object,
    Map<String, dynamic> valuation,
  ) async {
    setState(() { _preparing = true; _error = null; });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'pr-18-valuation-test',
        body: {
          'azione': 'SALVA_VALUTAZIONE',
          'codice_oggetto': objectId,
          'metadati': {
            'descrizione': (object['descrizione_oggetto'] ?? '').toString(),
            'produttore': (object['produttore'] ?? '').toString(),
            'codice_prodotto': (object['codice_prodotto'] ?? '').toString(),
          },
          'mercato_riferimento': _market,
          'valutazione': valuation,
        },
      );
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw StateError(data is Map
            ? (data['error'] ?? 'Salvataggio della valutazione non riuscito.').toString()
            : 'Risposta di salvataggio PR18 non valida.');
      }
      await _loadObjects();
      if (!mounted) return;
      final updated = data['valore_master_aggiornato'] == true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        updated
            ? 'Valutazione salvata: valore di mercato aggiornato. Oggetto ancora ${data['stato_oggetto']}.'
            : 'Valutazione e storico salvati. Nessun nuovo prezzo verificabile: il valore precedente è stato mantenuto.',
      )));
    } catch (e) {
      if (mounted) setState(() => _error = 'Salvataggio valutazione non riuscito: $e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _continueToPr06Valora() async {
    final id = _selectedId;
    final object = _objects.where((row) => row['codice_oggetto'] == id).firstOrNull;
    if (id == null || object == null || _prepared == null) {
      setState(() => _error = 'Completa prima la valutazione VALORA dell’oggetto selezionato.');
      return;
    }
    final state = (object['stato'] ?? '').toString().trim().toUpperCase();
    if (state != 'DISPONIBILE') {
      setState(() => _error = 'PR06 VALORA richiede un oggetto DISPONIBILE. Stato attuale: $state.');
      return;
    }
    final decision = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Valutazione completata'),
        content: const Text('Vuoi conservare la valutazione senza mettere in vendita l’oggetto, oppure proseguire con PR06 VALORA?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop('SOLO_VALUTAZIONE'), child: const Text('SOLO VALUTAZIONE')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop('CONTINUA'), child: const Text('CONTINUA A PR06 VALORA')),
        ],
      ),
    );
    if (!mounted || decision == null) return;
    if (decision == 'SOLO_VALUTAZIONE') {
      await _saveKnownObjectValuation(id, object, Map<String, dynamic>.from(_prepared!));
      return;
    }
    if (decision != 'CONTINUA') return;
    final rawValue = _prepared?['valore_mercato'] ?? _prepared?['valore_stimato'];
    final rawPrice = rawValue is num ? rawValue.toDouble() : double.tryParse((rawValue ?? '').toString());
    final originalDestination = (object['destinazione'] ?? '').toString().trim().toUpperCase();
    final session = _uuid.v4();
    var locked = false;
    var destinationChanged = false;
    setState(() { _preparing = true; _error = null; });
    try {
      if (originalDestination != 'RIVENDITA') {
        final lock = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': session});
        final lockData = lock['result'];
        if (lockData is! Map || lockData['acquisito'] != true) {
          throw StateError((lockData is Map ? lockData['messaggio'] : null)?.toString() ?? 'Blocco archivio non acquisito.');
        }
        locked = true;
        final payload = <String, dynamic>{
          'oggetti': [{'codice_oggetto': id, 'destinazione': 'RIVENDITA'}],
          'dati_confermati': true, 'altra_operazione': false, 'conferma_finale': true,
        };
        final preview = await _ValoraRuntimeApi.procedure('PR-02', 'preview', payload, sessionId: session);
        if (preview['errore'] != null || preview['scrittura_eseguita'] == true) {
          throw StateError((preview['errore'] ?? 'Anteprima PR-02 non valida.').toString());
        }
        await _ValoraRuntimeApi.procedure('PR-02', 'review', payload, sessionId: session);
        final saved = await _ValoraRuntimeApi.procedure('PR-02', 'save', payload, sessionId: session, requestId: _uuid.v4());
        if (saved['scrittura_eseguita'] != true || saved['blocco_rilasciato_automaticamente'] != true) {
          throw StateError('Cambio destinazione non verificato dal runtime.');
        }
        locked = false;
        destinationChanged = true;
      }
      if (!mounted) return;
      final saleSaved = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => Pr06ValoraPage(
          initialObjectCode: id,
          marketValue: rawPrice != null && rawPrice > 0 ? rawPrice : null,
        ),
      ));
      if (destinationChanged && saleSaved != true) {
        final rollbackSession = _uuid.v4();
        final rollbackLock = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': rollbackSession});
        final rollbackData = rollbackLock['result'];
        if (rollbackData is! Map || rollbackData['acquisito'] != true) {
          throw StateError('Impossibile acquisire il blocco per ripristinare la destinazione originaria.');
        }
        try {
          final rollbackPayload = <String, dynamic>{
            'oggetti': [{'codice_oggetto': id, 'destinazione': originalDestination}],
            'dati_confermati': true, 'altra_operazione': false, 'conferma_finale': true,
          };
          final rollbackPreview = await _ValoraRuntimeApi.procedure('PR-02', 'preview', rollbackPayload, sessionId: rollbackSession);
          if (rollbackPreview['errore'] != null || rollbackPreview['scrittura_eseguita'] == true) {
            throw StateError('Anteprima ripristino destinazione non valida.');
          }
          await _ValoraRuntimeApi.procedure('PR-02', 'review', rollbackPayload, sessionId: rollbackSession);
          final rollback = await _ValoraRuntimeApi.procedure('PR-02', 'save', rollbackPayload, sessionId: rollbackSession, requestId: _uuid.v4());
          if (rollback['scrittura_eseguita'] != true || rollback['blocco_rilasciato_automaticamente'] != true) {
            throw StateError('Ripristino destinazione non verificato.');
          }
        } finally {
          try { await _ValoraRuntimeApi.call('release_lock', {'session_id': rollbackSession}); } catch (_) {}
        }
      }
      if (mounted) await _loadObjects();
    } catch (e) {
      if (locked) {
        try { await _ValoraRuntimeApi.call('release_lock', {'session_id': session}); } catch (_) {}
      }
      if (mounted) setState(() => _error = 'Avvio PR06 VALORA non completato: $e');
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  @override
  Widget build(BuildContext context) => buildPage(context);

}
