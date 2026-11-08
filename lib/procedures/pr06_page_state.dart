part of '../main.dart';

/// PR-06: pagina e stato della nuova vendita.
class NewSalePage extends StatefulWidget {
  const NewSalePage({super.key, this.initialObjectCode});
  final int? initialObjectCode;

  @override
  State<NewSalePage> createState() => _NewSalePageState();
}

class _NewSalePageState extends State<NewSalePage> {
  final String _session = _uuid.v4();
  final TextEditingController _search = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _lotTotalPrice = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  bool _lotMode = false;
  final Set<int> _selectedLotObjects = <int>{};
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _platforms = [];
  final Set<int> _selectedPlatforms = <int>{};
  final List<Map<String, dynamic>> _pendingSales = [];
  final List<String> _pendingDescriptions = [];
  int? _selectedObject;
  Map<String, dynamic>? _preview;
  bool _busy = false, _locked = false, _loading = true, _confirmed = false;
  String _status = 'Caricamento degli oggetti disponibili per la rivendita…';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose(); _price.dispose(); _lotTotalPrice.dispose(); _notes.dispose();
    if (_locked) _releaseSilently();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPr06FormContent(context);
}
