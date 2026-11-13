import 'dart:typed_data';

import 'package:collection_by_valora/services/pr01_image_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('Pr01ImageManager', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    test('imports a supported gallery image and records its origin', () async {
      final manager = Pr01ImageManager(galleryPicker: () async => FilePickerResult([
        PlatformFile(name: 'foto.JPG', size: bytes.length, bytes: bytes),
      ]));
      final result = await manager.pickFromGallery();
      expect(result?.bytes, bytes);
      expect(result?.fileName, 'foto.JPG');
      expect(result?.acquisition, 'CARICAMENTO_FILE');
    });

    test('returns null when gallery selection is cancelled', () async {
      final manager = Pr01ImageManager(galleryPicker: () async => null);
      expect(await manager.pickFromGallery(), isNull);
    });

    test('rejects unsupported formats and unreadable files', () async {
      final unsupported = Pr01ImageManager(galleryPicker: () async => FilePickerResult([
        PlatformFile(name: 'foto.gif', size: bytes.length, bytes: bytes),
      ]));
      final unreadable = Pr01ImageManager(galleryPicker: () async => FilePickerResult([
        PlatformFile(name: 'foto.png', size: 0),
      ]));
      expect(() => unsupported.pickFromGallery(), throwsA(isA<Exception>()));
      expect(() => unreadable.pickFromGallery(), throwsA(isA<Exception>()));
    });

    test('captures a photo and records camera origin', () async {
      final manager = Pr01ImageManager(cameraPicker: () async => XFile.fromData(
        bytes, name: 'scatto.jpg', mimeType: 'image/jpeg',
      ));
      final result = await manager.capturePhoto();
      expect(result?.bytes, bytes);
      expect(result?.fileName, 'foto_valora.jpg');
      expect(result?.acquisition, 'FOTOCAMERA');
    });

    test('returns null when camera capture is cancelled', () async {
      final manager = Pr01ImageManager(cameraPicker: () async => null);
      expect(await manager.capturePhoto(), isNull);
    });

    test('enforces the ten megabyte limit', () async {
      final oversized = Uint8List(Pr01ImageManager.maxBytes + 1);
      final manager = Pr01ImageManager(galleryPicker: () async => FilePickerResult([
        PlatformFile(name: 'grande.png', size: oversized.length, bytes: oversized),
      ]));
      expect(() => manager.pickFromGallery(), throwsA(isA<Exception>()));
    });

    test('normalizes file names without changing supported extensions', () {
      expect(Pr01ImageManager.safeFileName('foto oggetto #1.JPG'), 'foto_oggetto_1.JPG');
      expect(Pr01ImageManager.extensionOf('foto oggetto.JPG'), 'jpg');
    });

    test('maps supported formats to upload and recognition MIME types', () {
      for (final extension in ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif']) {
        expect(Pr01ImageManager.supportedExtensions.contains(extension), isTrue);
      }
      expect(Pr01ImageManager.supportedExtensions.contains('gif'), isFalse);
      expect(Pr01ImageManager.mimeTypeFor('png'), 'image/png');
      expect(Pr01ImageManager.mimeTypeFor('webp'), 'image/webp');
      expect(Pr01ImageManager.mimeTypeFor('heic'), 'image/heic');
      expect(Pr01ImageManager.mimeTypeFor('heif'), 'image/heif');
      expect(Pr01ImageManager.mimeTypeFor('jpg'), 'image/jpeg');
      final manager = Pr01ImageManager();
      expect(manager.mimeTypeForFile('photo.JPG'), 'image/jpeg');
      expect(manager.mimeTypeForFile('photo.png'), 'image/png');
      expect(manager.mimeTypeForFile('photo.webp'), 'image/webp');
      expect(manager.mimeTypeForFile('photo.heic'), 'image/heic');
      expect(manager.mimeTypeForFile('photo.heif'), 'image/heif');
      expect(manager.mimeTypeForFile(null), 'image/jpeg');
    });
  });
}
