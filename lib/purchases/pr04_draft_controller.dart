part of '../main.dart';

extension _Pr04DraftController on _NewPurchasePageState {
  void _invalidate() { _preview = null; _dataConfirmed = false; }

  void _resize(int n) {
    while (_items.length < n) { _items.add(_PurchaseItemDraft()); }
    while (_items.length > n) { _items.removeLast().dispose(); }
    _invalidate();
  }

  bool _valid() {
    if (_items.isEmpty) { _notice('Inserisci almeno un oggetto.'); return false; }
    if (widget.wantedDesireId != null && (_pendingPurchases.isNotEmpty || _items.length != 1 || _type != 'SINGOLO')) {
      _notice('Un desiderio WANTED LIST deve essere registrato come acquisto singolo di un solo oggetto.'); return false;
    }
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].description.text.trim().isEmpty) {
        _notice('Inserisci la descrizione dell’oggetto ' + (i + 1).toString() + '.'); return false;
      }
      if (_items[i].destination == 'COLLEZIONE' && (_items[i].collectionCategoryCode == null || !_collectionCategories.any((e) => e['codice_categoria'] == _items[i].collectionCategoryCode))) {
        _notice('Seleziona la categoria COLLEZIONE per l’oggetto ' + (i + 1).toString() + '.'); return false;
      }
      final p = _items[i].amount;
      if (p == null || p <= 0) {
        _notice('Inserisci un prezzo maggiore di zero per l’oggetto ' + (i + 1).toString() + '.'); return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _currentPurchaseOperation() => {
    'data_acquisto': _date.toIso8601String().substring(0, 10),
    'importo_totale': double.parse(_total.toStringAsFixed(2)),
    'valuta': 'EUR',
    'oggetti': _items.map((e) => e.json()).toList(),
  };

  double get _pendingTotal => _pendingPurchases.fold<double>(0,
    (sum, purchase) => sum + ((purchase['importo_totale'] as num?)?.toDouble() ?? 0));

  Map<String, dynamic> _payload({bool confirmed = false, bool finalConfirmation = false}) => {
    // Ogni acquisto è un'operazione distinta: SÌ accoda, NO salva tutta la coda.
    'operazioni': [..._pendingPurchases, _currentPurchaseOperation()],
    'dati_confermati': confirmed,
    'conferma_finale': finalConfirmation,
    'altra_operazione': false,
  };

  void _queueCurrentAndStartNext() {
    if (!_valid()) return;
    final operation = _currentPurchaseOperation();
    final queuedCount = _pendingPurchases.length + 1;
    final queuedTotal = _pendingTotal + _total;
    for (final item in _items) { item.dispose(); }
    setState(() {
      _pendingPurchases.add(operation);
      _items..clear()..add(_PurchaseItemDraft());
      _step = 0;
      _type = 'SINGOLO';
      _date = DateTime.now();
      _count.text = '1';
      _preview = null;
      _dataConfirmed = false;
      _status = '$queuedCount acquisti in coda (€ ${queuedTotal.toStringAsFixed(2)}). Nessuna scrittura eseguita.';
    });
  }
}
