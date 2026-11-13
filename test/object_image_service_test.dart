import 'package:flutter_test/flutter_test.dart';
import 'package:collection_by_valora/services/object_image_service.dart';

void main() {
  group('ObjectImageService', () {
    test('normalizes file names without changing supported extensions', () {
      expect(
        ObjectImageService.safeFileName('foto oggetto #1.JPG'),
        'foto_oggetto__1_.JPG',
      );
      expect(ObjectImageService.extensionOf('foto oggetto.JPG'), 'jpg');
    });

    test('recognizes supported image formats only', () {
      for (final extension in ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif']) {
        expect(
          ObjectImageService.supportedExtensions.contains(extension),
          isTrue,
        );
      }
      expect(
        ObjectImageService.supportedExtensions.contains('gif'),
        isFalse,
      );
    });

    test('maps image extensions to upload MIME types', () {
      expect(ObjectImageService.mimeTypeFor('png'), 'image/png');
      expect(ObjectImageService.mimeTypeFor('webp'), 'image/webp');
      expect(ObjectImageService.mimeTypeFor('heic'), 'image/heic');
      expect(ObjectImageService.mimeTypeFor('heif'), 'image/heif');
      expect(ObjectImageService.mimeTypeFor('jpg'), 'image/jpeg');
    });

    test('enforces the ten megabyte upload limit', () {
      expect(ObjectImageService.maxBytes, 10 * 1024 * 1024);
    });
  });
}
