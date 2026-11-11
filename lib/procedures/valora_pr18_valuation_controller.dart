part of '../main.dart';

/// Preparazione PR-18 e persistenza dello storico valutazioni sugli oggetti già catalogati.
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
        final response = await Supabase.instance.client.functions.invoke(
          'pr-18-valuation-test',
          body: {
            'codice_oggetto': id,
            'metadati': metadata,
            'mercato_riferimento': _market,
          },
        );
        final data = response.data;
        if (data is! Map || data['ok'] != true) {
          throw StateError(data is Map
            ? (data['error'] ?? 'PR18 non ha completato la valutazione.').toString()
            : 'Risposta PR18 non valida.');
        }
        if (!mounted) return;
        setState(() => _prepared = Map<String, dynamic>.from(data));
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
      setState(() { _preparing = true; _error = null; });
      try {
        final response = await Supabase.instance.client.functions.invoke(
          'pr-18-valuation-test',
          body: {
            'azione': 'SALVA_VALUTAZIONE',
            'codice_oggetto': objectId,
            'metadati': {
              'descrizione': (object['descrizione_oggetto'] ?? '').toString(),
              'produttore': (object['produttore'] ?? '').toString(),
              'codice_prodotto': (object['codice_prodotto'] ?? '').toString(),
            },
            'mercato_riferimento': _market,
            'valutazione': valuation,
          },
        );
        final data = response.data;
        if (data is! Map || data['ok'] != true) {
          throw StateError(data is Map
              ? (data['error'] ?? 'Salvataggio della valutazione non riuscito.').toString()
              : 'Risposta di salvataggio PR18 non valida.');
        }
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
