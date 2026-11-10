part of '../main.dart';

class Pr12BatchPage extends StatefulWidget {
  const Pr12BatchPage({super.key});
  @override
  State<Pr12BatchPage> createState() => _Pr12BatchPageState();
}
class _Pr12BatchPageState extends State<Pr12BatchPage> {
  bool _loading = false, _running = false;
  List<Map<String, dynamic>> _queue = [];
  final List<Map<String, dynamic>> _results = [];
  final Set<String> _selectedIds = <String>{};
  final Set<String> _processedIds = <String>{};
  int _offset = 0;
  int _queuePage = 0;
  String _status = 'Carica gli oggetti incompleti. Nessun dato verrà salvato.';
  String? _error;

  Future<void> _loadQueue() async {
    if (_loading || _running) return;
    setState(() { _loading = true; _error = null; _status = 'Preparazione coda protetta PR-12…'; _results.clear(); _selectedIds.clear(); _processedIds.clear(); _offset = 0; _queuePage = 0; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Sessione scaduta. Accedi nuovamente.');
      final response = await http.post(Uri.parse('$supabaseUrl/functions/v1/pr-12-engine-test'),
        headers: {'apikey': publishableKey, 'Authorization': 'Bearer ${session.accessToken}', 'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'azione': 'PREPARA_CODA'})).timeout(const Duration(seconds: 25));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || decoded is! Map || decoded['ok'] != true) {
        final message = decoded is Map ? (decoded['error'] ?? 'Risposta non valida').toString() : 'Risposta non valida';
        throw Exception('Preparazione coda HTTP ${response.statusCode}: $message');
      }
      final raw = decoded['oggetti'];
      final rows = raw is List ? raw.whereType<Map>().map((v) => <String, dynamic>{
        'codice_oggetto': v['id'],
        'descrizione_oggetto': v['descrizione'],
        'produttore': v['produttore'],
        'anno_uscita': v['anno_uscita'],
        'codice_prodotto': v['codice_prodotto'],
      }).toList() : <Map<String, dynamic>>[];
      if (mounted) setState(() {
        _queue = rows;
        _status = 'Catalogo letto: ${decoded['totale_catalogo_letto'] ?? 'n/d'} record; ${decoded['totale_incompleti'] ?? rows.length} incompleti. Nessun dato modificato.';
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _status = 'Impossibile preparare la coda PR-12.'; });
    } finally { if (mounted) setState(() => _loading = false); }
  }

  String _category(String d) {
    final s = d.toLowerCase();
    if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(s)) return 'LEGO';
    if (RegExp(r'fumett|comic|manga|panini|salda.?press|isbn').hasMatch(s)) return 'FUMETTI';
    if (RegExp(r'myth cloth|saint seiya|cavalieri dello zodiaco|bandai|action figure|statua').hasMatch(s)) return 'ACTION_FIGURE';
    if (RegExp(r'maisto|die.?cast|modellin|hot wheels|matchbox').hasMatch(s)) return 'DIECAST';
    if (RegExp(r'birra|birre|beer|birrificio|breweriana').hasMatch(s)) return 'BEER';
    if (RegExp(r'vino|vini|bottiglia|bottiglie|barolo|champagne|brunello').hasMatch(s)) return 'WINE';
    return 'COLLEZIONABILE';
  }

  Future<void> _runBatch({List<Map<String, dynamic>>? selectedBatch, Map<String, dynamic>? singleRecord}) async {
    if (_running || _loading) return;
    if (_queue.isEmpty) { setState(() => _error = 'Carica prima la coda degli oggetti incompleti.'); return; }
    if (singleRecord == null && selectedBatch == null && _queue.every((row) => _processedIds.contains((row['codice_oggetto'] ?? '').toString()))) { setState(() => _error = 'Tutti i record sono già stati elaborati.'); return; }
    final batch = singleRecord != null ? <Map<String, dynamic>>[singleRecord] : (selectedBatch ?? _queue.where((row) => !_processedIds.contains((row['codice_oggetto'] ?? '').toString())).skip(_queuePage * 10).take(10).toList());
    if (batch.isEmpty) { setState(() => _error = 'Seleziona almeno un oggetto.'); return; }
    if (batch.length > 10) { setState(() => _error = 'Puoi elaborare al massimo 10 oggetti per volta.'); return; }
    setState(() { _running = true; _error = null; _status = singleRecord != null ? 'Verifica singola dell’oggetto ${singleRecord['codice_oggetto']} in corso. Nessuna scrittura database.' : 'PR-12 sta cercando fonti per ${batch.length} oggetti. Nessuna scrittura database.'; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Sessione scaduta. Accedi nuovamente.');
      final response = await http.post(Uri.parse('$supabaseUrl/functions/v1/pr-12-engine-test'),
        headers: {'apikey': publishableKey, 'Authorization': 'Bearer ${session.accessToken}', 'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'modalita_ia': 'TEST', 'oggetti': batch.map((v) => {
          'id': (v['codice_oggetto'] ?? '').toString(),
          'descrizione': (v['descrizione_oggetto'] ?? '').toString(),
          'categoria': _category((v['descrizione_oggetto'] ?? '').toString()),
          'produttore_attuale': (v['produttore'] ?? '').toString(),
          'anno_uscita_attuale': v['anno_uscita'],
          'codice_prodotto': (v['codice_prodotto'] ?? '').toString(),
        }).toList()})).timeout(const Duration(minutes: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 500).toInt())}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['ok'] != true || decoded['tipo'] != 'coda_completata') {
        final message = decoded is Map ? (decoded['error'] ?? 'Risposta PR-12 non valida').toString() : 'Risposta PR-12 non valida';
        throw Exception(message);
      }
      final rawResults = decoded['risultati_finali'];
      final batchResults = rawResults is List ? rawResults.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList() : <Map<String, dynamic>>[];
      if (mounted) setState(() {
        _results.addAll(batchResults);
        for (final result in batchResults) {
          if (result['ok'] == true) {
            _processedIds.add((result['oggetto_id'] ?? '').toString());
          }
        }
        for (final row in batch) {
          _selectedIds.remove((row['codice_oggetto'] ?? '').toString());
        }
        _offset = _processedIds.length;
        final good = batchResults.where((v) => v['ok'] == true).length;
        _status = 'Ricerca conclusa: $good risultati riusciti, ${batchResults.length - good} errori. Elaborati: $_offset/${_queue.length}. Database invariato.';
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _status = 'Lotto interrotto. Puoi riprovare.'; });
    } finally { if (mounted) setState(() => _running = false); }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _queue.where((row) => !_processedIds.contains((row['codice_oggetto'] ?? '').toString())).length.clamp(0, 10);
    return Scaffold(appBar: AppBar(title: Text(ValoraI18n.tr('PR-12 · RICERCA METADATI'))),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ValoraI18n.tr('RICERCA MULTIPLA IN LOTTI'), style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text(ValoraI18n.tr('PR-12 elabora al massimo 10 oggetti per lotto e mostra fonti, candidati ed errori. Prova in sola lettura: nessun metadato viene scritto o sovrascritto.')), 
        ]))),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _loading || _running ? null : _loadQueue,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
          label: Text(ValoraI18n.tr('CARICA OGGETTI INCOMPLETI'))),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _running || _loading || _queue.every((row) => _processedIds.contains((row['codice_oggetto'] ?? '').toString())) ? null : _runBatch,
          icon: _running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
          label: Text(_running ? ValoraI18n.tr('RICERCA IN CORSO…') : '${ValoraI18n.tr('ELABORA PROSSIMO LOTTO')} ($remaining)')),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ValoraI18n.tr('STATO'), style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(_status),
          if (_queue.isNotEmpty) Text('In coda: ${_queue.length} · elaborati: $_offset · lotti: ${(_queue.length / 10).ceil()}'),
          if (_error != null) SelectableText(_error!, style: const TextStyle(color: Color(0xFFE35D5D))),
        ]))),
        if (_queue.any((row) => !_processedIds.contains((row['codice_oggetto'] ?? '').toString()))) ...[
          Padding(padding: const EdgeInsets.only(top: 12, bottom: 4), child: Text(ValoraI18n.tr('OGGETTI IN CODA · SELEZIONE FACOLTATIVA'), style: TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
          Text(ValoraI18n.tr('Puoi elaborare il lotto automatico oppure selezionare fino a 10 oggetti specifici.'), style: TextStyle(color: Colors.white70)),
          Row(children: [
            Expanded(child: Text('PAGINA ${_queuePage + 1} DI ${((_queue.where((row) => !_processedIds.contains((row['codice_oggetto'] ?? '').toString())).length) / 10).ceil().clamp(1, 9999)}', style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
            Text('${_selectedIds.length}/10 selezionati', style: const TextStyle(color: Colors.white70)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _running || _loading || _queuePage == 0 ? null : () => setState(() { _queuePage--; _selectedIds.clear(); }),
              icon: const Icon(Icons.chevron_left), label: const Text('PRECEDENTE'),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: _running || _loading || (_queuePage + 1) * 10 >= _queue.where((row) => !_processedIds.contains((row['codice_oggetto'] ?? '').toString())).length ? null : () => setState(() { _queuePage++; _selectedIds.clear(); }),
              icon: const Icon(Icons.chevron_right), label: const Text('SUCCESSIVA'),
            )),
          ]),
          const SizedBox(height: 8),
          ..._queue.where((row) => !_processedIds.contains((row['codice_oggetto'] ?? '').toString())).skip(_queuePage * 10).take(10).map((v) {
            final id = (v['codice_oggetto'] ?? '').toString();
            final checked = _selectedIds.contains(id);
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Checkbox(
                  value: checked, activeColor: goldColor, checkColor: Colors.black,
                  onChanged: _running || _loading ? null : (value) => setState(() {
                    if (value == true) {
                      if (_selectedIds.length < 10) { _selectedIds.add(id); _error = null; }
                      else { _error = 'Massimo 10 oggetti selezionabili per ricerca.'; }
                    } else { _selectedIds.remove(id); _error = null; }
                  }),
                ),
                Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((v['descrizione_oggetto'] ?? 'Senza descrizione').toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('ID $id · produttore: ${v['produttore'] ?? 'mancante'} · anno: ${v['anno_uscita'] ?? 'mancante'} · codice: ${v['codice_prodotto'] ?? 'mancante'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ]),
                )),
                IconButton(
                  tooltip: 'Verifica solo questo record',
                  onPressed: _running || _loading ? null : () => _runBatch(singleRecord: v),
                  icon: const Icon(Icons.search, color: goldColor),
                ),
              ]),
            );
          }),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _running || _loading || _queuePage == 0 ? null : () => setState(() { _queuePage--; _selectedIds.clear(); }),
              icon: const Icon(Icons.chevron_left), label: const Text('INDIETRO'),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: _running || _loading || (_queuePage + 1) * 10 >= _queue.where((row) => !_processedIds.contains((row['codice_oggetto'] ?? '').toString())).length ? null : () => setState(() { _queuePage++; _selectedIds.clear(); }),
              icon: const Icon(Icons.chevron_right), label: const Text('AVANTI'),
            )),
          ]),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _running || _loading || _selectedIds.isEmpty ? null : () {
              final chosen = _queue.where((row) => _selectedIds.contains((row['codice_oggetto'] ?? '').toString())).take(10).toList();
              _runBatch(selectedBatch: chosen);
            },
            icon: const Icon(Icons.checklist),
            label: Text('${ValoraI18n.tr('ELABORA SELEZIONATI')} (${_selectedIds.length}/10)'),
          ),
        ],
        if (_results.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.only(top: 16, bottom: 4), child: Text('RISULTATI · SOLA LETTURA', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
          ..._results.map((v) {
            final candidates = v['risultati'] is List ? (v['risultati'] as List).whereType<Map>().toList() : <Map>[];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 42, height: 42,
                      decoration: BoxDecoration(color: goldColor.withOpacity(.14), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.inventory_2_outlined, color: goldColor)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('OGGETTO ${v['oggetto_id'] ?? ''}', style: const TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text((v['descrizione'] ?? 'Oggetto senza descrizione').toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(v['ok'] == true ? '${candidates.length} proposte trovate · nessuna scrittura' : 'Ricerca da verificare: ${v['error'] ?? 'errore non specificato'}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ])),
                  ]),
                  if (candidates.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const Text('PROPOSTE TROVATE', style: TextStyle(color: goldColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: .7)),
                    const SizedBox(height: 8),
                    ...candidates.take(6).map((c) {
                      final rawImage = (c['image_url'] ?? c['immagine_url'] ?? '').toString().trim();
                      final rawUrl = (c['url'] ?? '').toString().trim();
                      final uri = Uri.tryParse(rawUrl);
                      final validUrl = uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
                      final values = <String, String>{
                        'Produttore': (c['produttore'] ?? '').toString(),
                        'Anno': (c['anno_uscita'] ?? '').toString(),
                        'Codice / ISBN': (c['codice_prodotto'] ?? c['isbn'] ?? '').toString(),
                        'Editore': (c['editore'] ?? '').toString(),
                        'Lingua': (c['lingua'] ?? '').toString(),
                      };
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(.18), borderRadius: BorderRadius.circular(12), border: Border.all(color: goldColor.withOpacity(.22))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 88, height: 100,
                              child: rawImage.startsWith('https://') || rawImage.startsWith('http://')
                                ? Image.network(_valoraImageProxyUrl(rawImage), fit: BoxFit.contain, errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 30)))
                                : Container(color: Colors.white10, child: const Icon(Icons.image_search_outlined, color: goldColor, size: 30)))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text((c['title'] ?? 'Candidato senza titolo').toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 5),
                              Text((c['motore'] ?? c['tipologia_candidata'] ?? 'Fonte catalogo').toString().replaceAll('_', ' '), style: const TextStyle(fontSize: 11, color: goldColor)),
                              if ((c['snippet'] ?? '').toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text((c['snippet'] ?? '').toString(), maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                              ],
                              const SizedBox(height: 7),
                              Text(ValoraI18n.tr('Proposta da verificare prima di usarla'), style: TextStyle(fontSize: 11, color: Colors.white54)),
                            ])),
                          ]),
                          ...values.entries.where((e) => e.value.trim().isNotEmpty).map((e) =>
                            Padding(padding: const EdgeInsets.only(top: 4), child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12)))),
                          if (validUrl) Row(children: [
                            Expanded(child: Text(uri!.host, style: const TextStyle(fontSize: 11, color: Colors.white54), overflow: TextOverflow.ellipsis)),
                            TextButton.icon(onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
                              icon: const Icon(Icons.open_in_new, size: 16), label: Text(ValoraI18n.tr('APRI FONTE'))),
                            IconButton(tooltip: ValoraI18n.tr('Esamina proposta'), icon: const Icon(Icons.fact_check_outlined, color: goldColor),
                              onPressed: () {
                                final fields = <String, String>{
                                  'Oggetto': (v['descrizione'] ?? '').toString(),
                                  'Candidato': (c['title'] ?? '').toString(),
                                  'Produttore proposto': (c['produttore'] ?? '').toString(),
                                  'Anno proposto': (c['anno_uscita'] ?? '').toString(),
                                  'Codice prodotto / ISBN': (c['codice_prodotto'] ?? c['isbn'] ?? '').toString(),
                                  'Editore': (c['editore'] ?? '').toString(),
                                  'Lingua': (c['lingua'] ?? '').toString(),
                                  'Fonte': rawUrl,
                                };
                                showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                                  title: Text(ValoraI18n.tr('Scheda proposta · da verificare')),
                                  content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                                    children: fields.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${e.key}: ${e.value.isEmpty ? 'Non disponibile' : e.value}'))).toList())),
                                  actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CHIUDI'))],
                                ));
                              }),
                          ]),
                        ]),
                      );
                    }),
                  ] else if (v['ok'] == true) ...[
                    const SizedBox(height: 10),
                    Text(ValoraI18n.tr('Nessuna scheda verificabile trovata. Prova un altro oggetto o consulta le fonti specialistiche.'), style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                  if (v['diagnostica_ricerca'] is Map)
                    ExpansionTile(tilePadding: EdgeInsets.zero, title: Text(ValoraI18n.tr('Dettagli tecnici'), style: TextStyle(fontSize: 12, color: Colors.white54)),
                      children: [SelectableText(jsonEncode(v['diagnostica_ricerca']), style: const TextStyle(fontSize: 11, color: Colors.white54))]),
                ]),
              ),
            );
          }),
        ],
      ])));
  }
}
