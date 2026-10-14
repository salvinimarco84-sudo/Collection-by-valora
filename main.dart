import 'package:flutter/material.dart';

void main() => runApp(const CollectionByValoraApp());

const ink = Color(0xFFF4F5F7);
const inkSoft = Color(0xFFD2D5DB);
const paper = Color(0xFF101116);
const blue = Color(0xFF4D8DFF);
const red = Color(0xFFFF4655);
const gold = Color(0xFFE7B64B);
const muted = Color(0xFF9AA0AD);
const border = Color(0xFF30333D);

class CollectionByValoraApp extends StatelessWidget {
  const CollectionByValoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'COLLECTION by VALORA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
    dividerColor: border,
      colorScheme: ColorScheme.fromSeed(seedColor: red, brightness: Brightness.dark).copyWith(secondary: gold, surface: const Color(0xFF191B22)),
      appBarTheme: const AppBarTheme(backgroundColor: const Color(0xFF191B22), foregroundColor: Colors.white, elevation: 0),
      cardTheme: CardThemeData(
        color: const Color(0xFF191B22), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: border)),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: ink, letterSpacing: -0.6),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w750, color: ink),
        bodyMedium: TextStyle(fontSize: 14, color: ink),
      ),
    ),
    home: const HomeScreen(),
  );
}

class SectionInfo {
  const SectionInfo(this.name, this.subtitle, this.icon, this.color, this.groups);
  final String name, subtitle;
  final IconData icon;
  final Color color;
  final List<OperationGroup> groups;
}
class Operation {
  const Operation(this.title, this.description, this.icon, {this.apiCode, this.readOnly = false});
  final String title, description;
  final IconData icon;
  final String? apiCode;
  final bool readOnly;
  bool get mapped => apiCode != null;
}
class OperationGroup {
  const OperationGroup(this.title, this.operations);
  final String title;
  final List<Operation> operations;
}

