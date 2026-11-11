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

  @override
  void dispose() {
    _descriptionQuery.dispose();
    super.dispose();
  }
  int? _selectedId;
  String _market = '';
  bool _marketLoading = true;
  String? _marketError;
  Map<String, dynamic>? _prepared;

  @override
  void initState() {
    super.initState();
    _loadObjects();
    _loadUserMarket();
  }

  Future<void> _loadUserMarket() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw StateError('Accedi per leggere il mercato del profilo.');
      final rows = await client.schema('collection').from('master_utente')
          .select('mercato_nazionale_principale,mercati(nome_mercato)')
          .eq('auth_user_id', user.id).limit(1);
      if (rows.isEmpty) throw StateError('Completa il profilo e imposta il mercato principale.');
      final row = Map<String, dynamic>.from(rows.first);
      final market = row['mercati'];
      final marketName = market is Map ? (market['nome_mercato'] ?? '').toString().trim() : '';
      if (row['mercato_nazionale_principale'] == null || marketName.isEmpty) {
        throw StateError('Il profilo non contiene un mercato principale valido.');
      }
      if (!mounted) return;
      setState(() { _market = marketName; _marketError = null; _marketLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _marketError = e.toString(); _marketLoading = false; _market = ''; });
    }
  }

  @override
  Widget build(BuildContext context) => buildPage(context);

}
