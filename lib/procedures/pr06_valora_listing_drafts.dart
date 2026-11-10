part of '../main.dart';

class _Pr06ValoraListingDraftApi {
  static Future<List<Map<String, dynamic>>> create(int saleCode) async {
    final response = await Supabase.instance.client.functions.invoke(
      'valora-listing-drafts-test',
      body: {'action': 'create', 'codice_vendita_aperta': saleCode},
    );
    final data = response.data;
    if (response.status >= 400 || data is! Map || data['error'] != null) {
      throw Exception(data is Map ? (data['error'] ?? 'Errore generazione bozze') : 'Risposta non valida dal servizio bozze.');
    }
    final rows = data['bozze'];
    if (rows is! List) throw Exception('Il servizio non ha restituito le bozze.');
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<Map<String, dynamic>> update({
    required String id,
    required String title,
    required String description,
    required String category,
    required double price,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'valora-listing-drafts-test',
      body: {
        'action': 'update',
        'id': id,
        'titolo': title,
        'descrizione': description,
        'categoria': category,
        'prezzo': price,
      },
    );
    final data = response.data;
    if (response.status >= 400 || data is! Map || data['error'] != null || data['bozza'] is! Map) {
      throw Exception(data is Map ? (data['error'] ?? 'Bozza non aggiornata') : 'Risposta non valida dal servizio bozze.');
    }
    return Map<String, dynamic>.from(data['bozza'] as Map);
  }

  static Future<List<Map<String, dynamic>>> list() async {
    final response = await Supabase.instance.client.functions.invoke(
      'valora-listing-drafts-test',
      body: {'action': 'list'},
    );
    final data = response.data;
    if (response.status >= 400 || data is! Map || data['error'] != null) {
      throw Exception(data is Map ? (data['error'] ?? 'Impossibile caricare le bozze') : 'Risposta non valida dal servizio bozze.');
    }
    final rows = data['bozze'];
    if (rows is! List) throw Exception('Il servizio non ha restituito l’elenco delle bozze.');
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }
}

class Pr06ValoraListingDraftLibraryPage extends StatefulWidget {
  const Pr06ValoraListingDraftLibraryPage({super.key});

  @override
  State<Pr06ValoraListingDraftLibraryPage> createState() => _Pr06ValoraListingDraftLibraryPageState();
}

class _Pr06ValoraListingDraftLibraryPageState extends State<Pr06ValoraListingDraftLibraryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final drafts = await _Pr06ValoraListingDraftApi.list();
      if (!mounted) return;
      setState(() { _drafts = drafts; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _open(Map<String, dynamic> draft) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Pr06ValoraListingDraftsPage(drafts: [draft]),
    ));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final a = ValoraAppearance.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('ARCHIVIO BOZZE INSERZIONI')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? ListView(padding: const EdgeInsets.all(16), children: [
              Text('Caricamento non riuscito: $_error'),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('RIPROVA')),
            ])
          : _drafts.isEmpty
            ? Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Non ci sono ancora bozze. Verranno create dopo una vendita confermata in PR-06 VALORA.', textAlign: TextAlign.center, style: TextStyle(color: a.textSecondary)),
              ))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _drafts.length,
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    return Card(child: ListTile(
                      leading: Icon(Icons.description_outlined, color: a.colorFor('VENDITE')),
                      title: Text((draft['nome_piattaforma'] ?? 'Marketplace').toString()),
                      subtitle: Text('Oggetto #${draft['codice_oggetto']} · Vendita #${draft['codice_vendita_aperta']}\n${draft['titolo'] ?? ''}\nPrezzo: €${draft['prezzo']} · ${draft['stato']}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => _open(draft),
                    ));
                  },
                ),
              ),
    );
  }
}

class Pr06ValoraListingDraftsPage extends StatefulWidget {
  const Pr06ValoraListingDraftsPage({super.key, required this.drafts});
  final List<Map<String, dynamic>> drafts;

  @override
  State<Pr06ValoraListingDraftsPage> createState() => _Pr06ValoraListingDraftsPageState();
}

class _Pr06ValoraListingDraftsPageState extends State<Pr06ValoraListingDraftsPage> {
  late final List<Map<String, dynamic>> _drafts;
  late final List<TextEditingController> _titles;
  late final List<TextEditingController> _descriptions;
  late final List<TextEditingController> _categories;
  late final List<TextEditingController> _prices;
  final Set<int> _saving = <int>{};

