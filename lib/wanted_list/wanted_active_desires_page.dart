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
          .select('id, descrizione, categoria, condizione_desiderata, completezza_desiderata, note, data_creazione, immagine_path, immagine_fonte')
          .eq('user_id', user.id)
          .eq('stato', 'ATTIVO')
          .order('data_creazione', ascending: false);
      final rows = (response as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      for (final row in rows) {
        final path = row['immagine_path']?.toString();
        if (path != null && path.isNotEmpty) {
          try {
            row['immagine_url'] = await Supabase.instance.client.storage
                .from('wanted-list-images-test').createSignedUrl(path, 3600);
          } catch (_) {
            row['immagine_url'] = null;
          }
        }
      }
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _changeImage(Map<String, dynamic> row) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { _message('Sessione non valida. Accedi nuovamente.'); return; }
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final ext = picked.name.toLowerCase().split('.').last;
      final safeExt = ['png', 'webp'].contains(ext) ? ext : 'jpg';
      final mime = safeExt == 'png' ? 'image/png' : safeExt == 'webp' ? 'image/webp' : 'image/jpeg';
      final id = row['id'].toString();
      final path = '${user.id}/$id/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final storage = Supabase.instance.client.storage.from('wanted-list-images-test');
      await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mime));
      await Supabase.instance.client.schema('collection').from('wanted_desideri').update({
        'immagine_path': path,
        'immagine_fonte': 'CARICATA',
        'data_immagine': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id).eq('user_id', user.id);
      final oldPath = row['immagine_path']?.toString();
      if (oldPath != null && oldPath.isNotEmpty) { try { await storage.remove([oldPath]); } catch (_) {} }
      if (mounted) _message('Immagine aggiornata e salvata.');
      await _load();
    } catch (e) {
      _message('Caricamento immagine non riuscito: $e');
    }
  }

  Future<void> _removeImage(Map<String, dynamic> row) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) { _message('Sessione non valida. Accedi nuovamente.'); return; }
    try {
      final path = row['immagine_path']?.toString();
      await Supabase.instance.client.schema('collection').from('wanted_desideri').update({
        'immagine_path': null, 'immagine_fonte': null, 'data_immagine': null,
      }).eq('id', row['id'].toString()).eq('user_id', user.id);
      if (path != null && path.isNotEmpty) {
        await Supabase.instance.client.storage.from('wanted-list-images-test').remove([path]);
      }
      if (mounted) _message('Immagine rimossa.');
      await _load();
    } catch (e) {
      _message('Rimozione immagine non riuscita: $e');
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
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
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: (row['immagine_url'] is String)
                                            ? Image.network(row['immagine_url'] as String, width: 104, height: 104, fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => Container(width: 104, height: 104,
                                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  child: const Icon(Icons.broken_image_outlined, size: 34)))
                                            : Container(width: 104, height: 104,
                                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                child: const Icon(Icons.image_outlined, size: 34, color: silver)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(description, style: Theme.of(context).textTheme.titleMedium),
                                          if ((row['immagine_fonte'] ?? '').toString().isNotEmpty)
                                            Text('Immagine: ${row['immagine_fonte']}', style: Theme.of(context).textTheme.labelSmall),
                                        ])),
                                      ],
                                    ),
                                    if (category.trim().isNotEmpty)
                                      _detail('Categoria / tema', category),
                                    _detail('Condizione', row['condizione_desiderata']?.toString()),
                                    _detail('Completezza', row['completezza_desiderata']?.toString()),
                                    _detail('Note', row['note']?.toString()),
                                    const SizedBox(height: 8),
                                    Wrap(spacing: 8, children: [
                                      TextButton.icon(onPressed: () => _changeImage(row),
                                        icon: const Icon(Icons.add_photo_alternate_outlined),
                                        label: Text(row['immagine_path'] == null ? 'AGGIUNGI IMMAGINE' : 'CAMBIA IMMAGINE')),
                                      if (row['immagine_path'] != null)
                                        TextButton.icon(onPressed: () => _removeImage(row),
                                          icon: const Icon(Icons.delete_outline), label: const Text('RIMUOVI')),
                                    ]),
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
