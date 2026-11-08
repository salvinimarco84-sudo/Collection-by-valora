part of '../main.dart';

class Pr09CancelSalesPage extends StatefulWidget {
  const Pr09CancelSalesPage({super.key});

  @override
  State<Pr09CancelSalesPage> createState() => _Pr09CancelSalesPageState();
}

class _Pr09CancelSalesPageState extends State<Pr09CancelSalesPage> {
  static const int _pageSize = 50;
  final String _sessionId = _uuid.v4();
  final TextEditingController _search = TextEditingController();
  bool _loading = false;
  bool _lockHeld = false;
  bool _hasMore = false;
  int _offset = 0;
  List<Map<String, dynamic>> _sales = [];
  final Map<int, Map<String, dynamic>> _saleCache = {};
  final Map<int, bool> _dispositions = {};
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _review;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadCompletedSales(clearSelection: true);
  }

  @override
  void dispose() {
    _search.dispose();
    if (_lockHeld) {
      _ValoraRuntimeApi.call('release_lock', {'session_id': _sessionId})
          .catchError((_) => <String, dynamic>{});
    }
    super.dispose();
  }

  Future<void> _loadCompletedSales({int offset = 0, bool clearSelection = false, bool allowWhileBusy = false}) async {
    if (_loading && !allowWhileBusy) return;
    setState(() {
      _loading = true;
      _error = null;
      if (clearSelection) {
        _dispositions.clear();
        _saleCache.clear();
        _preview = null;
        _review = null;
      }
    });
    try {
      final response = await _ValoraRuntimeApi.call('consultation', {
        'session_id': _sessionId,
        'consultation_code': 'COMPLETED_SALES',
        'arguments': {
          'cerca': _search.text.trim(),
          'limite': _pageSize,
          'offset': offset,
        },
      });
      final outer = response['result'];
      final dynamic data = outer is Map ? outer['risultato'] : outer;
      final rows = data is List
          ? data.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _offset = offset;
        _sales = rows;
        _hasMore = rows.length == _pageSize;
        for (final row in rows) {
          final id = int.tryParse((row['codice_vendita'] ?? '').toString());
          if (id != null) _saleCache[id] = row;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Impossibile caricare le vendite concluse: $e';
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _payload() {
    if (_dispositions.isEmpty) {
      throw Exception('Seleziona almeno una vendita e scegli cosa fare con ciascun oggetto.');
    }
    final operations = _dispositions.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {
      'operazioni': operations.map((entry) => {
        'codice_vendita': entry.key,
        'rimetti_in_vendita': entry.value,
      }).toList(),
    };
  }

  Future<bool> _acquireLock() async {
    final response = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _sessionId});
    final result = response['result'];
    if (result is Map && result['acquisito'] == true) {
      _lockHeld = true;
      return true;
    }
    throw Exception(result is Map
        ? (result['messaggio'] ?? result['stato'] ?? 'Blocco archivio non acquisito.').toString()
        : 'Blocco archivio non acquisito.');
  }

  Future<void> _releaseLock() async {
    if (!_lockHeld) return;
    try {
      final response = await _ValoraRuntimeApi.call('release_lock', {'session_id': _sessionId});
      final result = response['result'];
      if (result is Map && result['rilasciato'] == true) _lockHeld = false;
    } catch (_) {}
  }

  Future<void> _previewSelected() async {
    final payload = _payload();
    if (!_lockHeld && !await _acquireLock()) return;
    late final Map<String, dynamic> result;
    try {
      result = await _ValoraRuntimeApi.procedure(
        'PR-09', 'preview', payload, sessionId: _sessionId,
      );
    } catch (_) {
      await _releaseLock();
      rethrow;
    }
    if (result['scrittura_eseguita'] == true || result['stato'] != 'BOZZA') {
      await _releaseLock();
      throw StateError('Anteprima PR-09 non valida. Nessuna vendita è stata annullata.');
    }
    if (mounted) setState(() {
      _preview = result;
      _review = null;
    });
  }

  Future<void> _confirmSelectedData() async {
    final payload = _payload()
      ..['dati_confermati'] = true
      ..['altra_operazione'] = false
      ..['conferma_finale'] = false;
    final result = await _ValoraRuntimeApi.procedure(
      'PR-09', 'review', payload, sessionId: _sessionId,
    );
    if (result['stato'] != 'IN_ATTESA_CONFERMA_FINALE') {
      throw Exception('La procedura non è arrivata alla conferma finale. Stato: ${result['stato'] ?? 'non disponibile'}.');
    }
    if (mounted) setState(() => _review = result);
  }

  Future<void> _saveSelected() async {
    if (_review == null) throw Exception('Conferma prima il riepilogo degli annullamenti.');
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma definitiva annullamento'),
        content: Text(
          'Stai per annullare ${_dispositions.length} vendite concluse. '
          'Per ogni vendita verrà registrata un’uscita compensativa in cassa. '
          'Le destinazioni degli oggetti seguiranno le opzioni selezionate. Vuoi procedere?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('TORNA INDIETRO'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ANNULLA VENDITE E SALVA'),
          ),
        ],
      ),
    );
    if (accepted != true) return;

    final payload = _payload()
      ..['dati_confermati'] = true
      ..['altra_operazione'] = false
      ..['conferma_finale'] = true;
    final result = await _ValoraRuntimeApi.procedure(
      'PR-09', 'save', payload,
      sessionId: _sessionId,
      requestId: _uuid.v4(),
    );
    if (result['scrittura_eseguita'] != true) {
      throw Exception('Il runtime non ha confermato l’annullamento.');
    }
    if (result['blocco_rilasciato_automaticamente'] == true) {
      _lockHeld = false;
    } else {
      await _releaseLock();
    }
    if (!mounted) return;
    final count = result['numero_operazioni'] ?? _dispositions.length;
    setState(() {
      _success = 'Annullamento salvato e verificato: $count vendite. Cassa e stato degli oggetti aggiornati.';
      _dispositions.clear();
      _saleCache.clear();
      _preview = null;
      _review = null;
    });
    await _loadCompletedSales(clearSelection: true, allowWhileBusy: true);
  }

  Future<void> _cancelDraft() async {
    await _releaseLock();
    if (mounted) setState(() {
      _preview = null;
      _review = null;
    });
  }

  String _money(dynamic value, [dynamic currency]) {
    final amount = double.tryParse((value ?? 0).toString()) ?? 0;
    return '€' + amount.toStringAsFixed(2) + ' ' + (currency ?? 'EUR').toString();
  }

  List<String> _previewLines() {
    final ids = _dispositions.keys.toList()..sort();
    return ids.map((id) {
      final row = _saleCache[id] ?? <String, dynamic>{};
      final relist = _dispositions[id] == true;
      final action = relist ? 'NUOVO CICLO DI VENDITA' : 'RITORNO IN COLLEZIONE';
      return 'Vendita #' + id.toString()
          + ' · Oggetto #' + (row['codice_oggetto'] ?? 'N/D').toString()
          + ' · ' + (row['descrizione_oggetto'] ?? 'Oggetto').toString()
          + ' · ' + _money(row['importo_vendita'], row['valuta'])
          + ' · ' + action;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final sectionColor = appearance.colorFor('VENDITE');
    return Scaffold(
      appBar: AppBar(
        title: const Text('PR-09 · ANNULLA VENDITA'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna vendite concluse',
            onPressed: _loading || _preview != null
                ? null
                : () => _loadCompletedSales(clearSelection: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading && _sales.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                Text(
                  'Seleziona una o più vendite già concluse. Per ogni oggetto scegli la destinazione dopo l’annullamento.',
                  style: TextStyle(color: appearance.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  enabled: !_loading && _preview == null,
                  onSubmitted: (_) => _loadCompletedSales(clearSelection: true),
                  decoration: InputDecoration(
                    labelText: 'Cerca vendita, codice oggetto o descrizione',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Cerca',
                      onPressed: _loading || _preview != null
                          ? null
                          : () => _loadCompletedSales(clearSelection: true),
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vendite concluse: ${_sales.length} · Selezionate: ${_dispositions.length}',
                        style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'Pagina ${(_offset ~/ _pageSize) + 1}',
                      style: TextStyle(color: appearance.textSecondary),
                    ),
                  ],
                ),
                if (_error != null)
                  Card(
                    color: Colors.red.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                if (_success != null)
                  Card(
                    color: Colors.green.withValues(alpha: 0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_success!, style: const TextStyle(color: Colors.green)),
                    ),
                  ),
                if (_sales.isEmpty && !_loading)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('Non ci sono vendite concluse disponibili per l’annullamento.'),
                    ),
                  ),
                ..._sales.map((row) {
                  final id = int.tryParse((row['codice_vendita'] ?? '').toString());
                  if (id == null) return const SizedBox.shrink();
                  return Pr09CompletedSaleCard(
                    row: row,
                    disposition: _dispositions[id],
                    amountLabel: _money(row['importo_vendita'], row['valuta']),
                    enabled: !_loading && _preview == null,
                    onDispositionChanged: (value) => setState(() {
                      if (value == null) {
                        _dispositions.remove(id);
                      } else {
                        _dispositions[id] = value;
                      }
                    }),
                  );
                }),
                if (_sales.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading || _offset == 0 || _preview != null
                              ? null
                              : () => _loadCompletedSales(
                                    offset: (_offset - _pageSize).clamp(0, 1 << 30).toInt(),
                                  ),
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('PRECEDENTI'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loading || !_hasMore || _preview != null
                              ? null
                              : () => _loadCompletedSales(offset: _offset + _pageSize),
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('SUCCESSIVE'),
                        ),
                      ),
                    ],
                  ),
                if (_dispositions.isNotEmpty && _preview == null)
                  FilledButton.icon(
                    onPressed: _loading ? null : () => _run(_previewSelected),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text('CONTROLLA ${_dispositions.length} ANNULLAMENTI'),
                  ),
                if (_preview != null)
                  Pr09CancelSalesPreviewCard(
                    lines: _previewLines(),
                    reviewReady: _review != null,
                    loading: _loading,
                    onConfirmData: () => _run(_confirmSelectedData),
                    onSave: () => _run(_saveSelected),
                    onCancel: () => _run(_cancelDraft),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
