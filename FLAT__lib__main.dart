import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const String publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
const Color backgroundColor = Color(0xFF101010);
const Color cardColor = Color(0xFF1C1C1C);
const Color goldColor = Color(0xFFD6B15E);

class ValoraAppearance extends ChangeNotifier {
  ValoraAppearance._();
  static final instance = ValoraAppearance._();
  static const Map<String, Color> defaults = {
    'CATALOGO': Color(0xFF3978C5), 'ACQUISTI': Color(0xFF39875B),
    'VENDITE': Color(0xFFC74444), 'FLUSSI': Color(0xFFD6A83F),
    'VALUTAZIONI': Color(0xFF8556C7), 'REPORT': Color(0xFFE17D35),
    'RICERCHE': Color(0xFF568DAD), 'CONTROLLO': Color(0xFF777777),
  };
  static const List<Color> palette = [
    Color(0xFF3978C5),Color(0xFF39875B),Color(0xFFC74444),Color(0xFFD6A83F),
    Color(0xFF8556C7),Color(0xFFE17D35),Color(0xFF568DAD),Color(0xFF777777),
    Color(0xFF00897B),Color(0xFF8E24AA),Color(0xFF5C6BC0),Color(0xFF7CB342),
    Color(0xFFEF6C00),Color(0xFFAD1457),Color(0xFF00838F),Color(0xFF6D4C41),
    Color(0xFF546E7A),Color(0xFF9E9D24),Color(0xFF3949AB),Color(0xFF00ACC1),
    Color(0xFFF4511E),Color(0xFF43A047),Color(0xFF6A1B9A),Color(0xFF283593),
  ];
  final Map<String, Color> colors = Map<String, Color>.from(defaults);
  bool whiteBackground = false;
  Color colorFor(String section) => colors[section] ?? defaults[section] ?? goldColor;
  Color get background => whiteBackground ? const Color(0xFFF5F5F5) : backgroundColor;
  Color get card => whiteBackground ? Colors.white : cardColor;
  Color get textPrimary => whiteBackground ? const Color(0xFF171717) : Colors.white;
  Color get textSecondary => whiteBackground ? const Color(0xFF424242) : Colors.white70;
  Color get textMuted => whiteBackground ? const Color(0xFF555555) : Colors.white60;
  Color get textSubtle => whiteBackground ? const Color(0xFF626262) : Colors.white54;
  Color get textFaint => whiteBackground ? const Color(0xFF666666) : Colors.white38;
  Color get neutralOverlay => whiteBackground ? Colors.black.withValues(alpha: 0.06) : Colors.white10;
  Color get neutralOverlayStrong => whiteBackground ? Colors.black.withValues(alpha: 0.12) : Colors.white24;
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    whiteBackground = p.getBool('valora_white_background') ?? false;
    for (final k in defaults.keys) { final v=p.getInt('valora_color_$k'); if(v!=null) colors[k]=Color(v); }
    final used=<int>{};
    for(final k in defaults.keys) {
      if(!used.add(colors[k]!.value)) {
        final replacement=palette.firstWhere((c)=>used.add(c.value),orElse:()=>defaults[k]!);
        colors[k]=replacement;
      }
    }
    notifyListeners();
  }
  Future<void> setBackground(bool white) async {
    whiteBackground=white;
    final p=await SharedPreferences.getInstance(); await p.setBool('valora_white_background',white); notifyListeners();
  }
  Future<void> setColor(String section,Color color) async {
    if(colors.entries.any((e)=>e.key!=section&&e.value.value==color.value)) return;
    colors[section]=color;
    final p=await SharedPreferences.getInstance(); await p.setInt('valora_color_$section',color.value); notifyListeners();
  }
  Future<void> reset() async {
    whiteBackground=false; colors..clear()..addAll(defaults);
    final p=await SharedPreferences.getInstance(); await p.remove('valora_white_background');
    for(final k in defaults.keys){await p.remove('valora_color_$k');}
    notifyListeners();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ValoraAppearance.instance.load();
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

class CollectionValoraApp extends StatefulWidget {
  const CollectionValoraApp({super.key, this.startupError});
  final String? startupError;
  @override
  State<CollectionValoraApp> createState() => _CollectionValoraAppState();
}
class _CollectionValoraAppState extends State<CollectionValoraApp> {
  @override
  void initState(){super.initState();ValoraAppearance.instance.addListener(_refresh);}
  void _refresh(){if(mounted)setState((){});}
  @override
  void dispose(){ValoraAppearance.instance.removeListener(_refresh);super.dispose();}
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'COLLECTION by VALORA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: ValoraAppearance.instance.whiteBackground ? Brightness.light : Brightness.dark,
          scaffoldBackgroundColor: ValoraAppearance.instance.background,
          colorScheme: ValoraAppearance.instance.whiteBackground
              ? ColorScheme.light(
                  primary: goldColor,
                  secondary: goldColor,
                  surface: ValoraAppearance.instance.card,
                  onSurface: ValoraAppearance.instance.textPrimary,
                  onPrimary: Colors.black,
                  onSecondary: Colors.black,
                  error: Color(0xFFB3261E),
                )
              : ColorScheme.dark(
                  primary: goldColor,
                  secondary: goldColor,
                  surface: ValoraAppearance.instance.card,
                  onSurface: ValoraAppearance.instance.textPrimary,
                  error: Color(0xFFE35D5D),
                ),
          appBarTheme: AppBarTheme(
            backgroundColor: ValoraAppearance.instance.background,
            foregroundColor: goldColor,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(color: ValoraAppearance.instance.card, elevation: 3),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: goldColor, width: 1.5),
            ),
          ),
        ),
        home: widget.startupError == null
            ? const AuthenticationGate()
            : StartupFailurePage(error: widget.startupError!),
      );
}

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});
  @override State<AppearanceSettingsPage> createState()=>_AppearanceSettingsPageState();
}
class _AppearanceSettingsPageState extends State<AppearanceSettingsPage>{
  final a=ValoraAppearance.instance;
  @override void initState(){super.initState();a.addListener(refresh);}
  void refresh(){if(mounted)setState((){});}
  @override void dispose(){a.removeListener(refresh);super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Personalizzazione')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      Text('SFONDO',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      SegmentedButton<bool>(segments:const [
        ButtonSegment<bool>(value:false,label:Text('Nero')),
        ButtonSegment<bool>(value:true,label:Text('Bianco'))],
        selected:{a.whiteBackground},onSelectionChanged:(v)=>a.setBackground(v.first)),
      const SizedBox(height:20),
      Text('COLORE DEI BLOCCHI',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:4),
      const Text('Ogni blocco ha un colore esclusivo. I colori già assegnati agli altri blocchi non sono disponibili.'),
      ...ValoraAppearance.defaults.keys.map((section){
        final current=a.colorFor(section);
        final available=ValoraAppearance.palette.where((c)=>c.value==current.value||
          !a.colors.entries.any((e)=>e.key!=section&&e.value.value==c.value)).toList();
        return Card(child:Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
          child:Row(children:[
            Container(width:18,height:18,decoration:BoxDecoration(color:current,borderRadius:BorderRadius.circular(4))),
            const SizedBox(width:10),
            Expanded(child:Text(section,style:TextStyle(color:a.whiteBackground?Colors.black87:ValoraAppearance.instance.textPrimary))),
            DropdownButton<int>(value:current.value,items:available.map((c)=>DropdownMenuItem<int>(
              value:c.value,child:Row(children:[
                Container(width:20,height:20,decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(4))),
                const SizedBox(width:8),Text('#${c.value.toRadixString(16).substring(2).toUpperCase()}')
              ]))).toList(),
              onChanged:(v){if(v!=null)a.setColor(section,Color(v));}),
          ])));
      }),
      const SizedBox(height:20),
      OutlinedButton.icon(onPressed:()async{
        await a.reset();
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Impostazioni iniziali ripristinate.')));
      },icon:const Icon(Icons.restart_alt),label:const Text('RIPRISTINA IMPOSTAZIONI INIZIALI')),
    ]));
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
                    Center(
                      child: SizedBox(
                        width: 228,
                        height: 228,
                        child: Image.asset(
                          'assets/valora_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ValoraAppearance.instance.card,
                              border: Border.all(color: goldColor, width: 2),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: goldColor, size: 72),
                          ),
                        ),
                      ),
                    ),
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
    ProcedureEntry(title: 'Nuovo oggetto', description: 'Crea un oggetto e prepara i metadati per la ricerca.', apiCode: 'PR-01', readOnly: false),
    ProcedureEntry(title: 'Modifica oggetto', description: 'Carica la scheda completa prima di modificarla.', apiCode: 'PR-02', readOnly: false),
    ProcedureEntry(title: 'Chiudi oggetto', description: 'Registra la chiusura con motivazione.', apiCode: 'PR-03', readOnly: false),
    ProcedureEntry(title: 'Visualizza scheda', description: 'Mostra la scheda completa in formato leggibile.', apiCode: 'OBJECT_MASTER'),
    ProcedureEntry(title: 'Elenco oggetti disponibili', description: 'Mostra gli oggetti con stato DISPONIBILE.', apiCode: 'OBJECTS_AVAILABLE'),
    ProcedureEntry(title: 'Storico oggetto', description: 'Mostra la cronologia del singolo oggetto selezionato.', apiCode: 'EXPLORE_RECORDS'),

    ProcedureEntry(title: 'Importa oggetti', description: 'Importa record da CSV o JSON con anteprima e controllo duplicati.', apiCode: 'OBJECT-IMPORT'),
    ProcedureEntry(title: 'Esporta oggetti', description: 'Esporta il catalogo in CSV o JSON.', apiCode: 'OBJECT-EXPORT'),
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
    ProcedureEntry(title: 'PR-12 · Ricerca metadati', description: 'Cerca fonti e candidati per un oggetto, senza salvare automaticamente i dati.', apiCode: 'PR-12', readOnly: true),
    ProcedureEntry(title: 'Ricerca #DEMONOFLU', description: 'Ricerca inserzioni associate a #DEMONOFLU.', enabled: false),
  ],
  'CONTROLLO': [
    ProcedureEntry(title: 'Stato runtime', description: 'Verifica lo stato del servizio runtime.', apiCode: 'RUNTIME-HEALTH'),
    ProcedureEntry(title: 'Catalogo API', description: 'Consulta il catalogo delle API runtime.', apiCode: 'RUNTIME-CATALOG'),
    ProcedureEntry(title: 'Pulizia file', description: 'Operazione non disponibile nell’app runtime.', enabled: false),
  ],
};

