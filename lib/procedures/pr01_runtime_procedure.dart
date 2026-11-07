part of '../main.dart';

extension _Pr01RuntimeProcedure on _ObjectRuntimePageState {
  Future<void> _confirmAndSaveNewObject() async {
    if (_description.text.trim().isEmpty) throw Exception('La descrizione oggetto è obbligatoria.');
    final yearText = _line.text.trim();
    if (yearText.isNotEmpty) {
      final year = int.tryParse(yearText);
      if (year == null || year < 1000 || year > DateTime.now().year + 2) {
        throw Exception('Anno di uscita non valido. Inserisci un anno plausibile oppure lascia il campo vuoto.');
      }
    }
    final qty = int.tryParse(_quantity.text.trim());
    if (qty == null || qty < 1) throw Exception('La quantità deve essere un numero intero maggiore di zero.');

    final unitPriceLabel = _unitPrice.text.trim().isEmpty
        ? 'Non indicato'
        : '${_unitPrice.text.trim()} €';
    final totalValueLabel = _totalValue.text.trim().isEmpty
        ? 'Non indicato'
        : '${_totalValue.text.trim()} €';
    final marketValueLabel = _marketValue.text.trim().isEmpty
        ? 'Non indicato'
        : '${_marketValue.text.trim()} €';
    final notesLabel = _notes.text.trim().isEmpty ? 'Nessuna' : _notes.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma inserimento oggetto'),
        content: SingleChildScrollView(
          child: Text(
            'Descrizione: ${_description.text.trim()}\\n'
            'Produttore: ${_producer.text.trim()}\\n'
            'Linea / serie: ${_line.text.trim()}\\n'
            'Famiglia / categoria: ${_family.text.trim()}\\n'
            'Condizione: $_condition\\n'
            'Completezza: $_completeness\\n'
            'Destinazione: $_destination\\n'
            'Quantità: ${_quantity.text.trim()}\\n'
            'Prezzo unitario: $unitPriceLabel\\n'
            'Valore totale: $totalValueLabel\\n'
            'Valore di mercato stimato: $marketValueLabel\\n'
            'Note: $notesLabel\\n\\n'
            'Confermi il salvataggio di questo oggetto nel database TEST?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('CONFERMA E SALVA')),
        ],
      ),
    );
    if (confirmed != true) {
      setState(() => _output = 'Salvataggio annullato. Nessun oggetto salvato.');
      return;
    }

    final currentPayload = _payload();
    final rows = currentPayload['oggetti'];
    if (rows is! List || rows.isEmpty || rows.first is! Map) {
      throw Exception('Nessun oggetto valido da aggiungere al blocco.');
    }
    _pr01PendingObjects.add({
      'oggetto': Map<String, dynamic>.from(rows.first as Map),
      'categoria': _selectedCollectionCategory,
      'image_bytes': _selectedImageBytes == null ? null : Uint8List.fromList(_selectedImageBytes!),
      'image_name': _selectedImageName,
      'image_acquisition': _imageAcquisition,
    });
    _pr01PendingRequestId ??= _uuid.v4();

    if (!mounted) return;
    final addAnother = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Oggetto confermato'),
        content: Text(
          'Vuoi inserire un altro oggetto?\n\n'
          'Se scegli NO, verranno salvati tutti i '
          '${_pr01PendingObjects.length} oggetti raccolti finora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('NO, SALVA IL BLOCCO'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('SÌ, INSERISCI UN ALTRO'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (addAnother == true) {
      setState(() {
        _description.clear();
        _producer.clear();
        _line.clear();
        _family.clear();
        _notes.clear();
        _quantity.text = '1';
        _unitPrice.clear();
        _totalValue.clear();
        _value.clear();
        _marketValue.text = '0.00';
        _condition = 'USATO';
        _completeness = 'COMPLETO';
        _destination = 'COLLEZIONE';
        _selectedCollectionCategory = null;
        _existingImageUrl = null;
        _selectedImageBytes = null;
        _selectedImageName = null;
        _imageStatus = 'Nessuna immagine selezionata.';
        _metadataResult = 'La ricerca dei metadati è disponibile esclusivamente tramite PR-12.';
        _output = 'Blocco provvisorio: ${_pr01PendingObjects.length} oggetti. Inserisci il prossimo.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_descriptionFocus);
      });
      return;
    }

