part of '../main.dart';

class _Pr06ValoraListingDraftApi {
  static Future<List<Map<String, dynamic>>> create(int saleCode) async {
    final response = await Supabase.instance.client.functions.invoke(
      'valora-listing-drafts-test',
      body: {'action': 'create', 'codice_vendita_aperta': saleCode},
    );
    final data = response.data;
    if (response.status >= 400 || data is! Map || data['error'] != null) {
      throw Exception(data is Map ? (data['error'] ?? 'Errore generazione bozze') : 'Risposta non valida dal servizio bozze.');
    }
    final rows = data['bozze'];
    if (rows is! List) throw Exception('Il servizio non ha restituito le bozze.');
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<Map<String, dynamic>> update({
    required String id,
    required String title,
    required String description,
    required String category,
    required double price,
  }) async {
    final response = await Supabase.instance.client.functions.invoke(
      'valora-listing-drafts-test',
      body: {
        'action': 'update',
        'id': id,
        'titolo': title,
        'descrizione': description,
        'categoria': category,
        'prezzo': price,
      },
    );
    final data = response.data;
    if (response.status >= 400 || data is! Map || data['error'] != null || data['bozza'] is! Map) {
      throw Exception(data is Map ? (data['error'] ?? 'Bozza non aggiornata') : 'Risposta non valida dal servizio bozze.');
    }
    return Map<String, dynamic>.from(data['bozza'] as Map);
  }

  static Future<List<Map<String, dynamic>>> list() async {
    final response = await Supabase.instance.client.functions.invoke(
      'valora-listing-drafts-test',
      body: {'action': 'list'},
    );
    final data = response.data;
    if (response.status >= 400 || data is! Map || data['error'] != null) {
      throw Exception(data is Map ? (data['error'] ?? 'Impossibile caricare le bozze') : 'Risposta non valida dal servizio bozze.');
    }
    final rows = data['bozze'];
    if (rows is! List) throw Exception('Il servizio non ha restituito l’elenco delle bozze.');
    return rows.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
