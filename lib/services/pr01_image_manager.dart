import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

typedef Pr01GalleryPicker = Future<FilePickerResult?> Function();
typedef Pr01CameraPicker = Future<XFile?> Function();

class Pr01ImageSelection {
  const Pr01ImageSelection({
    required this.bytes,
    required this.fileName,
    required this.acquisition,
  });
  final Uint8List bytes;
  final String fileName;
  final String acquisition;
}

/// Gestione unificata del ciclo immagine PR-01.
/// Include acquisizione, validazione, PR-12, upload/registrazione e recupero.
/// Le letture delle immagini esistenti non modificano il database.
class Pr01ImageManager {
  Pr01ImageManager({
    SupabaseClient? client,
    Uuid? uuid,
    Pr01GalleryPicker? galleryPicker,
    Pr01CameraPicker? cameraPicker,
  })  : _clientOverride = client,
        _uuid = uuid ?? const Uuid(),
        _galleryPicker = galleryPicker ?? _pickGallery,
        _cameraPicker = cameraPicker ?? _captureCamera;

  static const int maxBytes = 10 * 1024 * 1024;
  static const Set<String> supportedExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif',
  };

  final SupabaseClient? _clientOverride;
  final Uuid _uuid;
  final Pr01GalleryPicker _galleryPicker;
  final Pr01CameraPicker _cameraPicker;
  SupabaseClient get _client => _clientOverride ?? Supabase.instance.client;

  static Future<FilePickerResult?> _pickGallery() => FilePicker.platform.pickFiles(
    type: FileType.image, allowMultiple: false, withData: true,
  );

  static Future<XFile?> _captureCamera() => ImagePicker().pickImage(
    source: ImageSource.camera, imageQuality: 85, maxWidth: 2000, maxHeight: 2000,
  );

  Future<Pr01ImageSelection?> pickFromGallery() async {
    final picked = await _galleryPicker();
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.single;
    final extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
    if (!supportedExtensions.contains(extension)) {
      throw Exception('Formato non supportato. Usa JPG, PNG, WEBP, HEIC o HEIF.');
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Il file selezionato non contiene dati leggibili.');
    }
    _validateSize(bytes, 'L’immagine');
    return Pr01ImageSelection(bytes: bytes, fileName: file.name, acquisition: 'CARICAMENTO_FILE');
  }

  Future<Pr01ImageSelection?> capturePhoto() async {
    final picked = await _cameraPicker();
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) throw Exception('La fotocamera non ha restituito un’immagine valida.');
    _validateSize(bytes, 'La foto');
    return Pr01ImageSelection(
      bytes: bytes,
      fileName: picked.name.isNotEmpty ? picked.name : 'foto_valora.jpg',
      acquisition: 'FOTOCAMERA',
    );
  }

  static void _validateSize(Uint8List bytes, String label) {
    if (bytes.length > maxBytes) throw Exception('$label supera il limite di 10 MB.');
  }

  static String safeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');

  static String extensionOf(String fileName) {
    final safeName = safeFileName(fileName);
    return safeName.contains('.') ? safeName.split('.').last.toLowerCase() : 'jpg';
  }

  static String mimeTypeFor(String extension) => switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    _ => 'image/jpeg',
  };

  String mimeTypeForFile(String? fileName) {
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
    if (bytes.isEmpty) throw ArgumentError('Scatta prima una foto dell’oggetto.');
    final response = await _client.functions.invoke(
      'pr-12-engine-test',
      body: {
        'azione': 'ANALIZZA_FOTO',
        'modalita_ia': 'TEST',
        'image_data_url': 'data:${mimeTypeForFile(fileName)};base64,${base64Encode(bytes)}',
        'mercato': 'Italia',
      },
    );
    final data = response.data;
    if (data is! Map || data['ok'] != true) {
      throw Exception(data is Map
          ? (data['error'] ?? 'Riconoscimento non riuscito').toString()
          : 'Risposta PR-12 non valida');
    }
    return {
      'identificazione': data['identificazione'] is Map
          ? Map<String, dynamic>.from(data['identificazione'] as Map)
          : <String, dynamic>{},
      'risultati': data['risultati'] is List
          ? (data['risultati'] as List).whereType<Map>()
              .map((value) => Map<String, dynamic>.from(value)).toList()
          : <Map<String, dynamic>>[],
    };
  }

  Future<String> uploadAndRegister({
    required int objectId,
    required Uint8List bytes,
    required String fileName,
    required String acquisition,
    required String procedure,
  }) async {
    final client = _client;
    final user = client.auth.currentUser;
    final session = client.auth.currentSession;
    if (user == null || session == null) throw Exception('Sessione non valida per caricare l’immagine.');
    if (bytes.isEmpty || bytes.length > maxBytes) throw Exception('Immagine vuota o superiore a 10 MB.');
    final safeName = safeFileName(fileName);
    final extension = extensionOf(safeName);
    if (!supportedExtensions.contains(extension)) {
      throw Exception('Formato non supportato. Usa JPG, PNG, WEBP, HEIC o HEIF.');
    }
    final path = '${user.id}/$objectId/${_uuid.v4()}.$extension';
    await client.storage.from('pr01-foto-temporanee').uploadBinary(
      path, bytes,
      fileOptions: FileOptions(contentType: mimeTypeFor(extension), upsert: false),
    );
    final response = await client.functions.invoke(
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
    if (response.status < 200 || response.status >= 300 || response.data is! Map) {
      throw Exception('Registrazione immagine non confermata: ${response.data}');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['ok'] != true) throw Exception(data['error'] ?? 'Registrazione immagine non confermata.');
    final signedUrl = (data['signed_url'] ?? '').toString();
    if (signedUrl.isEmpty) throw Exception('Immagine registrata ma anteprima non disponibile.');
    return signedUrl;
  }

  Future<String?> loadExistingImage(int objectId) async {
    String? imageUrl;
    bool isHttpUrl(String value) => value.startsWith('https://') || value.startsWith('http://');

    // 1. Archivio immagini applicativo, privilegiando l'immagine principale.
    try {
      final rows = await _client.schema('collection').from('immagini_oggetto')
          .select('riferimento_immagine, url_fonte, tipo_immagine, immagine_principale, stato_verifica')
          .eq('codice_oggetto', objectId)
          .order('immagine_principale', ascending: false).limit(10);
      for (final row in rows) {
        final candidate = (row['riferimento_immagine'] ?? '').toString().trim();
        if (isHttpUrl(candidate)) { imageUrl = candidate; break; }
      }
    } catch (_) {
      // Continua con le fonti di fallback, sempre in sola lettura.
    }

    // 2. Endpoint immagini, per risolvere un percorso Storage in URL firmato.
    if (imageUrl == null) {
      try {
        final session = _client.auth.currentSession;
        if (session != null) {
          final response = await _client.functions.invoke(
            'collection-object-images-test',
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'action': 'get', 'codice_oggetto': objectId},
          );
          if (response.status >= 200 && response.status < 300 && response.data is Map) {
            final data = Map<String, dynamic>.from(response.data as Map);
            final signed = (data['signed_url'] ?? data['url'] ?? data['image_url'] ?? '').toString().trim();
            if (isHttpUrl(signed)) imageUrl = signed;
          }
        }
      } catch (_) {
        // Continua con i metadati catalografici.
      }
    }

    // 3. Fallback al campo immagine dei metadati PR-12.
    if (imageUrl == null) {
      try {
        final metadata = await _client.schema('collection').from('master_metadati')
            .select('url_immagine').eq('codice_oggetto', objectId).maybeSingle();
        final candidate = (metadata?['url_immagine'] ?? '').toString().trim();
        if (isHttpUrl(candidate)) imageUrl = candidate;
      } catch (_) {
        // Nessuna scrittura: l'immagine semplicemente non è disponibile.
      }
    }
    return imageUrl;
  }
}
