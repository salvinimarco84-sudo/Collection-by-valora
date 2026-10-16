import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const String supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const String publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
const Color backgroundColor = Color(0xFF101010);
const Color cardColor = Color(0xFF1C1C1C);
const Color goldColor = Color(0xFFD6B15E);
const uuid = Uuid();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, publishableKey: publishableKey);
  runApp(const CollectionValoraApp());
}

class CollectionValoraApp extends StatelessWidget {
  const CollectionValoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'COLLECTION by VALORA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.dark(primary: goldColor, secondary: goldColor, surface: cardColor),
      appBarTheme: const AppBarTheme(backgroundColor: backgroundColor, foregroundColor: goldColor, centerTitle: true),
      cardTheme: const CardThemeData(color: cardColor, elevation: 3),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: goldColor, width: 1.5)),
      ),
    ),
    home: const AuthenticationGate(),
  );
}

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) => Supabase.instance.client.auth.currentSession != null
      ? const HomeDashboard() : const LoginPage(),
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
  bool loading = false, obscure = true;
  String message = '';
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => message = 'Inserisci email e password.'); return;
    }
    setState(() { loading = true; message = ''; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
    } on AuthException catch (e) { if (mounted) setState(() => message = e.message); }
      catch (e) { if (mounted) setState(() => message = 'Errore di accesso: $e'); }
      finally { if (mounted) setState(() => loading = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 112, height: 112, decoration: BoxDecoration(
            shape: BoxShape.circle, color: cardColor, border: Border.all(color: goldColor, width: 2)),
            child: const Icon(Icons.inventory_2_outlined, color: goldColor, size: 56)),
          const SizedBox(height: 24),
          const Text('COLLECTION', style: TextStyle(color: goldColor, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 3)),
          const SizedBox(height: 4),
          const Text('by VALORA', style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 2)),
          const SizedBox(height: 36),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined))),
          const SizedBox(height: 16),
          TextField(controller: password, obscureText: obscure, onSubmitted: (_) => signIn(),
            decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure),
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 52, child: FilledButton(
            onPressed: loading ? null : signIn,
            child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('ACCEDI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)))),
          if (message.isNotEmpty) ...[const SizedBox(height: 16), Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent))],
          const SizedBox(height: 24),
          const Text('AMBIENTE TEST', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      )),
    ))),
  );
}

