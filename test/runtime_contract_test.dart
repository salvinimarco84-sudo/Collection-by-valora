import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();
  final pr19Source = File('supabase/functions/pr-19-object-valuation-test/index.ts').readAsStringSync();

  group('Contratti di regressione COLLECTION by VALORA', () {
    test('la scheda oggetto espone modifica e avvio vendita', () {
      expect(source, contains("label: const Text('MODIFICA OGGETTO'"));
      expect(source, contains("label: const Text('METTI IN VENDITA'"));
      expect(source, contains('Future<void> _openObjectForEdit()'));
      expect(source, contains('Future<void> _putObjectForSale()'));
      expect(source, contains('class NewSalePage'));
      expect(source, contains('NewSalePage(initialObjectCode: id)'));
      expect(source, contains('final int? initialObjectCode;'));
    });

    test('PR-02 accumula le modifiche fino alla risposta finale e mantiene separata la categoria', () {
      expect(source, contains('_selectedCollectionCategory'));
      expect(source, contains('categoria_collezione_selezionata'));
      expect(source, contains('_pr02AwaitingNextChoice'));
      expect(source, contains('_continuePr02WithAnotherObject()'));
      expect(source, contains('await _savePr02PendingChanges();'));
      expect(source, contains('Future<void> _savePr02PendingChanges({bool closeOnComplete = true})'));
      expect(source, contains('oggetto_collezione_categoria'));
    });

    test('PR-01 usa PR-12, valuta con PR-19 e conferma prima del salvataggio', () {
      expect(source, contains('_pr01PendingObjects.add({'));
      expect(source, contains('await _savePr01PendingObjects();'));
      expect(source, contains('Future<void> _savePr01PendingObjects() async'));
      expect(source, contains('_searchPr12ForPr01()'));
      expect(source, contains('pr-12-web-search-corrected-test'));
      expect(source, contains('pr-19-object-valuation-test'));
      expect(source, contains('CONFERMA OGGETTO E VALORE'));
      expect(source, contains('SÌ, NUOVO OGGETTO'));
      expect(source, contains('NO, TERMINA E SALVA'));
      expect(source, contains('Seleziona una categoria COLLEZIONE valida.'));
    });

    test('PR-01 non inventa stime e mantiene la valutazione separata dal salvataggio', () {
      expect(pr19Source, contains('scrittura_database: false'));
      expect(source, contains("'valore_mercato': marketValue"));
      expect(source, contains("'valore_mercato': _marketValue.text.trim().isEmpty ? null"));
      expect(source, contains("_merchCategoryCodeForCollection(_selectedCollectionCategory)"));
      expect(source, isNot(contains("'codice_categoria_collezione': _selectedCollectionCategory")));
      expect(source, contains('Nessun valore inventato'));
      expect(source, contains('_pr19ValuationResult'));
    });

    test('PR-01 e PR-02 usano una fonte categoria ammessa dal vincolo SQL', () {
      expect(source, contains("'fonte_assegnazione': 'MANUALE'"));
      expect(source, isNot(contains("'fonte_assegnazione': 'UTENTE_PR01'")));
      expect(source, isNot(contains("'fonte_assegnazione': 'UTENTE_PR02'")));
    });

    test('Visualizza scheda cerca anche il codice numerico direttamente nel master', () {
      expect(source, contains(".from('master_oggetti')"));
      expect(source, contains(".eq('codice_oggetto', exactCode)"));
      expect(source, contains('codeOf(item) == phrase.trim()'));
    });

    test('PR-02 conferma in linea senza dialoghi o chiamate preview/review intermedie', () {
      final start = source.indexOf('Future<void> _confirmPr02Changes() async {');
      final end = source.indexOf('Future<void> _continuePr02WithAnotherObject()', start);
      expect(start, isNonNegative);
      expect(end, greaterThan(start));
      final confirmFlow = source.substring(start, end);
      expect(confirmFlow, contains('_pr02PendingChanges.add'));
      expect(confirmFlow, contains('_pr02AwaitingNextChoice = true'));
      expect(confirmFlow, isNot(contains('showDialog')));
      expect(confirmFlow, isNot(contains('await _preview()')));
      expect(confirmFlow, isNot(contains('await _confirmData()')));
    });

    test('PR-12 mantiene la ricerca multi-fonte a lotti', () {
      expect(source, contains('_loadIncompleteMetadataCatalog'));
      expect(source, contains('_runPr12AiBatch'));
      expect(source, contains('LOTTO DA 10'));
      expect(source, contains('RIPROVA I PROSSIMI 10 IRRISOLTI'));
    });

    test('la consultazione inserzioni attive ha un codice dedicato', () {
      expect(source, contains("apiCode: 'REPORT-SALES-ACTIVE'"));
    });

    test('le procedure di base e i controlli di blocco sono presenti', () {
      for (final code in ['PR-01', 'PR-02', 'PR-03', 'PR-12']) {
        expect(source, contains("'$code'"), reason: code);
      }
      expect(source, contains('Future<void> _acquireLock()'));
      expect(source, contains('Future<void> _releaseLock()'));
      expect(source, contains("result['scrittura_eseguita'] != true"));
    });

    test('il client punta al progetto TEST e non contiene l’ID produzione noto', () {
      expect(source, contains('eeiekkflpnkummxtvljy'));
      expect(source, isNot(contains('bufwceckrmbocctarthj')));
    });
  });
}
