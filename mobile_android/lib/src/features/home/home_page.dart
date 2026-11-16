import 'package:flutter/material.dart';
import '../auth/auth_copy.dart';
import '../auth/auth_repository.dart';
import '../../theme/valora_appearance.dart';

class _MenuBlock {
  const _MenuBlock(this.key, this.title, this.description, this.icon, this.color, this.items);
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> items;
}

const _blocks = <_MenuBlock>[
  _MenuBlock('COLLEZIONE', 'COLLEZIONE', 'Tutti i temi e tutti i record', Icons.inventory_2_outlined, Color(0xFFD6B15E), ['Apri collezione', 'Categorie collezionistiche', 'Ricerca schede']),
  _MenuBlock('CATALOGO', 'CATALOGO', 'Consulta e gestisci gli oggetti', Icons.inventory_2_outlined, Color(0xFF3978C5), ['Nuovo oggetto · PR-01', 'Modifica oggetto · PR-02', 'Chiudi oggetto · PR-03', 'Visualizza scheda', 'Elenco oggetti disponibili', 'Storico oggetto', 'Importa oggetti', 'Esporta oggetti']),
  _MenuBlock('WANTED LIST', 'WANTED LIST', 'Desideri, obiettivi, offerte e storico', Icons.bookmark_outline, Color(0xFFB8BEC6), ['Nuovo desiderio', 'Lista dei desideri', 'Obiettivi di acquisto', 'Acquisto Wanted List', 'Ricerca offerte', 'Storico Wanted List']),
  _MenuBlock('ACQUISTI', 'ACQUISTI', 'Gestione acquisti e allocazioni', Icons.shopping_cart_outlined, Color(0xFFC74444), ['Nuovo acquisto · PR-04', 'Modifica acquisto · PR-05', 'PR-15 · Preorder', 'Acquisti comparati', 'Report acquisti']),
  _MenuBlock('VENDITE', 'VENDITE', 'Vendite', Icons.sell_outlined, Color(0xFF39875B), ['Nuova vendita · PR-06', 'Modifica vendita · PR-07', 'Chiudi vendita · PR-08', 'Annulla vendita · PR-09', 'Report vendite attive', 'Report vendite', 'Bozze inserzioni VALORA']),
  _MenuBlock('VALUTAZIONI', 'VALUTAZIONI', 'VALORA e valore della collezione', Icons.query_stats, Color(0xFF8556C7), ['PR-11 · Valutazione complessiva collezione', 'PR-13 · Ricerca offerta', 'PR-14 · Assistente VALORA']),
  _MenuBlock('REPORT', 'REPORT', 'Riepiloghi e risultati', Icons.analytics_outlined, Color(0xFFE17D35), ['Report per franchise / tema', 'Flussi di cassa', 'Report mattutino']),
  _MenuBlock('RICERCHE', 'RICERCHE', 'Ricerca oggetti e fonti', Icons.search, Color(0xFFD6A83F), ['PR-21 · Ricerca schede', 'PR-12 · Ricerca metadati in lotti', 'Registro fonti · Cataloghi e siti', 'Le mie piattaforme di vendita']),
  _MenuBlock('CONTROLLO', 'CONTROLLO', 'Stato e verifiche del sistema', Icons.admin_panel_settings_outlined, Color(0xFF777777), ['Stato runtime', 'Catalogo API', 'Pulizia file', 'Crea categoria collezione', 'Modifica categoria collezione']),
];

