import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pw_core;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

const String supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const String publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
String _valoraImageProxyUrl(String rawUrl) {
  final value = rawUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https') return value;
  const proxyHosts = {
    'www.gunpla-italia.com',
    'bandai-a.akamaihd.net',
    'cdn.media.amplience.net',
    'www.hasbropulse.com',
    'tf.takaratomy.co.jp',
    'www.hasbro.com',
    'www.fantamagus.com',
    'www.gamelife.it',
    'kurogami.com',
    'www.kurogami.com',
  };
  if (!proxyHosts.contains(uri.host.toLowerCase())) return value;
  return '${supabaseUrl}/functions/v1/collection-image-proxy?url=${Uri.encodeComponent(value)}';
}

const Color backgroundColor = Color(0xFF101010);
const Color cardColor = Color(0xFF1C1C1C);
const Color goldColor = Color(0xFFD6B15E);

class ValoraAppearance extends ChangeNotifier {
  ValoraAppearance._();
  static final instance = ValoraAppearance._();
  static const Map<String, Color> defaults = {
    'CATALOGO': Color(0xFF3978C5),
    'ACQUISTI': Color(0xFFC74444),
    'VENDITE': Color(0xFF39875B),
    'FLUSSI DI CASSA': Color(0xFFD6A83F),
    'VALUTAZIONI': Color(0xFF8556C7),
    'REPORT': Color(0xFFE17D35),
    'RICERCHE': Color(0xFF252525),
    'CONTROLLO': Color(0xFF777777),
    'COLLEZIONE': Color(0xFFD6B45C),
    'LEGO': Color(0xFFE31B23),
    'SAINT SEIYA': Color(0xFF7137B8),
    'MOTO DIE-CAST': Color(0xFFDD741D),
    'FUMETTI': Color(0xFF008C4A),
    'GUNDAM': Color(0xFFC62828),
    'TRANSFORMERS': Color(0xFF2476C8),
    'ALTRE COLLEZIONI': Color(0xFF466B87),
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
  bool useBlockLayout = false;
  final Map<String, String> imageUrls = {};
  final Map<String, String> imagePaths = {};
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
    whiteBackground = p.getBool('valora_white_background') ?? false; // Mantieni la scelta dell'utente.
    useBlockLayout = p.getBool('valora_block_layout') ?? false;
    imageUrls.clear();
    imagePaths.clear();
    for (final k in defaults.keys) {
      final url = p.getString('valora_image_url_$k');
      final path = p.getString('valora_image_path_$k');
      if (url != null && url.isNotEmpty) imageUrls[k] = url;
      if (path != null && path.isNotEmpty) imagePaths[k] = path;
    }
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
  Future<void> setLayout(bool blocks) async {
    useBlockLayout = blocks;
    final p = await SharedPreferences.getInstance();
    await p.setBool('valora_block_layout', blocks);
    notifyListeners();
  }
  Future<void> setSectionImage(String section, {String? url, String? path}) async {
    final p = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      imageUrls.remove(section);
      await p.remove('valora_image_url_$section');
    } else {
      imageUrls[section] = url.trim();
      await p.setString('valora_image_url_$section', url.trim());
    }
    if (path == null || path.trim().isEmpty) {
      imagePaths.remove(section);
      await p.remove('valora_image_path_$section');
    } else {
      imagePaths[section] = path.trim();
      await p.setString('valora_image_path_$section', path.trim());
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
    final p=await SharedPreferences.getInstance(); await p.setBool('valora_white_background', false);
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
  bool _uploading = false;
  final Map<String, TextEditingController> _urlControllers = {};
  @override void initState(){
    super.initState();
    a.addListener(refresh);
    for(final section in _allPersonalizableSections) {
      _urlControllers[section] = TextEditingController(text: a.imageUrls[section] ?? '');
    }
  }
  static const List<String> _allPersonalizableSections = [
    'COLLEZIONE','CATALOGO','ACQUISTI','VENDITE','FLUSSI DI CASSA',
    'VALUTAZIONI','REPORT','RICERCHE','CONTROLLO','LEGO','SAINT SEIYA',
    'MOTO DIE-CAST','FUMETTI','GUNDAM','TRANSFORMERS','ALTRE COLLEZIONI'
  ];
  void refresh(){
    if(!mounted)return;
    for(final section in _allPersonalizableSections) {
      final controller = _urlControllers[section];
      if(controller != null && !controller.text.trim().isNotEmpty && a.imageUrls[section] != null) {
        controller.text = a.imageUrls[section]!;
      }
    }
    setState((){});
  }
  Future<void> _uploadSectionImage(String section) async {
    setState(()=>_uploading=true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.image, allowMultiple: false, withData: true,
      );
      if(picked == null || picked.files.isEmpty) return;
      final file = picked.files.first;
      final bytes = file.bytes;
      if(bytes == null || bytes.isEmpty) throw Exception('Impossibile leggere il file immagine.');
      final ext = (file.extension ?? 'png').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final path = '${section.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}-${DateTime.now().millisecondsSinceEpoch}.${ext.isEmpty ? 'png' : ext}';
      final storage = Supabase.instance.client.storage.from('valora-section-images');
      await storage.uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      final url = storage.getPublicUrl(path);
      await a.setSectionImage(section, url: url, path: path);
      _urlControllers[section]?.text = url;
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Immagine aggiornata per $section.')));
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text('Caricamento non riuscito: $e. Verifica che esista il bucket pubblico valora-section-images in Supabase Storage.'),
        duration:const Duration(seconds:6),
      ));
    } finally {
      if(mounted) setState(()=>_uploading=false);
    }
  }
  @override void dispose(){
    a.removeListener(refresh);
    for(final c in _urlControllers.values){c.dispose();}
    super.dispose();
  }
  Widget _sectionImageEditor(String section) {
    final color=a.colorFor(section);
    final url=a.imageUrls[section];
    return Card(
      color:const Color(0xFF171717),
      child:Padding(
        padding:const EdgeInsets.all(12),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[
            Container(width:44,height:44,decoration:BoxDecoration(color:color.withValues(alpha:0.2),borderRadius:BorderRadius.circular(9)),
              clipBehavior:Clip.antiAlias,
              child:url==null?Icon(Icons.image_outlined,color:color,size:26):Image.network(_valoraImageProxyUrl(url),fit:BoxFit.cover,errorBuilder:(_,__,___)=>Icon(Icons.broken_image_outlined,color:color))),
            const SizedBox(width:10),
            Expanded(child:Text(section,style:TextStyle(color:color,fontWeight:FontWeight.bold))),
            IconButton(tooltip:'Carica immagine',onPressed:_uploading?null:()=>_uploadSectionImage(section),icon:const Icon(Icons.upload_file)),
          ]),
          const SizedBox(height:8),
          TextField(
            controller:_urlControllers[section],
            keyboardType:TextInputType.url,
            decoration:const InputDecoration(labelText:'URL immagine (opzionale)',hintText:'https://…',isDense:true,border:OutlineInputBorder()),
            onSubmitted:(value)=>a.setSectionImage(section,url:value),
          ),
          Row(children:[
            TextButton.icon(onPressed:()=>_uploadSectionImage(section),icon:const Icon(Icons.photo_library_outlined),label:const Text('Carica immagine')),
            const Spacer(),
            TextButton(onPressed:()async{
              _urlControllers[section]?.clear();
              await a.setSectionImage(section);
            },child:const Text('Ripristina')),
          ]),
        ]),
      ),
    );
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Personalizza VALORA')),
    body:ListView(padding:const EdgeInsets.all(16),children:[
      const Text('CONFIGURAZIONE HOME',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      SegmentedButton<bool>(
        segments:const [
          ButtonSegment<bool>(value:false,icon:Icon(Icons.view_agenda_outlined),label:Text('Schede')),
          ButtonSegment<bool>(value:true,icon:Icon(Icons.grid_view_rounded),label:Text('Blocchi')),
        ],
        selected:{a.useBlockLayout},
        onSelectionChanged:(values)=>a.setLayout(values.first),
      ),
      const SizedBox(height:8),
      const Text('La modalità iniziale è Schede con sfondo nero. Cambiare modalità modifica solo la presentazione, non le procedure o i dati.'),
      const SizedBox(height:20),
      const Text('SFONDO',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment<bool>(value:false, icon:Icon(Icons.dark_mode_outlined), label:Text('Nero')),
          ButtonSegment<bool>(value:true, icon:Icon(Icons.light_mode_outlined), label:Text('Bianco')),
        ],
        selected: <bool>{a.whiteBackground},
        onSelectionChanged:(values)=>a.setBackground(values.first),
        showSelectedIcon:true,
      ),
      const SizedBox(height:12),
      const Text('COLORI DELLE SEZIONI',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:4),
      const Text('Scegli il colore distintivo di ciascuna sezione.'),
      ...ValoraAppearance.defaults.keys.map((section){
        final current=a.colorFor(section);
        final available=ValoraAppearance.palette.where((c)=>c.value==current.value||
          !a.colors.entries.any((e)=>e.key!=section&&e.value.value==c.value)).toList();
        return Card(color:const Color(0xFF171717),child:Padding(
          padding:const EdgeInsets.symmetric(horizontal:12,vertical:6),
          child:Row(children:[
            Container(width:22,height:22,decoration:BoxDecoration(color:current,borderRadius:BorderRadius.circular(5))),
            const SizedBox(width:10),
            Expanded(child:Text(section,style:TextStyle(color:a.textPrimary))),
            DropdownButton<int>(value:current.value,items:available.map((c)=>DropdownMenuItem<int>(
              value:c.value,child:Row(children:[
                Container(width:20,height:20,decoration:BoxDecoration(color:c,borderRadius:BorderRadius.circular(4))),
                const SizedBox(width:8),Text('#${c.value.toRadixString(16).substring(2).toUpperCase()}')
              ]))).toList(),
              onChanged:(v){if(v!=null)a.setColor(section,Color(v));}),
          ])));
      }),
      const SizedBox(height:20),
      const Text('IMMAGINE PERSONALIZZATA PER SEZIONE',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:4),
      const Text('Carica un logo o una foto oppure incolla un URL. Il caricamento richiede il bucket pubblico valora-section-images in Supabase Storage.'),
      if(_uploading) const LinearProgressIndicator(),
      ..._allPersonalizableSections.map(_sectionImageEditor),
      const SizedBox(height:20),
      OutlinedButton.icon(onPressed:()async{
        await a.reset();
        for(final section in _allPersonalizableSections) {
          _urlControllers[section]?.text='';
          await a.setSectionImage(section);
        }
        await a.setLayout(false);
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Ripristinata la configurazione iniziale: Schede, sfondo nero.')));
      },icon:const Icon(Icons.restart_alt),label:const Text('RIPRISTINA CONFIGURAZIONE INIZIALE')),
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
    required this.icon, required this.color, this.menuTitle});
  final String title;
  final String? menuTitle;
  final String description;
  final IconData icon;
  final Color color;
}

const List<DashboardSection> dashboardSections = [
  DashboardSection(title: 'CATALOGO', description: 'Consulta e gestisci gli oggetti', icon: Icons.inventory_2_outlined, color: Color(0xFF3978C5)),
  DashboardSection(title: 'ACQUISTI', description: 'Gestione acquisti e allocazioni', icon: Icons.shopping_cart_outlined, color: Color(0xFFC74444)),
  DashboardSection(title: 'VENDITE', menuTitle: 'VENDITE E INSERZIONI', description: 'Vendite e inserzioni', icon: Icons.sell_outlined, color: Color(0xFF39875B)),
  DashboardSection(title: 'FLUSSI DI CASSA', description: 'Entrate, uscite e saldi', icon: Icons.account_balance_wallet_outlined, color: Color(0xFFD6A83F)),
  DashboardSection(title: 'VALUTAZIONI', description: 'VALORA e valore collezione', icon: Icons.query_stats, color: Color(0xFF8556C7)),
  DashboardSection(title: 'REPORT', description: 'Riepiloghi e risultati', icon: Icons.analytics_outlined, color: Color(0xFFE17D35)),
  DashboardSection(title: 'RICERCHE', description: 'Ricerca oggetti e fonti', icon: Icons.search, color: Color(0xFF252525)),
  DashboardSection(title: 'CONTROLLO', description: 'Stato e verifiche del sistema', icon: Icons.admin_panel_settings_outlined, color: Color(0xFF777777)),
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
    ProcedureEntry(title: 'Acquisti comparati', description: 'Confronta gli acquisti.', enabled: false),
    ProcedureEntry(title: 'Report acquisti', description: 'Riepilogo degli acquisti registrati.', apiCode: 'REPORT-PURCHASES'),
  ],
  'VENDITE': [
    ProcedureEntry(title: 'Nuova vendita', description: 'Registra una vendita.', apiCode: 'WRITE-PR-06', readOnly: false),
    ProcedureEntry(title: 'Nuova inserzione', description: 'Crea una nuova inserzione.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Modifica inserzione', description: 'Modifica un’inserzione esistente.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Chiudi inserzione', description: 'Chiude un’inserzione attiva.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Vendita multipla Vinted', description: 'Registra una vendita multipla.', enabled: false, readOnly: false),
    ProcedureEntry(title: 'Inserzioni attive', description: 'Consulta le inserzioni attive.', apiCode: 'REPORT-ACTIVE-LISTINGS'),
    ProcedureEntry(title: 'Report vendite', description: 'Riepilogo delle vendite registrate.', apiCode: 'REPORT-SALES'),
  ],
  'VALUTAZIONI': [
    ProcedureEntry(title: 'VALORA', description: 'Valutazione completa di un singolo oggetto, preparazione delle inserzioni e report.', apiCode: 'LAUNCH-VALORA'),
    ProcedureEntry(title: 'VALORE COLLEZIONE', description: 'Consulta il valore complessivo della collezione e i relativi riepiloghi.', apiCode: 'LAUNCH-COLLECTION-VALUE'),
    ProcedureEntry(title: 'VALUTA ACQUISTO', description: 'Analisi rapida di un acquisto prima di concluderlo. Motore in preparazione.', enabled: false),
  ],
  'FLUSSI DI CASSA': [
  ],
  'REPORT': [
    ProcedureEntry(title: 'Report per franchise / tema', description: 'Cerca in tutto il catalogo per descrizione, categoria collezionistica, tema e sottotema; esporta tutti i risultati.', apiCode: 'REPORT-COLLECTION-THEME'),
    ProcedureEntry(title: 'Flussi di cassa', description: 'Consulta entrate, uscite e saldo del periodo selezionato.', apiCode: 'REPORT-CASH'),
    ProcedureEntry(title: 'Report mattutino', description: 'Riepilogo operativo del mattino.', enabled: false),
  ],
  'RICERCHE': [
    ProcedureEntry(title: 'Ricerca oggetti', description: 'Cerca gli oggetti nel catalogo.', apiCode: 'READ-EXPLORE-RECORDS'),
    ProcedureEntry(title: 'PR-12 · Ricerca metadati in lotti', description: 'Analizza fino a 10 oggetti incompleti per lotto, mostra fonti e risultati senza modificare il database.', apiCode: 'PR-12-BATCH', readOnly: true),
    ProcedureEntry(title: 'REGISTRO FONTI · Gestisci cataloghi e siti', description: 'Consulta le fonti iniziali e aggiungi fonti specialistiche della tua nicchia collezionistica.', apiCode: 'SOURCE-REGISTRY', readOnly: false),
    ProcedureEntry(title: 'Le mie piattaforme di vendita', description: 'Aggiungi solo le piattaforme che utilizzi e attiva o disattiva ciascuna destinazione per le inserzioni VALORA.', apiCode: 'USER-SALES-PLATFORMS', readOnly: false),
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


class UserSalesPlatformsPage extends StatefulWidget {
  const UserSalesPlatformsPage({super.key});
  @override
  State<UserSalesPlatformsPage> createState() => _UserSalesPlatformsPageState();
}

class _UserSalesPlatformsPageState extends State<UserSalesPlatformsPage> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  List<Map<String, dynamic>> _platforms = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _message;
  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_userId == null) {
      setState(() { _loading = false; _error = 'Accedi per gestire le tue piattaforme.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await Supabase.instance.client.schema('collection')
          .from('piattaforme_utente').select()
          .eq('user_id', _userId!).order('creato_il');
      if (!mounted) return;
      setState(() {
        _platforms = (rows as List).whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Impossibile caricare le piattaforme: $e'; });
    }
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    final url = _url.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Inserisci il nome della piattaforma.');
      return;
    }
    if (_userId == null) {
      setState(() => _error = 'Sessione non valida. Accedi nuovamente.');
      return;
    }
    setState(() { _saving = true; _error = null; _message = null; });
    try {
      await Supabase.instance.client.schema('collection').from('piattaforme_utente').insert({
        'user_id': _userId,
        'nome_piattaforma': name,
        'url_piattaforma': url.isEmpty ? null : url,
        'utilizzata': true,
      });
      _name.clear();
      _url.clear();
      await _load();
      if (!mounted) return;
      setState(() { _saving = false; _message = 'Piattaforma aggiunta.'; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Non è stato possibile aggiungere la piattaforma. Verifica che non sia già presente. Dettaglio: $e';
      });
    }
  }

  Future<void> _toggle(Map<String, dynamic> platform, bool used) async {
    try {
      await Supabase.instance.client.schema('collection').from('piattaforme_utente')
          .update({'utilizzata': used, 'aggiornato_il': DateTime.now().toUtc().toIso8601String()})
          .eq('id', platform['id']).eq('user_id', _userId!);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Impossibile aggiornare la piattaforma: $e');
    }
  }

  Future<void> _delete(Map<String, dynamic> platform) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rimuovere la piattaforma?'),
        content: Text('Vuoi eliminare “${platform['nome_piattaforma']}” dal tuo elenco? Se vuoi solo sospenderla, disattiva il flag Utilizzata.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('RIMUOVI')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client.schema('collection').from('piattaforme_utente')
          .delete().eq('id', platform['id']).eq('user_id', _userId!);
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Impossibile rimuovere la piattaforma: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = ValoraAppearance.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('LE MIE PIATTAFORME')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Aggiungi soltanto i marketplace che utilizzi. VALORA preparerà le inserzioni solo per le piattaforme attive nel tuo elenco.',
          style: TextStyle(color: a.textSecondary)),
        const SizedBox(height: 16),
        TextField(controller: _name, textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nome piattaforma', hintText: 'Es. Vinted, eBay, Subito, Facebook Marketplace')),
        const SizedBox(height: 10),
        TextField(controller: _url, keyboardType: TextInputType.url,
          decoration: const InputDecoration(labelText: 'URL (facoltativo)', hintText: 'https://...')),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: _saving ? null : _add,
          icon: const Icon(Icons.add), label: Text(_saving ? 'SALVATAGGIO…' : 'AGGIUNGI PIATTAFORMA')),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 8),
          child: Text(_message!, style: TextStyle(color: a.textSecondary))),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 8),
          child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
        const SizedBox(height: 20),
        Text('PIATTAFORME CONFIGURATE', style: TextStyle(color: a.colorFor('RICERCHE'), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (!_loading && _platforms.isEmpty) Padding(padding: const EdgeInsets.all(16),
          child: Text('Non hai ancora aggiunto piattaforme. Inserisci la prima qui sopra.', style: TextStyle(color: a.textSecondary))),
        ..._platforms.map((p) {
          final used = p['utilizzata'] == true;
          return Card(child: ListTile(
            leading: Icon(Icons.storefront_outlined, color: used ? a.colorFor('RICERCHE') : a.textFaint),
            title: Text((p['nome_piattaforma'] ?? '').toString()),
            subtitle: Text(used ? 'Utilizzata: sì' : 'Utilizzata: no'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Switch(value: used, onChanged: (value) => _toggle(p, value)),
              IconButton(tooltip: 'Rimuovi', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(p)),
            ]),
          ));
        }),
      ]),
    );
  }
}

class SourceRegistryPage extends StatefulWidget {
  const SourceRegistryPage({super.key});
  @override
  State<SourceRegistryPage> createState() => _SourceRegistryPageState();
}

