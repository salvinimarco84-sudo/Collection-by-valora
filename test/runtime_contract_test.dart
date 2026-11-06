import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();
  final themeSource = File('lib/themes/valora_theme.dart').readAsStringSync();
  final procedureCardSource = File('lib/procedures/procedure_card.dart').readAsStringSync();
  final dashboardBackgroundSource = File('lib/dashboard/dashboard_section_background.dart').readAsStringSync();
  final dashboardHeaderSource = File('lib/dashboard/dashboard_section_header.dart').readAsStringSync();
  final dashboardFooterSource = File('lib/dashboard/dashboard_section_footer.dart').readAsStringSync();
  final dashboardMenuCardSource = File('lib/dashboard/dashboard_menu_card.dart').readAsStringSync();
  final dashboardGridMenuCardSource = File('lib/dashboard/dashboard_grid_menu_card.dart').readAsStringSync();
  final dashboardOverlaySource = File('lib/dashboard/dashboard_section_overlay.dart').readAsStringSync();
  final dashboardCollectionCategoryCardSource = File('lib/dashboard/dashboard_collection_category_card.dart').readAsStringSync();
  final dashboardCollectionHeaderSource = File('lib/dashboard/dashboard_collection_header.dart').readAsStringSync();
  final dashboardHomeHeaderSource = File('lib/dashboard/dashboard_home_header.dart').readAsStringSync();
  final dashboardHomeFooterSource = File('lib/dashboard/dashboard_home_footer.dart').readAsStringSync();
  final dashboardCollectionErrorBannerSource = File('lib/dashboard/dashboard_collection_error_banner.dart').readAsStringSync();
  final dashboardCollectionEmptyNoticeSource = File('lib/dashboard/dashboard_collection_empty_notice.dart').readAsStringSync();
  final dashboardCategoryBrandMarkSource = File('lib/dashboard/dashboard_category_brand_mark.dart').readAsStringSync();
  final dashboardCategoryObjectPreviewSource = File('lib/dashboard/dashboard_category_object_preview.dart').readAsStringSync();

  group('Contratti di regressione COLLECTION by VALORA', () {
    test('il velo di contrasto della sezione mantiene overlay e non intercetta i tocchi', () {
      expect(dashboardOverlaySource, contains('class DashboardSectionOverlay extends StatelessWidget'));
      expect(dashboardOverlaySource, contains('IgnorePointer('));
      expect(dashboardOverlaySource, contains('Color.fromRGBO(0, 0, 0, 0.22)'));
      expect(source, contains('const Positioned.fill(child: DashboardSectionOverlay())'));
    });

    test('la card a blocchi della dashboard conserva immagine, colori, conteggio e navigazione', () {
      expect(dashboardGridMenuCardSource, contains('class DashboardGridMenuCard extends StatelessWidget'));
      expect(dashboardGridMenuCardSource, contains('Image.network('));
      expect(dashboardGridMenuCardSource, contains('errorBuilder'));
      expect(dashboardGridMenuCardSource, contains('imageFit'));
      expect(dashboardGridMenuCardSource, contains('footerText'));
      expect(dashboardGridMenuCardSource, contains('onTap: onTap'));
      expect(source, contains("import 'dashboard/dashboard_grid_menu_card.dart';"));
      expect(source, contains('return DashboardGridMenuCard('));
      expect(source, contains('imageUrl: url == null ? null : _valoraImageProxyUrl(url)'));
    });

    test('la card del menu dashboard conserva immagini, colori e navigazione', () {
      expect(dashboardMenuCardSource, contains('class DashboardMenuCard extends StatelessWidget'));
      expect(dashboardMenuCardSource, contains('Image.network('));
      expect(dashboardMenuCardSource, contains('errorBuilder'));
      expect(dashboardMenuCardSource, contains('color.withValues(alpha: 0.85)'));
      expect(dashboardMenuCardSource, contains('onTap: onTap'));
      expect(dashboardMenuCardSource, contains('trailingText'));
      expect(source, contains("import 'dashboard/dashboard_menu_card.dart';"));
      expect(source, contains('return DashboardMenuCard('));
      expect(source, contains('imageUrl: imageUrl'));
    });

    test('l’anteprima oggetto categoria conserva immagini, fallback, dimensioni e navigazione', () {
      expect(dashboardCategoryObjectPreviewSource, contains('class DashboardCategoryObjectPreview extends StatelessWidget'));
      expect(dashboardCategoryObjectPreviewSource, contains('Image.network('));
      expect(dashboardCategoryObjectPreviewSource, contains('errorBuilder'));
      expect(dashboardCategoryObjectPreviewSource, contains('BoxFit.contain'));
      expect(dashboardCategoryObjectPreviewSource, contains('width: 98'));
      expect(dashboardCategoryObjectPreviewSource, contains('height: 75'));
      expect(dashboardCategoryObjectPreviewSource, contains('onTap: onTap'));
      expect(source, contains("import 'dashboard/dashboard_category_object_preview.dart';"));
      expect(source, contains('DashboardCategoryObjectPreview('));
    });

    test('il marchio grafico categoria conserva i loghi e lo stile delle collezioni', () {
      expect(dashboardCategoryBrandMarkSource, contains('class DashboardCategoryBrandMark extends StatelessWidget'));
      expect(dashboardCategoryBrandMarkSource, contains("base == 'LEGO'"));
      expect(dashboardCategoryBrandMarkSource, contains("base == 'TRANSFORMERS'"));
      expect(dashboardCategoryBrandMarkSource, contains("base == 'GUNDAM'"));
      expect(dashboardCategoryBrandMarkSource, contains("base == 'FUMETTI'"));
      expect(dashboardCategoryBrandMarkSource, contains("base == 'SAINT SEIYA'"));
      expect(dashboardCategoryBrandMarkSource, contains("base == 'MOTO DIE-CAST'"));
      expect(dashboardCategoryBrandMarkSource, contains('fallbackIcon'));
      expect(source, contains("import 'dashboard/dashboard_category_brand_mark.dart';"));
      expect(source, contains('DashboardCategoryBrandMark(category: category, color: color, fallbackIcon: icon)'));
    });

    test('l’avviso categorie vuote conserva padding e stile del testo', () {
      expect(dashboardCollectionEmptyNoticeSource, contains('class DashboardCollectionEmptyNotice extends StatelessWidget'));
      expect(dashboardCollectionEmptyNoticeSource, contains('EdgeInsets.all(12)'));
      expect(dashboardCollectionEmptyNoticeSource, contains('Nessuna categoria configurata nel master.'));
      expect(dashboardCollectionEmptyNoticeSource, contains('Colors.white70'));
      expect(source, contains("import 'dashboard/dashboard_collection_empty_notice.dart';"));
      expect(source, contains('const DashboardCollectionEmptyNotice()'));
    });

    test('il banner errore catalogo mantiene sfondo, margini e testo leggibile', () {
      expect(dashboardCollectionErrorBannerSource, contains('class DashboardCollectionErrorBanner extends StatelessWidget'));
      expect(dashboardCollectionErrorBannerSource, contains('Color(0xFF3B1717)'));
      expect(dashboardCollectionErrorBannerSource, contains('BorderRadius.circular(10)'));
      expect(dashboardCollectionErrorBannerSource, contains('Colors.white'));
      expect(source, contains("import 'dashboard/dashboard_collection_error_banner.dart';"));
      expect(source, contains('DashboardCollectionErrorBanner(message:'));
    });

    test('il footer dashboard mantiene marchio, colore e allineamento', () {
      expect(dashboardHomeFooterSource, contains('class DashboardHomeFooter extends StatelessWidget'));
      expect(dashboardHomeFooterSource, contains("'COLLECTION by VALORA'"));
      expect(dashboardHomeFooterSource, contains('Colors.white38'));
      expect(dashboardHomeFooterSource, contains('letterSpacing: 1'));
      expect(source, contains("import 'dashboard/dashboard_home_footer.dart';"));
      expect(source, contains('const DashboardHomeFooter()'));
    });

    test('l’intestazione dashboard mantiene titolo e descrizione nella vista lista', () {
      expect(dashboardHomeHeaderSource, contains('class DashboardHomeHeader extends StatelessWidget'));
      expect(dashboardHomeHeaderSource, contains('letterSpacing: 1.3'));
      expect(dashboardHomeHeaderSource, contains('Colors.white70'));
      expect(source, contains("import 'dashboard/dashboard_home_header.dart';"));
      expect(source, contains('DashboardHomeHeader('));
      expect(source, contains("title: ValoraI18n.tr('CENTRO OPERATIVO')"));
      expect(source, contains("subtitle: ValoraI18n.tr('Scegli una sezione per accedere alle relative funzioni.')"));
    });

    test('l’intestazione della collezione mantiene titolo, descrizione e conteggio', () {
      expect(dashboardCollectionHeaderSource, contains('class DashboardCollectionHeader extends StatelessWidget'));
      expect(dashboardCollectionHeaderSource, contains('Icons.inventory_2_outlined'));
      expect(dashboardCollectionHeaderSource, contains('countLabel'));
      expect(source, contains("import 'dashboard/dashboard_collection_header.dart';"));
      expect(source, contains('DashboardCollectionHeader('));
      expect(source, contains("title: ValoraI18n.tr('COLLEZIONE')"));
    });

    test('la card categoria collezione mantiene logo, conteggio, anteprime e navigazione', () {
      expect(dashboardCollectionCategoryCardSource, contains('class DashboardCollectionCategoryCard extends StatelessWidget'));
      expect(dashboardCollectionCategoryCardSource, contains('previewImageUrls'));
      expect(dashboardCollectionCategoryCardSource, contains('Image.network('));
      expect(dashboardCollectionCategoryCardSource, contains('errorBuilder'));
      expect(dashboardCollectionCategoryCardSource, contains('onTap: onTap'));
      expect(dashboardCollectionCategoryCardSource, contains('LEGO'));
      expect(dashboardCollectionCategoryCardSource, contains('TRANSFORMERS'));
      expect(source, contains("import 'dashboard/dashboard_collection_category_card.dart';"));
      expect(source, contains('return DashboardCollectionCategoryCard('));
      expect(source, contains('initialCategoryCode: code'));
    });

    test('le immagini Rebrickable e Bits and Blocks passano dal proxy', () {
      expect(source, contains("'cdn.rebrickable.com'"));
      expect(source, contains("'bits-and-blocks.co.uk'"));
      expect(source, contains("'www.brickeconomy.com'"));
      expect(source, contains("functions/v1/collection-image-proxy"));
    });

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
      expect(purchase, contains("labelText: 'Note (facoltative)'"));
      expect(purchase, contains("_items[i].notes.text.trim()"));
    });

    test('Report acquisti mostra il dettaglio leggibile degli oggetti', () {
      expect(source, contains('Future<void> _showPurchaseReportDetail(Map<String, dynamic> item)'));
      expect(source, contains("from('acquisti_oggetti')"));
      expect(source, contains("from('master_oggetti')"));
      expect(source, contains("'OGGETTI ACQUISTATI'"));
    });

    test('OBJECT_MASTER carica le categorie per mostrare quella già assegnata', () {
      final initStart = source.indexOf('void initState()');
      final initEnd = source.indexOf('Future<void> _loadCollectionCategories()', initStart);
      expect(initStart, isNonNegative);
      expect(initEnd, greaterThan(initStart));
      final init = source.substring(initStart, initEnd);
      expect(init, contains("widget.apiCode == 'PR-01' || widget.apiCode == 'PR-02' || widget.apiCode == 'OBJECT_MASTER'"));
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

    test('PR-02 carica e preseleziona la categoria COLLEZIONE esistente', () {
      expect(source, contains("widget.apiCode == 'PR-01' || widget.apiCode == 'PR-02' || widget.apiCode == 'OBJECT_MASTER'"));
      expect(source, contains("key: ValueKey('collection-category-"));
      expect(source, contains("from('oggetto_collezione_categoria').select('codice_categoria')"));
      expect(source, contains('_selectedCollectionCategory = assignedCollectionCategory'));
      expect(source, contains('collection-category-'));
    });

    test('PR-02 accumula le modifiche fino alla risposta finale e mantiene separata la categoria', () {
      expect(source, contains('_selectedCollectionCategory'));
      expect(source, contains('categoria_collezione_selezionata'));
      expect(source, contains('_pr02AwaitingNextChoice'));
      expect(source, contains('_continuePr02WithAnotherObject()'));
      expect(source, contains('await _savePr02PendingChanges(closeOnComplete: false);'));
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

    test('PR-02 salva e verifica la modifica prima della scelta successiva', () {
      final start = source.indexOf('Future<void> _confirmPr02Changes() async {');
      final end = source.indexOf('Future<void> _continuePr02WithAnotherObject()', start);
      expect(start, isNonNegative);
      expect(end, greaterThan(start));
      final confirmFlow = source.substring(start, end);
      expect(confirmFlow, contains('await _savePr02PendingChanges(closeOnComplete: false);'));
      expect(confirmFlow, contains('salvato e verificato'));
    });

    test('le schermate delle sezioni ripristinano gli sfondi locali dedicati', () {
      for (final asset in [
        'assets/menu_sections/01_VENDITE.jpg',
        'assets/menu_sections/02_ACQUISTI.jpg',
        'assets/menu_sections/a_vibrant_neon_cyber_desk_scene_matching_the_app_s.png',
        'assets/menu_sections/VALORA_VALUTAZIONI_GIALLO.jpg',
        'assets/menu_sections/05_CATALOGO.jpg',
        'assets/menu_sections/06_REPORT.jpg',
      ]) {
        expect(source, contains(asset));
      }
      expect(dashboardBackgroundSource, contains('Image.asset('));
      expect(dashboardBackgroundSource, contains('backgroundAsset'));
      expect(dashboardBackgroundSource, contains('errorBuilder'));
      expect(dashboardHeaderSource, contains('        title,'));
      expect(dashboardHeaderSource, contains('        description,'));
      expect(dashboardHeaderSource, contains('fontSize: 24'));
      expect(dashboardFooterSource, contains('OutlinedButton')); 
      expect(dashboardFooterSource, contains('backgroundColor: Colors.transparent'));
      expect(dashboardFooterSource, contains('withValues(alpha: 0.55)'));
      expect(source, contains('DashboardSectionFooter('));
      expect(procedureCardSource, contains('Colors.black.withValues(alpha: 0.20)'));
      expect(source, contains('Colors.black.withValues(alpha: 0.22)'));
      expect(themeSource, contains("'VALUTAZIONI': Color(0xFFD6A83F)"));
      expect(themeSource, contains("'RICERCHE': Color(0xFFD6A83F)"));
      expect(source, contains("'VALUTAZIONI': 'assets/menu_sections/VALORA_VALUTAZIONI_GIALLO.jpg'"));
      expect(source, contains("'RICERCHE': 'assets/menu_sections/a_vibrant_neon_cyber_desk_scene_matching_the_app_s.png'"));
    });

    test('PR-12 mantiene la ricerca multi-fonte a lotti', () {
      expect(source, contains('_loadIncompleteMetadataCatalog'));
      expect(source, contains('_runPr12AiBatch'));
      expect(source, contains('LOTTO DA 10'));
      expect(source, contains('RIPROVA I PROSSIMI 10 IRRISOLTI'));
    });

    test('PR-04 preserves every queued purchase until final save', () {
      expect(source, contains('_pendingPurchases'));
      expect(source, contains('_currentPurchaseOperation()'));
      expect(source, contains('_queueCurrentAndStartNext'));
      expect(source, contains("'operazioni': [..._pendingPurchases, _currentPurchaseOperation()]"));
      expect(source, contains('reread.length == expectedPurchases'));
      expect(source, contains("r['numero_acquisti'] == expectedPurchases"));
      expect(source, contains('AGGIUNGI UN ALTRO ACQUISTO ALLA CODA'));
      expect(source, isNot(contains('Vuoi effettuare un altro acquisto?')));
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

    test('PR-02 carica il master categorie prima di mostrare il selettore modificabile', () {
      expect(source, contains("if (widget.apiCode == 'PR-01' || widget.apiCode == 'PR-02' || widget.apiCode == 'OBJECT_MASTER')"));
      expect(source, contains("_loadCollectionCategories();"));
      expect(source, contains("if (_destination == 'COLLEZIONE') _collectionCategoryField()"));
    });
  });
}