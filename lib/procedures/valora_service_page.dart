part of '../main.dart';

class ValoraServicePage extends StatefulWidget {
  const ValoraServicePage({super.key});
  @override
  State<ValoraServicePage> createState() => _ValoraServicePageState();
}

class _ValoraServicePageState extends State<ValoraServicePage> {
  bool _loading = true;
  bool _preparing = false;
  String? _error;
  final TextEditingController _descriptionQuery = TextEditingController();
  List<Map<String, dynamic>> _objects = [];
  final List<XFile> _selectedImages = [];
  final List<PlatformFile> _selectedFiles = [];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final images = await picker.pickMultiImage(imageQuality: 92);
        if (!mounted || images.isEmpty) return;
        setState(() {
          for (final image in images) {
            if (_selectedImages.every((item) => item.path != image.path)) {
              _selectedImages.add(image);
            }
          }
        });
      } else {
        final image = await picker.pickImage(source: source, imageQuality: 92);
        if (!mounted || image == null) return;
        setState(() => _selectedImages.add(image));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Selezione immagine non riuscita: $e');
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );
      if (!mounted || result == null) return;
      setState(() {
        for (final file in result.files) {
          if (_selectedFiles.every((item) => item.name != file.name || item.size != file.size)) {
            _selectedFiles.add(file);
          }
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Selezione file non riuscita: $e');
    }
  }

  void _removeImage(XFile image) => setState(() => _selectedImages.remove(image));
  void _removeFile(PlatformFile file) => setState(() => _selectedFiles.remove(file));

  List<Map<String, dynamic>> get _matchingObjects {
    final query = _descriptionQuery.text.trim().toLowerCase();
    if (query.isEmpty) return _objects;
    return _objects.where((object) =>
      (object['descrizione_oggetto'] ?? '').toString().toLowerCase().contains(query)
    ).toList();
  }

  @override
  void dispose() {
    _descriptionQuery.dispose();
    super.dispose();
  }
  int? _selectedId;
  String _market = 'ITALIA';
  Map<String, dynamic>? _prepared;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  Future<void> _loadObjects() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Supabase.instance.client.schema('collection')
          .from('master_oggetti')
          .select('codice_oggetto,descrizione_oggetto,produttore,codice_prodotto,stato,condizione,completezza')
          .eq('destinazione', 'COLLEZIONE')
          .neq('archiviato_test', true)
          .order('descrizione_oggetto')
          .limit(500);
      final rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map))
          .where((r) => !['VENDUTO','PERSO','DISTRUTTO','USCITO','ACCORPATO']
              .contains((r['stato'] ?? '').toString().toUpperCase())).toList();
      if (!mounted) return;
      setState(() { _objects = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossibile caricare gli oggetti della collezione: $e'; _loading = false; });
    }
  }

  Future<void> _prepareValuation() async {
    final id = _selectedId;
    if (id == null) {
      setState(() => _error = 'Seleziona prima un oggetto.');
      return;
    }
    setState(() { _preparing = true; _error = null; _prepared = null; });
    try {
      final response = await _ValoraRuntimeApi.call('consultation', {
        'session_id': null,
        'consultation_code': 'MARKET_VALUATION_PREPARE',
        'arguments': {'codice_oggetto': id, 'mercato_riferimento': _market},
      });
      if (!mounted) return;
      final result = response['result'];
      setState(() {
        _prepared = result is Map ? Map<String, dynamic>.from(result) : {'risultato': result};
        _preparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Preparazione non riuscita: $e'; _preparing = false; });
    }
  }

  @override
  Widget build(BuildContext context) => buildPage(context);

}
