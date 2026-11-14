part of '../main.dart';

/// Gestisce il ciclo di vita delle richieste di ricerca della procedura PR-03.
extension _Pr03SearchRequestWorkflow on _ObjectRuntimePageState {
  int? _beginPr03SearchRequest() {
    if (widget.apiCode != 'PR-03') return null;
    return _pr03Controller.nextSearchRequestId();
  }

  bool _isCurrentPr03SearchRequest(int? requestId) {
    if (requestId == null) return true;
    return _pr03Controller.isCurrentSearchRequest(requestId);
  }
}
