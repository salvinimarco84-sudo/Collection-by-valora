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


}
