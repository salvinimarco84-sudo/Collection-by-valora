part of '../main.dart';

extension _Pr06RuntimeProcedure on _NewSalePageState {
  Future<void> _releaseSilently() async {
    try { await _ValoraRuntimeApi.call('release_lock', {'session_id': _session}); } catch (_) {}
    _locked = false;
  }

  void _invalidate() { _preview = null; _confirmed = false; }
  void _notice(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> _load() async {
    setState(() { _loading = true; _status = 'Lettura dal database TEST…'; });
    try {
      final response = await _ValoraRuntimeApi.call('consultation', {
        'session_id': _session, 'consultation_code': 'OBJECTS_SELLABLE',
        'arguments': {'limite': 500, 'offset': 0},
      });
      final outer = response['result'];
      final dynamic data = outer is Map ? (outer['risultato'] ?? outer) : outer;
      final rows = data is List
          ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      // Piattaforme configurate nel database TEST. Gli ID corrispondono a collection.piattaforme.
      // Non usare TABLE_VALUES qui: restituisce conteggi per valore, non righe della tabella.
      final platforms = <Map<String, dynamic>>[
        {'codice_piattaforma': 1, 'nome_piattaforma': 'Vinted'},
        {'codice_piattaforma': 2, 'nome_piattaforma': '[TEST-CBV] eBay'},
        {'codice_piattaforma': 3, 'nome_piattaforma': '[TEST-CBV] Mercatino'},
        {'codice_piattaforma': 6, 'nome_piattaforma': 'Subito'},
        {'codice_piattaforma': 7, 'nome_piattaforma': 'BrickLink'},
      ];
      if (!mounted) return;
      setState(() {
        _objects = rows;
        _platforms = platforms;
        final initialObjectExists = widget.initialObjectCode != null &&
            rows.any((row) => int.tryParse((row['codice_oggetto'] ?? '').toString()) == widget.initialObjectCode);
        _selectedObject = widget.initialObjectCode != null
          ? (initialObjectExists ? widget.initialObjectCode : (widget.valoraMode || rows.isEmpty ? null : int.tryParse((rows.first['codice_oggetto'] ?? '').toString())))
          : (rows.isNotEmpty ? int.tryParse((rows.first['codice_oggetto'] ?? '').toString()) : null);
        _selectedPlatforms.clear();
        if (platforms.isNotEmpty) {
          final vinted = platforms.where((p) => (p['nome_piattaforma'] ?? '').toString().toLowerCase().contains('vinted'));
          final first = vinted.isNotEmpty ? vinted.first : platforms.first;
          final id = int.tryParse((first['codice_piattaforma'] ?? '').toString());
          if (id != null) _selectedPlatforms.add(id);
        }
        _loading = false;
        _status = rows.isEmpty
          ? 'Nessun oggetto disponibile con destinazione RIVENDITA e stato DISPONIBILE.'
          : 'Caricati ${rows.length} oggetti vendibili. La vendita non è ancora stata registrata.';
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _status = 'Caricamento non riuscito: $e'; });
    }
  }

  List<Map<String, dynamic>> get _filteredObjects {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _objects;
    return _objects.where((o) => [
      o['codice_oggetto'], o['descrizione_oggetto'], o['codice_prodotto'], o['produttore']
    ].any((v) => (v ?? '').toString().toLowerCase().contains(q))).toList();
  }

  Map<String, dynamic>? get _chosenObject {
    for (final o in _objects) {
      if (int.tryParse((o['codice_oggetto'] ?? '').toString()) == _selectedObject) return o;
    }
    return null;
  }

  Map<String, dynamic> _payload({bool confirmed = false, bool finalConfirmation = false, List<Map<String, dynamic>>? operations}) => {
    'operazioni': operations ?? [
      {
        'codice_oggetto': _selectedObject,
        'prezzo_di_vendita': double.parse(double.parse(_price.text.trim().replaceAll(',', '.')).toStringAsFixed(2)),
        'codici_piattaforme': _selectedPlatforms.toList()..sort(),
        'note': _notes.text.trim(),
      }
    ],
    'dati_confermati': confirmed,
    'conferma_finale': finalConfirmation,
    'altra_operazione': false,
  };

  Future<bool> _acquire() async {
    final r = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _session});
    final data = r['result'];
    if (data is Map && data['acquisito'] == true) { _locked = true; return true; }
    if (mounted) setState(() => _status =
      (data is Map ? (data['messaggio'] ?? data['stato']) : null)?.toString() ?? 'Blocco archivio non acquisito.');
    return false;
  }

  Future<void> _release() async {
    if (!_locked) return;
    try { await _ValoraRuntimeApi.call('release_lock', {'session_id': _session}); }
    finally { _locked = false; }
  }

  bool _valid() {
    if (_selectedObject == null) { _notice('Seleziona un oggetto da mettere in vendita.'); return false; }
    final amount = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (amount == null || !amount.isFinite || amount <= 0) { _notice('Inserisci un prezzo di vendita maggiore di zero.'); return false; }
    if (_selectedPlatforms.isEmpty) { _notice('Seleziona almeno una piattaforma di vendita.'); return false; }
    return true;
  }

  Future<void> _previewSale() async {
    if (_lotMode) { await _previewLotSale(); return; }
    if (!_valid()) return;
    final operation = <String, dynamic>{
      'codice_oggetto': _selectedObject,
      'prezzo_di_vendita': double.parse(double.parse(_price.text.trim().replaceAll(',', '.')).toStringAsFixed(2)),
      'codici_piattaforme': _selectedPlatforms.toList()..sort(),
      'note': _notes.text.trim(),
    };
    final chosenDescription = (_chosenObject?['descrizione_oggetto'] ?? 'Oggetto #'+_selectedObject.toString()).toString();
    if (_pendingSales.any((e) => int.tryParse((e['codice_oggetto'] ?? '').toString()) == _selectedObject)) {
      _notice('Questo oggetto è già stato inserito nel lotto. Selezionane un altro.');
      return;
    }
    setState(() { _busy = true; _status = 'Controllo preliminare PR-06 in TEST. Nessuna scrittura…'; _invalidate(); });
    try {
      if (!await _acquire()) return;
      final r = await _ValoraRuntimeApi.procedure('PR-06', 'preview',
        _payload(operations: [operation]), sessionId: _session);
      if (r['scrittura_eseguita'] == true || (r['stato'] != null && r['stato'] != 'BOZZA')) {
        throw StateError('La verifica preliminare ha restituito un esito inatteso.');
      }
      if (!mounted) return;
      setState(() {
        _pendingSales.add(operation);
        _pendingDescriptions.add(chosenDescription);
        _preview = widget.valoraMode ? r : null;
        _confirmed = false;
        _status = 'Vendita aggiunta alla coda ('+_pendingSales.length.toString()+'). Nessuna vendita è ancora stata salvata.';
      });
      // Rilascia il blocco prima di attendere la risposta dell’utente; il salvataggio
      // finale riacquisirà il blocco per tutta la transazione del lotto.
      await _release();
      // PR-06 VALORA gestisce un solo oggetto: mostra il riepilogo e lascia
      // la conferma esplicita al pulsante CONFERMA E REGISTRA VENDITA.
      if (widget.valoraMode) return;
      final another = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Vuoi registrare un’altra vendita?'),
          content: Text(chosenDescription+' è pronta. Vendite in attesa: '+_pendingSales.length.toString()+'.\n\nSÌ riparte con una nuova vendita. NO salva tutte le vendite in attesa insieme.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('NO, SALVA IL LOTTO')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('SÌ, ALTRA VENDITA')),
          ],
        ),
      );
      if (!mounted) return;
      if (another == true) {
        setState(() {
          _selectedObject = _objects.map((o) => int.tryParse((o['codice_oggetto'] ?? '').toString()))
            .whereType<int>().firstWhere((id) =>
              !_pendingSales.any((sale) => int.tryParse((sale['codice_oggetto'] ?? '').toString()) == id),
              orElse: () => 0);
          if (_selectedObject == 0) _selectedObject = null;
          _price.clear(); _notes.clear(); _search.clear();
          _selectedPlatforms.clear(); _selectedPlatforms.add(1);
          _preview = null; _confirmed = false;
          _status = _selectedObject == null
            ? 'Non ci sono altri oggetti disponibili. Puoi terminare salvando il lotto.'
            : 'Nuova vendita pronta. Le vendite precedenti sono ancora in bozza.';
        });
        if (_selectedObject == null) {
          _notice('Non ci sono altri oggetti da inserire. Premi SALVA LOTTO per registrare le vendite in attesa.');
        }
      } else {
        await _saveSale();
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Controllo preliminare non riuscito: $e. Nessuna vendita del lotto è stata salvata.');
    } finally {
      await _release();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewLotSale() async {
    final ids = _selectedLotObjects.toList()..sort();
    final total = double.tryParse(_lotTotalPrice.text.trim().replaceAll(',', '.'));
    if (ids.length < 2) { _notice('Per creare un lotto unico seleziona almeno due oggetti.'); return; }
    if (total == null || !total.isFinite || total <= 0) { _notice('Inserisci un prezzo totale del lotto maggiore di zero.'); return; }
    if (_selectedPlatforms.isEmpty) { _notice('Seleziona almeno una piattaforma di vendita.'); return; }
    final operations = ids.map((id) => <String, dynamic>{'codice_oggetto': id, 'codici_piattaforme': _selectedPlatforms.toList()..sort(), 'note': _notes.text.trim()}).toList();
    setState(() { _busy = true; _status = 'Verifica del lotto unico in TEST. Nessuna scrittura…'; _preview = null; _confirmed = false; });
    try {
      if (!await _acquire()) return;
      final r = await _ValoraRuntimeApi.procedure('PR-06-LOTTO', 'preview', {
        'operazioni': operations, 'prezzo_totale': double.parse(total.toStringAsFixed(2)),
        'note': _notes.text.trim(), 'conferma_finale': false,
      }, sessionId: _session);
      if (r['scrittura_eseguita'] == true || r['stato'] != 'BOZZA') throw StateError('Anteprima lotto con esito inatteso.');
      if (!mounted) return;
      setState(() { _preview = r; _status = 'Anteprima pronta: '+ids.length.toString()+' oggetti, prezzo unico €'+total.toStringAsFixed(2)+'. Nessuna scrittura eseguita.'; });
    } catch (e) {
      if (mounted) setState(() => _status = 'Anteprima lotto non riuscita: $e. Nessun oggetto è stato messo in vendita.');
    } finally { await _release(); if (mounted) setState(() => _busy = false); }
  }

  Future<void> _saveLotSale() async {
    final ids = _selectedLotObjects.toList()..sort();
    final total = double.tryParse(_lotTotalPrice.text.trim().replaceAll(',', '.'));
    if (ids.length < 2 || total == null || !total.isFinite || total <= 0 || _selectedPlatforms.isEmpty) {
      _notice('Controlla oggetti selezionati, prezzo totale e piattaforma.'); return;
    }
    setState(() { _busy = true; _status = 'Salvataggio atomico del lotto in TEST e verifica database…'; });
    try {
      if (!await _acquire()) return;
      final operations = ids.map((id) => <String, dynamic>{'codice_oggetto': id, 'codici_piattaforme': _selectedPlatforms.toList()..sort(), 'note': _notes.text.trim()}).toList();
      final r = await _ValoraRuntimeApi.procedure('PR-06-LOTTO', 'save', {
        'operazioni': operations, 'prezzo_totale': double.parse(total.toStringAsFixed(2)),
        'note': _notes.text.trim(), 'dati_confermati': true, 'conferma_finale': true, 'altra_operazione': false,
      }, sessionId: _session, requestId: _uuid.v4());
      final verified = r['scrittura_eseguita'] == true && r['stato'] == 'SALVATO_E_VERIFICATO' &&
        (r['codice_lotto'] ?? '').toString().isNotEmpty && (r['numero_oggetti'] as num?)?.toInt() == ids.length;
      if (r['blocco_rilasciato_automaticamente'] == true) _locked = false;
      if (!mounted) return;
      setState(() { _preview = r; _status = verified
        ? 'LOTTO UNICO SALVATO: '+ids.length.toString()+' oggetti, totale €'+total.toStringAsFixed(2)+', codice '+r['codice_lotto'].toString()+'.'
        : 'Esito lotto non verificato completamente. Non considerare conclusa la registrazione.'; });
      if (verified) {
        await showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
          title: const Text('Lotto unico salvato e verificato'),
          content: Text(ids.length.toString()+' oggetti collegati al lotto '+r['codice_lotto'].toString()+'. Prezzo complessivo: €'+total.toStringAsFixed(2)+'.'),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('FINE'))],
        ));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Lotto non salvato: $e. La transazione deve essere interamente annullata in caso di errore.');
    } finally { await _release(); if (mounted) setState(() => _busy = false); }
  }

  Future<void> _saveSale() async {
    if (_lotMode) { await _saveLotSale(); return; }
    if (_pendingSales.isEmpty) { _notice('Non ci sono vendite in attesa di salvataggio.'); return; }
    setState(() { _busy = true; _status = 'Verifica del lotto completo e salvataggio atomico PR-06 in corso…'; });
    try {
      if (!await _acquire()) return;
      final preview = await _ValoraRuntimeApi.procedure('PR-06', 'preview',
        _payload(operations: _pendingSales), sessionId: _session);
      if (preview['scrittura_eseguita'] == true || preview['stato'] != 'BOZZA') {
        throw StateError('Riepilogo finale non valido. Nessuna vendita del lotto è stata salvata.');
      }
      final r = await _ValoraRuntimeApi.procedure('PR-06', 'save',
        _payload(confirmed: true, finalConfirmation: true, operations: _pendingSales),
        sessionId: _session, requestId: _uuid.v4());
      final verifiedRows = r['verifica_post_salvataggio'];
      final verified = r['scrittura_eseguita'] == true &&
        r['stato'] == 'SALVATO_E_VERIFICATO' &&
        verifiedRows is List && verifiedRows.length == _pendingSales.length &&
        verifiedRows.every((e) => e is Map &&
          (e['stato_ciclo_vendita'] ?? '').toString() == 'APERTO' &&
          (e['stato_oggetto'] ?? '').toString() == 'IN VENDITA');
      if (r['blocco_rilasciato_automaticamente'] == true) _locked = false;
      if (!mounted) return;
      setState(() {
        _preview = r;
        _status = verified
          ? 'LOTTO SALVATO E VERIFICATO: '+verifiedRows.length.toString()+' vendite registrate. Ogni oggetto risulta IN VENDITA.'
          : 'Esito non verificato completamente: non considerare concluso il lotto. Controlla il risultato runtime.';
      });
      if (verified) {
        if (widget.valoraMode) {
          List<Map<String, dynamic>> drafts = [];
          String? draftError;
          final firstVerified = Map<String, dynamic>.from(verifiedRows.first as Map);
          final saleCode = int.tryParse((firstVerified['codice_vendita_aperta'] ?? '').toString());
          try {
            if (saleCode == null) throw StateError('Codice vendita aperta non restituito dal salvataggio.');
            drafts = await _Pr06ValoraListingDraftApi.create(saleCode);
          } catch (e) {
            draftError = e.toString();
          }
          if (!mounted) return;
          var openDrafts = false;
          await showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
            title: const Text('Vendita registrata e verificata'),
            content: Text(draftError == null
              ? 'La vendita è stata salvata in TEST. Sono state create '+drafts.length.toString()+' bozze, una per ciascuna piattaforma selezionata in PR-06 VALORA. Puoi modificarle senza pubblicare nulla.'
              : 'La vendita è stata salvata e verificata in TEST, ma la generazione delle bozze non è riuscita: '+draftError),
            actions: [
              if (drafts.isNotEmpty) OutlinedButton(
                onPressed: () { openDrafts = true; Navigator.of(ctx).pop(); },
                child: const Text('APRI BOZZE'),
              ),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('FINE')),
            ],
          ));
          if (openDrafts && mounted) {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => Pr06ValoraListingDraftsPage(drafts: drafts),
            ));
          }
          if (mounted) Navigator.of(context).pop(true);
          return;
        }
        await showDialog<void>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
          title: const Text('Lotto salvato e verificato'),
          content: Text(verifiedRows.length.toString()+' vendite sono state registrate e verificate nel database TEST.'),
          actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('FINE'))],
        ));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Lotto non confermato: $e. La procedura SQL salva tutte le operazioni insieme oppure annulla l’intera transazione.');
    } finally {
      await _release();
      if (mounted) setState(() => _busy = false);
    }
  }

}
