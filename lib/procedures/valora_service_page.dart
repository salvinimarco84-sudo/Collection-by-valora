part of '../main.dart';

class ValoraServicePage extends StatefulWidget {
  const ValoraServicePage({super.key});
  @override
  State<ValoraServicePage> createState() => _ValoraServicePageState();
}

class _ValoraServicePageState extends State<ValoraServicePage> {
  bool _loading = true;
  bool _preparing = false;
  String? _error;
  List<Map<String, dynamic>> _objects = [];
  int? _selectedId;
  String _market = 'ITALIA';
  Map<String, dynamic>? _prepared;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  Future<void> _loadObjects() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Supabase.instance.client.schema('collection')
          .from('master_oggetti')
          .select('codice_oggetto,descrizione_oggetto,produttore,codice_prodotto,stato,condizione,completezza')
          .eq('destinazione', 'COLLEZIONE')
          .neq('archiviato_test', true)
          .order('descrizione_oggetto')
          .limit(500);
      final rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map))
          .where((r) => !['VENDUTO','PERSO','DISTRUTTO','USCITO','ACCORPATO']
              .contains((r['stato'] ?? '').toString().toUpperCase())).toList();
      if (!mounted) return;
      setState(() { _objects = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossibile caricare gli oggetti della collezione: $e'; _loading = false; });
    }
  }

  Future<void> _prepareValuation() async {
    final id = _selectedId;
    if (id == null) {
      setState(() => _error = 'Seleziona prima un oggetto.');
      return;
    }
    setState(() { _preparing = true; _error = null; _prepared = null; });
    try {
      final response = await _ValoraRuntimeApi.call('consultation', {
        'session_id': null,
        'consultation_code': 'MARKET_VALUATION_PREPARE',
        'arguments': {'codice_oggetto': id, 'mercato_riferimento': _market},
      });
      if (!mounted) return;
      final result = response['result'];
      setState(() {
        _prepared = result is Map ? Map<String, dynamic>.from(result) : {'risultato': result};
        _preparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Preparazione non riuscita: $e'; _preparing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _objects.where((o) => o['codice_oggetto'] == _selectedId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(ValoraI18n.tr('VALORA'))),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(18), children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF8556C7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8556C7)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8556C7), size: 38),
              SizedBox(height: 12),
              Text(ValoraI18n.tr('SERVIZIO VALORA'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8556C7))),
              SizedBox(height: 8),
              Text(ValoraI18n.tr('Seleziona un oggetto della collezione e prepara una richiesta di valutazione specialistica. La preparazione non equivale ancora a una stima di mercato conclusa.')), 
            ]),
          ),
          const SizedBox(height: 18),
          Text(ValoraI18n.tr('1. SELEZIONA L’OGGETTO'), style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedId,
            isExpanded: true,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: ValoraI18n.tr('Oggetto da valutare')),
            items: _objects.map((o) => DropdownMenuItem<int>(
              value: (o['codice_oggetto'] as num).toInt(),
              child: Text('#${o['codice_oggetto']} · ${o['descrizione_oggetto'] ?? 'Senza descrizione'}', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (value) => setState(() { _selectedId = value; _prepared = null; }),
          ),
          if (_objects.isEmpty) Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(ValoraI18n.tr('Non risultano oggetti disponibili nella destinazione COLLEZIONE.')), 
          ),
          if (selected != null) Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(selected['descrizione_oggetto']?.toString() ?? 'Oggetto selezionato', style: const TextStyle(fontWeight: FontWeight.bold)),
              if ((selected['produttore'] ?? '').toString().isNotEmpty) Text('Produttore: ${selected['produttore']}'),
              if ((selected['codice_prodotto'] ?? '').toString().isNotEmpty) Text('Codice prodotto: ${selected['codice_prodotto']}'),
              Text('Condizione: ${selected['condizione'] ?? 'Non indicata'}'),
              Text('Completezza: ${selected['completezza'] ?? 'Non indicata'}'),
            ]),
          )),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _market,
            decoration: InputDecoration(border: const OutlineInputBorder(), labelText: ValoraI18n.tr('Mercato di riferimento')), 
            items: [
              DropdownMenuItem(value: 'ITALIA', child: Text(ValoraI18n.tr('Italia'))),
              DropdownMenuItem(value: 'EUROPA', child: Text(ValoraI18n.tr('Europa'))),
              DropdownMenuItem(value: 'MONDO', child: Text(ValoraI18n.tr('Mondo'))),
            ],
            onChanged: (value) => setState(() { _market = value ?? 'ITALIA'; _prepared = null; }),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _preparing || _selectedId == null ? null : _prepareValuation,
            icon: _preparing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
            label: Text(_preparing ? ValoraI18n.tr('Preparazione in corso…') : ValoraI18n.tr('PREPARA VALUTAZIONE')),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
          if (_prepared != null) Card(
            margin: const EdgeInsets.only(top: 16),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ValoraI18n.tr('ESITO PREPARAZIONE'), style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(ValoraI18n.tr('La richiesta è stata inviata al runtime. Questo esito non rappresenta ancora una valutazione di mercato definitiva né genera automaticamente inserzioni.')), 
                const SizedBox(height: 8),
                SelectableText(_prepared.toString()),
              ],
            )),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _loadObjects, icon: const Icon(Icons.refresh), label: Text(ValoraI18n.tr('AGGIORNA OGGETTI'))),
        ]),
    );
  }
}
