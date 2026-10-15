import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const String publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
const Color backgroundColor = Color(0xFF101010);
const Color cardColor = Color(0xFF1C1C1C);
const Color goldColor = Color(0xFFD6B15E);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: publishableKey);
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

// Le voci senza mapping certo restano disabilitate: non chiamano API inventate.
const Map<String, List<ProcedureEntry>> sectionProcedures = {
  'CATALOGO': [
    ProcedureEntry(title: 'Nuovo oggetto', description: 'Inserisce un nuovo oggetto nel catalogo.', apiCode: 'WRITE-PR-01', readOnly: false),
    ProcedureEntry(title: 'Modifica oggetto', description: 'Modifica la scheda di un oggetto esistente.', apiCode: 'WRITE-PR-02', readOnly: false),
    ProcedureEntry(title: 'Visualizza scheda', description: 'Mostra la scheda completa di un oggetto.', apiCode: 'READ-OBJECT-MASTER'),
    ProcedureEntry(title: 'Ricerca oggetti', description: 'Cerca oggetti nel catalogo.', apiCode: 'READ-EXPLORE-RECORDS'),
    ProcedureEntry(title: 'Elenco catalogo', description: 'Mostra gli oggetti disponibili.', apiCode: 'READ-OBJECTS-AVAILABLE'),
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
          onTap: procedure.enabled ? () => showProcedureInfo(procedure) : null,
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
