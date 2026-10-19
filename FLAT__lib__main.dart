import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

const String supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const String publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
const Color backgroundColor = Color(0xFF101010);
const Color cardColor = Color(0xFF1C1C1C);
const Color goldColor = Color(0xFFD6B15E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: publishableKey,
    );
  } catch (error, stackTrace) {
    startupError = '$error';
    debugPrint('VALORA startup initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  runApp(CollectionValoraApp(startupError: startupError));
}

class CollectionValoraApp extends StatelessWidget {
  const CollectionValoraApp({super.key, this.startupError});

  final String? startupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'COLLECTION by VALORA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: backgroundColor,
          colorScheme: const ColorScheme.dark(
            primary: goldColor,
            secondary: goldColor,
            surface: cardColor,
            error: Color(0xFFE35D5D),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: backgroundColor,
            foregroundColor: goldColor,
            centerTitle: true,
          ),
          cardTheme: const CardThemeData(color: cardColor, elevation: 3),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: goldColor, width: 1.5),
            ),
          ),
        ),
        home: startupError == null
            ? const AuthenticationGate()
            : StartupFailurePage(error: startupError!),
      );
}

class StartupFailurePage extends StatelessWidget {
  const StartupFailurePage({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: goldColor, size: 64),
                    const SizedBox(height: 20),
                    const Text(
                      'COLLECTION by VALORA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: goldColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Avvio non completato. Il dettaglio seguente aiuta a individuare la causa.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      error,
                      style: const TextStyle(color: Color(0xFFE35D5D)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) =>
            Supabase.instance.client.auth.currentSession != null
                ? const HomeDashboard()
                : const LoginPage(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  String message = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => message = 'Inserisci email e password.');
      return;
    }
    setState(() { loading = true; message = ''; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email, password: password,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (e) {
      if (mounted) setState(() => message = 'Errore di accesso: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 112, height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: cardColor,
                        border: Border.all(color: goldColor, width: 2),
                      ),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: goldColor, size: 56),
                    ),
                    const SizedBox(height: 24),
                    const Text('COLLECTION', style: TextStyle(
                      color: goldColor, fontSize: 28,
                      fontWeight: FontWeight.bold, letterSpacing: 3,
                    )),
                    const SizedBox(height: 4),
                    const Text('by VALORA', style: TextStyle(
                      color: Colors.white70, fontSize: 16, letterSpacing: 2,
                    )),
                    const SizedBox(height: 36),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email', prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onSubmitted: (_) => signIn(),
                      decoration: InputDecoration(
                        labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: FilledButton(
                        onPressed: loading ? null : signIn,
                        child: loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('ACCEDI', style: TextStyle(
                                fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(message, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 24),
                    const Text('AMBIENTE TEST', style: TextStyle(
                      color: Colors.orangeAccent, fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class DashboardSection {
  const DashboardSection({required this.title, required this.description,
    required this.icon, required this.color});
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

const List<DashboardSection> dashboardSections = [
  DashboardSection(title: 'CATALOGO', description: 'Consulta gli oggetti', icon: Icons.inventory_2_outlined, color: Color(0xFF3978C5)),
  DashboardSection(title: 'ACQUISTI', description: 'Gestione acquisti', icon: Icons.shopping_cart_outlined, color: Color(0xFF39875B)),
  DashboardSection(title: 'VENDITE', description: 'Gestione vendite', icon: Icons.sell_outlined, color: Color(0xFFC74444)),
  DashboardSection(title: 'FLUSSI', description: 'Movimenti e saldi', icon: Icons.account_balance_wallet_outlined, color: Color(0xFFD6A83F)),
  DashboardSection(title: 'VALUTAZIONI', description: 'Valore degli oggetti', icon: Icons.query_stats, color: Color(0xFF8556C7)),
  DashboardSection(title: 'REPORT', description: 'Riepiloghi e risultati', icon: Icons.analytics_outlined, color: Color(0xFFE17D35)),
  DashboardSection(title: 'RICERCHE', description: 'Cerca dati e fonti', icon: Icons.search, color: Color(0xFF568DAD)),
  DashboardSection(title: 'CONTROLLO', description: 'Stato e verifiche', icon: Icons.admin_panel_settings_outlined, color: Color(0xFF777777)),
];

class ProcedureEntry {
  const ProcedureEntry({required this.title, required this.description,
    this.apiCode, this.readOnly = true, this.enabled = true});
  final String title;
  final String description;
  final String? apiCode;
  final bool readOnly;
  final bool enabled;
}

const Map<String, List<ProcedureEntry>> sectionProcedures = {
  'CATALOGO': [
    ProcedureEntry(title: 'PR-01 · Nuovo oggetto', description: 'Crea un oggetto e prepara i metadati per la ricerca.', apiCode: 'PR-01', readOnly: false),
    ProcedureEntry(title: 'PR-02 · Modifica oggetto', description: 'Carica la scheda completa prima di modificarla.', apiCode: 'PR-02', readOnly: false),
    ProcedureEntry(title: 'PR-03 · Chiudi oggetto', description: 'Registra la chiusura con motivazione.', apiCode: 'PR-03', readOnly: false),
    ProcedureEntry(title: 'PR-11 · Visualizza scheda', description: 'Mostra la scheda completa in formato leggibile.', apiCode: 'OBJECT_MASTER'),
    ProcedureEntry(title: 'CR · Elenco oggetti disponibili', description: 'Mostra gli oggetti con stato DISPONIBILE.', apiCode: 'OBJECTS_AVAILABLE'),
    ProcedureEntry(title: 'CR · Esplora record', description: 'Mostra la cronologia del singolo oggetto selezionato.', apiCode: 'EXPLORE_RECORDS'),
  ],
  'ACQUISTI': [
    ProcedureEntry(title: 'Nuovo acquisto', description: 'Registra un nuovo acquisto.', apiCode: 'WRITE-PR-04', readOnly: false),
    ProcedureEntry(title: 'Modifica acquisto', description: 'Modifica un acquisto esistente.', apiCode: 'WRITE-PR-05', readOnly: false),
    ProcedureEntry(title: 'Elenco acquisti', description: 'Consulta gli acquisti registrati.', apiCode: 'REPORT-PURCHASES'),
    ProcedureEntry(title: 'Acquisti comparati', description: 'Confronta gli acquisti.', enabled: false),
  ],
  'VENDITE': [
    ProcedureEntry(title: 'Nuova vendita', description: 'Registra una vendita.', apiCode: 'WRITE-PR-06', readOnly: false),
    ProcedureEntry(title: 'Nuova inserzione', description: 'Crea una nuova inserzione.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Modifica inserzione', description: 'Modifica un’inserzione esistente.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Chiudi inserzione', description: 'Chiude un’inserzione attiva.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Vendita multipla Vinted', description: 'Registra una vendita multipla.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Inserzioni attive', description: 'Consulta le inserzioni attive.', apiCode: 'REPORT-ACTIVE-LISTINGS'),
    ProcedureEntry(title: 'Report vendite', description: 'Consulta il riepilogo delle vendite.', apiCode: 'REPORT-SALES'),
  ],
  'FLUSSI': [
    ProcedureEntry(title: 'Flussi di cassa', description: 'Consulta i movimenti di cassa.', apiCode: 'REPORT-CASH'),
    ProcedureEntry(title: 'Nuovo movimento extra', description: 'Registra un movimento extra.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Giroconto', description: 'Sposta fondi tra destinazioni.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Mostra saldi', description: 'Consulta i saldi disponibili.', enabled: false),
    ProcedureEntry(title: 'Report spese', description: 'Consulta il riepilogo delle spese.', enabled: false),
  ],
  'VALUTAZIONI': [
    ProcedureEntry(title: 'Valuta oggetto', description: 'Prepara la consultazione per la valutazione di un oggetto.', apiCode: 'READ-VALUATION-PREPARE'),
    ProcedureEntry(title: 'Valuta più oggetti', description: 'Prepara la valutazione di più oggetti.', apiCode: 'READ-VALUATION-PREPARE'),
    ProcedureEntry(title: 'Opportunità di acquisto', description: 'Individua opportunità di acquisto.', enabled: false),
    ProcedureEntry(title: 'Report opportunità', description: 'Consulta il report delle opportunità.', enabled: false),
  ],
  'REPORT': [
    ProcedureEntry(title: 'Report acquisti', description: 'Riepilogo degli acquisti registrati.', apiCode: 'REPORT-PURCHASES'),
    ProcedureEntry(title: 'Report vendite', description: 'Riepilogo delle vendite registrate.', apiCode: 'REPORT-SALES'),
    ProcedureEntry(title: 'Report mattutino', description: 'Riepilogo operativo del mattino.', enabled: false),
  ],
  'RICERCHE': [
    ProcedureEntry(title: 'PR-12 · Ricerca metadati in lotti', description: 'Analizza fino a 10 oggetti incompleti per lotto, mostra fonti e risultati senza modificare il database.', apiCode: 'PR-12-BATCH'),
    ProcedureEntry(title: 'Ricerca oggetti', description: 'Cerca gli oggetti nel catalogo.', apiCode: 'READ-EXPLORE-RECORDS'),
    ProcedureEntry(title: 'Ricerca #DEMONOFLU', description: 'Ricerca inserzioni associate a #DEMONOFLU.', enabled: false),
  ],
  'CONTROLLO': [
    ProcedureEntry(title: 'Stato runtime', description: 'Verifica lo stato del servizio runtime.', apiCode: 'RUNTIME-HEALTH'),
    ProcedureEntry(title: 'Catalogo API', description: 'Consulta il catalogo delle API runtime.', apiCode: 'RUNTIME-CATALOG'),
    ProcedureEntry(title: 'Pulizia file', description: 'Operazione non disponibile nell’app runtime.', enabled: false),
  ],
};

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  DashboardSection? selectedSection;

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) setState(() => selectedSection = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: selectedSection == null ? null : IconButton(
            tooltip: 'Torna alla dashboard',
            onPressed: () => setState(() => selectedSection = null),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('COLLECTION by VALORA', style: TextStyle(
            fontWeight: FontWeight.bold, letterSpacing: 1,
          )),
          actions: [IconButton(tooltip: 'Esci', onPressed: logout, icon: const Icon(Icons.logout))],
        ),
        body: SafeArea(child: selectedSection == null
            ? buildDashboard() : buildSection(selectedSection!)),
      );

  Widget buildDashboard() => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000 ? 4 : constraints.maxWidth >= 600 ? 3 : 2;
        return Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text('CENTRO OPERATIVO', textAlign: TextAlign.center,
              style: TextStyle(color: goldColor, fontSize: 20,
                fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Gestione della tua collezione', style: TextStyle(color: Colors.white60))),
          Expanded(child: GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: dashboardSections.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              final section = dashboardSections[index];
              return Material(
                color: cardColor, borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => selectedSection = section),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: section.color, width: 1.2)),
                    padding: const EdgeInsets.all(10),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 54, height: 54,
                        decoration: BoxDecoration(color: section.color.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14)),
                        child: Icon(section.icon, color: section.color, size: 30)),
                      const SizedBox(height: 12),
                      Text(section.title, textAlign: TextAlign.center,
                        style: TextStyle(color: section.color, fontWeight: FontWeight.bold,
                          fontSize: 13, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(section.description, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ),
                ),
              );
            },
          )),
          const Padding(padding: EdgeInsets.all(10), child: Text('COLLECTION by VALORA · TEST',
            style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1))),
        ]);
      });

  Widget buildSection(DashboardSection section) {
    final procedures = sectionProcedures[section.title] ?? const <ProcedureEntry>[];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), children: [
      Icon(section.icon, color: section.color, size: 52),
      const SizedBox(height: 12),
      Text(section.title, textAlign: TextAlign.center, style: TextStyle(
        color: section.color, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 6),
      Text(section.description, textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 20),
      ...procedures.map((procedure) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          enabled: procedure.enabled,
          leading: CircleAvatar(
            backgroundColor: procedure.enabled ? section.color.withValues(alpha: 0.18) : Colors.white10,
            child: Icon(procedure.enabled
                ? (procedure.readOnly ? Icons.play_arrow : Icons.edit_outlined)
                : Icons.lock_outline,
              color: procedure.enabled ? section.color : Colors.white38),
          ),
          title: Text(procedure.title, style: TextStyle(fontWeight: FontWeight.w600,
            color: procedure.enabled ? Colors.white : Colors.white38)),
          subtitle: Text(procedure.enabled
              ? '${procedure.description}${procedure.apiCode == null ? '' : '\nAPI candidata: ${procedure.apiCode}'}'
              : '${procedure.description}\nIn attesa di un mapping runtime verificato'),
          isThreeLine: true,
          trailing: Icon(procedure.enabled ? Icons.chevron_right : Icons.lock_outline,
            color: procedure.enabled ? section.color : Colors.white24),
          onTap: procedure.enabled && procedure.apiCode != null
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => procedure.apiCode == 'PR-12-BATCH'
                        ? const Pr12BatchPage()
                        : ObjectRuntimePage(title: procedure.title, apiCode: procedure.apiCode!)))
              : null,
        ),
      )),
      const SizedBox(height: 12),
      const Card(child: Padding(padding: EdgeInsets.all(14), child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: goldColor), SizedBox(width: 10),
          Expanded(child: Text('Le procedure sono collocate nel sottomenu corretto. '
            'Le API mostrate sono candidate e da collaudare. Le scritture restano protette: '
            'nessun dato viene salvato da questa schermata.')),
        ],
      ))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () => setState(() => selectedSection = null),
        icon: const Icon(Icons.dashboard_outlined), label: const Text('TORNA ALLA DASHBOARD')),
    ]);
  }

  void showProcedureInfo(ProcedureEntry procedure) {
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(procedure.title),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(procedure.description),
        const SizedBox(height: 14),
        if (procedure.apiCode != null) Text('Codice API candidato: ${procedure.apiCode}'),
        const SizedBox(height: 10),
        Text(procedure.readOnly ? 'Modalità prevista: consultazione / sola lettura.'
          : 'Modalità prevista: scrittura, ancora non attivata.'),
        const SizedBox(height: 10),
        const Text('Il collegamento runtime sarà attivato dopo la verifica del contratto input '
          'e dei passaggi di anteprima, conferma e verifica in ambiente TEST.'),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('CHIUDI'))],
    ));
  }
}

