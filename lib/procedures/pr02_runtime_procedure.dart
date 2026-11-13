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

}