class _SourceRegistryPageState extends State<SourceRegistryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sources = [];
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await Supabase.instance.client.schema('collection')
          .from('registro_fonti').select()
          .order('priorita', ascending: true).order('nome');
      if (!mounted) return;
      setState(() {
        _sources = (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _editSource([Map<String, dynamic>? source]) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accedi per aggiungere fonti personali. Le fonti di sistema restano consultabili.')));
      return;
    }
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: (source?['nome'] ?? '').toString());
    final url = TextEditingController(text: (source?['url_base'] ?? '').toString());
    final category = TextEditingController(text: (source?['categoria'] ?? 'universale').toString());
    final market = TextEditingController(text: (source?['mercato'] ?? 'globale').toString());
    final maker = TextEditingController(text: (source?['marchio_editore'] ?? '').toString());
    final franchise = TextEditingController(text: (source?['franchise'] ?? '').toString());
    final note = TextEditingController(text: (source?['note'] ?? '').toString());
    var priority = int.tryParse((source?['priorita'] ?? 50).toString()) ?? 50;
    var type = (source?['tipo_fonte'] ?? 'specialistica').toString();
    var trustLevel = (source?['attendibilita_dichiarata'] ?? 'da_verificare').toString();
    final canEdit = source == null || (source['origine_configurazione'] == 'utente' && source['proprietario_utente'] == user.id);
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le fonti di sistema sono protette. Puoi aggiungere una tua fonte specialistica.')));
      return;
    }
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, updateDialog) => AlertDialog(
        title: Text(source == null ? 'AGGIUNGI FONTE SPECIALISTICA' : 'MODIFICA FONTE PERSONALE'),
        content: SizedBox(width: 520, child: SingleChildScrollView(child: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nome della fonte'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null),
            TextFormField(controller: url, decoration: const InputDecoration(labelText: 'URL del sito'), keyboardType: TextInputType.url, validator: (v) { final u = Uri.tryParse((v ?? '').trim()); return u == null || !{'http','https'}.contains(u.scheme) || u.host.isEmpty ? 'Inserisci un URL http/https valido' : null; }),
            TextFormField(controller: category, decoration: const InputDecoration(labelText: 'Categoria (es. orologi, LEGO, fumetti)')),
            TextFormField(controller: market, decoration: const InputDecoration(labelText: 'Mercato (es. Italia, Giappone, globale)')),
            TextFormField(controller: maker, decoration: const InputDecoration(labelText: 'Marchio / editore (facoltativo)')),
            TextFormField(controller: franchise, decoration: const InputDecoration(labelText: 'Linea / nicchia (facoltativo)')),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Tipo di fonte'),
              items: const [
                DropdownMenuItem(value: 'ufficiale', child: Text('Ufficiale')),
                DropdownMenuItem(value: 'specialistica', child: Text('Specialistica')),
                DropdownMenuItem(value: 'bibliografica', child: Text('Bibliografica')),
                DropdownMenuItem(value: 'comunita', child: Text('Comunità')),
                DropdownMenuItem(value: 'mercato', child: Text('Mercato')),
                DropdownMenuItem(value: 'personale', child: Text('Personale')),
              ],
              onChanged: (v) { if (v != null) updateDialog(() => type = v); },
            ),
            DropdownButtonFormField<String>(
              value: trustLevel,
              decoration: const InputDecoration(labelText: 'Attendibilità dichiarata (non verificata automaticamente)'),
              items: const [
                DropdownMenuItem(value: 'ufficiale', child: Text('Fonte ufficiale')),
                DropdownMenuItem(value: 'alta', child: Text('Alta')),
                DropdownMenuItem(value: 'media', child: Text('Media')),
                DropdownMenuItem(value: 'da_verificare', child: Text('Da verificare')),
              ],
              onChanged: (v) { if (v != null) updateDialog(() => trustLevel = v); },
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Priorità'),
              Expanded(child: Slider(value: priority.toDouble(), min: 1, max: 100, divisions: 99, label: '$priority', onChanged: (v) => updateDialog(() => priority = v.round()))),
              Text('$priority'),
            ]),
            TextFormField(controller: note, decoration: const InputDecoration(labelText: 'Note / cosa verifica questa fonte')),
            const SizedBox(height: 8),
            Text('La fonte verrà salvata come “da verificare”. Inserirla non significa che ogni dato trovato sia automaticamente attendibile.', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
          ]),
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () { if (formKey.currentState?.validate() == true) Navigator.pop(ctx, true); }, child: const Text('SALVA FONTE')),
        ],
      ),
    ));
    if (accepted != true) return;
    try {
      final data = <String, dynamic>{
        'nome': name.text.trim(), 'url_base': url.text.trim(),
        'categoria': category.text.trim().isEmpty ? 'universale' : category.text.trim(),
        'mercato': market.text.trim().isEmpty ? 'globale' : market.text.trim(),
        'marchio_editore': maker.text.trim().isEmpty ? null : maker.text.trim(),
        'franchise': franchise.text.trim().isEmpty ? null : franchise.text.trim(),
        'note': note.text.trim().isEmpty ? null : note.text.trim(),
        'tipo_fonte': type, 'priorita': priority,
        'attendibilita_dichiarata': trustLevel, 'stato_verifica': 'da_verificare',
      };
      final table = Supabase.instance.client.schema('collection').from('registro_fonti');
      if (source == null) {
        data.addAll({'origine_configurazione': 'utente', 'proprietario_utente': user.id, 'condivisa': false});
        await table.insert(data);
      } else {
        await table.update(data).eq('id', source['id']).eq('proprietario_utente', user.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fonte salvata. Stato: da verificare.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Salvataggio non riuscito: $e')));
    }
    name.dispose(); url.dispose(); category.dispose(); market.dispose(); maker.dispose(); franchise.dispose(); note.dispose();
  }

  Future<void> _toggleActive(Map<String, dynamic> source) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || source['origine_configurazione'] != 'utente' || source['proprietario_utente'] != user.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Puoi disattivare soltanto le tue fonti personali.')));
      return;
    }
    try {
      await Supabase.instance.client.schema('collection').from('registro_fonti')
          .update({'attiva': !(source['attiva'] == true)})
          .eq('id', source['id']).eq('proprietario_utente', user.id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Modifica non riuscita: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _sources.where((s) => query.isEmpty || ['nome','categoria','marchio_editore','franchise','mercato','url_base'].any((k) => (s[k] ?? '').toString().toLowerCase().contains(query))).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('REGISTRO FONTI'), actions: [
        IconButton(tooltip: 'Gestisci categorie e campi specialistici', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectibleCategoryRegistryPage())), icon: const Icon(Icons.category_outlined)),
        IconButton(tooltip: 'Aggiorna', onPressed: _load, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: 'Aggiungi fonte', onPressed: () => _editSource(), icon: const Icon(Icons.add_link)),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editSource(), icon: const Icon(Icons.add), label: const Text('AGGIUNGI FONTE')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.info_outline, size: 42), const SizedBox(height: 12),
            const Text('Registro non ancora disponibile'), const SizedBox(height: 8),
            SelectableText(_error!), const SizedBox(height: 12),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('RIPROVA')),
          ])))
        : Column(children: [
            Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Cerca fonte, marchio, categoria o mercato', border: OutlineInputBorder()))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: Text('${visible.length} fonti · le fonti personali sono modificabili; quelle di sistema sono protette. Le fonti iniziali sono da verificare prima di usarle come prova definitiva.', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12))),
            Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(12, 4, 12, 90), itemCount: visible.length, itemBuilder: (context, i) {
              final s = visible[i];
              final own = s['origine_configurazione'] == 'utente' && s['proprietario_utente'] == Supabase.instance.client.auth.currentUser?.id;
              final active = s['attiva'] == true;
              final title = (s['nome'] ?? 'Fonte senza nome').toString();
              final meta = ['${s['categoria'] ?? 'universale'}', '${s['mercato'] ?? 'globale'}', if ((s['marchio_editore'] ?? '').toString().isNotEmpty) s['marchio_editore'].toString(), if ((s['franchise'] ?? '').toString().isNotEmpty) s['franchise'].toString()].join(' · ');
              return Card(child: ListTile(
                leading: Icon(active ? Icons.travel_explore : Icons.pause_circle_outline, color: active ? ValoraAppearance.instance.colorFor('RICERCHE') : ValoraAppearance.instance.textFaint),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(meta), SelectableText((s['url_base'] ?? '').toString(), style: const TextStyle(fontSize: 12)),
                  Text('Priorità ${s['priorita'] ?? 50} · ${s['tipo_fonte'] ?? 'specialistica'} · ${s['stato_verifica'] ?? 'da_verificare'} · ${s['origine_configurazione'] ?? 'utente'}', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 11)),
                  if ((s['note'] ?? '').toString().isNotEmpty) Text(s['note'].toString()),
                ]),
                isThreeLine: true,
                trailing: own ? PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _editSource(s); if (v == 'toggle') _toggleActive(s); }, itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Modifica')),
                  PopupMenuItem(value: 'toggle', child: Text(active ? 'Disattiva' : 'Riattiva')),
                ]) : const Icon(Icons.verified_user_outlined),
              ));
            })),
          ]),
    );
  }
}

class CollectibleCategoryRegistryPage extends StatefulWidget {
  const CollectibleCategoryRegistryPage({super.key});
  @override
  State<CollectibleCategoryRegistryPage> createState() => _CollectibleCategoryRegistryPageState();
}

class _CollectibleCategoryRegistryPageState extends State<CollectibleCategoryRegistryPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Supabase.instance.client.schema('collection').from('registro_fonti_categorie').select().order('nome');
      if (!mounted) return;
      setState(() {
        _rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _addCategory() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accedi per aggiungere categorie personali.')));
      return;
    }
    final name = TextEditingController();
    final fields = TextEditingController(text: 'referenza, modello, anno, edizione, variante');
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('NUOVA CATEGORIA COLLEZIONISTICA'),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome categoria, es. Orologi Swatch')),
            const SizedBox(height: 10),
            TextField(controller: fields, maxLines: 3, decoration: const InputDecoration(labelText: 'Campi specialistici separati da virgola')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CREA CATEGORIA')),
        ],
      ),
    );
    if (accepted != true) { name.dispose(); fields.dispose(); return; }
    final categoryName = name.text.trim();
    final labels = fields.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci il nome della categoria.')));
      name.dispose(); fields.dispose(); return;
    }
    final schema = labels.map((label) {
      final key = label.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_');
      return <String, dynamic>{'key': key, 'label': label, 'type': 'text'};
    }).toList();
    try {
      await Supabase.instance.client.schema('collection').from('registro_fonti_categorie').insert({
        'nome': categoryName,
        'schema_campi': schema,
        'origine_configurazione': 'utente',
        'proprietario_utente': user.id,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categoria aggiunta. Puoi usarla nelle tue fonti.')));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Creazione categoria non riuscita: ' + e.toString())));
    }
    name.dispose();
    fields.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('CATEGORIE COLLEZIONISTICHE'), actions: [
      IconButton(onPressed: _load, tooltip: 'Aggiorna', icon: const Icon(Icons.refresh)),
    ]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _addCategory, icon: const Icon(Icons.add), label: const Text('NUOVA CATEGORIA')),
    body: _loading ? const Center(child: CircularProgressIndicator()) :
      _error != null ? Center(child: Padding(padding: const EdgeInsets.all(20), child: SelectableText(_error!))) :
      ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
        itemCount: _rows.length,
        itemBuilder: (context, i) {
          final row = _rows[i];
          final schema = row['schema_campi'] is List ? (row['schema_campi'] as List) : const [];
          final fields = schema.map((field) => field is Map ? (field['label'] ?? field['key'] ?? '').toString() : '').where((s) => s.isNotEmpty).join(' · ');
          final own = row['origine_configurazione'] == 'utente' && row['proprietario_utente'] == Supabase.instance.client.auth.currentUser?.id;
          return Card(child: ListTile(
            leading: Icon(Icons.category_outlined, color: ValoraAppearance.instance.colorFor('RICERCHE')),
            title: Text((row['nome'] ?? 'Categoria').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(fields.isEmpty ? 'Nessun campo specialistico configurato' : fields),
            trailing: Icon(own ? Icons.person_outline : Icons.lock_outline),
          ));
        },
      ),
  );
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
  Uint8List? _profileImageBytes;
  String? _profileImageName;
  String? _profileImageUrl;
  String? _profileImageStoragePath;
  bool _removeProfileImage = false;
  String _profileImageStatus = '';

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
      String? profilePhotoUrl;
      if (rows.isNotEmpty) {
        final storedPhoto = (rows.first['foto_profilo'] ?? '').toString().trim();
        if (storedPhoto.startsWith('http')) { profilePhotoUrl = storedPhoto; }
        else if (storedPhoto.isNotEmpty) { try { profilePhotoUrl = await client.storage.from('valora-profili-test').createSignedUrl(storedPhoto, 3600); } catch (_) {} }
      }
      if (!mounted) return false;
      setState(() {
        _markets = List<Map<String, dynamic>>.from(markets);
        if (rows.isNotEmpty) {
          final row = Map<String, dynamic>.from(rows.first);
          _name.text = (row['nome_utente'] ?? '').toString();
          _assistant.text = (row['nome_assistente'] ?? 'Demon').toString();
          _profileImageUrl = profilePhotoUrl;
          _profileImageStoragePath = (row['foto_profilo'] ?? '').toString().trim().isEmpty ? null : row['foto_profilo'].toString().trim();
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
      String? profileImagePath = _profileImageStoragePath;
      if (_profileImageBytes != null) {
        final fileName = (_profileImageName ?? 'profilo.jpg').replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
        final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
        final mime = switch (ext) { 'png' => 'image/png', 'webp' => 'image/webp', _ => 'image/jpeg' };
        final path = '${user.id}/profilo/${_uuid.v4()}.$ext';
        await client.storage.from('valora-profili-test').uploadBinary(path, _profileImageBytes!, fileOptions: FileOptions(contentType: mime, upsert: false));
        profileImagePath = path;
        _profileImageStoragePath = path;
      }
      if (_removeProfileImage) profileImagePath = null;
      final values = <String, dynamic>{
        'auth_user_id': user.id,
        'nome_utente': _name.text.trim(),
        'mercato_nazionale_principale': market['codice_mercato'],
        'valuta_predefinita': _currency.substring(0, 3),
        'lingua_interfaccia': const {'Italiano':'it','English':'en','Español':'es','Français':'fr'}[_language] ?? 'it',
        'formato_data': _dateFormat,
        'nome_assistente': _assistant.text.trim().isEmpty ? null : _assistant.text.trim(),
        'foto_profilo': profileImagePath,
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

  Future<void> _pickProfileImage() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
      if (!const ['jpg','jpeg','png','webp'].contains(ext)) throw Exception('Usa un file JPG, PNG o WEBP.');
      if (file.bytes == null || file.bytes!.isEmpty) throw Exception('Il file non contiene dati leggibili.');
      if (file.bytes!.length > 5 * 1024 * 1024) throw Exception('La foto supera il limite di 5 MB.');
      setState(() { _profileImageBytes = file.bytes; _profileImageName = file.name; _removeProfileImage = false; _profileImageStatus = 'Foto selezionata. Premi SALVA PROFILO per confermare.'; });
    } catch (e) { if (mounted) setState(() => _profileImageStatus = 'Caricamento non riuscito: $e'); }
  }

  Future<void> _removeProfilePhoto() async {
    setState(() { _profileImageBytes = null; _profileImageName = null; _profileImageUrl = null; _profileImageStoragePath = null; _removeProfileImage = true; _profileImageStatus = 'La foto verrà rimossa al salvataggio del profilo.'; });
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
              Center(child: Column(children: [
                Container(width: 104, height: 104,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldColor, width: 2)),
                  clipBehavior: Clip.antiAlias,
                  child: _profileImageBytes != null
                    ? Image.memory(_profileImageBytes!, fit: BoxFit.cover)
                    : (_profileImageUrl != null && _profileImageUrl!.startsWith('http')
                        ? Image.network(_profileImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, color: goldColor, size: 54))
                        : const Icon(Icons.person, color: goldColor, size: 54))),
                const SizedBox(height: 8),
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
                  OutlinedButton.icon(onPressed: _busy ? null : _pickProfileImage, icon: const Icon(Icons.upload_file), label: const Text('CARICA FOTO')),
                  if (_profileImageBytes != null || _profileImageUrl != null)
                    TextButton.icon(onPressed: _busy ? null : _removeProfilePhoto, icon: const Icon(Icons.delete_outline), label: const Text('RIMUOVI FOTO')),
                ]),
                if (_profileImageStatus.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_profileImageStatus, textAlign: TextAlign.center, style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12))),
              ])),
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

class ValoraServicePage extends StatefulWidget {
  const ValoraServicePage({super.key});
  @override
  State<ValoraServicePage> createState() => _ValoraServicePageState();
}

class _ValoraServicePageState extends State<ValoraServicePage> {
  bool _loading = true;
  bool _preparing = false;
  String? _error;
  List<Map<String, dynamic>> _objects = [];
  int? _selectedId;
  String _market = 'ITALIA';
  Map<String, dynamic>? _prepared;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  Future<void> _loadObjects() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Supabase.instance.client.schema('collection')
          .from('master_oggetti')
          .select('codice_oggetto,descrizione_oggetto,produttore,codice_prodotto,stato,condizione,completezza')
          .eq('destinazione', 'COLLEZIONE')
          .neq('archiviato_test', true)
          .order('descrizione_oggetto')
          .limit(500);
      final rows = (data as List).map((e) => Map<String, dynamic>.from(e as Map))
          .where((r) => !['VENDUTO','PERSO','DISTRUTTO','USCITO','ACCORPATO']
              .contains((r['stato'] ?? '').toString().toUpperCase())).toList();
      if (!mounted) return;
      setState(() { _objects = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossibile caricare gli oggetti della collezione: $e'; _loading = false; });
    }
  }

  Future<void> _prepareValuation() async {
    final id = _selectedId;
    if (id == null) {
      setState(() => _error = 'Seleziona prima un oggetto.');
      return;
    }
    setState(() { _preparing = true; _error = null; _prepared = null; });
    try {
      final response = await _ValoraRuntimeApi.call('consultation', {
        'session_id': null,
        'consultation_code': 'MARKET_VALUATION_PREPARE',
        'arguments': {'codice_oggetto': id, 'mercato_riferimento': _market},
      });
      if (!mounted) return;
      final result = response['result'];
      setState(() {
        _prepared = result is Map ? Map<String, dynamic>.from(result) : {'risultato': result};
        _preparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Preparazione non riuscita: $e'; _preparing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _objects.where((o) => o['codice_oggetto'] == _selectedId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('VALORA')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(18), children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF8556C7).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF8556C7)),
            ),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8556C7), size: 38),
              SizedBox(height: 12),
              Text('SERVIZIO VALORA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8556C7))),
              SizedBox(height: 8),
              Text('Seleziona un oggetto della collezione e prepara una richiesta di valutazione specialistica. La preparazione non equivale ancora a una stima di mercato conclusa.'),
            ]),
          ),
          const SizedBox(height: 18),
          Text('1. SELEZIONA L’OGGETTO', style: TextStyle(fontWeight: FontWeight.bold, color: ValoraAppearance.instance.textPrimary)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedId,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Oggetto da valutare'),
            items: _objects.map((o) => DropdownMenuItem<int>(
              value: (o['codice_oggetto'] as num).toInt(),
              child: Text('#${o['codice_oggetto']} · ${o['descrizione_oggetto'] ?? 'Senza descrizione'}', overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (value) => setState(() { _selectedId = value; _prepared = null; }),
          ),
          if (_objects.isEmpty) const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Non risultano oggetti disponibili nella destinazione COLLEZIONE.'),
          ),
          if (selected != null) Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(selected['descrizione_oggetto']?.toString() ?? 'Oggetto selezionato', style: const TextStyle(fontWeight: FontWeight.bold)),
              if ((selected['produttore'] ?? '').toString().isNotEmpty) Text('Produttore: ${selected['produttore']}'),
              if ((selected['codice_prodotto'] ?? '').toString().isNotEmpty) Text('Codice prodotto: ${selected['codice_prodotto']}'),
              Text('Condizione: ${selected['condizione'] ?? 'Non indicata'}'),
              Text('Completezza: ${selected['completezza'] ?? 'Non indicata'}'),
            ]),
          )),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _market,
            decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Mercato di riferimento'),
            items: const [
              DropdownMenuItem(value: 'ITALIA', child: Text('Italia')),
              DropdownMenuItem(value: 'EUROPA', child: Text('Europa')),
              DropdownMenuItem(value: 'MONDO', child: Text('Mondo')),
            ],
            onChanged: (value) => setState(() { _market = value ?? 'ITALIA'; _prepared = null; }),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _preparing || _selectedId == null ? null : _prepareValuation,
            icon: _preparing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
            label: Text(_preparing ? 'Preparazione in corso…' : 'PREPARA VALUTAZIONE'),
          ),
          if (_error != null) Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
          if (_prepared != null) Card(
            margin: const EdgeInsets.only(top: 16),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ESITO PREPARAZIONE', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('La richiesta è stata inviata al runtime. Questo esito non rappresenta ancora una valutazione di mercato definitiva né genera automaticamente inserzioni.'),
                const SizedBox(height: 8),
                SelectableText(_prepared.toString()),
              ],
            )),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _loadObjects, icon: const Icon(Icons.refresh), label: const Text('AGGIORNA OGGETTI')),
        ]),
    );
  }
}

class CollectionValuePage extends StatefulWidget {
  const CollectionValuePage({super.key});
  @override
  State<CollectionValuePage> createState() => _CollectionValuePageState();
}

class _CollectionValuePageState extends State<CollectionValuePage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  @override
  void initState() { super.initState(); _load(); }

  double? _num(dynamic value) => value == null ? null :
      value is num ? value.toDouble() : double.tryParse(value.toString());

  String _eur(double value) => '€ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Supabase.instance.client.schema('collection')
          .from('master_oggetti')
          .select('codice_oggetto,descrizione_oggetto,stato,quantita,valore_oggetto,valore_mercato')
          .eq('destinazione', 'COLLEZIONE')
          .neq('archiviato_test', true)
          .order('descrizione_oggetto');
      final rows = (data as List).map((e) => Map<String,dynamic>.from(e as Map))
          .where((r) => !['VENDUTO','PERSO','DISTRUTTO','USCITO','ACCORPATO']
              .contains((r['stato'] ?? '').toString().toUpperCase())).toList();
      if (!mounted) return;
      setState(() { _rows = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossibile leggere il catalogo: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    var market = 0.0, manual = 0.0;
    var units = 0, missing = 0;
    for (final r in _rows) {
      final q = (r['quantita'] as num?)?.toInt() ?? 1;
      units += q;
      final m = _num(r['valore_mercato']);
      final v = _num(r['valore_oggetto']);
      if (m == null) { missing++; } else { market += m * q; }
      if (v != null) manual += v * q;
    }
    Widget metric(String label, String value, IconData icon, Color color) => Card(
      child: ListTile(leading: Icon(icon, color: color), title: Text(label),
        subtitle: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18))),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('VALORE COLLEZIONE'),
        actions: [IconButton(tooltip: 'Aggiorna', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) :
        _error != null ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(
          mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12), FilledButton(onPressed: _load, child: const Text('Riprova'))])))
        : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('RIEPILOGO DEL PATRIMONIO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          const Text('Consultazione di sola lettura. Il valore commerciale resta separato dal costo storico; questa schermata non modifica oggetti o cassa.'),
          const SizedBox(height: 12),
          metric('Valore di mercato noto', _eur(market), Icons.trending_up, const Color(0xFF39875B)),
          metric('Valore manuale registrato', _eur(manual), Icons.edit_note, const Color(0xFF568DAD)),
          metric('Oggetti e unità', '${_rows.length} record · $units unità', Icons.inventory_2_outlined, const Color(0xFF8556C7)),
          metric('Oggetti senza stima di mercato', '$missing', Icons.hourglass_empty, const Color(0xFFE17D35)),
          const SizedBox(height: 12),
          const Text('DETTAGLIO OGGETTI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 6),
          if (_rows.isEmpty) const Card(child: ListTile(title: Text('Nessun oggetto destinato alla collezione.'))),
          ..._rows.map((r) {
            final q = (r['quantita'] as num?)?.toInt() ?? 1;
            final m = _num(r['valore_mercato']);
            final v = _num(r['valore_oggetto']);
            final label = m != null ? 'Mercato: ${_eur(m*q)}' :
                v != null ? 'Valore manuale: ${_eur(v*q)}' : 'Stima di mercato non disponibile';
            return Card(child: ListTile(
              title: Text((r['descrizione_oggetto'] ?? 'Oggetto senza descrizione').toString()),
              subtitle: Text('ID ${r['codice_oggetto']} · Quantità $q\n$label'),
              isThreeLine: true,
            ));
          }),
          const SizedBox(height: 10),
          Text('Le stime automatiche e l’aggiornamento mensile saranno collegati al motore di valutazione in un passaggio separato, dopo il collaudo.',
            style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
        ])),
    );
  }
}


class ValoraAssistantPage extends StatefulWidget {
  const ValoraAssistantPage({super.key, this.screenContext = 'Dashboard'});
  final String screenContext;
  @override
  State<ValoraAssistantPage> createState() => _ValoraAssistantPageState();
}

