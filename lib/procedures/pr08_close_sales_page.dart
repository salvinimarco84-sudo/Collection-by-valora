part of '../main.dart';

class Pr08CloseSalesPage extends StatefulWidget {
  const Pr08CloseSalesPage({super.key});
  @override State<Pr08CloseSalesPage> createState() => _Pr08CloseSalesPageState();
}

class _Pr08CloseSalesPageState extends State<Pr08CloseSalesPage> {
  final String _sessionId = _uuid.v4();
  final ScrollController _pageScroll = ScrollController();
  bool _loading = false, _lockHeld = false;
  List<Map<String, dynamic>> _sales = [], _platforms = [];
  final Set<int> _selected = <int>{};
  final Map<int, String> _outcomes = {}, _dates = {}, _amounts = {}, _platformCodes = {};
  Map<String, dynamic>? _preview, _review;
  String? _error, _success;

  @override void initState() { super.initState(); _loadOpenSales(); }
  @override void dispose() {
    _pageScroll.dispose();
    if (_lockHeld) { _ValoraRuntimeApi.call('release_lock', {'session_id': _sessionId}).catchError((_) => <String, dynamic>{}); }
    super.dispose();
  }

  String _today() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
  String _dateString(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadOpenSales() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await _ValoraRuntimeApi.call('open_sales_list', {'session_id': _sessionId});
      final result = response['result'];
      if (result is! Map) throw Exception('Risposta elenco vendite aperte non valida.');
      final rows = result['vendite'], platforms = result['piattaforme'];
      if (!mounted) return;
      setState(() {
        _sales = rows is List ? rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
        _platforms = platforms is List ? platforms.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
        _selected.removeWhere((id) => !_sales.any((r) => int.tryParse('${r['codice_vendita_aperta']}') == id));
        _preview = null; _review = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Impossibile caricare le vendite aperte: $e');
    } finally { if (mounted) setState(() => _loading = false); }
  }

  Map<String, dynamic> _salePayload() {
    if (_selected.isEmpty) throw Exception('Seleziona almeno una vendita aperta.');
    final operations = <Map<String, dynamic>>[];
    for (final row in _sales) {
      final id = int.tryParse('${row['codice_vendita_aperta']}');
      if (id == null || !_selected.contains(id)) continue;
      final outcome = _outcomes[id];
      if (outcome == null || outcome.isEmpty) throw Exception('Seleziona l’esito per la vendita #$id.');
      final item = <String, dynamic>{'codice_vendita_aperta': id, 'esito': outcome};
      if (outcome == 'VENDITA EFFETTIVA') {
        final date = (_dates[id] ?? '').trim();
        final amount = double.tryParse((_amounts[id] ?? '').trim().replaceAll(',', '.'));
        final platformCode = int.tryParse(_platformCodes[id] ?? '');
        if (date.isEmpty || DateTime.tryParse(date) == null) throw Exception('Inserisci una data valida per la vendita #$id.');
        if (amount == null || amount <= 0) throw Exception('Inserisci un importo effettivo maggiore di zero per la vendita #$id.');
        if (platformCode == null) throw Exception('Seleziona la piattaforma effettiva per la vendita #$id.');
        item['data_vendita'] = date; item['importo_vendita'] = amount; item['codice_piattaforma'] = platformCode;
      }
      operations.add(item);
    }
    if (operations.isEmpty) throw Exception('Nessuna vendita selezionata valida.');
    return {'operazioni': operations};
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try { await action(); }
    catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _previewSelected() async {
    final payload = _salePayload();
    if (!_lockHeld) {
      final lock = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _sessionId});
      final result = lock['result'];
      if (result is! Map || result['acquisito'] != true) throw Exception(result is Map ? (result['messaggio'] ?? 'Archivio bloccato da un’altra operazione.') : 'Blocco esclusivo non acquisito.');
      _lockHeld = true;
    }
    try {
      final result = await _ValoraRuntimeApi.procedure('PR-08', 'preview', payload, sessionId: _sessionId);
      if (mounted) setState(() { _preview = result; _review = null; });
    } catch (_) { await _releaseLock(); rethrow; }
  }

