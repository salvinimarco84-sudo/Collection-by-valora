part of '../main.dart';

class WantedActiveDesiresPage extends StatefulWidget {
  const WantedActiveDesiresPage({super.key});

  @override
  State<WantedActiveDesiresPage> createState() => _WantedActiveDesiresPageState();
}

class _WantedActiveDesiresPageState extends State<WantedActiveDesiresPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Sessione non valida. Accedi nuovamente.');
      final response = await Supabase.instance.client
          .schema('collection')
          .from('wanted_desideri')
          .select('id, descrizione, categoria, condizione_desiderata, completezza_desiderata, note, data_creazione')
          .eq('user_id', user.id)
          .eq('stato', 'ATTIVO')
          .order('data_creazione', ascending: false);
      final rows = (response as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _dateLabel(dynamic value) {
    final date = DateTime.tryParse((value ?? '').toString())?.toLocal();
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _detail(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text('$label: $value', style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Future<void> _searchAndImportImage(Map<String, dynamic> row) async {
    final desireId = (row['id'] ?? '').toString();
    final description = (row['descrizione'] ?? '').toString().trim();
    final category = (row['categoria'] ?? '').toString().trim();
    if (desireId.isEmpty || description.isEmpty) return;
    try {
      setState(() => _loading = true);
      final response = await Supabase.instance.client.functions.invoke(
        'pr-12-web-search-test',
        body: {
          'descrizione': description,
          'categoria': category,
          'tema': description,
          'mercato': 'Italia',
        },
      );
      if (response.status < 200 || response.status >= 300 || response.data is! Map) {
        throw StateError('Risposta PR-12 non valida (HTTP ${response.status}).');
      }
      final payload = Map<String, dynamic>.from(response.data as Map);
      if (payload['ok'] != true) {
        throw StateError((payload['error'] ?? 'Ricerca PR-12 non riuscita').toString());
      }
      final candidates = (payload['risultati'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => (e['image_url'] ?? '').toString().startsWith('https://'))
          .toList();
      if (!mounted) return;
      if (candidates.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessuna immagine diretta trovata. Nessuna modifica effettuata.')),
        );
        return;
      }
      int selected = 0;
      final choice = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('CANDIDATI IMMAGINE PR-12'),
            content: SizedBox(
              width: 520,
              child: ListView(shrinkWrap: true, children: [
                Text(description, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (int i = 0; i < candidates.length; i++)
                  RadioListTile<int>(
                    value: i,
                    groupValue: selected,
                    onChanged: (v) => setDialogState(() => selected = v ?? 0),
                    title: Text((candidates[i]['title'] ?? 'Immagine candidata').toString()),
                    subtitle: Text((candidates[i]['motore'] ?? candidates[i]['url'] ?? '').toString(),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    secondary: SizedBox(width: 64, height: 64,
                      child: Image.network(candidates[i]['image_url'].toString(),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined))),
                  ),
                const Text('Verifica che immagine, modello e variante coincidano esattamente.'),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ANNULLA')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, candidates[selected]),
                child: const Text('SELEZIONA')),
            ],
          ),
        ),
      );
      if (choice == null || !mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('CONFERMA CORRISPONDENZA'),
          content: Text('Confermi che questa immagine rappresenta esattamente:\\n\\n$description\\n\\nSarà salvata nell’archivio immagini condiviso TEST.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('INDIETRO')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('SÌ, IMPORTA')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final imported = await Supabase.instance.client.functions.invoke(
        'collection-shared-image-import-test',
        body: {
          'target_type': 'wanted',
          'wanted_id': desireId,
          'image_url': choice['image_url'],
          'match_confirmed': true,
        },
      );
      final data = imported.data;
      if (imported.status < 200 || imported.status >= 300 || data is! Map || data['ok'] != true) {
        throw StateError(data is Map
          ? (data['error'] ?? 'Importazione immagine non riuscita').toString()
          : 'Risposta non valida dal servizio immagini condiviso.');
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Immagine importata nell’archivio condiviso.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ricerca/importazione immagine non riuscita: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
      if (mounted) await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    const silver = Color(0xFFB8BEC6);
    return Scaffold(
      appBar: AppBar(
        title: const Text('LISTA DEI DESIDERI'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna elenco',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 38),
                          const SizedBox(height: 10),
                          Text('Impossibile caricare i desideri.\n$_error', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('RIPROVA')),
                        ],
                      ),
                    ),
                  )
                : _rows.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bookmark_border, size: 52, color: silver),
                              const SizedBox(height: 12),
                              Text('Nessun desiderio attivo', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 6),
                              const Text('Quando aggiungerai un oggetto con NUOVO DESIDERIO, lo troverai qui.', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final row = _rows[index];
                            final category = (row['categoria'] ?? '').toString();
                            final description = (row['descrizione'] ?? '').toString();
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.bookmark, color: silver),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(description, style: Theme.of(context).textTheme.titleMedium)),
                                      ],
                                    ),
                                    if (category.trim().isNotEmpty)
                                      _detail('Categoria / tema', category),
                                    _detail('Condizione', row['condizione_desiderata']?.toString()),
                                    _detail('Completezza', row['completezza_desiderata']?.toString()),
                                    _detail('Note', row['note']?.toString()),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        onPressed: _loading ? null : () => _searchAndImportImage(row),
                                        icon: const Icon(Icons.image_search),
                                        label: const Text('CERCA / IMPORTA IMMAGINE'),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text('Inserito il ${_dateLabel(row['data_creazione'])}', style: Theme.of(context).textTheme.labelSmall),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
