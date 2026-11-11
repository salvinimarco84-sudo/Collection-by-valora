part of '../main.dart';

extension _Pr04RuntimeProcedure on _NewPurchasePageState {
  void _invalidate() { _preview = null; _dataConfirmed = false; }

  void _resize(int n) {
    while (_items.length < n) { _items.add(_PurchaseItemDraft()); }
    while (_items.length > n) { _items.removeLast().dispose(); }
    _invalidate();
  }

  bool _valid() {
    if (_items.isEmpty) { _notice('Inserisci almeno un oggetto.'); return false; }
    if (widget.wantedDesireId != null && (_pendingPurchases.isNotEmpty || _items.length != 1 || _type != 'SINGOLO')) {
      _notice('Un desiderio WANTED LIST deve essere registrato come acquisto singolo di un solo oggetto.'); return false;
    }
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].description.text.trim().isEmpty) {
        _notice('Inserisci la descrizione dell’oggetto ' + (i + 1).toString() + '.'); return false;
      }
      if (_items[i].destination == 'COLLEZIONE' && (_items[i].collectionCategoryCode == null || !_collectionCategories.any((e) => e['codice_categoria'] == _items[i].collectionCategoryCode))) {
        _notice('Seleziona la categoria COLLEZIONE per l’oggetto ' + (i + 1).toString() + '.'); return false;
      }
      final p = _items[i].amount;
      if (p == null || p <= 0) {
        _notice('Inserisci un prezzo maggiore di zero per l’oggetto ' + (i + 1).toString() + '.'); return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _currentPurchaseOperation() => {
    'data_acquisto': _date.toIso8601String().substring(0, 10),
    'importo_totale': double.parse(_total.toStringAsFixed(2)),
    'valuta': 'EUR',
    'oggetti': _items.map((e) => e.json()).toList(),
  };

  double get _pendingTotal => _pendingPurchases.fold<double>(0,
    (sum, purchase) => sum + ((purchase['importo_totale'] as num?)?.toDouble() ?? 0));

  Map<String, dynamic> _payload({bool confirmed = false, bool finalConfirmation = false}) => {
    // Ogni acquisto è un'operazione distinta: SÌ accoda, NO salva tutta la coda.
    'operazioni': [..._pendingPurchases, _currentPurchaseOperation()],
    'dati_confermati': confirmed,
    'conferma_finale': finalConfirmation,
    'altra_operazione': false,
  };

  void _queueCurrentAndStartNext() {
    if (!_valid()) return;
    final operation = _currentPurchaseOperation();
    final queuedCount = _pendingPurchases.length + 1;
    final queuedTotal = _pendingTotal + _total;
    for (final item in _items) { item.dispose(); }
    setState(() {
      _pendingPurchases.add(operation);
      _items..clear()..add(_PurchaseItemDraft());
      _step = 0;
      _type = 'SINGOLO';
      _date = DateTime.now();
      _count.text = '1';
      _preview = null;
      _dataConfirmed = false;
      _status = '$queuedCount acquisti in coda (€ ${queuedTotal.toStringAsFixed(2)}). Nessuna scrittura eseguita.';
    });
  }

  Future<bool> _acquire() async {
    final r = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _session});
    final data = r['result'];
    if (data is Map && data['acquisito'] == true) { _locked = true; return true; }
    if (mounted) setState(() => _status =
      (data is Map ? data['messaggio'] : null)?.toString() ?? 'Blocco archivio non acquisito.');
    return false;
  }

  Future<void> _release() async {
    if (!_locked) return;
    try { await _ValoraRuntimeApi.call('release_lock', {'session_id': _session}); }
    finally { _locked = false; }
  }

  Future<void> _runPreview() async {
    if (!_valid()) return;
    setState(() { _busy = true; _status = 'Controllo preliminare in TEST…'; _invalidate(); });
    try {
      if (!await _acquire()) return;
      final expectedPurchases = _pendingPurchases.length + 1;
      final r = await _ValoraRuntimeApi.procedure('PR-04', 'preview', _payload(), sessionId: _session);
      if (r['scrittura_eseguita'] == true || r['numero_acquisti'] != expectedPurchases) {
        throw StateError('Anteprima incoerente: attesi $expectedPurchases acquisti, ricevuti ${r['numero_acquisti'] ?? 'nessun conteggio'}. Nessuna scrittura autorizzata.');
      }
      if (!mounted) return;
      setState(() { _preview = r; _step = 4; _status = 'Riepilogo pronto: $expectedPurchases acquisti inclusi. SÌ aggiunge un altro; NO salva l’intera coda.'; });
    } catch (e) {
      if (mounted) setState(() => _status = 'Controllo non riuscito: ' + e.toString());
    } finally { await _release(); if (mounted) setState(() => _busy = false); }
  }

  Future<void> _completeWantedPurchaseLink() async {
    final wantedId = widget.wantedDesireId;
    final purchaseCode = _wantedPurchaseCode;
    if (wantedId == null || purchaseCode == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw StateError('Sessione utente non valida per collegare il desiderio.');
    final db = Supabase.instance.client.schema('collection');
    final linkedRows = await db.from('acquisti_oggetti')
        .select('codice_oggetto')
        .eq('codice_acquisto', purchaseCode);
    final rows = (linkedRows as List).whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row)).toList();
    if (rows.length != 1) {
      throw StateError('Acquisto $purchaseCode verificato, ma il collegamento restituisce ${rows.length} oggetti invece di uno. Il desiderio resta attivo.');
    }
    final objectCode = int.tryParse((rows.single['codice_oggetto'] ?? '').toString());
    if (objectCode == null || objectCode <= 0) {
      throw StateError('Codice oggetto non valido per l’acquisto $purchaseCode. Il desiderio resta attivo.');
    }
    final updated = await db.from('wanted_desideri').update({
      'stato': 'ACQUISTATO',
      'codice_oggetto_acquistato': objectCode,
      'data_chiusura': DateTime.now().toUtc().toIso8601String(),
      'data_aggiornamento': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', wantedId).eq('user_id', user.id).eq('stato', 'ATTIVO')
      .select('id,stato,codice_oggetto_acquistato').maybeSingle();
    if (updated == null ||
        updated['stato'] != 'ACQUISTATO' ||
        int.tryParse((updated['codice_oggetto_acquistato'] ?? '').toString()) != objectCode) {
      throw StateError('Acquisto $purchaseCode salvato, ma il desiderio non è stato chiuso e verificato. Usa nuovamente CONFERMA COLLEGAMENTO, senza ripetere PR-04.');
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_wantedPurchaseCommitted) {
      setState(() { _busy = true; _status = 'Ripristino del collegamento WANTED LIST, senza ripetere l’acquisto…'; });
      try {
        await _completeWantedPurchaseLink();
        if (mounted) Navigator.of(context).pop(true);
      } catch (e) {
        if (mounted) setState(() => _status = 'Acquisto già salvato. Collegamento ancora da completare: $e');
      } finally { if (mounted) setState(() => _busy = false); }
      return;
    }
    if (_preview == null || !_dataConfirmed) {
      _notice('Completa il riepilogo prima di salvare.'); return;
    }
    setState(() { _busy = true; _status = 'Invio del salvataggio al runtime TEST…'; });
    try {
      if (!await _acquire()) return;
      final expectedPurchases = _pendingPurchases.length + 1;
      final r = await _ValoraRuntimeApi.procedure('PR-04', 'save',
        _payload(confirmed: true, finalConfirmation: true), sessionId: _session, requestId: _uuid.v4());
      final reread = r['verifica_post_salvataggio'] ?? r['rilettura_database'];
      final rereadCount = reread is List ? reread.length : 0;
      final verified = reread is List && reread.length == expectedPurchases &&
        reread.every((e) => e is Map && e['verificato'] == true && e['codice_acquisto'] != null);
      final saved = r['scrittura_eseguita'] == true &&
        r['stato'] == 'SALVATO_E_VERIFICATO' &&
        r['numero_acquisti'] == expectedPurchases && verified && rereadCount == expectedPurchases;
      if (r['blocco_rilasciato_automaticamente'] == true) _locked = false;
      if (!mounted) return;
      if (!saved) {
        setState(() {
          _preview = r;
          _status = 'Salvataggio NON concluso: attesi $expectedPurchases acquisti, riletture ricevute $rereadCount. La coda e la bozza restano disponibili.';
        });
        return;
      }
      if (widget.wantedDesireId != null) {
        final verifiedRow = (reread as List).single as Map;
        _wantedPurchaseCode = int.tryParse((verifiedRow['codice_acquisto'] ?? '').toString());
        if (_wantedPurchaseCode == null) {
          throw StateError('PR-04 ha verificato il salvataggio ma non ha restituito il codice acquisto. Non ripetere l’acquisto: verifica manualmente il collegamento.');
        }
        _wantedPurchaseCommitted = true;
        _pendingPurchases.clear();
        try {
          await _completeWantedPurchaseLink();
        } catch (e) {
          if (mounted) setState(() => _status = 'Acquisto salvato e verificato. Collegamento WANTED LIST da completare: $e. Premi nuovamente SALVA E ESCI per riprovare solo il collegamento, senza duplicare l’acquisto.');
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _pendingPurchases.clear();
        _preview = r;
        _status = widget.wantedDesireId == null
          ? 'Tutti i $expectedPurchases acquisti sono stati salvati e verificati singolarmente.'
          : 'Acquisto verificato e desiderio collegato allo stesso oggetto di catalogo.';
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _status = 'Salvataggio non confermato: ' + e.toString());
    } finally { await _release(); if (mounted) setState(() => _busy = false); }
  }

}
