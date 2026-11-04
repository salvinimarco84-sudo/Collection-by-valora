import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  group('Contratti di regressione COLLECTION by VALORA', () {
    test('le cartelle degli sfondi e dei temi restano incluse nel bundle', () {
      final manifest = File('pubspec.yaml').readAsStringSync();
      expect(manifest, contains('assets/patrimony_sections/'));
      expect(manifest, contains('assets/menu_sections/'));
      expect(manifest, contains('assets/themes/'));
      expect(Directory('assets/patrimony_sections').existsSync(), isTrue);
      expect(Directory('assets/menu_sections').existsSync(), isTrue);
      expect(Directory('assets/themes').existsSync(), isTrue);
    });

    test('PR-04 consente di inserire e salvare le note del singolo oggetto', () {
      final draftStart = source.indexOf('class _PurchaseItemDraft');
      final draftEnd = source.indexOf('/// PR-04:', draftStart);
      expect(draftStart, isNonNegative);
      expect(draftEnd, greaterThan(draftStart));
      final draft = source.substring(draftStart, draftEnd);
      expect(draft, contains('final notes = TextEditingController();'));
      expect(draft, contains("'note': notes.text.trim()"));
      expect(draft, contains('notes.dispose()'));

      final purchaseStart = source.indexOf('class NewPurchasePage');
      final purchaseEnd = source.indexOf('class EditPurchasePage', purchaseStart);
      expect(purchaseStart, isNonNegative);
      expect(purchaseEnd, greaterThan(purchaseStart));
      final purchase = source.substring(purchaseStart, purchaseEnd);
      expect(purchase, contains('TextField(controller: item.notes'));
      expect(purchase, contains("labelText: 'Note dell’oggetto (facoltative)'"));
      expect(purchase, contains("_items[i].notes.text.trim()"));
    });

    test('Report acquisti mostra il dettaglio leggibile degli oggetti', () {
      expect(source, contains('Future<void> _showPurchaseReportDetail(Map<String, dynamic> item)'));
      expect(source, contains("from('acquisti_oggetti')"));
      expect(source, contains("from('master_oggetti')"));
      expect(source, contains("'OGGETTI ACQUISTATI'"));
    });

    test('PR-02 carica le categorie COLLEZIONE e salva la nuova assegnazione', () {
      final initStart = source.indexOf('void initState()');
      final initEnd = source.indexOf('Future<void> _loadCollectionCategories()', initStart);
      expect(initStart, isNonNegative);
      expect(initEnd, greaterThan(initStart));
      final init = source.substring(initStart, initEnd);
      expect(init, contains("widget.apiCode == 'PR-02'"));
      expect(init, contains('_loadCollectionCategories()'));

      final saveStart = source.indexOf('Future<void> _savePr02PendingChanges(');
      final saveEnd = source.indexOf('Future<void> _confirmAndSaveNewObject()', saveStart);
      expect(saveStart, isNonNegative);
      expect(saveEnd, greaterThan(saveStart));
      final save = source.substring(saveStart, saveEnd);
      expect(save, contains("from('oggetto_collezione_categoria').upsert"));
      expect(save, contains("'codice_categoria': categoryCode"));
      expect(save, contains("'fonte_assegnazione': 'MANUALE'"));
    });

    test('OBJECT_MASTER carica le categorie per mostrare quella già assegnata', () {
      final initStart = source.indexOf('void initState()');
      final initEnd = source.indexOf('Future<void> _loadCollectionCategories()', initStart);
      expect(initStart, isNonNegative);
      expect(initEnd, greaterThan(initStart));
      final init = source.substring(initStart, initEnd);
      expect(init, contains("widget.apiCode == 'PR-01' || widget.apiCode == 'OBJECT_MASTER'"));
      expect(init, contains('_loadCollectionCategories();'));
    });

    test('PR-04 persiste la categoria selezionata sull’oggetto acquistato', () {
      final migration = File('supabase/migrations/20261104100000_pr04_persist_collection_category.sql').readAsStringSync();
      expect(migration, contains('codice_categoria_collezione'));
      expect(migration, contains('INSERT INTO collection.oggetto_collezione_categoria'));
      expect(migration, contains('ON CONFLICT (codice_oggetto) DO UPDATE'));
      expect(migration, contains('categoria COLLEZIONE mancante o non valida'));
    });

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

    test('PR-01 accoda gli oggetti e salva il blocco solo dopo la scelta finale', () {
      expect(source, contains('_pr01PendingObjects.add({'));
      expect(source, contains('await _savePr01PendingObjects();'));
      expect(source, contains('NO, SALVA IL BLOCCO'));
      expect(source, contains('Future<void> _savePr01PendingObjects() async'));
      expect(source, contains('Seleziona una categoria COLLEZIONE valida.'));
      expect(source, contains('Seleziona una categoria COLLEZIONE valida.'));
    });

    test('PR-01 e PR-02 usano una fonte categoria ammessa dal vincolo SQL', () {
      expect(source, contains("'fonte_assegnazione': 'MANUALE'"));
      expect(source, isNot(contains("'fonte_assegnazione': 'UTENTE_PR01'")));
      expect(source, isNot(contains("'fonte_assegnazione': 'UTENTE_PR02'")));
    });

    test('Visualizza scheda risolve l’immagine usando url_fonte e non il nome file', () {
      expect(source, contains("select('riferimento_immagine, url_fonte, tipo_immagine, immagine_principale, stato_verifica')"));
      expect(source, contains("row['riferimento_immagine']"));
      expect(source, contains("body: {'action':'get','codice_oggetto':objectId}"));
    });

    test('Visualizza scheda mostra il prezzo di acquisto associato all’oggetto', () {
      expect(source, contains(".from('acquisti_oggetti')"));
      expect(source, contains("'valore_acquisto_oggetto'"));
      expect(source, contains("m['prezzo_acquisto'] = purchase['valore_acquisto_oggetto']"));
      expect(source, contains("hasPurchasePrice ? 'Prezzo di acquisto' : 'Valore registrato'"));
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
      expect(source, contains('REPORT-ACTIVE-LISTINGS'));
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