  Future<void> _confirmSelectedData() async {
    final payload = _salePayload()
      ..['dati_confermati'] = true ..['altra_operazione'] = false ..['conferma_finale'] = false;
    final result = await _ValoraRuntimeApi.procedure('PR-08', 'review', payload, sessionId: _sessionId);
    if (result['stato'] != 'IN_ATTESA_CONFERMA_FINALE') {
      throw Exception('La procedura non è arrivata alla conferma finale. Stato ricevuto: ${result['stato'] ?? 'non disponibile'}');
    }
    if (!mounted) return;
    setState(() => _review = result);
    // Porta subito in vista il passaggio successivo: la conferma non deve
    // sembrare inattiva perché il pulsante finale è più in basso nella lista.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pageScroll.hasClients) {
        _pageScroll.animateTo(
          _pageScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveSelected() async {
    if (_review == null) throw Exception('Conferma prima il riepilogo delle chiusure.');
    final accepted = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma definitiva delle chiusure'),
        content: Text('Stai per chiudere ${_selected.length} vendite. Quelle non selezionate resteranno APERTE. Vuoi procedere?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('CONFERMA E SALVA')),
        ],
      ),
    );
    if (accepted != true) return;
    final payload = _salePayload()
      ..['dati_confermati'] = true ..['altra_operazione'] = false ..['conferma_finale'] = true;
    final result = await _ValoraRuntimeApi.procedure('PR-08', 'save', payload, sessionId: _sessionId, requestId: _uuid.v4());
    if (result['scrittura_eseguita'] != true) throw Exception('Il runtime non ha confermato la scrittura.');
    if (result['blocco_rilasciato_automaticamente'] == true) { _lockHeld = false; } else { await _releaseLock(); }
    if (!mounted) return;
    setState(() {
      _success = 'Chiusura salvata e verificata: ${result['numero_operazioni'] ?? _selected.length} vendite.';
      _selected.clear(); _outcomes.clear(); _dates.clear(); _amounts.clear(); _platformCodes.clear();
      _preview = null; _review = null;
    });
    await _loadOpenSales();
  }

  Future<void> _releaseLock() async {
    if (!_lockHeld) return;
    try {
      final response = await _ValoraRuntimeApi.call('release_lock', {'session_id': _sessionId});
      final result = response['result'];
      if (result is Map && result['rilasciato'] == true) _lockHeld = false;
    } catch (_) {}
  }

