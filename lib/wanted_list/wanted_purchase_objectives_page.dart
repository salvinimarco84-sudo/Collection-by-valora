part of '../main.dart';

class WantedPurchaseObjectivesPage extends StatefulWidget {
  const WantedPurchaseObjectivesPage({super.key});

  @override
  State<WantedPurchaseObjectivesPage> createState() => _WantedPurchaseObjectivesPageState();
}

class _WantedPurchaseObjectivesPageState extends State<WantedPurchaseObjectivesPage> {
  static const _silver = Color(0xFFB8BEC6);
  static const _priorities = ['ALTA', 'MEDIA', 'BASSA'];
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
      final response = await Supabase.instance.client.schema('collection')
          .from('wanted_obiettivi')
          .select('id, titolo, categoria_tema, priorita, note, data_creazione')
          .eq('user_id', user.id)
          .order('data_creazione', ascending: false);
      final rows = (response as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      rows.sort((a, b) {
        final rank = {'ALTA': 0, 'MEDIA': 1, 'BASSA': 2};
        final byPriority = (rank[a['priorita']] ?? 1).compareTo(rank[b['priorita']] ?? 1);
        if (byPriority != 0) return byPriority;
        return (b['data_creazione'] ?? '').toString().compareTo((a['data_creazione'] ?? '').toString());
      });
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _editGoal({Map<String, dynamic>? existing}) async {
    final title = TextEditingController(text: (existing?['titolo'] ?? '').toString());
    final category = TextEditingController(text: (existing?['categoria_tema'] ?? '').toString());
    final notes = TextEditingController(text: (existing?['note'] ?? '').toString());
    var priority = (existing?['priorita'] ?? 'MEDIA').toString();
    final formKey = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(existing == null ? 'NUOVO OBIETTIVO' : 'MODIFICA OBIETTIVO'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: title,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Obiettivo di acquisto *', hintText: 'Es. Completare la serie LEGO Space'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Inserisci il nome dell’obiettivo.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: category,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Tema / categoria *', hintText: 'LEGO, Gundam, Fumetti, Modellini...'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Indica il tema o la categoria.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(labelText: 'Priorità'),
                      items: _priorities.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                      onChanged: (value) { if (value != null) refresh(() => priority = value); },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notes,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Note', hintText: 'Dettagli utili per ricordare il traguardo'),
                    ),
                    const SizedBox(height: 8),
                    Text('Questa pianificazione non contiene prezzi, valori o budget.', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ANNULLA')),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) Navigator.pop(dialogContext, true);
              },
              child: const Text('CONFERMA'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw StateError('Sessione non valida. Accedi nuovamente.');
        final client = Supabase.instance.client.schema('collection').from('wanted_obiettivi');
        final payload = {
          'titolo': title.text.trim(),
          'categoria_tema': category.text.trim(),
          'priorita': priority,
          'note': notes.text.trim().isEmpty ? null : notes.text.trim(),
        };
        if (existing == null) {
          await client.insert({...payload, 'user_id': user.id});
        } else {
          await client.update({...payload, 'data_aggiornamento': DateTime.now().toUtc().toIso8601String()})
              .eq('id', existing['id']).eq('user_id', user.id);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(existing == null ? 'Obiettivo salvato.' : 'Obiettivo aggiornato.')));
          await _load();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvataggio non riuscito: $e')));
      }
    }
    title.dispose();
    category.dispose();
    notes.dispose();
  }

  Future<void> _deleteGoal(Map<String, dynamic> row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RIMUOVI OBIETTIVO'),
        content: Text('Vuoi rimuovere “${row['titolo']}” dalla pianificazione?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('RIMUOVI')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Sessione non valida. Accedi nuovamente.');
      await Supabase.instance.client.schema('collection').from('wanted_obiettivi')
          .delete().eq('id', row['id']).eq('user_id', user.id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rimozione non riuscita: $e')));
    }
  }

  Color _priorityColor(String value) => switch (value) {
    'ALTA' => Colors.redAccent,
    'BASSA' => Colors.blueGrey,
    _ => _silver,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OBIETTIVI DI ACQUISTO'),
        actions: [
          IconButton(tooltip: 'Aggiorna', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _editGoal(),
        icon: const Icon(Icons.add),
        label: const Text('NUOVO OBIETTIVO'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 40),
                      const SizedBox(height: 10),
                      Text('Impossibile caricare gli obiettivi.\n$_error', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('RIPROVA')),
                    ]),
                  ))
                : _rows.isEmpty
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.flag_outlined, size: 54, color: _silver),
                          const SizedBox(height: 12),
                          Text('Nessun obiettivo pianificato', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          const Text('Crea obiettivi per tema o categoria e assegna una priorità.', textAlign: TextAlign.center),
                        ]),
                      ))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
                          itemCount: _rows.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (context, index) {
                            final row = _rows[index];
                            final priority = (row['priorita'] ?? 'MEDIA').toString();
                            return Card(
                              child: ListTile(
                                leading: Icon(Icons.flag_outlined, color: _priorityColor(priority), size: 28),
                                title: Text((row['titolo'] ?? '').toString()),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text((row['categoria_tema'] ?? '').toString()),
                                    const SizedBox(height: 4),
                                    Text('PRIORITÀ $priority', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _priorityColor(priority), fontWeight: FontWeight.bold)),
                                    if ((row['note'] ?? '').toString().trim().isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(row['note'].toString()),
                                    ],
                                  ]),
                                ),
                                isThreeLine: (row['note'] ?? '').toString().trim().isNotEmpty,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') _editGoal(existing: row);
                                    if (value == 'delete') _deleteGoal(row);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('MODIFICA')),
                                    PopupMenuItem(value: 'delete', child: Text('RIMUOVI')),
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
