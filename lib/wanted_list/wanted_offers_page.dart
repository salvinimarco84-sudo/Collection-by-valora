part of '../main.dart';

class WantedOffersPage extends StatefulWidget {
  const WantedOffersPage({super.key});
  @override
  State<WantedOffersPage> createState() => _WantedOffersPageState();
}

class _WantedOffersPageState extends State<WantedOffersPage> {
  bool _loading = true;
  bool _searching = false;
  String? _error;
  List<Map<String, dynamic>> _desires = [];
  String? _selectedId;
  final _market = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  final Set<String> _savedUrls = {};

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _market.dispose(); super.dispose(); }

  Future<void> _load() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Sessione utente non valida.');
      final rows = await Supabase.instance.client.schema('collection')
          .from('wanted_desideri')
          .select('id,descrizione,categoria,condizione_desiderata,completezza_desiderata')
          .eq('user_id', user.id).eq('stato', 'ATTIVO')
          .order('data_creazione', ascending: false);
      if (!mounted) return;
      setState(() {
        _desires = (rows as List).whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)).toList();
        _selectedId = _desires.isEmpty ? null : _desires.first['id'].toString();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Map<String, dynamic>? get _selected {
    for (final row in _desires) {
      if (row['id'].toString() == _selectedId) return row;
    }
    return null;
  }

  Future<void> _search() async {
    final desire = _selected;
    if (desire == null) return;
    if (_market.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica il mercato geografico da interrogare.')));
      return;
    }
    setState(() { _searching = true; _results = []; _error = null; _savedUrls.clear(); });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'pr-12-web-search-test',
        body: {
          'descrizione': desire['descrizione'],
          'categoria': desire['categoria'] ?? '',
          'tema': desire['descrizione'],
          'mercato': _market.text.trim(),
        },
      );
      if (response.status < 200 || response.status >= 300 || response.data is! Map) {
        throw StateError('PR-12 non ha restituito una risposta valida (HTTP ${response.status}).');
      }
      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] == false) throw StateError((payload['error'] ?? 'Ricerca non riuscita').toString());
      final rows = (payload['risultati'] as List? ?? const [])
          .whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() { _results = rows; _searching = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _searching = false; });
    }
  }

  String _domain(String url) {
    try { return Uri.parse(url).host.replaceFirst('www.', ''); }
    catch (_) { return ''; }
  }

  Future<void> _save(Map<String, dynamic> candidate) async {
    final user = Supabase.instance.client.auth.currentUser;
    final desire = _selected;
    final url = (candidate['url'] ?? '').toString().trim();
    final title = (candidate['title'] ?? '').toString().trim();
    if (user == null || desire == null || !url.startsWith('http') || title.isEmpty) return;
    try {
      final rawPrice = (candidate['price'] ?? candidate['prezzo'] ?? '').toString();
      final priceMatch = RegExp(r'(\d+[,.]?\d*)').firstMatch(rawPrice);
      final price = priceMatch == null ? null : double.tryParse(priceMatch.group(1)!.replaceAll(',', '.'));
      await Supabase.instance.client.schema('collection').from('wanted_offerte').insert({
        'user_id': user.id,
        'desiderio_id': desire['id'],
        'titolo': title,
        'prezzo': price,
        'condizione': candidate['condition']?.toString(),
        'piattaforma': _domain(url),
        'url_annuncio': url,
        'fonte': candidate['motore']?.toString(),
        'snippet': candidate['snippet']?.toString(),
      });
      if (mounted) setState(() => _savedUrls.add(url));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offerta salvata nella WANTED LIST.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Salvataggio offerta non riuscito: $e')));
    }
  }

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
      appBar: AppBar(title: const Text('RICERCA OFFERTE')),
      body: SafeArea(
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _desires.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center)))
            : _desires.isEmpty
              ? const Center(child: Text('Non ci sono desideri attivi da cercare.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('1 · SELEZIONA IL DESIDERIO', style: TextStyle(fontWeight: FontWeight.bold, color: silver)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Oggetto desiderato'),
                      items: _desires.map((d) => DropdownMenuItem(
                        value: d['id'].toString(),
                        child: Text(d['descrizione'].toString(), overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) => setState(() { _selectedId = v; _results = []; }),
                    ),
                    const SizedBox(height: 14),
                    const Text('2 · MERCATO DA INTERROGARE', style: TextStyle(fontWeight: FontWeight.bold, color: silver)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _market,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Paese / mercato', hintText: 'Es. Italia, Francia, Europa'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _searching ? null : _search,
                      icon: _searching ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                      label: Text(_searching ? 'RICERCA IN CORSO…' : 'CERCA OFFERTE CON PR-12'),
                    ),
                    if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    if (_results.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('RISULTATI TROVATI: ${_results.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: silver)),
                      const SizedBox(height: 8),
                      for (final candidate in _results)
                        Card(
                          child: ListTile(
                            title: Text((candidate['title'] ?? 'Risultato senza titolo').toString()),
                            subtitle: Text([
                              _domain((candidate['url'] ?? '').toString()),
                              (candidate['snippet'] ?? '').toString(),
                            ].where((s) => s.trim().isNotEmpty).join('\n')),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: _savedUrls.contains((candidate['url'] ?? '').toString()) ? 'Già salvata' : 'Salva offerta',
                              onPressed: _savedUrls.contains((candidate['url'] ?? '').toString()) ? null : () => _save(candidate),
                              icon: Icon(_savedUrls.contains((candidate['url'] ?? '').toString()) ? Icons.bookmark_added : Icons.bookmark_add_outlined),
                            ),
                            onTap: () {
                              final url = (candidate['url'] ?? '').toString();
                              if (url.startsWith('https://') || url.startsWith('http://')) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            },
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    const Text('I risultati sono candidati da verificare. Salvarli non registra un acquisto e non modifica il catalogo.'),
                  ],
                ),
      ),
    ));
  }
}
