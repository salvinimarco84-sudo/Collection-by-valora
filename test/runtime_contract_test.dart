import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  group('Contratti del sorgente VALORA', () {
    test('il selettore lingua include tutte le nove lingue previste', () {
      expect(source, contains("supportedCodes = <String>['it','en','fr','de','es','pt','zh','ja','ru']"));
      for (final language in [
        "'Italiano':'it'",
        "'English':'en'",
        "'Français':'fr'",
        "'Deutsch':'de'",
        "'Español':'es'",
        "'Português':'pt'",
        "'中文 (简体)':'zh'",
        "'日本語':'ja'",
        "'Русский':'ru'",
      ]) {
        expect(source, contains(language), reason: language);
      }
    });

    test('il confronto del valore ha una funzione isolata e testabile', () {
      expect(source, contains('class CollectionValueComparison'));
      expect(source, contains('CollectionValueComparison calculateCollectionValueComparison'));
      expect(source, contains('currentValues: currentValues'));
      expect(source, contains('previousValues: previousValues'));
    });

    test('il totale collezione usa solo oggetti attivi presenti nella valutazione', () {
      expect(source, contains("eq('destinazione', 'COLLEZIONE')"));
      expect(source, contains("neq('archiviato_test', true)"));
      expect(source, contains("if (quantities.containsKey(objectId))"));
      expect(source, contains("!['VENDUTO','PERSO','DISTRUTTO','USCITO','ACCORPATO']"));
    });

    test('la schermata valore collezione espone il pulsante di calcolo manuale', () {
      expect(source, contains("label: const Text('CALCOLA VALORE COLLEZIONE')"));
      expect(source, contains('onPressed: _loading ? null : _load'));
      expect(source, isNot(contains(".eq('stato_stima','VALIDA')")));
    });

    test('il caricamento delle preferenze non blocca da solo l’avvio', () {
      expect(source, contains('VALORA appearance preferences could not be loaded'));
      expect(source, contains('await ValoraAppearance.instance.load();'));
    });
  });
}
