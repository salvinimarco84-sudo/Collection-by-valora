part of '../main.dart';

/// PR06 VALORA: percorso di vendita guidato avviato da una valutazione singola.
/// Usa il contratto runtime PR-06 esistente, senza modificare la procedura ordinaria.
class Pr06ValoraPage extends StatefulWidget {
  const Pr06ValoraPage({
    super.key,
    required this.initialObjectCode,
    this.marketValue,
  });

  final int initialObjectCode;
  final double? marketValue;

  @override
  State<Pr06ValoraPage> createState() => _Pr06ValoraPageState();
}

class _Pr06ValoraPageState extends State<Pr06ValoraPage> {
  final String _session = _uuid.v4();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final Set<int> _selectedPlatforms = <int>{1};
  final List<Map<String, dynamic>> _platforms = [
    {'codice_piattaforma': 1, 'nome_piattaforma': 'Vinted'},
    {'codice_piattaforma': 2, 'nome_piattaforma': '[TEST-CBV] eBay'},
    {'codice_piattaforma': 3, 'nome_piattaforma': '[TEST-CBV] Mercatino'},
    {'codice_piattaforma': 6, 'nome_piattaforma': 'Subito'},
    {'codice_piattaforma': 7, 'nome_piattaforma': 'BrickLink'},
  ];
  Map<String, dynamic>? _object;
  Map<String, dynamic>? _preview;
  bool _loading = true;
  bool _busy = false;
  bool _locked = false;
  bool _confirmed = false;
  String _status = 'Caricamento dell’oggetto confermato da VALORA…';

  @override
  void initState() {
    super.initState();
    final suggested = widget.marketValue;
    if (suggested != null && suggested.isFinite && suggested > 0) {
      _price.text = suggested.toStringAsFixed(2);
    }
    _loadObject();
  }

  @override
  void dispose() {
    _price.dispose();
    _notes.dispose();
    if (_locked) _releaseSilently();
    super.dispose();
  }

  Future<void> _releaseSilently() async {
    try {
      await _ValoraRuntimeApi.call('release_lock', {'session_id': _session});
    } catch (_) {}
    _locked = false;
  }

  Future<void> _loadObject() async {
    setState(() { _loading = true; _status = 'Verifica dell’oggetto nel database TEST…'; });
    try {
      final response = await _ValoraRuntimeApi.call('consultation', {
        'session_id': _session,
        'consultation_code': 'OBJECTS_SELLABLE',
        'arguments': {'limite': 500, 'offset': 0},
      });
      final outer = response['result'];
      final dynamic data = outer is Map ? (outer['risultato'] ?? outer) : outer;
      final rows = data is List
          ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final found = rows.where((row) =>
        int.tryParse((row['codice_oggetto'] ?? '').toString()) == widget.initialObjectCode
      ).firstOrNull;
      if (!mounted) return;
      setState(() {
        _object = found;
        _loading = false;
        _status = found == null
          ? 'L’oggetto non risulta vendibile: deve essere DISPONIBILE e destinato alla RIVENDITA.'
          : 'Oggetto verificato. La vendita non è ancora stata registrata.';
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _status = 'Verifica oggetto non riuscita: $e'; });
    }
  }

  Map<String, dynamic> _operation() => {
    'codice_oggetto': widget.initialObjectCode,
    'prezzo_di_vendita': double.parse(
      double.parse(_price.text.trim().replaceAll(',', '.')).toStringAsFixed(2),
    ),
    'codici_piattaforme': _selectedPlatforms.toList()..sort(),
    'note': _notes.text.trim(),
  };

