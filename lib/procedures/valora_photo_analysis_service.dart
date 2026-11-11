part of '../main.dart';

/// Chiamata isolata al motore PR-12 per l'analisi di una singola immagine.
Future<Map<String, dynamic>> _analyzeValoraImageBytes(
  Uint8List bytes,
  String fileName,
  String market,
) async {
  if (bytes.isEmpty) throw Exception('Il file $fileName è vuoto o non leggibile.');
  if (bytes.length > 10 * 1024 * 1024) throw Exception('Il file $fileName supera il limite di 10 MB.');
  final name = fileName.toLowerCase();
  final mime = name.endsWith('.png')
      ? 'image/png'
      : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
  final response = await Supabase.instance.client.functions.invoke(
    'pr-12-engine-test',
    body: {
      'azione': 'ANALIZZA_FOTO',
      'modalita_ia': 'TEST',
      'image_data_url': 'data:$mime;base64,${base64Encode(bytes)}',
      'mercato': market,
    },
  );
  final data = response.data;
  if (data is! Map || data['ok'] != true) {
    throw Exception(
      data is Map
          ? (data['error'] ?? 'Ricerca foto non riuscita').toString()
          : 'Risposta PR-12 non valida.',
    );
  }
  return Map<String, dynamic>.from(data);
}
