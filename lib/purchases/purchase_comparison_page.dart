import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Confronto storico in sola lettura per produttore e codice prodotto esatti.
class PurchaseComparisonPage extends StatefulWidget {
  const PurchaseComparisonPage({super.key});
  @override
  State<PurchaseComparisonPage> createState() => _PurchaseComparisonPageState();
}

class _PurchaseComparisonPageState extends State<PurchaseComparisonPage> {
  final _search = TextEditingController();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _comparisons = [];

  String _s(dynamic v) => (v ?? '').toString().trim();
  double _n(dynamic v) => double.tryParse(_s(v).replaceAll(',', '.')) ?? 0;
  String _key(String maker, String code) =>
      '${maker.toUpperCase().replaceAll(RegExp(r'\\s+'), ' ').trim()}|${code.toUpperCase().replaceAll(RegExp(r'\\s+'), '').trim()}';

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final db = Supabase.instance.client.schema('collection');
      final allocations = <Map<String, dynamic>>[];
      const pageSize = 500;
      var offset = 0;
      while (true) {
        final response = await db.from('acquisti_oggetti')
            .select('codice_acquisto,codice_oggetto,descrizione_oggetto,valore_acquisto_oggetto,quantita,valuta')
            .order('codice_acquisto').range(offset, offset + pageSize - 1);
        final rows = (response as List).whereType<Map>()
            .map((r) => Map<String, dynamic>.from(r)).toList();
        allocations.addAll(rows);
        if (rows.length < pageSize) break;
        offset += pageSize;
      }
      final objectIds = allocations.map((r) => int.tryParse(_s(r['codice_oggetto'])))
          .whereType<int>().where((id) => id > 0).toSet().toList();
      final objects = <int, Map<String, dynamic>>{};
      for (var i = 0; i < objectIds.length; i += 150) {
        final response = await db.from('master_oggetti')
            .select('codice_oggetto,descrizione_oggetto,produttore,anno_uscita,codice_prodotto,condizione,completezza')
            .inFilter('codice_oggetto', objectIds.skip(i).take(150).toList());
        for (final raw in response as List) {
          if (raw is! Map) continue;
          final row = Map<String, dynamic>.from(raw);
          final id = int.tryParse(_s(row['codice_oggetto']));
          if (id != null) objects[id] = row;
        }
      }
      final purchaseIds = allocations.map((r) => int.tryParse(_s(r['codice_acquisto'])))
          .whereType<int>().toSet().toList();
      final purchases = <int, Map<String, dynamic>>{};
      for (var i = 0; i < purchaseIds.length; i += 150) {
        final response = await db.from('master_acquisti')
            .select('codice_acquisto,data_acquisto')
            .inFilter('codice_acquisto', purchaseIds.skip(i).take(150).toList());
        for (final raw in response as List) {
          if (raw is! Map) continue;
          final row = Map<String, dynamic>.from(raw);
          final id = int.tryParse(_s(row['codice_acquisto']));
          if (id != null) purchases[id] = row;
        }
      }
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final allocation in allocations) {
        final objectId = int.tryParse(_s(allocation['codice_oggetto']));
        final object = objectId == null ? null : objects[objectId];
        final maker = _s(object?['produttore']);
        final code = _s(object?['codice_prodotto']);
        if (maker.isEmpty || code.isEmpty) continue;
        final purchaseId = int.tryParse(_s(allocation['codice_acquisto']));
        final purchase = purchaseId == null ? null : purchases[purchaseId];
        final qty = int.tryParse(_s(allocation['quantita'])) ?? 1;
        if (qty < 1) continue;
        final amount = _n(allocation['valore_acquisto_oggetto']);
        final entry = <String, dynamic>{
          'codice_acquisto': purchaseId, 'codice_oggetto': objectId,
          'descrizione': _s(object?['descrizione_oggetto']).isNotEmpty
              ? _s(object?['descrizione_oggetto']) : _s(allocation['descrizione_oggetto']),
          'data': _s(purchase?['data_acquisto']), 'quantita': qty,
          'prezzo_unitario': amount / qty, 'valuta': _s(allocation['valuta']).isEmpty ? 'EUR' : _s(allocation['valuta']),
          'condizione': _s(object?['condizione']), 'completezza': _s(object?['completezza']),
          'produttore': maker, 'codice_prodotto': code,
        };
        grouped.putIfAbsent(_key(maker, code), () => []).add(entry);
      }
      final result = <Map<String, dynamic>>[];
      for (final entries in grouped.values) {
        if (entries.length < 2) continue;
        if (entries.map((e) => _s(e['valuta'])).toSet().length != 1) continue;
        entries.sort((a, b) => _n(a['prezzo_unitario']).compareTo(_n(b['prezzo_unitario'])));
        final prices = entries.map((e) => _n(e['prezzo_unitario'])).toList();
        result.add({
          'produttore': entries.first['produttore'], 'codice_prodotto': entries.first['codice_prodotto'],
          'descrizione': entries.first['descrizione'], 'valuta': entries.first['valuta'],
          'numero_acquisti': entries.length, 'minimo': prices.first, 'massimo': prices.last,
          'medio': prices.reduce((a, b) => a + b) / prices.length,
          'differenza': prices.last - prices.first, 'righe': entries,
        });
      }
      result.sort((a, b) => _n(b['differenza']).compareTo(_n(a['differenza'])));
      if (mounted) setState(() { _comparisons = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Impossibile caricare gli acquisti comparati: $e'; _loading = false; });
    }
  }

  String _money(dynamic v, String currency) => '${_n(v).toStringAsFixed(2).replaceAll('.', ',')} $currency';

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final rows = _comparisons.where((r) =>
      q.isEmpty || '${r['produttore']} ${r['codice_prodotto']} ${r['descrizione']}'.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('ACQUISTI COMPARATI'), actions: [
        IconButton(tooltip: 'Aggiorna', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
      ]),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(
          controller: _search, onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Cerca produttore, codice o prodotto', border: OutlineInputBorder()),
        )),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Confronto esatto per produttore e codice prodotto. Consultazione senza modifiche.'),
        )),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
        Expanded(child: rows.isEmpty
          ? Center(child: Text(_loading ? 'Caricamento acquisti…' : 'Nessun prodotto con almeno due acquisti confrontabili.'))
          : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24), itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              final currency = _s(item['valuta']);
              final details = (item['righe'] as List).cast<Map<String, dynamic>>();
              return Card(margin: const EdgeInsets.only(bottom: 12), child: ExpansionTile(
                leading: const Icon(Icons.compare_arrows),
                title: Text(_s(item['descrizione']), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${item['produttore']} · Codice ${item['codice_prodotto']} · ${item['numero_acquisti']} acquisti'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                children: [
                  Row(children: [
                    Expanded(child: _metric('MINIMO', _money(item['minimo'], currency))),
                    Expanded(child: _metric('MEDIO', _money(item['medio'], currency))),
                    Expanded(child: _metric('MASSIMO', _money(item['massimo'], currency))),
                  ]),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: Text(
                    'Differenza massimo/minimo: ${_money(item['differenza'], currency)}',
                    style: const TextStyle(fontWeight: FontWeight.w600))),
                  const Divider(height: 20),
                  ...details.map((d) => ListTile(
                    dense: true, contentPadding: EdgeInsets.zero,
                    title: Text('Acquisto #${d['codice_acquisto']} · ${d['data']}'),
                    subtitle: Text('Oggetto #${d['codice_oggetto']} · Q.tà ${d['quantita']}'
                      '${_s(d['condizione']).isEmpty ? '' : ' · ${d['condizione']}'}'
                      '${_s(d['completezza']).isEmpty ? '' : ' · ${d['completezza']}'}'),
                    trailing: Text(_money(d['prezzo_unitario'], currency), style: const TextStyle(fontWeight: FontWeight.w600)),
                  )),
                ],
              ));
            },
          )),
      ])),
    );
  }

  Widget _metric(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3), Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    ],
  );
}
