part of '../main.dart';

extension _ObjectRuntimePagePr12Runtime on _ObjectRuntimePageState {
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
  
    Future<void> _runPr12AiBatch({bool retryUnresolved = false, Map<String, dynamic>? singleRecord, List<Map<String, dynamic>>? selectedRecords}) async {
      if (singleRecord == null && _pr12IncompleteRecords.isEmpty) { setState(() => _pr12AiBatchStatus = 'Prima esegui ANALIZZA CATALOGO.'); return; }
      final List<Map<String, dynamic>> batch;
      if (singleRecord != null) {
        batch = [singleRecord];
      } else if (selectedRecords != null) {
        batch = selectedRecords.take(10).toList();
        if (batch.isEmpty) { setState(() => _pr12AiBatchStatus = 'Seleziona almeno un record nella pagina corrente.'); return; }
      } else if (retryUnresolved) {
        if (_pr12UnresolvedRecords.isEmpty) { setState(() => _pr12AiBatchStatus = 'Non ci sono record da riprovare.'); return; }
        batch = _pr12UnresolvedRecords.take(10).toList();
      } else {
        if (_pr12NextBatchOffset >= _pr12IncompleteRecords.length) { setState(() => _pr12AiBatchStatus = 'Prima passata completata. I record irrisolti restano disponibili per una nuova ricerca.'); return; }
        batch = _pr12IncompleteRecords.skip(_pr12NextBatchOffset).take(10).toList();
      }
      setState(() { _pr12AiBatchRunning = true; _pr12RetryRunning = retryUnresolved; _pr12AiBatchStatus = singleRecord != null ? 'Ricerca singola per l’oggetto ${singleRecord['codice_oggetto']}…' : (selectedRecords != null ? 'Ricerca su ${batch.length} record selezionati…' : (retryUnresolved ? 'Nuovo tentativo sui record irrisolti…' : 'Ricerca multi-fonte del lotto in corso…')); });
      try {
        final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
          'modalita_ia': 'TEST',
          'oggetti': batch.map((row) {
            // Mantieni distinti tema e sottotema: non promuovere mai un
            // sottotema (es. Polizia) al campo tema solo perché è valorizzato.
            String metadataText(List<String> keys) {
              for (final key in keys) {
                final value = row[key];
                if (value != null && value.toString().trim().isNotEmpty) {
                  return value.toString().trim();
                }
              }
              return '';
            }
            return {
              'id': (row['codice_oggetto'] ?? '').toString(),
              'descrizione': (row['descrizione_oggetto'] ?? '').toString(),
              'categoria': metadataText(['categoria_principale', 'categoria_collezione']).isNotEmpty
                  ? metadataText(['categoria_principale', 'categoria_collezione'])
                  : _pr12CategoryFromDescription((row['descrizione_oggetto'] ?? '').toString()),
              'tema': metadataText(['tema', 'tema_lego', 'franchise_tema', 'franchise', 'linea_prodotto']),
              'sottotema': metadataText(['sottotema', 'sotto_tema', 'sottotema_lego']),
              'sezione': metadataText(['sezione', 'serie', 'linea']),
              'mercato': (row['mercato'] ?? row['market'] ?? 'Italia').toString(),
            };
          }).toList(),
        });
        dynamic raw = response.data;
        // Supabase Functions può esporre il body come ByteStream: consumarlo e decodificarlo prima del parsing JSON/SSE.
        if (raw is Stream<List<int>>) {
          final bytes = await raw.fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
          raw = utf8.decode(bytes, allowMalformed: true);
        } else if (raw is Uint8List) {
          raw = utf8.decode(raw, allowMalformed: true);
        }
        final finals = <Map<String, dynamic>>[];
  
        void addFinal(dynamic value) {
          if (value is Map) {
            final item = Map<String, dynamic>.from(value);
            // Accetta sia il contratto streaming (oggetto_completato/coda_completata)
            // sia la risposta JSON diretta dell'engine. In entrambi i casi l'ID
            // dell'oggetto deve essere presente per evitare risultati scollegati.
            if (item['oggetto_id'] != null && (item['risultati'] is List || item['ok'] == false)) {
              finals.add(item);
            }
            final nested = item['risultati_finali'];
            if (nested is List) {
              for (final entry in nested) {
                if (entry is Map) finals.add(Map<String, dynamic>.from(entry));
              }
            }
            final result = item['risultato'];
            if ((item['tipo'] == 'oggetto_completato' || item['tipo'] == 'oggetto_errore') && result is Map) {
              finals.add(Map<String, dynamic>.from(result));
            }
            final wrapped = item['data'] ?? item['result'];
            if (wrapped is Map) addFinal(wrapped);
            if (wrapped is List) {
              for (final entry in wrapped) {
                if (entry is Map) addFinal(entry);
              }
            }
          } else if (value is List) {
            for (final entry in value) {
              addFinal(entry);
            }
          }
        }
  