Color sectionColorForApiCode(String apiCode) {
  for (final section in dashboardSections) {
    final procedures = sectionProcedures[section.title] ?? const <ProcedureEntry>[];
    if (procedures.any((procedure) => procedure.apiCode == apiCode)) {
      return ValoraAppearance.instance.colorFor(section.title);
    }
  }
  return goldColor;
}


class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _name = TextEditingController();
  final _assistant = TextEditingController(text: 'Demon');
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _emailController = TextEditingController();
  String _market = 'Italia';
  List<Map<String, dynamic>> _markets = [];
  bool _profileLoaded = false;
  String _currency = 'EUR - Euro (€)';
  String _language = 'Italiano';
  String _dateFormat = 'GG/MM/AAAA';
  bool _showNewPassword = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _name.text = (user?.userMetadata?['display_name'] ?? user?.userMetadata?['name'] ?? '').toString();
    _emailController.text = user?.email ?? 'Email non disponibile';
    _loadProfile();
  }

  Future<bool> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return false;
    try {
      final markets = await client.schema('collection').from('mercati')
          .select('codice_mercato,nome_mercato').order('codice_mercato');
      final rows = await client.schema('collection').from('master_utente')
          .select().eq('auth_user_id', user.id).limit(1);
      if (!mounted) return false;
      setState(() {
        _markets = List<Map<String, dynamic>>.from(markets);
        if (rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first);
          _name.text = (row['nome_utente'] ?? '').toString();
          _assistant.text = (row['nome_assistente'] ?? 'Demon').toString();
          _currency = _currencyFor((row['valuta_predefinita'] ?? 'EUR').toString());
          _language = _languageFor((row['lingua_interfaccia'] ?? 'it').toString());
          _dateFormat = (row['formato_data'] ?? 'GG/MM/AAAA').toString();
          final market = _markets.where((m) => m['codice_mercato'] == row['mercato_nazionale_principale']).toList();
          if (market.isNotEmpty) _market = market.first['nome_mercato'].toString();
        }
        if (_markets.isNotEmpty && !_markets.any((m) => m['nome_mercato'] == _market)) {
          _market = _markets.first['nome_mercato'].toString();
        }
        _profileLoaded = true;
      });
      return true;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile caricare il profilo dal database TEST: $e')));
      return false;
    }
  }

  String _currencyFor(String code) => const {'EUR':'EUR - Euro (€)','USD':'USD - Dollaro USA (\$)','GBP':'GBP - Sterlina (£)'}[code] ?? 'EUR - Euro (€)';
  String _languageFor(String code) => const {'it':'Italiano','en':'English','es':'Español','fr':'Français'}[code] ?? 'Italiano';

  Future<void> _saveProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accedi per salvare il profilo.')));
      return;
    }
    if (!_profileLoaded || _markets.isEmpty || _name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa il nome e verifica il catalogo mercati prima di salvare.')));
      return;
    }
    setState(() => _busy = true);
    try {
      final market = _markets.firstWhere((m) => m['nome_mercato'] == _market);
      final existing = await client.schema('collection').from('master_utente')
          .select('codice_utente').eq('auth_user_id', user.id).limit(1);
      final values = <String, dynamic>{
        'auth_user_id': user.id,
        'nome_utente': _name.text.trim(),
        'mercato_nazionale_principale': market['codice_mercato'],
        'valuta_predefinita': _currency.substring(0, 3),
        'lingua_interfaccia': const {'Italiano':'it','English':'en','Español':'es','Français':'fr'}[_language] ?? 'it',
        'formato_data': _dateFormat,
        'nome_assistente': _assistant.text.trim().isEmpty ? null : _assistant.text.trim(),
        'stato_utente': 'ATTIVO',
      };
      if (existing.isEmpty) {
        await client.schema('collection').from('master_utente').insert(values);
      } else {
        await client.schema('collection').from('master_utente').update(values).eq('auth_user_id', user.id);
      }
      final reloaded = await _loadProfile();
      if (!reloaded) {
        throw StateError('Il salvataggio è stato inviato, ma la rilettura di conferma non è riuscita.');
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo salvato e verificato rileggendolo dal database TEST.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvataggio non riuscito. Verifica autorizzazione e policy TEST. Dettaglio: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _assistant.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final password = _newPassword.text;
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La nuova password deve contenere almeno 8 caratteri.')),
      );
      return;
    }
    if (password != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le due password non coincidono.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: password));
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password aggiornata correttamente.')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossibile aggiornare la password: ' + e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante l’aggiornamento della password.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Card(
    color: ValoraAppearance.instance.card,
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        ...children,
      ]),
    ),
  );

  InputDecoration _fieldDecoration(String label, {Widget? suffixIcon, String? helper}) =>
      InputDecoration(labelText: label, helperText: helper, suffixIcon: suffixIcon);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final created = user?.createdAt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo utente'),
        leading: IconButton(
          tooltip: 'Torna alla dashboard',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final content = <Widget>[
            _section('INFORMAZIONI UTENTE', Icons.person_outline, [
              Center(child: Container(
                width: 76, height: 76,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldColor, width: 2)),
                child: const Icon(Icons.person, color: goldColor, size: 42),
              )),
              const SizedBox(height: 12),
              TextField(controller: _name, decoration: _fieldDecoration('Nome utente')),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                readOnly: true,
                decoration: _fieldDecoration('Email', suffixIcon: const Icon(Icons.lock_outline),
                  helper: 'Gestita dal sistema di autenticazione'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _newPassword, obscureText: !_showNewPassword,
                decoration: _fieldDecoration('Nuova password',
                  suffixIcon: IconButton(
                    tooltip: _showNewPassword ? 'Nascondi password' : 'Mostra password',
                    onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                    icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility),
                  ),
                  helper: 'Almeno 8 caratteri')),
              const SizedBox(height: 12),
              TextField(controller: _confirmPassword, obscureText: !_showNewPassword,
                decoration: _fieldDecoration('Conferma nuova password')),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: _busy ? null : _changePassword,
                icon: const Icon(Icons.lock_reset),
                label: Text(_busy ? 'AGGIORNAMENTO...' : 'CAMBIA PASSWORD'),
              )),
              const SizedBox(height: 12),
              TextField(controller: _assistant, decoration: _fieldDecoration('Nome assistente')),
            ]),
            _section('PREFERENZE GENERALI', Icons.settings_outlined, [
              DropdownButtonFormField<String>(
                value: _markets.any((m) => m['nome_mercato'] == _market) ? _market : null,
                decoration: _fieldDecoration('Mercato principale'),
                items: _markets.map((m) => DropdownMenuItem<String>(value: m['nome_mercato'].toString(), child: Text(m['nome_mercato'].toString()))).toList(),
                onChanged: (v) { if (v != null) setState(() => _market = v); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: _fieldDecoration('Valuta predefinita'),
                items: const ['EUR - Euro (€)', 'USD - Dollaro USA (\$)', 'GBP - Sterlina (£)'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) { if (v != null) setState(() => _currency = v); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _language,
                decoration: _fieldDecoration('Lingua interfaccia'),
                items: const ['Italiano', 'English', 'Español', 'Français'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) { if (v != null) setState(() => _language = v); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _dateFormat,
                decoration: _fieldDecoration('Formato data'),
                items: const ['GG/MM/AAAA', 'AAAA-MM-GG', 'MM/GG/AAAA'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) { if (v != null) setState(() => _dateFormat = v); },
              ),
            ]),
            _section('STATO ACCOUNT', Icons.info_outline, [
              const ListTile(contentPadding: EdgeInsets.zero, title: Text('Stato'), trailing: Chip(label: Text('Autenticato'))),
              ListTile(contentPadding: EdgeInsets.zero, title: const Text('Data creazione account'), subtitle: Text(created ?? 'Non disponibile')),
            ]),
            Card(
              color: ValoraAppearance.instance.card,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text('Il profilo viene letto e salvato in master_utente nel database TEST. Le preferenze grafiche restano separate e locali.'),
              ),
            ),
          ];
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Center(child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 900 : 560),
                child: Column(children: [
                  ...content,
                  SizedBox(width: double.infinity, child: FilledButton.icon(
                    onPressed: _busy ? null : _saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_busy ? 'SALVATAGGIO...' : 'SALVA MODIFICHE'),
                  )),
                ]),
              )),
            ],
          );
        }),
      ),
    );
  }
}

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
          actions: [
            IconButton(tooltip: 'Profilo utente', onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserProfilePage()));
            }, icon: const Icon(Icons.account_circle_outlined)),
            IconButton(tooltip: 'Personalizza interfaccia', onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()));
            }, icon: const Icon(Icons.palette_outlined)),
            IconButton(tooltip: 'Esci', onPressed: logout, icon: const Icon(Icons.logout)),
          ],
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
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Gestione della tua collezione', style: TextStyle(color: ValoraAppearance.instance.textMuted))),
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
                color: ValoraAppearance.instance.card, borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => selectedSection = section),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ValoraAppearance.instance.colorFor(section.title), width: 1.2)),
                    padding: const EdgeInsets.all(10),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(width: 54, height: 54,
                        decoration: BoxDecoration(color: ValoraAppearance.instance.colorFor(section.title).withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14)),
                        child: Icon(section.icon, color: ValoraAppearance.instance.colorFor(section.title), size: 30)),
                      const SizedBox(height: 12),
                      Text(section.title, textAlign: TextAlign.center,
                        style: TextStyle(color: ValoraAppearance.instance.colorFor(section.title), fontWeight: FontWeight.bold,
                          fontSize: 13, letterSpacing: 0.5)),
                      const SizedBox(height: 6),
                      Text(section.description, textAlign: TextAlign.center,
                        style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 11)),
                    ]),
                  ),
                ),
              );
            },
          )),
          Padding(padding: const EdgeInsets.all(10), child: Text('COLLECTION by VALORA',
            style: TextStyle(color: ValoraAppearance.instance.textFaint, fontSize: 11, letterSpacing: 1))),
        ]);
      });

  Widget buildSection(DashboardSection section) {
    final procedures = sectionProcedures[section.title] ?? const <ProcedureEntry>[];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), children: [
      Icon(section.icon, color: ValoraAppearance.instance.colorFor(section.title), size: 52),
      const SizedBox(height: 12),
      Text(section.title, textAlign: TextAlign.center, style: TextStyle(
        color: ValoraAppearance.instance.colorFor(section.title), fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1)),
      const SizedBox(height: 6),
      Text(section.description, textAlign: TextAlign.center,
        style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
      const SizedBox(height: 20),
      ...procedures.map((procedure) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          enabled: procedure.enabled,
          leading: CircleAvatar(
            backgroundColor: procedure.enabled ? ValoraAppearance.instance.colorFor(section.title).withValues(alpha: 0.18) : ValoraAppearance.instance.neutralOverlay,
            child: Icon(procedure.enabled
                ? (procedure.readOnly ? Icons.play_arrow : Icons.edit_outlined)
                : Icons.lock_outline,
              color: procedure.enabled ? ValoraAppearance.instance.colorFor(section.title) : ValoraAppearance.instance.textFaint),
          ),
          title: Text(procedure.title, style: TextStyle(fontWeight: FontWeight.w600,
            color: procedure.enabled ? ValoraAppearance.instance.textPrimary : ValoraAppearance.instance.textFaint)),
          subtitle: Text(procedure.description),
          isThreeLine: true,
          trailing: Icon(procedure.enabled ? Icons.chevron_right : Icons.lock_outline,
            color: procedure.enabled ? ValoraAppearance.instance.colorFor(section.title) : ValoraAppearance.instance.neutralOverlayStrong),
          onTap: !procedure.enabled
              ? null
              : procedure.title == 'Ricerca oggetti'
                  ? () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const CategoryObjectSearchPage()))
                  : (procedure.apiCode == 'OBJECT-IMPORT' || procedure.apiCode == 'OBJECT-EXPORT')
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ObjectTransferPage(importMode: procedure.apiCode == 'OBJECT-IMPORT')))
                      : procedure.apiCode != null
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ObjectRuntimePage(title: procedure.title, apiCode: procedure.apiCode!)))
                      : null,
        ),
      )),
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

