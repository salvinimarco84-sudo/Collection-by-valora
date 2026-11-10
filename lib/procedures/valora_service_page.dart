part of '../main.dart';

class ValoraServicePage extends StatefulWidget {
  const ValoraServicePage({super.key});
  @override
  State<ValoraServicePage> createState() => _ValoraServicePageState();
}

class _ValoraServicePageState extends State<ValoraServicePage> {
  bool _loading = true;
  bool _preparing = false;
  bool _analyzingPhotos = false;
  final List<Map<String, dynamic>> _photoSearchResults = [];
  final Map<int, String> _selectedPhotoCandidates = {};
  final Set<String> _reviewedCandidateUrls = {};
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


  Future<void> _analyzeSelectedPhotos() async {
    if (_selectedImages.isEmpty) {
      setState(() => _error = 'Seleziona almeno una foto da usare nella ricerca.');
      return;
    }
    setState(() { _analyzingPhotos = true; _error = null; _photoSearchResults.clear(); });
    try {
      for (final image in List<XFile>.from(_selectedImages)) {
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty) throw Exception('La foto ${image.name} è vuota o non leggibile.');
        if (bytes.length > 10 * 1024 * 1024) throw Exception('La foto ${image.name} supera il limite di 10 MB.');
        final name = image.name.toLowerCase();
        final mime = name.endsWith('.png') ? 'image/png' : name.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
        final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
          'azione': 'ANALIZZA_FOTO',
          'modalita_ia': 'TEST',
          'image_data_url': 'data:$mime;base64,${base64Encode(bytes)}',
          'mercato': _market,
        });
        final data = response.data;
        if (data is! Map || data['ok'] != true) {
          throw Exception(data is Map ? (data['error'] ?? 'Ricerca foto non riuscita').toString() : 'Risposta PR-12 non valida.');
        }
        if (!mounted) return;
        setState(() => _photoSearchResults.add({
          'nome_foto': image.name,
          'identificazione': data['identificazione'] is Map ? Map<String, dynamic>.from(data['identificazione']) : <String, dynamic>{},
          'risultati': data['risultati'] is List ? List<dynamic>.from(data['risultati']) : <dynamic>[],
          'diagnostica': data['diagnostica_ricerca'],
          'query_eseguite': data['query_eseguite'] is List ? List<String>.from(data['query_eseguite']) : <String>[],
          'categoria': (data['identificazione'] is Map ? data['identificazione']['categoria'] : '').toString(),
          'tema': (data['identificazione'] is Map ? data['identificazione']['marchio'] : '').toString(),
          'ricerche_estese': 0,
          'scrittura_database': false,
        }));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Ricerca da foto non completata: $e');
    } finally {
      if (mounted) setState(() => _analyzingPhotos = false);
    }
  }

  Future<void> _retryPhotoSearch(int index) async {
    if (index < 0 || index >= _photoSearchResults.length) return;
    final current = _photoSearchResults[index];
    final clues = Map<String, dynamic>.from(current['identificazione'] as Map? ?? {});
    final candidates = (current['risultati'] as List? ?? []).whereType<Map>().toList();
    final excludedUrls = <String>{
      ..._reviewedCandidateUrls,
      ...candidates.map((item) => (item['url'] ?? '').toString()).where((url) => url.startsWith('http')),
    };
    final excludedQueries = (current['query_eseguite'] as List? ?? []).map((e) => e.toString()).toSet();
    setState(() { _analyzingPhotos = true; _error = null; });
    try {
      final response = await Supabase.instance.client.functions.invoke('pr-12-web-search-test', body: {
        'descrizione': (clues['descrizione_provvisoria'] ?? '').toString(),
        'categoria': (current['categoria'] ?? clues['categoria'] ?? '').toString(),
        'tema': (current['tema'] ?? clues['marchio'] ?? '').toString(),
        'mercato': _market,
        'ricerca_estesa': true,
        'escludi_url': excludedUrls.toList(),
        'escludi_query': excludedQueries.toList(),
      });
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['error'] ?? 'Nuova ricerca non riuscita').toString() : 'Risposta PR-12 non valida.');
      }
      final added = (data['risultati'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final old = candidates.map((e) => Map<String, dynamic>.from(e)).toList();
      final known = old.map((e) => (e['url'] ?? '').toString()).toSet();
      for (final item in added) {
        final url = (item['url'] ?? '').toString();
        if (url.isNotEmpty && known.add(url)) old.add(item);
      }
      if (!mounted) return;
      setState(() {
        current['risultati'] = old;
        current['query_eseguite'] = [
          ...excludedQueries,
          ...((data['query_eseguite'] as List? ?? []).map((e) => e.toString())),
        ].toSet().toList();
        current['ricerche_estese'] = ((current['ricerche_estese'] as int?) ?? 0) + 1;
        current['diagnostica'] = data['diagnostica'];
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Nuova ricerca PR-12 non completata: $e');
    } finally {
      if (mounted) setState(() => _analyzingPhotos = false);
    }
  }

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
      const pageSize = 500;
      var offset = 0;
      final rows = <Map<String, dynamic>>[];
      const excludedStatuses = {
        'VENDUTO', 'SOLD', 'PERSO', 'LOST', 'DISTRUTTO', 'DESTROYED',
        'USCITO', 'EXITED', 'ACCORPATO', 'MERGED',
      };

      // Legge tutte le pagine: il limite di una singola richiesta non deve
      // nascondere oggetti validi che si trovano oltre i primi 500 record.
      while (true) {
        final page = await Supabase.instance.client.schema('collection')
            .from('master_oggetti')
            .select('codice_oggetto,descrizione_oggetto,produttore,codice_prodotto,stato,condizione,completezza')
            .eq('destinazione', 'COLLEZIONE')
            .neq('archiviato_test', true)
            .order('descrizione_oggetto')
            .order('codice_oggetto')
            .range(offset, offset + pageSize - 1);

        final pageRows = (page as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((row) => !excludedStatuses.contains(
                (row['stato'] ?? '').toString().trim().toUpperCase()))
            .toList();
        rows.addAll(pageRows);

        if (page.length < pageSize) break;
        offset += pageSize;
      }

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
