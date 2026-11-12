part of '../main.dart';

extension _Pr04QueueController on _NewPurchasePageState {
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
