part of '../main.dart';

/// Selezione del risultato trovato dalla ricerca dedicata a PR-03.
extension _Pr03SearchResultSelection on _ObjectRuntimePageState {
  Future<bool> _selectPr03SearchResultIfNeeded(
    Map<String, dynamic> selected,
  ) async {
    if (widget.apiCode != 'PR-03') return false;
    await _selectPr03Object(selected);
    return true;
  }
}