class DashboardSection {
  const DashboardSection(this.title, this.description, this.icon, this.color);
  final String title, description;
  final IconData icon;
  final Color color;
}
const sections = <DashboardSection>[
  DashboardSection('CATALOGO','Consulta e gestisci gli oggetti',Icons.inventory_2_outlined,Color(0xFF3978C5)),
  DashboardSection('ACQUISTI','Gestione acquisti',Icons.shopping_cart_outlined,Color(0xFF39875B)),
  DashboardSection('VENDITE','Gestione vendite',Icons.sell_outlined,Color(0xFFC74444)),
  DashboardSection('FLUSSI','Movimenti e saldi',Icons.account_balance_wallet_outlined,Color(0xFFD6A83F)),
  DashboardSection('VALUTAZIONI','Valore degli oggetti',Icons.query_stats,Color(0xFF8556C7)),
  DashboardSection('REPORT','Riepiloghi e risultati',Icons.analytics_outlined,Color(0xFFE17D35)),
  DashboardSection('RICERCHE','Cerca dati e fonti',Icons.search,Color(0xFF568DAD)),
  DashboardSection('CONTROLLO','Stato e verifiche',Icons.admin_panel_settings_outlined,Color(0xFF777777)),
];

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}
class _HomeDashboardState extends State<HomeDashboard> {
  DashboardSection? selected;
  Future<void> logout() async { await Supabase.instance.client.auth.signOut(); if (mounted) setState(() => selected = null); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: selected == null ? null : IconButton(onPressed: () => setState(() => selected = null), icon: const Icon(Icons.arrow_back)),
      title: const Text('COLLECTION by VALORA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      actions: [IconButton(tooltip: 'Esci', onPressed: logout, icon: const Icon(Icons.logout))],
    ),
    body: SafeArea(child: selected == null ? dashboard() : sectionPage(selected!)),
  );
  Widget dashboard() => LayoutBuilder(builder: (context, c) {
    final cols = c.maxWidth >= 1000 ? 4 : c.maxWidth >= 600 ? 3 : 2;
    return Column(children: [
      const Padding(padding: EdgeInsets.fromLTRB(16,18,16,4), child: Text('CENTRO OPERATIVO', textAlign: TextAlign.center,
        style: TextStyle(color: goldColor,fontSize:20,fontWeight:FontWeight.bold,letterSpacing:2))),
      const Padding(padding: EdgeInsets.symmetric(horizontal:16), child: Text('Gestione della tua collezione',style:TextStyle(color:Colors.white60))),
      Expanded(child: GridView.builder(padding: const EdgeInsets.all(16), itemCount: sections.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:.95),
        itemBuilder: (_, i) { final s = sections[i]; return Material(color:cardColor,borderRadius:BorderRadius.circular(16),
          child: InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>setState(()=>selected=s),
            child: Container(decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:s.color,width:1.2)),
              padding:const EdgeInsets.all(10),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                Container(width:54,height:54,decoration:BoxDecoration(color:s.color.withValues(alpha:.16),borderRadius:BorderRadius.circular(14)),
                  child:Icon(s.icon,color:s.color,size:30)),
                const SizedBox(height:12),Text(s.title,textAlign:TextAlign.center,style:TextStyle(color:s.color,fontWeight:FontWeight.bold,fontSize:13,letterSpacing:.5)),
                const SizedBox(height:6),Text(s.description,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white70,fontSize:11)),
              ]))));
        })),
      const Padding(padding:EdgeInsets.all(10),child:Text('COLLECTION by VALORA · TEST',style:TextStyle(color:Colors.white38,fontSize:11,letterSpacing:1))),
    ]);
  });
  Widget sectionPage(DashboardSection s) {
    final entries = s.title == 'CATALOGO' ? const [
      ('PR-01 · Nuovo oggetto','Crea uno o più oggetti',Icons.add_box_outlined),
      ('PR-02 · Modifica oggetto','Cerca, visualizza e modifica schede',Icons.edit_outlined),
      ('PR-03 · Chiudi oggetto','Registra smarrimento, distruzione o cessione',Icons.archive_outlined),
      ('PR-11 · Visualizza scheda','Leggi la scheda completa, inclusi i campi vuoti',Icons.visibility_outlined),
      ('CR · Elenco oggetti','Consulta e cerca il catalogo',Icons.list_alt),
      ('CR · Esplora record','Ricerca paginata nel database',Icons.search),
    ] : const [
      ('Consultazioni disponibili','Apri gli strumenti runtime verificati',Icons.search),
    ];
    return ListView(padding:const EdgeInsets.all(16),children:[
      Icon(s.icon,color:s.color,size:50),const SizedBox(height:10),
      Text(s.title,textAlign:TextAlign.center,style:TextStyle(color:s.color,fontSize:24,fontWeight:FontWeight.bold)),
      const SizedBox(height:18),
      ...entries.map((e)=>Card(margin:const EdgeInsets.only(bottom:10),child:ListTile(
        leading:CircleAvatar(backgroundColor:s.color.withValues(alpha:.16),child:Icon(e.$3,color:s.color)),
        title:Text(e.$1),subtitle:Text(e.$2),trailing:const Icon(Icons.chevron_right),
        onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ObjectRuntimePage(title:e.$1))),
      ))),
      const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('Ambiente TEST. Le scritture richiedono autenticazione, blocco esclusivo, conferma esplicita e verifica della rilettura.'))),
    ]);
  }
}

