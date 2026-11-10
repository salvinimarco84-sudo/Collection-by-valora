part of '../main.dart';

class ValoraServicePage extends StatefulWidget {
  const ValoraServicePage({super.key});
  @override
  State<ValoraServicePage> createState() => _ValoraServicePageState();
}

abstract class _ValoraServicePageStateBase extends State<ValoraServicePage> {
  // Contratto condiviso: i moduli fotografici e di valutazione possono ricaricare il catalogo.
  Future<void> _loadObjects();

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
  int? _selectedId;
  String _market = 'ITALIA';
  Map<String, dynamic>? _prepared;
  List<Map<String, dynamic>> get _matchingObjects {
    final query = _descriptionQuery.text.trim().toLowerCase();
    if (query.isEmpty) return _objects;
    return _objects.where((object) =>
      (object['descrizione_oggetto'] ?? '').toString().toLowerCase().contains(query)
    ).toList();
  }
}

class _ValoraServicePageState extends _ValoraServicePageStateBase
    with _ValoraPhotoSearch, _ValoraCatalogObjects, _ValoraValuationFlow {
  @override
  void dispose() {
    _descriptionQuery.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  @override
  Widget build(BuildContext context) => buildPage(context);

}
