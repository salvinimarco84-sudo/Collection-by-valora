part of '../main.dart';

/// Selezione e caricamento della scheda oggetto per la procedura PR-03.
extension _Pr03ObjectSelection on _ObjectRuntimePageState {
  Future<void> _selectPr03Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null || id <= 0) {
      throw Exception('Il risultato non contiene un codice oggetto valido.');
    }

    // Invalida subito la selezione precedente: se il caricamento del nuovo
    // record fallisce, PR-03 non deve poter chiudere per errore il vecchio.
    setState(() {
      _code.text = id.toString();
      _currentObject = null;
      _loadedObjectId = null;
      _notes.clear();
      _metadataResult = '';
    });

    await _loadObject();
    if (!mounted) return;
    if (_loadedObjectId != id || _currentObject == null) {
      throw Exception('La scheda caricata non corrisponde all’oggetto selezionato ($id).');
    }

    // In PR-03 il campo di ricerca mostra la descrizione del record selezionato,
    // non la query digitata prima di scegliere il risultato.
    final selectedDescription = (_currentObject?['descrizione_oggetto']
        ?? _currentObject?['descrizione']
        ?? item['descrizione_oggetto']
        ?? '').toString().trim();

    const metadataKeys = [
      'produttore',
      'anno_uscita',
      'codice_prodotto',
      'fonte_dati_prodotto',
    ];
    final missing = metadataKeys.any(
      (key) => (_currentObject?[key]?.toString().trim().isEmpty ?? true),
    );

    setState(() {
      if (selectedDescription.isNotEmpty) _search.text = selectedDescription;
      _metadataResult = missing
          ? 'Scheda caricata. Alcuni metadati risultano assenti: verifica la scheda prima di confermare la chiusura.'
          : 'Scheda completa caricata automaticamente dal database.';
    });
  }
}
