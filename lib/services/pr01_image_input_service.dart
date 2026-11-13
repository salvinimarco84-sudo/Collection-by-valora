import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

typedef Pr01GalleryPicker = Future<FilePickerResult?> Function();
typedef Pr01CameraPicker = Future<XFile?> Function();

/// Risultato validato dell'acquisizione di una foto per PR-01.
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

/// Acquisizione e validazione locale delle immagini PR-01.
/// Non esegue upload né scritture sul database.
class Pr01ImageInputService {
  const Pr01ImageInputService({
    Pr01GalleryPicker? galleryPicker,
    Pr01CameraPicker? cameraPicker,
  })  : _galleryPicker = galleryPicker ?? _pickGallery,
        _cameraPicker = cameraPicker ?? _captureCamera;

  static const int maxBytes = 10 * 1024 * 1024;
  static const Set<String> supportedExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif',
  };

  final Pr01GalleryPicker _galleryPicker;
  final Pr01CameraPicker _cameraPicker;

  static Future<FilePickerResult?> _pickGallery() {
    return FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
  }

  static Future<XFile?> _captureCamera() {
    return ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
  }

  Future<Pr01ImageSelection?> pickFromGallery() async {
    final picked = await _galleryPicker();
    if (picked == null || picked.files.isEmpty) return null;

    final file = picked.files.single;
    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';
    if (!supportedExtensions.contains(extension)) {
      throw Exception('Formato non supportato. Usa JPG, PNG, WEBP, HEIC o HEIF.');
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('Il file selezionato non contiene dati leggibili.');
    }
    _validateSize(bytes, 'L’immagine');
    return Pr01ImageSelection(
      bytes: bytes,
      fileName: file.name,
      acquisition: 'CARICAMENTO_FILE',
    );
  }

  Future<Pr01ImageSelection?> capturePhoto() async {
    final picked = await _cameraPicker();
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('La fotocamera non ha restituito un’immagine valida.');
    }
    _validateSize(bytes, 'La foto');
    return Pr01ImageSelection(
      bytes: bytes,
      fileName: picked.name.isNotEmpty ? picked.name : 'foto_valora.jpg',
      acquisition: 'FOTOCAMERA',
    );
  }

  static void _validateSize(Uint8List bytes, String label) {
    if (bytes.length > maxBytes) {
      throw Exception('$label supera il limite di 10 MB.');
    }
  }
}