class CategoryObjectSearchPage extends StatefulWidget {
  const CategoryObjectSearchPage({super.key});

  @override
  State<CategoryObjectSearchPage> createState() => _CategoryObjectSearchPageState();
}

class _CategoryObjectSearchPageState extends State<CategoryObjectSearchPage> {
  final TextEditingController _query = TextEditingController();
  bool _loading = false;
  String _message = 'Inserisci una categoria o una dicitura, per esempio TRANSFORMERS.';
  List<Map<String, dynamic>> _results = [];

  String _description(Map<String, dynamic> row) =>
      (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome'] ?? '').toString();

  String _code(Map<String, dynamic> row) => (row['codice_oggetto'] ?? '').toString();

  Future<void> _search() async {
    final query = _query.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _message = 'Scrivi una categoria o una dicitura da cercare.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _results = [];
      _message = 'Ricerca nel catalogo in corso…';
    });
    try {
      final response = await Supabase.instance.client.schema('collection').rpc(
        'pr_11_ricerca_schede',
        params: {'p_cerca': query},
      );
      dynamic payload = response;
      if (payload is List && payload.length == 1 && payload.first is Map) {
        payload = payload.first;
      }
      if (payload is! Map || payload['oggetti'] is! List) {
        throw Exception('Il catalogo non ha restituito un elenco di oggetti valido.');
      }
      final normalizedQuery = query.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
      final rows = (payload['oggetti'] as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) => _description(row).toLowerCase().contains(normalizedQuery))
          .toList()
        ..sort((a, b) => (int.tryParse(_code(a)) ?? 0).compareTo(int.tryParse(_code(b)) ?? 0));

      final allResponse = await Supabase.instance.client.schema('collection').rpc(
        'pr_11_ricerca_schede',
        params: {'p_cerca': null},
      );
      dynamic allPayload = allResponse;
      if (allPayload is List && allPayload.length == 1 && allPayload.first is Map) {
        allPayload = allPayload.first;
      }
      if (allPayload is! Map || allPayload['oggetti'] is! List) {
        throw Exception('Impossibile calcolare il totale della collezione.');
      }
      final total = (allPayload['oggetti'] as List).length;
      final percentage = total == 0 ? 0.0 : rows.length * 100 / total;
      if (!mounted) return;
      setState(() {
        _results = rows;
        _message = rows.isEmpty
            ? 'Nessun record contiene “$query”. Prova una dicitura più breve.'
            : 'Trovati ${rows.length} record su $total totali (${percentage.toStringAsFixed(1).replaceAll('.', ',')}% della collezione). Seleziona una scheda per aprire il dettaglio completo.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _message = 'Ricerca non riuscita: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRecord(Map<String, dynamic> row) async {
    final code = int.tryParse(_code(row));
    if (code == null || code <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Il risultato non contiene un codice oggetto valido.')),
      );
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ObjectRuntimePage(
        title: 'Scheda oggetto',
        apiCode: 'OBJECT_MASTER',
        initialObjectCode: code,
      ),
    ));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ValoraAppearance.instance.colorFor('RICERCHE');
    return Scaffold(
      appBar: AppBar(title: const Text('RICERCA OGGETTI PER CATEGORIA')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Cerca nel catalogo esistente per categoria o dicitura. Esempio: TRANSFORMERS.',
              style: TextStyle(color: ValoraAppearance.instance.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Categoria o dicitura',
                hintText: 'TRANSFORMERS',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Cancella ricerca',
                  onPressed: () {
                    _query.clear();
                    setState(() {
                      _results = [];
                      _message = 'Inserisci una categoria o una dicitura, per esempio TRANSFORMERS.';
                    });
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _search,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.search),
                label: Text(_loading ? 'RICERCA IN CORSO…' : 'CERCA NEL CATALOGO'),
              ),
            ),
            const SizedBox(height: 16),
            Text(_message, style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
            const SizedBox(height: 8),
            ..._results.map((row) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.16),
                  child: Icon(Icons.inventory_2_outlined, color: color),
                ),
                title: Text(_description(row), maxLines: 3, overflow: TextOverflow.ellipsis),
                subtitle: Text('Codice oggetto: ${_code(row)}'),
                trailing: Icon(Icons.chevron_right, color: color),
                onTap: () => _openRecord(row),
              ),
            )),
          ],
        ),
      ),
    );
  }
}


class ObjectTransferPage extends StatefulWidget {
  const ObjectTransferPage({super.key, required this.importMode});
  final bool importMode;
  @override
  State<ObjectTransferPage> createState() => _ObjectTransferPageState();
}

class _ObjectTransferPageState extends State<ObjectTransferPage> {
  bool _busy = false;
  String _status = 'Pronto. Ambiente TEST.';
  List<Map<String, dynamic>> _rows = [];
  final Set<int> _duplicates = {};
  final Set<int> _invalid = {};
  static const _headers = ['codice_oggetto','descrizione_oggetto','condizione','completezza','destinazione','stato','quantita','valore_oggetto','valuta_valore','totale_calcolato'];

