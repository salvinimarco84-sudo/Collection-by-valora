import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File('lib/main.dart').readAsStringSync();
  final valoraI18nSource = File('lib/localization/valora_i18n.dart').readAsStringSync();
  final startupFailurePageSource = File('lib/startup/startup_failure_page.dart').readAsStringSync();
  final startupLoadingPageSource = File('lib/startup/startup_loading_page.dart').readAsStringSync();
  final authenticationGateSource = File('lib/authentication/authentication_gate.dart').readAsStringSync();
  final dashboardHomeCoordinatorSource = File('lib/dashboard/dashboard_home_coordinator.dart').readAsStringSync();
  final dashboardCollectionContentSource = File('lib/dashboard/dashboard_collection_content.dart').readAsStringSync();
  // Le verifiche d'integrazione includono il coordinatore estratto; i contratti
  // relativi agli import e alla direttiva part restano verificati su main.dart.
  final dashboardRuntimeSource = '$source\n$dashboardHomeCoordinatorSource\n$dashboardCollectionContentSource';
  final pr01FormContentSource = File('lib/procedures/pr01_form_content.dart').readAsStringSync();
  final pr01RuntimeProcedureSource = File('lib/procedures/pr01_runtime_procedure.dart').readAsStringSync();
  final pr02RuntimeProcedureSource = File('lib/procedures/pr02_runtime_procedure.dart').readAsStringSync();
  final themeSource = File('lib/themes/valora_theme.dart').readAsStringSync();
  final procedureCardSource = File('lib/procedures/procedure_card.dart').readAsStringSync();
  final dashboardBackgroundSource = File('lib/dashboard/dashboard_section_background.dart').readAsStringSync();
  final dashboardHeaderSource = File('lib/dashboard/dashboard_section_header.dart').readAsStringSync();
  final dashboardFooterSource = File('lib/dashboard/dashboard_section_footer.dart').readAsStringSync();
  final dashboardMenuCardSource = File('lib/dashboard/dashboard_menu_card.dart').readAsStringSync();
  final dashboardGridMenuCardSource = File('lib/dashboard/dashboard_grid_menu_card.dart').readAsStringSync();
  final dashboardOverlaySource = File('lib/dashboard/dashboard_section_overlay.dart').readAsStringSync();
  final dashboardCollectionCategoryCardSource = File('lib/dashboard/dashboard_collection_category_card.dart').readAsStringSync();
  final dashboardCollectionCategoryHeaderSource = File('lib/dashboard/dashboard_collection_category_header.dart').readAsStringSync();
  final dashboardCollectionCategoryLogoSource = File('lib/dashboard/dashboard_collection_category_logo.dart').readAsStringSync();
  final dashboardCollectionCategoryPreviewStripSource = File('lib/dashboard/dashboard_collection_category_preview_strip.dart').readAsStringSync();
  final dashboardCollectionHeaderSource = File('lib/dashboard/dashboard_collection_header.dart').readAsStringSync();
  final dashboardHomeHeaderSource = File('lib/dashboard/dashboard_home_header.dart').readAsStringSync();
  final dashboardHomeFooterSource = File('lib/dashboard/dashboard_home_footer.dart').readAsStringSync();
  final dashboardHomeListContentSource = File('lib/dashboard/dashboard_home_list_content.dart').readAsStringSync();
  final dashboardCollectionErrorBannerSource = File('lib/dashboard/dashboard_collection_error_banner.dart').readAsStringSync();
  final dashboardCollectionEmptyNoticeSource = File('lib/dashboard/dashboard_collection_empty_notice.dart').readAsStringSync();
  final dashboardCategoryBrandMarkSource = File('lib/dashboard/dashboard_category_brand_mark.dart').readAsStringSync();
  final dashboardCategoryObjectPreviewSource = File('lib/dashboard/dashboard_category_object_preview.dart').readAsStringSync();
  final dashboardCategoryObjectImageFallbackSource = File('lib/dashboard/dashboard_category_object_image_fallback.dart').readAsStringSync();
  final dashboardCategoryPanelHeaderSource = File('lib/dashboard/dashboard_category_panel_header.dart').readAsStringSync();
  final dashboardCategoryPanelSource = File('lib/dashboard/dashboard_category_panel.dart').readAsStringSync();
  final dashboardCategoryNoRecordsNoticeSource = File('lib/dashboard/dashboard_category_no_records_notice.dart').readAsStringSync();
  final dashboardCategoryLoadingNoticeSource = File('lib/dashboard/dashboard_category_loading_notice.dart').readAsStringSync();
  final dashboardCatalogCountErrorNoticeSource = File('lib/dashboard/dashboard_catalog_count_error_notice.dart').readAsStringSync();
  final dashboardAssistantFabSource = File('lib/dashboard/dashboard_assistant_fab.dart').readAsStringSync();
  final dashboardAppBarSource = File('lib/dashboard/dashboard_app_bar.dart').readAsStringSync();
  final dashboardCategoryPreviewListSource = File('lib/dashboard/dashboard_category_preview_list.dart').readAsStringSync();
  final dashboardProcedureInfoDialogSource = File('lib/dashboard/dashboard_procedure_info_dialog.dart').readAsStringSync();
  final dashboardBlockMenuGridSource = File('lib/dashboard/dashboard_block_menu_grid.dart').readAsStringSync();
  final dashboardHomeBlockContentSource = File('lib/dashboard/dashboard_home_block_content.dart').readAsStringSync();
  final dashboardHomeContentSource = File('lib/dashboard/dashboard_home_content.dart').readAsStringSync();
  final dashboardSectionContentSource = File('lib/dashboard/dashboard_section_content.dart').readAsStringSync();
  final objectHistoryDetailRowSource = File('lib/history/object_history_detail_row.dart').readAsStringSync();
  final objectImagePlaceholderSource = File('lib/objects/object_image_placeholder.dart').readAsStringSync();
  final objectInfoChipSource = File('lib/objects/object_info_chip.dart').readAsStringSync();

  group('Contratti di regressione COLLECTION by VALORA', () {
    test('il velo di contrasto della sezione mantiene overlay e non intercetta i tocchi', () {
      expect(dashboardOverlaySource, contains('class DashboardSectionOverlay extends StatelessWidget'));
      expect(dashboardOverlaySource, contains('IgnorePointer('));
      expect(dashboardOverlaySource, contains('Color.fromRGBO(0, 0, 0, 0.22)'));
      expect(dashboardSectionContentSource, contains('const Positioned.fill(child: DashboardSectionOverlay())'));
    });

    test('la dashboard seleziona un solo layout e costruisce solo quello attivo', () {
      expect(dashboardHomeContentSource, contains('class DashboardHomeContent extends StatelessWidget'));
      expect(dashboardHomeContentSource, contains('build(BuildContext context) => useBlockLayout'));
      expect(dashboardHomeContentSource, contains('blockContentBuilder()'));
      expect(dashboardHomeContentSource, contains('listContentBuilder()'));
      expect(source, contains("import 'dashboard/dashboard_home_content.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardHomeContent('));
      expect(dashboardRuntimeSource, contains('blockContentBuilder: () {'));
      expect(dashboardRuntimeSource, contains('listContentBuilder: () => DashboardHomeListContent('));
    });

    test('la riga dettaglio cronologia conserva gerarchia tipografica e spaziatura', () {
      expect(objectHistoryDetailRowSource, contains('class ObjectHistoryDetailRow extends StatelessWidget'));
      expect(objectHistoryDetailRowSource, contains('padding: const EdgeInsets.only(bottom: 2)'));
      expect(objectHistoryDetailRowSource, contains('fontSize: 12'));
      expect(objectHistoryDetailRowSource, contains('fontSize: 15'));
      expect(source, contains("import 'history/object_history_detail_row.dart';"));
      expect(source, contains('ObjectHistoryDetailRow('));
      expect(source, contains('labelColor: ValoraAppearance.instance.textMuted'));
    });

    test('il segnaposto immagine oggetto conserva dimensioni, icona e colori configurabili', () {
      expect(objectImagePlaceholderSource, contains('class ObjectImagePlaceholder extends StatelessWidget'));
      expect(objectImagePlaceholderSource, contains('this.size = 88'));
      expect(objectImagePlaceholderSource, contains('Icons.image_not_supported_outlined'));
      expect(objectImagePlaceholderSource, contains('width: size'));
      expect(objectImagePlaceholderSource, contains('height: size'));
      expect(source, contains("import 'objects/object_image_placeholder.dart';"));
      expect(source, contains('ObjectImagePlaceholder('));
      expect(source, contains('backgroundColor: ValoraAppearance.instance.neutralOverlay'));
      expect(source, contains('iconColor: ValoraAppearance.instance.textFaint'));
    });

    test('il chip metadati oggetto conserva icona, etichetta e stile compatto', () {
      expect(objectInfoChipSource, contains('class ObjectInfoChip extends StatelessWidget'));
      expect(objectInfoChipSource, contains('required this.icon'));
      expect(objectInfoChipSource, contains('required this.label'));
      expect(objectInfoChipSource, contains('required this.color'));
      expect(objectInfoChipSource, contains('EdgeInsets.symmetric(horizontal: 8, vertical: 5)'));
      expect(objectInfoChipSource, contains('BorderRadius.circular(20)'));
      expect(objectInfoChipSource, contains('Icon(icon, size: 13, color: color)'));
      expect(source, contains("import 'objects/object_info_chip.dart';"));
      expect(source, contains('ObjectInfoChip('));
      expect(source, contains('color: sectionColor'));
    });

    test('la card a blocchi della dashboard conserva immagine, colori, conteggio e navigazione', () {
      expect(dashboardGridMenuCardSource, contains('class DashboardGridMenuCard extends StatelessWidget'));
      expect(dashboardGridMenuCardSource, contains('Image.network('));
      expect(dashboardGridMenuCardSource, contains('errorBuilder'));
      expect(dashboardGridMenuCardSource, contains('imageFit'));
      expect(dashboardGridMenuCardSource, contains('footerText'));
      expect(dashboardGridMenuCardSource, contains('onTap: onTap'));
      expect(dashboardBlockMenuGridSource, contains('DashboardGridMenuCard('));
      expect(source, contains("import 'dashboard/dashboard_block_menu_grid.dart';"));
      expect(dashboardHomeBlockContentSource, contains('DashboardBlockMenuGrid('));
      expect(dashboardRuntimeSource, contains('DashboardHomeBlockContent('));
      expect(dashboardRuntimeSource, contains('imageUrlFor: (title) {'));
    });

    test('la card del menu dashboard conserva immagini, colori e navigazione', () {
      expect(dashboardMenuCardSource, contains('class DashboardMenuCard extends StatelessWidget'));
      expect(dashboardMenuCardSource, contains('Image.network('));
      expect(dashboardMenuCardSource, contains('errorBuilder'));
      expect(dashboardMenuCardSource, contains('color.withValues(alpha: 0.85)'));
      expect(dashboardMenuCardSource, contains('onTap: onTap'));
      expect(dashboardMenuCardSource, contains('trailingText'));
      expect(source, contains("import 'dashboard/dashboard_menu_card.dart';"));
      expect(dashboardRuntimeSource, contains('return DashboardMenuCard('));
      expect(dashboardRuntimeSource, contains('imageUrl: imageUrl'));
    });

    test('il pannello categoria conserva contenitore, intestazione e contenuto', () {
      expect(dashboardCategoryPanelSource, contains('class DashboardCategoryPanel extends StatelessWidget'));
      expect(dashboardCategoryPanelSource, contains('color.withValues(alpha: 0.22)'));
      expect(dashboardCategoryPanelSource, contains('BorderRadius.circular(16)'));
      expect(dashboardCategoryPanelSource, contains('EdgeInsets.fromLTRB(10, 10, 10, 8)'));
      expect(dashboardCategoryPanelSource, contains('DashboardCategoryPanelHeader('));
      expect(dashboardCategoryPanelSource, contains('child,'));
      expect(source, contains("import 'dashboard/dashboard_category_panel.dart';"));
      expect(dashboardRuntimeSource, contains('return DashboardCategoryPanel('));
      expect(dashboardRuntimeSource, contains('recordCount: rows.length'));
    });

    test('l’avviso caricamento categoria mantiene padding e indicatore', () {
      expect(dashboardCategoryLoadingNoticeSource, contains('class DashboardCategoryLoadingNotice extends StatelessWidget'));
      expect(dashboardCategoryLoadingNoticeSource, contains('EdgeInsets.all(14)'));
      expect(dashboardCategoryLoadingNoticeSource, contains('LinearProgressIndicator()'));
      expect(source, contains("import 'dashboard/dashboard_category_loading_notice.dart';"));
      expect(dashboardRuntimeSource, contains('const DashboardCategoryLoadingNotice()'));
    });

    test('il pulsante assistente globale mantiene icona, etichetta e callback', () {
      expect(dashboardAssistantFabSource, contains('class DashboardAssistantFab extends StatelessWidget'));
      expect(dashboardAssistantFabSource, contains("heroTag: 'valora_global_assistant'"));
      expect(dashboardAssistantFabSource, contains('Icons.mic_none'));
      expect(dashboardAssistantFabSource, contains('onPressed: onPressed'));
      expect(source, contains("import 'dashboard/dashboard_assistant_fab.dart';"));
      expect(dashboardRuntimeSource, contains('floatingActionButton: DashboardAssistantFab('));
      expect(dashboardRuntimeSource, contains('screenContext: selectedSection?.title ?? \'Dashboard\''));
    });

    test('l’avviso conteggio catalogo mantiene messaggio, margine e stile', () {
      expect(dashboardCatalogCountErrorNoticeSource, contains('class DashboardCatalogCountErrorNotice extends StatelessWidget'));
      expect(dashboardCatalogCountErrorNoticeSource, contains('EdgeInsets.only(top: 8)'));
      expect(dashboardCatalogCountErrorNoticeSource, contains('Colors.orangeAccent'));
      expect(dashboardCatalogCountErrorNoticeSource, contains('fontSize: 12'));
      expect(dashboardCatalogCountErrorNoticeSource, contains('message'));
      expect(source, contains("import 'dashboard/dashboard_catalog_count_error_notice.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardCatalogCountErrorNotice(message:'));
    });

    test('l’avviso categoria senza record mantiene testo e stile', () {
      expect(dashboardCategoryNoRecordsNoticeSource, contains('class DashboardCategoryNoRecordsNotice extends StatelessWidget'));
      expect(dashboardCategoryNoRecordsNoticeSource, contains('Nessun record riconosciuto in questa categoria.'));
      expect(dashboardCategoryNoRecordsNoticeSource, contains('EdgeInsets.fromLTRB(4, 10, 4, 5)'));
      expect(dashboardCategoryNoRecordsNoticeSource, contains('Colors.white70'));
      expect(source, contains("import 'dashboard/dashboard_category_no_records_notice.dart';"));
      expect(dashboardRuntimeSource, contains('const DashboardCategoryNoRecordsNotice()'));
    });

    test('l’intestazione categoria conserva marchio, conteggio e navigazione VEDI TUTTI', () {
      expect(dashboardCategoryPanelHeaderSource, contains('class DashboardCategoryPanelHeader extends StatelessWidget'));
      expect(dashboardCategoryPanelHeaderSource, contains('DashboardCategoryBrandMark('));
      expect(dashboardCategoryPanelHeaderSource, contains('recordCount'));
      expect(dashboardCategoryPanelHeaderSource, contains("Text('VEDI TUTTI'"));
      expect(dashboardCategoryPanelHeaderSource, contains('onViewAll'));
      expect(dashboardCategoryPanelSource, contains("import 'dashboard_category_panel_header.dart';"));
      expect(dashboardCategoryPanelSource, contains('DashboardCategoryPanelHeader('));
      expect(source, contains("import 'dashboard/dashboard_category_panel.dart';"));
      expect(dashboardRuntimeSource, contains('return DashboardCategoryPanel('));
      expect(dashboardRuntimeSource, contains('onViewAll: () => Navigator.of(context).push'));
    });

    test('l’anteprima oggetto categoria conserva immagini, fallback, dimensioni e navigazione', () {
      expect(dashboardCategoryObjectPreviewSource, contains('class DashboardCategoryObjectPreview extends StatelessWidget'));
      expect(dashboardCategoryObjectPreviewSource, contains('Image.network('));
      expect(dashboardCategoryObjectPreviewSource, contains('DashboardCategoryObjectImageFallback('));
      expect(dashboardCategoryObjectPreviewSource, contains('errorBuilder'));
      expect(dashboardCategoryObjectPreviewSource, contains('BoxFit.contain'));
      expect(dashboardCategoryObjectImageFallbackSource, contains('class DashboardCategoryObjectImageFallback extends StatelessWidget'));
      expect(dashboardCategoryObjectImageFallbackSource, contains('size: 34'));
      expect(dashboardCategoryObjectPreviewSource, contains('width: 98'));
      expect(dashboardCategoryObjectPreviewSource, contains('height: 75'));
      expect(dashboardCategoryObjectPreviewSource, contains('onTap: onTap'));
      expect(source, contains("import 'dashboard/dashboard_category_object_preview.dart';"));
      expect(dashboardCategoryPreviewListSource, contains('DashboardCategoryObjectPreview('));
      expect(dashboardRuntimeSource, contains('DashboardCategoryPreviewList('));
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
      expect(dashboardCategoryPanelHeaderSource, contains("import 'dashboard_category_brand_mark.dart';"));
      expect(dashboardCategoryPanelHeaderSource, contains('DashboardCategoryBrandMark('));
    });

    test('l’avviso categorie vuote conserva padding e stile del testo', () {
      expect(dashboardCollectionEmptyNoticeSource, contains('class DashboardCollectionEmptyNotice extends StatelessWidget'));
      expect(dashboardCollectionEmptyNoticeSource, contains('EdgeInsets.all(12)'));
      expect(dashboardCollectionEmptyNoticeSource, contains('Nessuna categoria configurata nel master.'));
      expect(dashboardCollectionEmptyNoticeSource, contains('Colors.white70'));
      expect(source, contains("import 'dashboard/dashboard_collection_empty_notice.dart';"));
      expect(dashboardRuntimeSource, contains('const DashboardCollectionEmptyNotice()'));
    });

    test('il banner errore catalogo mantiene sfondo, margini e testo leggibile', () {
      expect(dashboardCollectionErrorBannerSource, contains('class DashboardCollectionErrorBanner extends StatelessWidget'));
      expect(dashboardCollectionErrorBannerSource, contains('Color(0xFF3B1717)'));
      expect(dashboardCollectionErrorBannerSource, contains('BorderRadius.circular(10)'));
      expect(dashboardCollectionErrorBannerSource, contains('Colors.white'));
      expect(source, contains("import 'dashboard/dashboard_collection_error_banner.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardCollectionErrorBanner(message:'));
    });

    test('il footer dashboard mantiene marchio, colore e allineamento', () {
      expect(dashboardHomeFooterSource, contains('class DashboardHomeFooter extends StatelessWidget'));
      expect(dashboardHomeFooterSource, contains("'COLLECTION by VALORA'"));
      expect(dashboardHomeFooterSource, contains('Colors.white38'));
      expect(dashboardHomeFooterSource, contains('letterSpacing: 1'));
      expect(dashboardHomeListContentSource, contains('footer'));
      expect(dashboardHomeListContentSource, contains("import 'dashboard_home_footer.dart';"));
      expect(dashboardHomeListContentSource, contains('footer,'));
    });

    test('il contenuto lista dashboard conserva ordine, spaziatura e card', () {
      expect(dashboardHomeListContentSource, contains('class DashboardHomeListContent extends StatelessWidget'));
      expect(dashboardHomeListContentSource, contains('EdgeInsets.fromLTRB(16, 16, 16, 28)'));
      expect(dashboardHomeListContentSource, contains('...sectionCards'));
      expect(dashboardHomeListContentSource, contains('catalogError'));
      expect(dashboardHomeListContentSource, contains('const SizedBox(height: 12)'));
      expect(dashboardHomeListContentSource, contains('footer'));
      expect(source, contains("import 'dashboard/dashboard_home_list_content.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardHomeListContent('));
    });

    test('l’intestazione dashboard mantiene titolo e descrizione nella vista lista', () {
      expect(dashboardHomeHeaderSource, contains('class DashboardHomeHeader extends StatelessWidget'));
      expect(dashboardHomeHeaderSource, contains('letterSpacing: 1.3'));
      expect(dashboardHomeHeaderSource, contains('Colors.white70'));
      expect(dashboardHomeListContentSource, contains('header,'));
      expect(dashboardHomeListContentSource, contains('collectionCard,'));
      expect(source, contains("import 'dashboard/dashboard_home_list_content.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardHomeListContent('));
      expect(dashboardRuntimeSource, contains("title: ValoraI18n.tr('CENTRO OPERATIVO')"));
      expect(dashboardRuntimeSource, contains("subtitle: ValoraI18n.tr('Scegli una sezione per accedere alle relative funzioni.')"));
    });

    test('l’intestazione della collezione mantiene titolo, descrizione e conteggio', () {
      expect(dashboardCollectionHeaderSource, contains('class DashboardCollectionHeader extends StatelessWidget'));
      expect(dashboardCollectionHeaderSource, contains('Icons.inventory_2_outlined'));
      expect(dashboardCollectionHeaderSource, contains('countLabel'));
      expect(source, contains("import 'dashboard/dashboard_collection_header.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardCollectionHeader('));
      expect(dashboardRuntimeSource, contains("title: ValoraI18n.tr('COLLEZIONE')"));
    });

    test('la card categoria collezione mantiene logo, conteggio, anteprime e navigazione', () {
      expect(dashboardCollectionCategoryCardSource, contains('class DashboardCollectionCategoryCard extends StatelessWidget'));
      expect(dashboardCollectionCategoryCardSource, contains('previewImageUrls'));
      expect(dashboardCollectionCategoryCardSource, contains('DashboardCollectionCategoryPreviewStrip('));
      expect(dashboardCollectionCategoryPreviewStripSource, contains('class DashboardCollectionCategoryPreviewStrip extends StatelessWidget'));
      expect(dashboardCollectionCategoryPreviewStripSource, contains('height: 86'));
      expect(dashboardCollectionCategoryPreviewStripSource, contains('width: 76'));
      expect(dashboardCollectionCategoryPreviewStripSource, contains('Image.network('));
      expect(dashboardCollectionCategoryPreviewStripSource, contains('errorBuilder'));
      expect(dashboardCollectionCategoryPreviewStripSource, contains('BoxFit.contain'));
      expect(dashboardCollectionCategoryCardSource, contains('onTap: onTap'));
      expect(dashboardCollectionCategoryCardSource, contains("import 'dashboard_collection_category_header.dart';"));
      expect(dashboardCollectionCategoryCardSource, contains('DashboardCollectionCategoryHeader('));
      expect(source, contains("import 'dashboard/dashboard_collection_category_card.dart';"));
      expect(dashboardRuntimeSource, contains('return DashboardCollectionCategoryCard('));
      expect(dashboardRuntimeSource, contains('initialCategoryCode: code'));
    });

    test('l intestazione della card categoria conserva logo, testi, conteggio e navigazione', () {
      expect(dashboardCollectionCategoryHeaderSource, contains('class DashboardCollectionCategoryHeader extends StatelessWidget'));
      expect(dashboardCollectionCategoryHeaderSource, contains('DashboardCollectionCategoryLogo('));
      expect(dashboardCollectionCategoryHeaderSource, contains("import 'dashboard_collection_category_logo.dart';"));
      expect(dashboardCollectionCategoryLogoSource, contains('class DashboardCollectionCategoryLogo extends StatelessWidget'));
      expect(dashboardCollectionCategoryLogoSource, contains('DashboardCategoryBrandMark('));
      expect(dashboardCollectionCategoryLogoSource, contains('Image.network('));
      expect(dashboardCollectionCategoryLogoSource, contains('errorBuilder'));
      expect(dashboardCollectionCategoryLogoSource, contains('width: 62'));
      expect(dashboardCollectionCategoryLogoSource, contains('height: 46'));
      expect(dashboardCollectionCategoryHeaderSource, contains('Text('));
      expect(dashboardCollectionCategoryHeaderSource, contains(r"'$count'"));
      expect(dashboardCollectionCategoryHeaderSource, contains('onTap: onTap'));
      expect(dashboardCollectionCategoryCardSource, contains("import 'dashboard_collection_category_header.dart';"));
      expect(dashboardCollectionCategoryCardSource, contains('DashboardCollectionCategoryHeader('));
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
      expect(pr02RuntimeProcedureSource, contains('categoria_collezione_selezionata'));
      expect(source, contains('_pr02AwaitingNextChoice'));
      expect(source, contains('_continuePr02WithAnotherObject'));
      expect(pr02RuntimeProcedureSource, contains('_pr02PendingChanges.add'));
      expect(pr02RuntimeProcedureSource, contains('await _savePr02PendingChanges(closeOnComplete: false);'));
      expect(pr02RuntimeProcedureSource, contains('Future<void> _savePr02PendingChanges({bool closeOnComplete = true})'));
      expect(pr02RuntimeProcedureSource, contains('oggetto_collezione_categoria'));
    });

    test('la maschera PR-01 è separata e mantiene tutti i campi originali', () {
      expect(source, contains("import 'procedures/pr01_form_content.dart';"));
      expect(source, contains('Pr01FormContent('));
      expect(pr01FormContentSource, contains('class Pr01FormContent extends StatelessWidget'));
      for (final label in [
        'IDENTIFICAZIONE OGGETTO',
        'DATI IDENTIFICATIVI · INSERIMENTO MANUALE',
        'DATI INSERIBILI',
        'VALORI DETERMINATI DA ALTRE PROCEDURE',
      ]) {
        expect(pr01FormContentSource, contains(label));
      }
      expect(pr01FormContentSource, contains('descriptionField'));
      expect(pr01FormContentSource, contains('collectionCategoryField'));
      expect(pr01FormContentSource, contains('totalValueField'));
      expect(pr01FormContentSource, contains('marketValueField'));
    });

    test('PR-01 accoda gli oggetti e salva il blocco solo dopo la scelta finale', () {
      expect(pr01RuntimeProcedureSource, contains('_pr01PendingObjects.add({'));
      expect(pr01RuntimeProcedureSource, contains('await _savePr01PendingObjects();'));
      expect(pr01RuntimeProcedureSource, contains('NO, SALVA IL BLOCCO'));
      expect(pr01RuntimeProcedureSource, contains('Future<void> _savePr01PendingObjects() async'));
      expect(source, contains('_confirmAndSaveNewObject'));
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
      final start = pr02RuntimeProcedureSource.indexOf('Future<void> _confirmPr02Changes() async {');
      final end = pr02RuntimeProcedureSource.indexOf('Future<void> _continuePr02WithAnotherObject()', start);
      expect(start, isNonNegative);
      expect(end, greaterThan(start));
      final confirmFlow = pr02RuntimeProcedureSource.substring(start, end);
      expect(confirmFlow, contains('_pr02PendingChanges.add'));
      expect(confirmFlow, contains('_pr02AwaitingNextChoice = true'));
      expect(confirmFlow, isNot(contains('showDialog')));
      expect(confirmFlow, isNot(contains('await _preview()')));
      expect(confirmFlow, isNot(contains('await _confirmData()')));
    });

    test('PR-02 salva e verifica la modifica prima della scelta successiva', () {
      expect(pr02RuntimeProcedureSource, contains('await _savePr02PendingChanges(closeOnComplete: false);'));
      expect(pr02RuntimeProcedureSource, contains('salvato e verificato'));
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
        expect(dashboardRuntimeSource, contains(asset));
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
      expect(dashboardRuntimeSource, contains('DashboardSectionFooter('));
      expect(procedureCardSource, contains('Colors.black.withValues(alpha: 0.20)'));
      expect(source, contains('Colors.black.withValues(alpha: 0.22)'));
      expect(themeSource, contains("'VALUTAZIONI': Color(0xFFD6A83F)"));
      expect(themeSource, contains("'RICERCHE': Color(0xFF38BDF8)"));
      expect(dashboardMenuCardSource, contains('color: color.withValues(alpha: 0.20)'));
      expect(dashboardGridMenuCardSource, contains('color: color.withValues(alpha: 0.20)'));
      expect(dashboardRuntimeSource, contains("'VALUTAZIONI': 'assets/menu_sections/VALORA_VALUTAZIONI_GIALLO.jpg'"));
      expect(dashboardRuntimeSource, contains("'RICERCHE': 'assets/menu_sections/a_vibrant_neon_cyber_desk_scene_matching_the_app_s.png'"));
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

    test('la AppBar dashboard conserva titolo, pulsanti e callback di navigazione', () {
      expect(dashboardAppBarSource, contains('class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget'));
      expect(dashboardAppBarSource, contains("Text('COLLECTION by VALORA'"));
      expect(dashboardAppBarSource, contains('Icons.account_circle_outlined'));
      expect(dashboardAppBarSource, contains('Icons.palette_outlined'));
      expect(dashboardAppBarSource, contains('Icons.logout'));
      expect(dashboardAppBarSource, contains('onPressed: onBack'));
      expect(dashboardAppBarSource, contains('onPressed: onProfileTap'));
      expect(dashboardAppBarSource, contains('onPressed: onAppearanceTap'));
      expect(dashboardAppBarSource, contains('onPressed: onLogout'));
      expect(source, contains("import 'dashboard/dashboard_app_bar.dart';"));
      expect(dashboardRuntimeSource, contains('appBar: DashboardAppBar('));
    });

    test('l anteprima orizzontale categoria mantiene limite, layout e callback', () {
      expect(dashboardCategoryPreviewListSource, contains('class DashboardCategoryPreviewList extends StatelessWidget'));
      expect(dashboardCategoryPreviewListSource, contains('height: 118'));
      expect(dashboardCategoryPreviewListSource, contains('scrollDirection: Axis.horizontal'));
      expect(dashboardCategoryPreviewListSource, contains('rows.length > 5 ? 5 : rows.length'));
      expect(dashboardCategoryPreviewListSource, contains('descriptionFor(row)'));
      expect(dashboardCategoryPreviewListSource, contains('imageUrlFor(row)'));
      expect(dashboardCategoryPreviewListSource, contains('onObjectTap(row)'));
      expect(source, contains("import 'dashboard/dashboard_category_preview_list.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardCategoryPreviewList('));
    });

    test('il dialog informativo procedura conserva testo e chiusura', () {
      expect(dashboardProcedureInfoDialogSource, contains('class DashboardProcedureInfoDialog extends StatelessWidget'));
      expect(dashboardProcedureInfoDialogSource, contains('Text(title)'));
      expect(dashboardProcedureInfoDialogSource, contains('Text(description)'));
      expect(dashboardProcedureInfoDialogSource, contains('Text(closeLabel)'));
      expect(dashboardProcedureInfoDialogSource, contains('onPressed: onClose'));
      expect(source, contains("import 'dashboard/dashboard_procedure_info_dialog.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardProcedureInfoDialog('));
    });

    test('la griglia dashboard conserva breakpoint, card e immagini', () {
      expect(dashboardBlockMenuGridSource, contains('class DashboardBlockMenuGrid extends StatelessWidget'));
      expect(dashboardBlockMenuGridSource, contains('constraints.maxWidth >= 900'));
      expect(dashboardBlockMenuGridSource, contains('constraints.maxWidth >= 600'));
      expect(dashboardBlockMenuGridSource, contains('? 4'));
      expect(dashboardBlockMenuGridSource, contains('? 3'));
      expect(dashboardBlockMenuGridSource, contains(': 2'));
      expect(dashboardBlockMenuGridSource, contains('childAspectRatio: constraints.maxWidth < 600 ? 0.98 : 1.18'));
      expect(dashboardBlockMenuGridSource, contains('DashboardGridMenuCard('));
      expect(dashboardBlockMenuGridSource, contains('imageUrlFor(title)'));
      expect(dashboardBlockMenuGridSource, contains("sectionKey == 'RICERCHE' || sectionKey == 'VALUTAZIONI'"));
      expect(dashboardBlockMenuGridSource, contains("title == 'COLLEZIONE'"));
      expect(source, contains("import 'dashboard/dashboard_block_menu_grid.dart';"));
      expect(dashboardHomeBlockContentSource, contains('DashboardBlockMenuGrid('));
      expect(dashboardRuntimeSource, contains('DashboardHomeBlockContent('));
    });
    test('il tema scelto resta applicato alla dashboard dopo la chiusura della personalizzazione', () {
      expect(dashboardHomeCoordinatorSource, contains('ValoraAppearance.instance.addListener(_onAppearanceChanged)'));
      expect(dashboardHomeCoordinatorSource, contains('void _onAppearanceChanged()'));
      expect(dashboardHomeCoordinatorSource, contains('if (mounted) setState(() {})'));
      expect(dashboardHomeCoordinatorSource, contains('ValoraAppearance.instance.removeListener(_onAppearanceChanged)'));
      expect(dashboardHomeCoordinatorSource, contains('valoraThemeAsset(ValoraAppearance.instance.selectedThemeId)'));
      expect(themeSource, contains("Future<void> setTheme(String themeId) async"));
      expect(themeSource, contains("await p.setString('valora_selected_theme', themeId)"));
      expect(themeSource, contains('notifyListeners();'));
    });

    test('il coordinatore del menu principale è isolato senza alterarne i flussi', () {
      expect(dashboardHomeCoordinatorSource, contains("part of '../main.dart';"));
      expect(dashboardHomeCoordinatorSource, contains('class HomeDashboard extends StatefulWidget'));
      expect(dashboardHomeCoordinatorSource, contains('class _HomeDashboardState extends State<HomeDashboard>'));
      expect(dashboardHomeCoordinatorSource, contains('Future<void> _loadDashboardCatalog() async'));
      expect(dashboardHomeCoordinatorSource, contains('Widget buildDashboard()'));
      expect(dashboardHomeCoordinatorSource, contains('Widget buildCollection() => DashboardCollectionContent('));
      expect(dashboardCollectionContentSource, contains('class DashboardCollectionContent extends StatelessWidget'));
      expect(dashboardCollectionContentSource, contains('sortedCategories.sort'));
      expect(dashboardCollectionContentSource, contains('previewImageUrls: previewRows.map(imageUrlFor).toList()'));
      expect(source, contains("part 'dashboard/dashboard_collection_content.dart';"));
      expect(dashboardHomeCoordinatorSource, contains('Widget buildSection(DashboardSection section)'));
      expect(source, contains("part 'dashboard/dashboard_home_coordinator.dart';"));
      expect(source, isNot(contains('class HomeDashboard extends StatefulWidget')));
      expect(source, isNot(contains('class _HomeDashboardState extends State<HomeDashboard>')));
    });

    test('il gate autenticazione conserva il flusso sessione e i due percorsi', () {
      expect(authenticationGateSource, contains('class AuthenticationGate extends StatelessWidget'));
      expect(authenticationGateSource, contains('onAuthStateChange'));
      expect(authenticationGateSource, contains('currentSession != null'));
      expect(authenticationGateSource, contains('authenticatedBuilder(context)'));
      expect(authenticationGateSource, contains('unauthenticatedBuilder(context)'));
      expect(source, contains("import 'authentication/authentication_gate.dart';"));
      expect(source, contains('authenticatedBuilder: (_) => const HomeDashboard()'));
      expect(source, contains('unauthenticatedBuilder: (_) => const LoginPage()'));
      expect(source, isNot(contains('class AuthenticationGate extends StatelessWidget')));
    });

    test('la schermata di caricamento avvio conserva messaggio e indicatore', () {
      expect(startupLoadingPageSource, contains('class StartupLoadingPage extends StatelessWidget'));
      expect(startupLoadingPageSource, contains('CircularProgressIndicator(color: accentColor)'));
      expect(startupLoadingPageSource, contains('COLLECTION by VALORA'));
      expect(startupLoadingPageSource, contains('Inizializzazione dell’app in corso'));
      expect(source, contains("import 'startup/startup_loading_page.dart';"));
      expect(source, isNot(contains('class StartupLoadingPage extends StatelessWidget')));
    });

    test('la schermata di errore avvio resta separata e mostra il dettaglio', () {
      expect(startupFailurePageSource, contains('class StartupFailurePage extends StatelessWidget'));
      expect(startupFailurePageSource, contains('SelectableText('));
      expect(startupFailurePageSource, contains('Avvio non completato.'));
      expect(startupFailurePageSource, contains('required this.accentColor'));
      expect(source, contains("import 'startup/startup_failure_page.dart';"));
      expect(source, contains('StartupFailurePage(error: widget.startupError!, accentColor: goldColor)'));
      expect(source, isNot(contains('class StartupFailurePage extends StatelessWidget')));
    });

    test('la localizzazione resta separata dal file principale', () {
      expect(valoraI18nSource, contains('class ValoraI18n extends ChangeNotifier'));
      expect(valoraI18nSource, contains('static String tr('));
      expect(source, contains("import 'localization/valora_i18n.dart';"));
      expect(source, isNot(contains('class ValoraI18n extends ChangeNotifier')));
    });

    test('il contenuto della sezione mantiene sfondo, overlay, procedure e ritorno', () {
      expect(dashboardSectionContentSource, contains('class DashboardSectionContent extends StatelessWidget'));
      expect(dashboardSectionContentSource, contains('Positioned.fill(child: background)'));
      expect(dashboardSectionContentSource, contains('DashboardSectionOverlay()'));
      expect(dashboardSectionContentSource, contains('...procedureCards'));
      expect(dashboardSectionContentSource, contains('footer'));
      expect(source, contains("import 'dashboard/dashboard_section_content.dart';"));
      expect(dashboardRuntimeSource, contains('DashboardSectionContent('));
    });
  });
}