class _ValoraAssistantPageState extends State<ValoraAssistantPage> {
  final _textController = TextEditingController();
  final _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  bool _working = false;
  String _answer = '';
  String _status = 'Scrivi oppure premi il microfono per impartire un comando.';
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    try {
      final ready = await _speech.initialize(
        onStatus: (status) { if (mounted) setState(() => _listening = status == 'listening'); },
        onError: (error) { if (mounted) setState(() => _status = 'Microfono: ${error.errorMsg}'); },
      );
      if (mounted) setState(() {
        _speechReady = ready;
        _status = ready
          ? 'Assistente pronto. Puoi parlare in italiano.'
          : 'Riconoscimento vocale non disponibile: puoi comunque scrivere il comando.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Microfono non disponibile: $e');
    }
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      await _initializeSpeech();
      if (!_speechReady) return;
    }
    setState(() { _status = 'Ti ascolto…'; _listening = true; });
    await _speech.listen(
      localeId: 'it_IT',
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
          if (result.finalResult) {
            _status = 'Comando riconosciuto. Controllalo e premi ESEGUI.';
            _listening = false;
          }
        });
      },
    );
  }

  Future<void> _sendCommand() async {
    final command = _textController.text.trim();
    if (command.isEmpty || _working) return;
    setState(() { _working = true; _answer = ''; _status = 'ChatGPT sta elaborando il comando…'; });
    _history.add({'ruolo': 'utente', 'testo': command});
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'valora-assistant',
        body: {
          'comando': command,
          'schermata_corrente': widget.screenContext,
          'cronologia': _history.take(12).toList(),
          'modalita': 'TEST',
          'sola_lettura': true,
        },
      );
      final data = response.data;
      if (data is Map && data['ok'] == true) {
        final answer = (data['risposta'] ?? data['message'] ?? '').toString();
        setState(() {
          _answer = answer.isEmpty ? 'Risposta ricevuta senza testo.' : answer;
          _status = 'Risposta completata. Nessuna modifica al database è stata eseguita.';
        });
        _history.add({'ruolo': 'assistente', 'testo': _answer});
      } else {
        final detail = data is Map ? (data['error'] ?? data['message'] ?? 'Risposta non valida').toString() : 'Risposta non valida dal servizio.';
        setState(() { _answer = detail; _status = 'Servizio IA non disponibile.'; });
      }
    } on FunctionException catch (e) {
      setState(() {
        _answer = 'Il servizio ChatGPT di VALORA non è ancora configurato o ha restituito un errore. Dettaglio: ${e.details ?? e.reasonPhrase ?? e.status}';
        _status = 'Verifica la configurazione del motore IA.';
      });
    } catch (e) {
      setState(() {
        _answer = 'Non è stato possibile contattare il motore IA: $e';
        _status = 'Comando non eseguito.';
      });
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ASSISTENTE VALORA')),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.psychology_alt_outlined, color: goldColor, size: 44),
            const SizedBox(height: 8),
            const Text('Parla con VALORA', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('L’assistente riceve il contesto della schermata: ${widget.screenContext}. In questa fase i comandi sono in sola lettura.',
              textAlign: TextAlign.center, style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              minLines: 2,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Comando vocale o scritto',
                hintText: 'Esempio: cerca il prodotto esatto del record 7 e confronta le fonti',
                prefixIcon: Icon(Icons.chat_bubble_outline),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: _working ? null : _toggleListening,
                icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic),
                label: Text(_listening ? 'FERMA ASCOLTO' : 'PARLA'),
              )),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                onPressed: _working ? null : _sendCommand,
                icon: _working
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
                label: const Text('ESEGUI'),
              )),
            ]),
            const SizedBox(height: 10),
            Text(_status, style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12)),
          ],
        ))),
        if (_answer.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(_answer))),
        const SizedBox(height: 8),
        Text('SICUREZZA: in questa versione l’assistente non salva, cancella o modifica record. Le azioni sui dati richiederanno conferma esplicita.',
          style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12)),
      ],
    )),
  );
}

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  DashboardSection? selectedSection;
  bool showCollection = false;
  bool _catalogLoading = true;
  List<Map<String, dynamic>> _catalogRows = [];
  String? _catalogError;
  final Map<int, String> _dashboardImageUrls = {};
  final Set<int> _dashboardImageLookups = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardCatalog();
  }

  Future<void> _loadDashboardCatalog() async {
    try {
      final response = await Supabase.instance.client.schema('collection').rpc(
        'pr_11_ricerca_schede', params: {'p_cerca': null},
      );
      dynamic payload = response;
      if (payload is List && payload.length == 1 && payload.first is Map) {
        payload = payload.first;
      }
      if (payload is! Map || payload['oggetti'] is! List) {
        throw Exception('Risposta catalogo non valida.');
      }
      final rows = (payload['oggetti'] as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      if (mounted) setState(() { _catalogRows = rows; _catalogLoading = false; });
      await _loadDashboardImages(rows);
    } catch (e) {
      if (mounted) setState(() { _catalogError = '$e'; _catalogLoading = false; });
    }
  }

  Future<void> _loadDashboardImages(List<Map<String, dynamic>> rows, {bool retryFailed = false}) async {
    // Prima usa l'URL catalografico di PR-12 salvato in master_metadati.
    // Il registro immagini/Storage è un fallback, non l'unica sorgente.
    final selected = <Map<String, dynamic>>[];
    for (final category in ['LEGO', 'SAINT SEIYA', 'MOTO DIE-CAST', 'FUMETTI', 'GUNDAM', 'TRANSFORMERS', 'ALTRE COLLEZIONI']) {
      selected.addAll(rows.where((row) => _dashboardCategory(row) == category).take(5));
    }
    final ids = selected.map((row) => int.tryParse(
      (row['codice_oggetto'] ?? row['id'] ?? '').toString(),
    )).whereType<int>().where((id) => id > 0 &&
      (retryFailed || !_dashboardImageLookups.contains(id))).toSet();
    if (ids.isEmpty) return;

    // Segna come tentati solo dopo il tentativo. Un errore non deve bloccare
    // futuri recuperi quando la schermata viene aggiornata.
    await Future.wait(ids.map((id) async {
      var resolved = false;
      try {
        final metadata = await Supabase.instance.client
            .schema('collection')
            .from('master_metadati')
            .select('url_immagine')
            .eq('codice_oggetto', id)
            .maybeSingle();
        final catalogUrl = (metadata?['url_immagine'] ?? '').toString().trim();
        if (catalogUrl.startsWith('https://') || catalogUrl.startsWith('http://')) {
          _dashboardImageUrls[id] = catalogUrl;
          resolved = true;
        }
      } catch (e) {
        debugPrint('VALORA: URL catalografico non disponibile per $id: $e');
      }

      if (!resolved) {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          final response = await Supabase.instance.client.functions.invoke(
            'collection-object-images-test',
            headers: session == null ? null : {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'action': 'get', 'codice_oggetto': id},
          );
          if (response.status >= 200 && response.status < 300 && response.data is Map) {
            final data = Map<String, dynamic>.from(response.data as Map);
            final url = (data['signed_url'] ?? data['url'] ?? data['image_url'] ?? '').toString().trim();
            if (url.startsWith('https://') || url.startsWith('http://')) {
              _dashboardImageUrls[id] = url;
              resolved = true;
            }
          }
        } catch (e) {
          debugPrint('VALORA: immagine registro non disponibile per $id: $e');
        }
      }
      if (resolved) {
        _dashboardImageLookups.add(id);
      } else {
        _dashboardImageLookups.remove(id);
      }
    }));
    if (mounted) setState(() {});
  }

  Future<void> _retryDashboardImages() async {
    await _loadDashboardImages(_catalogRows, retryFailed: true);
  }

  // Se l'URL catalografico fallisce nella UI, prova le sorgenti alternative
  // senza riproporre lo stesso URL non funzionante.
  Future<void> _retryDashboardImageAfterFailure(
    Map<String, dynamic> row, String failedUrl,
  ) async {
    final id = int.tryParse((row['codice_oggetto'] ?? row['id'] ?? '').toString());
    if (id == null || id <= 0 || failedUrl.isEmpty) return;
    if (_dashboardImageUrls[id] != failedUrl) return;

    var replacementUrl = '';
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final response = await Supabase.instance.client.functions.invoke(
        'collection-object-images-test',
        headers: session == null ? null : {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'action': 'get', 'codice_oggetto': id},
      );
      if (response.status >= 200 && response.status < 300 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final candidate = (data['signed_url'] ?? data['url'] ?? data['image_url'] ?? '').toString().trim();
        if ((candidate.startsWith('https://') || candidate.startsWith('http://')) &&
            candidate != failedUrl) {
          replacementUrl = candidate;
        }
      }
    } catch (e) {
      debugPrint('VALORA: fallback immagine dashboard non disponibile per $id: $e');
    }

    // Ultimo tentativo con il registro immagini, ignorando l'URL che ha fallito.
    if (replacementUrl.isEmpty) {
      try {
        final rows = await Supabase.instance.client
            .schema('collection')
            .from('immagini_oggetto')
            .select('riferimento_immagine, url_fonte, immagine_principale')
            .eq('codice_oggetto', id)
            .order('immagine_principale', ascending: false)
            .limit(10);
        for (final imageRow in rows) {
          for (final key in ['riferimento_immagine', 'url_fonte']) {
            final candidate = (imageRow[key] ?? '').toString().trim();
            if ((candidate.startsWith('https://') || candidate.startsWith('http://')) &&
                candidate != failedUrl) {
              replacementUrl = candidate;
              break;
            }
          }
          if (replacementUrl.isNotEmpty) break;
        }
      } catch (e) {
        debugPrint('VALORA: registro immagini dashboard non disponibile per $id: $e');
      }
    }

    if (!mounted || replacementUrl.isEmpty || _dashboardImageUrls[id] != failedUrl) return;
    setState(() {
      _dashboardImageUrls[id] = replacementUrl;
      _dashboardImageLookups.add(id);
    });
  }

  String _dashboardDescription(Map<String, dynamic> row) =>
      (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome'] ?? '').toString();

  String _dashboardCategory(Map<String, dynamic> row) {
    final d = _dashboardDescription(row).toLowerCase();
    if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(d)) return 'LEGO';
    if (RegExp(r'saint seiya|myth cloth|cavalieri dello zodiaco').hasMatch(d)) return 'SAINT SEIYA';
    if (RegExp(r'maisto|die.?cast|modellin|ducati panigale|yamaha r1|kawasaki ninja').hasMatch(d)) return 'MOTO DIE-CAST';
    if (RegExp(r'fumett|comic|manga|panini|salda.?press|dragon ball|one piece|tex|batman').hasMatch(d)) return 'FUMETTI';
    if (RegExp(r'gundam|gunpla|rx-78|wing zero|sazabi').hasMatch(d)) return 'GUNDAM';
    if (RegExp(r'transformers|autobot|decepticon|optimus prime|bumblebee').hasMatch(d)) return 'TRANSFORMERS';
    return 'ALTRE COLLEZIONI';
  }

  String? _dashboardImageUrl(Map<String, dynamic> row) {
    final id = int.tryParse((row['codice_oggetto'] ?? row['id'] ?? '').toString());
    if (id != null && _dashboardImageUrls.containsKey(id)) return _dashboardImageUrls[id];
    for (final key in ['image_url', 'immagine_url', 'foto_url', 'url_immagine', 'image', 'foto']) {
      final value = row[key];
      if (value is String && (value.startsWith('https://') || value.startsWith('http://'))) return value;
    }
    return null;
  }

  Widget _categoryBrandMark(String category, Color color, IconData fallbackIcon) {
    final base = category.toUpperCase();
    if (base == 'LEGO') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFD71920),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFFFD54F), width: 2),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: const Text('LEGO', style: TextStyle(
          color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900,
          letterSpacing: -1.2, shadows: [Shadow(color: Colors.black54, offset: Offset(1, 2), blurRadius: 1)],
        )),
      );
    }
    if (base == 'TRANSFORMERS') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF174A8B), Color(0xFF101820)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF6DB8FF), width: 1.4),
        ),
        child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.shield_outlined, color: Color(0xFF6DB8FF), size: 19),
          Text('TRANSFORMERS', maxLines: 1, style: TextStyle(
            color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w900, letterSpacing: 0.2,
          )),
        ]),
      );
    }
    if (base == 'GUNDAM') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F0E8),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF3B6EA8), width: 2),
        ),
        child: const Text('GUNDAM', style: TextStyle(
          color: Color(0xFF164B8C), fontSize: 11, fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        )),
      );
    }
    if (base == 'FUMETTI') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFFD54F),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        child: const Stack(alignment: Alignment.center, children: [
          Icon(Icons.menu_book_rounded, color: Color(0xFF17202A), size: 29),
          Positioned(right: 3, top: 1, child: Icon(Icons.bolt, color: Color(0xFFD71920), size: 17)),
        ]),
      );
    }
    if (base == 'SAINT SEIYA') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4C237E), Color(0xFF171024)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFD7B56D), width: 1.4),
        ),
        child: const Icon(Icons.auto_awesome, color: Color(0xFFFFD76A), size: 30),
      );
    }
    if (base == 'MOTO DIE-CAST') {
      return Container(
        width: 62, height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF7D19), Color(0xFF9D3C0B)]),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFFFC078), width: 1.2),
        ),
        child: const Icon(Icons.two_wheeler, color: Colors.white, size: 31),
      );
    }
    return Container(
      width: 62, height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color, width: 1.3),
      ),
      child: Icon(fallbackIcon, color: color, size: 27),
    );
  }

  Widget _dashboardCategoryPanel(String category, String subtitle, Color color, IconData icon) {
    final rows = _catalogRows.where((r) => _dashboardCategory(r) == category).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _categoryBrandMark(category, color, icon),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Text('${rows.length} record', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CategoryObjectSearchPage(initialQuery: category))),
              style: TextButton.styleFrom(foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 7)),
              child: const Text('VEDI TUTTI', style: TextStyle(fontSize: 10)),
            ),
          ]),
          if (_catalogLoading)
            const Padding(padding: EdgeInsets.all(14), child: LinearProgressIndicator())
          else if (rows.isEmpty)
            const Padding(padding: EdgeInsets.fromLTRB(4, 10, 4, 5),
              child: Text('Nessun record riconosciuto in questa categoria.', style: TextStyle(color: Colors.white70, fontSize: 12)))
          else
            SizedBox(height: 118, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rows.length > 5 ? 5 : rows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final row = rows[index];
                final url = _dashboardImageUrl(row);
                return SizedBox(width: 98, child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ObjectRuntimePage(
                    title: 'Scheda oggetto', apiCode: 'OBJECT_MASTER',
                    initialObjectCode: int.tryParse((row['codice_oggetto'] ?? row['id'] ?? '').toString()),
                  ))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(height: 75, width: 98,
                      decoration: BoxDecoration(color: const Color(0xFF111111), borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: Colors.white24)),
                      clipBehavior: Clip.antiAlias,
                      child: url == null
                        ? Icon(icon, color: color.withValues(alpha: 0.9), size: 34)
                        : Image.network(_valoraImageProxyUrl(url), fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              _retryDashboardImageAfterFailure(row, url);
                              return Icon(icon, color: color, size: 34);
                            })),
                    const SizedBox(height: 4),
                    Text(_dashboardDescription(row), maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.1)),
                  ]),
                ));
              },
            )),
        ]),
      ),
    );
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) setState(() { selectedSection = null; showCollection = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          leading: selectedSection == null && !showCollection ? null : IconButton(
            tooltip: 'Torna alla dashboard',
            onPressed: () => setState(() { selectedSection = null; showCollection = false; }),
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
        body: SafeArea(child: showCollection
            ? buildCollection()
            : selectedSection == null
                ? buildDashboard()
                : buildSection(selectedSection!)),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'valora_global_assistant',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ValoraAssistantPage(screenContext: selectedSection?.title ?? 'Dashboard'),
          )),
          icon: const Icon(Icons.mic_none),
          label: const Text('ASSISTENTE'),
        ),
      );

  Widget _menuCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    String? trailingText,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.85), width: 1.25),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: (ValoraAppearance.instance.imageUrls[title] ?? ValoraAppearance.instance.imageUrls[title == 'VENDITE E INSERZIONI' ? 'VENDITE' : title]) is String &&
                      ((ValoraAppearance.instance.imageUrls[title] ?? ValoraAppearance.instance.imageUrls[title == 'VENDITE E INSERZIONI' ? 'VENDITE' : title])?.isNotEmpty ?? false)
                  ? Image.network(
                      (ValoraAppearance.instance.imageUrls[title] ?? ValoraAppearance.instance.imageUrls[title == 'VENDITE E INSERZIONI' ? 'VENDITE' : title])!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 27),
                    )
                  : Icon(icon, color: color, size: 27),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
            if (trailingText != null) ...[
              const SizedBox(width: 6),
              Text(trailingText, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(width: 5),
            Icon(Icons.chevron_right, color: color, size: 29),
          ]),
        ),
      ),
    ),
  );

  Widget buildDashboard() {
    if (ValoraAppearance.instance.useBlockLayout) {
      return LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 3 : 2;
        final entries = <Map<String, dynamic>>[
          {'title':'COLLEZIONE','subtitle':'Tutti i temi e tutti i record','color':goldColor,'icon':Icons.inventory_2_outlined,'tap':() => setState(() => showCollection=true)},
          ...dashboardSections.map((section)=> {
            'title':section.menuTitle ?? section.title,
            'subtitle':section.description,
            'color':ValoraAppearance.instance.colorFor(section.title),
            'icon':section.icon,
            'tap':() => setState(()=>selectedSection=section),
          }),
        ];
        return GridView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: entries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth < 600 ? 0.98 : 1.18,
          ),
          itemBuilder: (context,index) {
            final entry=entries[index];
            final title=entry['title'] as String;
            final color=entry['color'] as Color;
            final icon=entry['icon'] as IconData;
            final url=ValoraAppearance.instance.imageUrls[title] ??
              ValoraAppearance.instance.imageUrls[title=='VENDITE E INSERZIONI'?'VENDITE':title];
            return Material(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(15),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: entry['tap'] as VoidCallback,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(borderRadius:BorderRadius.circular(15),border:Border.all(color:color,width:1.4)),
                  child: Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                    Expanded(child:ClipRRect(
                      borderRadius:BorderRadius.circular(11),
                      child:url!=null && url.isNotEmpty
                        ? Image.network(_valoraImageProxyUrl(url),fit:BoxFit.contain,width:double.infinity,errorBuilder:(_,__,___)=>Icon(icon,color:color,size:42))
                        : Icon(icon,color:color,size:42),
                    )),
                    const SizedBox(height:8),
                    Text(title,textAlign:TextAlign.center,style:TextStyle(color:color,fontWeight:FontWeight.bold,fontSize:12)),
                    const SizedBox(height:4),
                    if(title=='COLLEZIONE') Text(_catalogLoading?'…':'${_catalogRows.length} record',style:const TextStyle(color:Colors.white70,fontSize:10)),
                    Icon(Icons.chevron_right,color:color,size:23),
                  ]),
                ),
              ),
            );
          },
        );
      });
    }
    return ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(2, 4, 2, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CENTRO OPERATIVO', style: TextStyle(color: goldColor, fontSize: 21, fontWeight: FontWeight.bold, letterSpacing: 1.3)),
          SizedBox(height: 5),
          Text('Scegli una sezione per accedere alle relative funzioni.', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
      ),
      _menuCard(
        title: 'COLLEZIONE',
        subtitle: 'Tutti i temi e tutti i record della tua collezione',
        color: goldColor,
        icon: Icons.inventory_2_outlined,
        trailingText: _catalogLoading ? '…' : '${_catalogRows.length} record',
        onTap: () => setState(() => showCollection = true),
      ),
      ...dashboardSections.map((section) => _menuCard(
        title: section.menuTitle ?? section.title,
        subtitle: section.description,
        color: ValoraAppearance.instance.colorFor(section.title),
        icon: section.icon,
        onTap: () => setState(() => selectedSection = section),
      )),
      if (_catalogError != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Conteggio catalogo non disponibile: $_catalogError', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12)),
        ),
      const SizedBox(height: 12),
      const Center(child: Text('COLLECTION by VALORA', style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1))),
    ],
  );
  }

  Widget buildCollection() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          const Icon(Icons.inventory_2_outlined, color: goldColor, size: 34),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COLLEZIONE', style: TextStyle(color: goldColor, fontSize: 21, fontWeight: FontWeight.bold)),
            SizedBox(height: 3),
            Text('Seleziona un tema per consultare i relativi oggetti.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Text(_catalogLoading ? '…' : '${_catalogRows.length}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
        ]),
      ),
      if (_catalogError != null)
        Container(
          margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF3B1717), borderRadius: BorderRadius.circular(10)),
          child: Text('Catalogo non disponibile: $_catalogError', style: const TextStyle(color: Colors.white)),
        ),
      _dashboardCategoryPanel('LEGO', 'Mattoncini, set, minifigure e collezioni', const Color(0xFFE31B23), Icons.extension),
      _dashboardCategoryPanel('SAINT SEIYA', 'Myth Cloth, personaggi e accessori', const Color(0xFF7137B8), Icons.shield_outlined),
      _dashboardCategoryPanel('MOTO DIE-CAST', 'Modellini in scala, marchi e serie', const Color(0xFFDD741D), Icons.two_wheeler),
      _dashboardCategoryPanel('FUMETTI', 'Manga, comics e collezioni', const Color(0xFF008C4A), Icons.menu_book_outlined),
      _dashboardCategoryPanel('GUNDAM', 'Gunpla, modelli e action figure', const Color(0xFFC62828), Icons.smart_toy_outlined),
      _dashboardCategoryPanel('TRANSFORMERS', 'Autobot, Decepticon e personaggi', const Color(0xFF2476C8), Icons.smart_toy_outlined),
      _dashboardCategoryPanel('ALTRE COLLEZIONI', 'Tutti gli altri oggetti catalogati', const Color(0xFF466B87), Icons.category_outlined),
    ],
  );

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
                      : procedure.apiCode == 'SOURCE-REGISTRY'
                  ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SourceRegistryPage()))
                  : procedure.apiCode == 'USER-SALES-PLATFORMS'
                      ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UserSalesPlatformsPage()))
                      : procedure.apiCode == 'LAUNCH-VALORA'
                          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ValoraServicePage()))
                          : procedure.apiCode == 'LAUNCH-COLLECTION-VALUE'
                              ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectionValuePage()))
                              : procedure.apiCode == 'WRITE-PR-04'
                          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewPurchasePage()))
                          : procedure.apiCode == 'WRITE-PR-05'
                               ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditPurchasePage()))
                               : procedure.apiCode != null
                      ? () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => procedure.apiCode == 'PR-12-BATCH' ? const Pr12BatchPage() : ObjectRuntimePage(title: procedure.title, apiCode: procedure.apiCode!)))
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
  const CategoryObjectSearchPage({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<CategoryObjectSearchPage> createState() => _CategoryObjectSearchPageState();
}

class _CategoryObjectSearchPageState extends State<CategoryObjectSearchPage> {
  final TextEditingController _query = TextEditingController();
  bool _loading = false;
  String _message = 'Inserisci una categoria o una dicitura, per esempio TRANSFORMERS.';
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) {
      _query.text = initial;
      _message = 'Apertura automatica della categoria $initial…';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  String _description(Map<String, dynamic> row) =>
      (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome'] ?? '').toString();

  String _code(Map<String, dynamic> row) => (row['codice_oggetto'] ?? '').toString();

  bool _matchesInitialCategory(Map<String, dynamic> row, String category) {
    final d = _description(row).toLowerCase();
    switch (category.toUpperCase()) {
      case 'LEGO':
        return RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(d);
      case 'SAINT SEIYA':
        return RegExp(r'saint seiya|myth cloth|cavalieri dello zodiaco').hasMatch(d);
      case 'MOTO DIE-CAST':
        return RegExp(r'maisto|die.?cast|modellin|ducati panigale|yamaha r1|kawasaki ninja|aprilia rsv|honda vtr').hasMatch(d);
      case 'FUMETTI':
        return RegExp(r'fumett|comic|manga|panini|salda.?press|dragon ball|one piece|tex|batman').hasMatch(d);
      case 'GUNDAM':
        return RegExp(r'gundam|gunpla|rx-78|wing zero|sazabi').hasMatch(d);
      case 'TRANSFORMERS':
        return RegExp(r'transformers|autobot|decepticon|optimus prime|bumblebee').hasMatch(d);
      case 'ALTRE COLLEZIONI':
        return !['LEGO', 'SAINT SEIYA', 'MOTO DIE-CAST', 'FUMETTI', 'GUNDAM', 'TRANSFORMERS']
            .any((name) => _matchesInitialCategory(row, name));
      default:
        return d.contains(category.toLowerCase());
    }
  }

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
      final categoryMode = widget.initialQuery?.trim().isNotEmpty ?? false;
      final response = await Supabase.instance.client.schema('collection').rpc(
        'pr_11_ricerca_schede',
        params: {'p_cerca': categoryMode ? null : query},
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
          .where((row) => categoryMode
              ? _matchesInitialCategory(row, widget.initialQuery!.trim())
              : _description(row).toLowerCase().contains(normalizedQuery))
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
  PlatformFile? _selectedImportFile;
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
    // Procedura di lettura dedicata del file_picker: il plugin recupera il
    // contenuto anche quando il picker non popola bytes o non espone un path
    // direttamente leggibile (ad esempio documenti forniti da Android SAF).
    late final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      int declaredSize = file.size;
      try {
        final path = file.path;
        if (path != null && path.trim().isNotEmpty) {
          final localFile = File(path);
          if (await localFile.exists()) declaredSize = await localFile.length();
        }
      } catch (_) {
        // Conserva la dimensione dichiarata dal selettore.
      }
      throw Exception('Impossibile leggere il file "${file.name}" (dimensione dichiarata: $declaredSize byte). Il selettore lo ha individuato ma file_picker non è riuscito a recuperarne il contenuto. Dettaglio tecnico: $e');
    }
    if (bytes.isEmpty) {
      throw Exception('Il file "${file.name}" è stato letto ma contiene 0 byte. Seleziona il file originale, non un collegamento o un elemento cloud non scaricato.');
    }

    final name = file.name.trim().toLowerCase();
    if (name.endsWith('.json')) {
      final dynamic data;
      try {
        data = jsonDecode(utf8.decode(bytes));
      } catch (e) {
        throw Exception('JSON non valido o non leggibile: $e');
      }
      final list = data is Map ? (data['oggetti'] ?? data['objects'] ?? data['data']) : data;
      if (list is! List) throw Exception('Il JSON deve contenere un elenco di oggetti.');
      return list.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    }
    if (name.endsWith('.xlsx')) {
      final xlsx.Excel workbook;
      try {
        workbook = xlsx.Excel.decodeBytes(bytes);
      } catch (e) {
        throw Exception('Excel non leggibile. Usa un file .xlsx (non .xls) non protetto. Dettaglio: $e');
      }
      if (workbook.tables.isEmpty) throw Exception('Il file Excel non contiene fogli leggibili.');

      String normalizeHeader(dynamic value) => (value ?? '')
          .toString()
          .replaceFirst('\uFEFF', '')
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[\\s\\-./]+'), '_');

      const descriptionHeaders = {
        'descrizione_oggetto','descrizione','nome','description','object_description'
      };
      List<dynamic>? table;
      int headerIndex = -1;
      List<String> headers = <String>[];

      // Cerca la riga di intestazione in tutti i fogli, anche se non è la prima
      // riga e anche se Excel ha intestazioni con spazi o maiuscole.
      for (final sheet in workbook.tables.values) {
        final rows = sheet.rows;
        for (var ri = 0; ri < rows.length; ri++) {
          final candidate = rows[ri]
              .map((cell) => normalizeHeader(cell?.value))
              .toList();
          if (candidate.any(descriptionHeaders.contains)) {
            table = rows;
            headerIndex = ri;
            headers = candidate;
            break;
          }
        }
        if (table != null) break;
      }

      if (table == null || headerIndex < 0) {
        final sheets = workbook.tables.keys.join(', ');
        throw Exception('Intestazione non trovata nei fogli Excel ($sheets). Serve una colonna descrizione_oggetto, descrizione o nome.');
      }

      final parsed = <Map<String, dynamic>>[];
      for (final sourceRow in table.skip(headerIndex + 1)) {
        if (!sourceRow.any((cell) => (cell?.value?.toString() ?? '').trim().isNotEmpty)) continue;
        final row = <String, dynamic>{};
        for (var i = 0; i < headers.length && i < sourceRow.length; i++) {
          final header = headers[i];
          if (header.isEmpty) continue;
          row[header] = sourceRow[i]?.value?.toString().trim() ?? '';
        }

        // Mantiene i nomi del master originale e aggiunge alias solo se mancanti.
        row['descrizione_oggetto'] = row['descrizione_oggetto'] ??
            row['descrizione'] ?? row['nome'] ?? row['description'] ?? '';
        row['quantita'] = row['quantita'] ??
            row['quantita_importazione'] ?? row['quantità'] ?? '1';
        parsed.add(row);
      }
      if (parsed.isEmpty) throw Exception('Intestazione trovata nel foglio Excel, ma non ci sono righe oggetto da importare.');
      return parsed;
    }
    if (name.endsWith('.csv')) {
      // Il CSV esportato da Excel/Android può usare LF invece di CRLF.
      // Normalizza le terminazioni prima del parsing e rimuove il BOM UTF-8.
      var text = utf8.decode(bytes, allowMalformed: true).replaceFirst('\uFEFF','');
      text = text.replaceAll('\r\n','\n').replaceAll('\r','\n');
      if (text.trim().isEmpty) throw Exception('Il file CSV è realmente vuoto (' + bytes.length.toString() + ' byte).');

      // I CSV arrivano da Excel con virgola, punto e virgola o tabulazione.
      final firstLine = text.split('\n').first;
      final delimiters = <String>[',', ';', '\t'];
      var delimiter = ',';
      var bestCount = -1;
      for (final candidate in delimiters) {
        final count = candidate.allMatches(firstLine).length;
        if (count > bestCount) { bestCount = count; delimiter = candidate; }
      }
      final table = CsvToListConverter(shouldParseNumbers:false, eol:'\n', fieldDelimiter:delimiter).convert(text);
      final nonEmptyRows = table.where((r)=>r.any((v)=>v.toString().trim().isNotEmpty)).toList();
      if (nonEmptyRows.length < 2) {
        final preview = firstLine.length > 100 ? firstLine.substring(0,100) : firstLine;
        throw Exception('CSV ricevuto (' + bytes.length.toString() + ' byte), ma non riconosco righe dati. Separatore rilevato: "' + delimiter + '". Intestazione: ' + preview);
      }
      final headers = nonEmptyRows.first.map((e)=>e.toString().replaceFirst('\uFEFF','').trim().toLowerCase()).toList();
      final parsed = <Map<String,dynamic>>[];
      for (final r in nonEmptyRows.skip(1)) {
        final row=<String,dynamic>{};
        for (var i=0;i<headers.length && i<r.length;i++) { final h=headers[i]; if(h.isNotEmpty) row[h]=r[i]; }
        row['descrizione_oggetto'] ??= row['descrizione'] ?? row['nome'] ?? '';
        row['quantita'] ??= row['quantita_importazione'] ?? row['quantità'] ?? '1';
        parsed.add(row);
      }
      if (parsed.isEmpty) throw Exception('CSV letto: intestazione presente, ma nessun record importabile.');
      return parsed;
    }
    throw Exception('Formato non supportato. Usa XLSX, CSV o JSON.');
  }

  Future<void> _pickImport() async {
    setState(() {
      _busy = true;
      _selectedImportFile = null;
      _rows = [];
      _duplicates.clear();
      _invalid.clear();
      _status = 'Apertura selettore file…';
    });
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx', 'csv', 'json'],
        withData: true,
        withReadStream: true,
        allowMultiple: false,
      );
      if (picked == null || picked.files.isEmpty) {
        if (mounted) setState(() => _status = 'Selezione annullata. Nessun dato modificato.');
        return;
      }
      final file = picked.files.first;
      if (mounted) {
        setState(() {
          _selectedImportFile = file;
          _status = 'File selezionato: ${file.name} · ${file.size} byte. Premi ANALIZZA FILE per caricarlo e vedere l’anteprima. Nessun record salvato.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Selezione file non riuscita: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyzeImport() async {
    final file = _selectedImportFile;
    if (file == null) {
      setState(() => _status = 'Prima seleziona un file.');
      return;
    }
    setState(() {
      _busy = true;
      _rows = [];
      _duplicates.clear();
      _invalid.clear();
      _status = 'Caricamento di ${file.name} (${file.size} byte)…';
    });
    try {
      final rows = await _parse(file);
      final existing = await _catalog();
      final descriptions = existing.map((e) => _norm(e['descrizione_oggetto'])).toSet();
      final codes = existing.map((e) => _norm(e['codice_oggetto'])).toSet();
      for (var i = 0; i < rows.length; i++) {
        final desc = _norm(rows[i]['descrizione_oggetto'] ?? rows[i]['descrizione'] ?? rows[i]['nome']);
        final code = _norm(rows[i]['codice_oggetto']);
        if (desc.isEmpty) {
          _invalid.add(i);
        } else if (descriptions.contains(desc) || (code.isNotEmpty && codes.contains(code)) ||
            rows.take(i).any((r) => _norm(r['descrizione_oggetto'] ?? r['descrizione'] ?? r['nome']) == desc)) {
          _duplicates.add(i);
        }
      }
      if (mounted) {
        setState(() {
          _rows = rows;
          _status = 'File letto: ${file.name}. Anteprima: ${rows.length} righe. Possibili duplicati: ${_duplicates.length}. Senza descrizione: ${_invalid.length}. Nessun record salvato.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Analisi di ${file.name} non riuscita: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
          SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_busy?null:_pickImport,icon:const Icon(Icons.file_open),label:const Text('1. SELEZIONA FILE'))),
          if (_selectedImportFile != null) ...[
            const SizedBox(height: 10),
            Card(child: ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(_selectedImportFile!.name, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text('File selezionato · ${_selectedImportFile!.size} byte'),
              trailing: const Icon(Icons.check_circle_outline),
            )),
            SizedBox(width:double.infinity,child:FilledButton.icon(
              onPressed:_busy?null:_analyzeImport,
              icon:const Icon(Icons.fact_check),
              label:const Text('2. CARICA E ANALIZZA FILE'),
            )),
          ],
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
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String _imageAcquisition = 'CARICAMENTO_FILE';
  String? _existingImageUrl;
  String _imageStatus = 'Nessuna immagine selezionata.';
  final Map<String, Map<String, dynamic>> _pr02PendingImages = {};
  final Set<String> _failedImageFallbacks = {};
  final Map<int, String> _objectCardImageFallbacks = {};
  final Set<String> _objectCardImageRetries = {};

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
  List<Map<String, dynamic>> _pr12UnresolvedRecords = [];
  final Map<String, int> _pr12SelectedCandidates = {};
  bool _pr12RetryRunning = false;
  bool _showPr02TechnicalTab = false;
  int _pr11MasterTabIndex = 0;
  bool _pr02SearchCompleted = false;
  final List<Map<String, dynamic>> _pr02PendingChanges = [];
  final List<Map<String, dynamic>> _pr03PendingClosures = [];
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _pr11SearchFocusNode = FocusNode();
  String _lastPr11SearchQuery = '';

  String _reportPeriodMode = 'month';
  DateTime _reportStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _reportEnd = DateTime.now();
  bool get _isPeriodReport => const {'REPORT-CASH', 'REPORT-PURCHASES', 'REPORT-SALES'}.contains(widget.apiCode);

  String _dateLabel(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Map<String, dynamic> _reportDateArguments() {
    final now = DateTime.now();
    late DateTime from;
    late DateTime to;
    if (_reportPeriodMode == 'year') {
      from = DateTime(now.year, 1, 1);
      to = DateTime(now.year, now.month, now.day);
    } else if (_reportPeriodMode == 'month') {
      from = DateTime(now.year, now.month, 1);
      to = DateTime(now.year, now.month, now.day);
    } else {
      from = DateTime(_reportStart.year, _reportStart.month, _reportStart.day);
      to = DateTime(_reportEnd.year, _reportEnd.month, _reportEnd.day);
    }
    if (from.isAfter(to)) throw Exception('La data iniziale non può essere successiva alla data finale.');
    String iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {'data_da': iso(from), 'data_a': iso(to), '_periodo_descrizione': '${_dateLabel(from)} – ${_dateLabel(to)}'};
  }

  Future<void> _pickReportDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context, initialDate: isStart ? _reportStart : _reportEnd,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      helpText: isStart ? 'Scegli la data iniziale' : 'Scegli la data finale',
      cancelText: 'ANNULLA', confirmText: 'CONFERMA',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _reportStart = picked;
        if (_reportStart.isAfter(_reportEnd)) _reportEnd = picked;
      } else {
        _reportEnd = picked;
        if (_reportEnd.isBefore(_reportStart)) _reportStart = picked;
      }
    });
  }

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
      if (item.length == 1 && (_selectedImageBytes == null || _selectedImageName == null)) throw Exception('Nessuna modifica rilevata.');
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
    final productCode = valueFor(['codice_prodotto', 'codice_identificativo']);
    final theme = valueFor(['tema']);
    final section = valueFor(['sezione']);
    final subtheme = valueFor(['sottotema']);
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
                  ? Image.network(_valoraImageProxyUrl(imageUrl), fit: BoxFit.contain,
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
              const SizedBox(height: 8),
              _metadataValue('Tema', theme),
              const SizedBox(height: 8),
              _metadataValue('Sezione', section),
              const SizedBox(height: 8),
              _metadataValue('Sottotema', subtheme),
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
            const SizedBox(height: 8),
            _imageField(),
          ],
        ]),
      ),
    );
  }

  Future<void> _pickImageFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false, withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      final bytes = file.bytes;
      final extension = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : '';
      if (!const ['jpg','jpeg','png','webp','heic','heif'].contains(extension)) {
        throw Exception('Formato non supportato. Usa JPG, PNG, WEBP, HEIC o HEIF.');
      }
      if (bytes == null || bytes.isEmpty) throw Exception('Il file selezionato non contiene dati leggibili.');
      if (bytes.length > 10 * 1024 * 1024) throw Exception('L’immagine supera il limite di 10 MB.');
      setState(() {
        _selectedImageBytes = bytes; _selectedImageName = file.name;
        _imageAcquisition = 'CARICAMENTO_FILE';
        _imageStatus = 'Immagine pronta: ${file.name}. Verrà associata dopo il salvataggio.';
      });
    } catch (e) {
      if (mounted) setState(() => _imageStatus = 'Caricamento immagine non riuscito: $e');
    }
  }

  Future<void> _captureImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) throw Exception('La fotocamera non ha restituito un’immagine valida.');
      if (bytes.length > 10 * 1024 * 1024) throw Exception('La foto supera il limite di 10 MB.');
      setState(() {
        _selectedImageBytes = bytes; _selectedImageName = picked.name.isNotEmpty ? picked.name : 'foto_valora.jpg';
        _imageAcquisition = 'FOTOCAMERA'; _imageStatus = 'Foto pronta. Avvia il riconoscimento per passare a PR-12.';
      });
    } catch (e) {
      if (mounted) setState(() => _imageStatus = 'Scatto foto non riuscito: $e');
    }
  }

  Future<void> _startAssistantPhoto() async {
    if (_loading) return;
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
      _imageStatus = 'Apro la fotocamera…';
    });
    await _captureImage();
    if (!mounted) return;
    if (_selectedImageBytes == null || _selectedImageBytes!.isEmpty) {
      setState(() => _imageStatus = 'Nessuna foto acquisita. Premi ASSISTENTE VALORA per riprovare.');
      return;
    }
    await _recognizeSelectedPhoto();
  }

  Future<void> _recognizeSelectedPhoto() async {
    final bytes = _selectedImageBytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scatta prima una foto dell’oggetto.')));
      return;
    }
    setState(() { _loading = true; _imageStatus = 'Sto riconoscendo l’oggetto e cercando fonti con PR-12…'; });
    try {
      final mime = (_selectedImageName ?? '').toLowerCase().endsWith('.png') ? 'image/png'
          : ((_selectedImageName ?? '').toLowerCase().endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
        'azione': 'ANALIZZA_FOTO',
        'modalita_ia': 'TEST',
        'image_data_url': 'data:$mime;base64,${base64Encode(bytes)}',
        'mercato': 'Italia',
      });
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['error'] ?? 'Riconoscimento non riuscito').toString() : 'Risposta PR-12 non valida');
      }
      final clues = data['identificazione'] is Map ? Map<String,dynamic>.from(data['identificazione']) : <String,dynamic>{};
      final results = data['risultati'] is List ? (data['risultati'] as List).whereType<Map>().map((v)=>Map<String,dynamic>.from(v)).toList() : <Map<String,dynamic>>[];
      if (!mounted) return;
      final description = (clues['descrizione_provvisoria'] ?? '').toString().trim();
      final maker = (clues['marchio'] ?? '').toString().trim();
      final code = (clues['codice_prodotto'] ?? '').toString().trim();
      final category = (clues['categoria'] ?? '').toString().trim();
      setState(() {
        if (description.isNotEmpty) _description.text = description;
        if (maker.isNotEmpty) _producer.text = maker;
        if (code.isNotEmpty) _family.text = code;
        if (category.isNotEmpty) _line.text = category;
        if (_description.text.trim().isEmpty && results.isNotEmpty) {
          final title = (results.first['title'] ?? '').toString().trim();
          if (title.isNotEmpty) _description.text = title;
        }
        _metadataSearchExecuted = true;
        _metadataResult = results.isEmpty
          ? 'Riconoscimento completato. Nessuna corrispondenza online affidabile: verifica e completa i dati.'
          : 'Riconoscimento completato. PR-12 ha trovato ${results.length} risultati da verificare.';
        final uncertainty = clues['incertezze'] is List ? (clues['incertezze'] as List).join(' · ') : '';
        _imageStatus = 'Assistente VALORA: campi compilati con le informazioni disponibili. ${uncertainty.isNotEmpty ? "Da verificare: $uncertainty. " : ""}Controlla i dati prima di salvare.';
      });
      if (mounted) {
        final details = <String>[
          if (description.isNotEmpty) 'Descrizione',
          if (maker.isNotEmpty) 'Marca',
          if (code.isNotEmpty) 'Codice prodotto',
          if (category.isNotEmpty) 'Categoria',
        ];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(details.isEmpty
            ? 'Ricerca terminata. Completa manualmente i campi non riconosciuti.'
            : 'Maschera compilata: ${details.join(", ")}. Verifica i risultati PR-12 e completa il record.'),
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) setState(() => _imageStatus = 'Assistente non disponibile: $e. Puoi comunque compilare la maschera manualmente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _imageField() {
    final hasSelected = _selectedImageBytes != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: sectionColor, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ASSISTENTE VALORA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('Scatta una foto: riconosco l’oggetto, cerco con PR-12 e compilo i campi disponibili. Poi controlli e completi tu.',
                style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 13)),
            ])),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _startAssistantPhoto,
              icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.mic),
              label: Text(_loading ? 'ASSISTENTE AL LAVORO…' : 'ASSISTENTE VALORA · SCATTA E CERCA'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          if (hasSelected) ...[
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: Image.memory(_selectedImageBytes!, height: 180, width: double.infinity, fit: BoxFit.contain)),
          ] else if (_existingImageUrl != null && _existingImageUrl!.startsWith('http')) ...[
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(10),
              child: Image.network(_valoraImageProxyUrl(_existingImageUrl!), height: 160, width: double.infinity, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _imagePlaceholder(size: 100))),
          ],
          const SizedBox(height: 8),
          Text(_imageStatus, style: TextStyle(
            color: _imageStatus.startsWith('Assistente non disponibile') || _imageStatus.startsWith('Scatto')
              ? Colors.orangeAccent : ValoraAppearance.instance.textSecondary,
            fontSize: 12)),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(
            onPressed: _loading ? null : _pickImageFile,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Scegli invece una foto dalla galleria'),
          )),
        ]),
      ),
    );
  }

  Widget _readOnlyImageCard() {
    final imageUrl = _existingImageUrl;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('IMMAGINE OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (imageUrl != null && imageUrl.startsWith('http'))
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                _valoraImageProxyUrl(imageUrl),
                width: double.infinity,
                height: 240,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : SizedBox(height: 180, child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes == null ? null : progress.cumulativeBytesLoaded / progress.expectedTotalBytes!))),
                errorBuilder: (_, __, ___) {
                  _retryImageAfterFailure(imageUrl);
                  return Column(children: [
                  Icon(Icons.broken_image_outlined, size: 42, color: ValoraAppearance.instance.textFaint),
                  const SizedBox(height: 6),
                  Text('Immagine registrata, ma anteprima non disponibile.', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                ]);
                },
              ),
            )
          else
            Row(children: [
              Icon(Icons.image_outlined, size: 30, color: ValoraAppearance.instance.textFaint),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _imageStatus == 'Verifica immagine associata…' ? 'Caricamento immagine…' :
                _imageStatus == 'Immagine già associata all’oggetto.' ? 'Immagine associata, ma URL non disponibile.' :
                'Nessuna immagine associata a questo oggetto.',
                style: TextStyle(color: ValoraAppearance.instance.textSecondary),
              )),
            ]),
        ]),
      ),
    );
  }

  Future<String> _uploadAndRegisterImage({
    required int objectId, required Uint8List bytes, required String fileName,
    required String acquisition, required String procedure,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final session = client.auth.currentSession;
    if (user == null || session == null) throw Exception('Sessione non valida per caricare l’immagine.');
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) throw Exception('Immagine vuota o superiore a 10 MB.');
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
    final extRaw = safeName.contains('.') ? safeName.split('.').last.toLowerCase() : 'jpg';
    if (!const ['jpg','jpeg','png','webp','heic','heif'].contains(extRaw)) {
      throw Exception('Formato non supportato. Usa JPG, PNG, WEBP, HEIC o HEIF.');
    }
    final ext = extRaw;
    final mime = switch (ext) {
      'png' => 'image/png', 'webp' => 'image/webp', 'heic' => 'image/heic',
      'heif' => 'image/heif', _ => 'image/jpeg',
    };
    final path = '${user.id}/$objectId/${_uuid.v4()}.$ext';
    await client.storage.from('pr01-foto-temporanee').uploadBinary(
      path, bytes, fileOptions: FileOptions(contentType: mime, upsert: false));
    final response = await client.functions.invoke(
      'collection-object-images-test',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {'action':'register','codice_oggetto':objectId,'path':path,'file_name':safeName,
        'modalita_acquisizione':acquisition,'procedura_origine':procedure},
    );
    if (response.status < 200 || response.status >= 300 || response.data is! Map) {
      throw Exception('Registrazione immagine non confermata: ${response.data}');
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    if (data['ok'] != true) throw Exception(data['error'] ?? 'Registrazione immagine non confermata.');
    final signedUrl = (data['signed_url'] ?? '').toString();
    if (signedUrl.isEmpty) throw Exception('Immagine registrata ma anteprima non disponibile.');
    return signedUrl;
  }

  Future<void> _loadExistingImage(int objectId, {bool skipCatalogUrl = false, String? failedUrl}) async {
    String? imageUrl;
    bool isHttpUrl(String value) =>
        value.startsWith('https://') || value.startsWith('http://');

    // 1) Prima prova l'immagine catalografica, tranne quando è proprio quella
    // che il widget ha appena segnalato come non caricabile.
    if (!skipCatalogUrl) {
      try {
        final metadata = await Supabase.instance.client
            .schema('collection')
            .from('master_metadati')
            .select('url_immagine')
            .eq('codice_oggetto', objectId)
            .maybeSingle();
        final candidate = (metadata?['url_immagine'] ?? '').toString().trim();
        if (isHttpUrl(candidate) && candidate != failedUrl) imageUrl = candidate;
      } catch (e) {
        debugPrint('VALORA: URL immagine catalogo non recuperato per $objectId: $e');
      }
    }

    // 2) Chiede al servizio immagini un eventuale URL alternativo / Storage.
    if (imageUrl == null) {
      try {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          final response = await Supabase.instance.client.functions.invoke(
            'collection-object-images-test',
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'action': 'get', 'codice_oggetto': objectId},
          );
          if (response.status >= 200 && response.status < 300 && response.data is Map) {
            final data = Map<String, dynamic>.from(response.data as Map);
            final candidate = (data['signed_url'] ?? data['url'] ?? data['image_url'] ?? '').toString().trim();
            if (isHttpUrl(candidate) && candidate != failedUrl) imageUrl = candidate;
          }
        }
      } catch (e) {
        debugPrint('VALORA: servizio immagini non disponibile per $objectId: $e');
      }
    }

    // 3) Ultimo fallback: URL HTTP distinti presenti nel registro immagini.
    if (imageUrl == null) {
      try {
        final rows = await Supabase.instance.client
            .schema('collection')
            .from('immagini_oggetto')
            .select('riferimento_immagine, url_fonte, immagine_principale, stato_verifica')
            .eq('codice_oggetto', objectId)
            .order('immagine_principale', ascending: false)
            .limit(10);
        for (final row in rows) {
          for (final key in ['riferimento_immagine', 'url_fonte']) {
            final candidate = (row[key] ?? '').toString().trim();
            if (isHttpUrl(candidate) && candidate != failedUrl) {
              imageUrl = candidate;
              break;
            }
          }
          if (imageUrl != null) break;
        }
      } catch (e) {
        debugPrint('VALORA: registro immagini non disponibile per $objectId: $e');
      }
    }

    if (!mounted || _loadedObjectId != objectId) return;
    setState(() {
      _existingImageUrl = imageUrl;
      _imageStatus = imageUrl != null
          ? 'Immagine associata alla scheda.'
          : 'Anteprima non disponibile: nessun URL alternativo valido.';
    });
  }

  Future<void> _retryImageAfterFailure(String failedUrl) async {
    final objectId = _loadedObjectId;
    if (objectId == null || failedUrl.isEmpty || !_failedImageFallbacks.add(failedUrl)) return;
    await _loadExistingImage(objectId, skipCatalogUrl: true, failedUrl: failedUrl);
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
    // OBJECT_MASTER restituisce i dati operativi; recupera separatamente i metadati
    // del catalogo, perché l'URL dell'immagine risiede in master_metadati.
    try {
      final metadata = await Supabase.instance.client
          .schema('collection')
          .from('master_metadati')
          .select('url_immagine, codice_identificativo, nome_ufficiale, produttore, anno_uscita, versione_variante, descrizione_ufficiale, tema, sezione, sottotema')
          .eq('codice_oggetto', id)
          .maybeSingle();
      if (metadata != null) {
        final md = Map<String, dynamic>.from(metadata);
        m.addAll(md);
        final imageUrl = (md['url_immagine'] ?? '').toString().trim();
        if (imageUrl.isNotEmpty) {
          // Uniforma le chiavi immagine attese dalla scheda e dal riquadro.
          m['url_immagine'] = imageUrl;
          m['image_url'] = imageUrl;
        }
      }
    } catch (e) {
      // La scheda operativa resta consultabile anche se i metadati non sono accessibili.
      debugPrint('VALORA: metadati immagine non recuperati per oggetto $id: $e');
    }
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
      _existingImageUrl = null; _selectedImageBytes = null; _selectedImageName = null;
      _imageStatus = 'Verifica immagine associata…';
    });
    if (widget.apiCode == 'PR-02' || widget.apiCode == 'OBJECT_MASTER') await _loadExistingImage(id);
  }

  Future<void> _loadIncompleteMetadataCatalog() async {
    setState(() {
      _metadataResult = 'PR-12: analisi del catalogo in corso…';
      _output = _metadataResult;
      _pr12IncompleteRecords = [];
      _pr12AiResults = [];
      _pr12UnresolvedRecords = [];
      _pr12SelectedCandidates.clear();
      _pr12NextBatchOffset = 0;
      _pr12AiBatchStatus = 'Catalogo aggiornato. La coda di ricerca è pronta.';
    });
    try {
      // Escludi i record sintetici archiviati prima di preparare qualsiasi lotto PR-12.
      // Se la lettura del flag fallisce, l'analisi fallisce in sicurezza e non avvia ricerche.
      final archivedRows = await Supabase.instance.client
          .schema('collection')
          .from('master_oggetti')
          .select('codice_oggetto')
          .eq('archiviato_test', true);
      final archivedTestIds = archivedRows
          .map((row) => (row['codice_oggetto'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();

      final incomplete = <Map<String, dynamic>>[];
      const pageSize = 500;
      var offset = 0;
      var totalRead = 0;
      var archivedSkipped = 0;
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
          final recordId = (row['codice_oggetto'] ?? '').toString();
          if (archivedTestIds.contains(recordId)) {
            archivedSkipped++;
            continue;
          }
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
        _metadataResult = 'Analisi completata: letti $totalRead record; esclusi $archivedSkipped record di test archiviati; ${incomplete.length} record reali con almeno un metadato mancante. Nessun dato modificato.';
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

  Future<void> _runPr12AiBatch({bool retryUnresolved = false, Map<String, dynamic>? singleRecord}) async {
    if (singleRecord == null && _pr12IncompleteRecords.isEmpty) { setState(() => _pr12AiBatchStatus = 'Prima esegui ANALIZZA CATALOGO.'); return; }
    final List<Map<String, dynamic>> batch;
    if (singleRecord != null) {
      batch = [singleRecord];
    } else if (retryUnresolved) {
      if (_pr12UnresolvedRecords.isEmpty) { setState(() => _pr12AiBatchStatus = 'Non ci sono record da riprovare.'); return; }
      batch = _pr12UnresolvedRecords.take(10).toList();
    } else {
      if (_pr12NextBatchOffset >= _pr12IncompleteRecords.length) { setState(() => _pr12AiBatchStatus = 'Prima passata completata. I record irrisolti restano disponibili per una nuova ricerca.'); return; }
      batch = _pr12IncompleteRecords.skip(_pr12NextBatchOffset).take(10).toList();
    }
    setState(() { _pr12AiBatchRunning = true; _pr12RetryRunning = retryUnresolved; _pr12AiBatchStatus = singleRecord != null ? 'Ricerca singola per l’oggetto ${singleRecord['codice_oggetto']}…' : (retryUnresolved ? 'Nuovo tentativo sui record irrisolti…' : 'Ricerca multi-fonte del lotto in corso…'); });
    try {
      final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
        'modalita_ia': 'TEST',
        'oggetti': batch.map((row) => {'id': (row['codice_oggetto'] ?? '').toString(), 'descrizione': (row['descrizione_oggetto'] ?? '').toString(), 'categoria': _pr12CategoryFromDescription((row['descrizione_oggetto'] ?? '').toString()), 'tema': (row['tema'] ?? row['franchise'] ?? row['franchise_tema'] ?? row['linea_prodotto'] ?? '').toString().trim(), 'mercato': (row['mercato'] ?? row['market'] ?? 'Italia').toString()}).toList(),
      });
      dynamic raw = response.data;
      // Supabase Functions può esporre il body come ByteStream: consumarlo e decodificarlo prima del parsing JSON/SSE.
      if (raw is Stream<List<int>>) {
        final bytes = await raw.fold<List<int>>(<int>[], (all, chunk) => all..addAll(chunk));
        raw = utf8.decode(bytes, allowMalformed: true);
      } else if (raw is Uint8List) {
        raw = utf8.decode(raw, allowMalformed: true);
      }
      final finals = <Map<String, dynamic>>[];

      void addFinal(dynamic value) {
        if (value is Map) {
          final item = Map<String, dynamic>.from(value);
          // Accetta sia il contratto streaming (oggetto_completato/coda_completata)
          // sia la risposta JSON diretta dell'engine. In entrambi i casi l'ID
          // dell'oggetto deve essere presente per evitare risultati scollegati.
          if (item['oggetto_id'] != null && (item['risultati'] is List || item['ok'] == false)) {
            finals.add(item);
          }
          final nested = item['risultati_finali'];
          if (nested is List) {
            for (final entry in nested) {
              if (entry is Map) finals.add(Map<String, dynamic>.from(entry));
            }
          }
          final result = item['risultato'];
          if ((item['tipo'] == 'oggetto_completato' || item['tipo'] == 'oggetto_errore') && result is Map) {
            finals.add(Map<String, dynamic>.from(result));
          }
          final wrapped = item['data'] ?? item['result'];
          if (wrapped is Map) addFinal(wrapped);
          if (wrapped is List) {
            for (final entry in wrapped) {
              if (entry is Map) addFinal(entry);
            }
          }
        } else if (value is List) {
          for (final entry in value) {
            addFinal(entry);
          }
        }
      }

      if (raw is Map || raw is List) {
        addFinal(raw);
      } else if (raw is String) {
        final normalized = raw.replaceFirst(RegExp(r'^\uFEFF'), '').trim();
        var decoded = false;
        try {
          final parsed = jsonDecode(normalized);
          addFinal(parsed);
          decoded = true;
          if (parsed is String) {
            try { addFinal(jsonDecode(parsed)); } catch (_) {}
          }
        } catch (_) {
          // Potrebbe essere una risposta SSE anziché JSON puro.
        }
        if (!decoded || finals.isEmpty) {
          for (final line in normalized.split(RegExp(r'\r?\n'))) {
            final trimmed = line.trimLeft();
            if (!trimmed.startsWith('data:')) continue;
            final payload = trimmed.substring(5).trim();
            if (payload.isEmpty || payload == '[DONE]') continue;
            try {
              addFinal(jsonDecode(payload));
            } catch (_) {
              // Ignore a malformed SSE frame while retaining valid frames.
            }
          }
        }
      }

      final deduplicated = <String, Map<String, dynamic>>{};
      for (final result in finals) {
        final id = (result['oggetto_id'] ?? '').toString();
        if (id.isNotEmpty) deduplicated[id] = result;
      }
      finals
        ..clear()
        ..addAll(deduplicated.values);
      if (finals.isEmpty) {
        final rawText = raw.toString();
        final preview = rawText.substring(0, rawText.length < 240 ? rawText.length : 240);
        throw Exception('Risposta PR-12 senza risultati interpretabili (HTTP ${response.status}, tipo ${raw.runtimeType}). Anteprima: $preview. Nessun dato del catalogo modificato.');
      }
      final byId = {for (final result in finals) (result['oggetto_id'] ?? '').toString(): result};
      final resolvedIds = <String>{};
      final unresolved = <Map<String, dynamic>>[];
      for (final row in batch) {
        final id = (row['codice_oggetto'] ?? '').toString();
        final result = byId[id];
        final count = result?['numero_risultati'] is num ? (result!['numero_risultati'] as num).toInt() : (result?['risultati'] is List ? (result!['risultati'] as List).length : 0);
        if (result?['ok'] == true && count > 0) { resolvedIds.add(id); } else { unresolved.add(row); }
      }
      if (!mounted) return;
      setState(() {
        _pr12AiResults = [..._pr12AiResults.where((old) => !finals.any((fresh) => (fresh['oggetto_id'] ?? '').toString() == (old['oggetto_id'] ?? '').toString())), ...finals];
        if (singleRecord != null) {
          _pr12AiBatchStatus = 'Ricerca singola completata: ${finals.where((r) => r['ok'] == true).length} risposta/e valida/e. Nessun dato salvato.';
        } else if (retryUnresolved) {
          _pr12UnresolvedRecords = [..._pr12UnresolvedRecords.where((row) => !resolvedIds.contains((row['codice_oggetto'] ?? '').toString()) && !batch.any((b) => (b['codice_oggetto'] ?? '').toString() == (row['codice_oggetto'] ?? '').toString())), ...unresolved];
        } else {
          _pr12NextBatchOffset += batch.length;
          _pr12UnresolvedRecords = [..._pr12UnresolvedRecords, ...unresolved.where((row) => !_pr12UnresolvedRecords.any((old) => old['codice_oggetto'] == row['codice_oggetto']))];
        }
        final good = finals.where((r) => r['ok'] == true && ((r['numero_risultati'] as num?) ?? ((r['risultati'] is List) ? (r['risultati'] as List).length : 0)) > 0).length;
        _pr12AiBatchStatus = singleRecord != null ? 'Ricerca singola completata: $good risultato/i con candidati pertinenti. Nessun dato salvato.' : '${retryUnresolved ? 'Nuovo tentativo' : 'Lotto completato'}: $good con risultati pertinenti; ${batch.length - good} da approfondire. Prima passata: $_pr12NextBatchOffset/${_pr12IncompleteRecords.length}. Da riprovare: ${_pr12UnresolvedRecords.length}. Nessun dato salvato.';
      });
    } catch (e) { if (mounted) setState(() => _pr12AiBatchStatus = 'Ricerca non completata: $e'); }
    finally { if (mounted) setState(() { _pr12AiBatchRunning = false; _pr12RetryRunning = false; }); }
  }
  Future<void> _pr12ApplySelectedCandidate(Map<String, dynamic> result, Map<String, dynamic> candidate) async {
    final id = int.tryParse((result['oggetto_id'] ?? '').toString());
    if (id == null) {
      setState(() => _pr12AiBatchStatus = 'Non posso applicare: codice oggetto non valido.');
      return;
    }
    final nested = candidate['metadati'] is Map
        ? Map<String, dynamic>.from(candidate['metadati'] as Map)
        : <String, dynamic>{};
    String valueFor(List<String> keys) {
      for (final key in keys) {
        final value = candidate[key] ?? nested[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
      }
      return '';
    }
    final maker = valueFor(['produttore', 'editore', 'manufacturer', 'publisher']);
    final yearText = valueFor(['anno_uscita', 'anno', 'release_year', 'year']);
    final productCode = valueFor(['codice_prodotto', 'codice', 'product_code', 'set_num', 'isbn', 'item_number']);
    final title = valueFor(['titolo_prodotto', 'nome_prodotto', 'product_name', 'title', 'titolo']);
    final imageCandidate = valueFor(['url_immagine', 'image_url', 'immagine_url', 'foto_url', 'main_image_url', 'image']);
    final imageUrl = (imageCandidate.startsWith('https://') || imageCandidate.startsWith('http://')) ? imageCandidate : '';
    final sourceUrl = valueFor(['url_fonte', 'url', 'source_url', 'source']);
    final theme = valueFor(['tema', 'theme', 'franchise']);
    final section = valueFor(['sezione', 'section', 'categoria', 'category']);
    final subtheme = valueFor(['sottotema', 'subtheme', 'linea', 'line', 'serie']);
    final officialDescription = valueFor(['descrizione_ufficiale', 'descrizione', 'description', 'snippet']);
    final version = valueFor(['versione_variante', 'variante', 'version', 'variant']);
    final year = int.tryParse(yearText);
    final genericTitles = <String>{'home', 'homepage', 'official website', 'search results', 'catalogo', 'risultati della ricerca'};
    final usefulTitle = title.length >= 5 && !genericTitles.contains(title.toLowerCase());
    if (maker.isEmpty && year == null && productCode.isEmpty && !usefulTitle && imageUrl.isEmpty && theme.isEmpty && section.isEmpty && subtheme.isEmpty && officialDescription.isEmpty && version.isEmpty) {
      setState(() => _pr12AiBatchStatus = 'La fonte non contiene metadati strutturati o un titolo prodotto utilizzabile. Nessun dato modificato.');
      return;
    }
    final client = Supabase.instance.client;
    final current = await client.schema('collection').from('master_oggetti')
        .select('descrizione_oggetto,produttore,anno_uscita,codice_prodotto')
        .eq('codice_oggetto', id).maybeSingle();
    if (current == null) throw Exception('Oggetto #$id non trovato nel catalogo TEST.');
    final currentDescription = (current['descrizione_oggetto'] ?? '').toString().trim();
    final existingMetadata = await client.schema('collection').from('master_metadati')
        .select('codice_identificativo,nome_ufficiale,produttore,anno_uscita,versione_variante,descrizione_ufficiale,tema,sezione,sottotema,isbn,editore,url_fonte,url_immagine,stato_verifica')
        .eq('codice_oggetto', id).maybeSingle();
    String existingValue(String key) => (existingMetadata?[key] ?? '').toString().trim();
    final appendTitle = usefulTitle && !currentDescription.toLowerCase().contains(title.toLowerCase());
    final proposedDescription = appendTitle
        ? (currentDescription.isEmpty ? title : currentDescription + ' · ' + title)
        : currentDescription;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CONFERMA APPLICAZIONE METADATI'),
        content: Text(
          'Oggetto #$id\n'
          'Descrizione proposta: ' + (proposedDescription.isEmpty ? 'nessuna modifica' : proposedDescription) + '\n'
          'Produttore: ' + (maker.isEmpty ? 'non trovato' : maker) + '\n'
          'Anno: ' + (year?.toString() ?? 'non trovato') + '\n'
          'Codice prodotto: ' + (productCode.isEmpty ? 'non trovato' : productCode) + '\n'
          + (imageUrl.isEmpty ? 'Nessuna immagine valida in questo candidato: immagine invariata.\n' : 'Immagine scelta da salvare:\n' + imageUrl + '\n')
          + (theme.isEmpty ? '' : 'Tema: ' + theme + '\n')
          + (section.isEmpty ? '' : 'Sezione: ' + section + '\n')
          + (subtheme.isEmpty ? '' : 'Sottotema: ' + subtheme + '\n\n')
          + 'I campi già compilati vengono conservati. Dopo la conferma verranno salvati anche URL immagine e tassonomia disponibili.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFERMO')),
        ],
      ),
    );
    if (accepted != true) return;
    final patch = <String, dynamic>{};
    if (appendTitle) patch['descrizione_oggetto'] = proposedDescription;
    if ((current['produttore'] ?? '').toString().trim().isEmpty && maker.isNotEmpty) patch['produttore'] = maker;
    if (current['anno_uscita'] == null && year != null && year >= 1800 && year <= DateTime.now().year + 2) patch['anno_uscita'] = year;
    if ((current['codice_prodotto'] ?? '').toString().trim().isEmpty && productCode.isNotEmpty) patch['codice_prodotto'] = productCode;
    final metadataPatch = <String, dynamic>{};
    void addIfMissing(String key, String value) {
      if (value.isNotEmpty && existingValue(key).isEmpty) metadataPatch[key] = value;
    }
    addIfMissing('codice_identificativo', productCode);
    addIfMissing('nome_ufficiale', usefulTitle ? title : '');
    addIfMissing('produttore', maker);
    if (existingMetadata?['anno_uscita'] == null && year != null && year >= 1800 && year <= DateTime.now().year + 2) metadataPatch['anno_uscita'] = year;
    addIfMissing('versione_variante', version);
    addIfMissing('descrizione_ufficiale', officialDescription);
    addIfMissing('tema', theme);
    addIfMissing('sezione', section);
    addIfMissing('sottotema', subtheme);
    addIfMissing('isbn', valueFor(['isbn']));
    addIfMissing('editore', valueFor(['editore', 'publisher']));
    addIfMissing('url_fonte', sourceUrl);
    // La conferma del candidato è una scelta esplicita dell'utente: se questo
    // candidato contiene un URL immagine valido, salva proprio quello anche
    // quando esiste già una foto diversa. Se non c'è URL valido, non toccare la foto.
    if (imageUrl.isNotEmpty) metadataPatch['url_immagine'] = imageUrl;
    if (metadataPatch.isNotEmpty) {
      metadataPatch['stato_verifica'] = 'PARZIALMENTE_VERIFICATO';
      metadataPatch['aggiornato_il'] = DateTime.now().toUtc().toIso8601String();
      if (existingMetadata == null) {
        await client.schema('collection').from('master_metadati').insert({'codice_oggetto': id, ...metadataPatch});
      } else {
        await client.schema('collection').from('master_metadati').update(metadataPatch).eq('codice_oggetto', id);
      }
    }
    if (patch.isNotEmpty) await client.schema('collection').from('master_oggetti').update(patch).eq('codice_oggetto', id);
    final savedMetadata = await client.schema('collection').from('master_metadati')
        .select('url_immagine,tema,sezione,sottotema')
        .eq('codice_oggetto', id).maybeSingle();
    final savedImage = (savedMetadata?['url_immagine'] ?? '').toString().trim();
    final imagePersisted = savedImage.startsWith('https://') || savedImage.startsWith('http://');
    final selectedImagePersisted = imageUrl.isEmpty || savedImage == imageUrl;
    final taxonomy = ['tema', 'sezione', 'sottotema'].where((key) => (savedMetadata?[key] ?? '').toString().trim().isNotEmpty).toList();
    if (!mounted) return;
    setState(() => _pr12AiBatchStatus = 'Salvataggio verificato per oggetto #$id. Campi aggiornati: ' + [...patch.keys, ...metadataPatch.keys.where((key) => key != 'stato_verifica' && key != 'aggiornato_il')].join(', ') + '. URL immagine presente: ' + (imagePersisted ? 'sì' : 'no') + '. Immagine scelta salvata: ' + (selectedImagePersisted ? 'sì' : 'NO, verificare') + '. Tassonomia presente: ' + (taxonomy.isEmpty ? 'no' : taxonomy.join(', ')) + '.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PR-12: salvataggio verificato per oggetto #$id')));
  }
  String _pr12CategoryFromDescription(String description) {
    final v = description.toLowerCase();
    if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(v)) return 'LEGO';
    if (RegExp(r'fumett|comic|manga|panini|salda|bonelli|graphic novel|isbn').hasMatch(v)) return 'FUMETTI';
    if (RegExp(r'orolog|watch|swatch|rolex|omega|seiko|casio|tissot|longines|tag heuer|cartier').hasMatch(v)) return 'WATCHES';
    if (RegExp(r'vinile|vinyl|disco|record|lp|musicassett|music tape').hasMatch(v)) return 'MUSIC';
    if (RegExp(r'moneta|monete|numismatic|coin|banconot|banknote|francoboll|stamp collection').hasMatch(v)) return 'NUMISMATICS';
    if (RegExp(r'carta collezionabile|trading card|pokemon card|magic the gathering|tcg|sports card').hasMatch(v)) return 'TRADING_CARDS';
    if (RegExp(r'myth cloth|saint seiya|bandai|gundam|gunpla|dragon ball|action figure|statua|transformers|optimus prime|bumblebee|megatron|star wars|naruto|one piece').hasMatch(v)) return 'ACTION_FIGURE';
    if (RegExp(r'maisto|die.?cast|modellino|motorbike|motocicletta|modellismo|auto in scala|hot wheels|matchbox').hasMatch(v)) return 'DIECAST';
    return 'COLLEZIONABILE';
  }
  String _exportCellValue(dynamic value) {
    if (value == null) return '';
    if (value is Map || value is List) return jsonEncode(value);
    return value.toString();
  }

  Future<void> _exportResults({required bool asPdf}) async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Non ci sono risultati da esportare.')),
      );
      return;
    }
    try {
      final records = _rows.map((row) => row is Map
          ? Map<String, dynamic>.from(row)
          : <String, dynamic>{'Risultato': row}).toList();
      final headers = <String>[];
      for (final record in records) {
        for (final key in record.keys) {
          if (!headers.contains(key)) headers.add(key);
        }
      }
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final baseName = 'VALORA_${widget.apiCode}_$stamp';
      Uint8List bytes;
      String extension;
      if (asPdf) {
        final document = pw.Document();
        final tableData = <List<String>>[
          headers,
          ...records.map((record) => headers.map((key) => _exportCellValue(record[key])).toList()),
        ];
        document.addPage(pw.MultiPage(
          pageFormat: pw_core.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            pw.Text('COLLECTION by VALORA',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text(widget.title, style: const pw.TextStyle(fontSize: 14)),
            pw.SizedBox(height: 4),
            pw.Text('Record: ${records.length} · Generato il ${_dateLabel(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              data: tableData,
              headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 6),
              headerDecoration: const pw.BoxDecoration(color: pw_core.PdfColor.fromInt(0xFFD6B15E)),
              cellAlignment: pw.Alignment.topLeft,
              border: pw.TableBorder.all(color: pw_core.PdfColor.fromInt(0xFFBBBBBB), width: 0.35),
            ),
          ],
        ));
        bytes = Uint8List.fromList(await document.save());
        extension = 'pdf';
      } else {
        final workbook = xlsx.Excel.createExcel();
        final sheet = workbook['Risultati'];
        sheet.appendRow(headers.map((h) => xlsx.TextCellValue(h)).toList());
        for (final record in records) {
          sheet.appendRow(headers.map((h) => xlsx.TextCellValue(_exportCellValue(record[h]))).toList());
        }
        final encoded = workbook.encode();
        if (encoded == null) throw Exception('Creazione del file Excel non riuscita.');
        bytes = Uint8List.fromList(encoded);
        extension = 'xlsx';
      }
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: asPdf ? 'Salva report PDF' : 'Salva elenco Excel',
        fileName: '$baseName.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(savedPath == null
            ? 'Esportazione annullata.'
            : 'File ${extension.toUpperCase()} creato: $savedPath'),
        duration: const Duration(seconds: 5),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Esportazione non riuscita: $e'), duration: const Duration(seconds: 6)),
      );
    }
  }

  Future<void> _consult() async {
    if (widget.apiCode == 'REPORT-COLLECTION-THEME') {
      final term = _search.text.trim();
      if (term.isEmpty) throw Exception('Inserisci un franchise o tema, ad esempio Batman, LEGO City o Saint Seiya.');
      final normalized = term.toLowerCase();
      final all = <Map<String, dynamic>>[];
      const batchSize = 500;
      var offset = 0;
      while (true) {
        final page = await Supabase.instance.client.schema('collection')
            .from('master_oggetti').select('*')
            .range(offset, offset + batchSize - 1);
        final rows = (page as List).map((r) => Map<String, dynamic>.from(r as Map)).toList();
        all.addAll(rows);
        if (rows.length < batchSize) break;
        offset += batchSize;
        if (offset >= 100000) throw Exception('Il catalogo supera il limite di sicurezza della ricerca. Riduci il perimetro o usa un indice server.');
      }
      // Cerca ricorsivamente in TUTTI i campi del record, inclusi metadati JSON
      // e colonne non note in anticipo. Non dipende da nomi ipotizzati come "tema".
      String flattenSearchable(dynamic value) {
        if (value == null) return '';
        if (value is Map) {
          return value.entries
              .map((entry) => '${entry.key} ${flattenSearchable(entry.value)}')
              .join(' ');
        }
        if (value is Iterable) {
          return value.map(flattenSearchable).join(' ');
        }
        return value.toString();
      }

      final matched = <Map<String, dynamic>>[];
      final seen = <String>{};
      for (final row in all) {
        final searchable = flattenSearchable(row).toLowerCase();
        if (!searchable.contains(normalized)) continue;
        final id = (row['codice_oggetto'] ?? row['id'] ?? '').toString();
        final uniqueKey = id.isNotEmpty ? id : jsonEncode(row);
        if (seen.add(uniqueKey)) matched.add(row);
      }
      if (!mounted) return;
      setState(() {
        _rows = matched;
        _currentObject = null;
        _output = 'Report franchise/tema: "$term" · ${matched.length} oggetti unici trovati nel catalogo completo.';
      });
      return;
    }
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

    final periodArgs = _isPeriodReport ? _reportDateArguments() : <String, dynamic>{};
    const pageSize = 100;
    final args = _isPeriodReport
      ? <String, dynamic>{'data_da': periodArgs['data_da'], 'data_a': periodArgs['data_a'], 'limite': pageSize, 'offset': 0}
      : widget.apiCode == 'OBJECT_MASTER'
        ? {'codice_oggetto': int.tryParse(_code.text.trim())}
        : {'cerca': _search.text.trim(), 'limite': pageSize, 'offset': 0};
    final response = await _ValoraRuntimeApi.call('consultation', {
      'session_id': _sessionId, 'consultation_code': widget.apiCode, 'arguments': args,
    });
    final result = response['result'];
    dynamic data = result is Map ? (result['risultato'] ?? result) : result;

    // Carica le pagine successive automaticamente: l'elenco completo rimane
    // scorrevole e anche l'esportazione include tutti i record recuperati.
    if (widget.apiCode != 'OBJECT_MASTER') {
      final firstList = _isPeriodReport && data is Map
          ? ((data as Map)['record'] is List ? List<dynamic>.from((data as Map)['record'] as List) : <dynamic>[])
          : (data is List ? List<dynamic>.from(data as List) : <dynamic>[]);
      if (firstList.length == pageSize) {
        final allRows = <dynamic>[...firstList];
        var offset = pageSize;
        String signature(List<dynamic> rows) => rows.isEmpty
            ? ''
            : '${jsonEncode(rows.first)}|${jsonEncode(rows.last)}|${rows.length}';
        var previousSignature = signature(firstList);
        for (var page = 1; page < 100; page++) {
          final nextArgs = <String, dynamic>{...args, 'limite': pageSize, 'offset': offset};
          final nextResponse = await _ValoraRuntimeApi.call('consultation', {
            'session_id': _sessionId,
            'consultation_code': widget.apiCode,
            'arguments': nextArgs,
          });
          final nextResult = nextResponse['result'];
          final nextData = nextResult is Map ? (nextResult['risultato'] ?? nextResult) : nextResult;
          final nextList = _isPeriodReport && nextData is Map
              ? ((nextData as Map)['record'] is List ? List<dynamic>.from((nextData as Map)['record'] as List) : <dynamic>[])
              : (nextData is List ? List<dynamic>.from(nextData as List) : <dynamic>[]);
          if (nextList.isEmpty) break;
          final nextSignature = signature(nextList);
          if (nextSignature == previousSignature) break;
          allRows.addAll(nextList);
          previousSignature = nextSignature;
          if (nextList.length < pageSize) break;
          offset += pageSize;
        }
        if (_isPeriodReport && data is Map) {
          data = <String, dynamic>{...Map<String, dynamic>.from(data as Map), 'record': allRows};
        } else {
          data = allRows;
        }
      }
    }
    if (_isPeriodReport && data is Map) {
      final report = Map<String, dynamic>.from(data);
      final recordList = report['record'];
      final list = recordList is List ? recordList : <dynamic>[];
      final periodLabel = '${periodArgs['data_da']} – ${periodArgs['data_a']}';
      final totalKeys = ['totale_venduto', 'totale_acquisti', 'totale'];
      final countKeys = ['numero_vendite', 'numero_acquisti', 'numero_movimenti'];
      String? firstKey(List<String> keys) {
        for (final key in keys) { if (report.containsKey(key)) return key; }
        return null;
      }
      final totalKey = firstKey(totalKeys);
      final countKey = firstKey(countKeys);
      double amount(dynamic value) {
        if (value is num) return value.toDouble();
        return double.tryParse((value ?? '0').toString().replaceAll(',', '.')) ?? 0;
      }
      String euro(dynamic value) {
        final n = amount(value);
        final fixed = n.toStringAsFixed(2).split('.');
        final whole = fixed[0].replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (_) => '.');
        return '${whole},${fixed[1]} €';
      }
      final isCash = widget.apiCode == 'REPORT-CASH';
      final totalSales = amount(report['entrate_vendite'] ?? report['totale_venduto'] ?? report['totale_vendite'] ?? report['totale'] ?? 0);
      final totalPurchases = amount(report['uscite_acquisti'] ?? report['totale_acquisti'] ?? report['totale'] ?? 0);
      final total = totalKey == null ? 0.0 : amount(report[totalKey]);
      final summary = [
        'Periodo: $periodLabel',
        if (countKey != null) 'Operazioni: ${report[countKey]}',
        if (isCash) 'Totale entrate: ${euro(totalSales)}',
        if (isCash) 'Totale uscite: ${euro(totalPurchases)}',
        if (isCash) 'Risultato (entrate − uscite): ${euro(totalSales - totalPurchases)}',
        if (!isCash) 'Totale periodo: ${euro(total)}',
      ].join('\\n');
      setState(() {
        _rows = list;
        // Per questi report mostriamo un riepilogo leggibile, non il JSON grezzo.
        _output = summary;
        _currentObject = null;
      });
      return;
    }
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

    // La scheda OGGETTO contiene solo i dati inseriti e gestionali.
    // I dati identificativi del prodotto sono mostrati esclusivamente in METADATI.
    const metadataKeys = {
      'produttore', 'marca', 'brand', 'linea', 'famiglia', 'categoria',
      'anno_uscita', 'anno', 'data_uscita', 'data_di_uscita',
      'codice_prodotto', 'ean', 'gtin', 'upc', 'isbn', 'issn', 'mpn', 'sku',
      'serie', 'licenza', 'franchise', 'tema', 'materiale', 'scala',
      'edizione', 'numero_serie', 'fonte', 'fonte_dati_prodotto',
      'fonte_dati', 'url_fonte', 'url_prodotto', 'fonte_campi',
      'metadati', 'metadata',
    };
    final entries = object.entries.where((e) {
      final key = e.key.toLowerCase();
      final metadataLike = metadataKeys.contains(key) ||
          key.contains('metad') || key.contains('produttore') ||
          key.contains('fonte') || key.contains('anno_uscita') ||
          key == 'codice_prodotto';
      return !imageKeys.contains(e.key) &&
          !summaryKeys.contains(e.key) &&
          !metadataLike;
    }).toList();
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

  Widget _pr11MetadataTab(Map<String, dynamic> object) {
    const keys = {
      'produttore', 'marca', 'brand', 'linea', 'famiglia', 'categoria',
      'anno_uscita', 'anno', 'codice_prodotto', 'ean', 'gtin', 'upc',
      'isbn', 'issn', 'mpn', 'sku', 'serie', 'licenza', 'franchise',
      'tema', 'materiale', 'scala', 'edizione', 'numero_serie',
      'fonte', 'fonte_dati_prodotto', 'fonte_dati', 'url_fonte',
      'url_prodotto', 'fonte_campi', 'metadati', 'metadata',
    };
    const excluded = {
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine', 'image',
      'imageUrl', 'photo_url', 'main_image_url', 'id', 'codice_oggetto',
      'descrizione_oggetto', 'descrizione', 'nome', 'destinazione',
      'condizione', 'stato', 'stato_oggetto', 'valore_oggetto', 'valore',
      'valore_stimato', 'prezzo_acquisto', 'prezzo_vendita', 'quantita',
      'collegato_vendita', 'collegato_acquisto', 'collegato_inserzione',
      'collegato_piattaforma', 'created_at', 'updated_at', 'deleted_at',
      'record_id', 'versione_record', 'modificabile_pr02', 'motivo_esclusione',
    };
    final fields = object.entries.where((e) =>
      !excluded.contains(e.key) &&
      (keys.contains(e.key) ||
       e.key.toLowerCase().contains('metad') ||
       e.key.toLowerCase().contains('fonte') ||
       e.key.toLowerCase().contains('codice') ||
       e.key.toLowerCase().contains('produttore') ||
       e.key.toLowerCase().contains('anno'))
    ).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('METADATI DELL’OGGETTO',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (fields.isEmpty)
            const Text('Nessun metadato disponibile nella scheda caricata. La ricerca e il salvataggio dei metadati restano affidati a PR12.')
          else
            ...fields.map((e) => _detailFieldCard(e.key, e.value)),
        ]),
      ),
    );
  }

  Widget _pr11CommercialTab(Map<String, dynamic> object) {
    const keys = {
      'destinazione', 'condizione', 'stato', 'stato_oggetto', 'quantita',
      'completezza', 'valore_mercato', 'valore_mercato_eur', 'valuta_valore',
      'valuta', 'prezzo_acquisto', 'prezzo_vendita', 'valore_oggetto',
      'valore', 'valore_stimato', 'collegato_vendita', 'collegato_acquisto',
      'collegato_inserzione', 'collegato_piattaforma', 'piattaforma',
      'stato_verifica_dati', 'motivo_esclusione', 'modificabile_pr02',
      'created_at', 'updated_at', 'data_inserimento', 'data_creazione',
      'data_modifica', 'record_id', 'deleted_at', 'versione_record',
      'id', 'costo', 'ricavo', 'margine', 'prezzo', 'vendita', 'acquisto',
      'valutazione', 'storico',
    };
    final fields = object.entries.where((e) =>
      keys.contains(e.key) ||
      e.key.toLowerCase().contains('vendit') ||
      e.key.toLowerCase().contains('acquist') ||
      e.key.toLowerCase().contains('piattaform') ||
      e.key.toLowerCase().contains('valutaz') ||
      e.key.toLowerCase().contains('storico') ||
      e.key.toLowerCase().contains('prezzo') ||
      e.key.toLowerCase().contains('margine')
    ).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DATI TECNICI E COMMERCIALI',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (fields.isEmpty)
            const Text('Nessun dato tecnico o commerciale aggiuntivo disponibile nella scheda caricata.')
          else
            ...fields.map((e) => _detailFieldCard(e.key, e.value)),
          const SizedBox(height: 8),
          Text('Questa vista mostra i dati già caricati nella scheda; acquisti, vendite e storico non vengono interrogati separatamente se non sono inclusi nel record restituito dal database.',
            style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 12)),
        ]),
      ),
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
          _pr11SummaryValue('Destinazione', destination),
          _pr11SummaryValue('Condizione', condition),
          _pr11SummaryValue('Stato', state),
          _pr11SummaryValue('Valore registrato', value),
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

  Future<void> _retryObjectCardImage(Map<String, dynamic> item, String failedUrl) async {
    final id = int.tryParse((item['codice_oggetto'] ?? item['id'] ?? '').toString());
    if (id == null || id <= 0 || failedUrl.isEmpty) return;
    final retryKey = '$id|$failedUrl';
    if (!_objectCardImageRetries.add(retryKey)) return;

    String? alternative;
    try {
      final rows = await Supabase.instance.client
          .schema('collection')
          .from('immagini_oggetto')
          .select('riferimento_immagine, url_fonte, immagine_principale')
          .eq('codice_oggetto', id)
          .order('immagine_principale', ascending: false)
          .limit(20);
      for (final imageRow in rows) {
        for (final key in ['riferimento_immagine', 'url_fonte']) {
          final candidate = (imageRow[key] ?? '').toString().trim();
          if ((candidate.startsWith('https://') || candidate.startsWith('http://')) &&
              candidate != failedUrl) {
            alternative = candidate;
            break;
          }
        }
        if (alternative != null) break;
      }
    } catch (e) {
      debugPrint('VALORA: fallback immagine scheda/lista non disponibile per $id: $e');
    }

    if (alternative == null) {
      try {
        final metadata = await Supabase.instance.client
            .schema('collection')
            .from('master_metadati')
            .select('url_immagine')
            .eq('codice_oggetto', id)
            .maybeSingle();
        final candidate = (metadata?['url_immagine'] ?? '').toString().trim();
        if ((candidate.startsWith('https://') || candidate.startsWith('http://')) &&
            candidate != failedUrl) {
          alternative = candidate;
        }
      } catch (e) {
        debugPrint('VALORA: URL catalografico alternativo non disponibile per $id: $e');
      }
    }

    if (!mounted || alternative == null || alternative == failedUrl) return;
    setState(() => _objectCardImageFallbacks[id] = alternative!);
  }

  Widget _objectCard(
    Map<String, dynamic> item, {
    VoidCallback? onTap, bool availableStyle = false, bool showImagePlaceholder = true,
  }) {
    final code = _valueFor(item, ['codice_oggetto', 'id'], 'Codice n/d');
    final desc = _valueFor(item, ['descrizione_oggetto', 'descrizione', 'nome'], 'Oggetto senza descrizione');
    String firstImage(dynamic value) {
      const imageKeys = <String>[
        'url_immagine_catalogo', 'url_immagine', 'immagine_url', 'foto_url',
        'image_url', 'immagine_principale', 'url_foto', 'foto', 'immagine',
        'image', 'imageUrl', 'photo_url', 'main_image_url', 'image_uri',
        'photo_uri', 'url_foto_principale', 'percorso_immagine',
      ];
      if (value is Map) {
        for (final key in imageKeys) {
          final candidate = value[key];
          if (candidate is String && (candidate.startsWith('https://') || candidate.startsWith('http://'))) {
            return candidate.trim();
          }
        }
        // Alcuni runtime restituiscono i metadati immagine annidati in JSON.
        for (final nested in value.values) {
          final found = firstImage(nested);
          if (found.isNotEmpty) return found;
        }
      } else if (value is Iterable) {
        for (final nested in value) {
          final found = firstImage(nested);
          if (found.isNotEmpty) return found;
        }
      } else if (value is String) {
        final trimmed = value.trim();
        if (trimmed.startsWith('https://') || trimmed.startsWith('http://')) return trimmed;
      }
      return '';
    }
    final itemId = int.tryParse((item['codice_oggetto'] ?? item['id'] ?? '').toString());
    final imageUrl = (itemId == null ? null : _objectCardImageFallbacks[itemId]) ?? firstImage(item);
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
            if (showImagePlaceholder) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.startsWith('http')
                  ? Image.network(_valoraImageProxyUrl(imageUrl), width: imageSize, height: imageSize, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        _retryObjectCardImage(item, imageUrl);
                        return _imagePlaceholder(size: imageSize);
                      })
                  : _imagePlaceholder(size: imageSize),
              ),
              const SizedBox(width: 12),
            ],
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
                    SelectableText(_pr12RetryRunning ? 'Nuovo tentativo sui record irrisolti in corso…' : _pr12AiBatchStatus),
                    if (_pr12UnresolvedRecords.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('DA RIPROVARE: ${_pr12UnresolvedRecords.length}', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(
                        onPressed: _pr12AiBatchRunning ? null : () => _runPr12AiBatch(retryUnresolved: true),
                        icon: const Icon(Icons.refresh),
                        label: Text(_pr12AiBatchRunning ? 'RICERCA IN CORSO…' : 'RIPROVA I PROSSIMI 10 IRRISOLTI'),
                      )),
                    ],
                    if (_pr12NextBatchOffset < _pr12IncompleteRecords.length) ...[
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: OutlinedButton.icon(
                        onPressed: _pr12AiBatchRunning ? null : () => _runPr12AiBatch(),
                        icon: const Icon(Icons.skip_next),
                        label: Text('ELABORA PROSSIMO LOTTO · ${(_pr12IncompleteRecords.length - _pr12NextBatchOffset).clamp(0, 10)} DI ${_pr12IncompleteRecords.length - _pr12NextBatchOffset} RECORD'),
                      )),
                    ],
                    if (_pr12AiResults.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('RISULTATI RICERCA (${_pr12AiResults.length})', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      ..._pr12AiResults.map((result) {
                        final candidates = result['risultati'];
                        final candidateList = candidates is List ? candidates : const [];
                        final objectId = (result['oggetto_id'] ?? '').toString();
                        final selectedIndex = _pr12SelectedCandidates[objectId];
                        return Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('#${result['oggetto_id'] ?? ''} · ${result['descrizione'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(result['ok'] != true ? 'Errore tecnico: ${result['error'] ?? 'ricerca non riuscita'}' : (((result['numero_risultati'] as num?) ?? candidateList.length) == 0 ? 'Nessuna corrispondenza pertinente trovata' : '${result['numero_risultati'] ?? candidateList.length} candidati da verificare')),
                          ...candidateList.take(5).toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value is Map ? Map<String, dynamic>.from(entry.value as Map) : <String, dynamic>{};
                            final imageUrl = (item['image_url'] ?? item['immagine'] ?? '').toString().trim();
                            final title = (item['title'] ?? 'Titolo non disponibile').toString().trim();
                            final snippet = (item['snippet'] ?? '').toString().trim();
                            final url = (item['url'] ?? '').toString().trim();
                            final maker = (item['produttore'] ?? item['editore'] ?? '').toString().trim();
                            final year = (item['anno_uscita'] ?? item['anno'] ?? '').toString().trim();
                            final productCode = (item['codice_prodotto'] ?? item['codice'] ?? item['isbn'] ?? '').toString().trim();
                            final source = Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\\.'), '') ?? '';
                            final selected = selectedIndex == index;
                            return InkWell(onTap: () => setState(() => _pr12SelectedCandidates[objectId] = index), child: Container(
                              margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(border: Border.all(color: selected ? sectionColor : ValoraAppearance.instance.neutralOverlayStrong, width: selected ? 2 : 1), borderRadius: BorderRadius.circular(12), color: selected ? ValoraAppearance.instance.neutralOverlay : null),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  if (imageUrl.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          imageUrl,
                                          width: 92,
                                          height: 112,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stack) => Container(
                                            width: 92,
                                            height: 112,
                                            alignment: Alignment.center,
                                            color: ValoraAppearance.instance.neutralOverlay,
                                            child: const Icon(Icons.image_not_supported_outlined, size: 28),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Container(
                                        width: 92,
                                        height: 112,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: ValoraAppearance.instance.neutralOverlay,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_search_outlined, size: 30),
                                            SizedBox(height: 5),
                                            Text('Nessuna immagine', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? sectionColor : null), const SizedBox(width: 5), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)))]),
                                    if (maker.isNotEmpty) Text('Produttore / editore: $maker'),
                                    if (year.isNotEmpty) Text('Anno: $year'),
                                    if (productCode.isNotEmpty) Text('Codice / ISBN: $productCode'),
                                    Text('Fonte: ${source.isEmpty ? 'sito non identificato' : source}', style: TextStyle(color: sectionColor, fontSize: 12)),
                                  ])),
                                ]),
                                if (snippet.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(snippet, maxLines: 5, overflow: TextOverflow.ellipsis)),
                                if (url.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: SelectableText(url, style: TextStyle(color: sectionColor, fontSize: 12))),
                                if (selected) Padding(padding: const EdgeInsets.only(top: 8), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _pr12ApplySelectedCandidate(result, item), icon: const Icon(Icons.check_circle_outline), label: const Text('APPLICA METADATI SE DISPONIBILI')))),
                                const SizedBox(height: 4),
                                Text('Candidato da verificare: selezionalo per applicare eventuali metadati strutturati.', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
                              ]),
                            ));
                          }),
                        ])));
                      }),
                    ],                    if (_pr12IncompleteRecords.isNotEmpty) ...[
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
                          trailing: IconButton(
                            tooltip: 'Cerca metadati per questo singolo record',
                            onPressed: _pr12AiBatchRunning ? null : () => _runPr12AiBatch(singleRecord: row),
                            icon: const Icon(Icons.manage_search),
                          ),
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
                      const Text('I candidati qui sopra sono solo proposte. Il record viene aggiornato esclusivamente dopo aver selezionato un candidato e confermato l’operazione; gli altri campi già compilati vengono conservati.'),
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
                const SizedBox(height: 10),
                _imageField(),
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
        if (_isPeriodReport) ...[
          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PERIODO DEL REPORT', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<String>(contentPadding: EdgeInsets.zero, dense: true, title: const Text('Mese corrente'),
                value: 'month', groupValue: _reportPeriodMode, onChanged: (v) => setState(() => _reportPeriodMode = v!)),
              RadioListTile<String>(contentPadding: EdgeInsets.zero, dense: true, title: const Text('Anno corrente'),
                value: 'year', groupValue: _reportPeriodMode, onChanged: (v) => setState(() => _reportPeriodMode = v!)),
              RadioListTile<String>(contentPadding: EdgeInsets.zero, dense: true, title: const Text('Intervallo personalizzato'),
                value: 'custom', groupValue: _reportPeriodMode, onChanged: (v) => setState(() => _reportPeriodMode = v!)),
              if (_reportPeriodMode == 'custom') ...[
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pickReportDate(isStart: true),
                    icon: const Icon(Icons.calendar_today_outlined), label: Text('Dal ${_dateLabel(_reportStart)}'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pickReportDate(isStart: false),
                    icon: const Icon(Icons.event_outlined), label: Text('Al ${_dateLabel(_reportEnd)}'))),
                ]),
              ],
              const SizedBox(height: 4),
              Text('Le date selezionate vengono applicate alla query del database.',
                style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
            ]),
          )),
          const SizedBox(height: 10),
        ],
        if (!_isWrite && !isMaster && !isHistory && !isAvailableList && !_isPeriodReport)
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
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
                          backgroundColor: _pr11MasterTabIndex == 0 ? sectionColor : ValoraAppearance.instance.card,
                          foregroundColor: _pr11MasterTabIndex == 0 ? Colors.black : ValoraAppearance.instance.textPrimary,
                        ),
                        onPressed: () => setState(() => _pr11MasterTabIndex = 0),
                        child: const Text('OGGETTO', textAlign: TextAlign.center, maxLines: 1, softWrap: false),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
                          backgroundColor: _pr11MasterTabIndex == 1 ? sectionColor : ValoraAppearance.instance.card,
                          foregroundColor: _pr11MasterTabIndex == 1 ? Colors.black : ValoraAppearance.instance.textPrimary,
                        ),
                        onPressed: () => setState(() => _pr11MasterTabIndex = 1),
                        child: const Text('METADATI', textAlign: TextAlign.center, maxLines: 1, softWrap: false),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
                          backgroundColor: _pr11MasterTabIndex == 2 ? sectionColor : ValoraAppearance.instance.card,
                          foregroundColor: _pr11MasterTabIndex == 2 ? Colors.black : ValoraAppearance.instance.textPrimary,
                        ),
                        onPressed: () => setState(() => _pr11MasterTabIndex = 2),
                        child: const Text('DATI TECNICI', textAlign: TextAlign.center, maxLines: 1, softWrap: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (_pr11MasterTabIndex == 0) ...[
              _readOnlyImageCard(),
              _pr11HeaderCard(_currentObject!),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('DATI INSERITI NELLA SCHEDA',
                      style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _masterDetails(_currentObject!),
                  ]),
                ),
              ),
            ] else if (_pr11MasterTabIndex == 1)
              _pr11MetadataTab(_currentObject!)
            else
              _pr11CommercialTab(_currentObject!)
          ] else if (isHistory) ...[
            Text(
              _valueFor(_currentObject!, ['descrizione_oggetto', 'descrizione', 'nome'], 'Oggetto senza descrizione'),
              style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text('SCHEDA OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 18)),
            _objectCard(_currentObject!, showImagePlaceholder: false),
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
            if (_isPeriodReport) {
              final dateValue = item['data_vendita'] ?? item['data_acquisto'] ?? item['data'] ?? item['data_inizio_vendita'] ?? 'Data non indicata';
              final description = item['descrizione_oggetto'] ?? item['descrizione'] ?? item['tipologia'] ?? item['tipo_movimento'] ?? 'Operazione';
              final amount = item['importo_vendita'] ?? item['importo_totale_acquisto'] ?? item['importo'] ?? item['prezzo_di_vendita'];
              return Card(child: ListTile(
                leading: Icon(Icons.receipt_long_outlined, color: sectionColor),
                title: Text(description.toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$dateValue · ${item['codice_vendita'] ?? item['codice_acquisto'] ?? item['codice_movimento'] ?? ''}'),
                trailing: amount == null ? null : Text('${amount.toString()} ${item['valuta'] ?? 'EUR'}'),
                onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
                  title: const Text('Dettaglio operazione'),
                  content: SingleChildScrollView(child: SelectableText(_pretty(item))),
                  actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('CHIUDI'))],
                )),
              ));
            }
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
          if (widget.apiCode == 'REPORT-CASH') ...[
            const SizedBox(height: 18),
            Builder(builder: (context) {
              double parseMoney(dynamic value) {
                if (value is num) return value.toDouble();
                var raw = (value ?? '').toString().trim()
                    .replaceAll('€', '').replaceAll('EUR', '')
                    .replaceAll(RegExp(r'\\s+'), '');
                if (raw.isEmpty) return 0;
                if (raw.contains(',') && raw.contains('.')) {
                  raw = raw.lastIndexOf(',') > raw.lastIndexOf('.')
                      ? raw.replaceAll('.', '').replaceAll(',', '.')
                      : raw.replaceAll(',', '');
                } else if (raw.contains(',')) {
                  raw = raw.replaceAll(',', '.');
                }
                return double.tryParse(raw) ?? 0;
              }
              double fieldAmount(Map<String, dynamic> row, List<String> keys) {
                for (final key in keys) {
                  final value = row[key];
                  if (value != null && value.toString().trim().isNotEmpty) {
                    return parseMoney(value);
                  }
                }
                return 0;
              }
              var entries = 0.0;
              var exits = 0.0;
              for (final raw in _rows) {
                if (raw is! Map) continue;
                final row = Map<String, dynamic>.from(raw);
                entries += fieldAmount(row, ['entrata','importo_entrata','totale_entrate','entrate']);
                exits += fieldAmount(row, ['uscita','importo_uscita','totale_uscite','uscite']);
                // Alcuni movimenti possono esporre un unico importo e una categoria.
                final hasEntry = ['entrata','importo_entrata','totale_entrate','entrate'].any((k) => row[k] != null);
                final hasExit = ['uscita','importo_uscita','totale_uscite','uscite'].any((k) => row[k] != null);
                if (!hasEntry && !hasExit) {
                  final amount = fieldAmount(row, ['importo','importo_totale','amount']);
                  final kind = '${row['tipo'] ?? row['tipo_movimento'] ?? row['categoria'] ?? ''}'.toLowerCase();
                  if (kind.contains('entrata') || kind.contains('vendita') || kind.contains('accredito')) {
                    entries += amount;
                  } else if (kind.contains('uscita') || kind.contains('acquisto') || kind.contains('spesa') || kind.contains('giroconto')) {
                    exits += amount;
                  }
                }
              }
              String euro(double value) {
                final fixed = value.toStringAsFixed(2).split('.');
                final whole = fixed[0].replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (_) => '.');
                return '${whole},${fixed[1]} €';
              }
              final balance = entries - exits;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sectionColor.withValues(alpha: 0.55)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('RIEPILOGO FLUSSI DI CASSA', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Expanded(child: Text('TOTALE ENTRATE')),
                    Text(euro(entries), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Expanded(child: Text('TOTALE USCITE')),
                    Text(euro(exits), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  const Divider(height: 18),
                  Row(children: [
                    const Expanded(child: Text('SALDO (ENTRATE − USCITE)', style: TextStyle(fontWeight: FontWeight.bold))),
                    Text(euro(balance), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: balance >= 0 ? Colors.green : Colors.red)),
                  ]),
                  const SizedBox(height: 4),
                  Text('${_rows.length} operazioni elencate', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
                ]),
              );
            }),
          ],
          if (_isPeriodReport && widget.apiCode != 'REPORT-CASH') ...[
            const SizedBox(height: 18),
            Builder(builder: (context) {
              double parseAmount(dynamic value) {
                if (value is num) return value.toDouble();
                var raw = (value ?? '').toString().trim()
                    .replaceAll('€', '').replaceAll('EUR', '')
                    .replaceAll(RegExp(r'\\s+'), '');
                if (raw.isEmpty) return 0;
                if (raw.contains(',') && raw.contains('.')) {
                  raw = raw.lastIndexOf(',') > raw.lastIndexOf('.')
                      ? raw.replaceAll('.', '').replaceAll(',', '.')
                      : raw.replaceAll(',', '');
                } else if (raw.contains(',')) {
                  raw = raw.replaceAll(',', '.');
                }
                return double.tryParse(raw) ?? 0;
              }
              double amountFor(Map<String, dynamic> item) {
                final keys = widget.apiCode == 'REPORT-SALES'
                    ? <String>['importo_vendita','prezzo_di_vendita','importo_totale','importo','totale','prezzo']
                    : <String>['importo_totale_acquisto','importo_acquisto','prezzo_di_acquisto','importo','totale','prezzo'];
                for (final key in keys) {
                  if (item[key] != null && item[key].toString().trim().isNotEmpty) {
                    return parseAmount(item[key]);
                  }
                }
                return 0;
              }
              final total = _rows.whereType<Map>()
                  .map((item) => amountFor(Map<String, dynamic>.from(item)))
                  .fold<double>(0, (sum, value) => sum + value);
              final label = widget.apiCode == 'REPORT-SALES'
                  ? 'TOTALE VENDITE'
                  : widget.apiCode == 'REPORT-PURCHASES'
                      ? 'TOTALE ACQUISTI'
                      : 'TOTALE OPERAZIONI';
              final money = total.toStringAsFixed(2).replaceAll('.', ',');
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: sectionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sectionColor.withValues(alpha: 0.55)),
                ),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${_rows.length} operazioni elencate', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
                    ],
                  )),
                  Text('$money €', style: TextStyle(color: ValoraAppearance.instance.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
              );
            }),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _exportResults(asPdf: false),
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('CREA FILE EXCEL'),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(
              onPressed: _loading ? null : () => _exportResults(asPdf: true),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('CREA FILE PDF'),
            )),
          ]),
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
        if (code != 'PR-01' && code != 'PR-02' && code != 'PR-03' && !isMaster && !isAvailableList && !isHistory && code != 'REPORT-CASH' && code != 'REPORT-PURCHASES' && code != 'REPORT-SALES') ...[
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
        _existingImageUrl = null;
        _selectedImageBytes = null;
        _selectedImageName = null;
        _imageStatus = 'Nessuna immagine selezionata.';
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
    if (_selectedImageBytes != null && _selectedImageName != null) {
      _pr02PendingImages[item['codice_oggetto'].toString()] = {
        'bytes': Uint8List.fromList(_selectedImageBytes!), 'name': _selectedImageName!, 'acquisition': _imageAcquisition,
      };
    }

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
        _selectedImageBytes = null; _selectedImageName = null; _existingImageUrl = null;
        _imageStatus = 'Nessuna immagine selezionata.';
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
      final pendingImage = _pr02PendingImages[item['codice_oggetto'].toString()];
      if (item.length > 1) await _acquireLock();
      try {
        if (item.length > 1) {
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
        }
        if (pendingImage != null) {
          final signedUrl = await _uploadAndRegisterImage(
            objectId: int.parse(item['codice_oggetto'].toString()), bytes: pendingImage['bytes'] as Uint8List,
            fileName: pendingImage['name'] as String, acquisition: pendingImage['acquisition'] as String, procedure: 'PR-02');
          _pr02PendingImages.remove(item['codice_oggetto'].toString());
          if (_loadedObjectId == int.tryParse(item['codice_oggetto'].toString()) && mounted) {
            setState(() { _existingImageUrl = signedUrl; _imageStatus = 'Immagine associata e verificata.'; });
          }
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
      final savedRows = result['risultati'];
      final savedRow = savedRows is List && savedRows.isNotEmpty && savedRows.first is Map
        ? Map<String, dynamic>.from(savedRows.first as Map) : <String, dynamic>{};
      final savedId = int.tryParse((savedRow['codice_oggetto'] ?? '').toString());
      if (_selectedImageBytes != null && _selectedImageName != null && savedId != null) {
        try {
          final signedUrl = await _uploadAndRegisterImage(
            objectId: savedId, bytes: Uint8List.fromList(_selectedImageBytes!), fileName: _selectedImageName!,
            acquisition: _imageAcquisition, procedure: 'PR-01');
          if (mounted) setState(() {
            _existingImageUrl = signedUrl; _selectedImageBytes = null; _selectedImageName = null;
            _imageStatus = 'Immagine caricata e associata all’oggetto #$savedId.';
          });
        } catch (e) {
          if (mounted) setState(() {
            _selectedImageBytes = null; _selectedImageName = null;
            _imageStatus = 'Oggetto #$savedId salvato, ma immagine non associata: $e. Puoi riprovare caricandola da PR-02.';
          });
        }
      }
      _description.clear(); _producer.clear(); _line.clear(); _family.clear();
      _notes.clear(); _quantity.text = '1'; _unitPrice.clear(); _totalValue.clear();
    }
  }
}