  String _norm(dynamic value) => (value ?? '').toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<List<Map<String,dynamic>>> _catalog() async {
    final result = await Supabase.instance.client.schema('collection').rpc('pr_11_ricerca_schede', params: {'p_cerca': null});
    dynamic data = result;
    if (data is List && data.length == 1 && data.first is Map) data = data.first;
    if (data is! Map || data['oggetti'] is! List) throw Exception('Risposta catalogo non valida.');
    return (data['oggetti'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
  }

  Future<void> _export(String format) async {
    setState(() { _busy = true; _status = 'Lettura catalogo TEST…'; });
    try {
      final rows = await _catalog();
      if (rows.isEmpty) throw Exception('Nessun record da esportare.');
      final stamp = DateTime.now().toIso8601String().replaceAll(':','-').split('.').first;
      late List<int> bytes;
      late String ext;
      if (format == 'json') {
        bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(rows));
        ext = 'json';
      } else if (format == 'xlsx') {
        final workbook = xlsx.Excel.createExcel();
        final sheet = workbook['Catalogo'];
        sheet.appendRow(_headers.map((h) => xlsx.TextCellValue(h)).toList());
        for (final row in rows) {
          sheet.appendRow(_headers.map((h) => xlsx.TextCellValue((row[h] ?? '').toString())).toList());
        }
        final encoded = workbook.encode();
        if (encoded == null) throw Exception('Creazione file Excel non riuscita.');
        bytes = encoded;
        ext = 'xlsx';
      } else {
        final matrix = <List<dynamic>>[_headers];
        for (final row in rows) { matrix.add(_headers.map((h)=>row[h] ?? '').toList()); }
        bytes = utf8.encode('\uFEFF' + const ListToCsvConverter().convert(matrix));
        ext = 'csv';
      }
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Esporta catalogo TEST',
        fileName: 'VALORA_catalogo_' + stamp + '.' + ext,
        bytes: Uint8List.fromList(bytes));
      if (mounted) setState(() => _status = path == null ? 'Esportazione annullata.' : 'Esportati ' + rows.length.toString() + ' record. File: ' + path);
    } catch (e) {
      if (mounted) setState(() => _status = 'Esportazione non riuscita: ' + e.toString());
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<List<Map<String,dynamic>>> _parse(PlatformFile file) async {
    if (file.bytes == null) throw Exception('Impossibile leggere il file selezionato.');
    final name = file.name.toLowerCase();
    if (name.endsWith('.json')) {
      final data = jsonDecode(utf8.decode(file.bytes!));
      final list = data is Map ? (data['oggetti'] ?? data['objects'] ?? data['data']) : data;
      if (list is! List) throw Exception('Il JSON deve contenere un elenco di oggetti.');
      return list.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    }
    if (name.endsWith('.xlsx')) {
      final workbook = xlsx.Excel.decodeBytes(file.bytes!);
      if (workbook.tables.isEmpty) throw Exception('Il file Excel non contiene fogli leggibili.');
      final table = workbook.tables.values.first.rows;
      if (table.length < 2) throw Exception('Il foglio Excel è vuoto o non contiene righe dati.');
      final headers = table.first.map((c) => (c?.value?.toString() ?? '').trim().toLowerCase()).toList();
      return table.skip(1).where((r) => r.any((c) => (c?.value?.toString() ?? '').trim().isNotEmpty)).map((r) {
        final row = <String, dynamic>{};
        for (var i = 0; i < headers.length && i < r.length; i++) {
          row[headers[i]] = r[i]?.value?.toString() ?? '';
        }
        return row;
      }).toList();
    }
    if (name.endsWith('.csv')) {
      final text = utf8.decode(file.bytes!).replaceFirst('\uFEFF','');
      final table = const CsvToListConverter(shouldParseNumbers:false).convert(text);
      if (table.length < 2) throw Exception('CSV vuoto o senza righe dati.');
      final headers = table.first.map((e)=>e.toString().trim().toLowerCase()).toList();
      return table.skip(1).where((r)=>r.any((v)=>v.toString().trim().isNotEmpty)).map((r) {
        final row=<String,dynamic>{};
        for (var i=0;i<headers.length && i<r.length;i++) { row[headers[i]]=r[i]; }
        return row;
      }).toList();
    }
    throw Exception('Formato non supportato. Usa XLSX, CSV o JSON.');
  }

  Future<void> _pickImport() async {
    setState(() { _busy=true; _status='Seleziona file CSV o JSON…'; _rows=[]; _duplicates.clear(); _invalid.clear(); });
    try {
      final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:const ['xlsx','csv','json'],withData:true);
      if (picked==null || picked.files.isEmpty) { if(mounted)setState(()=>_status='Importazione annullata. Nessuna modifica eseguita.'); return; }
      final rows=await _parse(picked.files.first);
      final existing=await _catalog();
      final descriptions=existing.map((e)=>_norm(e['descrizione_oggetto'])).toSet();
      final codes=existing.map((e)=>_norm(e['codice_oggetto'])).toSet();
      for(var i=0;i<rows.length;i++) {
        final desc=_norm(rows[i]['descrizione_oggetto'] ?? rows[i]['descrizione'] ?? rows[i]['nome']);
        final code=_norm(rows[i]['codice_oggetto']);
        if(desc.isEmpty) _invalid.add(i);
        else if(descriptions.contains(desc) || (code.isNotEmpty && codes.contains(code)) ||
          rows.take(i).any((r)=>_norm(r['descrizione_oggetto'] ?? r['descrizione'] ?? r['nome'])==desc)) _duplicates.add(i);
      }
      if(mounted)setState(() { _rows=rows; _status='Anteprima ' + rows.length.toString() + ' righe. Possibili duplicati: ' + _duplicates.length.toString() + '. Senza descrizione: ' + _invalid.length.toString() + '. Nessun record salvato.'; });
    } catch(e) { if(mounted)setState(()=>_status='Importazione non riuscita: '+e.toString()); }
    finally { if(mounted)setState(()=>_busy=false); }
  }

  String _enumValue(dynamic value, List<String> allowed, String fallback) {
    final v=(value ?? '').toString().trim().toUpperCase();
    return allowed.contains(v) ? v : fallback;
  }

  Future<void> _confirmImport() async {
    final eligible=<Map<String,dynamic>>[];
    for(var i=0;i<_rows.length;i++) { if(!_invalid.contains(i)&&!_duplicates.contains(i)) eligible.add(_rows[i]); }
    if(eligible.isEmpty) { setState(()=>_status='Non ci sono record validi da importare.'); return; }
    final ok=await showDialog<bool>(context:context,barrierDismissible:false,builder:(ctx)=>AlertDialog(
      title:const Text('CONFERMA IMPORTAZIONE'),
      content:Text('Saranno creati ' + eligible.length.toString() + ' nuovi oggetti in TEST. I possibili duplicati e le righe senza descrizione saranno esclusi. I codici saranno assegnati dal database. I record esistenti non saranno aggiornati. Procedere?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('ANNULLA')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('IMPORTA'))]));
    if(ok!=true || !mounted)return;
    setState(()=>_busy=true);
    var saved=0; var failed=0; final errors=<String>[];
    try {
      for(final row in eligible) {
        final description=(row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome'] ?? '').toString().trim();
        final qty=int.tryParse((row['quantita'] ?? '1').toString()) ?? 1;
        final valueText=(row['valore_oggetto'] ?? '').toString().trim().replaceAll(',','.');
        final value=valueText.isEmpty?null:double.tryParse(valueText);
        final yearText=(row['anno_uscita'] ?? '').toString().trim();
        final year=yearText.isEmpty?null:int.tryParse(yearText);
        final payload={'oggetti':[{
          'descrizione':description,
          'produttore':(row['produttore'] ?? '').toString().trim().isEmpty?null:row['produttore'].toString().trim(),
          'anno_uscita':year,
          'codice_prodotto':(row['codice_prodotto'] ?? '').toString().trim().isEmpty?null:row['codice_prodotto'].toString().trim(),
          'condizione':_enumValue(row['condizione'],const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'],'USATO'),
          'completezza':_enumValue(row['completezza'],const ['SIGILLATO','COMPLETO','INCOMPLETO'],'COMPLETO'),
          'destinazione':_enumValue(row['destinazione'],const ['COLLEZIONE','RIVENDITA','ALTRO'],'COLLEZIONE'),
          'quantita':qty<1?1:qty,
          if(value!=null&&value>=0)'valore_oggetto':value,
          'note':(row['note'] ?? '').toString().trim().isEmpty?null:row['note'].toString().trim()
        }]};
        final session=_uuid.v4();
        try {
          final lock=await _ValoraRuntimeApi.call('acquire_lock',{'session_id':session});
          final lockResult=lock['result'];
          if(lockResult is! Map || lockResult['acquisito']!=true) throw Exception('Blocco archivio non acquisito.');
          await _ValoraRuntimeApi.procedure('PR-01','preview',payload,sessionId:session);
          final review=Map<String,dynamic>.from(payload)..['dati_confermati']=true..['altra_operazione']=false..['conferma_finale']=false;
          await _ValoraRuntimeApi.procedure('PR-01','review',review,sessionId:session);
          final save=Map<String,dynamic>.from(payload)..['dati_confermati']=true..['altra_operazione']=false..['conferma_finale']=true;
          final result=await _ValoraRuntimeApi.procedure('PR-01','save',save,sessionId:session,requestId:_uuid.v4());
          if(result['scrittura_eseguita']!=true) throw Exception('Scrittura non confermata dal runtime.');
          saved++;
        } catch(e) { failed++; errors.add(description+': '+e.toString()); }
      }
      if(mounted)setState(()=>_status='Importazione conclusa. Salvati: '+saved.toString()+'. Errori: '+failed.toString()+(errors.isEmpty?'':'\n'+errors.take(5).join('\n')));
    } finally { if(mounted)setState(()=>_busy=false); }
  }

  @override
  Widget build(BuildContext context) {
    final color=ValoraAppearance.instance.colorFor('CATALOGO');
    return Scaffold(appBar:AppBar(title:Text(widget.importMode?'IMPORTA OGGETTI':'ESPORTA OGGETTI')),
      body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
        Text(widget.importMode?'Importa Excel, CSV o JSON. VALORA controlla i dati e mostra l’anteprima prima del salvataggio.':'Esporta il catalogo TEST in Excel, CSV o JSON.',style:TextStyle(color:ValoraAppearance.instance.textSecondary)),
        const SizedBox(height:16),
        if(widget.importMode) ...[
          SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy?null:_pickImport,icon:const Icon(Icons.file_open),label:const Text('SELEZIONA FILE E ANALIZZA'))),
          if(_rows.isNotEmpty) ...[
            const SizedBox(height:10),
            Text('Anteprima record: '+_rows.length.toString(),style:TextStyle(color:color,fontWeight:FontWeight.bold)),
            ..._rows.take(50).toList().asMap().entries.map((entry){
              final i=entry.key;final row=entry.value;
              final desc=(row['descrizione_oggetto']??row['descrizione']??row['nome']??'').toString();
              final warning=_invalid.contains(i)||_duplicates.contains(i);
              final label=_invalid.contains(i)?'Escluso: manca la descrizione':_duplicates.contains(i)?'Possibile duplicato, escluso':'Pronto per l’importazione';
              return Card(child:ListTile(leading:Icon(warning?Icons.warning_amber:Icons.inventory_2_outlined,color:warning?Colors.orange:color),title:Text(desc.isEmpty?'Riga '+(i+2).toString():desc,maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text(label)));
            }),
            if(_rows.length>50)Text('Mostrate le prime 50 righe su '+_rows.length.toString()),
            SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy?null:_confirmImport,icon:const Icon(Icons.save_alt),label:const Text('CONFERMA E IMPORTA NUOVI OGGETTI')))
          ]
        ] else ...[
          SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy?null:()=>_export('xlsx'),icon:const Icon(Icons.table_view),label:const Text('ESPORTA EXCEL (.XLSX)'))),
          const SizedBox(height:8),
          SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy?null:()=>_export('csv'),icon:const Icon(Icons.description_outlined),label:const Text('ESPORTA CSV'))),
          const SizedBox(height:8),
          SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:_busy?null:()=>_export('json'),icon:const Icon(Icons.data_object),label:const Text('ESPORTA JSON')))
        ],
        if(_busy)const Padding(padding:EdgeInsets.all(16),child:Center(child:CircularProgressIndicator())),
        const SizedBox(height:16),
        Card(child:Padding(padding:const EdgeInsets.all(12),child:Text(_status))),
        Text('Database TEST. L’importazione crea nuovi record e non aggiorna quelli esistenti.',style:TextStyle(color:ValoraAppearance.instance.textMuted,fontSize:12))
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
  Color get sectionColor => sectionColorForApiCode(widget.apiCode);
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
  List<Map<String, dynamic>> _pr12IncompleteRecords = [];
  int _pr12NextBatchOffset = 0;
  bool _pr12AiBatchRunning = false;
  String _pr12AiBatchStatus = 'Ricerca multi-fonte non ancora avviata.';
  List<Map<String, dynamic>> _pr12AiResults = [];
  bool _showPr02TechnicalTab = false;
  bool _pr02SearchCompleted = false;
  final List<Map<String, dynamic>> _pr02PendingChanges = [];
  final List<Map<String, dynamic>> _pr03PendingClosures = [];
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _pr11SearchFocusNode = FocusNode();
  String _lastPr11SearchQuery = '';

  bool get _isWrite => const {'PR-01', 'PR-02', 'PR-03'}.contains(widget.apiCode);

  @override
  void initState() {
    super.initState();
    if (widget.apiCode == 'OBJECT_MASTER') {
      _pr11SearchFocusNode.addListener(_onPr11SearchFocusChanged);
    }
    if (widget.apiCode == 'PR-01') {
      _quantity.addListener(_recalculateTotal);
      _unitPrice.addListener(_recalculateTotal);
    }
    if (widget.initialObjectCode != null) {
      _code.text = widget.initialObjectCode.toString();
      // Quando si apre la scheda da un elemento dell'elenco, carica subito
      // il record selezionato invece di mostrare una maschera vuota.
      if (widget.apiCode == 'OBJECT_MASTER') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _run(_loadObject);
        });
      }
    }
  }

  void _onPr11SearchFocusChanged() {
    if (widget.apiCode != 'OBJECT_MASTER' || _pr11SearchFocusNode.hasFocus || _loading) return;
    final query = _search.text.trim();
    if (query.length < 2 || query == _lastPr11SearchQuery) return;
    _lastPr11SearchQuery = query;
    _run(_searchPr02Objects);
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
    _pr11SearchFocusNode.removeListener(_onPr11SearchFocusChanged);
    _pr11SearchFocusNode.dispose();
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
      if (mounted) {
        setState(() => _output = 'ERRORE: $e');
        if (widget.apiCode == 'OBJECT_MASTER') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ricerca non riuscita: $e'), duration: const Duration(seconds: 5)),
          );
        }
      }
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

    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    Future<List<Map<String, dynamic>>> searchPhrase(String phrase) async {
      final searchRpc = (widget.apiCode == 'OBJECT_MASTER' || widget.apiCode == 'EXPLORE_RECORDS')
          ? 'pr_11_ricerca_schede'
          : 'pr_02_ricerca_oggetti';
      final response = await Supabase.instance.client.schema('collection').rpc(
        searchRpc,
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

    String descriptionOf(Map<String, dynamic> item) =>
        (item['descrizione_oggetto'] ?? item['descrizione'] ?? item['nome'] ?? '').toString();
    String codeOf(Map<String, dynamic> item) =>
        (item['codice_oggetto'] ?? '').toString().trim();

    // La RPC può restituire risultati troppo ampi (per esempio tutti gli
    // oggetti LEGO quando si cerca una descrizione precisa). Restringiamo
    // sempre i risultati alla frase richiesta prima di mostrarli.
    final normalizedQuery = normalize(query);
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
    List<Map<String, dynamic>> results = await searchPhrase(query);

    bool matchesPhrase(Map<String, dynamic> item, String phrase) {
      final q = normalize(phrase);
      if (q.isEmpty) return false;
      return normalize(descriptionOf(item)).contains(q) || codeOf(item) == phrase.trim();
    }

    results = results.where((item) => matchesPhrase(item, query)).toList();

    // Se il prefisso digitato non è presente nella descrizione archiviata,
    // prova le frasi complete più corte, mantenendo sempre il filtro stretto.
    if (results.isEmpty && tokens.length > 1) {
      for (var startAt = 1; startAt < tokens.length; startAt++) {
        final candidate = tokens.skip(startAt).join(' ').trim();
        if (candidate.isEmpty) continue;
        final candidateResults = await searchPhrase(candidate);
        final narrowed = candidateResults.where((item) => matchesPhrase(item, candidate)).toList();
        if (narrowed.isNotEmpty) {
          results = narrowed;
          break;        }
      }
    }

    // La ricerca per singola parola è consentita solo per una query di una
    // sola parola. Evita di unire risultati generici di ogni token, causa
    // frequente di elenchi enormi e irrilevanti.
    if (results.isEmpty && tokens.length == 1) {
      results = (await searchPhrase(tokens.first))
          .where((item) => matchesPhrase(item, tokens.first))
          .toList();
    }

    // Prima le descrizioni identiche, poi le corrispondenze parziali pertinenti.
    final exact = results.where((item) => normalize(descriptionOf(item)) == normalizedQuery).toList();
    if (exact.isNotEmpty) results = exact;

    results.sort((a, b) =>
      (int.tryParse(codeOf(a)) ?? 0).compareTo(int.tryParse(codeOf(b)) ?? 0));
    setState(() {
      _pr02SearchResults = results;
      _pr02SearchCompleted = true;
      _output = results.isEmpty
          ? 'Nessun oggetto corrispondente alla descrizione: ' + query
          : 'Trovati ' + results.length.toString() + ' risultati pertinenti. Seleziona il record.';
    });

    if (!mounted) return;
    if (results.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: ValoraAppearance.instance.card,
          title: Text('NESSUN RISULTATO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          content: Text('Non ho trovato oggetti per “' + query + '”. Prova con una parte più breve della descrizione o con il codice oggetto.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('RISULTATI RICERCA (' + results.length.toString() + ')',
          style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 560,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: results.map((item) => Card(
                  child: ListTile(
                    title: Text(codeOf(item) + ' · ' + descriptionOf(item)),
                    subtitle: Text('Stato: ' + (item['stato'] ?? 'Non indicato').toString() +
                      ' · Quantità: ' + (item['quantita'] ?? 'Non indicata').toString() +
                      ' · Prezzo unitario: € ' + (item['valore_oggetto'] ?? 'Non indicato').toString()),
                    trailing: Icon(Icons.chevron_right, color: sectionColor),
                    onTap: () => Navigator.of(dialogContext).pop(item),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('ANNULLA')),
        ],
      ),
    );
    if (selected != null && mounted) {
      if (widget.apiCode == 'PR-03') {
        await _selectPr03Object(selected);
      } else if (widget.apiCode == 'OBJECT_MASTER') {
        await _selectPr11Object(selected);
      } else if (widget.apiCode == 'EXPLORE_RECORDS') {
        await _selectHistoryObject(selected);
      } else {
        await _selectPr02Object(selected);
      }
    }
  }

  Future<void> _selectHistoryObject(Map<String, dynamic> item) async {
    final id=int.tryParse(item['codice_oggetto']?.toString()??'');
    if(id==null||id<=0)throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text=id.toString();
    final response=await _ValoraRuntimeApi.call('object_history',{'session_id':_sessionId,'codice_oggetto':id});
    final result=response['result'];
    if(result is! Map)throw Exception('Risposta dello storico non valida.');
    final history=Map<String,dynamic>.from(result);
    final object=history['scheda_corrente']; final events=history['eventi_storici'];
    setState((){
      _currentObject=object is Map?Map<String,dynamic>.from(object):Map<String,dynamic>.from(item);
      _rows=events is List?events:[];
      _search.text=(_currentObject?['descrizione_oggetto']??_currentObject?['descrizione']??'').toString();
      _output='Storico in sola lettura · ${history['numero_eventi']??_rows.length} eventi.';
    });
  }

  Future<void> _selectPr11Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null) throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text = id.toString();
    await _loadObject();
    if (!mounted || _currentObject == null) return;
    final description = (_currentObject?['descrizione_oggetto']
        ?? _currentObject?['descrizione']
        ?? item['descrizione_oggetto']
        ?? '').toString().trim();
    setState(() {
      _search.text = description;
      _output = 'Scheda completa caricata in sola lettura · codice $id.';
    });
  }

  Future<void> _selectPr03Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null) throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text = id.toString();
    await _loadObject();
    if (!mounted || _currentObject == null) return;

    // In PR-03 il campo di ricerca diventa la descrizione del record effettivamente selezionato.
    // Non lasciare visibile la query digitata dall'utente come se fosse la descrizione dell'oggetto.
    final selectedDescription = (_currentObject?['descrizione_oggetto']
        ?? _currentObject?['descrizione']
        ?? item['descrizione_oggetto']
        ?? '').toString().trim();
    if (selectedDescription.isNotEmpty) {
      setState(() => _search.text = selectedDescription);
    }

    final metadataKeys = ['produttore', 'anno_uscita', 'codice_prodotto', 'fonte_dati_prodotto'];
    final missing = metadataKeys.any((key) => (_currentObject?[key]?.toString().trim().isEmpty ?? true));
    if (missing) {
      setState(() => _metadataResult = 'Scheda caricata. Alcuni metadati risultano assenti: verifica la scheda prima di confermare la chiusura.');
    } else {
      setState(() => _metadataResult = 'Scheda completa caricata automaticamente dal database.');
    }
  }

  Future<void> _confirmPr03Closure() async {
    if (_currentObject == null || _loadedObjectId == null ||
        _loadedObjectId != int.tryParse(_code.text.trim())) {
      throw Exception('Cerca e seleziona prima l’oggetto da chiudere.');
    }
    final id = _loadedObjectId!;
    if (_pr03PendingClosures.any((entry) => entry['codice_oggetto'] == id)) {
      throw Exception('L’oggetto $id è già presente nell’elenco delle chiusure da confermare.');
    }
    final reason = _closeReason;
    final notes = _notes.text.trim();
    final description = (_currentObject?['descrizione_oggetto'] ?? _currentObject?['descrizione'] ?? 'Oggetto $id').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('CONFERMA CHIUSURA'),
        content: Text('Oggetto: $id · $description\nMotivo: $reason\nNote: ${notes.isEmpty ? "Nessuna" : notes}\n\nConfermi questa chiusura?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('CONFERMA')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _pr03PendingClosures.add({
        'codice_oggetto': id,
        'motivo_chiusura': reason,
        'note': notes.isEmpty ? null : notes,
        'descrizione': description,
      });
      _output = 'Chiusure confermate in attesa di salvataggio: ${_pr03PendingClosures.length}.';
    });
    final addAnother = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('ALTRO OGGETTO?'),
        content: Text('Vuoi chiudere un altro oggetto?\n\nOggetti confermati: ${_pr03PendingClosures.length}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('NO, SALVA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('SÌ, CERCA ALTRO')),
        ],
      ),
    );
    if (!mounted) return;
    if (addAnother == true) {
      setState(() {
        _search.clear();
        _code.clear();
        _notes.clear();
        _currentObject = null;
        _loadedObjectId = null;
        _lastResult = null;
        _dataConfirmed = false;
        _finalReady = false;
        _output = 'Cerca il prossimo oggetto da chiudere.';
      });
      return;
    }
    await _savePr03PendingClosures();
  }

  Future<void> _savePr03PendingClosures() async {
    if (_pr03PendingClosures.isEmpty) throw Exception('Non ci sono chiusure confermate da salvare.');
    final summary = _pr03PendingClosures.map((item) =>
      '${item['codice_oggetto']} · ${item['descrizione']} · ${item['motivo_chiusura']}'
    ).join('\n');
    final finalConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('RIEPILOGO FINALE'),
        content: SingleChildScrollView(child: Text('Saranno salvate queste chiusure:\n\n$summary\n\nConfermi il salvataggio?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('SALVA TUTTO')),
        ],
      ),
    );
    if (finalConfirmed != true) return;
    final saved = <int>[];
    for (final item in List<Map<String, dynamic>>.from(_pr03PendingClosures)) {
      final id = int.parse(item['codice_oggetto'].toString());
      final payload = <String, dynamic>{
        'oggetti': [{
          'codice_oggetto': id,
          'motivo_chiusura': item['motivo_chiusura'],
          'note': item['note'],
        }]
      };
      try {
        if (!_lockHeld) await _acquireLock();
        await _ValoraRuntimeApi.procedure('PR-03', 'preview', payload, sessionId: _sessionId);
        final reviewPayload = Map<String, dynamic>.from(payload)
          ..['dati_confermati'] = true
          ..['altra_operazione'] = false
          ..['conferma_finale'] = false;
        await _ValoraRuntimeApi.procedure('PR-03', 'review', reviewPayload, sessionId: _sessionId);
        final savePayload = Map<String, dynamic>.from(payload)
          ..['dati_confermati'] = true
          ..['altra_operazione'] = false
          ..['conferma_finale'] = true;
        final result = await _ValoraRuntimeApi.procedure(
          'PR-03', 'save', savePayload, sessionId: _sessionId, requestId: _uuid.v4());
        if (result['scrittura_eseguita'] != true) {
          throw Exception('Il runtime non ha confermato la scrittura per l’oggetto $id.');
        }
        if (result['blocco_rilasciato_automaticamente'] != true) {
          throw Exception('Il runtime non ha confermato il rilascio del blocco per l’oggetto $id.');
        }
        saved.add(id);
        if (mounted) setState(() { _lastResult = result; _output = _pretty(result); });
      } catch (error) {
        if (mounted) setState(() => _output = 'Salvate: ${saved.join(', ')}. Errore sull’oggetto $id: $error. Le restanti chiusure restano non elaborate.');
        rethrow;
      }
    }
    if (!mounted) return;
    setState(() {
      _pr03PendingClosures.clear();
      _currentObject = null;
      _loadedObjectId = null;
      _code.clear();
      _search.clear();
      _notes.clear();
      _lastResult = null;
      _output = 'Chiusure salvate e scrittura confermata per: ${saved.join(', ')}.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chiusure salvate: ${saved.join(', ')}')),
    );
  }

  Future<void> _selectPr02Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null) throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text = id.toString();
    _showPr02TechnicalTab = false;
    await _loadObject();
    if (!mounted || _currentObject == null) return;
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
          Text('METADATI DEL PRODOTTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(imageUrl, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined, color: ValoraAppearance.instance.textFaint, size: 36))
                  : Icon(Icons.image_outlined, color: ValoraAppearance.instance.textFaint, size: 36),
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
          Text('Metadati informativi, non modificabili da questa scheda.',
            style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _metadataValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: sectionColor, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: ValoraAppearance.instance.textPrimary, fontSize: 13)),
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
          Text('DATI TECNICI · SOLA LETTURA',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Divider(height: 24),
          if (technicalEntries.isEmpty)
            Text('Nessun altro dato tecnico presente nel record.',
              style: TextStyle(color: ValoraAppearance.instance.textMuted))
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
          Text(title, style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
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

  Future<void> _loadIncompleteMetadataCatalog() async {
    setState(() {
      _metadataResult = 'PR-12: analisi del catalogo in corso…';
      _output = _metadataResult;
      _pr12IncompleteRecords = [];
    });
    try {
      final incomplete = <Map<String, dynamic>>[];
      const pageSize = 500;
      var offset = 0;
      var totalRead = 0;
      while (true) {
        final response = await _ValoraRuntimeApi.call('pr12_catalog_page', {
          'session_id': _sessionId,
          'offset': offset,
          'limit': pageSize,
        });
        if (response['ok'] != true || response['rows'] is! List) {
          throw Exception('Il runtime non ha confermato la lettura del catalogo.');
        }
        final page = List<Map<String, dynamic>>.from(
          (response['rows'] as List).map((row) => Map<String, dynamic>.from(row as Map)),
        );
        totalRead += page.length;
        for (final row in page) {
          final producer = (row['produttore'] ?? '').toString().trim();
          final year = row['anno_uscita'];
          final productCode = (row['codice_prodotto'] ?? '').toString().trim();
          if (producer.isEmpty || year == null || productCode.isEmpty) incomplete.add(row);
        }
        if (page.length < pageSize) break;
        offset += pageSize;
      }
      if (!mounted) return;
      setState(() {
        _pr12IncompleteRecords = incomplete;
        _metadataResult = 'Analisi completata: letti $totalRead record; ${incomplete.length} con almeno un metadato mancante. Nessun dato modificato.';
        _output = _metadataResult;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pr12IncompleteRecords = [];
        _metadataResult = 'ANALISI NON COMPLETATA: $e';
        _output = _metadataResult;
      });
      rethrow;
    }
  }

  Future<void> _runPr12AiBatch() async {
    if (_pr12IncompleteRecords.isEmpty) { setState(() => _pr12AiBatchStatus = 'Prima esegui ANALIZZA CATALOGO.'); return; }
    if (_pr12NextBatchOffset >= _pr12IncompleteRecords.length) { setState(() => _pr12AiBatchStatus = 'Tutti i record della coda sono stati inviati alla ricerca.'); return; }
    setState(() { _pr12AiBatchRunning = true; _pr12AiBatchStatus = 'Ricerca multi-fonte in corso…'; });
    try {
      final batch = _pr12IncompleteRecords.skip(_pr12NextBatchOffset).take(10).toList();
      final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
        'modalita_ia': 'TEST',
        'oggetti': batch.map((row) => {'id': (row['codice_oggetto'] ?? '').toString(), 'descrizione': (row['descrizione_oggetto'] ?? '').toString(), 'categoria': _pr12CategoryFromDescription((row['descrizione_oggetto'] ?? '').toString())}).toList(),
      });
      final raw = response.data;
      final events = <Map<String, dynamic>>[];
      if (raw is String) {
        for (final line in raw.split(RegExp(r'\r?\n'))) {
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload.isEmpty) continue;
          try { events.add(Map<String, dynamic>.from(jsonDecode(payload) as Map)); } catch (_) {}
        }
      } else if (raw is Map) { events.add(Map<String, dynamic>.from(raw)); }
      final finals = <Map<String, dynamic>>[];
      for (final event in events) {
        if (event['tipo'] == 'oggetto_completato' || event['tipo'] == 'oggetto_errore') { final result = event['risultato']; if (result is Map) finals.add(Map<String, dynamic>.from(result)); }
        if (event['tipo'] == 'errore_coda') throw Exception(event['error'] ?? 'Errore nella coda di ricerca.');
      }
      if (finals.isEmpty) throw Exception('Il motore non ha restituito risultati leggibili.');
      if (!mounted) return;
      setState(() { _pr12AiResults = [..._pr12AiResults, ...finals]; _pr12NextBatchOffset += batch.length; _pr12AiBatchStatus = 'Lotto completato: ${finals.where((r) => r['ok'] == true).length} riusciti, ${finals.where((r) => r['ok'] != true).length} errori. Avanzamento: $_pr12NextBatchOffset/${_pr12IncompleteRecords.length}. Nessun dato salvato.'; });
    } catch (e) { if (mounted) setState(() => _pr12AiBatchStatus = 'Ricerca non completata: $e'); }
    finally { if (mounted) setState(() => _pr12AiBatchRunning = false); }
  }

  String _pr12CategoryFromDescription(String description) {
    final v = description.toLowerCase();
    if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(v)) return 'LEGO';
    if (RegExp(r'fumett|comic|manga|panini|salda|bonelli|graphic novel|isbn').hasMatch(v)) return 'FUMETTI';
    if (RegExp(r'myth cloth|saint seiya|bandai|gundam|gunpla|dragon ball|action figure|statua|transformers|optimus prime|bumblebee|megatron|star wars|naruto|one piece').hasMatch(v)) return 'ACTION_FIGURE';
    if (RegExp(r'maisto|die.?cast|modellino|motorbike|motocicletta|modellismo|auto in scala').hasMatch(v)) return 'DIECAST';
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
            Text(label, style: TextStyle(
              color: sectionColor, fontSize: 13, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 5),
            SelectableText(text, style: TextStyle(fontSize: 15)),
            if (isUrl) ...[
              const SizedBox(height: 4),
              Text('Fonte esterna', style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
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
              Icon(icon, color: sectionColor, size: 19),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(
                color: sectionColor, fontSize: 16, fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _pr11TechnicalDetails(Map<String, dynamic> object) {
    const technicalKeys = {
      'collegato_vendita', 'modificabile_pr02', 'motivo_esclusione',
      'collegato_acquisto', 'collegato_inserzione', 'collegato_piattaforma',
      'stato_verifica_dati', 'id', 'created_at', 'updated_at',
      'record_id', 'deleted_at', 'versione_record',
    };
    final technical = object.entries.where((e) => technicalKeys.contains(e.key)).toList();
    if (technical.isEmpty) {
      return Card(child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Nessun campo tecnico disponibile per questo oggetto.'),
      ));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DATI TECNICI E DI SISTEMA',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...technical.map((e) => _detailFieldCard(e.key, e.value)),
        ]),
      ),
    );
  }

  Widget _pr11HeaderCard(Map<String, dynamic> item) {
    final code = _valueFor(item, ['codice_oggetto', 'id'], 'Codice n/d');
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CODICE OGGETTO $code',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.startsWith('http')
                ? Image.network(imageUrl, width: 112, height: 112, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _pr11SummaryValue('Destinazione', destination),
              _pr11SummaryValue('Condizione', condition),
              _pr11SummaryValue('Stato', state),
              _pr11SummaryValue('Valore registrato', value),
            ])),
          ]),
        ]),
      ),
    );
  }

  Widget _pr11SummaryValue(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: sectionColor, fontSize: 12, fontWeight: FontWeight.w600)),
      Text(value, style: TextStyle(color: ValoraAppearance.instance.textPrimary, fontSize: 14)),
    ]),
  );

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

  Widget _objectCard(
    Map<String, dynamic> item, {
    VoidCallback? onTap,    bool availableStyle = false,
  }) {
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
    final imageSize = availableStyle ? 104.0 : 88.0;
    Widget infoChip(IconData icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: sectionColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sectionColor.withValues(alpha: 0.28)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: sectionColor),
        const SizedBox(width: 4),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 11))),
      ]),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: availableStyle ? sectionColor.withValues(alpha: 0.35) : ValoraAppearance.instance.neutralOverlay,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(availableStyle ? 14 : 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.startsWith('http')
                ? Image.network(imageUrl, width: imageSize, height: imageSize, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(size: imageSize))
                : _imagePlaceholder(size: imageSize),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(
                  'CODICE $code',
                  style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 12),
                )),
                if (onTap != null) Icon(Icons.chevron_right, color: sectionColor, size: 20),
              ]),
              const SizedBox(height: 5),
              Text(desc, style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: availableStyle ? 16 : 16,
              )),
              const SizedBox(height: 9),
              if (availableStyle) ...[
                Wrap(spacing: 6, runSpacing: 6, children: [
                  infoChip(Icons.inventory_2_outlined, destination),
                  infoChip(Icons.verified_outlined, condition),
                ]),
                const SizedBox(height: 7),
                Row(children: [
                  Icon(Icons.circle, size: 8, color: sectionColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Stato: $state', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12))),
                ]),
                const SizedBox(height: 5),
                Text(
                  'Valore: $value',
                  style: TextStyle(color: sectionColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ] else ...[
                Text('Destinazione: $destination'),
                Text('Condizione: $condition'),
                Text('Stato: $state'),
                Text('Valore: $value'),
              ],
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _imagePlaceholder({double size = 88}) => Container(
    width: size, height: size, color: ValoraAppearance.instance.neutralOverlay,
    child: Icon(Icons.image_not_supported_outlined, color: ValoraAppearance.instance.textFaint, size: 30),
  );

  Widget _historyCard(Map<String, dynamic> event) {
    final date = _valueFor(event, ['data_evento', 'data', 'created_at'], 'Data non indicata');
    final rawType = _valueFor(event, ['tipo_evento', 'tipo', 'azione'], 'Evento');
    final field = (event['campo_modificato'] ?? '').toString().trim();
    final previous = (event['valore_precedente'] ?? '').toString().trim();
    final next = (event['valore_nuovo'] ?? '').toString().trim();
    final reason = (event['motivo'] ?? event['motivazione'] ?? '').toString().trim();
    final note = (event['note'] ?? event['descrizione'] ?? event['dettaglio'] ?? '').toString().trim();
    final isPr03Closure = rawType == 'CAMBIO_STATO' &&
        (reason == 'DISTRUTTO' || reason == 'SMARRITO' || reason == 'DATO VIA' ||
         next == 'DISTRUTTO' || next == 'PERSO' || next == 'USCITO');
    final type = isPr03Closure ? 'CHIUSURA OGGETTO · PR-03' : rawType;
    String fieldLabel(String value) {
      const labels = <String, String>{
        'quantita': 'Quantità',
        'valore_oggetto': 'Valore oggetto',
        'stato': 'Stato',
        'descrizione_oggetto': 'Descrizione',
        'condizione': 'Condizione',
        'completezza': 'Completezza',
        'destinazione': 'Destinazione',
      };
      return labels[value] ?? (value.isEmpty ? 'Campo modificato' : value.replaceAll('_', ' '));
    }
    final isStateChange = field == 'stato' || isPr03Closure;
    final details = <Widget>[];
    if (field.isNotEmpty && !isStateChange) {
      details.add(_historyDetailRow('Campo', fieldLabel(field)));
    }
    if (previous.isNotEmpty || next.isNotEmpty) {
      if (isStateChange) {
        details.add(_historyDetailRow('Stato precedente', previous.isEmpty ? 'Non indicato' : previous));
        details.add(_historyDetailRow('Stato finale', next.isEmpty ? 'Non indicato' : next));
      } else if (previous.isNotEmpty && next.isNotEmpty) {
        details.add(_historyDetailRow('Valore precedente', previous));
        details.add(_historyDetailRow('Valore nuovo', next));
      } else {
        details.add(_historyDetailRow('Valore registrato', next.isEmpty ? previous : next));
      }
    }
    if (reason.isNotEmpty) details.add(_historyDetailRow('Motivo', reason));
    if (note.isNotEmpty) details.add(_historyDetailRow('Note', note));
    if (details.isEmpty) {
      details.add(Text('Nessun dettaglio registrato', style: TextStyle(color: ValoraAppearance.instance.textSecondary)));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isPr03Closure ? Icons.logout : Icons.history, color: sectionColor),
              const SizedBox(width: 10),
              Expanded(child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(date, style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: item,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final code = widget.apiCode;
    final isAvailableList = code == 'OBJECTS_AVAILABLE';
    final isHistory = code == 'EXPLORE_RECORDS';
    final isMaster = code == 'OBJECT_MASTER';

    if (code == 'PR-12') {
      return Scaffold(
        appBar: AppBar(title: const Text('PR-12 · RICERCA METADATI')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RICERCA MULTI-FONTE', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('PR-12 controlla il catalogo e individua tutti i record con almeno un metadato identificativo mancante. Questa fase è di sola lettura: i dati presenti non vengono modificati.'),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : () => _run(_loadIncompleteMetadataCatalog),
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.manage_search),
                        label: Text(_loading ? 'ANALISI IN CORSO…' : 'ANALIZZA CATALOGO'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Record incompleti: ${_pr12IncompleteRecords.length}', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: FilledButton.icon(
                      onPressed: _loading || _pr12AiBatchRunning ? null : _runPr12AiBatch,
                      icon: _pr12AiBatchRunning ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
                      label: Text(_pr12AiBatchRunning ? 'RICERCA IN CORSO…' : 'AVVIA RICERCA MULTI-FONTE · LOTTO DA 10'),
                    )),
                    const SizedBox(height: 8),
                    SelectableText(_pr12AiBatchStatus),
                    if (_pr12AiResults.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('RISULTATI RICERCA (${_pr12AiResults.length})', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      ..._pr12AiResults.map((result) {
                        final candidates = result['risultati'];
                        final candidateList = candidates is List ? candidates : const [];
                        return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('#${result['oggetto_id'] ?? ''} · ${result['descrizione'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(result['ok'] == true ? '${result['numero_risultati'] ?? candidateList.length} risultati trovati' : 'Errore: ${result['error'] ?? 'ricerca non riuscita'}'),
                          ...candidateList.take(5).map((candidate) {
                            final item = candidate is Map ? Map<String, dynamic>.from(candidate) : <String, dynamic>{};
                            return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text((item['title'] ?? 'Fonte senza titolo').toString()), subtitle: Text('${item['snippet'] ?? ''}\n${item['url'] ?? ''}'));
                          }),
                        ])));
                      }),
                    ],
                    if (_pr12IncompleteRecords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ..._pr12IncompleteRecords.take(30).map((row) {
                        final missing = <String>[
                          if ((row['produttore'] ?? '').toString().trim().isEmpty) 'produttore',
                          if (row['anno_uscita'] == null) 'anno',
                          if ((row['codice_prodotto'] ?? '').toString().trim().isEmpty) 'codice prodotto',
                        ];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('#${row['codice_oggetto']} · ${row['descrizione_oggetto'] ?? 'Senza descrizione'}'),
                          subtitle: Text('Mancano: ${missing.join(', ')}'),
                        );
                      }),
                      if (_pr12IncompleteRecords.length > 30)
                        Text('Visualizzati i primi 30 record su ${_pr12IncompleteRecords.length}.'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STATO DELLA RICERCA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(_metadataResult),
                    if (_producer.text.isNotEmpty || _line.text.isNotEmpty || _family.text.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text('METADATI SELEZIONATI', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _field(_producer, 'Produttore selezionato'),
                      _field(_line, 'Anno di uscita selezionato'),
                      _field(_family, 'Codice prodotto selezionato'),
                      const Text('I dati sono solo in questa schermata. Per inserirli nel record, torna a PR-01 e lancia PR-12 dalla relativa maschera.'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (!isMaster)
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text('COLLECTION by VALORA\nUtente: ${Supabase.instance.client.auth.currentUser?.email ?? 'sessione autenticata'}\n${_lockHeld ? 'Blocco archivio: ATTIVO' : 'Blocco archivio: non acquisito'}',
              style: TextStyle(color: sectionColor)),
          )),
        if (_isWrite && code == 'PR-01') ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('IDENTIFICAZIONE OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Codice oggetto: assegnato automaticamente dal database al salvataggio.', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
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
                Text('DATI IDENTIFICATIVI · INSERIMENTO MANUALE', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
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
                Text('DATI INSERIBILI', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
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
                Text('VALORI DETERMINATI DA ALTRE PROCEDURE', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Valore di mercato attuale (€)', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
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
                Text('La stima verrà valorizzata dalla procedura di valutazione del mercato, non inserita manualmente.', style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
              ]),
            ),
          ),
        ],
        if (_isWrite && code == 'PR-02') ...[
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('RICERCA OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
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
                    icon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('La ricerca trova i record contenenti il termine, senza distinzione tra maiuscole e minuscole.', style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12)),
              if (_pr02SearchCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _pr02SearchResults.isEmpty
                      ? 'Nessun risultato trovato.'
                      : 'Risultati mostrati nella finestra sovrapposta: ' + _pr02SearchResults.length.toString(),
                    style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12),
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
                        backgroundColor: !_showPr02TechnicalTab ? sectionColor : ValoraAppearance.instance.card,
                        foregroundColor: !_showPr02TechnicalTab ? Colors.black : ValoraAppearance.instance.textPrimary,
                      ),
                      onPressed: () => setState(() => _showPr02TechnicalTab = false),
                      child: Text('SCHEDA OGGETTO'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _showPr02TechnicalTab ? sectionColor : ValoraAppearance.instance.card,
                        foregroundColor: _showPr02TechnicalTab ? Colors.black : ValoraAppearance.instance.textPrimary,
                      ),
                      onPressed: () => setState(() => _showPr02TechnicalTab = true),
                      child: Text('DATI TECNICI'),
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
          _field(_search, 'Cerca oggetto per descrizione o codice'),
          FilledButton.icon(
            onPressed: _loading ? null : () => _run(_searchPr02Objects),
            icon: Icon(Icons.search),
            label: Text('CERCA E SELEZIONA OGGETTO'),
          ),
          if (_pr03PendingClosures.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Chiusure confermate in attesa: ${_pr03PendingClosures.length}',
                style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
            ),
          if (_currentObject != null) ...[
            _dropdown('Motivo chiusura', _closeReason, const ['SMARRITO','DISTRUTTO','DATO VIA'], (v) => setState(() => _closeReason = v!)),
            _field(_notes, 'Note', lines: 2),
            FilledButton.icon(
              onPressed: _loading ? null : () => _run(_confirmPr03Closure),
              icon: Icon(Icons.verified_outlined),
              label: Text('CONFERMA CHIUSURA'),
            ),
          ],
        ],
        if (!_isWrite && isHistory) ...[
          TextField(controller:_search,textInputAction:TextInputAction.search,
            onSubmitted:(_)=>_run(_searchPr02Objects),
            decoration:InputDecoration(labelText:'Descrizione oggetto',
              hintText:'Inserisci una descrizione completa o parziale',
              suffixIcon:IconButton(tooltip:'Cerca oggetto',onPressed:_loading?null:()=>_run(_searchPr02Objects),
                icon:Icon(Icons.search,color:sectionColor)))),
        ],
        if (!_isWrite && isMaster && widget.initialObjectCode == null) ...[
          TextField(
            controller: _search,
            focusNode: _pr11SearchFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) {
              final query = _search.text.trim();
              if (query.length >= 2 && !_loading) {
                _lastPr11SearchQuery = query;
                _run(_searchPr02Objects);
              }
            },
            decoration: InputDecoration(
              labelText: 'Descrizione oggetto',
              hintText: 'Inserisci la descrizione completa o una parte',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Cerca oggetto',
                onPressed: _loading ? null : () {
                  FocusScope.of(context).unfocus();
                  final query = _search.text.trim();
                  if (query.length >= 2) {
                    _lastPr11SearchQuery = query;
                    _run(_searchPr02Objects);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inserisci almeno 2 caratteri per cercare.')),
                    );
                  }
                },
                icon: Icon(Icons.search, color: sectionColor),
              ),
            ),
          ),
        ],
        if (!_isWrite && isAvailableList)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('Mostra tutti gli oggetti con stato DISPONIBILE, senza obbligo di ricerca.', style: TextStyle(color: ValoraAppearance.instance.textSecondary))),
        if (!_isWrite && !isMaster && !isHistory && !isAvailableList)
          _field(_search, 'Cerca'),
        if (_isWrite && code == 'PR-01') ...[
          FilledButton.icon(
            onPressed: _loading ? null : () => _run(_confirmAndSaveNewObject),
            icon: Icon(Icons.save_outlined),
            label: Text(_loading ? 'SALVATAGGIO IN CORSO…' : 'CONFERMA E SALVA OGGETTO'),
          ),
          const SizedBox(height: 8),
          if (_lockHeld) OutlinedButton.icon(onPressed: _loading ? null : () => _run(_releaseLock),
            icon: Icon(Icons.lock_open), label: Text('RILASCIA BLOCCO ARCHIVIO')),
        ] else if (_isWrite && code == 'PR-02') ...[
          FilledButton.icon(
            onPressed: _loading || _currentObject == null ? null : () => _run(_confirmPr02Changes),
            icon: Icon(Icons.verified_outlined),
            label: Text('CONFERMA DATI'),
          ),
        ] else if (_isWrite && code == 'PR-03') ...[
          const SizedBox.shrink(),
        ] else if (_isWrite) ...[
          FilledButton.icon(onPressed: _loading ? null : () => _run(_preview),
            icon: Icon(Icons.fact_check_outlined), label: Text('1 · CONTROLLA DATI E ANTEPRIMA')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _loading || _lastResult == null ? null : () => _run(_confirmData),
            icon: Icon(Icons.verified_outlined), label: Text('2 · CONFERMO I DATI')),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _loading || !_dataConfirmed || !_finalReady ? null : () => _run(_save),
            icon: Icon(Icons.save_outlined), label: Text('3 · CONFERMA DEFINITIVA E SALVA')),
          const SizedBox(height: 8),
          if (_lockHeld) OutlinedButton.icon(onPressed: _loading ? null : () => _run(_releaseLock),
            icon: Icon(Icons.lock_open), label: Text('RILASCIA BLOCCO ARCHIVIO')),
        ] else if (!isMaster)
          FilledButton.icon(onPressed: _loading ? null : () => _run(_consult),
            icon: Icon(Icons.search),
            label: Text(_loading ? 'RICERCA...' : isAvailableList
              ? 'VISUALIZZA ELENCO OGGETTI DISPONIBILI'
              : isHistory ? 'VISUALIZZA STORICO OGGETTO'
              : 'ESEGUI CONSULTAZIONE')),
        if (_currentObject != null && code != 'PR-02' && code != 'PR-03') ...[
          const SizedBox(height: 16),
          if (isMaster) ...[
            Text(
              _valueFor(_currentObject!, ['descrizione_oggetto', 'descrizione', 'nome'], 'Oggetto senza descrizione'),
              style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(children: [
                  Expanded(child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: !_showPr02TechnicalTab ? sectionColor : ValoraAppearance.instance.card,
                      foregroundColor: !_showPr02TechnicalTab ? Colors.black : ValoraAppearance.instance.textPrimary,
                    ),
                    onPressed: () => setState(() => _showPr02TechnicalTab = false),
                    child: Text('SCHEDA OGGETTO'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _showPr02TechnicalTab ? sectionColor : ValoraAppearance.instance.card,
                      foregroundColor: _showPr02TechnicalTab ? Colors.black : ValoraAppearance.instance.textPrimary,
                    ),
                    onPressed: () => setState(() => _showPr02TechnicalTab = true),
                    child: Text('DATI TECNICI'),
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            if (!_showPr02TechnicalTab) ...[
              _pr11HeaderCard(_currentObject!),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DATI DELL’OGGETTO',
                      style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _masterDetails(_currentObject!),
                  ]),
                ),
              ),
            ] else
              _pr11TechnicalDetails(_currentObject!),
          ] else if (isHistory) ...[
            Text(
              _valueFor(_currentObject!, ['descrizione_oggetto', 'descrizione', 'nome'], 'Oggetto senza descrizione'),
              style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text('SCHEDA OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 18)),
            _objectCard(_currentObject!),
          ] else ...[
            Text('SCHEDA OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 18)),
            _objectCard(_currentObject!),
            ..._currentObject!.entries
                .where((e) => !const {
                      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
                      'immagine_principale', 'url_foto', 'foto', 'immagine',
                      'image', 'imageUrl', 'photo_url', 'main_image_url',
                    }.contains(e.key))
                .map((e) => _detailFieldCard(e.key, e.value)),
          ],
        ],
        if (isAvailableList && _rows.isNotEmpty) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sectionColor.withValues(alpha: 0.40)),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined, color: sectionColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('OGGETTI DISPONIBILI', style: TextStyle(
                  color: sectionColor, fontWeight: FontWeight.bold, letterSpacing: 0.5,
                )),
                const SizedBox(height: 4),
                Text('${_rows.length} ${_rows.length == 1 ? 'oggetto trovato' : 'oggetti trovati'}',
                  style: TextStyle(color: ValoraAppearance.instance.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('Seleziona una scheda per vedere tutti i dettagli.',
                  style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
              ])),
            ]),
          ),
        ],
        if (_rows.isNotEmpty) ...[
          const SizedBox(height: 16),
          if (!isAvailableList)
            Text(isHistory ? 'CRONOLOGIA EVENTI (${_rows.length})' : 'RISULTATI (${_rows.length})',
              style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ..._rows.map((r) {
            if (r is! Map) return Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(r.toString())));
            final item = Map<String, dynamic>.from(r);
            if (isHistory) return _historyCard(item);
            return _objectCard(item, availableStyle: isAvailableList, onTap: isAvailableList
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ObjectRuntimePage(
                      title: 'Visualizza scheda',
                      apiCode: 'OBJECT_MASTER',
                      initialObjectCode: int.tryParse(item['codice_oggetto']?.toString() ?? item['id']?.toString() ?? ''),
                    )
                  )).then((_) {})
              : null);
          }),
        ] else if (isAvailableList && !_loading) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: ValoraAppearance.instance.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: sectionColor.withValues(alpha: 0.28)),
            ),
            child: Column(children: [
              Icon(Icons.inventory_2_outlined, size: 42, color: sectionColor),
              const SizedBox(height: 12),
              const Text('Nessun oggetto da mostrare',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Premi “Visualizza elenco oggetti disponibili” per caricare l’elenco.',
                style: TextStyle(color: ValoraAppearance.instance.textSecondary), textAlign: TextAlign.center),
            ]),
          ),
        ],
        if (code != 'PR-01' && code != 'PR-02' && code != 'PR-03' && !isMaster && !isAvailableList && !isHistory) ...[
          const SizedBox(height: 16),
          Text('ESITO RUNTIME', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
            color: ValoraAppearance.instance.card, borderRadius: BorderRadius.circular(12)),
            child: SelectableText(_output, style: TextStyle(fontSize: 13))),
        ],
        if (!_isWrite) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: sectionColor,
                side: BorderSide(color: sectionColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('CHIUDI E TORNA AL BLOCCO DI APPARTENENZA'),
            ),
          ),
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

    final unitPriceLabel = _unitPrice.text.trim().isEmpty
        ? 'Non indicato'
        : '${_unitPrice.text.trim()} €';
    final totalValueLabel = _totalValue.text.trim().isEmpty
        ? 'Non indicato'
        : '${_totalValue.text.trim()} €';
    final marketValueLabel = _marketValue.text.trim().isEmpty
        ? 'Non indicato'
        : '${_marketValue.text.trim()} €';
    final notesLabel = _notes.text.trim().isEmpty ? 'Nessuna' : _notes.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma inserimento oggetto'),
        content: SingleChildScrollView(
          child: Text(
            'Descrizione: ${_description.text.trim()}\\n'
            'Produttore: ${_producer.text.trim()}\\n'
            'Linea / serie: ${_line.text.trim()}\\n'
            'Famiglia / categoria: ${_family.text.trim()}\\n'
            'Condizione: $_condition\\n'
            'Completezza: $_completeness\\n'
            'Destinazione: $_destination\\n'
            'Quantità: ${_quantity.text.trim()}\\n'
            'Prezzo unitario: $unitPriceLabel\\n'
            'Valore totale: $totalValueLabel\\n'
            'Valore di mercato stimato: $marketValueLabel\\n'
            'Note: $notesLabel\\n\\n'
            'Confermi il salvataggio di questo oggetto nel database TEST?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('CONFERMA E SALVA')),
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
        title: Text('Oggetto salvato'),
        content: Text('Vuoi inserire un altro oggetto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('NO, TORNA AL MENU')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('SÌ, NUOVO OGGETTO')),
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
        _metadataResult = 'La ricerca dei metadati è disponibile esclusivamente tramite PR-12.';
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
    ).join('\\n');
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
        title: Text('Conferma modifiche oggetto'),
        content: SingleChildScrollView(
          child: SelectableText(_pr02ConfirmationText(item)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('ANNULLA'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('CONFERMA DATI'),
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
        title: Text('Modifica confermata'),
        content: Text('Vuoi modificare un altro oggetto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('NO, SALVA E TERMINA'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('SÌ, MODIFICA UN ALTRO'),
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