  Future<void> _pickDate(int id) async {
    final initial = DateTime.tryParse(_dates[id] ?? '') ?? DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(2000), lastDate: DateTime(2100),
      helpText: 'Data effettiva della vendita', cancelText: 'ANNULLA', confirmText: 'CONFERMA');
    if (picked != null && mounted) setState(() { _dates[id] = _dateString(picked); _preview = null; _review = null; });
  }

  String _money(dynamic value, [dynamic currency]) => '${(double.tryParse('${value ?? 0}') ?? 0).toStringAsFixed(2)} ${currency ?? 'EUR'}';

  Widget _saleCard(Map<String, dynamic> row) {
    final id = int.tryParse('${row['codice_vendita_aperta']}');
    if (id == null) return const SizedBox.shrink();
    final selected = _selected.contains(id);
    final linked = row['piattaforme_associate'] is List
      ? (row['piattaforme_associate'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : <Map<String, dynamic>>[];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CheckboxListTile(
            value: selected, controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero,
            title: Text('Vendita aperta #$id', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Oggetto #${row['codice_oggetto'] ?? 'n/d'} · ${row['descrizione_oggetto'] ?? 'Senza descrizione'}'),
            onChanged: _loading ? null : (value) => setState(() {
              if (value == true) { _selected.add(id); _dates.putIfAbsent(id, _today); _amounts.putIfAbsent(id, () => '${row['prezzo_di_vendita'] ?? ''}'); }
              else { _selected.remove(id); _outcomes.remove(id); }
              _preview = null; _review = null;
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 42, bottom: 4),
            child: Wrap(spacing: 12, runSpacing: 4, children: [
              Text('In vendita dal ${row['data_inizio_vendita'] ?? 'n/d'}'),
              Text('Prezzo richiesto: ${_money(row['prezzo_di_vendita'], row['valuta'])}'),
              if (linked.isNotEmpty) Text('Piattaforme: ${linked.map((e) => e['nome_piattaforma']).join(', ')}'),
              if (row['codice_lotto'] != null) const Text('Parte di un lotto'),
            ]),
          ),
          if (selected) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 42, right: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                DropdownButtonFormField<String>(
                  value: _outcomes[id],
                  decoration: const InputDecoration(labelText: 'Esito della chiusura *'),
                  items: const [
                    DropdownMenuItem(value: 'VENDITA EFFETTIVA', child: Text('Vendita effettiva')),
                    DropdownMenuItem(value: 'CHIUSURA SENZA VENDITA', child: Text('Chiusura senza vendita')),
                  ],
                  onChanged: _loading ? null : (v) => setState(() { _outcomes[id] = v ?? ''; _preview = null; _review = null; }),
                ),
                if (_outcomes[id] == 'VENDITA EFFETTIVA') ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('date-$id-${_dates[id]}'), initialValue: _dates[id] ?? _today(), readOnly: true,
                    decoration: InputDecoration(labelText: 'Data vendita *', suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _loading ? null : () => _pickDate(id))),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: ValueKey('amount-$id-${_amounts[id]}'), initialValue: _amounts[id] ?? '${row['prezzo_di_vendita'] ?? ''}',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Importo effettivo *', suffixText: 'EUR'),
                    onChanged: (v) => setState(() { _amounts[id] = v; _preview = null; _review = null; }),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _platformCodes[id], decoration: const InputDecoration(labelText: 'Piattaforma effettiva *'),
                    items: _platforms.map((p) => DropdownMenuItem<String>(value: '${p['codice_piattaforma']}', child: Text('${p['nome_piattaforma']}'))).toList(),
                    onChanged: _loading ? null : (v) => setState(() { _platformCodes[id] = v ?? ''; _preview = null; _review = null; }),
                  ),
                ],
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('PR-08 · CHIUDI VENDITA'), actions: [
        IconButton(tooltip: 'Aggiorna elenco', onPressed: _loading ? null : _loadOpenSales, icon: const Icon(Icons.refresh)),
      ]),
      body: _loading && _sales.isEmpty ? const Center(child: CircularProgressIndicator()) : ListView(
        controller: _pageScroll,
        padding: const EdgeInsets.all(14),
        children: [
          Pr08SalesSummaryCard(
            totalSales: _sales.length,
            selectedSales: _selected.length,
            headerColor: appearance.colorFor('VENDITE'),
            secondaryTextColor: appearance.textSecondary,
            onSelectAll: _loading || _sales.isEmpty ? null : () => setState(() {
              _selected.addAll(_sales.map((r) => int.tryParse('${r['codice_vendita_aperta']}')).whereType<int>());
              for (final r in _sales) { final id = int.tryParse('${r['codice_vendita_aperta']}'); if (id != null) { _dates.putIfAbsent(id, _today); _amounts.putIfAbsent(id, () => '${r['prezzo_di_vendita'] ?? ''}'); } }
              _preview = null; _review = null;
            }),
            onDeselectAll: _loading ? null : () => setState(() { _selected.clear(); _preview = null; _review = null; }),
          ),
          if (_error != null) Card(color: Colors.red.withValues(alpha: 0.12), child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))),
          if (_success != null) Card(color: Colors.green.withValues(alpha: 0.12), child: Padding(padding: const EdgeInsets.all(12), child: Text(_success!, style: const TextStyle(color: Colors.greenAccent)))),
          if (_sales.isEmpty && !_loading) const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Non ci sono vendite attualmente aperte.'))),
          ..._sales.map(_saleCard),
          if (_selected.isNotEmpty) ...[
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: _loading ? null : () => _run(_previewSelected), icon: const Icon(Icons.fact_check_outlined),
              label: Text(_loading ? 'CONTROLLO IN CORSO…' : 'CONTROLLA ${_selected.length} CHIUSURE')),
          ],
          if (_preview != null && _review == null) Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RIEPILOGO DELLE CHIUSURE', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${_selected.length} vendite selezionate. Controlla esito, importo e piattaforma prima di proseguire.',
                style: TextStyle(color: appearance.textSecondary)),
              const SizedBox(height: 8),
              ..._selected.map((id) {
                final row = _sales.firstWhere((r) => int.tryParse('${r['codice_vendita_aperta']}') == id);
                final outcome = _outcomes[id] ?? 'Esito non indicato';
                final details = outcome == 'VENDITA EFFETTIVA'
                    ? ' · ${_money(_amounts[id], 'EUR')} · ${_dates[id] ?? _today()}'
                    : '';
                final matchingPlatforms = _platforms.where((p) => '${p['codice_piattaforma']}' == (_platformCodes[id] ?? ''))
                    .map((p) => '${p['nome_piattaforma']}').toList();
                final platform = matchingPlatforms.isEmpty ? null : matchingPlatforms.first;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('Vendita #$id · Oggetto #${row['codice_oggetto']} · $outcome$details${platform == null ? '' : ' · $platform'}'),
                );
              }),
              const SizedBox(height: 10),
              FilledButton(onPressed: _loading ? null : () => _run(_confirmSelectedData),
                child: const Text('CONFERMO I DATI')),
            ]),
          )),
          if (_review != null) Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.verified_outlined, color: Colors.green),
                SizedBox(width: 8),
                Expanded(child: Text('DATI CONFERMATI', style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 8),
              Text('Hai confermato ${_selected.length} chiusure. Nessuna vendita è stata ancora modificata. Premi il pulsante qui sotto per eseguire il salvataggio definitivo.',
                style: TextStyle(color: appearance.textSecondary)),
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: _loading ? null : () => _run(_saveSelected), icon: const Icon(Icons.save_outlined), label: const Text('CONFERMA DEFINITIVA E SALVA')),
              TextButton(onPressed: _loading ? null : () => _run(() async { await _releaseLock(); if (mounted) setState(() { _preview = null; _review = null; }); }), child: const Text('ANNULLA E LASCIA APERTE LE VENDITE')),
            ]),
          )),
          if (_loading) const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