class _PurchaseItemDraft {
  final description = TextEditingController();
  final price = TextEditingController();
  Uint8List? photoBytes;
  String? photoName;
  String? photoUrl;
  String? metadataProducer;
  String? metadataCode;
  int? metadataYear;
  String? metadataSourceUrl;
  String photoStatus = 'Nessuna foto selezionata.';
  String destination = 'COLLEZIONE';
  String condition = 'USATO';
  String completeness = 'COMPLETO';
  double? get amount {
    var s = price.text.trim().replaceAll('€', '').replaceAll(' ', '');
    if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }
  Map<String, dynamic> json() => {
    'descrizione': description.text.trim(), 'valore_acquisto': amount,
    'destinazione': destination, 'condizione': condition,
    'completezza': completeness, 'quantita': 1,
    if (metadataProducer != null) 'produttore': metadataProducer,
    if (metadataCode != null) 'codice_prodotto': metadataCode,
    if (metadataYear != null) 'anno_uscita': metadataYear,
    if (metadataSourceUrl != null) 'fonte_dati_prodotto': metadataSourceUrl,
    if (metadataProducer != null || metadataCode != null || metadataYear != null)
      'stato_verifica_dati': 'DA_VERIFICARE',
    if (photoUrl != null) 'url_immagine_catalogo': photoUrl,
  };
  void dispose() { description.dispose(); price.dispose(); }
}

