part of '../main.dart';

extension _ValoraCatalogSaleController on _ValoraServicePageState {
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
        builder: (_) => Pr06ValoraPage(initialObjectCode: id, marketValue: price),
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

}
