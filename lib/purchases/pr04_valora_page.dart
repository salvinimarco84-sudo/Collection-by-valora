part of '../main.dart';

/// Procedura autonoma di acquisto per oggetti identificati da VALORA.
class Pr04ValoraPage extends StatefulWidget {
  const Pr04ValoraPage({
    super.key,
    required this.initialMetadata,
    required this.market,
    this.suggestedMarketValue,
    this.valuation,
  });
  final Map<String, dynamic> initialMetadata;
  final String market;
  final double? suggestedMarketValue;
  final Map<String, dynamic>? valuation;
  @override
  State<Pr04ValoraPage> createState() => _Pr04ValoraPageState();
}

class _Pr04ValoraPageState extends State<Pr04ValoraPage> {
  final _description = TextEditingController();
  final _producer = TextEditingController();
  final _productCode = TextEditingController();
  final _year = TextEditingController();
  final _source = TextEditingController();
  final _image = TextEditingController();
  final _purchaseRef = TextEditingController();
  final _cost = TextEditingController();
  final _notes = TextEditingController();
  final String _requestId = _uuid.v4();

  DateTime _date = DateTime.now();
  String? _condition;
  String? _completeness;
  String? _destination;
  bool _dateConfirmed = false;
  String? _category;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;
  bool _busy = false;
  bool _reviewed = false;
  bool _purchaseSaved = false;
  bool _saveAttempted = false;
  bool _valuationSaved = false;
  bool _valuationSaving = false;
  int? _objectId;
  int? _purchaseId;
  String? _status;
  String? _valuationError;

  static const _conditions = [
    'NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO',
    'USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO',
  ];
  static const _completenessValues = ['SIGILLATO','COMPLETO','INCOMPLETO'];