/// PR-04: una transazione sola; un record oggetto distinto per ogni elemento.
class NewPurchasePage extends StatefulWidget {
  const NewPurchasePage({super.key});
  @override
  State<NewPurchasePage> createState() => _NewPurchasePageState();
}

class _NewPurchasePageState extends State<NewPurchasePage> {
  int _step = 0;
  String _type = 'SINGOLO';
  final _count = TextEditingController(text: '2');
  DateTime _date = DateTime.now();
  final List<_PurchaseItemDraft> _items = [_PurchaseItemDraft()];
  final String _session = _uuid.v4();
  bool _busy = false, _locked = false, _dataConfirmed = false;
  Map<String, dynamic>? _preview;
  String _status = 'Bozza locale: nessun acquisto registrato.';

  @override
  void dispose() { _count.dispose(); for (final i in _items) { i.dispose(); } super.dispose(); }

  String _dateLabel(DateTime d) =>
      d.day.toString().padLeft(2, '0') + '/' +
      d.month.toString().padLeft(2, '0') + '/' + d.year.toString();
  double get _total => _items.fold<double>(0, (sum, i) => sum + (i.amount ?? 0));
  void _notice(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _photoAndRecognize(_PurchaseItemDraft item) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) throw Exception('Foto vuota o superiore a 10 MB.');
      setState(() {
        item.photoBytes = bytes;
        item.photoName = picked.name.isNotEmpty ? picked.name : 'foto_acquisto.jpg';
        item.photoUrl = null;
        item.photoStatus = 'Foto acquisita. Riconoscimento PR-12 in corso…';
      });
      final mime = (item.photoName ?? '').toLowerCase().endsWith('.png') ? 'image/png' : ((item.photoName ?? '').toLowerCase().endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
        'azione': 'ANALIZZA_FOTO', 'modalita_ia': 'TEST',
        'image_data_url': 'data:$mime;base64,${base64Encode(bytes)}', 'mercato': 'Italia',
      });
      final data = response.data;
      if (data is! Map || data['ok'] != true) throw Exception(data is Map ? (data['error'] ?? 'Riconoscimento non riuscito').toString() : 'Risposta PR-12 non valida');
      final clues = data['identificazione'] is Map ? Map<String,dynamic>.from(data['identificazione']) : <String,dynamic>{};
      final results = data['risultati'] is List ? (data['risultati'] as List).whereType<Map>().map((v)=>Map<String,dynamic>.from(v)).toList() : <Map<String,dynamic>>[];
      if (!mounted) return;
      final imageCandidates = results.where((r) {
        final u = (r['image_url'] ?? r['immagine_url'] ?? r['url_immagine'] ?? '').toString().trim();
        return u.startsWith('https://') || u.startsWith('http://');
      }).toList();
      final selection = await showDialog<Map<String, dynamic>>(
        context: context, barrierDismissible: false,
        builder: (ctx) {
          int selected = -1;
          return StatefulBuilder(builder: (ctx, refreshDialog) => AlertDialog(
            title: const Text('PR-12 · Verifica oggetto e immagine'),
            content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
              children: [
                Text('Descrizione proposta: ' + (clues['descrizione_provvisoria'] ?? 'Non rilevata').toString()),
                Text('Marchio: ' + (clues['marchio'] ?? 'Non rilevato').toString()),
                Text('Codice prodotto: ' + (clues['codice_prodotto'] ?? 'Non rilevato').toString()),
                if ((clues['categoria'] ?? '').toString().trim().isNotEmpty) Text('Categoria: ' + clues['categoria'].toString()),
                if (clues['incertezze'] is List && (clues['incertezze'] as List).isNotEmpty)
                  Text('Da verificare: ' + (clues['incertezze'] as List).join(' · ')),
                const Divider(),
                const Text('Scegli l’immagine da associare all’oggetto', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile<int>(
                  value: -1, groupValue: selected,
                  onChanged: (v) => refreshDialog(() => selected = v ?? -1),
                  title: const Text('Mantieni la foto scattata'),
                  subtitle: const Text('La foto del tuo esemplare'),
                  secondary: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.memory(bytes, width: 58, height: 58, fit: BoxFit.cover)),
                  contentPadding: EdgeInsets.zero,
                ),
                if (imageCandidates.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Nessuna immagine online utilizzabile. Puoi mantenere la foto originale.')),
                for (var i = 0; i < imageCandidates.length; i++)
                  RadioListTile<int>(
                    value: i, groupValue: selected,
                    onChanged: (v) => refreshDialog(() => selected = v ?? -1),
                    contentPadding: EdgeInsets.zero,
                    title: Text((imageCandidates[i]['title'] ?? 'Immagine trovata online').toString()),
                    subtitle: Text((imageCandidates[i]['motore'] ?? imageCandidates[i]['url'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    secondary: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(
                      (imageCandidates[i]['image_url'] ?? imageCandidates[i]['immagine_url'] ?? imageCandidates[i]['url_immagine']).toString(),
                      width: 58, height: 58, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 36),
                    )),
                  ),
                const Divider(),
                Text('Risultati catalografici PR-12: ${results.length}. I metadati proposti restano da verificare.'),
                const Text('La ricerca non salva dati nel database.'),
              ],
            ))),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, <String,dynamic>{'annulla': true}), child: const Text('ANNULLA')),
              FilledButton(onPressed: () => Navigator.pop(ctx, <String,dynamic>{
                'use_original': selected < 0,
                if (selected >= 0) 'candidate': imageCandidates[selected],
              }), child: const Text('USA SELEZIONE')),
            ],
          ));
        },
      );
      if (selection == null || selection['annulla'] == true) {
        if (mounted) setState(() => item.photoStatus = 'Ricerca terminata. Foto originale conservata; nessuna proposta applicata.');
        return;
      }
      final selectedCandidate = selection['candidate'] is Map
          ? Map<String,dynamic>.from(selection['candidate'] as Map)
          : (results.isNotEmpty ? results.first : <String,dynamic>{});
      final description = (clues['descrizione_provvisoria'] ?? selectedCandidate['title'] ?? '').toString().trim();
      final maker = (clues['marchio'] ?? selectedCandidate['produttore'] ?? selectedCandidate['editore'] ?? '').toString().trim();
      final code = (clues['codice_prodotto'] ?? selectedCandidate['codice_prodotto'] ?? selectedCandidate['isbn'] ?? '').toString().trim();
      final yearValue = selectedCandidate['anno_uscita'] ?? selectedCandidate['anno_pubblicazione'] ?? selectedCandidate['year'];
      final yearText = yearValue?.toString() ?? '';
      final yearMatch = RegExp(r'(19\d{2}|20\d{2})').firstMatch(yearText);
      final selectedUrl = selection['use_original'] == true ? null
          : (selectedCandidate['image_url'] ?? selectedCandidate['immagine_url'] ?? selectedCandidate['url_immagine'] ?? '').toString().trim();
      if (mounted) setState(() {
        if (description.isNotEmpty) item.description.text = description;
        item.metadataProducer = maker.isEmpty ? null : maker;
        item.metadataCode = code.isEmpty ? null : code;
        item.metadataYear = yearMatch == null ? null : int.tryParse(yearMatch.group(1)!);
        item.metadataSourceUrl = (selectedCandidate['url'] ?? '').toString().trim().isEmpty ? null : selectedCandidate['url'].toString();
        item.photoUrl = selectedUrl != null && (selectedUrl.startsWith('https://') || selectedUrl.startsWith('http://')) ? selectedUrl : null;
        item.photoStatus = item.photoUrl == null
          ? 'Metadati PR-12 proposti. Foto originale selezionata; verifica i dati prima di salvare.'
          : 'Metadati PR-12 proposti. Immagine online selezionata; verifica i dati prima di salvare.';
        _invalidate();
      });
    } catch (e) {
      if (mounted) setState(() => item.photoStatus = 'Riconoscimento non riuscito: $e');
    }
  }
  void _invalidate() { _preview = null; _dataConfirmed = false; }

  void _resize(int n) {
    while (_items.length < n) { _items.add(_PurchaseItemDraft()); }
    while (_items.length > n) { _items.removeLast().dispose(); }
    _invalidate();
  }

  bool _valid() {
    if (_items.isEmpty) { _notice('Inserisci almeno un oggetto.'); return false; }
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].description.text.trim().isEmpty) {
        _notice('Inserisci la descrizione dell’oggetto ' + (i + 1).toString() + '.'); return false;
      }
      final p = _items[i].amount;
      if (p == null || p < 0) {
        _notice('Inserisci un prezzo valido per l’oggetto ' + (i + 1).toString() + '.'); return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _payload({bool confirmed = false, bool finalConfirmation = false}) => {
    // Contratto canonico di collection.pr_04_nuovo_acquisto(p_operazioni):
    // le operazioni sono un array e ogni oggetto usa valore_acquisto.
    'operazioni': [
      {
        'data_acquisto': _date.toIso8601String().substring(0, 10),
        'importo_totale': double.parse(_total.toStringAsFixed(2)),
        'valuta': 'EUR',
        'oggetti': _items.map((e) => e.json()).toList(),
      }
    ],
    'dati_confermati': confirmed,
    'conferma_finale': finalConfirmation,
    'altra_operazione': false,
  };

  Future<bool> _acquire() async {
    final r = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _session});
    final data = r['result'];
    if (data is Map && data['acquisito'] == true) { _locked = true; return true; }
    if (mounted) setState(() => _status =
      (data is Map ? data['messaggio'] : null)?.toString() ?? 'Blocco archivio non acquisito.');
    return false;
  }

  Future<void> _release() async {
    if (!_locked) return;
    try { await _ValoraRuntimeApi.call('release_lock', {'session_id': _session}); }
    finally { _locked = false; }
  }

  Future<void> _runPreview() async {
    if (!_valid()) return;
    setState(() { _busy = true; _status = 'Controllo preliminare in TEST…'; _invalidate(); });
    try {
      if (!await _acquire()) return;
      final r = await _ValoraRuntimeApi.procedure('PR-04', 'preview', _payload(), sessionId: _session);
      if (!mounted) return;
      setState(() { _preview = r; _step = 4; _status = 'Riepilogo pronto. SÌ riparte con un nuovo acquisto senza salvare questo; NO salva e chiude.'; });
    } catch (e) {
      if (mounted) setState(() => _status = 'Controllo non riuscito: ' + e.toString());
    } finally { await _release(); if (mounted) setState(() => _busy = false); }
  }

  Future<void> _save() async {
    if (_preview == null || !_dataConfirmed) {
      _notice('Completa il riepilogo prima di salvare.'); return;
    }
    setState(() { _busy = true; _status = 'Invio del salvataggio al runtime TEST…'; });
    try {
      if (!await _acquire()) return;
      final r = await _ValoraRuntimeApi.procedure('PR-04', 'save',
        _payload(confirmed: true, finalConfirmation: true), sessionId: _session, requestId: _uuid.v4());
      final reread = r['rilettura_database'] ?? r['verifica_post_salvataggio'];
      final rereadCount = reread is List ? reread.length : 0;
      final verified = r['rilettura_verificata'] == true ||
        r['verifica_post_scrittura'] == 'OK' || r['stato'] == 'SALVATO_E_VERIFICATO' ||
        (reread is List && reread.isNotEmpty && reread.every((e) => e is Map && e['verificato'] == true));
      final saved = r['scrittura_eseguita'] == true && verified && rereadCount >= 1;
      if (r['blocco_rilasciato_automaticamente'] == true) _locked = false;
      if (!mounted) return;
      setState(() {
        _preview = r;
        _status = saved
          ? 'Acquisto salvato e rilettura verificata per tutti gli oggetti.'
          : 'Salvataggio NON considerato concluso: il runtime non conferma scrittura e rilettura coerenti per tutti gli oggetti. La bozza resta disponibile.';
      });
      if (saved && mounted) {
        final another = await showDialog<bool>(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
          title: const Text('Acquisto verificato'),
          content: const Text('Vuoi effettuare un altro acquisto?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('NO, TERMINA')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('SÌ, ALTRO ACQUISTO')),
          ],
        ));
        if (!mounted) return;
        if (another == true) {
          for (final i in _items) { i.dispose(); }
          setState(() {
            _step = 0; _type = 'SINGOLO'; _date = DateTime.now();
            _items..clear()..add(_PurchaseItemDraft()); _count.text = '2';
            _preview = null; _dataConfirmed = false; _status = 'Nuova bozza pronta. Nessun acquisto registrato.';
          });
        } else { Navigator.of(context).pop(); }
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Salvataggio non confermato: ' + e.toString());
    } finally { await _release(); if (mounted) setState(() => _busy = false); }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)), helpText: 'DATA DELL’ACQUISTO',
      cancelText: 'ANNULLA', confirmText: 'CONFERMA DATA');
    if (d != null && mounted) setState(() { _date = d; _invalidate(); });
  }

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5), Text(subtitle, style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
    ]));

  Widget _choice(String title, String subtitle, IconData icon, bool selected, VoidCallback onTap) => Card(
    color: selected ? ValoraAppearance.instance.card : null,
    child: ListTile(leading: Icon(icon, color: selected ? goldColor : null), title: Text(title),
      subtitle: Text(subtitle), trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
      onTap: _busy ? null : onTap));

  Widget _itemEditor(int n) {
    final item = _items[n];
    return Card(key: ValueKey('pr04-item-' + n.toString()), margin: const EdgeInsets.only(bottom: 10),
      child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('OGGETTO ' + (n + 1).toString(), style: TextStyle(color: ValoraAppearance.instance.colorFor('ACQUISTI'), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(controller: item.description, decoration: const InputDecoration(labelText: 'Descrizione oggetto *'),
          onChanged: (_) => setState(_invalidate)),
        const SizedBox(height: 6),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: _busy ? null : () => _photoAndRecognize(item),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('SCATTA FOTO · RICONOSCIMENTO PR-12'),
        )),
        if (item.photoUrl != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(item.photoUrl!, height: 130, width: double.infinity, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => item.photoBytes != null
              ? Image.memory(item.photoBytes!, height: 130, width: double.infinity, fit: BoxFit.contain)
              : const Icon(Icons.broken_image_outlined)),
        )) else if (item.photoBytes != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(item.photoBytes!, height: 130, width: double.infinity, fit: BoxFit.contain),
        )),
        Text(item.photoStatus, style: TextStyle(fontSize: 12, color: ValoraAppearance.instance.textSecondary)),
        const SizedBox(height: 8),
        TextField(controller: item.price, keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Prezzo di acquisto (€) *', hintText: 'Es. 25,00'),
          onChanged: (_) => setState(_invalidate)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: item.destination, decoration: const InputDecoration(labelText: 'Destinazione'),
          items: const [DropdownMenuItem(value: 'COLLEZIONE', child: Text('COLLEZIONE')), DropdownMenuItem(value: 'RIVENDITA', child: Text('RIVENDITA'))],
          onChanged: _busy ? null : (v) => setState(() { item.destination = v ?? item.destination; _invalidate(); })),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(value: item.condition, decoration: const InputDecoration(labelText: 'Condizione'),
            items: const [DropdownMenuItem(value: 'NUOVO', child: Text('NUOVO')), DropdownMenuItem(value: 'USATO', child: Text('USATO')), DropdownMenuItem(value: 'DA RIPARARE', child: Text('DA RIPARARE'))],
            onChanged: _busy ? null : (v) => setState(() { item.condition = v ?? item.condition; _invalidate(); }))),
          const SizedBox(width: 8),
          Expanded(child: DropdownButtonFormField<String>(value: item.completeness, decoration: const InputDecoration(labelText: 'Completezza'),
            items: const [DropdownMenuItem(value: 'COMPLETO', child: Text('COMPLETO')), DropdownMenuItem(value: 'INCOMPLETO', child: Text('INCOMPLETO')), DropdownMenuItem(value: 'SOLO PARTI', child: Text('SOLO PARTI'))],
            onChanged: _busy ? null : (v) => setState(() { item.completeness = v ?? item.completeness; _invalidate(); }))),
        ]),
      ])));
  }

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, color: bold ? goldColor : null))),
      const SizedBox(width: 8), Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: bold ? goldColor : null))),
    ]));

  Widget _content() {
    if (_step == 0) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Che tipo di acquisto vuoi registrare?', 'Una transazione può contenere uno o più oggetti.'),
      _choice('ACQUISTO SINGOLO', 'Una transazione · un oggetto', Icons.shopping_bag_outlined, _type == 'SINGOLO',
        () => setState(() { _type = 'SINGOLO'; _resize(1); _count.text = '1'; })),
      _choice('ACQUISTO MULTIPLO / LOTTO', 'Una transazione · più oggetti distinti', Icons.inventory_2_outlined, _type == 'LOTTO',
        () => setState(() { _type = 'LOTTO'; if (_items.length < 2) _resize(2); _count.text = _items.length.toString(); })),
      const SizedBox(height: 12), FilledButton(onPressed: _busy ? null : () => setState(() => _step = 1), child: const Text('CONTINUA')),
    ]);

    if (_step == 1) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Dati dell’acquisto', 'La data è unica per tutta la transazione.'),
      Card(child: ListTile(leading: const Icon(Icons.calendar_month_outlined), title: const Text('Data acquisto'),
        subtitle: Text(_dateLabel(_date)), trailing: const Icon(Icons.edit_calendar_outlined), onTap: _busy ? null : _pickDate)),
      if (_type == 'LOTTO') ...[
        const SizedBox(height: 10), TextField(controller: _count, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Numero di oggetti distinti *', helperText: 'Quanti record oggetto devono essere creati nella stessa transazione?')),
      ],
      const SizedBox(height: 12), FilledButton(onPressed: _busy ? null : () {
        if (_type == 'LOTTO') {
          final n = int.tryParse(_count.text.trim());
          if (n == null || n < 2 || n > 500) { _notice('Inserisci un numero compreso fra 2 e 500.'); return; }
          _resize(n);
        } else { _resize(1); }
        setState(() => _step = 2);
      }, child: const Text('CONTINUA AGLI OGGETTI')),
      OutlinedButton(onPressed: _busy ? null : () => setState(() => _step = 0), child: const Text('INDIETRO')),
    ]);

    if (_step == 2) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(_type == 'SINGOLO' ? 'Descrivi l’oggetto acquistato' : 'Inserisci tutti gli oggetti del lotto',
        _type == 'SINGOLO' ? 'Un oggetto, un record, un acquisto.' : 'Ogni oggetto ha il proprio prezzo e record; la transazione resta unica.'),
      for (var i = 0; i < _items.length; i++) _itemEditor(i),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: _line('TOTALE ACQUISTO', '€ ' + _total.toStringAsFixed(2).replaceAll('.', ','), bold: true))),
      const SizedBox(height: 10), FilledButton(onPressed: _busy ? null : () { if (!_valid()) return; setState(() => _step = 3); }, child: const Text('RIEPILOGO ACQUISTO')),
      OutlinedButton(onPressed: _busy ? null : () => setState(() => _step = 1), child: const Text('INDIETRO')),
    ]);

    if (_step == 3) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Riepilogo acquisto', 'Controlla i dati prima di procedere. Nessuna scrittura è stata eseguita.'),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _line('Tipo', _type == 'SINGOLO' ? 'Acquisto singolo' : 'Acquisto multiplo / lotto'),
        _line('Data acquisto', _dateLabel(_date)), _line('Oggetti distinti', _items.length.toString()),
        const Divider(height: 22),
        for (var i = 0; i < _items.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((i + 1).toString() + '. ' + _items[i].description.text.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_items[i].destination + ' · ' + _items[i].condition + ' · ' + _items[i].completeness, style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
          Align(alignment: Alignment.centerRight, child: Text('€ ' + (_items[i].amount ?? 0).toStringAsFixed(2).replaceAll('.', ','))),
        ])),
        const Divider(height: 22), _line('TOTALE TRANSAZIONE', '€ ' + _total.toStringAsFixed(2).replaceAll('.', ','), bold: true),
      ]))),
      const SizedBox(height: 10), FilledButton.icon(onPressed: _busy ? null : _runPreview, icon: const Icon(Icons.fact_check_outlined), label: const Text('CONTROLLA E MOSTRA RIEPILOGO')),
      OutlinedButton(onPressed: _busy ? null : () => setState(() => _step = 2), child: const Text('MODIFICA OGGETTI')),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading('Riepilogo acquisto', 'SÌ riparte con un nuovo acquisto senza salvare questo. NO salva l’acquisto e chiude la procedura.'),
      Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _line('Tipo', _type == 'SINGOLO' ? 'Acquisto singolo' : 'Acquisto multiplo / lotto'),
        _line('Data acquisto', _dateLabel(_date)), _line('Oggetti distinti', _items.length.toString()),
        const Divider(height: 22),
        for (var i = 0; i < _items.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text((i + 1).toString() + '. ' + _items[i].description.text.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(_items[i].destination + ' · ' + _items[i].condition + ' · ' + _items[i].completeness, style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
          Align(alignment: Alignment.centerRight, child: Text('€ ' + (_items[i].amount ?? 0).toStringAsFixed(2).replaceAll('.', ','))),
        ])),
        const Divider(height: 22), _line('TOTALE ACQUISTO', '€ ' + _total.toStringAsFixed(2).replaceAll('.', ','), bold: true),
      ]))),
      const SizedBox(height: 12),
      FilledButton(onPressed: _busy ? null : () {
        for (final item in _items) { item.dispose(); }
        setState(() { _step = 0; _type = 'SINGOLO'; _date = DateTime.now(); _items..clear()..add(_PurchaseItemDraft()); _count.text = '1'; _preview = null; _dataConfirmed = false; _status = 'Nuova bozza pronta. Nessun acquisto precedente è stato salvato.'; });
      }, child: const Text('SÌ · INSERISCI UN ALTRO ACQUISTO')),
      const SizedBox(height: 8),
      FilledButton(onPressed: _busy ? null : () { setState(() { _dataConfirmed = true; }); _save(); }, child: Text(_busy ? 'ATTENDI…' : 'NO · SALVA E ESCI')),
      OutlinedButton(onPressed: _busy ? null : () => setState(() { _step = 2; _invalidate(); }), child: const Text('MODIFICA DATI')),
    ]);
  }
  @override
  Widget build(BuildContext context) {
    final c = ValoraAppearance.instance.colorFor('ACQUISTI');
    return Scaffold(appBar: AppBar(title: const Text('PR-04 · NUOVO ACQUISTO')),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('AMBIENTE TEST · Nessun acquisto viene registrato senza conferma esplicita. Dopo il salvataggio è obbligatoria la rilettura di verifica.'))),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (_step + 1) / 5, minHeight: 5, color: c)),
          const SizedBox(height: 8), Text('PASSAGGIO ' + (_step + 1).toString() + ' DI 5', style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 14), if (_busy) const LinearProgressIndicator(),
          _content(), const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_status))),
        ])))));
  }
}