class RuntimeApi {
  static final client = Supabase.instance.client;
  static Future<Map<String,dynamic>> call(String action, Map<String,dynamic> body) async {
    final response = await client.functions.invoke('collection-procedure-runtime-test',
      body: {'action':action, ...body});
    final data = response.data;
    if (data is Map) {
      final map = Map<String,dynamic>.from(data);
      if (response.status >= 400 || map['error'] != null) throw Exception(map['error'] ?? 'HTTP ${response.status}');
      return map;
    }
    throw Exception('Risposta runtime non valida (HTTP ${response.status}).');
  }
  static Future<Map<String,dynamic>> procedure(String code,String step,Map<String,dynamic> payload,
      {required String sessionId,String? requestId}) async {
    final response = await client.functions.invoke('collection-procedure-runtime-test',
      body:{'procedure':code,'step':step,'payload':payload,'session_id':sessionId,'request_id':requestId});
    final data=response.data;
    if(data is Map){
      final map=Map<String,dynamic>.from(data);
      if(response.status>=400 || map['error']!=null) throw Exception(map['error']??'HTTP ${response.status}');
      final result=map['result'];
      if(result is Map) return Map<String,dynamic>.from(result);
      throw Exception('La funzione runtime non ha restituito un risultato strutturato.');
    }
    throw Exception('Risposta runtime non valida.');
  }
}

