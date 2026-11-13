import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection_by_valora/services/pr01_image_input_service.dart';

void main() {
  group('Pr01ImageInputService', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    test('imports a supported gallery image and records its origin', () async {
      final service = Pr01ImageInputService(
        galleryPicker: () async => FilePickerResult([
          PlatformFile(name: 'foto.JPG', size: bytes.length, bytes: bytes),
        ]),
      );

      final result = await service.pickFromGallery();

      expect(result?.bytes, bytes);
      expect(result?.fileName, 'foto.JPG');
      expect(result?.acquisition, 'CARICAMENTO_FILE');
    });

    test('returns null when the gallery is cancelled', () async {
      final service = Pr01ImageInputService(
        galleryPicker: () async => null,
      );

      expect(await service.pickFromGallery(), isNull);
    });

    test('rejects unsupported gallery formats', () async {
      final service = Pr01ImageInputService(
        galleryPicker: () async => FilePickerResult([
          PlatformFile(name: 'foto.gif', size: bytes.length, bytes: bytes),
        ]),
      );

      expect(
        () => service.pickFromGallery(),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects gallery files without readable bytes', () async {
      final service = Pr01ImageInputService(
        galleryPicker: () async => FilePickerResult([
          PlatformFile(name: 'foto.png', size: 0),
        ]),
      );

      expect(
        () => service.pickFromGallery(),
        throwsA(isA<Exception>()),
      );
    });

    test('captures a photo and records camera origin', () async {
      final service = Pr01ImageInputService(
        cameraPicker: () async => XFile.fromData(
          bytes,
          name: 'scatto.jpg',
          mimeType: 'image/jpeg',
        ),
      );

      final result = await service.capturePhoto();

      expect(result?.bytes, bytes);
      expect(result?.fileName, 'scatto.jpg');
      expect(result?.acquisition, 'FOTOCAMERA');
    });

    test('returns null when camera capture is cancelled', () async {
      final service = Pr01ImageInputService(
        cameraPicker: () async => null,
      );

      expect(await service.capturePhoto(), isNull);
    });

    test('enforces the ten megabyte limit', () async {
      final oversized = Uint8List(Pr01ImageInputService.maxBytes + 1);
      final service = Pr01ImageInputService(
        galleryPicker: () async => FilePickerResult([
          PlatformFile(
            name: 'grande.png',
            size: oversized.length,
            bytes: oversized,
          ),
        ]),
      );

      expect(
        () => service.pickFromGallery(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
