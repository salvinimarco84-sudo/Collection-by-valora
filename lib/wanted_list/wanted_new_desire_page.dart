part of '../main.dart';

class WantedNewDesirePage extends StatefulWidget {
  const WantedNewDesirePage({super.key});
  @override
  State<WantedNewDesirePage> createState() => _WantedNewDesirePageState();
}

class _WantedNewDesirePageState extends State<WantedNewDesirePage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _category = TextEditingController();
  final _notes = TextEditingController();
  String? _condition;
  String? _completeness;
  bool _saving = false;
  XFile? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1600);
      if (picked != null && mounted) setState(() => _selectedImage = picked);
    } catch (e) {
      _message('Impossibile selezionare l’immagine: $e');
    }
  }

  static const _conditions = [
    'NUOVO', 'NUOVO IMBALLATO', 'COME NUOVO', 'OTTIMO', 'BUONO',
    'DISCRETO', 'USATO', 'USATO ASSEMBLATO', 'USATO CON SEGNI',
  ];
  static const _completenessOptions = [
    'SIGILLATO', 'COMPLETO', 'COMPLETO CON ISTRUZIONI',
    'COMPLETO CON SCATOLA E ISTRUZIONI', 'INCOMPLETO', 'SOLO PARTI',
  ];

  @override
  void dispose() {
    _description.dispose();
    _category.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _message('Sessione non valida. Accedi nuovamente.');
      return;
    }
    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client.schema('collection');
      final desireId = const Uuid().v4();
      final inserted = await client.from('wanted_desideri').insert({
        'id': desireId,
        'user_id': user.id,
        'stato': 'ATTIVO',
        'descrizione': _description.text.trim(),
        'categoria': _category.text.trim().isEmpty ? null : _category.text.trim(),
        'condizione_desiderata': _condition,
        'completezza_desiderata': _completeness,
        'note': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      }).select('id').single();
      final id = inserted['id']?.toString();
      if (id == null || id.isEmpty) {
        throw StateError('Il database non ha restituito il codice del desiderio.');
      }
      var imageUploadError = false;
      if (_selectedImage != null) {
        try {
          final bytes = await _selectedImage!.readAsBytes();
          final ext = _selectedImage!.name.toLowerCase().split('.').last;
          final safeExt = ['png', 'webp'].contains(ext) ? ext : 'jpg';
          final mime = safeExt == 'png' ? 'image/png' : safeExt == 'webp' ? 'image/webp' : 'image/jpeg';
          final imagePath = '${user.id}/$id/${DateTime.now().millisecondsSinceEpoch}.$safeExt';
          await Supabase.instance.client.storage.from('wanted-list-images-test').uploadBinary(
            imagePath, bytes, fileOptions: FileOptions(contentType: mime),
          );
          await client.from('wanted_desideri').update({
            'immagine_path': imagePath,
            'immagine_fonte': 'CARICATA',
            'data_immagine': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', id).eq('user_id', user.id);
        } catch (_) {
          imageUploadError = true;
        }
      }
      final verified = await client.from('wanted_desideri')
          .select('id, descrizione, stato, immagine_path')
          .eq('id', id).eq('user_id', user.id).maybeSingle();
      if (verified == null || verified['stato'] != 'ATTIVO' ||
          verified['descrizione'] != _description.text.trim()) {
        throw StateError('Il desiderio non ha superato la verifica dopo il salvataggio.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(imageUploadError
          ? 'Desiderio salvato. Immagine non caricata: puoi aggiungerla dalla lista.'
          : 'Desiderio salvato e verificato.'),
      ));
      Navigator.of(context).pop(true);
    } catch (e) {
      _message('Salvataggio non riuscito: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    const silver = Color(0xFFB8BEC6);
    return Scaffold(
      appBar: AppBar(title: const Text('NUOVO DESIDERIO')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.bookmark_add_outlined, color: silver, size: 30),
                          const SizedBox(width: 12),
                          Expanded(child: Text(
                            'Registra l’oggetto che desideri acquistare. '
                            'Questa scheda non crea un oggetto nel catalogo e non registra un acquisto.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(
                      labelText: 'Descrizione oggetto *',
                      hintText: 'Es. LEGO  set  21309 NASA Apollo Saturn V',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Inserisci la descrizione dell’oggetto.' : null,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('IMMAGINE DEL DESIDERIO', style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 10),
                        if (_selectedImage != null)
                          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(
                            File(_selectedImage!.path), height: 170, width: double.infinity, fit: BoxFit.contain,
                          ))
                        else
                          Container(height: 110, width: double.infinity, alignment: Alignment.center,
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.image_outlined, size: 42)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          OutlinedButton.icon(onPressed: _saving ? null : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined), label: const Text('GALLERIA')),
                          OutlinedButton.icon(onPressed: _saving ? null : () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined), label: const Text('FOTOCAMERA')),
                          if (_selectedImage != null) TextButton.icon(onPressed: _saving ? null : () => setState(() => _selectedImage = null),
                            icon: const Icon(Icons.delete_outline), label: const Text('RIMUOVI')),
                        ]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _category,
                    decoration: const InputDecoration(
                      labelText: 'Categoria / tema',
                      hintText: 'Es. LEGO, Gundam, Fumetti, Modellini',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: const InputDecoration(
                      labelText: 'Condizione desiderata',
                      prefixIcon: Icon(Icons.verified_outlined),
                    ),
                    items: _conditions.map((v) =>
                      DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: _saving ? null : (v) => setState(() => _condition = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _completeness,
                    decoration: const InputDecoration(
                      labelText: 'Completezza desiderata',
                      prefixIcon: Icon(Icons.checklist_outlined),
                    ),
                    items: _completenessOptions.map((v) =>
                      DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: _saving ? null : (v) => setState(() => _completeness = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Edizione, versione, accessori o dettagli da controllare',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'SALVATAGGIO E VERIFICA…' : 'SALVA DESIDERIO'),
                    style: FilledButton.styleFrom(
                      backgroundColor: silver,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('ANNULLA'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