class EditPurchasePage extends StatefulWidget {
  const EditPurchasePage({super.key});
  @override
  State<EditPurchasePage> createState() => _EditPurchasePageState();
}

class _EditPurchasePageState extends State<EditPurchasePage> {
  final _query=TextEditingController(), _date=TextEditingController(), _total=TextEditingController(), _description=TextEditingController();
  final _session=_uuid.v4();
  bool _busy=false,_locked=false,_confirmed=false;
  String _status='Cerca un acquisto esistente.';
  List<Map<String,dynamic>> _found=[];
  Map<String,dynamic>? _purchase,_last;
  List<Map<String,dynamic>> _items=[];
  @override
  void dispose(){_query.dispose();_date.dispose();_total.dispose();_description.dispose();super.dispose();}

  double? _money(dynamic v){
    if(v==null)return null;
    var s=v.toString().trim().replaceAll('€','').replaceAll(' ','');
    if(s.contains(','))s=s.replaceAll('.','').replaceAll(',','.');
    return double.tryParse(s);
  }
  String _code(Map<String,dynamic> r)=>(r['codice_acquisto']??r['purchase_code']??r['id']??'').toString();
  String _name(Map<String,dynamic> r)=>(r['descrizione_acquisto']??r['descrizione']??r['description']??'Acquisto').toString();
  dynamic _totalValue(Map<String,dynamic> r)=>r['importo_totale']??r['totale']??r['prezzo_acquisto']??r['amount'];
  double get _allocated=>_items.fold<double>(0,(s,r)=>s+(_money(r['importo']??r['prezzo_acquisto']??r['valore'])??0));
  void _msg(String s)=>ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));
  Map<String,dynamic> _unwrap(Map<String,dynamic> r){
    final v=r['result'];return v is Map?Map<String,dynamic>.from(v):r;
  }
  Future<void> _lock()async{
    final r=await _ValoraRuntimeApi.call('acquire_lock',{'session_id':_session});
    final v=r['result'];
    if(v is Map&&v['acquisito']==true){_locked=true;return;}
    throw Exception(v is Map?(v['messaggio']??'Blocco archivio non acquisito.').toString():'Blocco archivio non acquisito.');
  }
  Future<void> _unlock()async{
    if(!_locked)return;
    try{await _ValoraRuntimeApi.call('release_lock',{'session_id':_session});}finally{_locked=false;}
  }
  Future<void> _search()async{
    if(_query.text.trim().isEmpty){_msg('Inserisci codice o descrizione.');return;}
    setState(()=>_busy=true);
    try{
      final r=await _ValoraRuntimeApi.call('procedure',{'procedure':'PR-05','step':'search','session_id':_session,'payload':{'query':_query.text.trim(),'codice_acquisto':_query.text.trim()}});
      final data=_unwrap(r);
      final raw=data['acquisti']??data['risultati']??data['results']??data['rows'];
      if(raw is! List)throw Exception('Il runtime non ha restituito una lista di acquisti.');
      if(!mounted)return;
      setState((){_found=raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();_purchase=null;_items=[];_last=null;_status=_found.isEmpty?'Nessun acquisto trovato.':'Seleziona l’acquisto da modificare.';});
    }catch(e){if(mounted)setState(()=>_status='Ricerca non completata: $e');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _load(Map<String,dynamic> row)async{
    setState(()=>_busy=true);
    try{
      final code=_code(row);
      if(code.isEmpty)throw Exception('Codice acquisto stabile mancante.');
      final r=await _ValoraRuntimeApi.procedure('PR-05','load',{'codice_acquisto':code,'purchase_code':code},sessionId:_session);
      final p=r['acquisto'] is Map?Map<String,dynamic>.from(r['acquisto']):r;
      final raw=p['oggetti']??p['allocazioni']??p['dettagli']??p['items'];
      final date=DateTime.tryParse((p['data_acquisto']??p['data']??p['purchase_date']??'').toString());
      final amount=_money(_totalValue(p));
      if(raw is! List||raw.isEmpty)throw Exception('Dettagli oggetto non disponibili: modifica bloccata.');
      if(date==null||amount==null)throw Exception('Data o totale originario mancanti.');
      if(!mounted)return;
      setState((){_purchase=p;_date.text=date.toIso8601String().substring(0,10);_total.text=amount.toStringAsFixed(2);_description.text=_name(p);_items=raw.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();_last=null;_confirmed=false;_status='Scheda completa caricata. Codice acquisto e codici oggetto saranno conservati.';});
    }catch(e){if(mounted)setState(()=>_status='Scheda non caricata: $e');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  bool _valid(){
    if(_purchase==null||_code(_purchase!).isEmpty){_msg('Seleziona un acquisto con codice valido.');return false;}
    if(DateTime.tryParse(_date.text.trim())==null){_msg('Data non valida. Usa AAAA-MM-GG.');return false;}
    final total=_money(_total.text);
    if(total==null||total<0||_description.text.trim().isEmpty){_msg('Descrizione e totale sono obbligatori.');return false;}
    if(_items.isEmpty||_items.any((r)=>_money(r['importo']??r['prezzo_acquisto']??r['valore'])==null)){_msg('Allocazioni non complete: salvataggio bloccato.');return false;}
    if((_allocated-total).abs()>0.009){_msg('Quadratura non valida: somma allocazioni diversa dal totale.');return false;}
    return true;
  }
  Map<String,dynamic> _payload({bool confirmed=false,bool finalConfirmation=false})=> {
    'codice_acquisto':_code(_purchase!), 'purchase_code':_code(_purchase!),
    'data_acquisto':_date.text.trim(),'descrizione_acquisto':_description.text.trim(),
    'importo_totale':_money(_total.text),'oggetti':_items,
    'dati_confermati':confirmed,'conferma_finale':finalConfirmation,
    'mantieni_codici_oggetto':true,'non_eliminare_ricreare':true,
    'aggiorna_cassa':true,'registra_storico':true,'verifica_quadratura':true,
  };
  Future<void> _preview()async{
    if(!_valid())return;setState(()=>_busy=true);
    try{await _lock();final r=await _ValoraRuntimeApi.procedure('PR-05','preview',_payload(),sessionId:_session);if(mounted)setState((){_last=r;_status='Anteprima completata: controlla le differenze prima della review.';});}
    catch(e){if(mounted)setState(()=>_status='Anteprima non riuscita: $e');}
    finally{await _unlock();if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _save()async{
    if(!_confirmed||_last==null||!_valid()){_msg('Controlla i dati e conferma il riepilogo prima di salvare.');return;}
    setState(()=>_busy=true);
    try{
      await _lock();
      final r=await _ValoraRuntimeApi.procedure('PR-05','save',_payload(confirmed:true,finalConfirmation:true),sessionId:_session,requestId:_uuid.v4());
      final reread=r['rilettura_database'];
      final verified=r['rilettura_verificata']==true||r['verifica_post_scrittura']=='OK'||r['stato']=='SALVATO_E_VERIFICATO';
      final audit=r['storico_aggiornato']==true||r['audit_registrato']==true;
      final cash=r['cassa_aggiornata']==true||r['movimenti_cassa_aggiornati']==true;
      final code=(r['codice_acquisto']??r['purchase_code']??_code(_purchase!)).toString()==_code(_purchase!);
      final saved=r['scrittura_eseguita']==true&&verified&&audit&&cash&&code&&reread is Map;
      if(r['blocco_rilasciato_automaticamente']==true)_locked=false;
      if(!mounted)return;
      setState((){_last=r;_status=saved?'Modifica verificata: codice conservato, cassa e storico aggiornati.':'Modifica NON considerata conclusa: il runtime non ha confermato tutti i controlli richiesti.';});
      if(saved&&mounted){
        final again=await showDialog<bool>(context:context,barrierDismissible:false,builder:(ctx)=>AlertDialog(
          title:const Text('Modifica verificata'),content:const Text('Vuoi modificare un altro acquisto?'),
          actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('NO, TERMINA')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('SÌ, ALTRO ACQUISTO'))]));
        if(!mounted)return;
        if(again==true)setState((){_query.clear();_found=[];_purchase=null;_items=[];_last=null;_confirmed=false;_status='Cerca un altro acquisto.';});
        else Navigator.of(context).pop();
      }
    }catch(e){if(mounted)setState(()=>_status='Modifica non confermata: $e');}
    finally{await _unlock();if(mounted)setState(()=>_busy=false);}
  }
  Widget _line(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[Expanded(child:Text(a)),Flexible(child:Text(b,textAlign:TextAlign.end))]));
  @override
  Widget build(BuildContext context){
    final color=ValoraAppearance.instance.colorFor('ACQUISTI');
    return Scaffold(appBar:AppBar(title:const Text('PR-05 · MODIFICA ACQUISTO')),
      body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:820),child:ListView(padding:const EdgeInsets.all(16),children:[
        const Card(child:Padding(padding:EdgeInsets.all(12),child:Text('AMBIENTE TEST · Conserva codice acquisto e codici oggetto. Nessuna eliminazione/ricreazione. Quadratura, cassa, storico e rilettura sono obbligatori.'))),
        Text('1 · CERCA ACQUISTO',style:TextStyle(color:color,fontWeight:FontWeight.bold)),
        TextField(controller:_query,decoration:const InputDecoration(labelText:'Codice acquisto o descrizione'),onSubmitted:(_)=>_search()),
        FilledButton(onPressed:_busy?null:_search,child:const Text('CERCA')),
        for(final row in _found) Card(child:ListTile(title:Text(_name(row)),subtitle:Text('Codice: '+_code(row)+' · Totale: '+((_money(_totalValue(row))??0).toStringAsFixed(2))+' €'),trailing:const Icon(Icons.chevron_right),onTap:_busy?null:()=>_load(row))),
        if(_purchase!=null)...[
          const Divider(height:24),Text('2 · MODIFICA SCHEDA ESISTENTE',style:TextStyle(color:color,fontWeight:FontWeight.bold)),
          _line('Codice acquisto',_code(_purchase!)),
          TextField(controller:_description,decoration:const InputDecoration(labelText:'Descrizione acquisto *'),onChanged:(_)=>setState((){_last=null;_confirmed=false;})),
          TextField(controller:_date,decoration:const InputDecoration(labelText:'Data acquisto (AAAA-MM-GG) *'),onChanged:(_)=>setState((){_last=null;_confirmed=false;})),
          TextField(controller:_total,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Totale acquisto (€) *'),onChanged:(_)=>setState((){_last=null;_confirmed=false;})),
          _line('Somma allocazioni','€ '+_allocated.toStringAsFixed(2)),_line('Totale','€ '+((_money(_total.text)??0).toStringAsFixed(2))),
          if (((_money(_total.text) ?? -999) - _allocated).abs() > 0.009) const Text('QUADRATURA NON VALIDA: il salvataggio è bloccato.',style:TextStyle(color:Colors.redAccent,fontWeight:FontWeight.bold)),
          for(final item in _items) Card(child:ListTile(title:Text((item['descrizione_oggetto']??item['descrizione']??item['nome']??'Oggetto collegato').toString()),subtitle:Text('Codice oggetto: '+(item['codice_oggetto']??item['object_code']??item['id']??'non disponibile').toString()),trailing:Text('€ '+((_money(item['importo']??item['prezzo_acquisto']??item['valore'])??0).toStringAsFixed(2))))),
          FilledButton(onPressed:_busy?null:_preview,child:const Text('MOSTRA RIEPILOGO')),
          if(_last!=null) Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('RIEPILOGO MODIFICA',style:TextStyle(fontWeight:FontWeight.bold)),
            _line('Codice acquisto',_code(_purchase!)),
            _line('Data',_date.text.trim()),
            _line('Descrizione',_description.text.trim()),
            _line('Oggetti collegati',_items.length.toString()),
            _line('Totale acquisto','€ '+((_money(_total.text)??0).toStringAsFixed(2))),
            _line('Somma allocazioni','€ '+_allocated.toStringAsFixed(2)),
            const Text('I codici degli oggetti collegati vengono conservati. Il salvataggio aggiorna cassa e storico tramite runtime.'),
          ]))),
          CheckboxListTile(value:_confirmed,title:const Text('Confermo il riepilogo e autorizzo il salvataggio.'),onChanged:_busy||_last==null?null:(v)=>setState(()=>_confirmed=v??false)),
          FilledButton(onPressed:_busy||!_confirmed||_last==null?null:_save,child:Text(_busy?'ATTENDI…':'SALVA MODIFICA E TERMINA')),
        ],
        if(_busy)const LinearProgressIndicator(),
        Card(child:Padding(padding:const EdgeInsets.all(12),child:Text(_status))),
      ])))));
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
    setState(() { _loading = true; _error = null; _status = 'Preparazione coda protetta PR-12…'; _results.clear(); _offset = 0; });
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Sessione scaduta. Accedi nuovamente.');
      final response = await http.post(Uri.parse('$supabaseUrl/functions/v1/pr-12-engine-test'),
        headers: {'apikey': publishableKey, 'Authorization': 'Bearer ${session.accessToken}', 'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'azione': 'PREPARA_CODA'})).timeout(const Duration(seconds: 25));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || decoded is! Map || decoded['ok'] != true) {
        final message = decoded is Map ? (decoded['error'] ?? 'Risposta non valida').toString() : 'Risposta non valida';
        throw Exception('Preparazione coda HTTP ${response.statusCode}: $message');
      }
      final raw = decoded['oggetti'];
      final rows = raw is List ? raw.whereType<Map>().map((v) => <String, dynamic>{
        'codice_oggetto': v['id'],
        'descrizione_oggetto': v['descrizione'],
        'produttore': v['produttore'],
        'anno_uscita': v['anno_uscita'],
        'codice_prodotto': v['codice_prodotto'],
      }).toList() : <Map<String, dynamic>>[];
      if (mounted) setState(() {
        _queue = rows;
        _status = 'Catalogo letto: ${decoded['totale_catalogo_letto'] ?? 'n/d'} record; ${decoded['totale_incompleti'] ?? rows.length} incompleti. Nessun dato modificato.';
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _status = 'Impossibile preparare la coda PR-12.'; });
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
        headers: {'apikey': publishableKey, 'Authorization': 'Bearer ${session.accessToken}', 'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'modalita_ia': 'TEST', 'oggetti': batch.map((v) => {
          'id': (v['codice_oggetto'] ?? '').toString(),
          'descrizione': (v['descrizione_oggetto'] ?? '').toString(),
          'categoria': _category((v['descrizione_oggetto'] ?? '').toString()),
          'produttore_attuale': (v['produttore'] ?? '').toString(),
          'anno_uscita_attuale': v['anno_uscita'],
          'codice_prodotto': (v['codice_prodotto'] ?? '').toString(),
        }).toList()})).timeout(const Duration(minutes: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 500).toInt())}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['ok'] != true || decoded['tipo'] != 'coda_completata') {
        final message = decoded is Map ? (decoded['error'] ?? 'Risposta PR-12 non valida').toString() : 'Risposta PR-12 non valida';
        throw Exception(message);
      }
      final rawResults = decoded['risultati_finali'];
      final batchResults = rawResults is List ? rawResults.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList() : <Map<String, dynamic>>[];
      if (mounted) setState(() {
        _results.addAll(batchResults); _offset += batch.length;
        final good = batchResults.where((v) => v['ok'] == true).length;
        _status = 'Lotto concluso: $good riusciti, ${batchResults.length - good} errori. Avanzamento $_offset/${_queue.length}. Database invariato.';
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
          label: Text(_running ? 'RICERCA IN CORSO…' : 'ELABORA PROSSIMO LOTTO ($remaining)')),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('STATO', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(_status),
          if (_queue.isNotEmpty) Text('In coda: ${_queue.length} · elaborati: $_offset · lotti: ${(_queue.length / 10).ceil()}'),
          if (_error != null) SelectableText(_error!, style: const TextStyle(color: Color(0xFFE35D5D))),
        ]))),
        // Mostra l'anteprima del lotto soltanto prima della prima elaborazione.
        // Dopo ogni lotto l'elenco operativo si svuota: restano visibili solo risultati già analizzati.
        if (_queue.isNotEmpty && _results.isEmpty) ...[
          const Padding(padding: EdgeInsets.only(top: 12, bottom: 4), child: Text('ELENCO DEL LOTTO DA ANALIZZARE', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold))),
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
                subtitle: Text('${c['url'] ?? ''}\n${c['snippet'] ?? ''}', maxLines: 4, overflow: TextOverflow.ellipsis),
                onTap: () {
                  final rawUrl = (c['url'] ?? '').toString().trim();
                  final uri = Uri.tryParse(rawUrl);
                  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link candidato non valido.')));
                  }
                },
                trailing: IconButton(
                  tooltip: 'Prepara proposta metadati',
                  icon: const Icon(Icons.fact_check_outlined, color: goldColor),
                  onPressed: () {
                    final fields = <String, String>{
                      "Oggetto": (v["descrizione"] ?? "").toString(),
                      "Candidato": (c["title"] ?? "").toString(),
                      "Produttore proposto": (c["produttore"] ?? "").toString(),
                      "Anno proposto": (c["anno_uscita"] ?? "").toString(),
                      "Codice prodotto proposto": (c["codice_prodotto"] ?? c["isbn"] ?? "").toString(),
                      "Fonte": (c["url"] ?? "").toString(),
                    };
                    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
                      title: const Text('Proposta metadati · sola lettura'),
                      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                        children: fields.entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('${e.key}: ${e.value.isEmpty ? 'non disponibile' : e.value}'))).toList())),
                      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CHIUDI'))],
                    ));
                  },
                ))),
              if (v['diagnostica_ricerca'] is Map) SelectableText('Diagnostica: ${jsonEncode(v['diagnostica_ricerca'])}', style: const TextStyle(fontSize: 11, color: Colors.white54)),
            ])));
          }),
        ],
      ])));
  }
}
