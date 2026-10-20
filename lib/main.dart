import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
const backgroundColor = Color(0xFF101010);
const cardColor = Color(0xFF1C1C1C);
const goldColor = Color(0xFFD6B15E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: publishableKey);
  runApp(const ValoraApp());
}

class ValoraApp extends StatelessWidget {
  const ValoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'COLLECTION by VALORA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(primary: goldColor, secondary: goldColor, surface: cardColor),
      appBarTheme: const AppBarTheme(backgroundColor: backgroundColor, foregroundColor: goldColor, centerTitle: true),
      cardTheme: const CardThemeData(color: cardColor, elevation: 3),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (_, __) => Supabase.instance.client.auth.currentSession == null
      ? const LoginPage() : const Dashboard(),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false, hidePassword = true;
  String message = '';
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => message = 'Inserisci email e password.'); return;
    }
    setState(() { busy = true; message = ''; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(), password: password.text);
    } on AuthException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (e) {
      if (mounted) setState(() => message = 'Errore di accesso: $e');
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(
    child: SingleChildScrollView(padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.inventory_2_outlined, size: 80, color: goldColor),
          const SizedBox(height: 18),
          const Text('COLLECTION by VALORA', style: TextStyle(color: goldColor, fontSize: 23, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('AMBIENTE TEST', style: TextStyle(color: Colors.orangeAccent)),
          const SizedBox(height: 28),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            autocorrect: false, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: hidePassword,
            onSubmitted: (_) => login(),
            decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(
              onPressed: () => setState(() => hidePassword = !hidePassword),
              icon: Icon(hidePassword ? Icons.visibility : Icons.visibility_off)))),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: busy ? null : login,
            child: Text(busy ? 'ACCESSO…' : 'ACCEDI'))),
          if (message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(message, style: const TextStyle(color: Colors.redAccent))),
        ]),
      ),
    ),
  )));
}

class Section {
  const Section(this.name, this.description, this.icon, this.color);
  final String name, description;
  final IconData icon;
  final Color color;
}
const sections = <Section>[
  Section('CATALOGO', 'Consulta e gestisci gli oggetti', Icons.inventory_2_outlined, Color(0xFF3978C5)),
  Section('ACQUISTI', 'Gestione acquisti', Icons.shopping_cart_outlined, Color(0xFF39875B)),
  Section('VENDITE', 'Gestione vendite', Icons.sell_outlined, Color(0xFFC74444)),
  Section('FLUSSI', 'Movimenti e saldi', Icons.account_balance_wallet_outlined, Color(0xFFD6A83F)),
  Section('VALUTAZIONI', 'Valore degli oggetti', Icons.query_stats, Color(0xFF8556C7)),
  Section('REPORT', 'Riepiloghi e risultati', Icons.analytics_outlined, Color(0xFFE17D35)),
  Section('RICERCHE', 'Cerca dati e fonti', Icons.search, Color(0xFF568DAD)),
  Section('CONTROLLO', 'Stato e verifiche', Icons.admin_panel_settings_outlined, Color(0xFF777777)),
];

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  Section? selected;
  Future<void> logout() async => Supabase.instance.client.auth.signOut();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: selected == null ? null : IconButton(
        onPressed: () => setState(() => selected = null), icon: const Icon(Icons.arrow_back)),
      title: const Text('COLLECTION by VALORA'),
      actions: [IconButton(onPressed: logout, tooltip: 'Esci', icon: const Icon(Icons.logout))],
    ),
    body: selected == null ? LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 950 ? 4 : c.maxWidth > 600 ? 3 : 2;
      return Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('CENTRO OPERATIVO',
          style: TextStyle(color: goldColor, fontSize: 20, fontWeight: FontWeight.bold))),
        Expanded(child: GridView.count(
          padding: const EdgeInsets.all(14), crossAxisCount: cols,
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .92,
          children: sections.map((s) => Card(
            child: InkWell(borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => selected = s),
              child: Padding(padding: const EdgeInsets.all(10),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(s.icon, color: s.color, size: 38), const SizedBox(height: 10),
                  Text(s.name, style: TextStyle(color: s.color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6), Text(s.description, textAlign: TextAlign.center),
                ]),
              ),
            ),
          )).toList(),
        )),
        const Padding(padding: EdgeInsets.all(8), child: Text('AMBIENTE TEST', style: TextStyle(color: Colors.orangeAccent))),
      ]);
    }) : _sectionPage(selected!),
  );

  Widget _sectionPage(Section s) {
    final entries = s.name == 'CATALOGO'
      ? ['PR-01 · Nuovo oggetto', 'PR-02 · Modifica oggetto', 'Visualizza scheda', 'Ricerca oggetti']
      : s.name == 'ACQUISTI'
        ? ['PR-04 · Nuovo acquisto', 'PR-05 · Modifica acquisto', 'Elenco acquisti']
        : s.name == 'VENDITE'
          ? ['PR-06 · Nuova vendita', 'PR-07 · Modifica vendita', 'PR-08 · Chiudi vendita', 'PR-09 · Annulla vendita']
          : ['Consultazione', 'Report', 'Funzione in attesa di collaudo'];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Icon(s.icon, size: 48, color: s.color),
      const SizedBox(height: 10),
      Text(s.name, textAlign: TextAlign.center, style: TextStyle(color: s.color, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...entries.map((name) => Card(child: ListTile(
        title: Text(name), trailing: const Icon(Icons.chevron_right),
        onTap: name.startsWith('PR-01')
          ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewObjectPage()))
          : name.startsWith('PR-04')
              ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewPurchasePage()))
              : () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
                  title: Text(name),
                  content: const Text('Procedura non ancora abilitata in questa versione.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CHIUDI'))],
                )),
      ))),
    ]);
  }
}

