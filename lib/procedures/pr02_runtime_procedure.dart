part of '../main.dart';

/// Dati minimi usati dal flusso di conferma PR-02.
extension _Pr02RuntimeProcedure on _ObjectRuntimePageState {
  Map<String, dynamic> _pr02ConfirmationPayload() {
    final payload = _payload();
    final rows = payload['oggetti'];
    if (rows is! List || rows.isEmpty || rows.first is! Map) {
      throw Exception('Non ci sono modifiche valide da confermare.');
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }
}
