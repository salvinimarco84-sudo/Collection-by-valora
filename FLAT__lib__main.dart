import 'dart:async';
import 'dart:convert';
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
        home: const AuthenticationGate(),
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
                    builder: (_) => ObjectRuntimePage(title: procedure.title, apiCode: procedure.apiCode!)))
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
  final _value = TextEditingController();
  final _producer = TextEditingController();
  final _line = TextEditingController();
  final _family = TextEditingController();

  final String _sessionId = _uuid.v4();
  final FocusNode _descriptionFocus = FocusNode();
  String _lastMetadataQuery = '';
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

  bool get _isWrite => const {'PR-01', 'PR-02', 'PR-03'}.contains(widget.apiCode);

  @override
  void initState() {
    super.initState();
    if (widget.apiCode == 'PR-01') {
      _descriptionFocus.addListener(_onDescriptionFocusChanged);
    }
    if (widget.initialObjectCode != null) _code.text = widget.initialObjectCode.toString();
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
    _descriptionFocus.removeListener(_onDescriptionFocusChanged);
    _descriptionFocus.dispose();
    _search.dispose(); _description.dispose(); _notes.dispose(); _code.dispose();
    _quantity.dispose(); _value.dispose(); _producer.dispose(); _line.dispose(); _family.dispose();
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

  Map<String, dynamic> _payload() {
    final id = int.tryParse(_code.text.trim());
    if (widget.apiCode == 'PR-01') {
      if (_description.text.trim().isEmpty) throw Exception('La descrizione è obbligatoria.');
      final q = int.tryParse(_quantity.text.trim());
      if (q == null || q <= 0) throw Exception('La quantità deve essere un intero positivo.');
      return {'oggetti': [{
        'descrizione': _description.text.trim(),
        'condizione': _condition, 'completezza': _completeness,
        'destinazione': _destination, 'quantita': q,
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
    final id = int.tryParse(_code.text.trim());
    final args = {
      'descrizione': _description.text.trim(),
      'produttore': _producer.text.trim(),
      'linea': _line.text.trim(),
      'famiglia': _family.text.trim(),
    };
    if ((args['descrizione'] as String).isEmpty) throw Exception('Inserisci almeno la descrizione.');
    final response = await _ValoraRuntimeApi.call('metadata_prepare', {
      'session_id': _sessionId, 'codice_oggetto': id, 'metadata': args,
    });
    final result = response['result'];
    final prettyResult = _pretty(result ?? response);
    setState(() { _metadataResult = prettyResult; _output = prettyResult; });
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
    return value.toString();
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
          _field(_description, 'Descrizione oggetto *', lines: 2, focusNode: _descriptionFocus),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.travel_explore, color: goldColor),
                  SizedBox(width: 8),
                  Expanded(child: Text('DATI OTTENUTI DALLA RICERCA METADATI',
                    style: TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 8),
                SelectableText(_metadataResult, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                const Text('La ricerca parte quando esci dal campo descrizione. I risultati non verificati non vengono considerati dati certi.',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          const Text('DATI OBBLIGATORI E COMPLETAMENTO SCHEDA',
            style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _field(_producer, 'Produttore *'),
          _field(_line, 'Linea / serie *'),
          _field(_family, 'Famiglia / categoria *'),
          _dropdown('Condizione *', _condition, const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], (v) => setState(() => _condition = v!)),
          _dropdown('Completezza *', _completeness, const ['SIGILLATO','COMPLETO','INCOMPLETO'], (v) => setState(() => _completeness = v!)),
          _dropdown('Destinazione *', _destination, const ['COLLEZIONE','RIVENDITA','ALTRO'], (v) => setState(() => _destination = v!)),
          _field(_quantity, 'Quantità', type: TextInputType.number),
          _field(_notes, 'Note', lines: 2),
        ],
        if (_isWrite && (code == 'PR-02' || code == 'PR-03')) ...[
          _field(_code, 'Codice oggetto *', type: TextInputType.number),
          if (code == 'PR-02' || code == 'PR-03') OutlinedButton.icon(
            onPressed: _loading ? null : () => _run(_loadObject),
            icon: const Icon(Icons.download_outlined), label: const Text('CARICA SCHEDA COMPLETA DAL DATABASE')),
          if (code == 'PR-02') ...[
            _field(_description, 'Descrizione'),
            _dropdown('Condizione', _condition, const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], (v) => setState(() => _condition = v!)),
            _dropdown('Completezza', _completeness, const ['SIGILLATO','COMPLETO','INCOMPLETO'], (v) => setState(() => _completeness = v!)),
            _dropdown('Destinazione', _destination, const ['COLLEZIONE','RIVENDITA','ALTRO'], (v) => setState(() => _destination = v!)),
            _field(_value, 'Valore oggetto (€)', type: const TextInputType.numberWithOptions(decimal: true)),
            _field(_notes, 'Note', lines: 2),
          ],
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
        if (_currentObject != null) ...[
          const SizedBox(height: 16),
          const Text('SCHEDA OGGETTO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 18)),
          _objectCard(_currentObject!),
          ..._currentObject!.entries
              .where((e) => !const {
                    'url_immagine', 'immagine_url', 'foto_url', 'image_url',
                    'immagine_principale', 'url_foto', 'foto', 'immagine',
                    'image', 'imageUrl', 'photo_url', 'main_image_url',
                  }.contains(e.key))
              .map((e) => Card(
                    child: ListTile(
                      title: Text(_italianFieldLabel(e.key)),
                      subtitle: Text(_displayFieldValue(e.value)),
                    ),
                  )),
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
        const SizedBox(height: 16),
        const Text('ESITO RUNTIME', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
          color: cardColor, borderRadius: BorderRadius.circular(12)),
          child: SelectableText(_output, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Future<void> _confirmAndSaveNewObject() async {
    if (_description.text.trim().isEmpty) throw Exception('La descrizione oggetto è obbligatoria.');
    if (_producer.text.trim().isEmpty) throw Exception('Il produttore è obbligatorio.');
    if (_line.text.trim().isEmpty) throw Exception('La linea / serie è obbligatoria.');
    if (_family.text.trim().isEmpty) throw Exception('La famiglia / categoria è obbligatoria.');
    final qty = int.tryParse(_quantity.text.trim());
    if (qty == null || qty < 1) throw Exception('La quantità deve essere un numero intero maggiore di zero.');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma inserimento oggetto'),
        content: SingleChildScrollView(child: Text(
          'Descrizione: ${_description.text.trim()}\\n'
          'Produttore: ${_producer.text.trim()}\\n'
          'Linea / serie: ${_line.text.trim()}\\n'
          'Famiglia / categoria: ${_family.text.trim()}\\n'
          'Condizione: $_condition\\n'
          'Completezza: $_completeness\\n'
          'Destinazione: $_destination\\n'
          'Quantità: ${_quantity.text.trim()}\\n'
          'Note: ${_notes.text.trim().isEmpty ? 'Nessuna' : _notes.text.trim()}\\n\\n'
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
        _condition = 'USATO';
        _completeness = 'COMPLETO';
        _destination = 'COLLEZIONE';
        _lastMetadataQuery = '';
        _metadataResult = 'Inserisci la descrizione e poi esci dal campo per avviare la ricerca metadati.';
        _output = 'Pronto per il prossimo oggetto.';
      });
      _descriptionFocus.requestFocus();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _preview() async {
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
      _notes.clear(); _quantity.text = '1';
    }
  }
}
