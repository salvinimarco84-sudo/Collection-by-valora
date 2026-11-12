part of '../main.dart';

extension _Pr04DraftController on _NewPurchasePageState {
  void _invalidate() { _preview = null; _dataConfirmed = false; }

  void _resize(int n) {
    while (_items.length < n) { _items.add(_PurchaseItemDraft()); }
    while (_items.length > n) { _items.removeLast().dispose(); }
    _invalidate();
  }



}
