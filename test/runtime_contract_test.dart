import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:collection_by_valora/main.dart';

void main() {
  group('Contratto client COLLECTION by VALORA', () {
    test('i codici report UI sono tradotti nei codici API effettivi', () {
      expect(reportRuntimeCodes['REPORT-ACTIVE-LISTINGS'], 'ACTIVE_LISTINGS_REPORT');
      expect(reportRuntimeCodes['REPORT-CASH'], 'CASH_MOVEMENTS_REPORT');
      expect(reportRuntimeCodes['REPORT-HISTORY'], 'HISTORY_REPORT');
      expect(reportRuntimeCodes['REPORT-INVENTORY'], 'INVENTORY_SUMMARY_REPORT');
      expect(reportRuntimeCodes['REPORT-PURCHASES'], 'PURCHASES_REPORT');
      expect(reportRuntimeCodes['REPORT-SALES'], 'SALES_REPORT');
      expect(reportArgumentsTemplate('REPORT-INVENTORY')['destinazione'], 'COLLEZIONE');
      expect(reportArgumentsTemplate('REPORT-SALES')['data_da'], '2026-10-01');
      expect(reportArgumentsTemplate('REPORT-SALES')['data_a'], '2026-10-31');
    });

    test('le dieci procedure principali sono esposte', () {
      expect(procedureNames.keys, containsAll([
        'PR-01', 'PR-02', 'PR-03', 'PR-04', 'PR-05',
        'PR-06', 'PR-07', 'PR-08', 'PR-09', 'PR-10',
      ]));
    });

    test('le funzioni accessorie non diventano procedure autonome', () {
      expect(procedureNames.containsKey('GESTIONE PIATTAFORME'), isTrue);
      expect(procedureNames.containsKey('PR04-ACCORPA-COLLEZ'), isFalse);
      expect(templateFor('PR04-ACCORPA-COLLEZ'), isNotEmpty);
    });

    test('la maschera usa campi nativi e non un editor JSON operativo', () {
      final source = File('lib/main.dart').readAsStringSync();
      expect(source, contains('DynamicPayloadEditor'));
      expect(source, contains('showDatePicker'));
      expect(source, isNot(contains('TextField(controller: payload')));
      expect(source, contains('appendAnotherOperation'));
    });

    test('ogni procedura principale ha un template JSON a oggetto', () {
      for (final code in procedureNames.keys) {
        final template = templateFor(code);
        expect(template, isA<Map<String, dynamic>>(), reason: code);
        expect(template, isNotEmpty, reason: code);
      }
    });

    test('le fonti per i dati ufficiali contengono tutti i campi richiesti', () {
      for (final code in ['CMD-DATA-OUT', 'CMD-PRICE-OUT', 'CMD-DATE-PRICE-OUT']) {
        final template = templateFor(code);
        expect(template['fonti'], isA<List>(), reason: code);
      }
      final sourceEditorCode = File('lib/main.dart').readAsStringSync();
      expect(sourceEditorCode, contains("'estratto': ''"));
      expect(sourceEditorCode, contains("'tipo_fonte': 'PRODUTTORE_UFFICIALE'"));
      expect(sourceEditorCode, contains("'tipo_fonte' => ['PRODUTTORE_UFFICIALE', 'ARCHIVIO_UFFICIALE_PRODUTTORE']"));
    });

    test('le procedure data/prezzo di uscita operano su oggetti catalogati', () {
      for (final code in ['CMD-DATA-OUT', 'CMD-PRICE-OUT', 'CMD-DATE-PRICE-OUT']) {
        final template = templateFor(code);
        expect(template.containsKey('codice_oggetto'), isTrue, reason: code);
        expect(template.containsKey('fonti'), isTrue, reason: code);
        expect(template['fonti'], isA<List>(), reason: code);
      }
    });

    test('i template multi-record usano una lista operazioni o oggetti', () {
      for (final code in ['PR-01', 'PR-04', 'PR-05', 'PR-06', 'PR-07', 'PR-08', 'PR-09', 'PR-10', 'GESTIONE PIATTAFORME', 'PR04-ACCORPA-COLLEZ']) {
        final template = templateFor(code);
        expect(template.containsKey('operazioni') || template.containsKey('oggetti'), isTrue, reason: code);
      }
    });
  });
}
