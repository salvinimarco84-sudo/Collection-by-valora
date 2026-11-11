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
  final Map<int, Map<String, dynamic>> _confirmedPhotoCandidates = {};
  final Map<int, String> _metadataValuationStatus = {};
  final Set<String> _reviewedCandidateUrls = {};
  String? _error;
  final TextEditingController _descriptionQuery = TextEditingController();
  List<Map<String, dynamic>> _objects = [];
  final List<XFile> _selectedImages = [];
  final List<PlatformFile> _selectedFiles = [];

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
            .select('codice_oggetto,descrizione_oggetto,produttore,codice_prodotto,stato,destinazione,condizione,completezza,valore_mercato')
            .or('archiviato_test.is.null,archiviato_test.eq.false')
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


  @override
  Widget build(BuildContext context) => buildPage(context);

}
