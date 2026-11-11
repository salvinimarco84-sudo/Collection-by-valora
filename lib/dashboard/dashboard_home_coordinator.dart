part of '../main.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  DashboardSection? selectedSection;
  bool showCollection = false;
  bool _catalogLoading = true;
  List<Map<String, dynamic>> _catalogRows = [];
  List<Map<String, dynamic>> _collectionCategories = [];
  final Map<String, int> _collectionCategoryCounts = {};
  String? _catalogError;
  final Map<int, String> _dashboardImageUrls = {};
  final Set<int> _dashboardImageLookups = {};

  @override
  void initState() {
    super.initState();
    // La Dashboard deve ridisegnarsi quando cambia il tema dalla schermata
    // Personalizzazione, che viene aperta sopra questa route.
    ValoraAppearance.instance.addListener(_onAppearanceChanged);
    _loadDashboardCatalog();
  }

  void _onAppearanceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ValoraAppearance.instance.removeListener(_onAppearanceChanged);
    super.dispose();
  }

  Future<void> _loadDashboardCatalog() async {
    try {
      final response = await Supabase.instance.client.schema('collection').rpc(
        'pr_21_ricerca_schede', params: {'p_cerca': null},
      );
      dynamic payload = response;
      if (payload is List && payload.length == 1 && payload.first is Map) {
        payload = payload.first;
      }
      if (payload is! Map || payload['oggetti'] is! List) {
        throw Exception('Risposta catalogo non valida.');
      }
      final rows = (payload['oggetti'] as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          // La HOME "COLLEZIONE" deve includere solo gli oggetti destinati
          // alla collezione. Gli oggetti per rivendita/altro non vanno contati qui.
          .where((row) =>
              (row['destinazione'] ?? '').toString().trim().toUpperCase() == 'COLLEZIONE' &&
              row['archiviato_test'] != true &&
              !['VENDUTO', 'PERSO', 'DISTRUTTO', 'USCITO', 'ACCORPATO']
                  .contains((row['stato'] ?? '').toString().trim().toUpperCase()))
          .toList();
      final categoryResponse = await Supabase.instance.client.schema('collection')
          .from('master_categorie_collezione')
          .select('codice_categoria, descrizione, icona, colore_hex, logo_url, ordine_menu, visibile')
          .eq('visibile', true).order('ordine_menu').order('descrizione');
      final categories = List<Map<String, dynamic>>.from(
        (categoryResponse as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)),
      );
      // PostgREST limita le risposte per pagina: caricare una sola volta
      // le assegnazioni tagliava i risultati oltre il limite e mostrava, per
      // esempio, Funko Pop = 0 anche se i 31 record erano presenti nel master.
      final assignments = <Map<String, dynamic>>[];
      const assignmentPageSize = 500;
      var assignmentOffset = 0;
      while (true) {
        final assignmentResponse = await Supabase.instance.client.schema('collection')
            .from('oggetto_collezione_categoria')
            .select('codice_oggetto, codice_categoria')
            .order('codice_oggetto')
            .range(assignmentOffset, assignmentOffset + assignmentPageSize - 1);
        final page = List<Map<String, dynamic>>.from(
          (assignmentResponse as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)),
        );
        assignments.addAll(page);
        if (page.length < assignmentPageSize) break;
        assignmentOffset += assignmentPageSize;
      }
      // Conta soltanto oggetti ancora disponibili e destinati alla COLLEZIONE.
      // Le assegnazioni storiche restano nel database, ma non gonfiano i contatori.
      final eligibleCodes = rows.map((row) =>
        (row['codice_oggetto'] ?? row['id'] ?? '').toString().trim()
      ).where((code) => code.isNotEmpty).toSet();
      final categoryCounts = <String, int>{};
      final countedPairs = <String>{};
      for (final assignment in assignments) {
        final objectCode = (assignment['codice_oggetto'] ?? '').toString().trim();
        final key = (assignment['codice_categoria'] ?? '').toString().trim();
        final pair = '$objectCode|$key';
        if (eligibleCodes.contains(objectCode) && key.isNotEmpty && countedPairs.add(pair)) {
          categoryCounts[key] = (categoryCounts[key] ?? 0) + 1;
        }
      }
      if (mounted) setState(() {
        _catalogRows = rows;
        _collectionCategories = categories;
        _collectionCategoryCounts
          ..clear()
          ..addAll(categoryCounts);
        _catalogLoading = false;
      });
      await _loadDashboardImages(rows);
    } catch (e) {
      if (mounted) setState(() { _catalogError = '$e'; _catalogLoading = false; });
    }
  }

  Future<void> _loadDashboardImages(List<Map<String, dynamic>> rows, {bool retryFailed = false}) async {
    // Ripristino della logica funzionante: prima URL catalografico PR-12,
    // poi registro immagini/Storage. Un errore non deve bloccare i tentativi futuri.
    final selected = <Map<String, dynamic>>[];
    final activeCategories = rows.map(_dashboardCategory).toSet();
    for (final category in ['LEGO', 'SAINT SEIYA', 'MOTO DIE-CAST', 'FUMETTI', 'GUNDAM', 'TRANSFORMERS', 'FUNKO POP', 'MODEL KIT', 'G.I. JOE', 'GIOCHI DA TAVOLO', 'ALTRE COLLEZIONI']) {
      if (activeCategories.contains(category)) {
        selected.addAll(rows.where((row) => _dashboardCategory(row) == category).take(5));
      }
    }
    final ids = selected.map((row) => int.tryParse(
      (row['codice_oggetto'] ?? row['id'] ?? '').toString(),
    )).whereType<int>().where((id) => id > 0 &&
      (retryFailed || !_dashboardImageLookups.contains(id))).toSet();
    if (ids.isEmpty) return;

    await Future.wait(ids.map((id) async {
      var resolved = false;
      try {
        final metadata = await Supabase.instance.client
            .schema('collection')
            .from('master_metadati')
            .select('url_immagine')
            .eq('codice_oggetto', id)
            .maybeSingle();
        final catalogUrl = (metadata?['url_immagine'] ?? '').toString().trim();
        if (catalogUrl.startsWith('https://') || catalogUrl.startsWith('http://')) {
          _dashboardImageUrls[id] = catalogUrl;
          resolved = true;
        }
      } catch (e) {
        debugPrint('VALORA: URL catalografico non disponibile per $id: $e');
      }

      if (!resolved) {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          final response = await Supabase.instance.client.functions.invoke(
            'collection-object-images-test',
            headers: session == null ? null : {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'action': 'get', 'codice_oggetto': id},
          );
          if (response.status >= 200 && response.status < 300 && response.data is Map) {
            final data = Map<String, dynamic>.from(response.data as Map);
            final url = (data['signed_url'] ?? data['url'] ?? data['image_url'] ?? data['url_immagine'] ?? '').toString().trim();
            if (url.startsWith('https://') || url.startsWith('http://')) {
              _dashboardImageUrls[id] = url;
              resolved = true;
            }
          }
        } catch (e) {
          debugPrint('VALORA: immagine registro non disponibile per $id: $e');
        }
      }
      if (resolved) {
        _dashboardImageLookups.add(id);
      } else {
        _dashboardImageLookups.remove(id);
      }
    }));
    if (mounted) setState(() {});
  }

  Future<void> _retryDashboardImages() async {
    await _loadDashboardImages(_catalogRows, retryFailed: true);
  }

  String _dashboardDescription(Map<String, dynamic> row) =>
      (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome'] ?? '').toString();

  String _dashboardCategory(Map<String, dynamic> row) {
    final d = _dashboardDescription(row).toLowerCase();
    if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(d)) return 'LEGO';
    if (RegExp(r'saint seiya|myth cloth|cavalieri dello zodiaco').hasMatch(d)) return 'SAINT SEIYA';
    if (RegExp(r'maisto|die.?cast|modellin|ducati panigale|yamaha r1|kawasaki ninja').hasMatch(d)) return 'MOTO DIE-CAST';
    if (RegExp(r'fumett|comic|manga|panini|salda.?press|dragon ball|one piece|tex|batman|from hell|alan moore|eddie campbell|magic press').hasMatch(d)) return 'FUMETTI';
    if (RegExp(r'gundam|gunpla|rx-78|wing zero|sazabi').hasMatch(d)) return 'GUNDAM';
    if (RegExp(r'transformers|autobot|decepticon|optimus prime|bumblebee').hasMatch(d)) return 'TRANSFORMERS';
    if (RegExp(r'funko\s*pop|funko pop!').hasMatch(d)) return 'FUNKO POP';
    if (RegExp(r'\buno\b|dobble|monopoly|trivial pursuit|gioco da tavolo|board game').hasMatch(d)) return 'GIOCHI DA TAVOLO';
    if (RegExp(r'g\.i\.\s*joe|cobra commander|cobra officer|cobra trooper|sgt\. stalker').hasMatch(d)) return 'G.I. JOE';
    if (RegExp(r'model kit|mechanic collection|gunpla|plastic model kit').hasMatch(d)) return 'MODEL KIT';
    return 'ALTRE COLLEZIONI';
  }

  String? _dashboardImageUrl(Map<String, dynamic> row) {
    final id = int.tryParse((row['codice_oggetto'] ?? row['id'] ?? '').toString());
    if (id != null && _dashboardImageUrls.containsKey(id)) return _dashboardImageUrls[id];
    for (final key in ['image_url', 'immagine_url', 'foto_url', 'url_immagine', 'image', 'foto']) {
      final value = row[key];
      if (value is String && (value.startsWith('https://') || value.startsWith('http://'))) return value;
    }
    return null;
  }

  Widget _dashboardCategoryPanel(String category, String subtitle, Color color, IconData icon) {
    final rows = _catalogRows.where((r) => _dashboardCategory(r) == category).toList();
    return DashboardCategoryPanel(
      category: category,
      subtitle: subtitle,
      color: color,
      fallbackIcon: icon,
      recordCount: rows.length,
      onViewAll: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CategoryObjectSearchPage(initialQuery: category)),
      ),
      child: _catalogLoading
          ? const DashboardCategoryLoadingNotice()
          : rows.isEmpty
              ? const DashboardCategoryNoRecordsNotice()
              : DashboardCategoryPreviewList(
                  rows: rows,
                  icon: icon,
                  color: color,
                  descriptionFor: _dashboardDescription,
                  imageUrlFor: (row) {
                    final url = _dashboardImageUrl(row);
                    return url == null ? null : _valoraImageProxyUrl(url);
                  },
                  onObjectTap: (row) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ObjectRuntimePage(
                    title: 'Scheda oggetto', apiCode: 'OBJECT_MASTER',
                    initialObjectCode: int.tryParse((row['codice_oggetto'] ?? row['id'] ?? '').toString()),
                  ))),
                ),
    );
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) setState(() { selectedSection = null; showCollection = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: selectedSection != null,
        appBar: DashboardAppBar(
          backgroundColor: ValoraAppearance.instance.background.withValues(alpha: selectedSection != null ? 0.12 : 0.82),
          showBackButton: selectedSection != null || showCollection,
          onBack: () => setState(() { selectedSection = null; showCollection = false; }),
          onProfileTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserProfilePage()));
          },
          onAppearanceTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()));
          },
          onLogout: logout,
        ),
        body: Stack(children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Il livello di fondo riempie lo schermo; il livello nitido
                  // mostra l'intera grafica senza tagli laterali.
                  Image.asset(
                    selectedSection == null
                        ? valoraThemeAsset(ValoraAppearance.instance.selectedThemeId)
                        : _sectionBackgroundAsset(selectedSection!.title),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const ColoredBox(color: backgroundColor),
                  ),
                  Image.asset(
                    selectedSection == null
                        ? valoraThemeAsset(ValoraAppearance.instance.selectedThemeId)
                        : _sectionBackgroundAsset(selectedSection!.title),
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  ColoredBox(color: Colors.black.withValues(alpha: 0.24)),
                ],
              ),
            ),
          ),
          SafeArea(child: showCollection
              ? buildCollection()
              : selectedSection == null
                  ? buildDashboard()
                  : buildSection(selectedSection!)),
        ]),
        floatingActionButton: DashboardAssistantFab(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ValoraAssistantPage(screenContext: selectedSection?.title ?? 'Dashboard'),
          )),
          label: ValoraI18n.tr('ASSISTENTE'),
        ),
      );

  Widget _menuCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    String? trailingText,
  }) {
    final imageUrl = ValoraAppearance.instance.imageUrls[title] ??
        ValoraAppearance.instance.imageUrls[
            title == 'VENDITE E INSERZIONI' ? 'VENDITE' : title];
    return DashboardMenuCard(
      title: title,
      subtitle: subtitle,
      color: color,
      icon: icon,
      onTap: onTap,
      trailingText: trailingText,
      imageUrl: imageUrl,
    );
  }

  Widget buildDashboard() => DashboardHomeContent(
        useBlockLayout: ValoraAppearance.instance.useBlockLayout,
        blockContentBuilder: () {
          final entries = <Map<String, dynamic>>[
            {'title':'COLLEZIONE','subtitle':'Tutti i temi e tutti i record','color':goldColor,'icon':Icons.inventory_2_outlined,'tap':() => setState(() => showCollection=true)},
            ...dashboardSections.map((section)=> {
              'title':ValoraI18n.tr(section.menuTitle ?? section.title),
              'sectionKey':section.title,
              'subtitle':ValoraI18n.tr(section.description),
              'color':ValoraAppearance.instance.colorFor(section.title),
              'icon':section.icon,
              'tap':() => setState(()=>selectedSection=section),
            }),
          ];
          return DashboardHomeBlockContent(
            entries: entries,
            catalogLoading: _catalogLoading,
            catalogCount: _catalogRows.length,
            imageUrlFor: (title) {
              final url = ValoraAppearance.instance.imageUrls[title] ??
                  ValoraAppearance.instance.imageUrls[
                      title == 'VENDITE E INSERZIONI' ? 'VENDITE' : title];
              return url == null ? null : _valoraImageProxyUrl(url);
            },
          );
        },
        listContentBuilder: () => DashboardHomeListContent(
          header: DashboardHomeHeader(
            title: ValoraI18n.tr('CENTRO OPERATIVO'),
            subtitle: ValoraI18n.tr('Scegli una sezione per accedere alle relative funzioni.'),
          ),
          collectionCard: _menuCard(
            title: ValoraI18n.tr('COLLEZIONE'),
            subtitle: ValoraI18n.tr('Tutti i temi e tutti i record della tua collezione'),
            color: goldColor,
            icon: Icons.inventory_2_outlined,
            trailingText: _catalogLoading ? '…' : '${_catalogRows.length} record',
            onTap: () { setState(() => showCollection = true); _loadDashboardCatalog(); },
          ),
          sectionCards: dashboardSections.map((section) => _menuCard(
            title: ValoraI18n.tr(section.menuTitle ?? section.title),
            subtitle: ValoraI18n.tr(section.description),
            color: ValoraAppearance.instance.colorFor(section.title),
            icon: section.icon,
            onTap: () => setState(() => selectedSection = section),
          )).toList(),
          catalogError: _catalogError != null
              ? DashboardCatalogCountErrorNotice(message: 'Conteggio catalogo non disponibile: $_catalogError')
              : null,
          footer: const DashboardHomeFooter(),
        ),
      );

  Widget buildCollection() => DashboardCollectionContent(
    catalogLoading: _catalogLoading,
    catalogError: _catalogError,
    catalogRows: _catalogRows,
    categories: _collectionCategories,
    categoryCounts: _collectionCategoryCounts,
    categoryFor: _dashboardCategory,
    imageUrlFor: (row) {
      final url = _dashboardImageUrl(row);
      return url == null ? null : _valoraImageProxyUrl(url);
    },
    onCategoryTap: (name, code) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CategoryObjectSearchPage(initialQuery: name, initialCategoryCode: code),
    )),
  );

  String _sectionBackgroundAsset(String section) {
    const assets = <String, String>{
      'VENDITE': 'assets/menu_sections/01_VENDITE.jpg',
      'ACQUISTI': 'assets/menu_sections/02_ACQUISTI.jpg',
      'RICERCHE': 'assets/menu_sections/a_vibrant_neon_cyber_desk_scene_matching_the_app_s.png',
      'VALUTAZIONI': 'assets/menu_sections/VALORA_VALUTAZIONI_GIALLO.jpg',
      'CATALOGO': 'assets/menu_sections/05_CATALOGO.jpg',
      'REPORT': 'assets/menu_sections/06_REPORT.jpg',
      'COLLEZIONE': 'assets/menu_sections/01_collezione_personale.png',
    };
    return assets[section] ?? '';
  }

  Widget buildSection(DashboardSection section) {
    final procedures = sectionProcedures[section.title] ?? const <ProcedureEntry>[];
    final appearance = ValoraAppearance.instance;
    return DashboardSectionContent(
      background: const SizedBox.shrink(),
      header: DashboardSectionHeader(
        title: section.title,
        description: ValoraI18n.tr(section.description),
        accentColor: appearance.colorFor(section.title),
        secondaryTextColor: appearance.textSecondary,
      ),
      showHeader: !['CATALOGO', 'ACQUISTI', 'VENDITE', 'VALUTAZIONI', 'REPORT', 'RICERCHE'].contains(section.title),
      procedureCards: [
            ...procedures.map((procedure) => ProcedureCard(
            procedure: procedure,
            title: ValoraI18n.tr(procedure.title),
            description: ValoraI18n.tr(procedure.description),
            accentColor: appearance.colorFor(section.title),
            textPrimary: appearance.textPrimary,
            textFaint: appearance.textFaint,
            neutralOverlay: appearance.neutralOverlay,
            neutralOverlayStrong: appearance.neutralOverlayStrong,
            onTap: !procedure.enabled
                ? null
                : procedure.apiCode == 'WANTED-NEW'
                    ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WantedNewDesirePage()))
                    : procedure.apiCode == 'WANTED-ACTIVE'
                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WantedActiveDesiresPage()))
                    : procedure.apiCode == 'WANTED-GOALS'
                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WantedPurchaseObjectivesPage()))
                    : procedure.apiCode == 'WANTED-PURCHASE'
                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WantedPurchasePage()))
                    : procedure.apiCode == 'WANTED-OFFERS'
                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WantedOffersPage()))
                    : procedure.apiCode == 'PR-21-SEARCH'
                    ? () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const CategoryObjectSearchPage()))
                    : (procedure.apiCode == 'OBJECT-IMPORT' || procedure.apiCode == 'OBJECT-EXPORT')
                        ? () => Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ObjectTransferPage(importMode: procedure.apiCode == 'OBJECT-IMPORT')))
                        : procedure.apiCode == 'PURCHASES-COMPARE'
                            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PurchaseComparisonPage()))
                            : procedure.apiCode == 'SOURCE-REGISTRY'
                            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SourceRegistryPage()))
                            : (procedure.apiCode == 'CREATE-COLLECTION-CATEGORY' || procedure.apiCode == 'EDIT-COLLECTION-CATEGORY')
                                ? () async { await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectibleCategoryRegistryPage())); await _loadDashboardCatalog(); }
                                : procedure.apiCode == 'USER-SALES-PLATFORMS'
                                    ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserSalesPlatformsPage()))
                                    : procedure.apiCode == 'VALORA-LISTING-DRAFTS'
                                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Pr06ValoraListingDraftLibraryPage()))
                                        : procedure.apiCode == 'LAUNCH-VALORA'
                                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ValoraServicePage()))
                                        : procedure.apiCode == 'LAUNCH-COLLECTION-VALUE'
                                            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionValuePage()))
                                            : procedure.apiCode == 'WRITE-PR-04'
                                                ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewPurchasePage()))
                                                : procedure.apiCode == 'WRITE-PR-05'
                                                    ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditPurchasePage()))
                                                    : procedure.apiCode == 'WRITE-PR-07'
                                          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Pr07EditSalesPage()))
                                      : procedure.apiCode == 'WRITE-PR-06'
                                                        ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewSalePage()))
                                                        : procedure.apiCode == 'WRITE-PR-08'
                                                            ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Pr08CloseSalesPage()))
                                                            : procedure.apiCode == 'WRITE-PR-09'
                                                                 ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Pr09CancelSalesPage()))
                                                                 : procedure.apiCode != null
                                                                ? () => Navigator.of(context).push(MaterialPageRoute(
                                                                      builder: (_) => procedure.apiCode == 'REPORT-ACTIVE-LISTINGS'
                                                                           ? const ActiveSalesReportPage()
                                                                           : procedure.apiCode == 'REPORT-SALES'
                                                                               ? const SalesReportPage()
                                                                               : procedure.apiCode == 'PR-12-BATCH'
                                                                          ? const Pr12BatchPage()
                                                                          : ObjectRuntimePage(title: procedure.title, apiCode: procedure.apiCode == 'WRITE-PR-08' ? 'PR-08' : procedure.apiCode == 'WRITE-PR-07' ? 'PR-07' : procedure.apiCode == 'WRITE-PR-09' ? 'PR-09' : procedure.apiCode == 'WRITE-PR-06' ? 'PR-06' : procedure.apiCode!)))
                                                                : null,
          )),
      ],
      footer: DashboardSectionFooter(
        label: ValoraI18n.tr('TORNA ALLA DASHBOARD'),
        accentColor: appearance.colorFor(section.title),
        onPressed: () => setState(() => selectedSection = null),
      ),
    );
  }

  void showProcedureInfo(ProcedureEntry procedure) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => DashboardProcedureInfoDialog(
        title: ValoraI18n.tr(procedure.title),
        description: ValoraI18n.tr(procedure.description),
        closeLabel: ValoraI18n.tr('CHIUDI'),
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}