const _uuid = Uuid();

class _ValoraRuntimeApi {
  static final _client = Supabase.instance.client;

  static Future<Map<String, dynamic>> call(String action, Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(
      'collection-procedure-runtime-test',
      body: {'action': action, ...body},
    );
    final data = response.data;
    if (data is! Map) throw Exception('Risposta runtime non valida (HTTP ${response.status}).');
    final map = Map<String, dynamic>.from(data);
    if (response.status >= 400 || map['error'] != null) {
      throw Exception(map['error'] ?? 'HTTP ${response.status}');
    }
    return map;
  }

  static Future<Map<String, dynamic>> procedure(
    String code, String step, Map<String, dynamic> payload, {
    required String sessionId, String? requestId,
  }) async {
    final response = await _client.functions.invoke(
      'collection-procedure-runtime-test',
      body: {
        'procedure': code, 'step': step, 'payload': payload,
        'session_id': sessionId, 'request_id': requestId,
      },
    );
    final data = response.data;
    if (data is! Map) throw Exception('Risposta runtime non valida.');
    final map = Map<String, dynamic>.from(data);
    if (response.status >= 400 || map['error'] != null) {
      throw Exception(map['error'] ?? 'HTTP ${response.status}');
    }
    if (map['result'] is Map) return Map<String, dynamic>.from(map['result']);
    throw Exception('Il runtime non ha restituito un risultato strutturato.');
  }
}


class Pr12BatchPage extends StatefulWidget {
  const Pr12BatchPage({super.key});
  @override
  State<Pr12BatchPage> createState() => _Pr12BatchPageState();
}
class _Pr12BatchPageState extends State<Pr12BatchPage> {
  bool _loading = false, _running = false;
  List<Map<String, dynamic>> _queue = [];
  final List<Map<String, dynamic>> _results = [];
  int _offset = 0;
  String _status = 'Carica gli oggetti incompleti. Nessun dato verrà salvato.';
  String? _error;

  Future<void> _loadQueue() async {
    if (_loading || _running) return;
    setState(() { _loading = true; _error = null; _status = 'Lettura catalogo TEST…'; _results.clear(); _offset = 0; });
    try {
      final data = await Supabase.instance.client.schema('collection').from('master_oggetti')
        .select('codice_oggetto,descrizione_oggetto,produttore,anno_uscita,codice_prodotto,archiviato_test')
        .order('codice_oggetto', ascending: true).limit(2000);
      final rows = (data as List).whereType<Map>().map((v) => Map<String, dynamic>.from(v)).where((v) {
        if (v['archiviato_test'] == true) return false;
        final p = (v['produttore'] ?? '').toString().trim();
        final c = (v['codice_prodotto'] ?? '').toString().trim();
        return p.isEmpty || c.isEmpty || v['anno_uscita'] == null;
      }).where((v) => (v['descrizione_oggetto'] ?? '').toString().trim().length >= 2).toList();
      if (mounted) setState(() { _queue = rows; _status = 'Trovati ${rows.length} oggetti incompleti. Database invariato.'; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _status = 'Lettura catalogo non riuscita.'; });
    } finally { if (mounted) setState(() => _loading = false); }
  }

  String _category(String d) {
    final s = d.toLowerCase();
    if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(s)) return 'LEGO';
    if (RegExp(r'fumett|comic|manga|panini|salda.?press|isbn').hasMatch(s)) return 'FUMETTI';
    if (RegExp(r'myth cloth|saint seiya|cavalieri dello zodiaco|bandai|action figure|statua').hasMatch(s)) return 'ACTION_FIGURE';
    if (RegExp(r'maisto|die.?cast|modellin|hot wheels|matchbox').hasMatch(s)) return 'DIECAST';
    if (RegExp(r'birra|birre|beer|birrificio|breweriana').hasMatch(s)) return 'BEER';
    if (RegExp(r'vino|vini|bottiglia|bottiglie|barolo|champagne|brunello').hasMatch(s)) return 'WINE';
    return 'COLLEZIONABILE';
  }

  Future<void> _runBatch() async {
    if (_running || _loading) return;
    if (_queue.isEmpty || _offset >= _queue.length) { setState(() => _error = 'Carica la coda o tutti i lotti sono già stati elaborati.'); return; }
    final batch = _queue.skip(_offset).take(10).toList();
    setState(() { _running = true; _error = null; _status = 'PR-12 sta cercando fonti per ${batch.length} oggetti. Nessuna scrittura database.'; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Sessione scaduta. Accedi nuovamente.');
      final response = await http.post(Uri.parse('$supabaseUrl/functions/v1/pr-12-engine-test'),
        headers: {'apikey': publishableKey, 'Authorization': 'Bearer ${session.accessToken}', 'Content-Type': 'application/json', 'Accept': 'text/event-stream'},
        body: jsonEncode({'modalita_ia': 'TEST', 'oggetti': batch.map((v) => {
          'id': (v['codice_oggetto'] ?? '').toString(),
          'descrizione': (v['descrizione_oggetto'] ?? '').toString(),
          'categoria': _category((v['descrizione_oggetto'] ?? '').toString()),
        }).toList()})).timeout(const Duration(minutes: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 500).toInt())}');
      }
      final events = <Map<String, dynamic>>[];
      for (final line in const LineSplitter().convert(response.body)) {
        if (!line.startsWith('data:')) continue;
        try { final v = jsonDecode(line.substring(5).trim()); if (v is Map) events.add(Map<String, dynamic>.from(v)); } catch (_) {}
      }
      final finals = events.where((v) => v['tipo'] == 'coda_completata').toList();
      if (finals.isEmpty) {
        final errors = events.where((v) => v['tipo'] == 'oggetto_errore').map((v) => (v['risultato'] as Map?)?['error']?.toString() ?? 'errore').take(3).join('; ');
        throw Exception('Evento finale PR-12 assente. ${errors.isEmpty ? response.body.substring(0, response.body.length.clamp(0, 500).toInt()) : errors}');
      }
      final rawResults = finals.last['risultati_finali'];
      final batchResults = rawResults is List ? rawResults.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList() : <Map<String, dynamic>>[];
      if (mounted) setState(() {
        _results.addAll(batchResults); _offset += batch.length;
        final good = batchResults.where((v) => v['ok'] == true).length;
        _status = 'Lotto concluso: $good riusciti, ${batchResults.length - good} errori. Avanzamento \$_offset/${_queue.length}. Database invariato.';
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _status = 'Lotto interrotto. Puoi riprovare.'; });
    } finally { if (mounted) setState(() => _running = false); }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_queue.length - _offset).clamp(0, 10);
    return Scaffold(appBar: AppBar(title: const Text('PR-12 · RICERCA METADATI')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: Padding(padding: EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RICERCA MULTIPLA IN LOTTI', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          SizedBox(height: 8), Text('PR-12 elabora al massimo 10 oggetti per lotto e mostra fonti, candidati ed errori. Prova in sola lettura: nessun metadato viene scritto o sovrascritto.'),
        ]))),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _loading || _running ? null : _loadQueue,
          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
          label: const Text('CARICA OGGETTI INCOMPLETI')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _running || _loading || _queue.isEmpty || _offset >= _queue.length ? null : _runBatch,
          icon: _running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
          label: Text(_running ? 'RICERCA IN CORSO…' : 'ELABORA PROSSIMO LOTTO (\$remaining)')),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('STATO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(_status),
          if (_queue.isNotEmpty) Text('In coda: ${_queue.length} · elaborati: \$_offset · lotti: ${(_queue.length / 10).ceil()}'),
          if (_error != null) SelectableText(_error!, style: const TextStyle(color: Color(0xFFE35D5D))),
        ]))),
        if (_queue.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.only(top: 12, bottom: 4), child: Text('PROSSIMO LOTTO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
          ..._queue.skip(_offset).take(10).map((v) => ListTile(dense: true, leading: const Icon(Icons.inventory_2_outlined, color: goldColor),
            title: Text((v['descrizione_oggetto'] ?? 'Senza descrizione').toString()),
            subtitle: Text('ID ${v['codice_oggetto']} · produttore: ${v['produttore'] ?? 'mancante'} · anno: ${v['anno_uscita'] ?? 'mancante'} · codice: ${v['codice_prodotto'] ?? 'mancante'}'))),
        ],
        if (_results.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.only(top: 16, bottom: 4), child: Text('RISULTATI · SOLA LETTURA', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
          ..._results.map((v) {
            final candidates = v['risultati'] is List ? (v['risultati'] as List).whereType<Map>().toList() : <Map>[];
            return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${v['oggetto_id'] ?? ''} · ${v['descrizione'] ?? ''}', style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(v['ok'] == true ? 'Candidati: ${candidates.length} · nessuna scrittura' : 'ERRORE: ${v['error'] ?? 'non specificato'}'),
              ...candidates.take(4).map((c) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.link, color: goldColor),
                title: Text((c['title'] ?? 'Risultato senza titolo').toString(), style: const TextStyle(fontSize: 13)),
                subtitle: Text('${c['url'] ?? ''}\n${c['snippet'] ?? ''}', maxLines: 4, overflow: TextOverflow.ellipsis))),
              if (v['diagnostica_ricerca'] is Map) SelectableText('Diagnostica: ${jsonEncode(v['diagnostica_ricerca'])}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ])));
          }),
        ],
      ])));
  }
}


