part of '../main.dart';

class _PurchaseItemDraft {
  final description = TextEditingController();
  final price = TextEditingController();
  final notes = TextEditingController();
  Uint8List? photoBytes;
  String? photoName;
  String? photoUrl;
  String? metadataProducer;
  String? metadataCode;
  int? metadataYear;
  String? metadataSourceUrl;
  String photoStatus = 'Nessuna foto selezionata.';
  String destination = 'COLLEZIONE';
  String? collectionCategoryCode;
  String condition = 'USATO';
  String completeness = 'COMPLETO';
  double? get amount {
    var s = price.text.trim().replaceAll('€', '').replaceAll(' ', '');
    if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }
  Map<String, dynamic> json() => {
    'descrizione': description.text.trim(), 'valore_acquisto': amount,
    if (notes.text.trim().isNotEmpty) 'note': notes.text.trim(),
    'destinazione': destination, 'condizione': condition,
    if (destination == 'COLLEZIONE' && collectionCategoryCode != null) 'codice_categoria_collezione': collectionCategoryCode,
    'completezza': completeness, 'quantita': 1,
    if (metadataProducer != null) 'produttore': metadataProducer,
    if (metadataCode != null) 'codice_prodotto': metadataCode,
    if (metadataYear != null) 'anno_uscita': metadataYear,
    if (metadataSourceUrl != null) 'fonte_dati_prodotto': metadataSourceUrl,
    if (metadataProducer != null || metadataCode != null || metadataYear != null)
      'stato_verifica_dati': 'DA_VERIFICARE',
    if (photoUrl != null) 'url_immagine_catalogo': photoUrl,
  };
  void dispose() { description.dispose(); price.dispose(); notes.dispose(); }
}

mixin _Pr04PageState on State<NewPurchasePage> {

  int _step = 0;
  String _type = 'SINGOLO';
  final _count = TextEditingController(text: '2');
  DateTime _date = DateTime.now();
  final List<_PurchaseItemDraft> _items = [_PurchaseItemDraft()];
  // Gli acquisti confermati restano in coda fino al salvataggio finale unico.
  final List<Map<String, dynamic>> _pendingPurchases = [];
  List<Map<String, dynamic>> _collectionCategories = [];
  bool _categoriesLoading = false;
  final String _session = _uuid.v4();
  bool _busy = false, _locked = false, _dataConfirmed = false;
  bool _wantedPurchaseCommitted = false;
  int? _wantedPurchaseCode;
  Map<String, dynamic>? _preview;
  String _status = 'Bozza locale: nessun acquisto registrato.';


  String? _nonEmptyMetadata(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<void> _loadCollectionCategories() async {
    _categoriesLoading = true;
    try {
      final rows = await Supabase.instance.client.schema('collection')
          .from('master_categorie_collezione')
          .select('codice_categoria, descrizione, ordine_menu, visibile')
          .eq('visibile', true)
          .order('ordine_menu')
          .order('descrizione');
      if (!mounted) return;
      setState(() => _collectionCategories = (rows as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList());
    } catch (e) {
      if (mounted) setState(() => _status = 'Errore caricamento categorie: $e');
    } finally {
      _categoriesLoading = false;
    }
  }

  double get _total => _items.fold<double>(0,
      (sum, item) => sum + (item.amount ?? 0));

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    final metadata = widget.initialMetadata;
    if (metadata != null) {
      final item = _items.first;
      item.description.text = (metadata['descrizione'] ?? '').toString();
      item.metadataProducer = _nonEmptyMetadata(metadata['produttore']);
      item.metadataCode = _nonEmptyMetadata(metadata['codice_prodotto']);
      item.metadataYear = metadata['anno_uscita'] is num
          ? (metadata['anno_uscita'] as num).toInt()
          : int.tryParse((metadata['anno_uscita'] ?? '').toString());
      item.metadataSourceUrl = _nonEmptyMetadata(metadata['fonte_dati_prodotto']);
      final imageUrl = _nonEmptyMetadata(metadata['url_immagine_catalogo']);
      item.photoUrl = imageUrl != null &&
          (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'))
          ? imageUrl : null;
      item.photoStatus = item.photoUrl == null
          ? 'Metadati VALORA precompilati. Foto utente non importata come immagine definitiva.'
          : 'Metadati e immagine catalogo selezionata da fonte online. Verifica prima del salvataggio.';
      // Il costo resta intenzionalmente vuoto: il valore di mercato non è un costo d’acquisto.
    }
    _loadCollectionCategories();
  }

  @override
  void dispose() { _count.dispose(); for (final i in _items) { i.dispose(); } super.dispose(); }

}
