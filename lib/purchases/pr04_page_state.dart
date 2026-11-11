part of '../main.dart';

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
    _initializeFromMetadata(widget.initialMetadata);
    _loadCollectionCategories();
  }

  @override
  void dispose() { _count.dispose(); for (final i in _items) { i.dispose(); } super.dispose(); }

}
