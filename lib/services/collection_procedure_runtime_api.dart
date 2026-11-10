part of '../main.dart';

class _ValoraRuntimeApi {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> call(String action, Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(
      'collection-procedure-runtime-test',
      body: {'action': action, ...body},
    );
    final data = response.data;
    if (data is! Map) throw Exception('Risposta runtime non valida (HTTP ${response.status}).');
    final map = Map<String, dynamic>.from(data);
    if (response.status >= 400 || map['error'] != null) {
      throw Exception(map['error'] ?? 'HTTP ${response.status}');
    }
    return map;
  }

  static Future<Map<String, dynamic>> procedure(
    String code, String step, Map<String, dynamic> payload, {
    required String sessionId, String? requestId,
  }) async {
    final response = await _client.functions.invoke(
      'collection-procedure-runtime-test',
      body: {
        'procedure': code, 'step': step, 'payload': payload,
        'session_id': sessionId, 'request_id': requestId,
      },
    );
    final data = response.data;
    if (data is! Map) throw Exception('Risposta runtime non valida.');
    final map = Map<String, dynamic>.from(data);
    if (response.status >= 400 || map['error'] != null) {
      throw Exception(map['error'] ?? 'HTTP ${response.status}');
    }
    if (map['result'] is Map) return Map<String, dynamic>.from(map['result']);
    throw Exception('Il runtime non ha restituito un risultato strutturato.');
  }
}
