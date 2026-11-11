part of '../main.dart';

/// Coordinamento UI della valutazione PR-18 per oggetti già presenti nel catalogo.
extension _ValoraKnownObjectPr18Controller on _ValoraServicePageState {
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
      final data = await _requestKnownObjectPr18Valuation(
        objectId: id,
        metadata: metadata,
        market: _market,
      );
      if (!mounted) return;
      setState(() => _prepared = data);
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
    final metadata = {
      'descrizione': (object['descrizione_oggetto'] ?? '').toString(),
      'produttore': (object['produttore'] ?? '').toString(),
      'codice_prodotto': (object['codice_prodotto'] ?? '').toString(),
    };
    setState(() { _preparing = true; _error = null; });
    try {
      final data = await _persistKnownObjectPr18Valuation(
        objectId: objectId,
        metadata: metadata,
        market: _market,
        valuation: valuation,
      );
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
}