  @override
  void initState() {
    super.initState();
    _drafts = widget.drafts.map((draft) => Map<String, dynamic>.from(draft)).toList();
    _titles = _drafts.map((draft) => TextEditingController(text: (draft['titolo'] ?? '').toString())).toList();
    _descriptions = _drafts.map((draft) => TextEditingController(text: (draft['descrizione'] ?? '').toString())).toList();
    _categories = _drafts.map((draft) => TextEditingController(text: (draft['categoria'] ?? '').toString())).toList();
    _prices = _drafts.map((draft) => TextEditingController(text: (draft['prezzo'] ?? '').toString())).toList();
  }

  @override
  void dispose() {
    for (final controller in [..._titles, ..._descriptions, ..._categories, ..._prices]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save(int index) async {
    final price = double.tryParse(_prices[index].text.trim().replaceAll(',', '.'));
    if (_titles[index].text.trim().isEmpty || _descriptions[index].text.trim().isEmpty || price == null || !price.isFinite || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Controlla titolo, descrizione e prezzo della bozza.')));
      return;
    }
    setState(() => _saving.add(index));
    try {
      final saved = await _Pr06ValoraListingDraftApi.update(
        id: (_drafts[index]['id'] ?? '').toString(),
        title: _titles[index].text.trim(),
        description: _descriptions[index].text.trim(),
        category: _categories[index].text.trim(),
        price: price,
      );
      if (!mounted) return;
      setState(() => _drafts[index] = saved);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bozza ${saved['nome_piattaforma']} salvata.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvataggio bozza non riuscito: $e')));
    } finally {
      if (mounted) setState(() => _saving.remove(index));
    }
  }

  Future<void> _copy(int index) async {
    final price = _prices[index].text.trim();
    final content = '${_titles[index].text.trim()}\n\n${_descriptions[index].text.trim()}\n\nPrezzo: €$price';
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Testo ${_drafts[index]['nome_piattaforma']} copiato.')));
  }

  @override
  Widget build(BuildContext context) {
    final accent = ValoraAppearance.instance.colorFor('VENDITE');
    return Scaffold(
      appBar: AppBar(title: const Text('BOZZE INSERZIONI VALORA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Bozze create esclusivamente per le piattaforme selezionate in PR-06 VALORA. Ogni testo è indipendente e modificabile. Nessuna inserzione viene pubblicata automaticamente.',
              style: TextStyle(color: ValoraAppearance.instance.textSecondary),
            ),
          )),
          const SizedBox(height: 8),
          ...List.generate(_drafts.length, (index) {
            final draft = _drafts[index];
            final warnings = draft['avvisi'] is List ? (draft['avvisi'] as List).map((v) => v.toString()).toList() : <String>[];
            final images = draft['immagini'] is List ? draft['immagini'] as List : const [];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text((draft['nome_piattaforma'] ?? 'Marketplace').toString(),
                      style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 17))),
                    Text((draft['stato'] ?? 'BOZZA').toString(), style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                  ]),
                  const SizedBox(height: 8),
                  Text('Oggetto #${draft['codice_oggetto']} · Vendita #${draft['codice_vendita_aperta']}'),
                  const SizedBox(height: 10),
                  TextField(controller: _titles[index], maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Titolo inserzione')),
                  const SizedBox(height: 10),
                  TextField(controller: _categories[index],
                    decoration: const InputDecoration(labelText: 'Categoria sulla piattaforma')),
                  const SizedBox(height: 10),
                  TextField(controller: _prices[index],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Prezzo (€)', prefixIcon: Icon(Icons.euro))),
                  const SizedBox(height: 10),
                  TextField(controller: _descriptions[index], minLines: 5, maxLines: 12,
                    decoration: const InputDecoration(labelText: 'Descrizione inserzione', alignLabelWithHint: true)),
                  if (images.isNotEmpty) Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${images.length} foto confermate disponibili come riferimenti. Le immagini non vengono caricate sul marketplace.'),
                  ),
                  if (warnings.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('DA VERIFICARE', style: TextStyle(color: Colors.orange.shade300, fontWeight: FontWeight.bold)),
                    ...warnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• $warning', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                    )),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _saving.contains(index) ? null : () => _copy(index),
                      icon: const Icon(Icons.copy_outlined), label: const Text('COPIA TESTO'))),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton.icon(
                      onPressed: _saving.contains(index) ? null : () => _save(index),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving.contains(index) ? 'SALVATAGGIO…' : 'SALVA BOZZA'))),
                  ]),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('FINE'),
          ),
        ],
      ),
    );
  }
}