const sections = <SectionInfo>[
  SectionInfo('Catalogo oggetti', 'Schede, inventario e destinazioni', Icons.inventory_2_outlined, blue, [
    OperationGroup('GESTIONE OGGETTI', [
      Operation('Nuovo oggetto', 'Inserimento singolo o multiplo nel catalogo', Icons.add_box_outlined, apiCode: 'WRITE-PR-01'),
      Operation('Modifica oggetto', 'Selezione esplicita e modifica dei campi consentiti', Icons.edit_note_outlined, apiCode: 'WRITE-PR-02'),
      Operation('Visualizza scheda', 'Scheda completa, inclusi i campi vuoti', Icons.article_outlined, apiCode: 'READ-OBJECT-MASTER', readOnly: true),
      Operation('Ricerca oggetti', 'Ricerca per codice, descrizione e attributi', Icons.search, apiCode: 'READ-EXPLORE-RECORDS', readOnly: true),
    ]),
    OperationGroup('CONSULTAZIONI', [
      Operation('Elenco catalogo', 'Filtri per posseduti, desiderati, collezione e rivendita', Icons.view_list_outlined, apiCode: 'READ-OBJECTS-AVAILABLE', readOnly: true),
      Operation('Valore di mercato', 'Consulta valori e data dell’ultimo aggiornamento', Icons.price_change_outlined, apiCode: 'READ-VALUATION-PREPARE', readOnly: true),
    ]),
  ]),
  SectionInfo('Acquisti', 'Registrazioni, storico e analisi', Icons.shopping_bag_outlined, blue, [
    OperationGroup('PROCEDURE OPERATIVE', [
      Operation('Nuovo acquisto', 'Registra uno o più oggetti con riepilogo prima della conferma', Icons.add_shopping_cart_outlined, apiCode: 'WRITE-PR-04'),
      Operation('Modifica acquisto', 'Seleziona un acquisto e modifica i campi modificabili', Icons.edit_outlined, apiCode: 'WRITE-PR-05'),
    ]),
    OperationGroup('CONSULTAZIONI E REPORT', [
      Operation('Elenco acquisti', 'Consulta gli acquisti registrati e filtra i risultati', Icons.receipt_long_outlined, apiCode: 'REPORT-PURCHASES', readOnly: true),
      Operation('Report acquisti', 'Analisi per periodo, importi e destinazione', Icons.bar_chart_outlined, apiCode: 'REPORT-PURCHASES', readOnly: true),
      Operation('Acquisti comparati', 'Confronto tra periodi e risultati', Icons.compare_arrows_outlined),
    ]),
  ]),
  SectionInfo('Vendite e inserzioni', 'Piattaforme, vendite e stato delle inserzioni', Icons.sell_outlined, red, [
    OperationGroup('PROCEDURE OPERATIVE', [
      Operation('Nuova inserzione', 'Crea una o più inserzioni secondo le piattaforme scelte', Icons.add_link_outlined),
      Operation('Modifica inserzione', 'Aggiorna i campi consentiti di un’inserzione', Icons.edit_note_outlined),
      Operation('Chiudi inserzione', 'Chiude un’inserzione dopo selezione e riepilogo', Icons.link_off_outlined),
      Operation('Nuova vendita', 'Registra una vendita e la relativa piattaforma', Icons.point_of_sale_outlined, apiCode: 'WRITE-PR-06'),
      Operation('Vendita multipla Vinted', 'Registra più vendite nella stessa sessione operativa', Icons.playlist_add_check_outlined),
    ]),
    OperationGroup('CONSULTAZIONI E REPORT', [
      Operation('Inserzioni attive', 'Visualizza tutte le inserzioni attive, senza limiti arbitrari', Icons.list_alt_outlined, apiCode: 'REPORT-ACTIVE-LISTINGS', readOnly: true),
      Operation('Report vendite', 'Totali e numero vendite per periodo', Icons.query_stats_outlined, apiCode: 'REPORT-SALES', readOnly: true),
      Operation('Vendite comparate', 'Confronto dei risultati tra periodi', Icons.compare_outlined),
    ]),
  ]),
  SectionInfo('Flussi di cassa e saldi', 'Movimenti, giroconti e riconciliazione', Icons.account_balance_wallet_outlined, gold, [
    OperationGroup('PROCEDURE OPERATIVE', [
      Operation('Nuovo movimento extra', 'Registra un movimento extra dopo riepilogo', Icons.post_add_outlined),
      Operation('Giroconto', 'Registra uno spostamento tra fondi o destinazioni', Icons.swap_horiz_outlined),
      Operation('Mostra saldi', 'Consulta i saldi disponibili per piattaforma', Icons.account_balance_outlined),
    ]),
    OperationGroup('CONSULTAZIONI E REPORT', [
      Operation('Flussi di cassa', 'Elenco cronologico di entrate e uscite', Icons.waterfall_chart_outlined, apiCode: 'REPORT-CASH', readOnly: true),
      Operation('Report spese', 'Analisi per categoria e periodo', Icons.pie_chart_outline),
    ]),
  ]),
  SectionInfo('Valutazioni e opportunità', 'Valori di mercato e decisioni d’acquisto', Icons.price_check_outlined, blue, [
    OperationGroup('VALUTAZIONE', [
      Operation('Valuta oggetto', 'Stima basata su comparabili e mercato selezionato', Icons.calculate_outlined, apiCode: 'READ-VALUATION-PREPARE', readOnly: true),
      Operation('Valuta più oggetti', 'Valutazione multipla in un’unica procedura', Icons.playlist_add_outlined, apiCode: 'READ-VALUATION-PREPARE', readOnly: true),
      Operation('Opportunità di acquisto', 'Confronta costo richiesto e valore stimato', Icons.lightbulb_outline),
    ]),
    OperationGroup('REPORT', [
      Operation('Report opportunità', 'Riepilogo delle opportunità di acquisto', Icons.insights_outlined),
    ]),
  ]),
  SectionInfo('Report e consultazioni', 'Quadro d’insieme delle attività', Icons.analytics_outlined, blue, [
    OperationGroup('REPORT', [
      Operation('Report mattutino', 'Riepilogo operativo del periodo', Icons.wb_sunny_outlined),
      Operation('Report vendite', 'Vendite per anno, mese o intervallo date', Icons.trending_up_outlined),
      Operation('Report acquisti', 'Acquisti per anno, mese o intervallo date', Icons.shopping_cart_outlined),
      Operation('Report spese', 'Spese per categoria e periodo', Icons.receipt_outlined),
    ]),
    OperationGroup('CONSULTAZIONI RAPIDE', [
      Operation('Vendite', 'Elenco vendite e totali per periodo', Icons.sell_outlined),
      Operation('Vendite comparate', 'Confronta periodi selezionati', Icons.compare_arrows),
      Operation('Acquisti', 'Elenco acquisti e totali per periodo', Icons.shopping_bag_outlined),
      Operation('Acquisti comparati', 'Confronta periodi selezionati', Icons.compare_outlined),
    ]),
  ]),
  SectionInfo('Ricerche', 'Ricerca mirata nel catalogo e negli archivi', Icons.manage_search_outlined, blue, [
    OperationGroup('RICERCHE', [
      Operation('Ricerca oggetti', 'Cerca nel catalogo per codice e descrizione', Icons.search),
      Operation('Ricerca #DEMONOFLU', 'Ricerca riferimenti e inserzioni del profilo', Icons.tag_outlined),
    ]),
  ]),
  SectionInfo('Controllo sistema', 'Procedure, integrità e collaudo', Icons.settings_suggest_outlined, inkSoft, [
    OperationGroup('CONTROLLO', [
      Operation('Gestione procedure', 'Consulta il catalogo ufficiale delle procedure', Icons.rule_folder_outlined, apiCode: 'RUNTIME-CATALOG', readOnly: true),
      Operation('Stato database', 'Verifica ambiente e stato della connessione', Icons.storage_outlined, apiCode: 'RUNTIME-HEALTH', readOnly: true),
      Operation('Collaudo runtime', 'Stato dei test e verifiche end-to-end', Icons.fact_check_outlined),
      Operation('Pulizia file', 'Operazione disponibile solo dopo verifica delle regole', Icons.cleaning_services_outlined),
    ]),
  ]),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('COLLECTION by VALORA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text('DEMON SOFTWARE HOUSE', style: TextStyle(fontSize: 10, color: Colors.white70, letterSpacing: 1.2)),
        ]),
        actions: const [Padding(padding: EdgeInsets.only(right: 14), child: Center(child: _TestBadge()))],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 850;
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: wide ? 30 : 16, vertical: 20),
          children: [
            const Text('CENTRO DI CONTROLLO', style: TextStyle(color: muted, letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            const Text('La tua collezione, sotto controllo.', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 6),
            const Text('Scegli una sezione per accedere a tutte le operazioni disponibili.', style: TextStyle(color: muted, fontSize: 13)),
            const SizedBox(height: 18),
            _SearchTile(onTap: () => _showSearch(context)),
            const SizedBox(height: 18),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: wide ? 170 : 158,
              ),
              itemBuilder: (context, index) => _SectionCard(
                section: sections[index],
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SectionScreen(section: sections[index]),
                )),
              ),
            ),
            const SizedBox(height: 18),
            const _EnvironmentPanel(),
            const SizedBox(height: 14),
            const Center(child: Text('Anteprima Flutter · nessuna scrittura sul database', style: TextStyle(color: muted, fontSize: 11))),
          ],
        );
      }),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _GlobalSearchDelegate());
  }
}