class DraftObject {
  DraftObject(this.description, this.condition, this.completeness, this.destination, this.quantity);
  final String description, condition, completeness, destination;
  final int quantity;
  Map<String, dynamic> toJson() => {
    'descrizione': description, 'condizione': condition,
    'completezza': completeness, 'destinazione': destination, 'quantita': quantity,
  };
}

class NewObjectPage extends StatefulWidget {
  const NewObjectPage({super.key});
  @override
  State<NewObjectPage> createState() => _NewObjectPageState();
}
class _NewObjectPageState extends State<NewObjectPage> {
  final description = TextEditingController();
  final notes = TextEditingController();
  final List<DraftObject> drafts = [];
  String condition = 'USATO', completeness = 'COMPLETO', destination = 'COLLEZIONE';
  int quantity = 1;
  bool busy = false, dataConfirmed = false, finalConfirmed = false;
  Map<String, dynamic>? preview;
  String message = 'Bozza locale: nessun dato salvato.';
  String? requestId;
  late final String sessionId = _uuidV4();

  @override
  void dispose() { description.dispose(); notes.dispose(); super.dispose(); }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0,8)}-${h.substring(8,12)}-${h.substring(12,16)}-${h.substring(16,20)}-${h.substring(20)}';
  }

  Future<Map<String, dynamic>> callRuntime(
    String action,
    Map<String, dynamic> payload, {
    String? step,
    Map<String, dynamic>? topLevel,
  }) async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) throw Exception('Sessione scaduta: accedi nuovamente.');

    final body = <String, dynamic>{
      'procedure': 'PR-01',
      'action': action,
      'session_id': sessionId,
      'payload': payload,
    };
    if (step != null) body['step'] = step;
    if (requestId != null) body['request_id'] = requestId;
    if (topLevel != null) body.addAll(topLevel);

    final response = await client.functions.invoke(
      'collection-procedure-runtime-test',
      body: body,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) {
      throw Exception('Runtime HTTP ${response.status}: $data');
    }
    if (data is! Map) throw Exception('Risposta runtime non valida: $data');
    final result = Map<String, dynamic>.from(data);
    if (result['error'] != null) throw Exception('${result['error']}');
    return result['result'] is Map
        ? Map<String, dynamic>.from(result['result'] as Map)
        : result;
  }

  Future<void> releaseLockSafely() async {
    try {
      await callRuntime('release_lock', {}, step: null);
    } catch (_) {
      // Il rilascio viene comunque tentato; non nascondiamo l'esito dell'operazione principale.
    }
  }

  Future<bool> acquireLock() async {
    final r = await callRuntime('acquire_lock', {}, step: null);
    if (r['acquisito'] != true) {
      setState(() => message = '${r['messaggio'] ?? 'Blocco esclusivo non acquisito.'}');
      return false;
    }
    return true;
  }

  void notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> prepareSources() async {
    if (description.text.trim().isEmpty) { notice('Inserisci prima la descrizione.'); return; }
    setState(() { busy = true; message = 'Preparazione fonti…'; });
    try {
      if (!await acquireLock()) return;
      final r = await callRuntime('metadata_prepare', {}, step: null, topLevel: {'metadata': {
        'descrizione': description.text.trim(),
        'produttore': '', 'linea': '', 'famiglia': '',
      }});
      if (!mounted) return;
      showDialog<void>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Fonti suggerite'),
        content: SingleChildScrollView(child: SelectableText(const JsonEncoder.withIndent('  ').convert(r))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CHIUDI'))],
      ));
      setState(() => message = 'Fonti preparate. Nessun dato esterno importato e nessun oggetto salvato.');
    } catch (e) { if (mounted) setState(() => message = 'Errore fonti: $e'); }
    finally { await releaseLockSafely(); if (mounted) setState(() => busy = false); }
  }

  void addDraft() {
    if (description.text.trim().isEmpty) { notice('La descrizione è obbligatoria.'); return; }
    setState(() {
      drafts.add(DraftObject(description.text.trim(), condition, completeness, destination, quantity));
      description.clear(); notes.clear(); condition = 'USATO'; completeness = 'COMPLETO';
      destination = 'COLLEZIONE'; quantity = 1; preview = null;
      dataConfirmed = false; finalConfirmed = false; requestId = null;
      message = 'Aggiunto alla bozza. Nessuna scrittura effettuata.';
    });
  }

  Future<void> checkDraft() async {
    if (drafts.isEmpty) { notice('Aggiungi almeno un oggetto.'); return; }
    setState(() { busy = true; message = 'Controllo preliminare…'; });
    try {
      if (!await acquireLock()) return;
      requestId ??= _uuidV4();
      final r = await callRuntime('procedure', {'oggetti': drafts.map((x) => x.toJson()).toList(),
        'dati_confermati': false, 'conferma_finale': false, 'altra_operazione': false}, step: 'preview');
      if (!mounted) return;
      setState(() { preview = r; dataConfirmed = false; finalConfirmed = false;
        message = 'Controlla il riepilogo prima di confermare.'; });
    } catch (e) { if (mounted) setState(() => message = 'Controllo non riuscito: $e'); }
    finally { await releaseLockSafely(); if (mounted) setState(() => busy = false); }
  }

  Future<void> saveFinal() async {
    if (!dataConfirmed || !finalConfirmed || drafts.isEmpty) {
      notice('Conferma i dati e poi autorizza il salvataggio definitivo.'); return;
    }
    setState(() { busy = true; message = 'Richiesta di salvataggio inviata…'; });
    try {
      if (!await acquireLock()) return;
      final r = await callRuntime('procedure', {'oggetti': drafts.map((x) => x.toJson()).toList(),
        'dati_confermati': true, 'conferma_finale': true, 'altra_operazione': false}, step: 'save');
      if (!mounted) return;
      final reread = r['rilettura_database'];
      final saved = r['scrittura_eseguita'] == true &&
          (r['stato'] == 'SALVATO_E_VERIFICATO' ||
           r['rilettura_verificata'] == true ||
           r['verifica_post_scrittura'] == 'OK' ||
           (reread is List && reread.isNotEmpty));
      setState(() {
        preview = r;
        message = saved
            ? 'Il runtime dichiara scrittura e rilettura verificate. Controlla il risultato prima di chiudere.'
            : 'Salvataggio non considerato concluso: la risposta non prova scrittura e rilettura verificate. La bozza è conservata.';
        if (saved) { dataConfirmed = false; finalConfirmed = false; requestId = null; }
      });
    } catch (e) { if (mounted) setState(() => message = 'Salvataggio non confermato: $e'); }
    finally { await releaseLockSafely(); if (mounted) setState(() => busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PR-01 · NUOVO OGGETTO')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Card(child: Padding(padding: EdgeInsets.all(12),
        child: Text('Ambiente TEST. Nessun dato viene salvato senza conferma finale.'))),
      const SizedBox(height: 12),
      TextField(controller: description, maxLines: 2,
        decoration: const InputDecoration(labelText: 'Descrizione *')),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: condition, decoration: const InputDecoration(labelText:'Condizione'),
        items: const ['NUOVO','USATO','DA RIPARARE'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
        onChanged: busy ? null : (v)=>setState(()=>condition=v??condition)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: completeness, decoration: const InputDecoration(labelText:'Completezza'),
        items: const ['COMPLETO','INCOMPLETO','SOLO PARTI'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
        onChanged: busy ? null : (v)=>setState(()=>completeness=v??completeness)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: destination, decoration: const InputDecoration(labelText:'Destinazione'),
        items: const ['COLLEZIONE','RIVENDITA'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),
        onChanged: busy ? null : (v)=>setState(()=>destination=v??destination)),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(value: quantity, decoration: const InputDecoration(labelText:'Quantità'),
        items: List.generate(100,(i)=>i+1).map((x)=>DropdownMenuItem(value:x,child:Text('$x'))).toList(),
        onChanged: busy ? null : (v)=>setState(()=>quantity=v??1)),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: busy?null:prepareSources,
        icon: const Icon(Icons.travel_explore), label: const Text('PREPARA FONTI DI RICERCA')),
      FilledButton.icon(onPressed: busy?null:addDraft,
        icon: const Icon(Icons.add), label: const Text('AGGIUNGI ALLA BOZZA')),
      if (drafts.isNotEmpty) ...[
        const SizedBox(height: 18),
        Text('RIEPILOGO · ${drafts.length} OGGETTO/I',
          style: const TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
        ...List.generate(drafts.length,(i)=>Card(child:ListTile(
          title:Text(drafts[i].description),
          subtitle:Text('${drafts[i].condition} · ${drafts[i].completeness} · ${drafts[i].destination} · Qtà ${drafts[i].quantity}'),
          trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:busy?null:()=>setState((){
            drafts.removeAt(i);preview=null;dataConfirmed=false;finalConfirmed=false;
          })),
        ))),
        FilledButton(onPressed:busy?null:checkDraft,child:const Text('1 · CONTROLLA E RIVEDI')),
      ],
      if (preview != null) ...[
        const SizedBox(height:14),
        Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('RISPOSTA DEL RUNTIME',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
            const SizedBox(height:8),
            SelectableText(const JsonEncoder.withIndent('  ').convert(preview)),
            CheckboxListTile(value:dataConfirmed,contentPadding:EdgeInsets.zero,
              title:const Text('Confermo che i dati sono corretti'),
              onChanged:busy?null:(v)=>setState(() { dataConfirmed=v??false; finalConfirmed=false; })),
            if(dataConfirmed) CheckboxListTile(value:finalConfirmed,contentPadding:EdgeInsets.zero,
              title:const Text('Conferma definitiva: autorizzo il salvataggio in TEST'),
              onChanged:busy?null:(v)=>setState(()=>finalConfirmed=v??false)),
            FilledButton(onPressed:busy||!dataConfirmed||!finalConfirmed?null:saveFinal,
              child:Text(busy?'ATTENDI…':'2 · CONFERMA DEFINITIVA E SALVA')),
          ],
        ))),
      ],
      const SizedBox(height:12),
      Card(child:Padding(padding:const EdgeInsets.all(12),child:Text(message))),
    ]),
  );
}


