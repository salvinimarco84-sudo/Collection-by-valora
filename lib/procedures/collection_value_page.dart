part of '../main.dart';

class CollectionValuePage extends StatefulWidget {
  const CollectionValuePage({super.key});
  @override
  State<CollectionValuePage> createState() => _CollectionValuePageState();
}

class _CollectionValuePageState extends State<CollectionValuePage> with _CollectionValuePresentation {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _lots = [];
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _cash = [];
  Map<String, dynamic>? _latest;
  double? _latestTotal;
  double? _previousTotal;
  DateTime? _refreshedAt;
  bool _snapshotBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _maps(dynamic value) =>
      (value as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  Future<List<Map<String, dynamic>>> _readAll(String table, String columns) async {
    final all = <Map<String, dynamic>>[];
    for (var offset = 0; offset < 100000; offset += 1000) {
      final page = await Supabase.instance.client.schema('collection')
          .from(table).select(columns).range(offset, offset + 999);
      final rows = _maps(page);
      all.addAll(rows);
      if (rows.length < 1000) break;
    }
    return all;
  }

  double? _num(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  int? _id(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  String _eur(double value) {
    final fixed = value.abs().toStringAsFixed(2).split('.');
    final grouped = fixed[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '${value < 0 ? '-' : ''}€ $grouped,${fixed[1]}';
  }

  String _date(dynamic value) {
    final parsed = value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
    if (parsed == null) return 'Data non disponibile';
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  bool _excludedState(dynamic value) {
    final state = (value ?? '').toString().trim().toUpperCase();
    return const {'USCITO', 'VENDUTO', 'PERSO', 'DISTRUTTO', 'ACCORPATO'}.contains(state);
  }

  bool _isEuro(dynamic value) {
    final currency = (value ?? 'EUR').toString().trim().toUpperCase();
    return currency.isEmpty || currency == 'EUR' || currency == '€';
  }

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


  @override
  Widget build(BuildContext context) {
    final excludedIds = _sales
        .where((s) => (s['stato_vendita'] ?? '').toString().toUpperCase() == 'CONCLUSA')
        .map((s) => _id(s['codice_oggetto']))
        .whereType<int>()
        .toSet();

    final activeObjects = _objects.where((o) =>
      o['archiviato_test'] != true &&
      !_excludedState(o['stato']) &&
      !excludedIds.contains(_id(o['codice_oggetto']))
    ).toList();

    final collection = activeObjects.where((o) => (o['destinazione'] ?? '').toString().toUpperCase() == 'COLLEZIONE').toList();
    final resale = activeObjects.where((o) => (o['destinazione'] ?? '').toString().toUpperCase() == 'RIVENDITA').toList();

    final acquisitionByObject = <String, double>{};
    for (final p in _purchases) {
      if (p['incluso_nella_quadratura'] != true || !_isEuro(p['valuta'])) continue;
      final id = _id(p['codice_oggetto']);
      final amount = _num(p['valore_acquisto_oggetto']);
      if (id == null || amount == null) continue;
      final quantity = (_num(p['quantita']) ?? 1).clamp(1, 100000).toDouble();
      acquisitionByObject[id.toString()] = (acquisitionByObject[id.toString()] ?? 0) + amount * quantity;
    }

    double collectionMarket = 0;
    double collectionHistoricalCost = 0;
    int collectionUnits = 0;
    int collectionUnvalued = 0;
    int collectionCostCoverage = 0;
    double collectionComparableMarket = 0;
    double collectionComparableCost = 0;
    int collectionComparableCount = 0;
    for (final o in collection) {
      final id = _id(o['codice_oggetto']);
      final quantity = (_num(o['quantita']) ?? 1).clamp(1, 100000).toInt();
      collectionUnits += quantity;
      final market = _num(o['valore_mercato']);
      if (market == null) {
        collectionUnvalued++;
      } else {
        collectionMarket += market * quantity;
      }
      final cost = id == null ? null : acquisitionByObject[id.toString()];
      if (cost != null) {
        collectionHistoricalCost += cost;
        collectionCostCoverage++;
        if (market != null) {
          collectionComparableMarket += market * quantity;
          collectionComparableCost += cost;
          collectionComparableCount++;
        }
      }
    }

    double resaleKnownCost = 0;
    int resaleCostCoverage = 0;
    int resaleUnits = 0;
    for (final o in resale) {
      final id = _id(o['codice_oggetto']);
      resaleUnits += (_num(o['quantita']) ?? 1).clamp(1, 100000).toInt();
      final cost = id == null ? null : acquisitionByObject[id.toString()];
      if (cost != null) {
        resaleKnownCost += cost;
        resaleCostCoverage++;
      }
    }

    final openListings = _listings.where((l) =>
      (l['stato_ciclo_vendita'] ?? '').toString().toUpperCase() == 'APERTO'
    ).toList();
    final resaleIds = resale.map((o) => _id(o['codice_oggetto'])).whereType<int>().toSet();
    final activeListingObjects = openListings
        .map((l) => _id(l['codice_oggetto']))
        .whereType<int>()
        .where(resaleIds.contains)
        .toSet();
    double activeListingValue = 0;
    int individualListings = 0;
    for (final l in openListings) {
      final objectId = _id(l['codice_oggetto']);
      if (l['codice_lotto'] != null || (objectId != null && !resaleIds.contains(objectId)) || !_isEuro(l['valuta'])) continue;
      activeListingValue += _num(l['prezzo_di_vendita']) ?? 0;
      individualListings++;
    }
    final openLots = _lots.where((l) => (l['stato_lotto'] ?? '').toString().toUpperCase() == 'APERTO').toList();
    for (final lot in openLots) {
      if (_isEuro(lot['valuta'])) activeListingValue += _num(lot['prezzo_totale_inserzione']) ?? 0;
    }

    final completedSales = _sales.where((s) =>
      (s['stato_vendita'] ?? '').toString().toUpperCase() == 'CONCLUSA'
    ).toList();
    final grossSales = completedSales.where((s) => _isEuro(s['valuta']))
        .fold<double>(0, (sum, s) => sum + (_num(s['importo_vendita']) ?? 0));
    double soldHistoricalCost = 0;
    int soldCostCoverage = 0;
    for (final sale in completedSales) {
      final id = _id(sale['codice_oggetto']);
      final cost = id == null ? null : acquisitionByObject[id.toString()];
      if (cost != null) {
        soldHistoricalCost += cost;
        soldCostCoverage++;
      }
    }

    double cashIn = 0;
    double cashOut = 0;
    for (final movement in _cash) {
      if (!_isEuro(movement['valuta'])) continue;
      final amount = _num(movement['importo']) ?? 0;
      final type = (movement['tipologia'] ?? '').toString().toUpperCase();
      if (type == 'ENTRATA') cashIn += amount;
      if (type == 'USCITA') cashOut += amount;
    }
    final cashNet = cashIn - cashOut;
    final linkedSaleExpenses = _cash.where((movement) =>
      (movement['tipologia'] ?? '').toString().toUpperCase() == 'USCITA' &&
      movement['codice_vendita'] != null && _isEuro(movement['valuta'])
    ).fold<double>(0, (sum, movement) => sum + (_num(movement['importo']) ?? 0));
    final netRealizedProfit = completedSales.isNotEmpty && soldCostCoverage == completedSales.length
        ? grossSales - soldHistoricalCost - linkedSaleExpenses
        : null;
    final documentedTotal = collectionMarket + resaleKnownCost;
    final missingResaleCosts = (resale.length - resaleCostCoverage).clamp(0, 100000);
    final costCoverageComplete = missingResaleCosts == 0;
    final collectionValued = (collection.length - collectionUnvalued).clamp(0, 100000);
    final collectionValuationCoverage = collection.isEmpty ? 0.0 : collectionValued / collection.length;
    final activeAssetCount = collection.length + resale.length;
    final knownAcquisitionObjects = collectionCostCoverage + resaleCostCoverage;
    final acquisitionCoverage = activeAssetCount == 0 ? 0.0 : knownAcquisitionObjects / activeAssetCount;
    final delta = _latestTotal != null && _previousTotal != null ? _latestTotal! - _previousTotal! : null;
    final trendColor = delta == null ? const Color(0xFFB9A77A) : delta >= 0 ? const Color(0xFF73C58B) : const Color(0xFFE47A72);
    final backgroundUrl = ValoraAppearance.instance.imageUrls['COLLEZIONE'];

    return Scaffold(
      backgroundColor: const Color(0xFF10100F),
      appBar: AppBar(
        title: const Text('RIEPILOGO PATRIMONIALE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
        backgroundColor: const Color(0xFF10100F),
        foregroundColor: const Color(0xFFE8D39B),
        actions: [
          IconButton(
            tooltip: 'Aggiorna dati',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD6B15E)))
          : _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_outlined, color: Color(0xFFE5C77A), size: 42),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 14),
                    FilledButton(onPressed: _load, child: const Text('RIPROVA')),
                  ]),
                ))
              : RefreshIndicator(
                  color: const Color(0xFFD6B15E),
                  backgroundColor: const Color(0xFF1A1917),
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 28),
                    children: [
                      Container(
                        height: 224,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFFD6B15E).withValues(alpha: 0.7), width: 1.1),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.42), blurRadius: 22, offset: const Offset(0, 9))],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(fit: StackFit.expand, children: [
                          if (backgroundUrl != null && backgroundUrl.trim().isNotEmpty)
                            Image.network(backgroundUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF090909).withValues(alpha: 0.68),
                                  const Color(0xFF17130D).withValues(alpha: 0.91),
                                  const Color(0xFF090909).withValues(alpha: 0.97),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                const Icon(Icons.diamond_outlined, color: Color(0xFFE5C77A), size: 19),
                                const SizedBox(width: 8),
                                const Text('VALORA  /  PATRIMONIO', style: TextStyle(color: Color(0xFFE5C77A), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(color: const Color(0xFFD6B15E).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFD6B15E).withValues(alpha: 0.4))),
                                  child: const Text('VALORI TRACCIATI', style: TextStyle(color: Color(0xFFE5C77A), fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                                ),
                              ]),
                              const Spacer(),
                              const Text('IL TUO PATRIMONIO', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 5),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(_eur(documentedTotal), style: const TextStyle(color: Color(0xFFF3D990), fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1.1)),
                              ),
                              const SizedBox(height: 5),
                              Text('Collezione a valore di mercato + stock commerciale a costo documentato', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 10)),
                              const SizedBox(height: 11),
                              Row(children: [
                                const Icon(Icons.inventory_2_outlined, color: Color(0xFFE5C77A), size: 15),
                                const SizedBox(width: 6),
                                Text('${collection.length + resale.length} oggetti nel patrimonio', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                if (!costCoverageComplete)
                                  Text('Stock: ${resaleCostCoverage}/${resale.length} costi noti', style: const TextStyle(color: Color(0xFFE7B56D), fontSize: 9, fontWeight: FontWeight.w700)),
                              ]),
                            ]),
                          ),
                        ]),
                      ),
                      if (!costCoverageComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(color: const Color(0xFF5B421E).withValues(alpha: 0.35), borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE7B56D).withValues(alpha: 0.35))),
                            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(Icons.info_outline, color: Color(0xFFE7B56D), size: 17),
                              SizedBox(width: 8),
                              Expanded(child: Text('Il totale mostra i valori effettivamente documentati. Per alcuni oggetti destinati alla vendita manca ancora il costo di acquisto registrato: non viene inventato né stimato.', style: TextStyle(color: Color(0xFFE8D5B4), fontSize: 10, height: 1.35))),
                            ]),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD6B45F), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD6B45F).withValues(alpha: 0.12),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: AspectRatio(
                              aspectRatio: 1600 / 700,
                              child: Image.asset(
                                'assets/patrimony_sections/banner_riepilogo_patrimoniale.jpg',
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),

                      _sectionHeading('AFFIDABILITÀ DEI DATI', 'Quanto sono completi i valori e i costi registrati', Icons.fact_check_outlined),
                      _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.fact_check_outlined, color: Color(0xFFE5C77A), size: 18),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Copertura delle valutazioni', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700))),
                          Text('${(collectionValuationCoverage * 100).toStringAsFixed(1).replaceAll('.', ',')}%', style: const TextStyle(color: Color(0xFF73C58B), fontSize: 15, fontWeight: FontWeight.w900)),
                        ]),
                        const SizedBox(height: 7),
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
                          value: collectionValuationCoverage.clamp(0.0, 1.0),
                          minHeight: 8, backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF73C58B)),
                        )),
                        const SizedBox(height: 5),
                        Text('$collectionValued di ${collection.length} oggetti della collezione con valore di mercato; $collectionUnvalued ancora da valutare.',
                          style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        const Divider(color: Colors.white12, height: 22),
                        Row(children: [
                          const Icon(Icons.receipt_long_outlined, color: Color(0xFFE5C77A), size: 18),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Copertura dei costi di acquisto', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700))),
                          Text('${(acquisitionCoverage * 100).toStringAsFixed(1).replaceAll('.', ',')}%', style: const TextStyle(color: Color(0xFFE7B56D), fontSize: 15, fontWeight: FontWeight.w900)),
                        ]),
                        const SizedBox(height: 7),
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
                          value: acquisitionCoverage.clamp(0.0, 1.0),
                          minHeight: 8, backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE7B56D)),
                        )),
                        const SizedBox(height: 5),
                        Text('$knownAcquisitionObjects di $activeAssetCount oggetti attivi con costo storico documentato. Il dato non comprende gli oggetti già venduti.',
                          style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ])),

                      _sectionImageHeader('assets/patrimony_sections/01_collezione_personale.png', 'COLLEZIONE PERSONALE', 'Il valore di ciò che possiedi e conservi'),
                      _panel(child: Column(children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 1.48,
                          children: [
                            _metricCard(label: 'Valore di mercato', value: _eur(collectionMarket), icon: Icons.auto_graph, accent: const Color(0xFFE5C77A), detail: 'Valore corrente registrato'),
                            _metricCard(label: 'Costo storico noto', value: _eur(collectionHistoricalCost), icon: Icons.receipt_long_outlined, accent: const Color(0xFFB9C8D7), detail: '$collectionCostCoverage oggetti con acquisto tracciato'),
                            _metricCard(label: 'Oggetti posseduti', value: '${collection.length}', icon: Icons.inventory_2_outlined, accent: const Color(0xFFB79AE8), detail: '$collectionUnits unità complessive'),
                            _metricCard(label: 'Da valutare', value: '$collectionUnvalued', icon: Icons.hourglass_empty, accent: const Color(0xFFE6A36B), detail: 'Senza valore di mercato registrato'),
                          ],
                        ),
                        const SizedBox(height: 11),
                        _detailLine('Rivalutazione su oggetti confrontabili', collectionComparableCount == 0 ? 'Non calcolabile' : _eur(collectionComparableMarket - collectionComparableCost), valueColor: collectionComparableCount == 0 ? Colors.white54 : collectionComparableMarket >= collectionComparableCost ? const Color(0xFF73C58B) : const Color(0xFFE47A72), hint: 'Solo oggetti con costo storico e valore di mercato entrambi registrati: $collectionComparableCount'),
                      ])),

                      _sectionImageHeader('assets/patrimony_sections/02_patrimonio_commerciale.png', 'PATRIMONIO COMMERCIALE', 'Gli oggetti destinati alla vendita restano qui finché non sono venduti'),
                      _panel(child: Column(children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 9,
                          crossAxisSpacing: 9,
                          childAspectRatio: 1.48,
                          children: [
                            _metricCard(label: 'Stock a costo noto', value: _eur(resaleKnownCost), icon: Icons.inventory, accent: const Color(0xFFE5C77A), detail: '$resaleCostCoverage di ${resale.length} oggetti con costo'),
                            _metricCard(label: 'Inserzioni attive', value: _eur(activeListingValue), icon: Icons.sell_outlined, accent: const Color(0xFF86B6D9), detail: '${individualListings + openLots.length} inserzioni / lotti aperti'),
                            _metricCard(label: 'Oggetti in rivendita', value: '${resale.length}', icon: Icons.widgets_outlined, accent: const Color(0xFFB79AE8), detail: '$resaleUnits unità ancora possedute'),
                            _metricCard(label: 'Vendite concluse', value: _eur(grossSales), icon: Icons.point_of_sale_outlined, accent: const Color(0xFF73C58B), detail: '${completedSales.length} vendite registrate'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _detailLine('Oggetti presenti in inserzioni aperte', '${activeListingObjects.length}', valueColor: const Color(0xFF86B6D9)),
                        _detailLine('Costi di acquisto non ancora documentati', '$missingResaleCosts', valueColor: missingResaleCosts == 0 ? const Color(0xFF73C58B) : const Color(0xFFE7B56D)),
                        _detailLine('Utile netto realizzato', netRealizedProfit == null ? 'Non calcolabile' : _eur(netRealizedProfit), valueColor: netRealizedProfit == null ? const Color(0xFFE7B56D) : netRealizedProfit >= 0 ? const Color(0xFF73C58B) : const Color(0xFFE47A72), hint: 'Costi documentati per $soldCostCoverage di ${completedSales.length} vendite; incluse le sole spese collegate alla vendita'),
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text('La vendita conclusa esclude l’oggetto dal patrimonio commerciale. Il suo storico e l’incasso restano registrati.', style: TextStyle(color: Colors.white54, fontSize: 10, height: 1.35)),
                        ),
                      ])),

                      _sectionImageHeader('assets/patrimony_sections/03_liquidita_movimenti.png', 'LIQUIDITÀ E MOVIMENTI', 'Entrate e uscite registrate nella cassa'),
                      _panel(child: Column(children: [
                        Row(children: [
                          Expanded(child: _metricCard(label: 'Entrate registrate', value: _eur(cashIn), icon: Icons.south_west, accent: const Color(0xFF73C58B))),
                          const SizedBox(width: 9),
                          Expanded(child: _metricCard(label: 'Uscite registrate', value: _eur(cashOut), icon: Icons.north_east, accent: const Color(0xFFE47A72))),
                        ]),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFFD6B15E).withValues(alpha: 0.09), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFD6B15E).withValues(alpha: 0.25))),
                          child: Row(children: [
                            const Icon(Icons.account_balance, color: Color(0xFFE5C77A)),
                            const SizedBox(width: 9),
                            const Expanded(child: Text('Saldo netto dei movimenti registrati', style: TextStyle(color: Colors.white70, fontSize: 11))),
                            Text(_eur(cashNet), style: TextStyle(color: cashNet >= 0 ? const Color(0xFF73C58B) : const Color(0xFFE47A72), fontWeight: FontWeight.w800, fontSize: 16)),
                          ]),
                        ),
                        const SizedBox(height: 8),
                        const Text('Questo saldo è calcolato sui movimenti presenti in cassa. Non viene presentato come liquidità effettiva se manca un saldo iniziale o parte dei movimenti.', style: TextStyle(color: Colors.white54, fontSize: 10, height: 1.35)),
                      ])),

                      _sectionImageHeader('assets/patrimony_sections/04_andamento_patrimoniale.png', 'ANDAMENTO PATRIMONIALE', 'Evoluzione del valore della tua collezione e delle attività commerciali'),
                      _panel(child: _latest == null
                          ? const Row(children: [
                              Icon(Icons.timeline, color: Color(0xFFE5C77A), size: 24),
                              SizedBox(width: 10),
                              Expanded(child: Text('Non è ancora disponibile una rilevazione confrontabile. I valori correnti sono comunque consultabili nelle sezioni sopra.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4))),
                            ])
                          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_date(_latest!['data_riferimento'] ?? _latest!['avviata_il']), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              const SizedBox(height: 7),
                              Text(_latestTotal == null ? 'Valore della rilevazione non disponibile' : _eur(_latestTotal!), style: const TextStyle(color: Color(0xFFF3D990), fontSize: 25, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 7),
                              Row(children: [
                                Icon(delta == null ? Icons.compare_arrows : delta >= 0 ? Icons.trending_up : Icons.trending_down, color: trendColor, size: 20),
                                const SizedBox(width: 7),
                                Expanded(child: Text(delta == null ? 'Confronto precedente non disponibile' : '${delta >= 0 ? 'Aumento' : 'Diminuzione'} di ${_eur(delta.abs())} rispetto agli oggetti confrontabili', style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.w700))),
                              ]),
                              const SizedBox(height: 8),
                              Text('${_latest!['oggetti_valutati'] ?? 0} oggetti valutati nella rilevazione', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            ])),

                      const SizedBox(height: 9),
                      _panel(child: Row(children: [
                        const Expanded(child: Text('Salva una fotografia della componente collezione per confrontarla con la prossima rilevazione.', style: TextStyle(color: Colors.white54, fontSize: 10, height: 1.35))),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _snapshotBusy ? null : _capturePatrimonySnapshot,
                          icon: _snapshotBusy ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt_outlined, size: 15),
                          label: Text(_snapshotBusy ? 'CALCOLO…' : 'REGISTRA', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ])),
                      const SizedBox(height: 19),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFF171716), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF5E4C2D))),
                        child: Row(children: [
                          const Icon(Icons.verified_outlined, color: Color(0xFFE5C77A), size: 17),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            _refreshedAt == null ? 'Dati letti dal database TEST' : 'Ultimo aggiornamento: ${_date(_refreshedAt!.toIso8601String())} alle ${_refreshedAt!.hour.toString().padLeft(2, '0')}:${_refreshedAt!.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          )),
                          TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 15), label: const Text('AGGIORNA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800))),
                        ]),
                      ),
                    ],
                  ),
                ),
    );
  }
}
