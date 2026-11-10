part of '../main.dart';

mixin _ValoraPhotoSearch on _ValoraServicePageStateBase {
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
      builder: (_) => Pr04ValoraPage(
        initialMetadata: metadata,
        suggestedMarketValue: valuation?['valore_mercato'] is num
            ? (valuation!['valore_mercato'] as num).toDouble()
            : null,
        valuation: valuation,
        market: _market,
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
}