        if (raw is Map || raw is List) {
          addFinal(raw);
        } else if (raw is String) {
          final normalized = raw.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
          var decoded = false;
          try {
            final parsed = jsonDecode(normalized);
            addFinal(parsed);
            decoded = true;
            if (parsed is String) {
              try { addFinal(jsonDecode(parsed)); } catch (_) {}
            }
          } catch (_) {
            // Potrebbe essere una risposta SSE anziché JSON puro.
          }
          if (!decoded || finals.isEmpty) {
            for (final line in normalized.split(RegExp(r'\r?\n'))) {
              final trimmed = line.trimLeft();
              if (!trimmed.startsWith('data:')) continue;
              final payload = trimmed.substring(5).trim();
              if (payload.isEmpty || payload == '[DONE]') continue;
              try {
                addFinal(jsonDecode(payload));
              } catch (_) {
                // Ignore a malformed SSE frame while retaining valid frames.
              }
            }
          }
        }
  
        final deduplicated = <String, Map<String, dynamic>>{};
        for (final result in finals) {
          final id = (result['oggetto_id'] ?? '').toString();
          if (id.isNotEmpty) deduplicated[id] = result;
        }
        finals
          ..clear()
          ..addAll(deduplicated.values);
        if (finals.isEmpty) {
          final rawText = raw.toString();
          final preview = rawText.substring(0, rawText.length < 240 ? rawText.length : 240);
          throw Exception('Risposta PR-12 senza risultati interpretabili (HTTP ${response.status}, tipo ${raw.runtimeType}). Anteprima: $preview. Nessun dato del catalogo modificato.');
        }
        final byId = {for (final result in finals) (result['oggetto_id'] ?? '').toString(): result};
        final resolvedIds = <String>{};
        final unresolved = <Map<String, dynamic>>[];
        for (final row in batch) {
          final id = (row['codice_oggetto'] ?? '').toString();
          final result = byId[id];
          final count = result?['numero_risultati'] is num ? (result!['numero_risultati'] as num).toInt() : (result?['risultati'] is List ? (result!['risultati'] as List).length : 0);
          if (result?['ok'] == true && count > 0) { resolvedIds.add(id); } else { unresolved.add(row); }
        }
        if (!mounted) return;
        setState(() {
          _pr12AiResults = [..._pr12AiResults.where((old) => !finals.any((fresh) => (fresh['oggetto_id'] ?? '').toString() == (old['oggetto_id'] ?? '').toString())), ...finals];
          if (singleRecord != null) {
            _pr12AiBatchStatus = 'Ricerca singola completata: ${finals.where((r) => r['ok'] == true).length} risposta/e valida/e. Nessun dato salvato.';
          } else if (retryUnresolved) {
            _pr12UnresolvedRecords = [..._pr12UnresolvedRecords.where((row) => !resolvedIds.contains((row['codice_oggetto'] ?? '').toString()) && !batch.any((b) => (b['codice_oggetto'] ?? '').toString() == (row['codice_oggetto'] ?? '').toString())), ...unresolved];
          } else {
            _pr12NextBatchOffset += batch.length;
            _pr12UnresolvedRecords = [..._pr12UnresolvedRecords, ...unresolved.where((row) => !_pr12UnresolvedRecords.any((old) => old['codice_oggetto'] == row['codice_oggetto']))];
          }
          final good = finals.where((r) => r['ok'] == true && ((r['numero_risultati'] as num?) ?? ((r['risultati'] is List) ? (r['risultati'] as List).length : 0)) > 0).length;
          _pr12AiBatchStatus = singleRecord != null ? 'Ricerca singola completata: $good risultato/i con candidati pertinenti. Nessun dato salvato.' : '${retryUnresolved ? 'Nuovo tentativo' : 'Lotto completato'}: $good con risultati pertinenti; ${batch.length - good} da approfondire. Prima passata: $_pr12NextBatchOffset/${_pr12IncompleteRecords.length}. Da riprovare: ${_pr12UnresolvedRecords.length}. Nessun dato salvato.';
        });
      } catch (e) { if (mounted) setState(() => _pr12AiBatchStatus = 'Ricerca non completata: $e'); }
      finally { if (mounted) setState(() { _pr12AiBatchRunning = false; _pr12RetryRunning = false; }); }
    }
    Future<void> _pr12ApplySelectedCandidate(Map<String, dynamic> result, Map<String, dynamic> candidate) async {
      final id = int.tryParse((result['oggetto_id'] ?? '').toString());
      if (id == null) {
        setState(() => _pr12AiBatchStatus = 'Non posso applicare: codice oggetto non valido.');
        return;
      }
      final nested = candidate['metadati'] is Map
          ? Map<String, dynamic>.from(candidate['metadati'] as Map)
          : <String, dynamic>{};
      String valueFor(List<String> keys) {
        for (final key in keys) {
          final value = candidate[key] ?? nested[key];
          if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
        }
        return '';
      }
      final maker = valueFor(['produttore', 'editore', 'manufacturer', 'publisher']);
      final yearText = valueFor(['anno_uscita', 'anno', 'release_year', 'year']);
      final productCode = valueFor(['codice_prodotto', 'codice', 'product_code', 'set_num', 'isbn', 'item_number']);
      final title = valueFor(['titolo_prodotto', 'nome_prodotto', 'product_name', 'title', 'titolo']);
      final year = int.tryParse(yearText);
      final genericTitles = <String>{'home', 'homepage', 'official website', 'search results', 'catalogo', 'risultati della ricerca'};
      final usefulTitle = title.length >= 5 && !genericTitles.contains(title.toLowerCase());
      if (maker.isEmpty && year == null && productCode.isEmpty && !usefulTitle) {
        setState(() => _pr12AiBatchStatus = 'La fonte non contiene metadati strutturati o un titolo prodotto utilizzabile. Nessun dato modificato.');
        return;
      }
      final client = Supabase.instance.client;
      final current = await client.schema('collection').from('master_oggetti')
          .select('descrizione_oggetto,produttore,anno_uscita,codice_prodotto')
          .eq('codice_oggetto', id).maybeSingle();
      if (current == null) throw Exception('Oggetto #$id non trovato nel catalogo TEST.');
      final currentDescription = (current['descrizione_oggetto'] ?? '').toString().trim();
      final appendTitle = usefulTitle && !currentDescription.toLowerCase().contains(title.toLowerCase());
      final proposedDescription = appendTitle
          ? (currentDescription.isEmpty ? title : currentDescription + ' · ' + title)
          : currentDescription;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('CONFERMA APPLICAZIONE METADATI'),
          content: Text(
            'Oggetto #$id\n'
            'Descrizione proposta: ' + (proposedDescription.isEmpty ? 'nessuna modifica' : proposedDescription) + '\n'
            'Produttore: ' + (maker.isEmpty ? 'non trovato' : maker) + '\n'
            'Anno: ' + (year?.toString() ?? 'non trovato') + '\n'
            'Codice prodotto: ' + (productCode.isEmpty ? 'non trovato' : productCode) + '\n\n'
            'La descrizione esistente viene conservata e integrata con il titolo candidato. Gli altri campi vengono compilati soltanto se vuoti. Verifica che il candidato identifichi proprio questo oggetto.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFERMO')),
          ],
        ),
      );
      if (accepted != true) return;
      final patch = <String, dynamic>{};
      if (appendTitle) patch['descrizione_oggetto'] = proposedDescription;
      if ((current['produttore'] ?? '').toString().trim().isEmpty && maker.isNotEmpty) patch['produttore'] = maker;
      if (current['anno_uscita'] == null && year != null && year >= 1800 && year <= DateTime.now().year + 2) patch['anno_uscita'] = year;
      if ((current['codice_prodotto'] ?? '').toString().trim().isEmpty && productCode.isNotEmpty) patch['codice_prodotto'] = productCode;
      if (patch.isEmpty) {
        setState(() => _pr12AiBatchStatus = 'Nessun campo vuoto aggiornabile per l’oggetto #$id. I dati presenti sono stati conservati.');
        return;
      }
      await client.schema('collection').from('master_oggetti').update(patch).eq('codice_oggetto', id);
      if (!mounted) return;
      setState(() => _pr12AiBatchStatus = 'Metadati applicati all’oggetto #$id: ' + patch.keys.join(', ') + '. Sono stati aggiornati soltanto campi vuoti.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Oggetto #$id aggiornato: ' + patch.keys.join(', '))));
    }
    String _pr12CategoryFromDescription(String description) {
      final v = description.toLowerCase();
      if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(v)) return 'LEGO';
      if (RegExp(r'fumett|comic|manga|panini|salda|bonelli|graphic novel|isbn').hasMatch(v)) return 'FUMETTI';
      if (RegExp(r'orolog|watch|swatch|rolex|omega|seiko|casio|tissot|longines|tag heuer|cartier').hasMatch(v)) return 'WATCHES';
      if (RegExp(r'vinile|vinyl|disco|record|lp|musicassett|music tape').hasMatch(v)) return 'MUSIC';
      if (RegExp(r'moneta|monete|numismatic|coin|banconot|banknote|francoboll|stamp collection').hasMatch(v)) return 'NUMISMATICS';
      if (RegExp(r'carta collezionabile|trading card|pokemon card|magic the gathering|tcg|sports card').hasMatch(v)) return 'TRADING_CARDS';
      if (RegExp(r'myth cloth|saint seiya|bandai|gundam|gunpla|dragon ball|action figure|statua|transformers|optimus prime|bumblebee|megatron|star wars|naruto|one piece').hasMatch(v)) return 'ACTION_FIGURE';
      if (RegExp(r'maisto|die.?cast|modellino|motorbike|motocicletta|modellismo|auto in scala|hot wheels|matchbox').hasMatch(v)) return 'DIECAST';
      return 'COLLEZIONABILE';
    }
}