String _menuText(BuildContext context, String key) {
  const values = <String, Map<String, String>>{
    'COLLEZIONE': {'it':'COLLEZIONE','en':'COLLECTION','fr':'COLLECTION','de':'SAMMLUNG','es':'COLECCIÓN','pt':'COLEÇÃO','zh':'收藏','ja':'コレクション'},
    'CATALOGO': {'it':'CATALOGO','en':'CATALOG','fr':'CATALOGUE','de':'KATALOG','es':'CATÁLOGO','pt':'CATÁLOGO','zh':'目录','ja':'カタログ'},
    'WANTED LIST': {'it':'WANTED LIST','en':'WANTED LIST','fr':'LISTE DE SOUHAITS','de':'WUNSCHLISTE','es':'LISTA DE DESEOS','pt':'LISTA DE DESEJOS','zh':'愿望清单','ja':'ウィッシュリスト'},
    'ACQUISTI': {'it':'ACQUISTI','en':'PURCHASES','fr':'ACHATS','de':'EINKÄUFE','es':'COMPRAS','pt':'COMPRAS','zh':'购入','ja':'購入'},
    'VENDITE': {'it':'VENDITE','en':'SALES','fr':'VENTES','de':'VERKÄUFE','es':'VENTAS','pt':'VENDAS','zh':'销售','ja':'販売'},
    'VALUTAZIONI': {'it':'VALUTAZIONI','en':'VALUATIONS','fr':'ÉVALUATIONS','de':'BEWERTUNGEN','es':'VALORACIONES','pt':'AVALIAÇÕES','zh':'估值','ja':'評価'},
    'REPORT': {'it':'REPORT','en':'REPORTS','fr':'RAPPORTS','de':'BERICHTE','es':'INFORMES','pt':'RELATÓRIOS','zh':'报告','ja':'レポート'},
    'RICERCHE': {'it':'RICERCHE','en':'SEARCHES','fr':'RECHERCHES','de':'SUCHEN','es':'BÚSQUEDAS','pt':'PESQUISAS','zh':'搜索','ja':'検索'},
    'CONTROLLO': {'it':'CONTROLLO','en':'SYSTEM CONTROL','fr':'CONTRÔLE','de':'SYSTEMKONTROLLE','es':'CONTROL','pt':'CONTROLO','zh':'系统控制','ja':'システム管理'},
    'chooseBlock': {'it':'Scegli un blocco per aprire il relativo menu','en':'Choose a block to open its menu','fr':'Choisissez un bloc pour ouvrir son menu','de':'Wähle einen Bereich, um das Menü zu öffnen','es':'Elige un bloque para abrir su menú','pt':'Escolha um bloco para abrir o menu','zh':'选择一个模块以打开菜单','ja':'ブロックを選択してメニューを開く'},
    'back': {'it':'Menu principale','en':'Main menu','fr':'Menu principal','de':'Hauptmenü','es':'Menú principal','pt':'Menu principal','zh':'主菜单','ja':'メインメニュー'},
    'notMigrated': {'it':'La pagina operativa di questa funzione deve ancora essere trasferita da TEST1. Il collegamento del menu è predisposto.','en':'The operational page for this feature still needs to be migrated from TEST1. The menu link is prepared.','fr':'La page opérationnelle doit encore être transférée depuis TEST1. Le lien du menu est prêt.','de':'Die Funktionsseite muss noch aus TEST1 übertragen werden. Der Menülink ist vorbereitet.','es':'La página operativa aún debe migrarse desde TEST1. El enlace del menú está preparado.','pt':'A página operacional ainda precisa ser migrada do TEST1. O link do menu está preparado.','zh':'此功能的操作页面仍需从 TEST1 迁移，菜单入口已准备好。','ja':'この機能の操作ページはTEST1からの移行が必要です。メニューリンクは準備済みです。'},
  };
  final lang = Localizations.localeOf(context).languageCode;
  return values[key]?[lang] ?? values[key]?['it'] ?? key;
}


