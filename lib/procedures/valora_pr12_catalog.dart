part of '../main.dart';

extension _ObjectRuntimePagePr12Catalog on _ObjectRuntimePageState {
    Future<void> _loadIncompleteMetadataCatalog() async {
      setState(() {
        _metadataResult = 'PR-12: analisi del catalogo in corso…';
        _output = _metadataResult;
        _pr12IncompleteRecords = [];
        _pr12QueuePage = 0;
        _pr12SelectedRecordIds.clear();
        _pr12AiResults = [];
        _pr12UnresolvedRecords = [];
        _pr12SelectedCandidates.clear();
        _pr12NextBatchOffset = 0;
        _pr12AiBatchStatus = 'Catalogo aggiornato. La coda di ricerca è pronta.';
      });
      try {
        // Escludi i record sintetici archiviati prima di preparare qualsiasi lotto PR-12.
        // Se la lettura del flag fallisce, l'analisi fallisce in sicurezza e non avvia ricerche.
        final archivedRows = await Supabase.instance.client
            .schema('collection')
            .from('master_oggetti')
            .select('codice_oggetto')
            .eq('archiviato_test', true);
        final archivedTestIds = archivedRows
            .map((row) => (row['codice_oggetto'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet();
  
        final incomplete = <Map<String, dynamic>>[];
        const pageSize = 500;
        var offset = 0;
        var totalRead = 0;
        var archivedSkipped = 0;
        while (true) {
          final response = await _ValoraRuntimeApi.call('pr12_catalog_page', {
            'session_id': _sessionId,
            'offset': offset,
            'limit': pageSize,
          });
          if (response['ok'] != true || response['rows'] is! List) {
            throw Exception('Il runtime non ha confermato la lettura del catalogo.');
          }
          final page = List<Map<String, dynamic>>.from(
            (response['rows'] as List).map((row) => Map<String, dynamic>.from(row as Map)),
          );
          totalRead += page.length;
          for (final row in page) {
            final recordId = (row['codice_oggetto'] ?? '').toString();
            if (archivedTestIds.contains(recordId)) {
              archivedSkipped++;
              continue;
            }
            final producer = (row['produttore'] ?? '').toString().trim();
            final year = row['anno_uscita'];
            final productCode = (row['codice_prodotto'] ?? '').toString().trim();
            if (producer.isEmpty || year == null || productCode.isEmpty) incomplete.add(row);
          }
          if (page.length < pageSize) break;
          offset += pageSize;
        }
        if (!mounted) return;
        setState(() {
          _pr12IncompleteRecords = incomplete;
          _metadataResult = 'Analisi completata: letti $totalRead record; esclusi $archivedSkipped record di test archiviati; ${incomplete.length} record reali con almeno un metadato mancante. Nessun dato modificato.';
          _output = _metadataResult;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _pr12IncompleteRecords = [];
          _metadataResult = 'ANALISI NON COMPLETATA: $e';
          _output = _metadataResult;
        });
        rethrow;
      }
    }
}
