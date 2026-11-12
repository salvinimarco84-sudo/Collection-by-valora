part of '../main.dart';

class WantedPurchasePage extends StatefulWidget {
  const WantedPurchasePage({super.key});
  @override
  State<WantedPurchasePage> createState() => _WantedPurchasePageState();
}

class _WantedPurchasePageState extends State<WantedPurchasePage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw StateError('Sessione non valida. Accedi nuovamente.');
      final response = await Supabase.instance.client.schema('collection')
          .from('wanted_desideri')
          .select('id,descrizione,categoria,condizione_desiderata,completezza_desiderata,note')
          .eq('user_id', user.id).eq('stato', 'ATTIVO')
          .order('data_creazione', ascending: false);
      if (!mounted) return;
      setState(() {
        _rows = (response as List).whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _startPurchase(Map<String, dynamic> desire) async {
    final result = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => NewPurchasePage(
        wantedDesireId: desire['id'].toString(),
        initialMetadata: {'descrizione': desire['descrizione']},
      ),
    ));
    if (result == true && mounted) await _load();
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
      appBar: AppBar(title: const Text('ACQUISTO WANTED LIST'), actions: [
        IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
      ]),
      body: SafeArea(
        child: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Impossibile caricare i desideri.\n$_error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('RIPROVA')),
              ]),
            ))
          : _rows.isEmpty ? const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Non ci sono desideri attivi da acquistare.', textAlign: TextAlign.center),
            ))
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: _rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final row = _rows[index];
                return Card(child: ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined, color: silver),
                  title: Text((row['descrizione'] ?? '').toString()),
                  subtitle: Text([
                    if ((row['categoria'] ?? '').toString().trim().isNotEmpty) row['categoria'].toString(),
                    if ((row['condizione_desiderata'] ?? '').toString().trim().isNotEmpty) row['condizione_desiderata'].toString(),
                    if ((row['completezza_desiderata'] ?? '').toString().trim().isNotEmpty) row['completezza_desiderata'].toString(),
                  ].join(' · ')),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _startPurchase(row),
                ));
              },
            ),
      ),
    ));
  }
}
