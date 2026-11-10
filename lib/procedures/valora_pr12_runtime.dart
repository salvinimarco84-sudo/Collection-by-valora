part of '../main.dart';

extension _ObjectRuntimePagePr12Runtime on _ObjectRuntimePageState {
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
}
