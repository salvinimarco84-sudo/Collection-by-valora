part of '../main.dart';

/// Collega lo stato PR-03 al runtime della pagina senza mantenere getter nel file principale.
extension _Pr03ControllerBindings on _ObjectRuntimePageState {
  List<Map<String, dynamic>> get _pr03PendingClosures =>
      _pr03Controller.pendingClosures;

  String get _closeReason => _pr03Controller.closeReason;

  set _closeReason(String value) => _pr03Controller.closeReason = value;
}