String _localizedMenuLabel(BuildContext context, String label) {
  const translations = <String, Map<String, String>>{
    'Tutti i temi e tutti i record': {'it':'Tutti i temi e tutti i record','en':'All themes and all records','fr':'Tous les thèmes et tous les objets','de':'Alle Themen und alle Einträge','es':'Todos los temas y registros','pt':'Todos os temas e registos','zh':'所有主题和记录','ja':'すべてのテーマとレコード'},
    'Consulta e gestisci gli oggetti': {'it':'Consulta e gestisci gli oggetti','en':'Browse and manage objects','fr':'Consulter et gérer les objets','de':'Objekte anzeigen und verwalten','es':'Consulta y gestiona objetos','pt':'Consultar e gerir objetos','zh':'查看和管理藏品','ja':'アイテムの閲覧と管理'},
    'Desideri, obiettivi, offerte e storico': {'it':'Desideri, obiettivi, offerte e storico','en':'Wishes, goals, offers and history','fr':'Souhaits, objectifs, offres et historique','de':'Wünsche, Ziele, Angebote und Verlauf','es':'Deseos, objetivos, ofertas e historial','pt':'Desejos, objetivos, ofertas e histórico','zh':'愿望、目标、报价与历史','ja':'希望、目標、オファー、履歴'},
    'Gestione acquisti e allocazioni': {'it':'Gestione acquisti e allocazioni','en':'Purchases and allocations','fr':'Achats et affectations','de':'Einkäufe und Zuordnungen','es':'Compras y asignaciones','pt':'Compras e alocações','zh':'购买与分配管理','ja':'購入と割り当て管理'},
    'Vendite': {'it':'Vendite','en':'Sales','fr':'Ventes','de':'Verkäufe','es':'Ventas','pt':'Vendas','zh':'销售','ja':'販売'},
    'VALORA e valore della collezione': {'it':'VALORA e valore della collezione','en':'VALORA and collection value','fr':'VALORA et valeur de la collection','de':'VALORA und Sammlungswert','es':'VALORA y valor de la colección','pt':'VALORA e valor da coleção','zh':'VALORA 与收藏价值','ja':'VALORAとコレクション価値'},
    'Riepiloghi e risultati': {'it':'Riepiloghi e risultati','en':'Summaries and results','fr':'Synthèses et résultats','de':'Übersichten und Ergebnisse','es':'Resúmenes y resultados','pt':'Resumos e resultados','zh':'汇总与结果','ja':'概要と結果'},
    'Ricerca oggetti e fonti': {'it':'Ricerca oggetti e fonti','en':'Object and source search','fr':'Recherche d’objets et de sources','de':'Objekt- und Quellensuche','es':'Búsqueda de objetos y fuentes','pt':'Pesquisa de objetos e fontes','zh':'藏品与来源搜索','ja':'アイテムと情報源の検索'},
    'Stato e verifiche del sistema': {'it':'Stato e verifiche del sistema','en':'System status and checks','fr':'État et contrôles du système','de':'Systemstatus und Prüfungen','es':'Estado y comprobaciones del sistema','pt':'Estado e verificações do sistema','zh':'系统状态与检查','ja':'システム状態と確認'},
    'Apri collezione': {'it':'Apri collezione','en':'Open collection','fr':'Ouvrir la collection','de':'Sammlung öffnen','es':'Abrir colección','pt':'Abrir coleção','zh':'打开收藏','ja':'コレクションを開く'},
    'Categorie collezionistiche': {'it':'Categorie collezionistiche','en':'Collection categories','fr':'Catégories de collection','de':'Sammlungskategorien','es':'Categorías de colección','pt':'Categorias da coleção','zh':'收藏分类','ja':'コレクションカテゴリ'},
    'Ricerca schede': {'it':'Ricerca schede','en':'Record search','fr':'Recherche de fiches','de':'Datensatzsuche','es':'Búsqueda de fichas','pt':'Pesquisa de registos','zh':'记录搜索','ja':'レコード検索'},
    'Nuovo oggetto · PR-01': {'it':'Nuovo oggetto · PR-01','en':'New object · PR-01','fr':'Nouvel objet · PR-01','de':'Neues Objekt · PR-01','es':'Nuevo objeto · PR-01','pt':'Novo objeto · PR-01','zh':'新增藏品 · PR-01','ja':'新規アイテム · PR-01'},
    'Modifica oggetto · PR-02': {'it':'Modifica oggetto · PR-02','en':'Edit object · PR-02','fr':'Modifier l’objet · PR-02','de':'Objekt bearbeiten · PR-02','es':'Editar objeto · PR-02','pt':'Editar objeto · PR-02','zh':'编辑藏品 · PR-02','ja':'アイテム編集 · PR-02'},
    'Chiudi oggetto · PR-03': {'it':'Chiudi oggetto · PR-03','en':'Close object · PR-03','fr':'Clôturer l’objet · PR-03','de':'Objekt abschließen · PR-03','es':'Cerrar objeto · PR-03','pt':'Fechar objeto · PR-03','zh':'关闭藏品 · PR-03','ja':'アイテムを終了 · PR-03'},
    'Visualizza scheda': {'it':'Visualizza scheda','en':'View record','fr':'Voir la fiche','de':'Datensatz anzeigen','es':'Ver ficha','pt':'Ver registo','zh':'查看记录','ja':'レコードを表示'},
    'Elenco oggetti disponibili': {'it':'Elenco oggetti disponibili','en':'Available objects','fr':'Objets disponibles','de':'Verfügbare Objekte','es':'Objetos disponibles','pt':'Objetos disponíveis','zh':'可用藏品列表','ja':'利用可能なアイテム'},
    'Storico oggetto': {'it':'Storico oggetto','en':'Object history','fr':'Historique de l’objet','de':'Objektverlauf','es':'Historial del objeto','pt':'Histórico do objeto','zh':'藏品历史','ja':'アイテム履歴'},
    'Importa oggetti': {'it':'Importa oggetti','en':'Import objects','fr':'Importer des objets','de':'Objekte importieren','es':'Importar objetos','pt':'Importar objetos','zh':'导入藏品','ja':'アイテムをインポート'},
    'Esporta oggetti': {'it':'Esporta oggetti','en':'Export objects','fr':'Exporter des objets','de':'Objekte exportieren','es':'Exportar objetos','pt':'Exportar objetos','zh':'导出藏品','ja':'アイテムをエクスポート'},
    'Nuovo desiderio': {'it':'Nuovo desiderio','en':'New wish','fr':'Nouveau souhait','de':'Neuer Wunsch','es':'Nuevo deseo','pt':'Novo desejo','zh':'新增愿望','ja':'新しい希望'},
    'Lista dei desideri': {'it':'Lista dei desideri','en':'Wish list','fr':'Liste des souhaits','de':'Wunschliste','es':'Lista de deseos','pt':'Lista de desejos','zh':'愿望清单','ja':'ウィッシュリスト'},
    'Obiettivi di acquisto': {'it':'Obiettivi di acquisto','en':'Purchase goals','fr':'Objectifs d’achat','de':'Kaufziele','es':'Objetivos de compra','pt':'Objetivos de compra','zh':'购买目标','ja':'購入目標'},
    'Acquisto Wanted List': {'it':'Acquisto Wanted List','en':'Wanted List purchase','fr':'Achat Wanted List','de':'Wanted-List-Kauf','es':'Compra de Wanted List','pt':'Compra da Wanted List','zh':'愿望清单购买','ja':'ウィッシュリスト購入'},
    'Ricerca offerte': {'it':'Ricerca offerte','en':'Search offers','fr':'Rechercher des offres','de':'Angebote suchen','es':'Buscar ofertas','pt':'Pesquisar ofertas','zh':'搜索报价','ja':'オファーを検索'},
    'Storico Wanted List': {'it':'Storico Wanted List','en':'Wanted List history','fr':'Historique Wanted List','de':'Wanted-List-Verlauf','es':'Historial Wanted List','pt':'Histórico Wanted List','zh':'愿望清单历史','ja':'ウィッシュリスト履歴'},
    'Nuovo acquisto · PR-04': {'it':'Nuovo acquisto · PR-04','en':'New purchase · PR-04','fr':'Nouvel achat · PR-04','de':'Neuer Einkauf · PR-04','es':'Nueva compra · PR-04','pt':'Nova compra · PR-04','zh':'新增购买 · PR-04','ja':'新規購入 · PR-04'},
    'Modifica acquisto · PR-05': {'it':'Modifica acquisto · PR-05','en':'Edit purchase · PR-05','fr':'Modifier l’achat · PR-05','de':'Einkauf bearbeiten · PR-05','es':'Editar compra · PR-05','pt':'Editar compra · PR-05','zh':'编辑购买 · PR-05','ja':'購入を編集 · PR-05'},
    'PR-15 · Preorder': {'it':'PR-15 · Preorder','en':'PR-15 · Preorder','fr':'PR-15 · Précommande','de':'PR-15 · Vorbestellung','es':'PR-15 · Preventa','pt':'PR-15 · Pré-encomenda','zh':'PR-15 · 预订','ja':'PR-15 · 予約'},
    'Acquisti comparati': {'it':'Acquisti comparati','en':'Purchase comparison','fr':'Comparaison des achats','de':'Einkaufsvergleich','es':'Comparativa de compras','pt':'Comparação de compras','zh':'购买对比','ja':'購入比較'},
    'Report acquisti': {'it':'Report acquisti','en':'Purchase report','fr':'Rapport des achats','de':'Einkaufsbericht','es':'Informe de compras','pt':'Relatório de compras','zh':'购买报告','ja':'購入レポート'},
    'Nuova vendita · PR-06': {'it':'Nuova vendita · PR-06','en':'New sale · PR-06','fr':'Nouvelle vente · PR-06','de':'Neuer Verkauf · PR-06','es':'Nueva venta · PR-06','pt':'Nova venda · PR-06','zh':'新增销售 · PR-06','ja':'新規販売 · PR-06'},
    'Modifica vendita · PR-07': {'it':'Modifica vendita · PR-07','en':'Edit sale · PR-07','fr':'Modifier la vente · PR-07','de':'Verkauf bearbeiten · PR-07','es':'Editar venta · PR-07','pt':'Editar venda · PR-07','zh':'编辑销售 · PR-07','ja':'販売を編集 · PR-07'},
    'Chiudi vendita · PR-08': {'it':'Chiudi vendita · PR-08','en':'Close sale · PR-08','fr':'Clôturer la vente · PR-08','de':'Verkauf abschließen · PR-08','es':'Cerrar venta · PR-08','pt':'Fechar venda · PR-08','zh':'完成销售 · PR-08','ja':'販売を完了 · PR-08'},
    'Annulla vendita · PR-09': {'it':'Annulla vendita · PR-09','en':'Cancel sale · PR-09','fr':'Annuler la vente · PR-09','de':'Verkauf stornieren · PR-09','es':'Anular venta · PR-09','pt':'Cancelar venda · PR-09','zh':'取消销售 · PR-09','ja':'販売を取り消す · PR-09'},
    'Report vendite attive': {'it':'Report vendite attive','en':'Active sales report','fr':'Rapport des ventes actives','de':'Bericht aktive Verkäufe','es':'Informe de ventas activas','pt':'Relatório de vendas ativas','zh':'在售商品报告','ja':'販売中レポート'},
    'Report vendite': {'it':'Report vendite','en':'Sales report','fr':'Rapport des ventes','de':'Verkaufsbericht','es':'Informe de ventas','pt':'Relatório de vendas','zh':'销售报告','ja':'販売レポート'},
    'Bozze inserzioni VALORA': {'it':'Bozze inserzioni VALORA','en':'VALORA listing drafts','fr':'Brouillons d’annonces VALORA','de':'VALORA-Anzeigenentwürfe','es':'Borradores de anuncios VALORA','pt':'Rascunhos de anúncios VALORA','zh':'VALORA刊登草稿','ja':'VALORA出品下書き'},
    'PR-11 · Valutazione complessiva collezione': {'it':'PR-11 · Valutazione complessiva collezione','en':'PR-11 · Complete collection valuation','fr':'PR-11 · Évaluation complète de la collection','de':'PR-11 · Gesamtbewertung der Sammlung','es':'PR-11 · Valoración completa de la colección','pt':'PR-11 · Avaliação completa da coleção','zh':'PR-11 · 收藏整体估值','ja':'PR-11 · コレクション総合評価'},
    'PR-13 · Ricerca offerta': {'it':'PR-13 · Ricerca offerta','en':'PR-13 · Offer search','fr':'PR-13 · Recherche d’offre','de':'PR-13 · Angebotssuche','es':'PR-13 · Búsqueda de ofertas','pt':'PR-13 · Pesquisa de ofertas','zh':'PR-13 · 报价搜索','ja':'PR-13 · オファー検索'},
    'PR-14 · Assistente VALORA': {'it':'PR-14 · Assistente VALORA','en':'PR-14 · VALORA Assistant','fr':'PR-14 · Assistant VALORA','de':'PR-14 · VALORA-Assistent','es':'PR-14 · Asistente VALORA','pt':'PR-14 · Assistente VALORA','zh':'PR-14 · VALORA助手','ja':'PR-14 · VALORAアシスタント'},
    'Report per franchise / tema': {'it':'Report per franchise / tema','en':'Franchise / theme report','fr':'Rapport par franchise / thème','de':'Bericht nach Franchise / Thema','es':'Informe por franquicia / tema','pt':'Relatório por franquia / tema','zh':'按系列／主题报告','ja':'シリーズ／テーマ別レポート'},
    'Flussi di cassa': {'it':'Flussi di cassa','en':'Cash flows','fr':'Flux de trésorerie','de':'Cashflow','es':'Flujos de caja','pt':'Fluxos de caixa','zh':'现金流','ja':'キャッシュフロー'},
    'Report mattutino': {'it':'Report mattutino','en':'Morning report','fr':'Rapport du matin','de':'Morgenbericht','es':'Informe matutino','pt':'Relatório da manhã','zh':'晨间报告','ja':'朝のレポート'},
    'PR-21 · Ricerca schede': {'it':'PR-21 · Ricerca schede','en':'PR-21 · Record search','fr':'PR-21 · Recherche de fiches','de':'PR-21 · Datensatzsuche','es':'PR-21 · Búsqueda de fichas','pt':'PR-21 · Pesquisa de registos','zh':'PR-21 · 记录搜索','ja':'PR-21 · レコード検索'},
    'PR-12 · Ricerca metadati in lotti': {'it':'PR-12 · Ricerca metadati in lotti','en':'PR-12 · Batch metadata search','fr':'PR-12 · Recherche de métadonnées par lots','de':'PR-12 · Metadatensuche in Stapeln','es':'PR-12 · Búsqueda de metadatos por lotes','pt':'PR-12 · Pesquisa de metadados em lotes','zh':'PR-12 · 批量元数据搜索','ja':'PR-12 · メタデータ一括検索'},
    'Registro fonti · Cataloghi e siti': {'it':'Registro fonti · Cataloghi e siti','en':'Source registry · Catalogs and sites','fr':'Registre des sources · Catalogues et sites','de':'Quellenregister · Kataloge und Websites','es':'Registro de fuentes · Catálogos y sitios','pt':'Registo de fontes · Catálogos e sites','zh':'来源登记 · 目录与网站','ja':'情報源台帳 · カタログとサイト'},
    'Le mie piattaforme di vendita': {'it':'Le mie piattaforme di vendita','en':'My sales platforms','fr':'Mes plateformes de vente','de':'Meine Verkaufsplattformen','es':'Mis plataformas de venta','pt':'As minhas plataformas de venda','zh':'我的销售平台','ja':'販売プラットフォーム'},
    'Stato runtime': {'it':'Stato runtime','en':'Runtime status','fr':'État du runtime','de':'Laufzeitstatus','es':'Estado del runtime','pt':'Estado do runtime','zh':'运行状态','ja':'ランタイム状態'},
    'Catalogo API': {'it':'Catalogo API','en':'API catalog','fr':'Catalogue API','de':'API-Katalog','es':'Catálogo API','pt':'Catálogo API','zh':'API目录','ja':'APIカタログ'},
    'Pulizia file': {'it':'Pulizia file','en':'File cleanup','fr':'Nettoyage des fichiers','de':'Dateibereinigung','es':'Limpieza de archivos','pt':'Limpeza de ficheiros','zh':'文件清理','ja':'ファイル整理'},
    'Crea categoria collezione': {'it':'Crea categoria collezione','en':'Create collection category','fr':'Créer une catégorie de collection','de':'Sammlungskategorie erstellen','es':'Crear categoría de colección','pt':'Criar categoria da coleção','zh':'创建收藏分类','ja':'コレクションカテゴリを作成'},
    'Modifica categoria collezione': {'it':'Modifica categoria collezione','en':'Edit collection category','fr':'Modifier une catégorie de collection','de':'Sammlungskategorie bearbeiten','es':'Editar categoría de colección','pt':'Editar categoria da coleção','zh':'编辑收藏分类','ja':'コレクションカテゴリを編集'},
  };
  final lang = Localizations.localeOf(context).languageCode;
  return translations[label]?[lang] ?? translations[label]?['it'] ?? label;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});
  final AuthRepository repository;
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedBlock;
  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final block = _blocks.firstWhere((item) => item.key == _selectedBlock, orElse: () => _blocks.first);
    final inSection = _selectedBlock != null;
    return Scaffold(
      appBar: AppBar(
        leading: inSection ? IconButton(icon: const Icon(Icons.arrow_back), tooltip: _menuText(context, 'back'), onPressed: () => setState(() => _selectedBlock = null)) : null,
        title: Text(inSection ? _menuText(context, block.title) : authText(context, 'home')),
        actions: [
          if (!inSection) IconButton(tooltip: appearance.listMode ? 'Griglia' : 'Elenco', onPressed: appearance.toggleLayout, icon: Icon(appearance.listMode ? Icons.grid_view_rounded : Icons.view_agenda_rounded)),
          IconButton(tooltip: appearanceText(context, 'appearance'), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppearanceSettingsPage())), icon: const Icon(Icons.palette_outlined)),
          IconButton(tooltip: authText(context, 'logout'), onPressed: widget.repository.signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListenableBuilder(
        listenable: appearance,
        builder: (context, _) {
          final preset = appearance.selected;
          return Stack(fit: StackFit.expand, children: [
            Image.asset(themeBackgroundAsset(preset.id), key: ValueKey(preset.id), fit: BoxFit.cover, alignment: Alignment.center, errorBuilder: (_, __, ___) => ColoredBox(color: preset.background)),
            ColoredBox(color: Colors.black.withValues(alpha: .20)),
            SafeArea(
              top: false,
              child: inSection ? _buildSectionMenu(context, block) : _buildMainMenu(context),
            ),
          ]);
        },
      ),
    );
  }

  Widget _buildMainMenu(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final header = Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(_menuText(context, 'chooseBlock'), textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
    );
    if (appearance.listMode) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
        children: [
          header,
          ..._blocks.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MainMenuBlockListCard(block: item, title: _menuText(context, item.title),
              onTap: () => setState(() => _selectedBlock = item.key)),
          )),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
      children: [
        header,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _blocks.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.12, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemBuilder: (context, index) {
            final item = _blocks[index];
            return _MainMenuBlockCard(block: item, title: _menuText(context, item.title), onTap: () => setState(() => _selectedBlock = item.key));
          },
        ),
      ],
    );
  }

  Widget _buildSectionMenu(BuildContext context, _MenuBlock block) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
    children: [
      Text(_localizedMenuLabel(context, block.description), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
      const SizedBox(height: 16),
      ...block.items.map((label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Colors.black.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
              title: Text(label),
              content: Text(_menuText(context, 'notMigrated')),
              actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
            )),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              child: Row(children: [
                Icon(Icons.chevron_right, color: block.color),
                const SizedBox(width: 10),
                Expanded(child: Text(_localizedMenuLabel(context, label), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        ),
      )),
    ],
  );
}

