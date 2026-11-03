import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();

  group('Contratti di regressione COLLECTION by VALORA', () {
    test('RICERCHE e VALUTAZIONI mantengono colori coerenti su dashboard e menu', () {
      expect(source, contains("'VALUTAZIONI': Color(0xFFFFD54F)"));
      expect(source, contains("'RICERCHE': Color(0xFF35C7E8)"));
      expect(source, contains("color: Color(0xFFFFD54F)"));
      expect(source, contains("color: Color(0xFF35C7E8)"));
      expect(source, contains("for (final k in const ['RICERCHE', 'VALUTAZIONI'])"));
      expect(source, contains('alignment: Alignment.center'));\n      expect(source, isNot(contains('scale: 1.20')));\n      expect(source, isNot(contains('Alignment(0, 0.18)')));
      final sectionStart = source.indexOf('  Widget buildSection(DashboardSection section) {');
      final sectionEnd = source.indexOf('  void showProcedureInfo(ProcedureEntry procedure) {', sectionStart);
      expect(sectionStart, isNonNegative);
      expect(sectionEnd, greaterThan(sectionStart));
      final sectionLayout = source.substring(sectionStart, sectionEnd);
      // Il titolo e la descrizione della sezione sono già incorporati negli asset:
      // non devono essere duplicati sopra lo sfondo. Le icone restano sulle singole procedure.
      expect(sectionLayout, contains('Colors.black.withValues(alpha: 0.16)'));
      expect(sectionLayout, isNot(contains('ColoredBox(color: Color(0xFF101010))')));
      expect(sectionLayout, isNot(contains('Image.network(')));
      expect(sectionLayout, isNot(contains('Text(section.title')));
      expect(sectionLayout, isNot(contains('ValoraI18n.tr(section.description)')));
      expect(sectionLayout, contains('CircleAvatar('));
      expect(sectionLayout, contains('sectionTint.withValues(alpha: 0.17)'));
      expect(sectionLayout, contains('contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2)'));
      expect(sectionLayout, contains('procedure.description'));
    });

    test('i sei menu usano esclusivamente i sei asset approvati', () {
      const assets = <String>[
        'assets/menu_sections/01_VENDITE.jpg',
        'assets/menu_sections/02_ACQUISTI.jpg',
        'assets/menu_sections/05_CATALOGO.jpg',
        'assets/menu_sections/06_REPORT.jpg',
        'assets/menu_sections/VALORA_RICERCHE_CELESTE.jpg',
        'assets/menu_sections/VALORA_VALUTAZIONI_GIALLO.jpg',
      ];
      for (final asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: 'Asset mancante: $asset');
        expect(source, contains(asset));
      }
      expect(source, contains("'CATALOGO' => 'assets/menu_sections/05_CATALOGO.jpg'"));
      expect(source, contains("'ACQUISTI' => 'assets/menu_sections/02_ACQUISTI.jpg'"));
      expect(source, contains("'VENDITE' || 'VENDITE E INSERZIONI' => 'assets/menu_sections/01_VENDITE.jpg'"));
      expect(source, contains("'REPORT' => 'assets/menu_sections/06_REPORT.jpg'"));
      expect(source, contains("'RICERCHE' => 'assets/menu_sections/VALORA_RICERCHE_CELESTE.jpg'"));
      expect(source, contains("'VALUTAZIONI' => 'assets/menu_sections/VALORA_VALUTAZIONI_GIALLO.jpg'"));
      expect(source, isNot(contains('assets/menu_sections/01_collezione_personale.png')));
      expect(source, isNot(contains('assets/menu_sections/03_RICERCHE.jpg')));
      expect(source, isNot(contains('assets/menu_sections/04_VALUTAZIONI.jpg')));
    });

    test('la dashboard principale usa lo sfondo dinamico dei dieci temi', () {
      expect(source, contains('if (selectedSection == null && !showCollection)'));
      expect(source, contains('_valoraThemeAsset(ValoraAppearance.instance.selectedThemeId)'));
      const themeAssets = <String>[
        'assets/themes/industrial.jpg',
        'assets/themes/electric_green.jpg',
        'assets/themes/black_gold.jpg',
        'assets/themes/comic_style.jpg',
        'assets/themes/midnight_blue.jpg',
        'assets/themes/fire_red.jpg',
        'assets/themes/pastel.jpg',
        'assets/themes/minimal_zen.jpg',
        'assets/themes/royal_purple.jpg',
        'assets/themes/silver_light.jpg',
      ];
      for (final asset in themeAssets) {
        expect(File(asset).existsSync(), isTrue, reason: 'Sfondo tema mancante: $asset');
        expect(source, contains(asset));
      }
    });

    test('la scheda patrimoniale conserva banner, copertura valutazioni e costi', () {
      expect(source, contains('assets/patrimony_sections/banner_riepilogo_patrimoniale.jpg'));
      expect(File('assets/patrimony_sections/banner_riepilogo_patrimoniale.jpg').existsSync(), isTrue);
      expect(source, contains('Copertura delle valutazioni'));
      expect(source, contains('collectionValuationCoverage'));
      expect(source, contains('Copertura dei costi di acquisto'));
      expect(source, contains('acquisitionCoverage'));
      expect(source, contains('collectionCostCoverage + resaleCostCoverage'));
      expect(source, contains('collectionMarket + resaleKnownCost'));
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
