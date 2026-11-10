part of '../main.dart';

extension _CollectionValueRuntime on _CollectionValuePageState {
  Future<void> _load() async {
    if (_loading == false && mounted) setState(() => _loading = true);
    if (mounted) setState(() => _error = null);
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait<List<Map<String, dynamic>>>([
        _readAll('master_oggetti', 'codice_oggetto,descrizione_oggetto,destinazione,stato,quantita,valore_oggetto,valore_mercato,archiviato_test'),
        _readAll('acquisti_oggetti', 'codice_oggetto,valore_acquisto_oggetto,quantita,incluso_nella_quadratura,valuta'),
        _readAll('master_oggetti_in_vendita', 'codice_vendita_aperta,codice_oggetto,prezzo_di_vendita,valuta,stato_ciclo_vendita,codice_lotto'),
        _readAll('lotti_vendita', 'codice_lotto,prezzo_totale_inserzione,valuta,stato_lotto'),
        _readAll('master_vendite', 'codice_vendita,codice_oggetto,data_vendita,importo_vendita,valuta,stato_vendita,codice_lotto'),
        _readAll('cassa', 'data,tipo_movimento,importo,tipologia,valuta,codice_vendita,codice_acquisto'),
      ]);

      final objects = results[0];
      final purchases = results[1];
      final listings = results[2];
      final lots = results[3];
      final sales = results[4];
      final cash = results[5];

      Map<String, dynamic>? latest;
      double? latestTotal;
      double? previousTotal;
      // Lo storico è un arricchimento: se il servizio non risponde, il riepilogo
      // patrimoniale continua comunque a funzionare con i dati correnti.
      try {
        final response = await client.functions.invoke(
          'collection-valuation-history',
          body: <String, dynamic>{},
        );
        if (response.status >= 200 && response.status < 300 && response.data is Map) {
          final payload = Map<String, dynamic>.from(response.data as Map);
          if (payload['ok'] == true) {
            if (payload['ultima_valutazione'] is Map) {
              latest = Map<String, dynamic>.from(payload['ultima_valutazione'] as Map);
            }
            latestTotal = _num(payload['valore_ultima']);
            previousTotal = _num(payload['valore_precedente']);
          }
        }
      } catch (_) {
        // Nessun blocco della dashboard per indisponibilità dello storico.
      }

      if (!mounted) return;
      setState(() {
        _objects = objects;
        _purchases = purchases;
        _listings = listings;
        _lots = lots;
        _sales = sales;
        _cash = cash;
        _latest = latest;
        _latestTotal = latestTotal;
        _previousTotal = previousTotal;
        _refreshedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossibile aggiornare il riepilogo patrimoniale: $e';
        _loading = false;
      });
    }
  }


  Future<void> _capturePatrimonySnapshot() async {
    if (_snapshotBusy) return;
    setState(() => _snapshotBusy = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'collection-patrimony-snapshot',
        body: <String, dynamic>{},
      );
      if (response.status < 200 || response.status >= 300) {
        throw Exception('Servizio snapshot non disponibile: ${response.status}');
      }
      final result = Map<String, dynamic>.from(response.data as Map);
      if (result['ok'] != true) {
        throw Exception((result['error'] ?? 'Calcolo non riuscito').toString());
      }
      if (!mounted) return;
      setState(() => _snapshotBusy = false);
      final hasPrevious = result['precedente'] != null;
      final total = _num(result['variazione_totale']);
      final quantity = _num(result['variazione_quantita']);
      final revaluation = _num(result['variazione_rivalutazioni']);
      final residual = _num(result['variazione_non_attribuita']);
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confronto della collezione'),
          content: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text('Valore attuale: ${_eur(_num(result['valore_mercato']) ?? 0)}'),
              const SizedBox(height: 10),
              if (!hasPrevious) const Text('Prima fotografia salvata. Il prossimo calcolo permetterà il confronto.'),
              if (hasPrevious) ...[
                Text('Variazione totale: ${_eur(total ?? 0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Effetto quantità / oggetti: ${_eur(quantity ?? 0)}'),
                Text('Effetto rivalutazione: ${_eur(revaluation ?? 0)}'),
                Text('Non attribuito / dati mancanti: ${_eur(residual ?? 0)}'),
                const SizedBox(height: 8),
                const Text('Il residuo segnala differenze non spiegabili con certezza dai dati disponibili.'),
              ],
              const SizedBox(height: 8),
              Text('Record: ${result['record'] ?? 0} · Unità: ${result['unita'] ?? 0}'),
              Text('Oggetti senza stima: ${result['oggetti_senza_stima'] ?? 0}'),
            ]),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Chiudi'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _snapshotBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot non riuscito: $e')),
      );
    }
  }
}