class _TestBadge extends StatelessWidget {
  const _TestBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: const Color(0xFF3A321E), borderRadius: BorderRadius.circular(99), border: Border.all(color: gold)),
    child: const Text('TEST', style: TextStyle(color: Color(0xFFFFE2A0), fontWeight: FontWeight.w800, fontSize: 11)),
  );
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        child: Row(children: [
          Icon(Icons.search, color: blue, size: 27),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cerca in COLLECTION', style: TextStyle(fontWeight: FontWeight.w750, color: ink)),
            Text('Oggetti, operazioni e procedure', style: TextStyle(color: muted, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, size: 15, color: muted),
        ]),
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onTap});
  final SectionInfo section;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final count = section.groups.fold<int>(0, (n, g) => n + g.operations.length);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: section.color.withOpacity(.10), borderRadius: BorderRadius.circular(13)),
              child: Icon(section.icon, color: section.color, size: 23),
            ),
            const Spacer(),
            Text(section.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ink), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(child: Text('$count operazioni disponibili', style: const TextStyle(color: muted, fontSize: 11))),
              const Icon(Icons.arrow_forward_rounded, color: blue, size: 18),
            ]),
          ]),
        ),
      ),
    );
  }
}

class SectionScreen extends StatelessWidget {
  const SectionScreen({super.key, required this.section});
  final SectionInfo section;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: section.color.withOpacity(.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: section.color.withOpacity(.2))),
          child: Row(children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: section.color.withOpacity(.13), borderRadius: BorderRadius.circular(15)), child: Icon(section.icon, color: section.color, size: 27)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(section.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 3),
              Text(section.subtitle, style: const TextStyle(color: muted, fontSize: 12)),
            ])),
          ]),
        ),
        const SizedBox(height: 20),
        for (final group in section.groups) ...[
          Padding(
            padding: const EdgeInsets.only(left: 3, bottom: 9, top: 4),
            child: Text(group.title, style: const TextStyle(color: muted, letterSpacing: 1.5, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          Card(
            child: Column(children: [
              for (var i = 0; i < group.operations.length; i++) ...[
                _OperationTile(operation: group.operations[i], color: section.color),
                if (i != group.operations.length - 1) const Divider(height: 1, indent: 58, color: border),
              ],
            ]),
          ),
          const SizedBox(height: 17),
        ],
        const _EnvironmentPanel(),
      ],
    ),
  );
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({required this.operation, required this.color});
  final Operation operation;
  final Color color;
  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 12,
    leading: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: color.withOpacity(.09), borderRadius: BorderRadius.circular(12)),
      child: Icon(operation.icon, color: color, size: 21),
    ),
    title: Text(operation.title, style: const TextStyle(fontWeight: FontWeight.w750, color: ink, fontSize: 14)),
    subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(operation.description, style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 6), Wrap(spacing: 6, runSpacing: 4, children: [if (operation.apiCode != null) _StatusChip(label: operation.apiCode!, color: blue), _StatusChip(label: operation.mapped ? 'MAPPING CANDIDATO' : 'DA ALLINEARE', color: operation.mapped ? gold : muted), if (operation.readOnly) const _StatusChip(label: 'SOLA LETTURA', color: blue)])])),
    trailing: const Icon(Icons.chevron_right, color: muted),
    onTap: () => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(operation.icon, color: color, size: 30),
        title: Text(operation.title),
        content: Text('${operation.description}\n\n${operation.apiCode == null ? 'Nessuna API certa è stata associata: la voce resta da allineare e non deve essere usata come procedura operativa.' : 'API candidata: ${operation.apiCode}. Il contratto di input e il runtime devono ancora essere collaudati prima di attivare l’operazione.'}\n\nNessuna chiamata al runtime e nessuna modifica al database viene eseguita da questa schermata.'),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Chiudi'))],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(.10), borderRadius: BorderRadius.circular(7), border: Border.all(color: color.withOpacity(.35))),
    child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: .3)),
  );
}