    await _savePr01PendingObjects();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _savePr01PendingObjects() async {
    if (_pr01PendingObjects.isEmpty) {
      throw Exception('Il blocco PR-01 è vuoto: nessun oggetto da salvare.');
    }
    final pending = List<Map<String, dynamic>>.from(_pr01PendingObjects);
    final payload = <String, dynamic>{
      'oggetti': pending.map((entry) =>
        Map<String, dynamic>.from(entry['oggetto'] as Map)).toList(),
      'dati_confermati': true,
      'altra_operazione': false,
      'conferma_finale': true,
    };
    await _acquireLock();
    try {
      final preview = await _ValoraRuntimeApi.procedure(
        'PR-01', 'preview', payload, sessionId: _sessionId);
      if (preview['errore'] != null) throw Exception(preview['errore'].toString());
      final review = await _ValoraRuntimeApi.procedure(
        'PR-01', 'review', payload, sessionId: _sessionId);
      if (review['errore'] != null) throw Exception(review['errore'].toString());
      final result = await _ValoraRuntimeApi.procedure(
        'PR-01', 'save', payload, sessionId: _sessionId,
        requestId: _pr01PendingRequestId ??= _uuid.v4());
      if (result['scrittura_eseguita'] != true) {
        throw Exception('Il runtime non ha confermato il salvataggio del blocco PR-01.');
      }
      if (result['blocco_rilasciato_automaticamente'] == true) {
        setState(() => _lockHeld = false);
      } else {
        throw Exception('Blocco salvato, ma il rilascio del blocco non è stato confermato.');
      }
      final savedRows = result['risultati'];
      if (savedRows is! List || savedRows.length != pending.length) {
        throw Exception('Il runtime non ha restituito tutti i codici oggetto del blocco.');
      }
      for (var index = 0; index < pending.length; index++) {
        final savedRow = savedRows[index] is Map
          ? Map<String, dynamic>.from(savedRows[index] as Map)
          : <String, dynamic>{};
        final savedId = int.tryParse((savedRow['codice_oggetto'] ?? '').toString());
        if (savedId == null) throw Exception('Codice oggetto mancante nell’elemento ${index + 1}.');
        final category = pending[index]['categoria']?.toString();
        if (category != null && category.isNotEmpty) {
          await Supabase.instance.client.schema('collection')
            .from('oggetto_collezione_categoria').upsert({
              'codice_oggetto': savedId,
              'codice_categoria': category,
              'fonte_assegnazione': 'MANUALE',
              'stato_verifica': 'VERIFICATO',
              'aggiornato_il': DateTime.now().toIso8601String(),
            }, onConflict: 'codice_oggetto');
        }
        final bytes = pending[index]['image_bytes'];
        final name = pending[index]['image_name'];
        if (bytes is Uint8List && name is String && name.isNotEmpty) {
          await _uploadAndRegisterImage(
            objectId: savedId,
            bytes: bytes,
            fileName: name,
            acquisition: pending[index]['image_acquisition'] as String? ?? _imageAcquisition,
            procedure: 'PR-01',
          );
        }
      }
      _pr01PendingObjects.clear();
      _pr01PendingRequestId = null;
      if (mounted) setState(() {
        _description.clear(); _producer.clear(); _line.clear(); _family.clear();
        _notes.clear(); _quantity.text = '1'; _unitPrice.clear(); _totalValue.clear();
        _value.clear(); _marketValue.text = '0.00'; _selectedCollectionCategory = null;
        _selectedImageBytes = null; _selectedImageName = null;
        _imageStatus = 'Nessuna immagine selezionata.';
        _output = 'Blocco PR-01 salvato e verificato: ${pending.length} oggetti.';
      });
    } catch (e) {
      if (_lockHeld) { try { await _releaseLock(); } catch (_) {} }
      if (mounted) setState(() => _output =
        'ERRORE nel salvataggio del blocco PR-01. Gli oggetti restano in attesa: $e');
      rethrow;
    }
  }
}
