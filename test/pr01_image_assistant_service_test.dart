import 'package:flutter_test/flutter_test.dart';
import 'package:collection_by_valora/services/pr01_image_assistant_service.dart';

void main() {
  group('Pr01ImageAssistantService', () {
    const service = Pr01ImageAssistantService();

    test('maps supported image extensions to MIME types', () {
      expect(service.mimeTypeFor('photo.JPG'), 'image/jpeg');
      expect(service.mimeTypeFor('photo.png'), 'image/png');
      expect(service.mimeTypeFor('photo.webp'), 'image/webp');
      expect(service.mimeTypeFor('photo.heic'), 'image/heic');
      expect(service.mimeTypeFor('photo.heif'), 'image/heif');
      expect(service.mimeTypeFor(null), 'image/jpeg');
    });
  });
}