class _EnvironmentPanel extends StatelessWidget {
  const _EnvironmentPanel();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.shield_outlined, color: gold),
          SizedBox(width: 8),
          Text('STATO AMBIENTE', style: TextStyle(fontWeight: FontWeight.w800, color: ink, letterSpacing: 1)),
        ]),
        const SizedBox(height: 10),
        const _StatusLine('Modalità', 'DEMO / TEST'),
        const _StatusLine('Supabase TEST', 'Non collegato'),
        const _StatusLine('Procedure runtime', 'Da collaudare'),
        const _StatusLine('Produzione', 'Non modificata'),
      ]),
    ),
  );
}

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 12))),
      Text(value, style: const TextStyle(color: inkSoft, fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );
}

class _GlobalSearchDelegate extends SearchDelegate<String> {
  @override
  String get searchFieldLabel => 'Cerca sezioni e operazioni';
  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, ''), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext context) => _results(context);
  @override
  Widget buildSuggestions(BuildContext context) => _results(context);
  Widget _results(BuildContext context) {
    final all = <({SectionInfo section, Operation op})>[
      for (final s in sections)
        for (final g in s.groups)
          for (final op in g.operations)
            (section: s, op: op),
    ];
    final q = query.toLowerCase().trim();
    final results = all.where((x) => '${x.section.name} ${x.op.title} ${x.op.description}'.toLowerCase().contains(q)).toList();
    if (q.isEmpty) {
      return const Center(child: Text('Cerca una sezione o un’operazione'));
    }
    if (results.isEmpty) return const Center(child: Text('Nessun risultato'));
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => ListTile(
        leading: Icon(results[i].op.icon, color: results[i].section.color),
        title: Text(results[i].op.title),
        subtitle: Text(results[i].section.name),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          close(context, results[i].op.title);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => SectionScreen(section: results[i].section)));
        },
      ),
    );
  }
}
