part of '../main.dart';

/// Selezione e caricamento della scheda oggetto per la procedura PR-03.
extension _Pr03ObjectSelection on _ObjectRuntimePageState {
  Future<void> _selectPr03Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null) throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text = id.toString();
    await _loadObject();
    if (!mounted || _currentObject == null) return;

    // In PR-03 il campo di ricerca diventa la descrizione del record effettivamente selezionato.
    // Non lasciare visibile la query digitata dall'utente come se fosse la descrizione dell'oggetto.
    final selectedDescription = (_currentObject?['descrizione_oggetto']
        ?? _currentObject?['descrizione']
        ?? item['descrizione_oggetto']
        ?? '').toString().trim();
    if (selectedDescription.isNotEmpty) {
      setState(() => _search.text = selectedDescription);
    }

    final metadataKeys = ['produttore', 'anno_uscita', 'codice_prodotto', 'fonte_dati_prodotto'];
    final missing = metadataKeys.any((key) => (_currentObject?[key]?.toString().trim().isEmpty ?? true));
    if (missing) {
      setState(() => _metadataResult = 'Scheda caricata. Alcuni metadati risultano assenti: verifica la scheda prima di confermare la chiusura.');
    } else {
      setState(() => _metadataResult = 'Scheda completa caricata automaticamente dal database.');
    }
  }
}