  Future<bool> _acquire() async {
    final response = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _session});
    final data = response['result'];
    if (data is Map && data['acquisito'] == true) {
      _locked = true;
      return true;
    }
    if (mounted) setState(() => _status =
      (data is Map ? (data['messaggio'] ?? data['stato']) : null)?.toString()
      ?? 'Blocco archivio non acquisito.');
    return false;
  }

  Future<void> _release() async {
    if (!_locked) return;
    try {
      await _ValoraRuntimeApi.call('release_lock', {'session_id': _session});
    } finally {
      _locked = false;
    }
  }

  bool _valid() {
    final amount = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (_object == null) {
      _notice('L’oggetto non è disponibile per la vendita.');
      return false;
    }
    if (amount == null || !amount.isFinite || amount <= 0) {
      _notice('Inserisci un prezzo di vendita maggiore di zero.');
      return false;
    }
    if (_selectedPlatforms.isEmpty) {
      _notice('Seleziona almeno una piattaforma di vendita.');
      return false;
    }
    return true;
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _previewSale() async {
    if (!_valid()) return;
    setState(() { _busy = true; _preview = null; _confirmed = false; _status = 'Controllo preliminare PR06 VALORA. Nessuna scrittura…'; });
    try {
      if (!await _acquire()) return;
      final response = await _ValoraRuntimeApi.procedure(
        'PR-06', 'preview', {
          'operazioni': [_operation()],
          'dati_confermati': false,
          'conferma_finale': false,
          'altra_operazione': false,
        },
        sessionId: _session,
      );
      if (response['scrittura_eseguita'] == true || response['stato'] != 'BOZZA') {
        throw StateError('L’anteprima ha restituito un esito inatteso.');
      }
      if (!mounted) return;
      setState(() {
        _preview = response;
        _status = 'Anteprima pronta. Nessuna vendita è stata ancora registrata.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Anteprima non riuscita: $e. Nessuna vendita salvata.');
    } finally {
      await _release();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveSale() async {
    if (!_valid() || !_confirmed || _preview == null) return;
    setState(() { _busy = true; _status = 'Registrazione e verifica della vendita in TEST…'; });
    try {
      if (!await _acquire()) return;
      final response = await _ValoraRuntimeApi.procedure(
        'PR-06', 'save', {
          'operazioni': [_operation()],
          'dati_confermati': true,
          'conferma_finale': true,
          'altra_operazione': false,
        },
        sessionId: _session,
        requestId: _uuid.v4(),
      );
      final verifiedRows = response['verifica_post_salvataggio'];
      final verified = response['scrittura_eseguita'] == true &&
        response['stato'] == 'SALVATO_E_VERIFICATO' &&
        verifiedRows is List && verifiedRows.length == 1 &&
        verifiedRows.first is Map &&
        (verifiedRows.first['stato_ciclo_vendita'] ?? '').toString() == 'APERTO' &&
        (verifiedRows.first['stato_oggetto'] ?? '').toString() == 'IN VENDITA';
      if (response['blocco_rilasciato_automaticamente'] == true) _locked = false;
      if (!mounted) return;
      setState(() {
        _preview = response;
        _status = verified
          ? 'VENDITA REGISTRATA E VERIFICATA. L’oggetto risulta IN VENDITA.'
          : 'Esito non verificato completamente. Controlla il risultato runtime.';
      });
      if (verified) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Vendita registrata'),
            content: const Text('La vendita è stata salvata e verificata nel database TEST.'),
            actions: [FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('FINE'))],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Vendita non confermata: $e');
    } finally {
      await _release();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = ValoraAppearance.instance.colorFor('VALUTAZIONI');
    return Scaffold(
      appBar: AppBar(title: const Text('PR06 VALORA · VENDITA DA VALUTAZIONE')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(16), children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PERCORSO VALORA', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('Questa procedura riceve l’oggetto già identificato e confermato in VALORA. Il valore di mercato è proposto come prezzo iniziale, ma il prezzo di vendita resta modificabile.'),
              const SizedBox(height: 6),
              const Text('La registrazione cambia lo stato in IN VENDITA solo dopo la conferma finale.'),
            ]),
          )),
          const SizedBox(height: 12),
          if (_object == null)
            Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_status)))
          else ...[
            Card(child: ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: Text((_object!['descrizione_oggetto'] ?? 'Oggetto #${widget.initialObjectCode}').toString()),
              subtitle: Text('Codice oggetto #${widget.initialObjectCode} · Stato: ${_object!['stato'] ?? 'DISPONIBILE'}'),
            )),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Prezzo di vendita (€) *', prefixIcon: Icon(Icons.euro)),
              onChanged: (_) => setState(() { _preview = null; _confirmed = false; }),
            ),
            const SizedBox(height: 8),
            Text('Piattaforme di vendita', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ..._platforms.map((platform) {
              final id = platform['codice_piattaforma'] as int;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selectedPlatforms.contains(id),
                title: Text(platform['nome_piattaforma'].toString()),
                onChanged: _busy ? null : (value) => setState(() {
                  if (value == true) { _selectedPlatforms.add(id); } else { _selectedPlatforms.remove(id); }
                  _preview = null; _confirmed = false;
                }),
              );
            }),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Note (facoltative)'),
              onChanged: (_) => setState(() { _preview = null; _confirmed = false; }),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _previewSale,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('CONTROLLA E MOSTRA RIEPILOGO'),
            ),
            if (_preview != null) ...[
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RIEPILOGO PRIMA DEL SALVATAGGIO', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(const JsonEncoder.withIndent('  ').convert(_preview)),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _confirmed,
                    title: const Text('Confermo oggetto, prezzo e piattaforme.'),
                    onChanged: _busy ? null : (value) => setState(() => _confirmed = value == true),
                  ),
                  FilledButton.icon(
                    onPressed: _busy || !_confirmed ? null : _saveSale,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('CONFERMA E REGISTRA VENDITA'),
                  ),
                ],
              ))),
            ],
          ],
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_status))),
          OutlinedButton.icon(
            onPressed: _busy ? null : _loadObject,
            icon: const Icon(Icons.refresh),
            label: const Text('RICONTROLLA OGGETTO'),
          ),
        ]),
    );
  }
}
