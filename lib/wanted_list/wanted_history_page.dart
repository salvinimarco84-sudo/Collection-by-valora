part of '../main.dart';

class WantedHistoryPage extends StatefulWidget {
  const WantedHistoryPage({super.key});
  @override
  State<WantedHistoryPage> createState() => _WantedHistoryPageState();
}

class _WantedHistoryPageState extends State<WantedHistoryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final Map<String, List<Map<String, dynamic>>> _offers = {};
  final Set<String> _expanded = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Sessione utente non valida.');
      final response = await Supabase.instance.client.schema('collection')
          .from('wanted_desideri')
          .select('id,descrizione,categoria,condizione_desiderata,completezza_desiderata,note,stato,codice_oggetto_acquistato,data_creazione,data_aggiornamento,data_chiusura')
          .eq('user_id', user.id)
          .neq('stato', 'ATTIVO')
          .order('data_chiusura', ascending: false, nullsFirst: false)
          .order('data_creazione', ascending: false);
      final rows = (response as List).whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadOffers(String id) async {
    if (_offers.containsKey(id)) return;
    try {
      final response = await Supabase.instance.client.schema('collection')
          .from('wanted_offerte')
          .select('id,titolo,prezzo,valuta,condizione,piattaforma,url_annuncio,stato,data_ricerca')
          .eq('desiderio_id', id)
          .order('data_ricerca', ascending: false);
      if (mounted) setState(() {
        _offers[id] = (response as List).whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile caricare le offerte: $e')));
    }
  }

  String _date(dynamic value) {
    if (value == null) return 'Data non disponibile';
    final parsed = DateTime.tryParse(value.toString())?.toLocal();
    if (parsed == null) return value.toString();
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  Color _statusColor(String status) =>
      status == 'ACQUISTATO' ? Colors.green : Colors.grey;

  @override
  Widget build(BuildContext context) {
    const silver = Color(0xFFB8BEC6);
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: const Color(0xFFB8BEC6),
          secondary: const Color(0xFFB8BEC6),
        ),
      ),
      child: Scaffold(
      appBar: AppBar(title: const Text('STORICO WANTED LIST')),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
            : _rows.isEmpty
              ? const Center(child: Text('Non ci sono ancora desideri conclusi.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('DESIDERI CONCLUSI · ${_rows.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: silver)),
                      const SizedBox(height: 10),
                      for (final row in _rows) _historyCard(row),
                    ],
                  ),
                ),
      ),
    ));
  }

  Widget _historyCard(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final status = (row['stato'] ?? '').toString();
    final objectCode = row['codice_oggetto_acquistato'];
    final expanded = _expanded.contains(id);
    final offers = _offers[id];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text((row['descrizione'] ?? 'Desiderio').toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Chip(label: Text(status), side: BorderSide.none,
              backgroundColor: _statusColor(status).withValues(alpha: .14)),
          ]),
          if ((row['categoria'] ?? '').toString().isNotEmpty)
            Text('Categoria: ${row['categoria']}'),
          if ((row['condizione_desiderata'] ?? '').toString().isNotEmpty)
            Text('Condizione richiesta: ${row['condizione_desiderata']}'),
          if ((row['completezza_desiderata'] ?? '').toString().isNotEmpty)
            Text('Completezza: ${row['completezza_desiderata']}'),
          const SizedBox(height: 6),
          Text('Inserito: ${_date(row['data_creazione'])}'),
          Text('Concluso: ${_date(row['data_chiusura'])}'),
          if (objectCode != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text('Oggetto catalogo collegato: #$objectCode',
                style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
          ],
          if ((row['note'] ?? '').toString().trim().isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 6),
              child: Text('Note: ${row['note']}')),
          const Divider(),
          TextButton.icon(
            onPressed: () async {
              setState(() {
                if (expanded) { _expanded.remove(id); } else { _expanded.add(id); }
              });
              if (!expanded) await _loadOffers(id);
            },
            icon: Icon(expanded ? Icons.expand_less : Icons.local_offer_outlined),
            label: Text(expanded ? 'NASCONDI OFFERTE' : 'OFFERTE SALVATE'),
          ),
          if (expanded)
            if (offers == null)
              const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator()))
            else if (offers.isEmpty)
              const Padding(padding: EdgeInsets.all(8), child: Text('Nessuna offerta salvata per questo desiderio.'))
            else
              for (final offer in offers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text((offer['titolo'] ?? '').toString()),
                  subtitle: Text([
                    if (offer['prezzo'] != null) '${offer['prezzo']} ${offer['valuta'] ?? 'EUR'}',
                    (offer['piattaforma'] ?? '').toString(),
                    'Stato: ${offer['stato'] ?? 'DA_VALUTARE'}',
                  ].where((s) => s.trim().isNotEmpty).join(' · ')),
                  trailing: IconButton(
                    tooltip: 'Apri annuncio',
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      final url = (offer['url_annuncio'] ?? '').toString();
                      if (url.startsWith('https://') || url.startsWith('http://')) {
                        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ),
        ]),
      ),
    );
  }
}
