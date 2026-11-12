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
    ));
  }
}
