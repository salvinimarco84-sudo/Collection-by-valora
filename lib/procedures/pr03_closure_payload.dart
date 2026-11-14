part of '../main.dart';

/// Prepara il payload di chiusura verificando che la scheda caricata sia quella selezionata.
extension _Pr03ClosurePayload on _ObjectRuntimePageState {
  Map<String, dynamic> _buildPr03ClosurePayload() {
    final id = int.tryParse(_code.text.trim());
    if (id == null || id <= 0) {
      throw Exception('Inserisci un codice oggetto valido.');
    }
    if (_loadedObjectId != id || _currentObject == null) {
      throw Exception('Per PR-03 carica prima la scheda completa del codice selezionato.');
    }
    return {
      'oggetti': [{
        'codice_oggetto': id,
        'motivo_chiusura': _closeReason,
        'note': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      }],
    };
  }
}