class ObjectRuntimePage extends StatefulWidget {
  const ObjectRuntimePage({super.key,required this.title});
  final String title;
  @override
  State<ObjectRuntimePage> createState()=>_ObjectRuntimePageState();
}
class _ObjectRuntimePageState extends State<ObjectRuntimePage> {
  final search=TextEditingController(), description=TextEditingController(), notes=TextEditingController(), code=TextEditingController();
  final quantity=TextEditingController(text:'1'), value=TextEditingController();
  final sessionId=uuid.v4();
  String condition='USATO', completeness='COMPLETO', destination='COLLEZIONE', closeReason='SMARRITO';
  String? procedureCode;
  bool loading=false, lockHeld=false, dataConfirmed=false, anotherOperation=false, finalReady=false;
  int? loadedObjectId;
  Map<String,dynamic>? lastResult;
  String output='Pronto. Le consultazioni sono in sola lettura; le scritture richiedono conferme distinte.';
  List<dynamic> rows=[];
  @override
  void initState(){super.initState();procedureCode=_chooseCode(widget.title);}
  String? _chooseCode(String t){if(t.contains('PR-01'))return 'PR-01';if(t.contains('PR-02'))return 'PR-02';if(t.contains('PR-03'))return 'PR-03';if(t.contains('PR-11'))return 'OBJECT_MASTER';if(t.contains('Elenco'))return 'OBJECTS_AVAILABLE';if(t.contains('Esplora'))return 'EXPLORE_RECORDS';return null;}
  @override
  void dispose(){search.dispose();description.dispose();notes.dispose();code.dispose();quantity.dispose();value.dispose();super.dispose();}
  Future<void> _run(Future<void> Function() action) async {if(loading)return;setState(()=>loading=true);try{await action();}catch(e){if(mounted)setState(()=>output='ERRORE: $e');}finally{if(mounted)setState(()=>loading=false);}}
  Future<void> _lock() async {
    final r=await RuntimeApi.call('acquire_lock',{'session_id':sessionId});
    final result=r['result'];
    if(result is Map && result['acquisito']==true){lockHeld=true;setState(()=>output='Blocco esclusivo acquisito. Ora puoi preparare la procedura.');}
    else throw Exception(result is Map ? result['messaggio']??'Archivio bloccato.' : 'Blocco esclusivo non acquisito.');
  }
  Future<void> _consult(String code,Map<String,dynamic> args) async {
    final r=await RuntimeApi.call('consultation',{'session_id':sessionId,'consultation_code':code,'arguments':args});
    final result=r['result'];
    if(result is Map){final val=result['risultato'];rows=val is List?val:val==null?[]:[val];}
    else {rows=result is List?result:result==null?[]:[result];}
    setState(()=>output=const JsonEncoder.withIndent('  ').convert(r));
  }
  Map<String,dynamic> _payload() {
    final id=int.tryParse(code.text.trim());
    if(procedureCode=='PR-01') return {'oggetti':[{'descrizione':description.text.trim(),'condizione':condition,'completezza':completeness,'destinazione':destination,'quantita':int.tryParse(quantity.text)??1,'note':notes.text.trim().isEmpty?null:notes.text.trim()}]};
    if(procedureCode=='PR-02') {
      if(id==null || id<=0) throw Exception('Inserisci un codice oggetto valido.');
      if(loadedObjectId != id) throw Exception('Prima di modificare, carica la scheda completa dal database e verifica i valori correnti.');
      final item=<String,dynamic>{'codice_oggetto':id};
      if(description.text.trim().isNotEmpty)item['descrizione']=description.text.trim();
      item['condizione']=condition;item['completezza']=completeness;item['destinazione']=destination;
      if(notes.text.trim().isNotEmpty)item['note']=notes.text.trim();
      if(value.text.trim().isNotEmpty)item['valore_oggetto']=double.tryParse(value.text.replaceAll(',','.'));
      return {'oggetti':[item]};
    }
    if(procedureCode=='PR-03'){
      if(id==null || id<=0) throw Exception('Inserisci un codice oggetto valido.');
      return {'oggetti':[{'codice_oggetto':id,'motivo_chiusura':closeReason,'note':notes.text.trim()}]};
    }
    throw Exception('Procedura non selezionata.');
  }
  Future<void> _loadObjectSheet() async {
    final id = int.tryParse(code.text.trim());
    if (id == null || id <= 0) throw Exception('Inserisci un codice oggetto valido.');
    final r = await RuntimeApi.call('consultation', {
      'session_id': sessionId,
      'consultation_code': 'OBJECT_MASTER',
      'arguments': {'codice_oggetto': id},
    });
    final outer = r['result'];
    dynamic data = outer is Map ? outer['risultato'] : null;
    if (data is List) {
      if (data.isEmpty) throw Exception('Nessuna scheda trovata per il codice $id.');
      data = data.first;
    }
    if (data is! Map) throw Exception('La consultazione non ha restituito una scheda leggibile: ${const JsonEncoder.withIndent('  ').convert(r)}');
    final m = Map<String, dynamic>.from(data);
    String getText(List<String> keys, [String fallback = '']) {
      for (final k in keys) {
        final v = m[k];
        if (v != null) return v.toString();
      }
      return fallback;
    }
    setState(() {
      loadedObjectId = id;
      description.text = getText(['descrizione_oggetto', 'descrizione']);
      notes.text = getText(['note']);
      quantity.text = getText(['quantita'], '1');
      value.text = getText(['valore_oggetto']);
      final c = getText(['condizione'], condition);
      if (['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'].contains(c)) condition = c;
      final cp = getText(['completezza'], completeness);
      if (['SIGILLATO','COMPLETO','INCOMPLETO'].contains(cp)) completeness = cp;
      final d = getText(['destinazione'], destination);
      if (['COLLEZIONE','RIVENDITA','ALTRO'].contains(d)) destination = d;
      output = 'SCHEDA COMPLETA LETTA DAL DATABASE (sola lettura):\n${const JsonEncoder.withIndent('  ').convert(m)}\n\nI campi sono stati precompilati con i valori correnti. Controlla e modifica solo ciò che desideri.';
    });
  }

