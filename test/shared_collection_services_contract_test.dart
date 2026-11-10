import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final imageProxy = File('lib/services/collection_image_proxy.dart').readAsStringSync();
  final runtimeApi = File('lib/services/collection_procedure_runtime_api.dart').readAsStringSync();

  group('Servizi condivisi VALORA e catalogo', () {
    test('il proxy immagini è estratto senza perdere i domini supportati', () {
      expect(mainSource, contains("part 'services/collection_image_proxy.dart';"));
      expect(mainSource, isNot(contains('String _valoraImageProxyUrl(String rawUrl)')));
      expect(imageProxy, contains("part of '../main.dart';"));
      expect(imageProxy, contains("uri.scheme != 'https'"));
      expect(imageProxy, contains("proxyHosts.contains(uri.host.toLowerCase())"));
      expect(imageProxy, contains("collection-image-proxy?url="));
      expect(imageProxy, contains("Uri.encodeComponent(value)"));
      for (final host in [
        'bandai-a.akamaihd.net',
        'www.lego.com',
        'i.ebayimg.com',
        'funko.com',
        'www.hasbro.com',
        'cdn.shopify.com',
      ]) {
        expect(imageProxy, contains("'$host'"));
      }
      expect(RegExp(r'_valoraImageProxyUrl\(').allMatches(mainSource).length, greaterThanOrEqualTo(5));
    });

    test('il runtime procedure resta unico e condiviso tra le procedure', () {
      expect(mainSource, contains("part 'services/collection_procedure_runtime_api.dart';"));
      expect(mainSource, isNot(contains('class _ValoraRuntimeApi')));
      expect(runtimeApi, contains("part of '../main.dart';"));
      expect(runtimeApi, contains("class _ValoraRuntimeApi"));
      expect(runtimeApi, contains("'collection-procedure-runtime-test'"));
      expect(runtimeApi, contains("'action': action"));
      expect(runtimeApi, contains("'procedure': code"));
      expect(runtimeApi, contains("'step': step"));
      expect(runtimeApi, contains("'session_id': sessionId"));
      expect(runtimeApi, contains("'request_id': requestId"));
      expect(runtimeApi, contains("response.status >= 400"));
      expect(runtimeApi, contains("map['result'] is Map"));
      expect(RegExp(r'_ValoraRuntimeApi\.(call|procedure)\(').allMatches(mainSource).length, greaterThan(10));
      expect(mainSource, contains("widget.apiCode == 'PR-01'"));
      expect(mainSource, contains("'PR-02', 'preview'"));
      expect(mainSource, contains("'PR-03'"));
    });
  });
}
