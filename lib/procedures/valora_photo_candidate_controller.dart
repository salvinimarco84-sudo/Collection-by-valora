part of '../main.dart';

/// Conferma dei candidati PR-12 e ricerca estesa senza duplicati.
extension _ValoraPhotoCandidateController on _ValoraServicePageState {
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
