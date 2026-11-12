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


}