class _MainMenuBlockCard extends StatelessWidget {
  const _MainMenuBlockCard({required this.block, required this.title, required this.onTap});
  final _MenuBlock block;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: .70),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: block.color.withValues(alpha: .95), width: 2)),
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(block.icon, size: 36, color: block.color),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: TextStyle(color: block.key == 'WANTED LIST' ? const Color(0xFFE0E4E8) : Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 5),
          Text(block.description, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    ),
  );
}

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    return Scaffold(
      appBar: AppBar(title: Text(appearanceText(context, 'appearance'))),
      body: ListenableBuilder(
        listenable: appearance,
        builder: (context, _) {
          return SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  appearanceText(context, 'choose'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.32,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: ValoraAppearance.presets.length,
                itemBuilder: (context, index) {
                  final preset = ValoraAppearance.presets[index];
                  final selected = preset.id == appearance.selectedThemeId;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => appearance.setTheme(preset.id),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? preset.accent
                              : Theme.of(context).dividerColor,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            themeBackgroundAsset(preset.id),
                            fit: BoxFit.cover,
                          ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              color: preset.card.withValues(alpha: .92),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 8,
                              ),
                              child: Text(
                                preset.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: preset.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (selected)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Icon(
                                Icons.check_circle,
                                color: preset.accent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            ),
          );
        },
      ),
    );
  }
}

class _MainMenuBlockListCard extends StatelessWidget {
  const _MainMenuBlockListCard({required this.block, required this.title, required this.onTap});
  final _MenuBlock block;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: block.color.withValues(alpha: .17),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
          border: Border.all(color: block.color.withValues(alpha: .95), width: 1.6)),
        child: Row(children: [
          Container(width: 58, height: 58,
            decoration: BoxDecoration(color: block.color.withValues(alpha: .18), borderRadius: BorderRadius.circular(14)),
            child: Icon(block.icon, color: block.color, size: 30)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: block.key == 'WANTED LIST' ? const Color(0xFFE0E4E8) : block.color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 7),
            Text(_localizedMenuLabel(context, block.description), maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ])),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: block.color, size: 30),
        ]),
      ),
    ),
  );
}
