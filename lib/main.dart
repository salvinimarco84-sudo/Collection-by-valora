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
