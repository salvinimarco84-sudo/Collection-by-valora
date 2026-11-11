part of '../main.dart';

/// Chiamate PR-18 per preparazione e salvataggio delle valutazioni catalogate.
extension _ValoraKnownObjectPr18Service on _ValoraServicePageState {
  Future<Map<String, dynamic>> _requestKnownObjectPr18Valuation({
    required int objectId,
    required Map<String, dynamic> metadata,
    required String market,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'pr-18-valuation-test',
      body: {
        'codice_oggetto': objectId,
        'metadati': metadata,
        'mercato_riferimento': market,
      },
    );
    final data = response.data;
    if (data is! Map || data['ok'] != true) {
      throw StateError(data is Map
          ? (data['error'] ?? 'PR18 non ha completato la valutazione.').toString()
          : 'Risposta PR18 non valida.');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> _persistKnownObjectPr18Valuation({
    required int objectId,
    required Map<String, dynamic> metadata,
    required String market,
    required Map<String, dynamic> valuation,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'pr-18-valuation-test',
      body: {
        'azione': 'SALVA_VALUTAZIONE',
        'codice_oggetto': objectId,
        'metadati': metadata,
        'mercato_riferimento': market,
        'valutazione': valuation,
      },
    );
    final data = response.data;
    if (data is! Map || data['ok'] != true) {
      throw StateError(data is Map
          ? (data['error'] ?? 'Salvataggio della valutazione non riuscito.').toString()
          : 'Risposta di salvataggio PR18 non valida.');
    }
    return Map<String, dynamic>.from(data);
  }
}