class PurchaseDraftItem {
  final description = TextEditingController();
  final price = TextEditingController();
  String condition = 'USATO';
  String completeness = 'COMPLETO';
  String destination = 'COLLEZIONE';

  double? get parsedPrice {
    var raw = price.text.trim().replaceAll('€', '').replaceAll(' ', '');
    if (raw.contains(',')) raw = raw.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(raw);
  }

  Map<String, dynamic> toJson() => {
    'descrizione': description.text.trim(),
    'prezzo_acquisto': parsedPrice,
    'condizione': condition,
    'completezza': completeness,
    'destinazione': destination,
    'quantita': 1,
  };

  void dispose() { description.dispose(); price.dispose(); }
}

/// PR-04: una transazione, uno o più record oggetto.
/// Le scritture passano solo dal runtime TEST, con preview, review,
/// conferma esplicita e controllo della rilettura.
class NewPurchasePage extends StatefulWidget {
  const NewPurchasePage({super.key});
  @override
  State<NewPurchasePage> createState() => _NewPurchasePageState();
}

class _NewPurchasePageState extends State<NewPurchasePage> {
  int stage = 0;
  String purchaseType = 'SINGOLO';
  final countController = TextEditingController(text: '2');
  DateTime purchaseDate = DateTime.now();
  final List<PurchaseDraftItem> items = [PurchaseDraftItem()];
  bool busy = false, dataConfirmed = false, finalConfirmed = false;
  Map<String, dynamic>? preview, review;
  String message = 'Bozza locale: nessun acquisto registrato.';
  late final String sessionId = _uuidV4();
  String? requestId;

