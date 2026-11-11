part of '../main.dart';

/// Invoca PR-18 per il candidato confermato senza effettuare scritture nel catalogo.
extension _ValoraCatalogIntakeValuationService on _ValoraServicePageState {
  Future<Map<String, dynamic>> _requestValoraCatalogIntakeValuation(
    Map<String, dynamic> metadata,
  ) async {
    final response = await Supabase.instance.client.functions.invoke(
      'pr-18-valuation-test',
      body: {
        'metadati': metadata,
        'mercato_riferimento': _market,
      },
    );
    final data = response.data;
    if (data is! Map || data['ok'] != true) {
      throw StateError(data is Map
          ? (data['error'] ?? 'PR18 non ha completato la valutazione').toString()
          : 'Risposta PR18 non valida.');
    }
    return Map<String, dynamic>.from(data);
  }
}