  Future<void> _preview() async {
    if(procedureCode=='PR-02' && loadedObjectId != int.tryParse(code.text.trim())) throw Exception('Per PR-02 carica prima la scheda completa del codice selezionato.');
    if(procedureCode==null){await _consult(_chooseCode(widget.title)??'OBJECTS_AVAILABLE',{'cerca':search.text.trim(),'limite':100,'offset':0});return;}
    if(!lockHeld)await _lock();
    final p=_payload();
    final r=await RuntimeApi.procedure(procedureCode!,'preview',p,sessionId:sessionId);
    setState(() {
      lastResult = r;
      dataConfirmed = false;
      finalReady = false;
      output = const JsonEncoder.withIndent('  ').convert(r);
    });
  }
  Future<void> _confirmData() async {
    if(lastResult==null)throw Exception('Esegui prima l’anteprima.');
    final p=_payload()..['dati_confermati']=true..['altra_operazione']=false..['conferma_finale']=false;
    final r=await RuntimeApi.procedure(procedureCode!,'review',p,sessionId:sessionId);
    setState(() {
      lastResult = r;
      dataConfirmed = true;
      finalReady = true;
      output = 'Dati confermati. Verifica il riepilogo e premi SALVA solo se corretto.\n${const JsonEncoder.withIndent('  ').convert(r)}';
    });
  }
  Future<void> _save() async {
    if(!dataConfirmed||!finalReady)throw Exception('Conferma i dati prima del salvataggio.');
    final p=_payload()..['dati_confermati']=true..['altra_operazione']=false..['conferma_finale']=true;
    final r=await RuntimeApi.procedure(procedureCode!,'save',p,sessionId:sessionId,requestId:uuid.v4());
    setState(() {
      lastResult = r;
      output = const JsonEncoder.withIndent('  ').convert(r);
      dataConfirmed = false;
      finalReady = false;
    });
    if(r['scrittura_eseguita']!=true) throw Exception('Il runtime non ha confermato una scrittura verificata. Controlla l’esito prima di riprovare.');
    if(procedureCode=='PR-01'){description.clear();notes.clear();quantity.text='1';}
  }
  Future<void> _release() async {
    final r=await RuntimeApi.call('release_lock',{'session_id':sessionId});
    final result=r['result'];
    if (result is Map && result['rilasciato'] == true) {
      setState(() {
        lockHeld = false;
        output = 'Blocco esclusivo rilasciato.';
      });
    }
    else throw Exception(result is Map?result['messaggio']??'Blocco non rilasciato':'Blocco non rilasciato');
  }
  Widget field(TextEditingController c,String label,{int lines=1,TextInputType type=TextInputType.text})=>Padding(
    padding:const EdgeInsets.only(bottom:12),child:TextField(controller:c,maxLines:lines,keyboardType:type,decoration:InputDecoration(labelText:label)));
  Widget dropdown(String label,String current,List<String> options,ValueChanged<String?> changed)=>Padding(
    padding:const EdgeInsets.only(bottom:12),child:DropdownButtonFormField<String>(initialValue:current,decoration:InputDecoration(labelText:label),
      items:options.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:changed));
  @override
  Widget build(BuildContext context){
    final write=procedureCode!=null && procedureCode!.startsWith('PR-');
    return Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView(padding:const EdgeInsets.all(16),children:[
      Card(child:Padding(padding:const EdgeInsets.all(12),child:Text('COLLECTION by VALORA · TEST\nUtente: ${Supabase.instance.client.auth.currentUser?.email??'sessione autenticata'}\n${lockHeld?'Blocco archivio: ATTIVO':'Blocco archivio: non acquisito'}',style:const TextStyle(color:goldColor)))),
      if(procedureCode=='PR-01') ...[
        field(description,'Descrizione oggetto *',lines:2),
        dropdown('Condizione',condition,['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'],(v)=>setState(()=>condition=v!)),
        dropdown('Completezza',completeness,['SIGILLATO','COMPLETO','INCOMPLETO'],(v)=>setState(()=>completeness=v!)),
        dropdown('Destinazione',destination,['COLLEZIONE','RIVENDITA','ALTRO'],(v)=>setState(()=>destination=v!)),
        field(quantity,'Quantità',type:TextInputType.number),field(notes,'Note',lines:2),
      ],
      if(procedureCode=='PR-02'||procedureCode=='PR-03'||procedureCode=='OBJECT_MASTER') ...[
        field(code,'Codice oggetto'),
        if(procedureCode=='PR-02') ...[
          OutlinedButton.icon(onPressed:loading?null:()=>_run(_loadObjectSheet),icon:const Icon(Icons.download_outlined),label:const Text('CARICA SCHEDA COMPLETA DAL DATABASE')),
        ],
        if(procedureCode=='PR-02') ...[
          field(description,'Nuova descrizione (lascia vuoto per non cambiarla)',lines:2),
          dropdown('Condizione',condition,['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'],(v)=>setState(()=>condition=v!)),
          dropdown('Completezza',completeness,['SIGILLATO','COMPLETO','INCOMPLETO'],(v)=>setState(()=>completeness=v!)),
          dropdown('Destinazione',destination,['COLLEZIONE','RIVENDITA','ALTRO'],(v)=>setState(()=>destination=v!)),
          field(value,'Valore oggetto (€)',type:const TextInputType.numberWithOptions(decimal:true)),field(notes,'Note',lines:2),
        ],
        if(procedureCode=='PR-03') ...[
          dropdown('Motivo chiusura',closeReason,['SMARRITO','DISTRUTTO','DATO VIA'],(v)=>setState(()=>closeReason=v!)),
          field(notes,'Note',lines:2),
        ],
      ],
      if(procedureCode=='OBJECTS_AVAILABLE'||procedureCode=='EXPLORE_RECORDS') ...[
        field(search,'Cerca descrizione o codice'),
        if(procedureCode=='EXPLORE_RECORDS') const Text('Tabella consultata: master_oggetti. Risultati paginati, in sola lettura.',style:TextStyle(color:Colors.white70)),
      ],
      if(procedureCode==null) const Text('Seleziona una procedura OGGETTO dal menu precedente.',style:TextStyle(color:Colors.white70)),
      if(write) ...[
        FilledButton.icon(onPressed:loading?null:()=>_run(_preview),icon:const Icon(Icons.fact_check_outlined),label:Text(loading?'ATTENDI...':'1 · CONTROLLA DATI E ANTEPRIMA')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:loading||lastResult==null?null:()=>_run(_confirmData),icon:const Icon(Icons.verified_outlined),label:const Text('2 · CONFERMO I DATI'),
        ),
        const SizedBox(height:8),
        FilledButton.icon(onPressed:loading||!dataConfirmed||!finalReady?null:()=>_run(_save),icon:const Icon(Icons.save_outlined),label:const Text('3 · CONFERMA DEFINITIVA E SALVA')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:loading||!lockHeld?null:()=>_run(_release),icon:const Icon(Icons.lock_open),label:const Text('RILASCIA BLOCCO ARCHIVIO')),
      ] else ...[
        FilledButton.icon(onPressed:loading?null:()=>_run(()=>_consult(procedureCode??'OBJECTS_AVAILABLE',procedureCode=='OBJECT_MASTER'?{'codice_oggetto':int.tryParse(code.text.trim())}:procedureCode=='EXPLORE_RECORDS'?{'tabella':'master_oggetti','limite':100,'offset':0}:{'cerca':search.text.trim(),'limite':100,'offset':0}),),icon:const Icon(Icons.search),label:Text(loading?'RICERCA...':'ESEGUI CONSULTAZIONE')),
      ],
      const SizedBox(height:16),
      const Text('ESITO RUNTIME / RILETTURA DATABASE',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:cardColor,borderRadius:BorderRadius.circular(12)),
        child:SelectableText(output,style:const TextStyle(fontFamily:'monospace',fontSize:12))),
    ]));
  }
}
