part of '../main.dart';

extension _Pr02RuntimeProcedure on _ObjectRuntimePageState {
  Map<String, dynamic> _pr02ConfirmationPayload() {
    final payload = _payload();
    final rows = payload['oggetti'];
    if (rows is! List || rows.isEmpty || rows.first is! Map) {
      throw Exception('Non ci sono modifiche valide da confermare.');
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }

  String _pr02ConfirmationText(Map<String, dynamic> item) {
    final labels = <String, String>{
      'codice_oggetto': 'Codice oggetto',
      'descrizione': 'Descrizione oggetto',
      'produttore': 'Produttore',
      'anno_uscita': 'Anno di uscita',
      'codice_prodotto': 'Codice prodotto',
      'fonte_dati_prodotto': 'Fonte dati',
      'stato_verifica_dati': 'Stato verifica dati',
      'condizione': 'Condizione',
      'completezza': 'Completezza',
      'destinazione': 'Destinazione',
      'quantita': 'Quantità',
      'valore_oggetto': 'Valore oggetto (€)',
      'note': 'Note',
    };
    return item.entries.map((e) =>
      '${labels[e.key] ?? _italianFieldLabel(e.key)}: ${_displayFieldValue(e.value)}'
    ).join('\\n');
  }

  Future<void> _confirmPr02Changes() async {
    if (_currentObject == null || _loadedObjectId == null) {
      throw Exception('Seleziona prima un oggetto dalla ricerca.');
    }

    // Ogni oggetto viene salvato e verificato prima di consentire una nuova modifica.
    final item = _pr02ConfirmationPayload();
    final objectCode = item['codice_oggetto']?.toString();
    if (objectCode == null || objectCode.isEmpty) {
      throw Exception('Codice oggetto mancante: impossibile accodare la modifica.');
    }

    _pr02PendingChanges.removeWhere(
      (e) => e['codice_oggetto']?.toString() == objectCode,
    );
    _pr02PendingChanges.add(Map<String, dynamic>.from(item));

    if (_selectedImageBytes != null && _selectedImageName != null) {
      _pr02PendingImages[objectCode] = {
        'bytes': Uint8List.fromList(_selectedImageBytes!),
        'name': _selectedImageName!,
        'acquisition': _imageAcquisition,
      };
    }

    if (_lockHeld) await _releaseLock();
    if (!mounted) return;

    await _savePr02PendingChanges(closeOnComplete: false);
    if (!mounted) return;

    setState(() {
      _dataConfirmed = true;
      _finalReady = false;
      _pr02AwaitingNextChoice = true;
      _output = 'Oggetto $objectCode salvato e verificato. Puoi modificare un altro oggetto oppure terminare.';
    });
  }

  Future<void> _continuePr02WithAnotherObject() async {
      setState(() {
        _search.clear();
        _code.clear();
        _description.clear();
        _notes.clear();
        _producer.clear();
        _line.clear();
        _family.clear();
        _value.clear();
        _currentObject = null;
        _loadedObjectId = null;
        _pr02SearchResults = [];
        _pr02SearchCompleted = false;
        _metadataSourceUrl = null;
        _metadataSearchExecuted = false;
        _metadataResult = 'Inserisci una parola o parte della descrizione per iniziare.';
        _lastResult = null;
        _dataConfirmed = false;
        _finalReady = false;
        _showPr02TechnicalTab = false;
        _selectedImageBytes = null; _selectedImageName = null; _existingImageUrl = null;
        _imageStatus = 'Nessuna immagine selezionata.';
        _output = 'PR-02 pronta per una nuova ricerca.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
      });
      setState(() => _pr02AwaitingNextChoice = false);
      return;
  }

  Future<void> _finishPr02PendingChanges() async {
    if (_pr02PendingChanges.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await _savePr02PendingChanges();
  }

  Future<void> _savePr02PendingChanges({bool closeOnComplete = true}) async {
    final pending = _pr02PendingChanges
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    for (final item in pending) {
      final categoryCode = item['categoria_collezione_selezionata']?.toString();
      final objectPayload = Map<String, dynamic>.from(item)..remove('categoria_collezione_selezionata');
      final objectHasChanges = objectPayload.keys.any((key) => key != 'codice_oggetto');
      final payload = <String, dynamic>{
        'oggetti': [objectPayload],
        'dati_confermati': true,
        'altra_operazione': false,
        'conferma_finale': true,
      };
      final pendingImage = _pr02PendingImages[item['codice_oggetto'].toString()];
      if (objectHasChanges) await _acquireLock();
      try {
        if (objectHasChanges) {
        final preview = await _ValoraRuntimeApi.procedure(
          'PR-02', 'preview', payload, sessionId: _sessionId);
        if (preview['errore'] != null) {
          throw Exception(preview['errore'].toString());
        }
        await _ValoraRuntimeApi.procedure(
          'PR-02', 'review', payload, sessionId: _sessionId);
        final result = await _ValoraRuntimeApi.procedure(
          'PR-02', 'save', payload, sessionId: _sessionId, requestId: _uuid.v4());
        if (result['scrittura_eseguita'] != true) {
          throw Exception('Salvataggio non confermato per oggetto ${item['codice_oggetto']}.');
        }
        if (result['blocco_rilasciato_automaticamente'] == true) {
          setState(() => _lockHeld = false);
        } else {
          throw Exception('Salvataggio eseguito ma rilascio del blocco non confermato.');
        }
        }
        final objectIdForCategory = int.tryParse(item['codice_oggetto'].toString());
        if (objectIdForCategory != null) {
          if (categoryCode != null && categoryCode.isNotEmpty) {
            await Supabase.instance.client.schema('collection').from('oggetto_collezione_categoria').upsert({
              'codice_oggetto': objectIdForCategory, 'codice_categoria': categoryCode,
              'fonte_assegnazione': 'MANUALE', 'stato_verifica': 'VERIFICATO',
              'aggiornato_il': DateTime.now().toIso8601String(),
            }, onConflict: 'codice_oggetto');
          } else {
            await Supabase.instance.client.schema('collection').from('oggetto_collezione_categoria')
              .delete().eq('codice_oggetto', objectIdForCategory);
          }
        }
        if (pendingImage != null) {
          final signedUrl = await _uploadAndRegisterImage(
            objectId: int.parse(item['codice_oggetto'].toString()), bytes: pendingImage['bytes'] as Uint8List,
            fileName: pendingImage['name'] as String, acquisition: pendingImage['acquisition'] as String, procedure: 'PR-02');
          _pr02PendingImages.remove(item['codice_oggetto'].toString());
          if (_loadedObjectId == int.tryParse(item['codice_oggetto'].toString()) && mounted) {
            setState(() { _existingImageUrl = signedUrl; _imageStatus = 'Immagine associata e verificata.'; });
          }
        }
      } catch (_) {
        if (_lockHeld) {
          try { await _releaseLock(); } catch (_) {}
        }
        rethrow;
      }
    }
    _pr02PendingChanges.clear();
    if (!mounted || !closeOnComplete) return;
    Navigator.of(context).pop();
  }
}