  @override
  void dispose() {
    countController.dispose();
    for (final item in items) { item.dispose(); }
    super.dispose();
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0,8)}-${h.substring(8,12)}-${h.substring(12,16)}-${h.substring(16,20)}-${h.substring(20)}';
  }

  String _dateText(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  double get total => items.fold<double>(0, (sum, item) => sum + (item.parsedPrice ?? 0));

  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _reset() {
    for (final item in items) { item.dispose(); }
    setState(() {
      stage = 0; purchaseType = 'SINGOLO'; purchaseDate = DateTime.now();
      items..clear()..add(PurchaseDraftItem()); countController.text = '2';
      busy = false; dataConfirmed = false; finalConfirmed = false;
      preview = null; review = null; requestId = null;
      message = 'Nuova bozza pronta. Nessun acquisto registrato.';
    });
  }

  void _setCount(int count) {
    while (items.length < count) { items.add(PurchaseDraftItem()); }
    while (items.length > count) { items.removeLast().dispose(); }
    preview = null; review = null; dataConfirmed = false; finalConfirmed = false;
  }

  bool _validateItems() {
    if (items.isEmpty) { _notice('Inserisci almeno un oggetto.'); return false; }
    for (var i = 0; i < items.length; i++) {
      if (items[i].description.text.trim().isEmpty) {
        _notice('Inserisci la descrizione dell’oggetto ${i + 1}.'); return false;
      }
      final p = items[i].parsedPrice;
      if (p == null || p < 0) {
        _notice('Inserisci un prezzo valido per l’oggetto ${i + 1}.'); return false;
      }
    }
    return true;
  }

  Future<Map<String, dynamic>> _callRuntime(String action, {String? step, Map<String, dynamic>? payload}) async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) throw Exception('Sessione scaduta: accedi nuovamente.');
    final body = <String, dynamic>{
      'procedure': 'PR-04', 'action': action, 'session_id': sessionId,
      'payload': payload ?? <String, dynamic>{},
    };
    if (step != null) body['step'] = step;
    if (requestId != null) body['request_id'] = requestId;
    final response = await client.functions.invoke(
      'collection-procedure-runtime-test',
      body: body,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    final data = response.data;
    if (response.status < 200 || response.status >= 300) throw Exception('Runtime HTTP ${response.status}: ${data}');
    if (data is! Map) throw Exception('Risposta runtime non valida: ${data}');
    final result = Map<String, dynamic>.from(data);
    if (result['error'] != null) throw Exception('${result['error']}');
    return result['result'] is Map ? Map<String, dynamic>.from(result['result'] as Map) : result;
  }

  Future<bool> _lock() async {
    final r = await _callRuntime('acquire_lock');
    if (r['acquisito'] == true) return true;
    if (mounted) setState(() => message = '${r['messaggio'] ?? 'Blocco esclusivo non acquisito.'}');
    return false;
  }

  Future<void> _unlock() async { try { await _callRuntime('release_lock'); } catch (_) {} }

  Map<String, dynamic> _payload({required bool confirmed, required bool finalConfirmation}) => {
    'tipo_acquisto': purchaseType,
    'data_acquisto': purchaseDate.toIso8601String().substring(0,10),
    'numero_oggetti': items.length,
    'importo_totale': double.parse(total.toStringAsFixed(2)),
    'oggetti': items.map((x) => x.toJson()).toList(),
    'dati_confermati': confirmed,
    'conferma_finale': finalConfirmation,
    'altra_operazione': false,
  };

  Future<void> _previewPurchase() async {
    if (!_validateItems()) return;
    setState(() { busy = true; message = 'Controllo preliminare in TEST…'; preview = null; review = null; dataConfirmed = false; finalConfirmed = false; });
    try {
      requestId ??= _uuidV4();
      if (!await _lock()) return;
      final r = await _callRuntime('procedure', step: 'preview', payload: _payload(confirmed: false, finalConfirmation: false));
      if (!mounted) return;
      setState(() { preview = r; stage = 4; message = 'Controllo preliminare ricevuto. Verifica i dati prima di procedere.'; });
    } catch (e) { if (mounted) setState(() => message = 'Controllo non riuscito: ${e}'); }
    finally { await _unlock(); if (mounted) setState(() => busy = false); }
  }

  Future<void> _reviewPurchase() async {
    if (!dataConfirmed) { _notice('Conferma prima la correttezza dei dati.'); return; }
    setState(() { busy = true; message = 'Validazione dati (review)…'; review = null; finalConfirmed = false; });
    try {
      if (!await _lock()) return;
      final r = await _callRuntime('procedure', step: 'review', payload: _payload(confirmed: true, finalConfirmation: false));
      if (!mounted) return;
      setState(() { review = r; message = 'Review ricevuta. Leggi l’esito prima di autorizzare il salvataggio.'; });
    } catch (e) { if (mounted) setState(() => message = 'Validazione non riuscita: ${e}'); }
    finally { await _unlock(); if (mounted) setState(() => busy = false); }
  }

  Future<void> _savePurchase() async {
    if (!dataConfirmed || !finalConfirmed || review == null) { _notice('Completa la review e conferma esplicitamente il salvataggio.'); return; }
    setState(() { busy = true; message = 'Invio del salvataggio al runtime TEST…'; });
    try {
      if (!await _lock()) return;
      final r = await _callRuntime('procedure', step: 'save', payload: _payload(confirmed: true, finalConfirmation: true));
      if (!mounted) return;
      final reread = r['rilettura_database'];
      final rereadCount = reread is List ? reread.length : 0;
      final verified = r['rilettura_verificata'] == true || r['verifica_post_scrittura'] == 'OK' || r['stato'] == 'SALVATO_E_VERIFICATO';
      final saved = r['scrittura_eseguita'] == true && verified && rereadCount == items.length;
      setState(() {
        preview = r;
        message = saved
          ? 'Acquisto salvato e rilettura dichiarata coerente. Controlla il risultato prima di proseguire.'
          : 'Salvataggio NON considerato concluso: il runtime non dimostra scrittura e rilettura coerenti per tutti gli oggetti. La bozza è conservata.';
      });
      if (saved && mounted) {
        final another = await showDialog<bool>(
          context: context, barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Acquisto verificato'),
            content: const Text('Vuoi effettuare un altro acquisto?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('NO, TERMINA')),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('SÌ, ALTRO ACQUISTO')),
            ],
          ),
        );
        if (!mounted) return;
        if (another == true) { _reset(); } else { Navigator.of(context).pop(); }
      }
    } catch (e) { if (mounted) setState(() => message = 'Salvataggio non confermato: ${e}'); }
    finally { await _unlock(); if (mounted) setState(() => busy = false); }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context, initialDate: purchaseDate, firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      helpText: 'DATA DELL’ACQUISTO', cancelText: 'ANNULLA', confirmText: 'CONFERMA DATA',
    );
    if (d != null && mounted) setState(() { purchaseDate = d; preview = null; review = null; });
  }

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5), Text(subtitle, style: const TextStyle(color: Colors.white70)),
    ]),
  );

  Widget _choice(String title, String subtitle, IconData icon, bool selected, VoidCallback onTap) => Card(
    color: selected ? goldColor.withOpacity(.10) : null,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: selected ? goldColor : Colors.white12, width: selected ? 1.5 : 1)),
    child: InkWell(borderRadius: BorderRadius.circular(14), onTap: busy ? null : onTap,
      child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
        Icon(icon, color: selected ? goldColor : Colors.white70, size: 28), const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? goldColor : Colors.white38),
      ])),
    ),
  );

  Widget _itemEditor(int index) {
    final item = items[index];
    return Card(
      key: ValueKey('purchase-item-§index'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OGGETTO ${index + 1}', style: const TextStyle(color: goldColor, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        TextField(controller: item.description, textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Descrizione oggetto *', hintText: 'Es. LEGO 76139 Batmobile'),
          onChanged: (_) => setState(() { preview = null; review = null; })),
        const SizedBox(height: 10),
        TextField(controller: item.price, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Prezzo di acquisto (€) *', hintText: 'Es. 25,00'),
          onChanged: (_) => setState(() { preview = null; review = null; })),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: item.destination, decoration: const InputDecoration(labelText: 'Destinazione'),
          items: const [
            DropdownMenuItem(value: 'COLLEZIONE', child: Text('COLLEZIONE')),
            DropdownMenuItem(value: 'RIVENDITA', child: Text('RIVENDITA')),
          ],
          onChanged: busy ? null : (v) => setState(() { item.destination = v ?? item.destination; preview = null; review = null; })),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            value: item.condition, decoration: const InputDecoration(labelText: 'Condizione'),
            items: const [
              DropdownMenuItem(value: 'NUOVO', child: Text('NUOVO')),
              DropdownMenuItem(value: 'USATO', child: Text('USATO')),
              DropdownMenuItem(value: 'DA RIPARARE', child: Text('DA RIPARARE')),
            ],
            onChanged: busy ? null : (v) => setState(() { item.condition = v ?? item.condition; preview = null; review = null; }))),
          const SizedBox(width: 10),
          Expanded(child: DropdownButtonFormField<String>(
            value: item.completeness, decoration: const InputDecoration(labelText: 'Completezza'),
            items: const [
              DropdownMenuItem(value: 'COMPLETO', child: Text('COMPLETO')),
              DropdownMenuItem(value: 'INCOMPLETO', child: Text('INCOMPLETO')),
              DropdownMenuItem(value: 'SOLO PARTI', child: Text('SOLO PARTI')),
            ],
            onChanged: busy ? null : (v) => setState(() { item.completeness = v ?? item.completeness; preview = null; review = null; }))),
        ]),
      ])),
    );
  }

  Widget _summaryLine(String label, String value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w500, color: strong ? goldColor : null))),
      const SizedBox(width: 10),
      Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: strong ? FontWeight.w900 : FontWeight.w600, color: strong ? goldColor : null))),
    ]),
  );

  Widget _resultCard(String title, Map<String, dynamic> result) => Card(
    child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: goldColor, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), SelectableText(const JsonEncoder.withIndent('  ').convert(result)),
    ])),
  );

  Widget _stageContent() {
    if (stage == 0) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Che tipo di acquisto vuoi registrare?', 'Una sola transazione può contenere uno o più oggetti.'),
      _choice('ACQUISTO SINGOLO', 'Una transazione · un oggetto', Icons.shopping_bag_outlined, purchaseType == 'SINGOLO', () => setState(() { purchaseType = 'SINGOLO'; _setCount(1); countController.text = '1'; })),
      _choice('ACQUISTO MULTIPLO / LOTTO', 'Una transazione · più oggetti distinti', Icons.inventory_2_outlined, purchaseType == 'LOTTO', () => setState(() { purchaseType = 'LOTTO'; if (items.length < 2) _setCount(2); countController.text = items.length.toString(); })),
      const SizedBox(height: 12),
      FilledButton(onPressed: busy ? null : () => setState(() => stage = 1), child: const Text('CONTINUA')),
    ]);

    if (stage == 1) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Dati dell’acquisto', 'La data si riferisce all’intera transazione.'),
      Card(child: ListTile(leading: const Icon(Icons.calendar_month_outlined, color: goldColor), title: const Text('Data acquisto'), subtitle: Text(_dateText(purchaseDate)), trailing: const Icon(Icons.edit_calendar_outlined), onTap: busy ? null : _pickDate)),
      if (purchaseType == 'LOTTO') ...[
        const SizedBox(height: 12),
        TextField(controller: countController, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Numero di oggetti distinti *', helperText: 'Da 2 a 100 oggetti nella stessa transazione.'),
          onChanged: (_) => setState(() {})),
      ],
      const SizedBox(height: 12),
      FilledButton(onPressed: busy ? null : () {
        if (purchaseType == 'LOTTO') {
          final count = int.tryParse(countController.text.trim());
          if (count == null || count < 2 || count > 100) { _notice('Inserisci un numero compreso fra 2 e 100.'); return; }
          _setCount(count);
        } else { _setCount(1); }
        setState(() => stage = 2);
      }, child: const Text('CONTINUA AGLI OGGETTI')),
      OutlinedButton(onPressed: busy ? null : () => setState(() => stage = 0), child: const Text('INDIETRO')),
    ]);

    if (stage == 2) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(purchaseType == 'SINGOLO' ? 'Descrivi l’oggetto acquistato' : 'Inserisci tutti gli oggetti del lotto',
        purchaseType == 'SINGOLO' ? 'Un oggetto, un record, un acquisto.' : 'Ogni oggetto avrà il proprio record e prezzo; l’acquisto resterà unico.'),
      for (var i = 0; i < items.length; i++) _itemEditor(i),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: _summaryLine('TOTALE ACQUISTO', '${total.toStringAsFixed(2).replaceAll('.', ',')} €', strong: true))),
      const SizedBox(height: 12),
      FilledButton(onPressed: busy ? null : () { if (!_validateItems()) return; setState(() { stage = 3; preview = null; review = null; dataConfirmed = false; finalConfirmed = false; }); }, child: const Text('RIEPILOGO ACQUISTO')),
      OutlinedButton(onPressed: busy ? null : () => setState(() => stage = 1), child: const Text('INDIETRO')),
    ]);

    if (stage == 3) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Riepilogo prima del controllo', 'Controlla gli importi. Nessun dato è ancora stato salvato.'),
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _summaryLine('Tipo', purchaseType == 'SINGOLO' ? 'Acquisto singolo' : 'Acquisto multiplo / lotto'),
        _summaryLine('Data acquisto', _dateText(purchaseDate)),
        _summaryLine('Oggetti distinti', '${items.length}'),
        const Divider(height: 24),
        for (var i = 0; i < items.length; i++) Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${i + 1}. ${items[i].description.text.trim()}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${items[i].destination} · ${items[i].condition} · ${items[i].completeness}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Align(alignment: Alignment.centerRight, child: Text('${(items[i].parsedPrice ?? 0).toStringAsFixed(2).replaceAll('.', ',')} €', style: const TextStyle(fontWeight: FontWeight.w700))),
        ])),
        const Divider(height: 24),
        _summaryLine('TOTALE TRANSAZIONE', '${total.toStringAsFixed(2).replaceAll('.', ',')} €', strong: true),
      ]))),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: busy ? null : _previewPurchase, icon: const Icon(Icons.fact_check_outlined), label: const Text('CONTROLLA NEL RUNTIME TEST')),
      OutlinedButton(onPressed: busy ? null : () => setState(() => stage = 2), child: const Text('MODIFICA OGGETTI')),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Verifica e conferma', 'Il runtime deve completare preview e review prima del salvataggio.'),
      if (preview != null) _resultCard('ESITO CONTROLLO PRELIMINARE', preview!),
      CheckboxListTile(value: dataConfirmed, contentPadding: EdgeInsets.zero,
        title: const Text('Confermo che descrizioni, destinazioni e prezzi sono corretti.'),
        onChanged: busy ? null : (v) => setState(() { dataConfirmed = v ?? false; finalConfirmed = false; review = null; })),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: busy || !dataConfirmed ? null : _reviewPurchase, child: Text(busy ? 'ATTENDI…' : 'VALIDA DATI (REVIEW)'))),
      if (review != null) ...[
        const SizedBox(height: 12), _resultCard('ESITO REVIEW', review!),
        CheckboxListTile(value: finalConfirmed, contentPadding: EdgeInsets.zero,
          title: const Text('Conferma definitiva: autorizzo una sola transazione e tutti i record oggetto in TEST.'),
          onChanged: busy ? null : (v) => setState(() => finalConfirmed = v ?? false)),
        SizedBox(width: double.infinity, child: FilledButton(onPressed: busy || !finalConfirmed ? null : _savePurchase, child: Text(busy ? 'ATTENDI…' : 'CONFERMA E REGISTRA ACQUISTO'))),
      ],
      OutlinedButton(onPressed: busy ? null : () => setState(() { stage = 3; preview = null; review = null; dataConfirmed = false; finalConfirmed = false; }), child: const Text('INDIETRO AL RIEPILOGO')),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PR-04 · NUOVO ACQUISTO'), actions: [
      Padding(padding: const EdgeInsets.only(right: 12), child: Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFF3A321E), borderRadius: BorderRadius.circular(99), border: Border.all(color: goldColor)),
        child: const Text('TEST', style: TextStyle(color: Color(0xFFFFE2A0), fontSize: 11, fontWeight: FontWeight.w800)),
      ))),
    ]),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Ambiente TEST. Nessuna scrittura senza conferma esplicita; dopo il salvataggio è obbligatoria la rilettura di verifica.'))),
        const SizedBox(height: 12),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (stage + 1) / 5, minHeight: 5)),
        const SizedBox(height: 8),
        Text('PASSAGGIO ${stage + 1} DI 5', style: const TextStyle(color: goldColor, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 14),
        if (busy) const LinearProgressIndicator(),
        _stageContent(),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(message))),
      ]),
    ))),
  );
}
