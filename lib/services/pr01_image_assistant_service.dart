import 'dart:typed_data';

import 'package:dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Isola la chiamata di riconoscimento fotografico PR-12 usata dall'assistente PR-01.
class Pr01ImageAssistantService {
  const Pr01ImageAssistantService();

  String mimeTypeFor(String? fileName) {
    final name = (fileName ?? '').toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    if (name.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  Future<Map<String, dynamic>> recognize({
    required Uint8List bytes,
    required String? fileName,
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Scatta prima una foto dell’oggetto.');
    }
    final response = await Supabase.instance.client.functions.invoke(
      'pr-12-engine-test',
      body: {
        'azione': 'ANALIZZA_FOTO',
        'modalita_ia': 'TEST',
        'image_data_url': 'data:${mimeTypeFor(fileName)};base64,${base64Encode(bytes)}',
        'mercato': 'Italia',
      },
    );
    final data = response.data;
    if (data is! Map || data['ok'] != true) {
      throw Exception(
        data is Map
            ? (data['error'] ?? 'Riconoscimento non riuscito').toString()
            : 'Risposta PR-12 non valida',
      );
    }
    return {
      'identificazione': data['identificazione'] is Map
          ? Map<String, dynamic>.from(data['identificazione'] as Map)
          : <String, dynamic>{},
      'risultati': data['risultati'] is List
          ? (data['risultati'] as List)
              .whereType<Map>()
              .map((value) => Map<String, dynamic>.from(value))
              .toList()
          : <Map<String, dynamic>>[],
    };
  }
}