class ObjectRuntimePage extends StatefulWidget {
  const ObjectRuntimePage({super.key, required this.title, required this.apiCode, this.initialObjectCode});
  final String title;
  final String apiCode;
  final int? initialObjectCode;

  @override
  State<ObjectRuntimePage> createState() => _ObjectRuntimePageState();
}

class _ObjectRuntimePageState extends State<ObjectRuntimePage> {
  final _search = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();
  final _code = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _unitPrice = TextEditingController();
  final _totalValue = TextEditingController();
  final _value = TextEditingController();
  final _marketValue = TextEditingController(text: '0.00');
  final _producer = TextEditingController();
  final _line = TextEditingController();
  final _family = TextEditingController();

  final String _sessionId = _uuid.v4();
  final FocusNode _descriptionFocus = FocusNode();
  String _lastMetadataQuery = '';
  String? _metadataSourceUrl;
  bool _metadataSearchExecuted = false;
  String _metadataResult = 'La ricerca dei metadati partirà quando esci dal campo Descrizione oggetto.';
  bool _loading = false;
  bool _lockHeld = false;
  bool _dataConfirmed = false;
  bool _finalReady = false;
  int? _loadedObjectId;
  String _condition = 'USATO';
  String _completeness = 'COMPLETO';
  String _destination = 'COLLEZIONE';
  String _closeReason = 'SMARRITO';
  String _output = 'Pronto. Le consultazioni sono in sola lettura.';
  Map<String, dynamic>? _lastResult;
  List<dynamic> _rows = [];
  Map<String, dynamic>? _currentObject;
  List<Map<String, dynamic>> _pr02SearchResults = [];
  bool _showPr02TechnicalTab = false;
  bool _pr02SearchCompleted = false;
  final List<Map<String, dynamic>> _pr02PendingChanges = [];
  final FocusNode _searchFocusNode = FocusNode();

  bool get _isWrite => const {'PR-01', 'PR-02', 'PR-03'}.contains(widget.apiCode);

  @override
  void initState() {
    super.initState();
    if (widget.apiCode == 'PR-01') {
      // PR-12 runs independently; PR-01 must not trigger a web search.
      _quantity.addListener(_recalculateTotal);
      _unitPrice.addListener(_recalculateTotal);
    }
    if (widget.initialObjectCode != null) _code.text = widget.initialObjectCode.toString();
  }

  void _recalculateTotal() {
    if (widget.apiCode != 'PR-01') return;
    final quantity = int.tryParse(_quantity.text.trim());
    final unitText = _unitPrice.text.trim();
    if (quantity == null || quantity < 1 || unitText.isEmpty) {
      if (_totalValue.text.isNotEmpty) _totalValue.clear();
      return;
    }
    final unitPrice = double.tryParse(unitText.replaceAll(',', '.'));
    if (unitPrice == null || unitPrice < 0) {
      if (_totalValue.text.isNotEmpty) _totalValue.clear();
      return;
    }
    final totalCents = (unitPrice * 100 * quantity).round();
    final total = (totalCents / 100).toStringAsFixed(2);
    if (_totalValue.text != total) _totalValue.text = total;
  }

  void _onDescriptionFocusChanged() {
    if (widget.apiCode != 'PR-01' || _descriptionFocus.hasFocus) return;
    final query = _description.text.trim();
    if (query.length < 4 || query == _lastMetadataQuery || _loading) return;
    _run(() async {
      if (query != _description.text.trim()) return;
      setState(() {
        _metadataResult = 'RICERCA METADATI IN CORSO…';
        _output = 'Ricerca metadati in corso…';
      });
      try {
        await _prepareMetadata();
        if (mounted && query == _description.text.trim()) {
          setState(() => _lastMetadataQuery = query);
        }
      } catch (e) {
        if (mounted) setState(() => _metadataResult = 'Ricerca metadati non riuscita: $e');
        rethrow;
      }
    });
  }

  Future<void> _releaseOwnedLockSilently() async {
    try {
      await _ValoraRuntimeApi.call('release_lock', {'session_id': _sessionId});
    } catch (_) {
      // Il rilascio server-side può fallire; non mascherare l'uscita dalla schermata.
    }
  }

