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

const _blockColors = <String, Color>{
  'CATALOGO': Color(0xFF3978C5),
  'WANTED LIST': Color(0xFFB8BEC6),
  'ACQUISTI': Color(0xFFC74444),
  'VENDITE': Color(0xFF39875B),
  'VALUTAZIONI': Color(0xFF8556C7),
  'REPORT': Color(0xFFE17D35),
  'RICERCHE': Color(0xFFD6A83F),
  'CONTROLLO': Color(0xFF777777),
};

const _blocks = <_MenuBlock>[
  _MenuBlock('COLLEZIONE', 'COLLEZIONE', 'Tutti i temi e tutti i record', Icons.inventory_2_outlined, Color(0xFFD6B15E), ['Apri collezione', 'Categorie collezionistiche', 'Ricerca schede']),
  _MenuBlock('CATALOGO', 'CATALOGO', 'Consulta e gestisci gli oggetti', Icons.inventory_2_outlined, Color(0xFF3978C5), ['Nuovo oggetto · PR-01', 'Modifica oggetto · PR-02', 'Chiudi oggetto · PR-03', 'Visualizza scheda', 'Elenco oggetti disponibili', 'Storico oggetto', 'Importa oggetti', 'Esporta oggetti']),
  _MenuBlock('WANTED LIST', 'WANTED LIST', 'Desideri, obiettivi, offerte e storico', Icons.bookmark_outline, Color(0xFFB8BEC6), ['Nuovo desiderio', 'Lista dei desideri', 'Obiettivi di acquisto', 'Acquisto Wanted List', 'Ricerca offerte', 'Storico Wanted List']),
  _MenuBlock('ACQUISTI', 'ACQUISTI', 'Gestione acquisti e allocazioni', Icons.shopping_cart_outlined, Color(0xFFC74444), ['Nuovo acquisto · PR-04', 'Modifica acquisto · PR-05', 'PR-15 · Preorder', 'Acquisti comparati', 'Report acquisti']),
  _MenuBlock('VENDITE', 'VENDITE E INSERZIONI', 'Vendite e inserzioni', Icons.sell_outlined, Color(0xFF39875B), ['Nuova vendita · PR-06', 'Modifica vendita · PR-07', 'Chiudi vendita · PR-08', 'Annulla vendita · PR-09', 'Report vendite attive', 'Report vendite', 'Bozze inserzioni VALORA']),
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
    'VENDITE E INSERZIONI': {'it':'VENDITE E INSERZIONI','en':'SALES & LISTINGS','fr':'VENTES ET ANNONCES','de':'VERKÄUFE & INSERATE','es':'VENTAS Y ANUNCIOS','pt':'VENDAS E ANÚNCIOS','zh':'销售与刊登','ja':'販売・出品'},
    'VALUTAZIONI': {'it':'VALUTAZIONI','en':'VALUATIONS','fr':'ÉVALUATIONS','de':'BEWERTUNGEN','es':'VALORACIONES','pt':'AVALIAÇÕES','zh':'估值','ja':' मूल्य評価'},
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

  Widget _buildMainMenu(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
    children: [
      Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(_menuText(context, 'chooseBlock'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600))),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _blocks.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.22, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemBuilder: (context, index) {
          final item = _blocks[index];
          return _MainMenuBlockCard(block: item, title: _menuText(context, item.title), onTap: () => setState(() => _selectedBlock = item.key));
        },
      ),
    ],
  );

  Widget _buildSectionMenu(BuildContext context, _MenuBlock block) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
    children: [
      Text(block.description, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500)),
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
                Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
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