  @override
  void initState() {
    super.initState();
    final m = widget.initialMetadata;
    _description.text = (m['descrizione'] ?? '').toString();
    _producer.text = (m['produttore'] ?? '').toString();
    _productCode.text = (m['codice_prodotto'] ?? '').toString();
    _year.text = (m['anno_uscita'] ?? '').toString();
    _source.text = (m['fonte_dati_prodotto'] ?? '').toString();
    _image.text = (m['url_immagine_catalogo'] ?? '').toString();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await Supabase.instance.client.schema('collection')
          .from('master_categorie_collezione')
          .select('codice_categoria,descrizione')
          .eq('visibile', true).order('ordine_menu').order('descrizione');
      if (!mounted) return;
      setState(() {
        _categories = (rows as List).whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)).toList();
        _loadingCategories = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loadingCategories = false;
        _status = 'Caricamento categorie non riuscito: ' + e.toString();
      });
    }
  }

  double? get _amount {
    var raw = _cost.text.trim().replaceAll('€', '').replaceAll(' ', '');
    if (raw.contains(',')) raw = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(raw);
  }

  void _invalidate() {
    if (_reviewed) setState(() => _reviewed = false);
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  bool _validate() {
    if (!_dateConfirmed) {
      _message('Conferma la data di acquisto selezionandola nel calendario.'); return false;
    }
    if (_destination == null || _condition == null || _completeness == null) {
      _message('Seleziona destinazione, condizione e completezza.'); return false;
    }
    if (_description.text.trim().length < 2) {
      _message('Inserisci una descrizione valida.'); return false;
    }
    final amount = _amount;
    if (amount == null || amount <= 0) {
      _message('Inserisci il costo effettivo pagato. La stima di mercato non è il costo di acquisto.');
      return false;
    }
    if (_destination == 'COLLEZIONE' &&
        (_category == null || !_categories.any((e) => e['codice_categoria'] == _category))) {
      _message('Seleziona la categoria principale della collezione.'); return false;
    }
    if (_year.text.trim().isNotEmpty) {
      final y = int.tryParse(_year.text.trim());
      if (y == null || y < 1000 || y > 9999) {
        _message('Anno di uscita non valido.'); return false;
      }
    }
    final hasProductMetadata = _producer.text.trim().isNotEmpty ||
        _year.text.trim().isNotEmpty || _productCode.text.trim().isNotEmpty;
    if (hasProductMetadata && _source.text.trim().isEmpty) {
      _message('I metadati identificativi richiedono la fonte effettiva. Inserisci il link della fonte oppure rimuovi i metadati non verificabili.');
      return false;
    }
    for (final raw in [_source.text.trim(), _image.text.trim()]) {
      if (raw.isNotEmpty && !(raw.startsWith('https://') || raw.startsWith('http://'))) {
        _message('Gli URL devono iniziare con http:// o https://.'); return false;
      }
    }
    return true;
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null && mounted) setState(() { _date = value; _dateConfirmed = true; _reviewed = false; });
  }

  Map<String, dynamic> _payload() {
    final amount = _amount!;
    final year = int.tryParse(_year.text.trim());
    return {
      'conferma_finale': true,
      'data_acquisto': _date.toIso8601String().substring(0, 10),
      'importo_totale': double.parse(amount.toStringAsFixed(2)),
      'valuta': 'EUR',
      if (_purchaseRef.text.trim().isNotEmpty) 'descrizione': _purchaseRef.text.trim(),
      'oggetto': {
        'descrizione': _description.text.trim(),
        'valore_acquisto': double.parse(amount.toStringAsFixed(2)),
        'condizione': _condition!,
        'completezza': _completeness!,
        'destinazione': _destination!,
        'quantita': 1,
        if (_notes.text.trim().isNotEmpty) 'note': _notes.text.trim(),
        if (_destination == 'COLLEZIONE' && _category != null)
          'codice_categoria_collezione': _category,
        if (_producer.text.trim().isNotEmpty) 'produttore': _producer.text.trim(),
        if (year != null) 'anno_uscita': year,
        if (_productCode.text.trim().isNotEmpty) 'codice_prodotto': _productCode.text.trim(),
        if (_source.text.trim().isNotEmpty) 'fonte_dati_prodotto': _source.text.trim(),
        if (_producer.text.trim().isNotEmpty || year != null || _productCode.text.trim().isNotEmpty || _source.text.trim().isNotEmpty)
          'stato_verifica_dati': 'DA_VERIFICARE',
        if (_image.text.trim().isNotEmpty) 'url_immagine_catalogo': _image.text.trim(),
      },
    };
  }

  Future<void> _savePurchase() async {
    if (_busy || _purchaseSaved || !_reviewed || !_validate()) return;
    final confirm = await showDialog<bool>(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma PR-04 VALORA'),
        content: Text(
          'Verranno creati un nuovo oggetto e il relativo acquisto nel database TEST.\n\n'
          'Costo effettivo: € ' + _amount!.toStringAsFixed(2) + '\n'
          'Valore di mercato indicativo: ' +
          (widget.suggestedMarketValue == null ? 'non disponibile' : '€ ' + widget.suggestedMarketValue!.toStringAsFixed(2)) +
          '\n\nIl valore di mercato non verrà usato come costo. Confermi?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFERMA E REGISTRA')),
        ],
      ),
    );
    if (confirm != true || !mounted || _busy || _purchaseSaved) return;
    setState(() { _busy = true; _saveAttempted = true; _status = 'Registrazione PR-04 VALORA in TEST…'; });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'pr-04-valora-test',
        body: {
          'action': 'save', 'request_id': _requestId,
          'conferma_finale': true, 'payload': _payload(),
        },
      );
      final data = response.data;
      if (data is! Map || data['ok'] != true || data['result'] is! Map) {
        throw StateError(data is Map
            ? (data['error'] ?? 'Risposta PR-04 VALORA non valida.').toString()
            : 'Risposta PR-04 VALORA non valida.');
      }
      final result = Map<String, dynamic>.from(data['result'] as Map);
      if (result['stato'] != 'SALVATO_E_VERIFICATO' ||
          result['oggetto_nuovo_creato'] != true ||
          result['quadratura_verificata'] != true) {
        throw StateError('Il database non ha certificato tutte le verifiche richieste.');
      }
      final objectId = int.tryParse((result['codice_oggetto'] ?? '').toString());
      final purchaseId = int.tryParse((result['codice_acquisto'] ?? '').toString());
      if (objectId == null || purchaseId == null) {
        throw StateError('Codici oggetto/acquisto mancanti nella risposta verificata.');
      }
      if (!mounted) return;
      setState(() {
        _purchaseSaved = true; _objectId = objectId; _purchaseId = purchaseId;
        _status = 'Acquisto #' + purchaseId.toString() + ' e nuovo oggetto #' +
            objectId.toString() + ' salvati e verificati. Salvataggio PR18 in corso…';
      });
      await _saveValuation();
    } catch (e) {
      if (mounted) setState(() => _status =
          'Salvataggio non certificato: ' + e.toString() +
          '. In caso di risposta interrotta, la stessa richiesta può essere ripetuta senza duplicare i record.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveValuation() async {
    final objectId = _objectId;
    final valuation = widget.valuation;
    if (objectId == null || valuation == null || _valuationSaved || _valuationSaving) return;
    setState(() => _valuationSaving = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'pr-18-valuation-test',
        body: {
          'azione': 'SALVA_VALUTAZIONE',
          'codice_oggetto': objectId,
          'metadati': {
            'descrizione': _description.text.trim(),
            'produttore': _producer.text.trim(),
            'codice_prodotto': _productCode.text.trim(),
          },
          'mercato_riferimento': widget.market,
          'valutazione': valuation,
        },
      );
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw StateError(data is Map
            ? (data['error'] ?? 'Salvataggio valutazione PR18 non riuscito.').toString()
            : 'Risposta PR18 non valida.');
      }
      if (!mounted) return;
      setState(() {
        _valuationSaved = true;
        _status = data['valore_master_aggiornato'] == true
            ? 'Acquisto e oggetto verificati. Valutazione PR18 salvata e valore di mercato aggiornato.'
            : 'Acquisto e oggetto verificati. Storico PR18 salvato; nessun prezzo verificabile, valore mercato invariato.';
      });
    } catch (e) {
      if (mounted) setState(() {
        _valuationError = 'Acquisto e oggetto sono già salvati. Salvataggio PR18 non riuscito: ' + e.toString();
        _status = _valuationError;
      });
    } finally {
      if (mounted) setState(() => _valuationSaving = false);
    }
  }

  @override
  void dispose() {
    _description.dispose(); _producer.dispose(); _productCode.dispose();
    _year.dispose(); _source.dispose(); _image.dispose(); _purchaseRef.dispose();
    _cost.dispose(); _notes.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = ValoraAppearance.instance.colorFor('ACQUISTI');
    final value = widget.suggestedMarketValue;
    final valuation = widget.valuation;
    final rangeMin = valuation?['fascia_minima'];
    final rangeMax = valuation?['fascia_massima'];
    final reliability = (valuation?['affidabilita'] ?? 'NON DISPONIBILE').toString();
    final selectedCategory = _categories.where((e) => e['codice_categoria'] == _category)
        .map((e) => (e['descrizione'] ?? '').toString()).firstOrNull ?? 'Non selezionata';

    return Scaffold(
      appBar: AppBar(title: const Text('PR-04 VALORA · NUOVO ACQUISTO')),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(
            padding: EdgeInsets.all(12),
            child: Text('PROCEDURA AUTONOMA · AMBIENTE TEST\nCrea un nuovo oggetto distinto, registra l’acquisto e verifica il collegamento contabile. Nessuna scrittura prima della conferma finale.'),
          )),
          if (value != null || valuation != null) Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VALUTAZIONE PR18 · ' + widget.market, style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              Text(value == null ? 'Valore di mercato non disponibile.' : 'Valore indicativo: € ' + value.toStringAsFixed(2)),
              if (rangeMin != null || rangeMax != null) Text('Fascia: € ' + (rangeMin ?? 'n.d.').toString() + ' - € ' + (rangeMax ?? 'n.d.').toString()),
              Text('Affidabilità: ' + reliability),
              const Text('Stima informativa: non viene mai copiata nel costo di acquisto.'),
            ]),
          )),
          Text('DATI OGGETTO', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _description, enabled: !_purchaseSaved && !_saveAttempted, decoration: const InputDecoration(labelText: 'Descrizione oggetto *'), onChanged: (_) => _invalidate()),
          const SizedBox(height: 8),
          TextField(controller: _producer, enabled: !_purchaseSaved && !_saveAttempted, decoration: const InputDecoration(labelText: 'Produttore'), onChanged: (_) => _invalidate()),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _productCode, enabled: !_purchaseSaved && !_saveAttempted, decoration: const InputDecoration(labelText: 'Codice prodotto'), onChanged: (_) => _invalidate())),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _year, enabled: !_purchaseSaved && !_saveAttempted, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Anno uscita'), onChanged: (_) => _invalidate())),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _source, enabled: !_purchaseSaved && !_saveAttempted, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Fonte metadati'), onChanged: (_) => _invalidate()),
          const SizedBox(height: 8),
          TextField(controller: _image, enabled: !_purchaseSaved && !_saveAttempted, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'URL immagine catalogo'), onChanged: (_) => _invalidate()),
          const SizedBox(height: 14),
          Text('DATI ACQUISTO', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          OutlinedButton.icon(
            onPressed: _purchaseSaved || _saveAttempted || _busy ? null : _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: Text('Data acquisto: ' + _date.day.toString().padLeft(2, '0') + '/' +
                _date.month.toString().padLeft(2, '0') + '/' + _date.year.toString()),
          ),
          TextField(
            controller: _cost, enabled: !_purchaseSaved && !_saveAttempted,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Costo effettivo di acquisto (€) *',
              helperText: 'Campo volutamente vuoto. Inserisci quanto hai realmente pagato.',
            ),
            onChanged: (_) => _invalidate(),
          ),
          const SizedBox(height: 8),
          TextField(controller: _purchaseRef, enabled: !_purchaseSaved && !_saveAttempted, decoration: const InputDecoration(labelText: 'Negozio / provenienza (facoltativo)'), onChanged: (_) => _invalidate()),
          const SizedBox(height: 14),
          Text('CLASSIFICAZIONE', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _destination,
            decoration: const InputDecoration(labelText: 'Destinazione'),
            items: const [
              DropdownMenuItem(value: 'COLLEZIONE', child: Text('COLLEZIONE')),
              DropdownMenuItem(value: 'RIVENDITA', child: Text('RIVENDITA')),
              DropdownMenuItem(value: 'ALTRO', child: Text('ALTRO')),
            ],
            onChanged: _purchaseSaved || _saveAttempted ? null : (v) => setState(() {
              _destination = v;
              if (_destination != 'COLLEZIONE') _category = null;
              _reviewed = false;
            }),
          ),
          if (_destination == 'COLLEZIONE') DropdownButtonFormField<String>(
            value: _categories.any((e) => e['codice_categoria'] == _category) ? _category : null,
            decoration: InputDecoration(
              labelText: 'Categoria principale *',
              helperText: _loadingCategories ? 'Caricamento categorie…' : 'Categoria dell’oggetto identificato.',
            ),
            items: _categories.map((e) => DropdownMenuItem<String>(
              value: e['codice_categoria'].toString(),
              child: Text((e['descrizione'] ?? e['codice_categoria']).toString()),
            )).toList(),
            onChanged: _purchaseSaved || _saveAttempted || _loadingCategories ? null : (v) => setState(() {
              _category = v; _reviewed = false;
            }),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(
              value: _condition,
              decoration: const InputDecoration(labelText: 'Condizione'),
              items: _conditions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: _purchaseSaved || _saveAttempted ? null : (v) => setState(() { _condition = v; _reviewed = false; }),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<String>(
              value: _completeness,
              decoration: const InputDecoration(labelText: 'Completezza'),
              items: _completenessValues.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: _purchaseSaved || _saveAttempted ? null : (v) => setState(() { _completeness = v; _reviewed = false; }),
            )),
          ]),
          const SizedBox(height: 8),
          TextField(controller: _notes, enabled: !_purchaseSaved && !_saveAttempted, minLines: 2, maxLines: 3, decoration: const InputDecoration(labelText: 'Note e difetti (facoltativi)'), onChanged: (_) => _invalidate()),
          const SizedBox(height: 14),
          if (!_purchaseSaved && !_saveAttempted) OutlinedButton.icon(
            onPressed: _busy ? null : () {
              if (_validate()) setState(() => _reviewed = true);
            },
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('CONTROLLA E MOSTRA RIEPILOGO'),
          ),
          if (_reviewed && !_purchaseSaved) Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RIEPILOGO DA CONFERMARE', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              Text('Oggetto: ' + _description.text.trim()),
              Text('Data: ' + _date.toIso8601String().substring(0, 10)),
              Text('Costo effettivo: € ' + _amount!.toStringAsFixed(2)),
              Text('Destinazione: ' + _destination!),
              if (_destination == 'COLLEZIONE') Text('Categoria: ' + selectedCategory),
              Text('Condizione: ' + _condition! + ' · Completezza: ' + _completeness!),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _savePurchase,
                icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: Text(_saveAttempted ? 'RIPROVA LA STESSA REGISTRAZIONE' : 'CONFERMA E REGISTRA ACQUISTO'),
              ),
            ]),
          )),
          if (_purchaseSaved) Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ACQUISTO REGISTRATO', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              Text('Codice acquisto: #' + (_purchaseId?.toString() ?? 'n.d.')),
              Text('Nuovo codice oggetto: #' + (_objectId?.toString() ?? 'n.d.')),
              Text(_valuationSaved ? 'Valutazione PR18 salvata.' :
                  widget.valuation == null ? 'Valutazione PR18 non disponibile: nessun valore inventato.' :
                  'Valutazione PR18 da completare.'),
              if (_valuationError != null) Text(_valuationError!, style: const TextStyle(color: Colors.orangeAccent)),
              if (_valuationError != null)
                const Text('La valutazione non è stata ripetuta automaticamente per evitare duplicati nello storico. Potrai rilanciare VALORA sull’oggetto appena creato.'),
              FilledButton(onPressed: _busy ? null : () => Navigator.of(context).pop(true), child: const Text('FINE')),
            ]),
          )),
          if (_status != null) Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_status!))),
        ]),
      )),
      ),
    );
  }
}
