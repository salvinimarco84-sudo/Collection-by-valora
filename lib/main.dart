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
        onTap: name.startsWith('PR-01') ? () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const NewObjectPage()))
          : name.startsWith('PR-05') ? () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const EditPurchasePage()))
          : () => showDialog<void>(context: context, builder: (ctx) => AlertDialog(
            title: Text(name), content: const Text('Procedura non ancora abilitata in questa versione.'),
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

 
class EditPurchasePage extends StatefulWidget {
  const EditPurchasePage({super.key});
  @override
  State<EditPurchasePage> createState() => _EditPurchasePageState();
}

class _EditPurchasePageState extends State<EditPurchasePage> {
  final search = TextEditingController();
  final purchaseDate = TextEditingController();
  final total = TextEditingController();
  final List<Map<String, dynamic>> purchases = [];
  Map<String, dynamic>? selected;
  Map<String, dynamic>? preview;
  bool busy = false, dataConfirmed = false, finalConfirmed = false, lockHeld = false;
  String message = 'Cerca un acquisto per codice o descrizione.';
  String? requestId;
  late final String sessionId = _uuidV4();

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0,8)}-${h.substring(8,12)}-${h.substring(12,16)}-${h.substring(16,20)}-${h.substring(20)}';
  }

  @override
  void dispose() {
    search.dispose();
    purchaseDate.dispose();
    total.dispose();
    if (lockHeld) { _releaseLock(); }
    super.dispose();
  }

  Future<Map<String, dynamic>> _call({
    required String step,
    Map<String, dynamic> payload = const {},
    String? action,
  }) async {
    final client = Supabase.instance.client;
    final session = client.auth.currentSession;
    if (session == null) throw Exception('Sessione scaduta. Accedi nuovamente.');
    final body = <String, dynamic>{
      'procedure': 'PR-05',
      'step': step,
      'session_id': sessionId,
      'payload': payload,
    };
    if (action != null) body['action'] = action;
    if (requestId != null) body['request_id'] = requestId;
    final response = await client.functions.invoke(
      'collection-procedure-runtime-test',
      body: body,
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );
    final raw = response.data;
    if (response.status < 200 || response.status >= 300) {
      final errorText = raw is Map ? raw['error']?.toString() : null;
      throw Exception(errorText ?? 'Runtime HTTP ${response.status}: $raw');
    }
    if (raw is! Map) throw Exception('Risposta runtime non valida: $raw');
    if (raw['error'] != null) throw Exception('${raw['error']}');
    final map = Map<String, dynamic>.from(raw);
    final result = map['result'];
    return result is Map ? Map<String, dynamic>.from(result) : map;
  }

  Future<void> _searchPurchases() async {
    setState(() { busy = true; message = 'Ricerca acquisti in corso…'; });
    try {
      final result = await _call(
        step: search.text.trim().isEmpty ? 'list' : 'search',
        payload: {'query': search.text.trim()},
      );
      final rows = result['acquisti'];
      if (rows is! List) throw Exception('Il runtime non ha restituito l’elenco acquisti.');
      setState(() {
        purchases
          ..clear()
          ..addAll(rows.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
        selected = null;
        preview = null;
        dataConfirmed = false;
        finalConfirmed = false;
        message = 'Trovati ${purchases.length} acquisti. Seleziona una riga per modificarla.';
      });
    } catch (e) {
      if (mounted) setState(() => message = 'Ricerca non riuscita: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _loadPurchase(Map<String, dynamic> row) async {
    setState(() { busy = true; message = 'Caricamento acquisto…'; });
    try {
      final result = await _call(
        step: 'load',
        payload: {'query': '${row['codice_acquisto']}'},
      );
      final rows = result['acquisti'];
      if (rows is! List || rows.isEmpty || rows.first is! Map) {
        throw Exception('Il runtime non ha restituito la scheda dell’acquisto.');
      }
      final loaded = Map<String, dynamic>.from(rows.first as Map);
      setState(() {
        selected = loaded;
        purchaseDate.text = (loaded['data_acquisto'] ?? '').toString();
        total.text = (loaded['importo_totale'] ?? '').toString();
        preview = null;
        dataConfirmed = false;
        finalConfirmed = false;
        requestId = null;
        message = 'Acquisto caricato. Puoi modificare data e importo totale.';
      });
    } catch (e) {
      if (mounted) setState(() => message = 'Caricamento non riuscito: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> _acquireLock() async {
    final result = await _call(step: 'acquire_lock', action: 'acquire_lock');
    if (result['acquisito'] != true) {
      throw Exception(result['messaggio'] ?? 'Blocco esclusivo non acquisito.');
    }
    lockHeld = true;
    return true;
  }

  Future<void> _releaseLock() async {
    try {
      await _call(step: 'release_lock', action: 'release_lock');
    } catch (_) {
      // Il messaggio principale resta visibile; il runtime impedisce comunque scritture senza blocco valido.
    } finally {
      lockHeld = false;
    }
  }

  Map<String, dynamic> _buildPayload({required bool confirmed, required bool finalSave}) {
    final row = selected;
    if (row == null) throw Exception('Seleziona prima un acquisto.');
    final code = int.tryParse('${row['codice_acquisto']}');
    if (code == null || code < 1) throw Exception('Codice acquisto non valido.');
    final date = purchaseDate.text.trim();
    final parsedDate = DateTime.tryParse(date);
    if (parsedDate == null || date.length != 10) {
      throw Exception('Inserisci la data nel formato AAAA-MM-GG.');
    }
    final amountText = total.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || !amount.isFinite || amount <= 0) {
      throw Exception('L’importo totale deve essere maggiore di zero.');
    }
    return {
      'operazioni': [{
        'codice_acquisto': code,
        'data_acquisto': date,
        'importo_totale': amount,
      }],
      'dati_confermati': confirmed,
      'conferma_finale': finalSave,
      'altra_operazione': false,
    };
  }

  Future<void> _preparePreview() async {
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleziona prima un acquisto.')));
      return;
    }
    setState(() { busy = true; message = 'Controllo preliminare in corso. Nessuna scrittura…'; });
    try {
      final payload = _buildPayload(confirmed: false, finalSave: false);
      await _acquireLock();
      requestId = _uuidV4();
      final result = await _call(step: 'preview', payload: payload);
      setState(() {
        preview = result;
        dataConfirmed = false;
        finalConfirmed = false;
        message = 'Anteprima pronta. Controlla i valori prima di confermare.';
      });
    } catch (e) {
      if (mounted) setState(() => message = 'Controllo non riuscito: $e');
      if (lockHeld) await _releaseLock();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _reviewFinal() async {
    if (!dataConfirmed) return;
    setState(() { busy = true; message = 'Preparazione della conferma finale…'; });
    try {
      final result = await _call(
        step: 'review',
        payload: _buildPayload(confirmed: true, finalSave: false),
      );
      setState(() {
        preview = result;
        finalConfirmed = false;
        message = 'Riepilogo verificato. Il database non è ancora stato modificato.';
      });
    } catch (e) {
      if (mounted) setState(() => message = 'Revisione non riuscita: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _saveFinal() async {
    if (!dataConfirmed || !finalConfirmed) return;
    setState(() { busy = true; message = 'Salvataggio e verifica nel database TEST…'; });
    try {
      requestId ??= _uuidV4();
      final result = await _call(
        step: 'save',
        payload: _buildPayload(confirmed: true, finalSave: true),
      );
      final saved = result['scrittura_eseguita'] == true &&
          (result['stato'] == 'SALVATO_E_VERIFICATO' || result['verifica_database'] == true);
      setState(() {
        preview = result;
        message = saved
          ? 'Modifica salvata e verificata dal runtime. Controlla il risultato qui sotto.'
          : 'Salvataggio non considerato completato: il runtime non ha confermato la verifica.';
        if (saved) {
          dataConfirmed = false;
          finalConfirmed = false;
          lockHeld = result['blocco_rilasciato_automaticamente'] != true ? lockHeld : false;
          requestId = null;
        }
      });
      if (saved) await _searchPurchases();
    } catch (e) {
      if (mounted) setState(() => message = 'Salvataggio non riuscito: $e. Nessun esito positivo viene dichiarato.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PR-05 · MODIFICA ACQUISTO')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('AMBIENTE TEST · La ricerca e l’anteprima non scrivono dati. La scrittura richiede conferma finale. Gli oggetti collegati non vengono modificati.'),
        )),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          decoration: InputDecoration(
            labelText: 'Cerca per codice o descrizione',
            hintText: 'Es. 46 oppure lotto LEGO',
            suffixIcon: IconButton(
              tooltip: 'Cerca',
              onPressed: busy ? null : _searchPurchases,
              icon: const Icon(Icons.search),
            ),
          ),
          onSubmitted: (_) => busy ? null : _searchPurchases(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : _searchPurchases,
          icon: const Icon(Icons.list_alt),
          label: const Text('MOSTRA ELENCO ACQUISTI'),
        ),
        if (purchases.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('RISULTATI: ${purchases.length}', style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          ...purchases.map((row) => Card(
            child: ListTile(
              title: Text('#${row['codice_acquisto']} · ${row['descrizione']?.toString().trim().isNotEmpty == true ? row['descrizione'] : 'Acquisto senza descrizione'}'),
              subtitle: Text('${row['data_acquisto'] ?? 'Data non disponibile'} · ${row['importo_totale'] ?? '?'} ${row['valuta'] ?? 'EUR'}'),
              trailing: const Icon(Icons.edit_outlined),
              selected: selected?['codice_acquisto'] == row['codice_acquisto'],
              onTap: busy ? null : () => _loadPurchase(row),
            ),
          )),
        ],
        if (selected != null) ...[
          const Divider(height: 28),
          Text('ACQUISTO SELEZIONATO #${selected!['codice_acquisto']}', style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Descrizione: ${selected!['descrizione'] ?? 'Non specificata'}'),
          Text('Valuta: ${selected!['valuta'] ?? 'EUR'}'),
          const SizedBox(height: 12),
          TextField(
            controller: purchaseDate,
            enabled: !busy,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(labelText: 'Data acquisto', hintText: 'AAAA-MM-GG'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: total,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Importo totale', helperText: 'Deve coincidere con la somma degli oggetti inclusi nella quadratura. Se cambi solo la data, lascia invariato l’importo.'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: busy ? null : _preparePreview,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('1 · CONTROLLA E MOSTRA ANTEPRIMA'),
          ),
        ],
        if (preview != null) ...[
          const SizedBox(height: 12),
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RIEPILOGO RUNTIME', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(const JsonEncoder.withIndent('  ').convert(preview)),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: dataConfirmed,
                title: const Text('Confermo che codice, data e importo sono corretti'),
                onChanged: busy ? null : (v) => setState(() { dataConfirmed = v ?? false; finalConfirmed = false; }),
              ),
              OutlinedButton(
                onPressed: busy || !dataConfirmed ? null : _reviewFinal,
                child: const Text('2 · RICONTROLLA PRIMA DEL SALVATAGGIO'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: finalConfirmed,
                title: const Text('Conferma definitiva: autorizzo la modifica nel database TEST'),
                onChanged: busy || !dataConfirmed ? null : (v) => setState(() => finalConfirmed = v ?? false),
              ),
              FilledButton(
                onPressed: busy || !dataConfirmed || !finalConfirmed ? null : _saveFinal,
                child: Text(busy ? 'ATTENDI…' : '3 · CONFERMA DEFINITIVA E SALVA'),
              ),
              OutlinedButton(
                onPressed: busy ? null : () async {
                  if (lockHeld) await _releaseLock();
                  setState(() { preview = null; dataConfirmed = false; finalConfirmed = false; requestId = null; message = 'Bozza annullata. Nessuna scrittura richiesta.'; });
                },
                child: const Text('ANNULLA BOZZA'),
              ),
            ]),
          )),
        ],
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(message))),
      ],
    ),
  );
}