  @override
  void dispose() {
    if (_lockHeld) {
      _releaseOwnedLockSilently();
    }
    _descriptionFocus.dispose();
    _searchFocusNode.dispose();
    _search.dispose(); _description.dispose(); _notes.dispose(); _code.dispose();
    _quantity.dispose(); _unitPrice.dispose(); _totalValue.dispose(); _value.dispose(); _marketValue.dispose(); _producer.dispose(); _line.dispose(); _family.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _output = 'ERRORE: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acquireLock() async {
    final response = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _sessionId});
    final result = response['result'];
    if (result is Map && result['acquisito'] == true) {
      setState(() { _lockHeld = true; _output = 'Blocco esclusivo acquisito.'; });
      return;
    }
    throw Exception(result is Map ? (result['messaggio'] ?? 'Archivio bloccato.') : 'Blocco esclusivo non acquisito.');
  }

  Future<void> _releaseLock() async {
    final response = await _ValoraRuntimeApi.call('release_lock', {'session_id': _sessionId});
    final result = response['result'];
    if (result is Map && result['rilasciato'] == true) {
      setState(() { _lockHeld = false; _output = 'Blocco archivio rilasciato.'; });
      return;
    }
    throw Exception(result is Map ? (result['messaggio'] ?? 'Blocco non rilasciato.') : 'Blocco non rilasciato.');
  }

  bool get _hasAnyMetadata =>
      _producer.text.trim().isNotEmpty ||
      _line.text.trim().isNotEmpty ||
      _family.text.trim().isNotEmpty ||
      (_metadataSourceUrl?.trim().isNotEmpty ?? false);

  double _parseNonNegativeValue(String raw, String label) {
    final parsed = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (parsed == null || parsed < 0) {
      throw Exception('$label non valido. Inserisci un importo positivo o zero, oppure lascia vuoto.');
    }
    return parsed;
  }

  Map<String, dynamic> _payload() {
    final id = int.tryParse(_code.text.trim());
    if (widget.apiCode == 'PR-01') {
      if (_description.text.trim().isEmpty) throw Exception('La descrizione è obbligatoria.');
      final q = int.tryParse(_quantity.text.trim());
      if (q == null || q <= 0) throw Exception('La quantità deve essere un intero positivo.');
      final unitPriceText = _unitPrice.text.trim();
      final double? unitPrice = unitPriceText.isEmpty
          ? null
          : _parseNonNegativeValue(unitPriceText, 'Prezzo unitario');
      final double? totalValue = unitPrice == null
          ? null
          : ((unitPrice * 100 * q).round() / 100.0);
      _recalculateTotal();
      return {'oggetti': [{
        'descrizione': _description.text.trim(),
        'produttore': _producer.text.trim().isEmpty ? null : _producer.text.trim(),
        'anno_uscita': _line.text.trim().isEmpty ? null : int.tryParse(_line.text.trim()),
        'codice_prodotto': _family.text.trim().isEmpty ? null : _family.text.trim(),
        if (_hasAnyMetadata)
          'fonte_dati_prodotto': (_metadataSourceUrl?.trim().isNotEmpty == true)
              ? _metadataSourceUrl!.trim()
              : (_metadataSearchExecuted
                  ? 'RICERCA_ESEGUITA_NESSUNA_FONTE_SELEZIONATA'
                  : 'RICERCA_NON_ESEGUITA'),
        if (_hasAnyMetadata) 'stato_verifica_dati': 'DA_VERIFICARE',
        'condizione': _condition, 'completezza': _completeness,
        'destinazione': _destination, 'quantita': q,
        if (totalValue != null) 'valore_oggetto': totalValue,
        'note': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      }]};
    }
    if (id == null || id <= 0) throw Exception('Inserisci un codice oggetto valido.');
    if (widget.apiCode == 'PR-02') {
      if (_loadedObjectId != id) throw Exception('Carica la scheda completa del codice selezionato prima di procedere.');
      final item = <String, dynamic>{'codice_oggetto': id};
      if (_description.text.trim() != (_currentObject?['descrizione_oggetto'] ?? _currentObject?['descrizione'] ?? '').toString()) {
        item['descrizione'] = _description.text.trim();
      }
      if (_condition != (_currentObject?['condizione'] ?? _condition)) item['condizione'] = _condition;
      if (_completeness != (_currentObject?['completezza'] ?? _completeness)) item['completezza'] = _completeness;
      if (_destination != (_currentObject?['destinazione'] ?? _destination)) item['destinazione'] = _destination;
      if (_notes.text.trim() != (_currentObject?['note'] ?? '').toString()) item['note'] = _notes.text.trim().isEmpty ? null : _notes.text.trim();
      if (_quantity.text.trim() != (_currentObject?['quantita'] ?? '1').toString()) {
        final q = int.tryParse(_quantity.text.trim());
        if (q == null || q < 1) throw Exception('La quantità deve essere un intero maggiore di zero.');
        item['quantita'] = q;
      }
      if (_producer.text.trim() != (_currentObject?['produttore'] ?? '').toString()) item['produttore'] = _producer.text.trim().isEmpty ? null : _producer.text.trim();
      if (_line.text.trim() != (_currentObject?['anno_uscita'] ?? '').toString()) {
        final year = _line.text.trim().isEmpty ? null : int.tryParse(_line.text.trim());
        if (_line.text.trim().isNotEmpty && year == null) throw Exception('Anno di uscita non valido.');
        item['anno_uscita'] = year;
      }
      if (_family.text.trim() != (_currentObject?['codice_prodotto'] ?? '').toString()) item['codice_prodotto'] = _family.text.trim().isEmpty ? null : _family.text.trim();
      final currentSource = (_currentObject?['fonte_dati_prodotto'] ?? '').toString().trim();
      final proposedSource = (_metadataSourceUrl ?? '').trim();
      if (proposedSource.isNotEmpty && proposedSource != currentSource) {
        item['fonte_dati_prodotto'] = proposedSource;
        item['stato_verifica_dati'] = 'DA_VERIFICARE';
      }
      final currentValueRaw = _currentObject?['valore_oggetto'] ?? _currentObject?['valore'];
      final currentValueText = currentValueRaw == null ? '' : currentValueRaw.toString().trim();
      final proposedValueText = _value.text.trim().replaceAll(',', '.');
      if (proposedValueText != currentValueText.replaceAll(',', '.')) {
        if (proposedValueText.isEmpty) {
          item['valore_oggetto'] = null;
        } else {
          final n = double.tryParse(proposedValueText);
          if (n == null || n < 0) throw Exception('Valore oggetto non valido.');
          item['valore_oggetto'] = n;
        }
      }
      if (item.length == 1) throw Exception('Nessuna modifica rilevata.');
      return {'oggetti': [item]};
    }
    if (widget.apiCode == 'PR-03') {
      if (_loadedObjectId != id || _currentObject == null) {
        throw Exception('Per PR-03 carica prima la scheda completa del codice selezionato.');
      }
      return {'oggetti': [{
        'codice_oggetto': id, 'motivo_chiusura': _closeReason,
        'note': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      }]};
    }
    throw Exception('Procedura di scrittura non riconosciuta.');
  }

  Future<void> _searchPr02Objects() async {
    final query = _search.text.trim();
    if (query.isEmpty) throw Exception('Inserisci una parola, parte della descrizione o un codice.');

    Future<List<Map<String, dynamic>>> searchPhrase(String phrase) async {
      final response = await Supabase.instance.client.schema('collection').rpc(
        'pr_02_ricerca_oggetti',
        params: {'p_cerca': phrase},
      );
      dynamic payload = response;
      if (payload is List && payload.length == 1 && payload.first is Map) {
        payload = payload.first;
      }
      if (payload is! Map) {
        throw Exception('Risposta PR-02 non valida per la ricerca: ' + phrase);
      }
      final raw = payload['oggetti'];
      if (raw is! List) return <Map<String, dynamic>>[];
      return raw.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList();
    }

    // Priorità assoluta alla frase completa. Se il marchio iniziale non è
    // registrato nella descrizione (es. "LEGO 6660 ..."), prova le frasi
    // complete rimuovendo progressivamente le parole iniziali. Appena trova
    // corrispondenze, mostra solo quelle, senza unire risultati generici.
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
    List<Map<String, dynamic>> results = await searchPhrase(query);
    if (results.isEmpty && tokens.length > 1) {
      for (var startAt = 1; startAt < tokens.length; startAt++) {
        final candidate = tokens.skip(startAt).join(' ').trim();
        if (candidate.isEmpty) continue;
        final candidateResults = await searchPhrase(candidate);
        if (candidateResults.isNotEmpty) {
          results = candidateResults;
          break;
        }
      }
    }

    // Solo se nessuna frase completa (né una sua variante senza prefisso)
    // corrisponde, ripiega sulla ricerca per singole parole.
    if (results.isEmpty && tokens.length > 1) {
      final byId = <String, Map<String, dynamic>>{};
      for (final token in tokens) {
        for (final item in await searchPhrase(token)) {
          final id = item['codice_oggetto']?.toString();
          if (id != null) byId.putIfAbsent(id, () => item);
        }
      }
      results = byId.values.toList();
    }

    results.sort((a, b) =>
      (int.tryParse(a['codice_oggetto']?.toString() ?? '') ?? 0)
        .compareTo(int.tryParse(b['codice_oggetto']?.toString() ?? '') ?? 0));
    setState(() {
      _pr02SearchResults = results;
      _pr02SearchCompleted = true;
      _output = results.isEmpty
          ? 'Nessun oggetto disponibile per: ' + query
          : 'Trovati ' + results.length.toString() + ' risultati. Seleziona il record nella finestra di ricerca.';
    });

    if (results.isEmpty || !mounted) return;
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('RISULTATI RICERCA (' + results.length.toString() + ')',
          style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 560,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: results.map((item) => Card(
                  child: ListTile(
                    title: Text((item['codice_oggetto'] ?? '').toString() + ' · ' +
                      (item['descrizione_oggetto'] ?? '').toString()),
                    subtitle: Text('Stato: ' + (item['stato'] ?? 'Non indicato').toString() +
                      ' · Quantità: ' + (item['quantita'] ?? 'Non indicata').toString() +
                      ' · Prezzo unitario: € ' + (item['valore_oggetto'] ?? 'Non indicato').toString()),
                    trailing: const Icon(Icons.chevron_right, color: goldColor),
                    onTap: () => Navigator.of(dialogContext).pop(item),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ANNULLA')),
        ],
      ),
    );
    if (selected != null && mounted) await _selectPr02Object(selected);
  }

  Future<void> _selectPr02Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null) throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text = id.toString();
    _showPr02TechnicalTab = false;
    await _loadObject();
    if (!mounted || _currentObject == null) return;
    final hasMetadata = ['produttore', 'anno_uscita', 'codice_prodotto', 'fonte_dati_prodotto']
        .any((key) => (_currentObject?[key]?.toString().trim().isNotEmpty ?? false));
    if (!hasMetadata) {
      setState(() {
        _metadataResult = 'Metadati assenti. Avvio della ricerca tramite PR-12…';
        _output = _metadataResult;
      });
      await _prepareMetadata();
    } else {
      setState(() => _metadataResult = 'Metadati già presenti. Ricerca automatica PR-12 non necessaria.');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_descriptionFocus);
    });
  }

  Widget _pr02MetadataCard(Map<String, dynamic> object) {
    const imageKeys = [
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    ];
    String valueFor(List<String> keys) {
      for (final key in keys) {
        final value = object[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
      }
      return 'Non disponibile';
    }
    final imageUrl = valueFor(imageKeys);
    final hasImage = imageUrl != 'Non disponibile' &&
        (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'));
    final producer = valueFor(['produttore']);
    final year = valueFor(['anno_uscita', 'data_uscita', 'data_di_uscita']);
    final productCode = valueFor(['codice_prodotto']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('METADATI DEL PRODOTTO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(imageUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 36))
                  : const Icon(Icons.image_outlined, color: Colors.white38, size: 36),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _metadataValue('Produttore', producer),
              const SizedBox(height: 8),
              _metadataValue('Data di uscita', year),
              const SizedBox(height: 8),
              _metadataValue('Codice prodotto', productCode),
            ])),
          ]),
          const SizedBox(height: 8),
          const Text('Metadati informativi, non modificabili da questa scheda.',
            style: TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _metadataValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: goldColor, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
    ],
  );

  Widget _pr02TechnicalCard(Map<String, dynamic> object) {
    const operationalKeys = {
      'codice_oggetto', 'descrizione_oggetto', 'descrizione', 'produttore',
      'anno_uscita', 'data_uscita', 'data_di_uscita', 'codice_prodotto',
      'condizione', 'completezza', 'destinazione', 'quantita',
      'valore_oggetto', 'valore', 'note', 'stato',
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    };
    final technicalEntries = object.entries
        .where((entry) => !operationalKeys.contains(entry.key))
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DATI TECNICI · SOLA LETTURA',
            style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(_metadataResult, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _run(_prepareMetadata),
            icon: const Icon(Icons.travel_explore),
            label: const Text('RICHIAMA METADATI PR-12'),
          ),
          const Divider(height: 24),
          if (technicalEntries.isEmpty)
            const Text('Nessun altro dato tecnico presente nel record.',
              style: TextStyle(color: Colors.white60))
          else
            ...technicalEntries.map((entry) => _detailFieldCard(entry.key, entry.value)),
        ]),
      ),
    );
  }

  Widget _pr02Side({required bool oldValues}) {
    final object = _currentObject ?? <String, dynamic>{};
    final title = oldValues ? 'VECCHI VALORI · SOLA LETTURA' : 'NUOVI VALORI · MODIFICABILI';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (oldValues) ...[
            _detailFieldCard('codice_oggetto', object['codice_oggetto']),
            _detailFieldCard('descrizione_oggetto', object['descrizione_oggetto']),
            _detailFieldCard('produttore', object['produttore']),
            _detailFieldCard('anno_uscita', object['anno_uscita']),
            _detailFieldCard('codice_prodotto', object['codice_prodotto']),
            _detailFieldCard('fonte_dati_prodotto', object['fonte_dati_prodotto']),
            _detailFieldCard('condizione', object['condizione']),
            _detailFieldCard('completezza', object['completezza']),
            _detailFieldCard('destinazione', object['destinazione']),
            _detailFieldCard('quantita', object['quantita']),
            _detailFieldCard('valore_oggetto', object['valore_oggetto']),
            _detailFieldCard('note', object['note']),
            _detailFieldCard('stato', object['stato']),
          ] else ...[
            _field(_description, 'Descrizione oggetto', focusNode: _descriptionFocus),
            _field(_producer, 'Produttore'),
            _field(_line, 'Anno di uscita', type: TextInputType.number),
            _field(_family, 'Codice prodotto'),
            _detailFieldCard('fonte_dati_prodotto', _metadataSourceUrl ?? object['fonte_dati_prodotto']),
            _detailFieldCard('stato_verifica_dati', object['stato_verifica_dati'] ?? 'DA_VERIFICARE'),
            _dropdown('Condizione', _condition, const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], (v) => setState(() => _condition = v!)),
            _dropdown('Completezza', _completeness, const ['SIGILLATO','COMPLETO','INCOMPLETO'], (v) => setState(() => _completeness = v!)),
            _dropdown('Destinazione', _destination, const ['COLLEZIONE','RIVENDITA','ALTRO'], (v) => setState(() => _destination = v!)),
            _field(_quantity, 'Quantità', type: TextInputType.number),
            _field(_value, 'Prezzo unitario (€)', type: const TextInputType.numberWithOptions(decimal: true)),
            _field(_notes, 'Note', lines: 2),
          ],
        ]),
      ),
    );
  }

  Future<void> _loadObject() async {
    final id = int.tryParse(_code.text.trim());
    if (id == null || id <= 0) throw Exception('Inserisci un codice oggetto valido.');
    final response = await _ValoraRuntimeApi.call('consultation', {
      'session_id': _sessionId,
      'consultation_code': 'OBJECT_MASTER',
      'arguments': {'codice_oggetto': id},
    });
    final outer = response['result'];
    dynamic data = outer is Map ? outer['risultato'] : null;
    if (data is List) {
      if (data.isEmpty) throw Exception('Nessuna scheda trovata per il codice $id.');
      data = data.first;
    }
    if (data is! Map) throw Exception('Scheda non disponibile per il codice $id.');
    final m = Map<String, dynamic>.from(data);
    String txt(List<String> keys, [String fallback = '']) {
      for (final k in keys) { if (m[k] != null) return m[k].toString(); }
      return fallback;
    }
    setState(() {
      _currentObject = m;
      _loadedObjectId = id;
      _description.text = txt(['descrizione_oggetto', 'descrizione']);
      _notes.text = txt(['note']);
      _quantity.text = txt(['quantita'], '1');
      _value.text = txt(['valore_oggetto', 'valore']);
      _producer.text = txt(['produttore']);
      _line.text = txt(['anno_uscita']);
      _family.text = txt(['codice_prodotto']);
      final c = txt(['condizione'], _condition);
      if (const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'].contains(c)) _condition = c;
      final cp = txt(['completezza'], _completeness);
      if (const ['SIGILLATO','COMPLETO','INCOMPLETO'].contains(cp)) _completeness = cp;
      final d = txt(['destinazione'], _destination);
      if (const ['COLLEZIONE','RIVENDITA','ALTRO'].contains(d)) _destination = d;
      _output = 'Scheda corrente caricata dal database. I campi sono in sola lettura fino alla conferma della procedura.';
    });
  }

  Future<void> _prepareMetadata() async {
    final description = _description.text.trim();
    if (description.isEmpty) throw Exception('Inserisci almeno la descrizione.');

    setState(() {
      _metadataResult = 'PR-12: ricerca web pubblica in corso…';
      _output = _metadataResult;
    });

    final response = await Supabase.instance.client.functions.invoke(
      'pr-12-web-search-test',
      body: {
        'descrizione': description,
        'categoria': _inferMetadataCategory(description),
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw Exception('PR-12 ha restituito una risposta non valida.');
    }
    final result = Map<String, dynamic>.from(data);
    if (result['ok'] != true) {
      throw Exception((result['error'] ?? 'Ricerca web non riuscita').toString());
    }
    _metadataSearchExecuted = true;
    final rawResults = result['risultati'];
    final candidates = rawResults is List
        ? rawResults.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];

    if (!mounted) return;
    if (candidates.isEmpty) {
      final warning = (result['avviso'] ?? '').toString().trim();
      final errors = result['errori_fonti'] is List
          ? (result['errori_fonti'] as List).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).take(5).join('\n')
          : '';
      final diagnostics = result['diagnostica'] is Map
          ? Map<String, dynamic>.from(result['diagnostica'] as Map)
          : <String, dynamic>{};
      final queryDiagnostics = diagnostics['query'] is List
          ? (diagnostics['query'] as List).whereType<Map>().take(6).map((q) {
              final query = (q['query'] ?? '').toString();
              final count = (q['risultati_grezzi'] ?? 0).toString();
              final error = (q['errore'] ?? '').toString();
              return error.isEmpty ? '• $query: $count risultati grezzi' : '• $query: ERRORE $error';
            }).join('\n')
          : '';
      final details = <String>[
        'PR-12: ricerca completata, zero candidati utilizzabili.',
        if (warning.isNotEmpty) warning,
        'Risultati grezzi: ' + (diagnostics['risultati_grezzi_unici'] ?? 'n/d').toString() +
            '; dopo controllo codice: ' + (diagnostics['dopo_filtro_codice'] ?? 'n/d').toString() +
            '; dopo controllo pertinenza: ' + (diagnostics['dopo_filtro_pertinenza'] ?? 'n/d').toString() + '.',
        if (queryDiagnostics.isNotEmpty) 'Dettaglio query:\n' + queryDiagnostics,
        if (errors.isNotEmpty) 'Errori fonti (primi 5):\n' + errors,
        'Nessun metadato è stato salvato. Puoi riprovare o completare i campi manualmente.',
      ];
      setState(() {
        _metadataResult = details.join('\n\n');
        _output = _metadataResult;
      });
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('PR-12 · RISULTATI RICERCA ONLINE'),
        content: SizedBox(
          width: 650,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Descrizione: $description\n'
                  'Risultati trovati: ${candidates.length}. Seleziona un risultato per esaminarne la fonte. '
                  'La selezione non salva automaticamente metadati.',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const Divider(color: goldColor),
                    itemBuilder: (context, index) {
                      final item = candidates[index];
                      final title = (item['title'] ?? 'Risultato senza titolo').toString();
                      final url = (item['url'] ?? '').toString();
                      final snippet = (item['snippet'] ?? '').toString();
                      final producer = (item['produttore'] ?? '').toString().trim();
                      final productCode = (item['codice_prodotto'] ?? '').toString().trim();
                      final year = (item['anno_uscita'] ?? '').toString().trim();
                      final metadataLines = <String>[
                        if (producer.isNotEmpty) 'Produttore: $producer',
                        if (productCode.isNotEmpty) 'Codice prodotto: $productCode',
                        if (year.isNotEmpty) 'Anno di uscita: $year',
                      ];
                      return ListTile(
                        leading: const Icon(Icons.language, color: goldColor),
                        title: Text(title, style: const TextStyle(color: goldColor)),
                        subtitle: Text(
                          '${metadataLines.isEmpty ? '' : '${metadataLines.join('\n')}\n'}${snippet.isEmpty ? url : snippet}\n$url',
                          maxLines: 7,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        onTap: () => Navigator.of(dialogContext).pop(item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('ANNULLA'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (selected == null) {
      setState(() {
        _metadataResult = 'Ricerca annullata. I dati già inseriti sono rimasti invariati.';
        _output = _metadataResult;
      });
      return;
    }

    final url = (selected['url'] ?? '').toString().trim();
    final title = (selected['title'] ?? '').toString().trim();
    final snippet = (selected['snippet'] ?? '').toString();
    setState(() {
      _metadataResult = 'Fonte selezionata: $title\n$url\n\n'
          '${snippet.isEmpty ? '' : '$snippet\n\n'}'
          'Verifica la pagina selezionata. Produttore, anno di uscita e codice prodotto '
          'non vengono dedotti automaticamente dal titolo di un risultato: inserisci soltanto '
          'i valori confermati consultando la fonte.';
      _output = _metadataResult;
    });

    final sourceAction = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('PR-12 · VERIFICA FONTE'),
        content: SelectableText(
          '$title\n$url\n\n'
          '${(selected['produttore'] ?? '').toString().trim().isEmpty ? '' : 'Produttore: ${selected['produttore']}\n'}'
          '${(selected['codice_prodotto'] ?? '').toString().trim().isEmpty ? '' : 'Codice prodotto: ${selected['codice_prodotto']}\n'}'
          '${(selected['anno_uscita'] ?? '').toString().trim().isEmpty ? '' : 'Anno di uscita: ${selected['anno_uscita']}\n'}'
          '\n$snippet',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('back'),
            child: const Text('TORNA ALLA SCHEDA'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('open'),
            child: const Text('MOSTRA COLLEGAMENTO'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('apply'),
            child: const Text('USA METADATI'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (sourceAction == 'apply') {
      final producer = (selected['produttore'] ?? '').toString().trim();
      final productCode = (selected['codice_prodotto'] ?? '').toString().trim();
      final year = (selected['anno_uscita'] ?? '').toString().trim();
      setState(() {
        // La conferma accetta il titolo del risultato anche se la fonte non
        // restituisce tutti i campi strutturati; i campi assenti restano manuali.
        if (title.isNotEmpty) _description.text = title;
        if (producer.isNotEmpty) _producer.text = producer;
        if (productCode.isNotEmpty) _family.text = productCode;
        if (year.isNotEmpty && int.tryParse(year) != null) _line.text = year;
        _metadataSourceUrl = url.isNotEmpty ? url : null;
        _metadataResult = (producer.isEmpty && productCode.isEmpty && year.isEmpty)
            ? 'Titolo e fonte applicati su tua conferma. La fonte non ha restituito metadati strutturati: completa i campi manualmente. Stato: DA_VERIFICARE. Nessun dato è stato salvato nel database.'
            : 'Metadati applicati alla maschera PR-01 su tua conferma. Descrizione aggiornata al titolo selezionato. Fonte registrata; stato: DA_VERIFICARE. Nessun dato è stato salvato nel database.';
        _output = _metadataResult;
      });
    } else if (sourceAction == 'open') {
      // La selezione mostra l'URL senza scrivere dati nel database.
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: cardColor,
          title: const Text('Apri la fonte nel browser'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CHIUDI'),
            ),
          ],
        ),
      );
    }
  }

  String _inferMetadataCategory(String description) {
    final value = description.toLowerCase();
    if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(value)) {
      return 'LEGO';
    }
    if (RegExp(r'fumett|comic|manga|panini|salda|bonelli').hasMatch(value)) {
      return 'FUMETTI';
    }
    if (RegExp(r'myth cloth|saint seiya|bandai|gundam|dragon ball|action figure|statua').hasMatch(value)) {
      return 'ACTION_FIGURE';
    }
    return 'COLLEZIONABILE';
  }

  Future<void> _consult() async {
    if (widget.apiCode == 'EXPLORE_RECORDS') {
      final id = int.tryParse(_code.text.trim());
      if (id == null || id <= 0) throw Exception('Inserisci il codice dell’oggetto di cui vuoi leggere lo storico.');
      final response = await _ValoraRuntimeApi.call('object_history', {
        'session_id': _sessionId,
        'codice_oggetto': id,
      });
      final result = response['result'];
      if (result is! Map) throw Exception('Risposta dello storico non valida.');
      final history = Map<String, dynamic>.from(result);
      final object = history['scheda_corrente'];
      setState(() {
        _currentObject = object is Map ? Map<String, dynamic>.from(object) : null;
        final events = history['eventi_storici'];
        _rows = events is List ? events : [];
        _output = 'Storico in sola lettura · ${history['numero_eventi'] ?? _rows.length} eventi.';
      });
      return;
    }

    final args = widget.apiCode == 'OBJECT_MASTER'
      ? {'codice_oggetto': int.tryParse(_code.text.trim())}
      : {'cerca': _search.text.trim(), 'limite': 100, 'offset': 0};
    final response = await _ValoraRuntimeApi.call('consultation', {
      'session_id': _sessionId, 'consultation_code': widget.apiCode, 'arguments': args,
    });
    final result = response['result'];
    dynamic data = result is Map ? result['risultato'] : result;
    final list = data is List ? data : data == null ? <dynamic>[] : <dynamic>[data];
    setState(() {
      _rows = list;
      _output = list.isEmpty ? 'Nessun risultato.' : 'Risultati: ${list.length}.';
      _currentObject = widget.apiCode == 'OBJECT_MASTER' && list.isNotEmpty && list.first is Map
        ? Map<String, dynamic>.from(list.first as Map) : null;
    });
  }

  String _pretty(dynamic data) {
    try { return const JsonEncoder.withIndent('  ').convert(data); }
    catch (_) { return data?.toString() ?? ''; }
  }

  String _valueFor(Map<String, dynamic> m, List<String> keys, [String fallback = 'Non indicato']) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  String _italianFieldLabel(String key) {
    const labels = <String, String>{
      'id': 'ID record',
      'codice_oggetto': 'Codice oggetto',
      'descrizione_oggetto': 'Descrizione oggetto',
      'descrizione': 'Descrizione',
      'nome': 'Nome',
      'produttore': 'Produttore',
      'linea': 'Linea',
      'famiglia': 'Famiglia / categoria',
      'categoria': 'Categoria',
      'condizione': 'Condizione',
      'completezza': 'Completezza',
      'destinazione': 'Destinazione',
      'quantita': 'Quantità',
      'note': 'Note',
      'valore_oggetto': 'Valore oggetto (€)',
      'valore': 'Valore (€)',
      'valore_stimato': 'Valore stimato (€)',
      'stato': 'Stato',
      'stato_oggetto': 'Stato oggetto',
      'url_immagine': 'Immagine',
      'immagine_url': 'Immagine',
      'foto_url': 'Immagine',
      'image_url': 'Immagine',
      'data_inserimento': 'Data inserimento',
      'data_creazione': 'Data creazione',
      'data_modifica': 'Data ultima modifica',
      'created_at': 'Data creazione',
      'updated_at': 'Data ultima modifica',
      'data_evento': 'Data evento',
      'tipo_evento': 'Tipo evento',
      'motivo_chiusura': 'Motivo chiusura',
      'prezzo_acquisto': 'Prezzo di acquisto (€)',
      'prezzo_vendita': 'Prezzo di vendita (€)',
      'piattaforma': 'Piattaforma',
      'fonte': 'Fonte',
    };
    if (labels.containsKey(key)) return labels[key]!;
    final normalized = key
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return 'Campo';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _displayFieldValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return 'Non indicato';
    if (value is bool) return value ? 'Sì' : 'No';
    final text = value.toString().trim();
    if (text.toLowerCase() == 'true') return 'Sì';
    if (text.toLowerCase() == 'false') return 'No';
    return text;
  }

  Widget _detailFieldCard(String key, dynamic value) {
    final label = _italianFieldLabel(key);
    final text = _displayFieldValue(value);
    final isUrl = text.startsWith('https://') || text.startsWith('http://');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(
              color: goldColor, fontSize: 13, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 5),
            SelectableText(text, style: const TextStyle(fontSize: 15)),
            if (isUrl) ...[
              const SizedBox(height: 4),
              const Text('Fonte esterna', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _masterDetails(Map<String, dynamic> object) {
    const imageKeys = {
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    };
    const summaryKeys = {
      'id', 'codice_oggetto', 'descrizione_oggetto', 'descrizione', 'nome',
      'destinazione', 'condizione', 'stato', 'stato_oggetto',
      'valore_oggetto', 'valore', 'valore_stimato',
    };
    const identityKeys = {
      'produttore', 'linea', 'famiglia', 'categoria', 'anno_uscita',
      'codice_prodotto', 'codice', 'serie', 'licenza', 'franchise',
    };
    const conditionKeys = {
      'completezza', 'quantita', 'note', 'data_inserimento',
      'data_creazione', 'data_modifica', 'created_at', 'updated_at',
      'fonte', 'fonte_dati_prodotto', 'url_fonte', 'fonte_dati',
    };
    const valueKeys = {
      'valore_mercato', 'valore_mercato_eur', 'valore_stimato',
      'valuta_valore', 'valuta', 'prezzo_acquisto', 'prezzo_vendita',
      'valore_oggetto', 'valore',
    };
    const technicalKeys = {
      'collegato_vendita', 'modificabile_pr02', 'motivo_esclusione',
      'collegato_acquisto', 'collegato_inserzione', 'collegato_piattaforma',
      'stato_verifica_dati', 'id', 'created_at', 'updated_at',
      'record_id', 'deleted_at', 'versione_record',
    };

    final entries = object.entries.where((e) =>
      !imageKeys.contains(e.key) && !summaryKeys.contains(e.key)
    ).toList();
    List<MapEntry<String, dynamic>> group(Set<String> keys) =>
      entries.where((e) => keys.contains(e.key)).toList();
    final identity = group(identityKeys);
    final condition = group(conditionKeys).where((e) => !technicalKeys.contains(e.key)).toList();
    final values = group(valueKeys);
    final technical = entries.where((e) => technicalKeys.contains(e.key)).toList();
    final assigned = <String>{
      ...identity.map((e) => e.key),
      ...condition.map((e) => e.key),
      ...values.map((e) => e.key),
      ...technical.map((e) => e.key),
    };
    final other = entries.where((e) => !assigned.contains(e.key)).toList();

    Widget section(String title, IconData icon, List<MapEntry<String, dynamic>> fields) {
      if (fields.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: goldColor, size: 19),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(
                color: goldColor, fontSize: 16, fontWeight: FontWeight.bold,
              ))),
            ]),
            const SizedBox(height: 8),
            ...fields.map((e) => _detailFieldCard(e.key, e.value)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('IDENTIFICAZIONE', Icons.qr_code_2, identity),
        section('GESTIONE OGGETTO', Icons.inventory_2_outlined, condition),
        section('VALORI E VALUTAZIONE', Icons.euro_outlined, values),
        section('ALTRI DETTAGLI', Icons.info_outline, other),
        if (technical.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 14),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                leading: const Icon(Icons.settings_outlined, color: goldColor),
                title: const Text('DETTAGLI TECNICI', style: TextStyle(
                  color: goldColor, fontWeight: FontWeight.bold, fontSize: 15,
                )),
                subtitle: Text('${technical.length} campi di sistema',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: technical.map((e) => _detailFieldCard(e.key, e.value)).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {int lines = 1, TextInputType type = TextInputType.text, FocusNode? focusNode}) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
      controller: c, focusNode: focusNode, maxLines: lines, keyboardType: type,
      decoration: InputDecoration(labelText: label),
    ));

  Widget _dropdown(String label, String current, List<String> options, ValueChanged<String?> onChanged) =>
    Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(
      value: current, decoration: InputDecoration(labelText: label),
      items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: onChanged,
    ));

  Widget _objectCard(Map<String, dynamic> item, {VoidCallback? onTap}) {
    final code = _valueFor(item, ['codice_oggetto', 'id'], 'Codice n/d');
    final desc = _valueFor(item, ['descrizione_oggetto', 'descrizione', 'nome'], 'Oggetto senza descrizione');
    final imageUrl = _valueFor(item, [
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    ], '');
    final destination = _valueFor(item, ['destinazione'], 'Non indicata');
    final condition = _valueFor(item, ['condizione'], 'Non indicata');
    final state = _valueFor(item, ['stato', 'stato_oggetto'], 'Non indicato');
    final value = _valueFor(item, ['valore_oggetto', 'valore', 'valore_stimato'], 'Non indicato');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.startsWith('http')
                ? Image.network(imageUrl, width: 88, height: 88, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CODICE $code', style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 6),
              Text('Destinazione: $destination'),
              Text('Condizione: $condition'),
              Text('Stato: $state'),
              Text('Valore: $value'),
            ])),
            if (onTap != null) const Icon(Icons.chevron_right, color: goldColor),
          ]),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 88, height: 88, color: Colors.white10,
    child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38, size: 30),
  );

  Widget _historyCard(Map<String, dynamic> event) {
    final date = _valueFor(event, ['data_evento', 'data', 'created_at'], 'Data non indicata');
    final type = _valueFor(event, ['tipo_evento', 'tipo', 'azione'], 'Evento');
    final detail = _valueFor(event, ['descrizione', 'dettaglio', 'note', 'motivazione'], 'Nessun dettaglio registrato');
    return Card(child: ListTile(
      leading: const Icon(Icons.history, color: goldColor),
      title: Text(type),
      subtitle: Text('$date\n$detail'),
      isThreeLine: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.apiCode;
    final isAvailableList = code == 'OBJECTS_AVAILABLE';
    final isHistory = code == 'EXPLORE_RECORDS';
    final isMaster = code == 'OBJECT_MASTER';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('COLLECTION by VALORA · TEST\nUtente: ${Supabase.instance.client.auth.currentUser?.email ?? 'sessione autenticata'}\n${_lockHeld ? 'Blocco archivio: ATTIVO' : 'Blocco archivio: non acquisito'}',
            style: const TextStyle(color: goldColor)),
        )),
        if (_isWrite && code == 'PR-01') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('IDENTIFICAZIONE OGGETTO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Codice oggetto: assegnato automaticamente dal database al salvataggio.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                _field(_description, 'Descrizione oggetto *', lines: 2, focusNode: _descriptionFocus),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.travel_explore, color: goldColor),
                  SizedBox(width: 8),
                  Expanded(child: Text('RICERCA METADATI', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 8),
                SelectableText(_metadataResult, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                const Text('Fonte, titolo e metadati restituiti dalla ricerca vengono mostrati insieme. Verifica le informazioni prima di applicarle.', style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 10),
                _field(_producer, 'Produttore (facoltativo)'),
                _field(_line, 'Anno di uscita (facoltativo)', type: TextInputType.number),
                _field(_family, 'Codice prodotto (facoltativo)'),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('DATI INSERIBILI', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _dropdown('Condizione *', _condition, const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], (v) => setState(() => _condition = v!)),
                _dropdown('Completezza *', _completeness, const ['SIGILLATO','COMPLETO','INCOMPLETO'], (v) => setState(() => _completeness = v!)),
                _dropdown('Destinazione *', _destination, const ['COLLEZIONE','RIVENDITA','ALTRO'], (v) => setState(() => _destination = v!)),
                _field(_quantity, 'Quantità', type: TextInputType.number),
                _field(_unitPrice, 'Prezzo unitario (€)', type: const TextInputType.numberWithOptions(decimal: true)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _totalValue,
                    readOnly: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Valore totale calcolato (€)',
                      helperText: 'Quantità × prezzo unitario. Il totale viene registrato in valore_oggetto.',
                    ),
                  ),
                ),
                _field(_notes, 'Note', lines: 2),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('VALORI DETERMINATI DA ALTRE PROCEDURE', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Valore di mercato attuale (€)', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                TextField(
                  controller: _marketValue,
                  readOnly: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: '0,00',
                    helperText: 'Valore restituito dalla procedura di valutazione. 0,00 finché non è disponibile una stima.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('La stima verrà valorizzata dalla procedura di valutazione del mercato, non inserita manualmente.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
            ),
          ),
        ],
        if (_isWrite && code == 'PR-02') ...[
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RICERCA OGGETTO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _search,
                focusNode: _searchFocusNode,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _run(_searchPr02Objects),
                decoration: InputDecoration(
                  labelText: 'Parola, parte della descrizione o codice',
                  hintText: 'Es. Batman',
                  suffixIcon: IconButton(
                    tooltip: 'Cerca',
                    onPressed: _loading ? null : () => _run(_searchPr02Objects),
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('La ricerca trova i record contenenti il termine, senza distinzione tra maiuscole e minuscole.', style: TextStyle(color: Colors.white60, fontSize: 12)),
              if (_pr02SearchCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _pr02SearchResults.isEmpty
                      ? 'Nessun risultato trovato.'
                      : 'Risultati mostrati nella finestra sovrapposta: ' + _pr02SearchResults.length.toString(),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
            ]),
          )),
          if (_currentObject != null) ...[
            const SizedBox(height: 12),
            _pr02MetadataCard(_currentObject!),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: !_showPr02TechnicalTab ? goldColor : cardColor,
                        foregroundColor: !_showPr02TechnicalTab ? Colors.black : Colors.white,
                      ),
                      onPressed: () => setState(() => _showPr02TechnicalTab = false),
                      child: const Text('SCHEDA OGGETTO'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _showPr02TechnicalTab ? goldColor : cardColor,
                        foregroundColor: _showPr02TechnicalTab ? Colors.black : Colors.white,
                      ),
                      onPressed: () => setState(() => _showPr02TechnicalTab = true),
                      child: const Text('DATI TECNICI'),
                    ),
                  ),
                ]),
              ),
            ),
            if (!_showPr02TechnicalTab)
              LayoutBuilder(builder: (context, constraints) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _pr02Side(oldValues: true)),
                  const SizedBox(width: 8),
                  Expanded(child: _pr02Side(oldValues: false)),
                ]);
              })
            else
              _pr02TechnicalCard(_currentObject!),
          ],
        ],
        if (_isWrite && code == 'PR-03') ...[
          _field(_code, 'Codice oggetto *', type: TextInputType.number),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _run(_loadObject),
            icon: const Icon(Icons.download_outlined), label: const Text('CARICA SCHEDA COMPLETA DAL DATABASE')),
          if (code == 'PR-03') ...[
            _dropdown('Motivo chiusura', _closeReason, const ['SMARRITO','DISTRUTTO','DATO VIA'], (v) => setState(() => _closeReason = v!)),
            _field(_notes, 'Note', lines: 2),
          ],
        ],
        if (!_isWrite && (isHistory || isMaster))
          _field(_code, isHistory ? 'Codice oggetto *' : 'Codice oggetto', type: TextInputType.number),
        if (!_isWrite && isAvailableList)
          const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Mostra tutti gli oggetti con stato DISPONIBILE, senza obbligo di ricerca.', style: TextStyle(color: Colors.white70))),
        if (!_isWrite && !isMaster && !isHistory && !isAvailableList)
          _field(_search, 'Cerca'),
        if (_isWrite && code == 'PR-01') ...[
          FilledButton.icon(
            onPressed: _loading ? null : () => _run(_confirmAndSaveNewObject),
            icon: const Icon(Icons.save_outlined),
            label: Text(_loading ? 'SALVATAGGIO IN CORSO…' : 'CONFERMA E SALVA OGGETTO'),
          ),
          const SizedBox(height: 8),
          if (_lockHeld) OutlinedButton.icon(onPressed: _loading ? null : () => _run(_releaseLock),
            icon: const Icon(Icons.lock_open), label: const Text('RILASCIA BLOCCO ARCHIVIO')),
        ] else if (_isWrite && code == 'PR-02') ...[
          FilledButton.icon(
            onPressed: _loading || _currentObject == null ? null : () => _run(_confirmPr02Changes),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('CONFERMA DATI'),
          ),
        ] else if (_isWrite) ...[
          FilledButton.icon(onPressed: _loading ? null : () => _run(_preview),
            icon: const Icon(Icons.fact_check_outlined), label: const Text('1 · CONTROLLA DATI E ANTEPRIMA')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _loading || _lastResult == null ? null : () => _run(_confirmData),
            icon: const Icon(Icons.verified_outlined), label: const Text('2 · CONFERMO I DATI')),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _loading || !_dataConfirmed || !_finalReady ? null : () => _run(_save),
            icon: const Icon(Icons.save_outlined), label: const Text('3 · CONFERMA DEFINITIVA E SALVA')),
          const SizedBox(height: 8),
          if (_lockHeld) OutlinedButton.icon(onPressed: _loading ? null : () => _run(_releaseLock),
            icon: const Icon(Icons.lock_open), label: const Text('RILASCIA BLOCCO ARCHIVIO')),
        ] else
          FilledButton.icon(onPressed: _loading ? null : () => _run(_consult),
            icon: const Icon(Icons.search),
            label: Text(_loading ? 'RICERCA...' : isAvailableList
              ? 'VISUALIZZA ELENCO OGGETTI DISPONIBILI'
              : isHistory ? 'VISUALIZZA STORICO OGGETTO'
              : isMaster ? 'CARICA SCHEDA COMPLETA' : 'ESEGUI CONSULTAZIONE')),
        if (_currentObject != null && code != 'PR-02') ...[
          const SizedBox(height: 16),
          const Text('SCHEDA OGGETTO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 18)),
          _objectCard(_currentObject!),
          if (isMaster)
            _masterDetails(_currentObject!)
          else
            ..._currentObject!.entries
                .where((e) => !const {
                      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
                      'immagine_principale', 'url_foto', 'foto', 'immagine',
                      'image', 'imageUrl', 'photo_url', 'main_image_url',
                    }.contains(e.key))
                .map((e) => _detailFieldCard(e.key, e.value)),
        ],
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(isHistory ? 'CRONOLOGIA EVENTI (${_rows.length})' : 'RISULTATI (${_rows.length})',
            style: const TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ..._rows.map((r) {
            if (r is! Map) return Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(r.toString())));
            final item = Map<String, dynamic>.from(r);
            if (isHistory) return _historyCard(item);
            return _objectCard(item, onTap: isAvailableList
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ObjectRuntimePage(
                      title: 'PR-11 · Visualizza scheda',
                      apiCode: 'OBJECT_MASTER',
                      initialObjectCode: int.tryParse(item['codice_oggetto']?.toString() ?? item['id']?.toString() ?? ''),
                    )
                  )).then((_) {})
              : null);
          }),
        ],
        if (code != 'PR-01' && code != 'PR-02') ...[
          const SizedBox(height: 16),
          const Text('ESITO RUNTIME', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
            color: cardColor, borderRadius: BorderRadius.circular(12)),
            child: SelectableText(_output, style: const TextStyle(fontSize: 13))),
        ],
      ]),
    );
  }

  Future<void> _confirmAndSaveNewObject() async {
    if (_description.text.trim().isEmpty) throw Exception('La descrizione oggetto è obbligatoria.');
    final yearText = _line.text.trim();
    if (yearText.isNotEmpty) {
      final year = int.tryParse(yearText);
      if (year == null || year < 1000 || year > DateTime.now().year + 2) {
        throw Exception('Anno di uscita non valido. Inserisci un anno plausibile oppure lascia il campo vuoto.');
      }
    }
    final qty = int.tryParse(_quantity.text.trim());
    if (qty == null || qty < 1) throw Exception('La quantità deve essere un numero intero maggiore di zero.');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma inserimento oggetto'),
        content: SingleChildScrollView(child: Text(
          'Descrizione: ${_description.text.trim()}\n'
          'Produttore: ${_producer.text.trim()}\n'
          'Linea / serie: ${_line.text.trim()}\n'
          'Famiglia / categoria: ${_family.text.trim()}\n'
          'Condizione: $_condition\n'
          'Completezza: $_completeness\n'
          'Destinazione: $_destination\n'
          'Quantità: ${_quantity.text.trim()}\n'
          'Prezzo unitario: ${_unitPrice.text.trim().isEmpty ? 'Non indicato' : _unitPrice.text.trim() + ' €'}\n'
          'Valore totale: ${_totalValue.text.trim().isEmpty ? 'Non indicato' : _totalValue.text.trim() + ' €'}\n'
          'Valore di mercato stimato: ${_marketValue.text.trim().isEmpty ? 'Non indicato' : _marketValue.text.trim() + ' €'}\n'
          'Note: ${_notes.text.trim().isEmpty ? 'Nessuna' : _notes.text.trim()}\n\n'
          'Confermi il salvataggio di questo oggetto nel database TEST?'
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('CONFERMA E SALVA')),
        ],
      ),
    );
    if (confirmed != true) {
      setState(() => _output = 'Salvataggio annullato. Nessun oggetto salvato.');
      return;
    }

    await _preview();
    await _confirmData();
    await _save();

    if (!mounted) return;
    final addAnother = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Oggetto salvato'),
        content: const Text('Vuoi inserire un altro oggetto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('NO, TORNA AL MENU')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('SÌ, NUOVO OGGETTO')),
        ],
      ),
    );
    if (!mounted) return;
    if (addAnother == true) {
      setState(() {
        _description.clear();
        _producer.clear();
        _line.clear();
        _family.clear();
        _notes.clear();
        _quantity.text = '1';
        _unitPrice.clear();
        _totalValue.clear();
        _value.clear();
        _marketValue.text = '0.00';
        _condition = 'USATO';
        _completeness = 'COMPLETO';
        _destination = 'COLLEZIONE';
        _lastMetadataQuery = '';
        _metadataResult = 'Inserisci la descrizione e poi esci dal campo per preparare la ricerca metadati.';
        _output = 'Pronto per il prossimo oggetto.';
      });
      // Aspetta che il dialogo sia chiuso e il modulo sia ridisegnato prima di
      // riportare il cursore sul primo campo utile del nuovo oggetto.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_descriptionFocus);
      });
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _preview() async {
    if (widget.apiCode == 'PR-02' && _currentObject == null) {
      await _searchPr02Objects();
      return;
    }
    if ((widget.apiCode == 'PR-02' || widget.apiCode == 'PR-03') &&
        _loadedObjectId != int.tryParse(_code.text.trim())) {
      throw Exception('Per questa procedura carica prima la scheda completa del codice selezionato.');
    }
    if (!_lockHeld) await _acquireLock();
    try {
      final result = await _ValoraRuntimeApi.procedure(
        widget.apiCode, 'preview', _payload(), sessionId: _sessionId,
      );
      setState(() {
        _lastResult = result;
        _dataConfirmed = false;
        _finalReady = false;
        _output = _pretty(result);
      });
    } catch (_) {
      if (_lockHeld) {
        try {
          final response = await _ValoraRuntimeApi.call(
            'release_lock', {'session_id': _sessionId},
          );
          final result = response['result'];
          if (result is Map && result['rilasciato'] == true && mounted) {
            setState(() => _lockHeld = false);
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> _confirmData() async {
    if (_lastResult == null) throw Exception('Esegui prima l’anteprima.');
    final payload = _payload()
      ..['dati_confermati'] = true
      ..['altra_operazione'] = false
      ..['conferma_finale'] = false;
    final result = await _ValoraRuntimeApi.procedure(widget.apiCode, 'review', payload, sessionId: _sessionId);
    setState(() { _lastResult = result; _dataConfirmed = true; _finalReady = true; _output = _pretty(result); });
  }

  Map<String, dynamic> _pr02ConfirmationPayload() {
    final payload = _payload();
    final rows = payload['oggetti'];
    if (rows is! List || rows.isEmpty || rows.first is! Map) {
      throw Exception('Non ci sono modifiche valide da confermare.');
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }

  String _pr02ConfirmationText(Map<String, dynamic> item) {
    final labels = <String, String>{
      'codice_oggetto': 'Codice oggetto',
      'descrizione': 'Descrizione oggetto',
      'produttore': 'Produttore',
      'anno_uscita': 'Anno di uscita',
      'codice_prodotto': 'Codice prodotto',
      'fonte_dati_prodotto': 'Fonte dati',
      'stato_verifica_dati': 'Stato verifica dati',
      'condizione': 'Condizione',
      'completezza': 'Completezza',
      'destinazione': 'Destinazione',
      'quantita': 'Quantità',
      'valore_oggetto': 'Valore oggetto (€)',
      'note': 'Note',
    };
    return item.entries.map((e) =>
      '${labels[e.key] ?? _italianFieldLabel(e.key)}: ${_displayFieldValue(e.value)}'
    ).join('\n');
  }

  Future<void> _confirmPr02Changes() async {
    if (_currentObject == null || _loadedObjectId == null) {
      throw Exception('Seleziona prima un oggetto dalla ricerca.');
    }

    // Prepara e valida i dati, ma non scrive ancora nel database.
    final item = _pr02ConfirmationPayload();
    await _preview();
    await _confirmData();

    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma modifiche oggetto'),
        content: SingleChildScrollView(
          child: SelectableText(_pr02ConfirmationText(item)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('CONFERMA DATI'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) {
      if (_lockHeld) await _releaseLock();
      if (mounted) setState(() { _dataConfirmed = false; _finalReady = false; });
      return;
    }

    _pr02PendingChanges.removeWhere((e) =>
      e['codice_oggetto']?.toString() == item['codice_oggetto']?.toString());
    _pr02PendingChanges.add(Map<String, dynamic>.from(item));

    if (_lockHeld) await _releaseLock();
    if (!mounted) return;

    final another = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifica confermata'),
        content: const Text('Vuoi modificare un altro oggetto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('NO, SALVA E TERMINA'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('SÌ, MODIFICA UN ALTRO'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (another == true) {
      setState(() {
        _search.clear();
        _code.clear();
        _description.clear();
        _notes.clear();
        _producer.clear();
        _line.clear();
        _family.clear();
        _value.clear();
        _currentObject = null;
        _loadedObjectId = null;
        _pr02SearchResults = [];
        _pr02SearchCompleted = false;
        _metadataSourceUrl = null;
        _metadataSearchExecuted = false;
        _lastMetadataQuery = '';
        _metadataResult = 'Inserisci una parola o parte della descrizione per iniziare.';
        _lastResult = null;
        _dataConfirmed = false;
        _finalReady = false;
        _showPr02TechnicalTab = false;
        _output = 'PR-02 pronta per una nuova ricerca.';
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
      });
      return;
    }

    if (_pr02PendingChanges.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    await _savePr02PendingChanges();
  }

  Future<void> _savePr02PendingChanges() async {
    final pending = _pr02PendingChanges
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    for (final item in pending) {
      final payload = <String, dynamic>{
        'oggetti': [Map<String, dynamic>.from(item)],
        'dati_confermati': true,
        'altra_operazione': false,
        'conferma_finale': true,
      };
      await _acquireLock();
      try {
        final preview = await _ValoraRuntimeApi.procedure(
          'PR-02', 'preview', payload, sessionId: _sessionId);
        if (preview['errore'] != null) {
          throw Exception(preview['errore'].toString());
        }
        await _ValoraRuntimeApi.procedure(
          'PR-02', 'review', payload, sessionId: _sessionId);
        final result = await _ValoraRuntimeApi.procedure(
          'PR-02', 'save', payload, sessionId: _sessionId, requestId: _uuid.v4());
        if (result['scrittura_eseguita'] != true) {
          throw Exception('Salvataggio non confermato per oggetto ${item['codice_oggetto']}.');
        }
        if (result['blocco_rilasciato_automaticamente'] == true) {
          setState(() => _lockHeld = false);
        } else {
          throw Exception('Salvataggio eseguito ma rilascio del blocco non confermato.');
        }
      } catch (_) {
        if (_lockHeld) {
          try { await _releaseLock(); } catch (_) {}
        }
        rethrow;
      }
    }
    _pr02PendingChanges.clear();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (!_dataConfirmed || !_finalReady) throw Exception('Conferma i dati prima del salvataggio.');
    final payload = _payload()
      ..['dati_confermati'] = true
      ..['altra_operazione'] = false
      ..['conferma_finale'] = true;
    final result = await _ValoraRuntimeApi.procedure(
      widget.apiCode, 'save', payload, sessionId: _sessionId, requestId: _uuid.v4());
    setState(() { _lastResult = result; _output = _pretty(result); _dataConfirmed = false; _finalReady = false; });
    if (result['scrittura_eseguita'] != true) {
      throw Exception('Scrittura non confermata dal runtime: blocco mantenuto per sicurezza.');
    }
    if (result['blocco_rilasciato_automaticamente'] == true) {
      setState(() => _lockHeld = false);
    } else {
      throw Exception('Scrittura verificata ma il runtime non ha confermato il rilascio automatico del blocco.');
    }
    if (widget.apiCode == 'PR-01') {
      _description.clear(); _producer.clear(); _line.clear(); _family.clear();
      _notes.clear(); _quantity.text = '1'; _unitPrice.clear(); _totalValue.clear();
    }
  }
}
