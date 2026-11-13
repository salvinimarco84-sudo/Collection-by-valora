import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Upload e registrazione delle immagini degli oggetti.
/// Non gestisce la UI né lo stato della maschera: riceve i dati già acquisiti
/// e restituisce l'URL firmato solo dopo la conferma dell'endpoint.
class ObjectImageService {
  ObjectImageService({
    SupabaseClient? client,
    Uuid? uuid,
  })  : _client = client ?? Supabase.instance.client,
        _uuid = uuid ?? const Uuid();

  final SupabaseClient _client;
  final Uuid _uuid;

  static const int maxBytes = 10 * 1024 * 1024;
  static const Set<String> supportedExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif',
  };

  static String safeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');

  static String extensionOf(String fileName) {
    final safeName = safeFileName(fileName);
    return safeName.contains('.')
        ? safeName.split('.').last.toLowerCase()
        : 'jpg';
  }

  static String mimeTypeFor(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'heif' => 'image/heif',
        _ => 'image/jpeg',
      };

  Future<String> uploadAndRegister({
    required int objectId,
    required Uint8List bytes,
    required String fileName,
    required String acquisition,
    required String procedure,
  }) async {
    final user = _client.auth.currentUser;
    final session = _client.auth.currentSession;
    if (user == null || session == null) {
      throw Exception('Sessione non valida per caricare l’immagine.');
    }
    if (bytes.isEmpty || bytes.length > maxBytes) {
      throw Exception('Immagine vuota o superiore a 10 MB.');
    }

    final safeName = safeFileName(fileName);
    final extension = extensionOf(safeName);
    if (!supportedExtensions.contains(extension)) {
      throw Exception('Formato non supportato. Usa JPG, PNG, WEBP, HEIC o HEIF.');
    }

    final path = '${user.id}/$objectId/${_uuid.v4()}.$extension';
    await _client.storage.from('pr01-foto-temporanee').uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: mimeTypeFor(extension),
        upsert: false,
      ),
    );

    final response = await _client.functions.invoke(
      'collection-object-images-test',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        'action': 'register',
        'codice_oggetto': objectId,
        'path': path,
        'file_name': safeName,
        'modalita_acquisizione': acquisition,
        'procedura_origine': procedure,
      },
    );

    if (response.status < 200 ||
        response.status >= 300 ||
        response.data is! Map) {
      throw Exception('Registrazione immagine non confermata: ${response.data}');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['ok'] != true) {
      throw Exception(data['error'] ?? 'Registrazione immagine non confermata.');
    }
    final signedUrl = (data['signed_url'] ?? '').toString();
    if (signedUrl.isEmpty) {
      throw Exception('Immagine registrata ma anteprima non disponibile.');
    }
    return signedUrl;
  }
}
