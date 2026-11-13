part of '../main.dart';

/// Conferma dell'oggetto e gestione della coda temporanea PR-01.
extension _Pr01ConfirmationWorkflow on _ObjectRuntimePageState {
  Future<void> _confirmAndSaveNewObject() async {
    // La validazione e la costruzione del payload sono responsabilità del controller PR-01.
    _payload();

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
}
