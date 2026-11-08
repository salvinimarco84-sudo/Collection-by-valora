part of '../main.dart';

class ActiveSalesReportPage extends StatefulWidget {
  const ActiveSalesReportPage({super.key});

  @override
  State<ActiveSalesReportPage> createState() => _ActiveSalesReportPageState();
}

class _ActiveSalesReportPageState extends State<ActiveSalesReportPage> {
  static const int _pageSize = 50;
  final String _sessionId = _uuid.v4();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final Map<int, String> _imageUrls = {};
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final all = <Map<String, dynamic>>[];
      const batchSize = 100;
      var offset = 0;
      while (true) {
        final response = await _ValoraRuntimeApi.call('report', {
          'session_id': _sessionId,
          'report_code': 'ACTIVE_LISTINGS_REPORT',
          'arguments': {'limite': batchSize, 'offset': offset},
        });
        final envelope = response['result'];
        final data = envelope is Map ? (envelope['risultato'] ?? envelope) : envelope;
        if (data is! Map) throw Exception('Risposta del report vendite attive non valida.');
        final raw = data['record'];
        final rows = raw is List
            ? raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
            : <Map<String, dynamic>>[];
        all.addAll(rows);
        if (rows.length < batchSize) break;
        offset += batchSize;
        if (offset >= 10000) throw Exception('Il report supera il limite di sicurezza di 10.000 record.');
      }

      final platformBySale = <String, String>{};
      try {
        final salesResponse = await _ValoraRuntimeApi.call('open_sales_list', {'session_id': _sessionId});
        final salesResult = salesResponse['result'];
        final sales = salesResult is Map ? salesResult['vendite'] : null;
        if (sales is List) {
          for (final sale in sales.whereType<Map>()) {
            final code = (sale['codice_vendita_aperta'] ?? '').toString();
            final links = sale['piattaforme_associate'];
            final names = links is List
                ? links.whereType<Map>()
                    .map((link) => (link['nome_piattaforma'] ?? '').toString().trim())
                    .where((name) => name.isNotEmpty).toList()
                : <String>[];
            platformBySale[code] = names.isEmpty ? 'Non indicata' : names.join(' · ');
          }
        }
      } catch (_) {
        // Le righe restano consultabili anche se il dettaglio piattaforme non risponde.
      }
      for (final row in all) {
        final code = (row['codice_vendita_aperta'] ?? '').toString();
        row['piattaforme_report'] = platformBySale[code] ?? 'Non indicata';
      }
      if (!mounted) return;
      setState(() { _rows = all; _page = 0; _loading = false; });
      await _loadImages(all);
    } catch (error) {
      if (mounted) setState(() { _loading = false; _error = 'Impossibile caricare le vendite attive: $error'; });
    }
  }

  Future<void> _loadImages(List<Map<String, dynamic>> rows) async {
    final ids = rows.map((row) => int.tryParse((row['codice_oggetto'] ?? row['id_oggetto'] ?? '').toString()))
        .whereType<int>().where((id) => id > 0).toSet();
    await Future.wait(ids.map((id) async {
      var url = '';
      try {
        final metadata = await Supabase.instance.client.schema('collection')
            .from('master_metadati').select('url_immagine').eq('codice_oggetto', id).maybeSingle();
        url = (metadata?['url_immagine'] ?? '').toString().trim();
      } catch (_) {}
      if (!(url.startsWith('https://') || url.startsWith('http://'))) {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          final response = await Supabase.instance.client.functions.invoke(
            'collection-object-images-test',
            headers: session == null ? null : {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'action': 'get', 'codice_oggetto': id},
          );
          if (response.status >= 200 && response.status < 300 && response.data is Map) {
            final data = Map<String, dynamic>.from(response.data as Map);
            url = (data['signed_url'] ?? data['url'] ?? data['image_url'] ?? data['url_immagine'] ?? '').toString().trim();
          }
        } catch (_) {}
      }
      if (url.startsWith('https://') || url.startsWith('http://')) _imageUrls[id] = url;
    }));
    if (mounted && _imageUrls.isNotEmpty) setState(() {});
  }

  String _money(dynamic value) {
    final amount = double.tryParse((value ?? 0).toString()) ?? 0;
    return '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final color = appearance.colorFor('VENDITE');
    final pageCount = (_rows.length / _pageSize).ceil();
    final visible = _rows.skip(_page * _pageSize).take(_pageSize).toList();
    final total = _rows.fold<double>(0, (sum, row) =>
      sum + (double.tryParse((row['prezzo_di_vendita'] ?? row['valore_nominale'] ?? row['importo_vendita'] ?? 0).toString()) ?? 0));
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORT VENDITE ATTIVE'),
        actions: [IconButton(tooltip: 'Aggiorna report', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading && _rows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Text('Consultazione in sola lettura delle vendite ancora aperte. Nessun filtro temporale applicato.',
                style: TextStyle(color: appearance.textSecondary, height: 1.4)),
              const SizedBox(height: 12),
              ReportSummaryPanel(
                sectionColor: color,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('RIEPILOGO VENDITE ATTIVE', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Text('INSERZIONI APERTE: ${_rows.length}')),
                    Text(_money(total), style: TextStyle(color: appearance.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                  Text('Valore nominale complessivo delle inserzioni attive',
                    style: TextStyle(color: appearance.textSecondary, fontSize: 12)),
                ]),
              ),
              if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))),
              if (!_loading && _rows.isEmpty && _error == null)
                const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Nessuna vendita attiva trovata.'))),
              ...visible.map((row) {
                final id = int.tryParse((row['codice_oggetto'] ?? row['id_oggetto'] ?? '').toString());
                final image = id == null ? null : _imageUrls[id];
                return ActiveSaleReportCard(
                  row: row,
                  imageUrl: image,
                  amountLabel: _money(row['prezzo_di_vendita'] ?? row['valore_nominale'] ?? row['importo_vendita']),
                  onTap: id == null ? null : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ObjectRuntimePage(title: 'Scheda oggetto', apiCode: 'OBJECT_MASTER', initialObjectCode: id),
                  )),
                );
              }),
              if (pageCount > 1)
                ReportPaginationControls(
                  currentPage: _page, pageSize: _pageSize, totalItems: _rows.length,
                  pageCount: pageCount, textColor: appearance.textSecondary,
                  onPrevious: _loading || _page == 0 ? null : () => setState(() => _page--),
                  onNext: _loading || _page + 1 >= pageCount ? null : () => setState(() => _page++),
                ),
              if (_loading) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close), label: const Text('CHIUDI E TORNA AL BLOCCO VENDITE'),
              ),
            ]),
    );
  }
}
