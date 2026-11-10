part of '../main.dart';

mixin _ValoraValuationFlow on _ValoraServicePageState {
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
}
