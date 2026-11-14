import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:archive/archive.dart' as archive;
import 'package:xml/xml.dart' as xml;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pw_core;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'themes/valora_theme.dart';
import 'localization/valora_i18n.dart';
import 'startup/startup_failure_page.dart';
import 'startup/startup_loading_page.dart';
import 'authentication/authentication_gate.dart';
import 'procedures/procedure_registry.dart';
import 'purchases/purchase_comparison_page.dart';
import 'procedures/procedure_card.dart';
import 'procedures/pr01_form_content.dart';
import 'procedures/pr01_page.dart';
import 'procedures/pr02_page.dart';
import 'procedures/pr02_controller.dart';
import 'procedures/pr03_controller.dart';
import 'procedures/pr03_closure_section.dart';
import 'procedures/pr01_image_field.dart';
import 'procedures/pr01_controller.dart';
import 'services/pr01_image_manager.dart';



import 'dashboard/dashboard_section_background.dart';
import 'dashboard/dashboard_collection_category_card.dart';
import 'dashboard/dashboard_collection_header.dart';
import 'dashboard/dashboard_home_header.dart';
import 'dashboard/dashboard_home_footer.dart';
import 'dashboard/dashboard_home_list_content.dart';
import 'dashboard/dashboard_collection_error_banner.dart';
import 'dashboard/dashboard_collection_empty_notice.dart';
import 'dashboard/dashboard_category_brand_mark.dart';
import 'dashboard/dashboard_category_object_preview.dart';
import 'dashboard/dashboard_category_panel_header.dart';
import 'dashboard/dashboard_category_panel.dart';
import 'dashboard/dashboard_category_no_records_notice.dart';
import 'dashboard/dashboard_category_loading_notice.dart';
import 'dashboard/dashboard_catalog_count_error_notice.dart';
import 'dashboard/dashboard_assistant_fab.dart';
import 'dashboard/dashboard_app_bar.dart';
import 'dashboard/dashboard_category_preview_list.dart';
import 'dashboard/dashboard_procedure_info_dialog.dart';
import 'dashboard/dashboard_block_menu_grid.dart';
import 'dashboard/dashboard_home_block_content.dart';
import 'dashboard/dashboard_home_content.dart';
import 'history/object_history_detail_row.dart';
import 'objects/object_image_placeholder.dart';
import 'objects/object_info_chip.dart';
import 'dashboard/dashboard_section_header.dart';
import 'dashboard/dashboard_section_footer.dart';
import 'dashboard/dashboard_section_content.dart';
import 'dashboard/dashboard_menu_card.dart';
import 'dashboard/dashboard_grid_menu_card.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

part 'dashboard/dashboard_home_coordinator.dart';
part 'dashboard/dashboard_collection_content.dart';
part 'procedures/pr02_object_management.dart';
part 'procedures/pr01_confirmation_workflow.dart';
part 'procedures/pr01_save_workflow.dart';
part 'procedures/pr01_data_workflow.dart';
part 'procedures/pr01_page_workflow.dart';
part 'procedures/pr01_image_workflow.dart';
part 'procedures/object_search_workflow.dart';
part 'procedures/pr03_closure_save.dart';
part 'procedures/pr03_closure_confirmation.dart';
part 'procedures/pr03_closure_payload.dart';
part 'procedures/pr03_object_selection.dart';
part 'procedures/pr03_controller_bindings.dart';
part 'procedures/pr03_controller_owner.dart';
part 'purchases/pr04_runtime_procedure.dart';
part 'wanted_list/wanted_new_desire_page.dart';
part 'wanted_list/wanted_active_desires_page.dart';
part 'wanted_list/wanted_purchase_objectives_page.dart';
part 'wanted_list/wanted_purchase_page.dart';
part 'wanted_list/wanted_offers_page.dart';
part 'wanted_list/wanted_history_page.dart';
part 'purchases/pr05_runtime_procedure.dart';
part 'purchases/pr04_form_content.dart';
part 'purchases/pr04_photo_field.dart';
part 'purchases/pr04_valora_page.dart';
part 'purchases/pr04_page_frame.dart';
part 'purchases/pr04_step_content.dart';
part 'purchases/pr04_recognition_dialog.dart';
part 'purchases/pr05_form_content.dart';
part 'purchases/pr05_search_section.dart';
part 'purchases/pr05_details_section.dart';
part 'purchases/pr05_confirmation_section.dart';
part 'purchases/pr05_page_frame.dart';
part 'procedures/pr06_page_frame.dart';
part 'procedures/pr06_runtime_procedure.dart';
part 'procedures/pr07_edit_sales_page.dart';
part 'procedures/pr07_edit_sales_data_mixin.dart';
part 'procedures/pr07_sale_edit_card.dart';
part 'procedures/pr06_form_content.dart';
part 'procedures/pr06_pending_sales_section.dart';
part 'procedures/pr06_object_selection_section.dart';
part 'procedures/pr06_sale_details_section.dart';
part 'procedures/pr06_preview_confirmation_section.dart';
part 'procedures/pr06_status_section.dart';
part 'procedures/pr06_page_state.dart';
part 'procedures/pr06_valora_page.dart';
part 'procedures/pr06_valora_listing_drafts.dart';
part 'procedures/pr06_valora_listing_draft_pages.dart';
part 'procedures/pr06_valora_listing_draft_card.dart';
part 'procedures/pr08_close_sales_page.dart';
part 'procedures/pr09_cancel_sales_page.dart';
part 'procedures/pr09_completed_sale_card.dart';
part 'procedures/pr09_cancel_sales_preview_card.dart';
part 'procedures/pr08_sales_summary_card.dart';
part 'procedures/pr08_open_sale_card.dart';
part 'procedures/pr08_sales_preview_card.dart';
part 'procedures/write_procedure_action_panel.dart';
part 'objects/object_master_presentation.dart';
part 'objects/object_cards_presentation.dart';
part 'reports/report_summary_panel.dart';
part 'reports/report_operation_card.dart';
part 'reports/report_pagination_controls.dart';
part 'reports/active_sales_report_page.dart';
part 'reports/active_sales_report_data_mixin.dart';
part 'reports/active_sale_report_card.dart';
part 'reports/sales_report_page.dart';
part 'reports/sales_report_data_mixin.dart';
part 'reports/sales_report_export_service.dart';
part 'reports/sales_report_card.dart';
part 'procedures/valora_service_page.dart';
part 'procedures/valora_user_market_service.dart';
part 'procedures/valora_photo_input_controller.dart';
part 'procedures/valora_photo_input_presentation.dart';
part 'procedures/valora_photo_analysis_service.dart';
part 'procedures/valora_photo_search_controller.dart';
part 'procedures/valora_photo_candidate_controller.dart';
part 'procedures/valora_catalog_intake_controller.dart';
part 'procedures/valora_catalog_intake_review_dialog.dart';
part 'procedures/valora_catalog_intake_valuation_summary.dart';
part 'procedures/valora_catalog_intake_valuation_service.dart';
part 'procedures/valora_catalog_metadata_builder.dart';
part 'procedures/valora_known_object_pr18_service.dart';
part 'procedures/valora_pr18_valuation_controller.dart';
part 'procedures/valora_known_object_valuation_controller.dart';
part 'procedures/valora_catalog_sale_controller.dart';
part 'procedures/valora_service_presentation.dart';
part 'procedures/valora_collection_search_section.dart';
part 'procedures/valora_market_valuation_section.dart';
part 'procedures/valora_market_valuation_controls.dart';
part 'procedures/valora_market_valuation_result.dart';
part 'procedures/valora_intro_section.dart';
part 'procedures/valora_catalog_actions_section.dart';
part 'procedures/valora_catalog_objects_service.dart';
part 'procedures/valora_catalog_objects_controller.dart';
part 'procedures/collection_value_page.dart';
part 'procedures/collection_value_presentation.dart';
part 'procedures/pr12_batch_page.dart';

const String supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const String publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
String _valoraImageProxyUrl(String rawUrl) {
  final value = rawUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https') return value;
  const proxyHosts = {
    'bandai-a.akamaihd.net',
    'www.gunpla-italia.com',
    'cdn.media.amplience.net',
    'www.hasbropulse.com',
    'tf.takaratomy.co.jp',
    'www.hasbro.com',
    'www.fantamagus.com',
    'www.gamelife.it',
    'kurogami.com',
    'www.kurogami.com',
    'www.vendiloshop.it',
    'cdn.rebrickable.com',
    'bits-and-blocks.co.uk',
    'www.brickeconomy.com',
    'i5.walmartimages.com',
    'shopdeinerd.com',
    'm3toys.com',
    'eshop.czechrepubrick.cz',
    'www.lego.com',
    'images.pristineauction.com',
    'super-briques.fr',
    'instructions.hasbro.com',
    'bwtf.com',
    'www.bwtf.com',
    'media.entertainmentearth.com',
    'collecticontoys.com',
    'images.brickset.com',
    'funko.com',
    'www.funko.com',
    'tamashiiweb.com',
    'www.ibs.it',
    'www.thechosenprime.com',
    'transforverse.eu',
    'cdn11.bigcommerce.com',
    'www.lafeltrinelli.it',
    'www.tfsafari.com',
    'i.tformers.com',
    'i.ebayimg.com',
    's3.amazonaws.com',
    'toynado.ca',
    'www.1999.co.jp',
    'images.bigbadtoystore.com',
    'pops.today',
    'images-na.ssl-images-amazon.com',
    'www.previewsworld.com',
    'cdn.awsli.com.br',
    'image.shopcraft.co.kr',
    'b2c.magicpressedizioni.it',
    'media.karousell.com',
    'comicsbox.it',
    'www.bibelotmania.com',
    'thelittlebrickmarket.com',
    'www.comicsbox.it',
    'books.google.com',
    'down-id.img.susercontent.com',
    'giuntialpunto.it',
    'www.hlj.com',
    'cdn.ecommercedns.uk',
    'media.gamestop.com',
    'i0.wp.com',
    'www.comix21.it',
    'edicolaonline.store',
    'smoothsales.com.au',
    'resources.claroshop.com',
    'toyarena.com',
    'cmdstore.com',
    'rihappy.vtexassets.com',
    'transformers.pe',
    'media.okini.land',
    'www.toynk.com',
    'www.fanboycollectibles.com',
    'imgmarketplace.lojasrenner.com.br',
    'kaostech.net',
    'indemandtoys.co.uk',
    'brickheads.co',
    'atlbrick.com',
    'www.transformerland.com',
    'cdn.shopify.com',
  };
  if (!proxyHosts.contains(uri.host.toLowerCase())) return value;
  return '${supabaseUrl}/functions/v1/collection-image-proxy?url=${Uri.encodeComponent(value)}';
}

const Color backgroundColor = Color(0xFF101010);
const Color cardColor = Color(0xFF1C1C1C);
const Color goldColor = Color(0xFFD6B15E);

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
            ? AuthenticationGate(
                authenticatedBuilder: (_) => const HomeDashboard(),
                unauthenticatedBuilder: (_) => const LoginPage(),
              )
            : StartupFailurePage(error: widget.startupError!, accentColor: goldColor),
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
    'COLLEZIONE','CATALOGO','ACQUISTI','VENDITE',
    'VALUTAZIONI','REPORT','RICERCHE','CONTROLLO'
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
      color:const Color(0xFF171717).withValues(alpha:0.72),
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
    backgroundColor: Colors.transparent,
    appBar:AppBar(
      title:const Text('Personalizza VALORA'),
      backgroundColor: Colors.black.withValues(alpha:0.48),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  valoraThemeAsset(a.selectedThemeId),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: backgroundColor),
                ),
                ColoredBox(color: Colors.black.withValues(alpha:0.32)),
              ],
            ),
          ),
        ),
        ListView(padding:const EdgeInsets.all(16),children:[
      const Text('TEMA APPLICAZIONE',style:TextStyle(color:goldColor,fontWeight:FontWeight.bold)),
      const SizedBox(height:8),
      const Text('Scegli uno dei dieci temi predefiniti. Palette e stile sono bloccati; la scelta si applica all’interfaccia e viene salvata su questo dispositivo.'),
      const SizedBox(height:8),
      ...ValoraAppearance.themePresets.entries.map((entry) {
        final theme = entry.value;
        final selected = a.selectedThemeId == entry.key;
        final accent = Color(theme['accent'] as int);
        final previewDescription = switch (entry.key) {
          'black_gold' => 'Marmo nero venato d’oro · elegante e premium',
          'industrial' => 'Acciaio spazzolato e grafite · robusto e tecnico',
          'comic' => 'Pop-art e contrasti netti · energico e colorato',
          'midnight_blue' => 'Blu notte e bagliori elettrici · profondo e tecnologico',
          'emerald' => 'Circuiti elettronici e verde neon · luminoso e futuristico',
          'silver_light' => 'Marmo chiaro e venature argento · luminoso e minimale',
          'dark_red' => 'Roccia vulcanica e magma · intenso e realistico',
          'royal_purple' => 'Cristalli ametista e luce viola · creativo e raffinato',
          'minimal_zen' => 'Pietra naturale e toni sabbia · semplice e rilassante',
          'pastel' => 'Gradienti pastello morbidi · delicato e moderno',
          _ => 'Tema coordinato predefinito',
        };
        return Card(
          color: Color(theme['background'] as int).withValues(alpha: 0.78),
          margin: const EdgeInsets.symmetric(vertical:4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(entry.key == 'comic' ? 3 : (entry.key == 'minimal_zen' ? 18 : 12)),
            side: BorderSide(color: selected ? accent : accent.withValues(alpha:0.35), width: selected ? 2.2 : 1),
          ),
          child: ListTile(
            leading: Container(width:34,height:34,decoration:BoxDecoration(
              color:Color(theme['background'] as int),
              borderRadius:BorderRadius.circular(entry.key == 'comic' ? 2 : 8),
              border:Border.all(color:accent,width:entry.key == 'comic' ? 2 : 1),
            ),child:CustomPaint(
              painter:ValoraThemeBackdropPainter(
                themeId:entry.key,
                background:Color(theme['background'] as int),
                accent:accent,
              ),
              child:Center(child:Icon(
                entry.key == 'comic' ? Icons.auto_awesome : (entry.key == 'minimal_zen' ? Icons.spa_outlined : Icons.palette_outlined),
                color:accent,size:20,
              )),
            )),
            title:Text(theme['name'] as String,style:TextStyle(fontWeight:FontWeight.bold,color:a.textPrimary)),
            subtitle:Text(previewDescription,style:TextStyle(color:(theme['light'] as bool) ? const Color(0xFF424242) : Colors.white70)),
            trailing:selected ? Icon(Icons.check_circle,color:accent) : const Icon(Icons.radio_button_unchecked),
            onTap:()=>a.setTheme(entry.key),
          ),
        );
      }),
      const SizedBox(height:20),
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
      const Text('I colori e lo sfondo sono gestiti dal tema predefinito selezionato. Puoi continuare a personalizzare il layout della Home e le immagini delle sezioni.',style:TextStyle(color:goldColor)),
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
    ]),
      ],
    ),
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
        backgroundColor: const Color(0xFF101010),
        body: ColoredBox(
          color: const Color(0xFF101010),
          child: SafeArea(
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
        ),
      );
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
        title: Text(ValoraI18n.tr('Rimuovere la piattaforma?')),
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
      appBar: AppBar(title: Text(ValoraI18n.tr('LE MIE PIATTAFORME'))),
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
              IconButton(tooltip: ValoraI18n.tr('RIMUOVI'), icon: const Icon(Icons.delete_outline), onPressed: () => _delete(p)),
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
            TextFormField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
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
      appBar: AppBar(title: Text(ValoraI18n.tr('REGISTRO FONTI')), actions: [
        IconButton(tooltip: ValoraI18n.tr('Gestisci categorie e campi specialistici'), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CollectibleCategoryRegistryPage())), icon: const Icon(Icons.category_outlined)),
        IconButton(tooltip: ValoraI18n.tr('Aggiorna'), onPressed: _load, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: ValoraI18n.tr('Aggiungi fonte'), onPressed: () => _editSource(), icon: const Icon(Icons.add_link)),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _editSource(), icon: const Icon(Icons.add), label: Text(ValoraI18n.tr('AGGIUNGI FONTE'))),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _error != null
        ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.info_outline, size: 42), const SizedBox(height: 12),
            const Text('Registro non ancora disponibile'), const SizedBox(height: 8),
            SelectableText(_error!), const SizedBox(height: 12),
            FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(ValoraI18n.tr('RIPROVA'))),
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
  @override State<CollectibleCategoryRegistryPage> createState() => _CollectibleCategoryRegistryPageState();
}
class _CollectibleCategoryRegistryPageState extends State<CollectibleCategoryRegistryPage> {
  bool _loading = true, _saving = false; String? _error; List<Map<String,dynamic>> _rows = [];
  static const Map<String,IconData> _icons = {
    'category_outlined': Icons.category_outlined, 'extension': Icons.extension, 'toys_outlined': Icons.toys_outlined,
    'smart_toy_outlined': Icons.smart_toy_outlined, 'menu_book_outlined': Icons.menu_book_outlined, 'two_wheeler': Icons.two_wheeler,
    'watch_outlined': Icons.watch_outlined, 'sports_esports_outlined': Icons.sports_esports_outlined, 'palette_outlined': Icons.palette_outlined,
    'collections_outlined': Icons.collections_outlined, 'shield_outlined': Icons.shield_outlined, 'directions_car_outlined': Icons.directions_car_outlined,
  };
  static const Map<String,String> _colors = {
    'Rosso':'#C62828','Rosso scuro':'#8E0000','Corallo':'#FF6F61','Bordeaux':'#800020','Arancione':'#DD741D','Pesca':'#FFB07C',
    'Giallo':'#F9A825','Oro':'#D6B15E','Giallo limone':'#D4E157','Verde':'#008C4A','Verde chiaro':'#7CB342','Verde foresta':'#1B5E20',
    'Menta':'#66CDAA','Turchese':'#00897B','Acquamarina':'#00BFA5','Azzurro':'#29B6F6','Blu':'#2476C8','Blu navy':'#1A237E',
    'Blu notte':'#283593','Indaco':'#3F51B5','Viola':'#7137B8','Lilla':'#B39DDB','Lavanda':'#9575CD','Magenta':'#C2185B',
    'Rosa':'#EC407A','Rosa chiaro':'#F8BBD0','Fucsia':'#D500F9','Marrone':'#6D4C41','Cuoio':'#8D6E63','Sabbia':'#D7CCC8',
    'Beige':'#DCC7A1','Avorio':'#FFF8E1','Grigio':'#607D8B','Grigio chiaro':'#B0BEC5','Antracite':'#37474F','Nero':'#212121',
    'Bianco':'#FFFFFF','Argento':'#B0BEC5','Bronzo':'#A66A3F','Petrolio':'#006064','Prugna':'#6A1B9A','Oliva':'#827717',
  };
  @override void initState(){super.initState();_load();}
  Future<void> _load() async { setState(()=>_loading=true); try { final data=await Supabase.instance.client.schema('collection').from('master_categorie_collezione').select('codice_categoria, descrizione, icona, colore_hex, logo_url, ordine_menu, visibile').order('ordine_menu').order('descrizione'); if(!mounted)return; setState(()=>_rows=(data as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList()); } catch(e){if(mounted)setState(()=>_error=e.toString());} finally {if(mounted)setState(()=>_loading=false);} }

  Future<String?> _saveCategoryLogo(Uint8List? bytes,String? fileName,String? code,String? existingUrl) async { if(bytes==null)return existingUrl; final ext=(fileName??'logo.jpg').toLowerCase().split('.').last; final safeExt=['png','webp'].contains(ext)?ext:'jpg'; final mime=safeExt=='png'?'image/png':safeExt=='webp'?'image/webp':'image/jpeg'; final path='${code??'category'}-${DateTime.now().millisecondsSinceEpoch}.$safeExt'; await Supabase.instance.client.storage.from('valora-category-logos-test').uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:true)); return Supabase.instance.client.storage.from('valora-category-logos-test').getPublicUrl(path); }

  Future<void> _editCategory(Map<String,dynamic> row) async {
    final name=TextEditingController(text:(row['descrizione']??'').toString());
    String iconKey=_icons.containsKey(row['icona'])?row['icona'].toString():'category_outlined';
    final matchingColors=_colors.entries.where((e)=>e.value.toUpperCase()==(row['colore_hex']??'').toString().toUpperCase()).toList(); String colorName=matchingColors.isEmpty?'Oro':matchingColors.first.key;
    bool visible=row['visibile']==true; Uint8List? logoBytes; String? logoName; String? logoUrl=(row['logo_url']??'').toString().trim().isEmpty?null:row['logo_url'].toString();
    final accepted=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,sd)=>AlertDialog(
      title:Text('MODIFICA CATEGORIA ${row['codice_categoria']}'),
      content:SizedBox(width:460,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,textCapitalization:TextCapitalization.words,decoration:const InputDecoration(labelText:'Descrizione categoria')),
        const SizedBox(height:14),
        DropdownButtonFormField<String>(value:iconKey,decoration:const InputDecoration(labelText:'Logo della categoria'),items:_icons.entries.map((e)=>DropdownMenuItem(value:e.key,child:Row(children:[Icon(e.value,size:20),const SizedBox(width:10),Text(e.key.replaceAll('_',' '))]))).toList(),onChanged:(v){if(v!=null)sd(()=>iconKey=v);}),
        const SizedBox(height:14),
        StatefulBuilder(builder:(ctx,logoSet)=>Column(children:[if(logoBytes!=null) Image.memory(logoBytes!,height:90,fit:BoxFit.contain) else if(logoUrl!=null) Image.network(logoUrl!,height:90,errorBuilder:(c,e,s)=>const Icon(Icons.broken_image,size:48)),Row(children:[Expanded(child:Text(logoName??(logoUrl!=null?'Logo personalizzato presente':'Nessuna immagine personalizzata'))),TextButton.icon(onPressed:() async {final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:85,maxWidth:1200);if(picked!=null){final bytes=await picked.readAsBytes();logoSet((){logoBytes=bytes;logoName=picked.name;});}},icon:const Icon(Icons.image_outlined),label:const Text('SCEGLI IMMAGINE')),if(logoUrl!=null||logoBytes!=null) IconButton(onPressed:()=>logoSet((){logoBytes=null;logoName=null;logoUrl=null;}),icon:const Icon(Icons.delete_outline),tooltip:'Rimuovi immagine')])])),
        const SizedBox(height:14),
        DropdownButtonFormField<String>(value:colorName,decoration:const InputDecoration(labelText:'Colore della scheda'),items:_colors.entries.map((e)=>DropdownMenuItem(value:e.key,child:Row(children:[Container(width:20,height:20,decoration:BoxDecoration(color:Color(int.parse(e.value.substring(1),radix:16)+0xFF000000),borderRadius:BorderRadius.circular(5))),const SizedBox(width:10),Text(e.key)]))).toList(),onChanged:(v){if(v!=null)sd(()=>colorName=v);}),
        SwitchListTile(title:const Text('Visibile in COLLEZIONE'),value:visible,onChanged:(v)=>sd(()=>visible=v),contentPadding:EdgeInsets.zero),
        const SizedBox(height:8),Text('Il codice ${row['codice_categoria']} resta invariato.',style:const TextStyle(fontSize:12)),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('ANNULLA')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('SALVA MODIFICHE'))])));
    if(accepted!=true){name.dispose();return;}
    final description=name.text.trim();
    if(description.isEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Inserisci la descrizione della categoria.')));name.dispose();return;}
    setState(()=>_saving=true);
    try{
      final duplicate=await Supabase.instance.client.schema('collection').from('master_categorie_collezione').select('codice_categoria').ilike('descrizione',description);
      if((duplicate as List).any((e)=>(e as Map)['codice_categoria']!=row['codice_categoria'])){
        if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Esiste già una categoria con questa descrizione.')));return;
      }
      await Supabase.instance.client.schema('collection').from('master_categorie_collezione').update({'descrizione':description,'icona':iconKey,'colore_hex':_colors[colorName],'visibile':visible,'logo_url':await _saveCategoryLogo(logoBytes,logoName,row['codice_categoria']?.toString(),logoUrl)}).eq('codice_categoria',row['codice_categoria']);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Categoria aggiornata.')));
      await _load();
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Modifica non riuscita: '+e.toString())));}
    finally{name.dispose();if(mounted)setState(()=>_saving=false);}
  }

  Future<void> _addCategory() async {
    if(Supabase.instance.client.auth.currentUser==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Accedi per creare una categoria.')));return;}
    final name=TextEditingController(); String iconKey='category_outlined', colorName='Oro'; Uint8List? logoBytes; String? logoName;
    final accepted=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,sd)=>AlertDialog(
      title:const Text('CREA CATEGORIA COLLEZIONE'), content:SizedBox(width:460,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:name,textCapitalization:TextCapitalization.words,decoration:const InputDecoration(labelText:'Descrizione categoria',hintText:'Es. Orologi Swatch')), const SizedBox(height:14),
        DropdownButtonFormField<String>(value:iconKey,decoration:const InputDecoration(labelText:'Logo della categoria'),items:_icons.entries.map((e)=>DropdownMenuItem(value:e.key,child:Row(children:[Icon(e.value,size:20),const SizedBox(width:10),Text(e.key.replaceAll('_',' '))]))).toList(),onChanged:(v){if(v!=null)sd(()=>iconKey=v);}),
        const SizedBox(height:14), StatefulBuilder(builder:(ctx,logoSet)=>Column(children:[if(logoBytes!=null) Image.memory(logoBytes!,height:90,fit:BoxFit.contain),Row(children:[Expanded(child:Text(logoName??'Nessuna immagine personalizzata')),TextButton.icon(onPressed:() async {final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:85,maxWidth:1200);if(picked!=null){logoBytes=await picked.readAsBytes();logoSet(()=>logoName=picked.name);}},icon:const Icon(Icons.image_outlined),label:const Text('SCEGLI IMMAGINE')),if(logoBytes!=null) IconButton(onPressed:()=>logoSet(()=>{logoBytes=null,logoName=null}),icon:const Icon(Icons.delete_outline))])])), const SizedBox(height:14), DropdownButtonFormField<String>(value:colorName,decoration:const InputDecoration(labelText:'Colore della scheda'),items:_colors.entries.map((e)=>DropdownMenuItem(value:e.key,child:Row(children:[Container(width:20,height:20,decoration:BoxDecoration(color:Color(int.parse(e.value.substring(1),radix:16)+0xFF000000),borderRadius:BorderRadius.circular(5))),const SizedBox(width:10),Text(e.key)]))).toList(),onChanged:(v){if(v!=null)sd(()=>colorName=v);}),
        const SizedBox(height:8),const Text('Il codice progressivo univoco viene assegnato automaticamente.',style:TextStyle(fontSize:12)),
      ]))), actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('ANNULLA')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('CREA CATEGORIA'))])));
    if(accepted!=true){name.dispose();return;} final description=name.text.trim(); if(description.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Inserisci la descrizione della categoria.')));name.dispose();return;}
    setState(()=>_saving=true); try {
      final existing=await Supabase.instance.client.schema('collection').from('master_categorie_collezione').select('codice_categoria').ilike('descrizione',description);
      if((existing as List).isNotEmpty){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Esiste già una categoria con questa descrizione.')));return;}
      final codes=_rows.map((r)=>(r['codice_categoria']??'').toString()).where((v)=>RegExp(r'^CAT-\d+$').hasMatch(v)).map((v)=>int.tryParse(v.substring(4))??0).toList();
      final maxCode=codes.isEmpty?0:codes.reduce((a,b)=>a>b?a:b); final code='CAT-'+(maxCode+1).toString().padLeft(3,'0');
      final maxOrder=_rows.map((r)=>int.tryParse('${r['ordine_menu']??0}')??0).fold<int>(0,(a,b)=>a>b?a:b);
      await Supabase.instance.client.schema('collection').from('master_categorie_collezione').insert({'codice_categoria':code,'descrizione':description,'icona':iconKey,'colore_hex':_colors[colorName],'ordine_menu':maxOrder+10,'visibile':true,'logo_url':await _saveCategoryLogo(logoBytes,logoName,code,null)});
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Categoria '+code+' creata.'))); await _load();
    } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Creazione categoria non riuscita: '+e.toString())));} finally{name.dispose();if(mounted)setState(()=>_saving=false);}
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CATEGORIE COLLEZIONE'), actions: [
        IconButton(onPressed: _load, tooltip: 'Aggiorna', icon: const Icon(Icons.refresh)),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _addCategory,
        icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
        label: Text(_saving ? 'SALVATAGGIO...' : 'CREA CATEGORIA'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(20), child: SelectableText(_error!)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: _rows.length,
                  itemBuilder: (context, i) {
                    final row = _rows[i];
                    final hex = (row['colore_hex'] ?? '#D6B15E').toString();
                    final rgb = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xD6B15E;
                    final parsed = Color(rgb + 0xFF000000);
                    final iconKey = (row['icona'] ?? 'category_outlined').toString();
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: parsed.withValues(alpha: 0.18),
                          child: (row['logo_url']??'').toString().trim().isNotEmpty ? ClipOval(child:Image.network(_valoraImageProxyUrl(row['logo_url'].toString()),fit:BoxFit.cover,width:48,height:48,errorBuilder:(c,e,s)=>Icon(_icons[iconKey]??Icons.category_outlined,color:parsed))) : Icon(_icons[iconKey] ?? Icons.category_outlined, color: parsed),
                        ),
                        title: Text((row['descrizione'] ?? 'Categoria').toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${row['codice_categoria']} · ${row['visibile'] == true ? 'Visibile nel menu' : 'Nascosta dal menu'}'),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 24, height: 24, decoration: BoxDecoration(color: parsed, borderRadius: BorderRadius.circular(6))),
                          IconButton(tooltip: 'Modifica categoria', onPressed: _saving ? null : () => _editCategory(row), icon: const Icon(Icons.edit_outlined)),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
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
  String _market = '';
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
          ValoraI18n.instance.setLanguage((row['lingua_interfaccia'] ?? 'it').toString());
          _dateFormat = (row['formato_data'] ?? 'GG/MM/AAAA').toString();
          final market = _markets.where((m) => m['codice_mercato'] == row['mercato_nazionale_principale']).toList();
          if (market.isNotEmpty) _market = market.first['nome_mercato'].toString();
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
  String _languageFor(String code) => const {'it':'Italiano','en':'English','fr':'Français','es':'Español'}[code] ?? 'Italiano';

  Future<void> _saveProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Accedi per salvare il profilo.')));
      return;
    }
    if (!_profileLoaded || _markets.isEmpty || _name.text.trim().isEmpty ||
        !_markets.any((m) => m['nome_mercato'] == _market)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa il nome e seleziona il tuo mercato principale prima di salvare.')));
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
        'lingua_interfaccia': const {'Italiano':'it','English':'en','Français':'fr','Español':'es'}[_language] ?? 'it',
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
      ValoraI18n.instance.setLanguage((values['lingua_interfaccia'] ?? 'it').toString());
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
          Text(ValoraI18n.tr(title), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 14),
        ...children,
      ]),
    ),
  );

  InputDecoration _fieldDecoration(String label, {Widget? suffixIcon, String? helper}) =>
      InputDecoration(labelText: ValoraI18n.tr(label), helperText: helper == null ? null : ValoraI18n.tr(helper), suffixIcon: suffixIcon);

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final created = user?.createdAt;
    return Scaffold(
      appBar: AppBar(
        title: Text(ValoraI18n.tr('Profilo utente')),
        leading: IconButton(
          tooltip: ValoraI18n.tr('Torna alla dashboard'),
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
                    tooltip: ValoraI18n.tr(_showNewPassword ? 'Nascondi password' : 'Mostra password'),
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
                label: Text(ValoraI18n.tr(_busy ? 'AGGIORNAMENTO...' : 'CAMBIA PASSWORD')),
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
                items: const ['Italiano', 'English', 'Français', 'Español'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
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
              ListTile(contentPadding: EdgeInsets.zero, title: Text(ValoraI18n.tr('Stato')), trailing: Chip(label: Text(ValoraI18n.tr('Autenticato')))),
              ListTile(contentPadding: EdgeInsets.zero, title: Text(ValoraI18n.tr('Data creazione account')), subtitle: Text(created ?? ValoraI18n.tr('Non disponibile'))),
            ]),
            Card(
              color: ValoraAppearance.instance.card,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(ValoraI18n.tr('Il profilo viene letto e salvato in master_utente nel database TEST. Le preferenze grafiche restano separate e locali.')),
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
          ? 'Assistente pronto. Puoi parlare in $_speechLanguageName.'
          : 'Riconoscimento vocale non disponibile: puoi comunque scrivere il comando.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Microfono non disponibile: $e');
    }
  }

  String get _speechLocaleId => switch (ValoraI18n.instance.code) {
    'en' => 'en_US',
    'fr' => 'fr_FR',
    'de' => 'de_DE',
    'es' => 'es_ES',
    'pt' => 'pt_BR',
    'zh' => 'zh_CN',
    'ja' => 'ja_JP',
    'ru' => 'ru_RU',
    _ => 'it_IT',
  };

  String get _speechLanguageName => switch (ValoraI18n.instance.code) {
    'en' => 'English',
    'fr' => 'français',
    'de' => 'Deutsch',
    'es' => 'español',
    'pt' => 'português',
    'zh' => '普通话',
    'ja' => '日本語',
    'ru' => 'русский',
    _ => 'italiano',
  };

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
      localeId: _speechLocaleId,
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
    appBar: AppBar(title: Text(ValoraI18n.tr('ASSISTENTE VALORA'))),
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
  const CategoryObjectSearchPage({super.key, this.initialQuery, this.initialCategoryCode});
  final String? initialQuery;
  final String? initialCategoryCode;

  @override
  State<CategoryObjectSearchPage> createState() => _CategoryObjectSearchPageState();
}

class _CategoryObjectSearchPageState extends State<CategoryObjectSearchPage> {
  final TextEditingController _query = TextEditingController();
  bool _loading = false;
  String _message = 'Inserisci una categoria o una dicitura, per esempio TRANSFORMERS.';
  List<Map<String, dynamic>> _results = [];
  int _resultsPage = 0;
  static const int _resultsPageSize = 50;
  List<Map<String, dynamic>> _themes = [];
  String? _selectedThemeId;

  Future<void> _loadThemes() async {
    final code = widget.initialCategoryCode?.trim() ?? '';
    if (code.isEmpty) return;
    try {
      final response = await Supabase.instance.client.schema('collection')
          .from('temi_collezione')
          .select('id_tema, descrizione')
          .eq('codice_categoria', code)
          .eq('attivo', true)
          .order('ordine')
          .order('descrizione');
      if (!mounted) return;
      setState(() => _themes = List<Map<String, dynamic>>.from(
        (response as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)),
      ));
    } catch (e) {
      if (mounted) setState(() => _message = 'Impossibile caricare i temi: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadThemes();
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
    // La schermata "VEDI TUTTI" deve filtrare sulla categoria merceologica
    // canonica restituita da PR-11, mai su parole della descrizione.
    // Il vecchio filtro per regex spostava, per esempio, Batman Funko nei fumetti
    // e tutti gli oggetti non riconosciuti in "Altre collezioni".
    final canonical = (row['categoria'] ?? '').toString().trim();
    if (canonical.isEmpty) {
      return category.trim().toUpperCase() == 'DA CLASSIFICARE';
    }
    return canonical.toLowerCase() == category.trim().toLowerCase();
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
      final categoryMode = (widget.initialQuery?.trim().isNotEmpty ?? false) ||
          (widget.initialCategoryCode?.trim().isNotEmpty ?? false);
      Set<String>? assignedObjectCodes;
      if (widget.initialCategoryCode?.trim().isNotEmpty ?? false) {
        final assignmentResponse = await Supabase.instance.client.schema('collection')
            .from('oggetto_collezione_categoria')
            .select('codice_oggetto, id_tema')
            .eq('codice_categoria', widget.initialCategoryCode!.trim());
        final assignmentRows = (assignmentResponse as List)
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row));
        assignedObjectCodes = assignmentRows
            .where((row) => _selectedThemeId == null ||
                (row['id_tema'] ?? '').toString() == _selectedThemeId)
            .map((row) => (row['codice_oggetto'] ?? '').toString())
            .toSet();
      }
      final normalizedInput = query.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
      final otherCollectionsMode = !categoryMode &&
          (normalizedInput == 'altre collezioni' || normalizedInput == 'altre collezione');
      final response = await Supabase.instance.client.schema('collection').rpc(
        'pr_21_ricerca_schede',
        params: {'p_cerca': (categoryMode || otherCollectionsMode) ? null : query},
      );
      dynamic payload = response;
      if (payload is List && payload.length == 1 && payload.first is Map) {
        payload = payload.first;
      }
      if (payload is! Map || payload['oggetti'] is! List) {
        throw Exception('Il catalogo non ha restituito un elenco di oggetti valido.');
      }
      final normalizedQuery = normalizedInput;
      const primaryDashboardCategories = {'lego', 'saint seiya', 'fumetti', 'transformers'};
      final rows = (payload['oggetti'] as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .where((row) {
            // Le ricerche della collezione escludono sempre oggetti non più disponibili,
            // anche quando esiste ancora una vecchia assegnazione di categoria.
            final destination = (row['destinazione'] ?? '').toString().trim().toUpperCase();
            final state = (row['stato'] ?? '').toString().trim().toUpperCase();
            if (destination != 'COLLEZIONE' || row['archiviato_test'] == true ||
                ['VENDUTO', 'PERSO', 'DISTRUTTO', 'USCITO', 'ACCORPATO'].contains(state)) {
              return false;
            }
            if (widget.initialCategoryCode?.trim().isNotEmpty ?? false) {
              return assignedObjectCodes!.contains(_code(row));
            }
            if (categoryMode) {
              return _matchesInitialCategory(row, widget.initialQuery!.trim());
            }
            if (otherCollectionsMode) {
              final canonical = (row['categoria'] ?? '').toString().trim().toLowerCase();
              return canonical.isEmpty || !primaryDashboardCategories.contains(canonical);
            }
            final description = _description(row).toLowerCase();
            final objectCode = _code(row).toLowerCase();
            final category = (row['categoria'] ?? '').toString().toLowerCase().trim();
            final categoryCode = (row['codice_categoria'] ?? '').toString().toLowerCase().trim();
            return description.contains(normalizedQuery) ||
                objectCode.contains(normalizedQuery) ||
                category.contains(normalizedQuery) ||
                categoryCode.contains(normalizedQuery);
          })
          .toList()
        ..sort((a, b) => (int.tryParse(_code(a)) ?? 0).compareTo(int.tryParse(_code(b)) ?? 0));

      final allResponse = await Supabase.instance.client.schema('collection').rpc(
        'pr_21_ricerca_schede',
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
        _resultsPage = 0;
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
    final pageCount = (_results.length / _resultsPageSize).ceil();
    final pageStart = (_resultsPage * _resultsPageSize).clamp(0, _results.length);
    final pageEnd = (pageStart + _resultsPageSize).clamp(0, _results.length);
    final visibleResults = _results.sublist(pageStart, pageEnd);
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
            if ((widget.initialCategoryCode?.trim().isNotEmpty ?? false) && _themes.isNotEmpty) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedThemeId,
                decoration: const InputDecoration(
                  labelText: 'Categoria 1 · Tema',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Tutti i temi')),
                  ..._themes.map((theme) => DropdownMenuItem<String?>(
                    value: (theme['id_tema'] ?? '').toString(),
                    child: Text((theme['descrizione'] ?? '').toString()),
                  )),
                ],
                onChanged: (value) {
                  setState(() => _selectedThemeId = value);
                  _search();
                },
              ),
            ],
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
            if (_results.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                Text('Visualizzazione ${pageStart + 1}–$pageEnd di ${_results.length}', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
                const Spacer(),
                IconButton(tooltip: 'Blocco precedente', onPressed: _resultsPage > 0 ? () => setState(() => _resultsPage--) : null, icon: const Icon(Icons.chevron_left)),
                Text('${_resultsPage + 1}/$pageCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(tooltip: 'Blocco successivo', onPressed: _resultsPage + 1 < pageCount ? () => setState(() => _resultsPage++) : null, icon: const Icon(Icons.chevron_right)),
              ]),
            ],
            const SizedBox(height: 8),
            ...visibleResults.map((row) => Card(
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
  final Set<int> _selectedRows = {};
  int _importPage = 0;
  static const int _importPageSize = 50;
  static const _headers = ['codice_oggetto','descrizione_oggetto','condizione','completezza','destinazione','stato','quantita','valore_oggetto','valuta_valore','totale_calcolato'];

  String _norm(dynamic value) => (value ?? '').toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<List<Map<String,dynamic>>> _catalog() async {
    final result = await Supabase.instance.client.schema('collection').rpc('pr_21_ricerca_schede', params: {'p_cerca': null});
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
    // Compatibile con la versione file_picker bloccata nel progetto:
    // bytes, poi readStream, infine path locale quando disponibile.
    late final Uint8List bytes;
    try {
      if (file.bytes != null) {
        bytes = file.bytes!;
      } else if (file.readStream != null) {
        final buffer = BytesBuilder(copy: false);
        await for (final chunk in file.readStream!) {
          buffer.add(chunk);
        }
        bytes = buffer.takeBytes();
      } else {
        final path = file.path;
        if (path == null || path.trim().isEmpty) {
          throw Exception('Android non ha fornito né contenuto, né flusso, né percorso locale.');
        }
        bytes = await File(path).readAsBytes();
      }
    } catch (e) {
      throw Exception('Lettura di "${file.name}" non riuscita (${file.size} byte dichiarati). Dettaglio: $e');
    }
    if (bytes.isEmpty) {
      throw Exception('Il file "${file.name}" è stato selezionato ma contiene 0 byte.');
    }
    final name = file.name.toLowerCase();
    if (name.endsWith('.json')) {
      final data = jsonDecode(utf8.decode(bytes));
      final list = data is Map ? (data['oggetti'] ?? data['objects'] ?? data['data']) : data;
      if (list is! List) throw Exception('Il JSON deve contenere un elenco di oggetti.');
      return list.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();
    }
  List<Map<String, dynamic>> _readXlsxXmlFallback(Uint8List bytes) {
    final zipped = archive.ZipDecoder().decodeBytes(bytes);
    String? entry(String path) {
      for (final file in zipped.files) {
        if (file.name == path) {
          final data = file.content;
          if (data is List<int>) return utf8.decode(data);
        }
      }
      return null;
    }
    final sheetXml = entry('xl/worksheets/sheet1.xml');
    if (sheetXml == null) throw Exception('Il file XLSX non contiene il primo foglio.');
    final shared = <String>[];
    final sharedXml = entry('xl/sharedStrings.xml');
    if (sharedXml != null) {
      final doc = xml.XmlDocument.parse(sharedXml);
      for (final si in doc.descendants.whereType<xml.XmlElement>().where((e) => e.name.local == 'si')) {
        shared.add(si.descendants.whereType<xml.XmlElement>().where((e) => e.name.local == 't').map((e) => e.innerText).join());
      }
    }
    final doc = xml.XmlDocument.parse(sheetXml);
    final lines = <Map<int, String>>[];
    for (final row in doc.descendants.whereType<xml.XmlElement>().where((e) => e.name.local == 'row')) {
      final values = <int, String>{};
      for (final cell in row.children.whereType<xml.XmlElement>().where((e) => e.name.local == 'c')) {
        final ref = cell.getAttribute('r') ?? '';
        final letters = RegExp(r'^[A-Z]+').stringMatch(ref);
        if (letters == null) continue;
        var col = 0;
        for (final unit in letters.codeUnits) { col = col * 26 + unit - 64; }
        final type = cell.getAttribute('t') ?? '';
        final raw = cell.descendants.whereType<xml.XmlElement>().where((e) => e.name.local == (type == 'inlineStr' ? 't' : 'v')).map((e) => e.innerText).join();
        values[col - 1] = type == 's' ? (int.tryParse(raw) != null && int.parse(raw) < shared.length ? shared[int.parse(raw)] : '') : raw;
      }
      lines.add(values);
    }
    final headerIndex = lines.indexWhere((row) => row.values.any((v) => const ['descrizione_oggetto', 'descrizione', 'nome'].contains(v.trim().toLowerCase())));
    if (headerIndex < 0) throw Exception('Intestazione descrizione_oggetto non trovata nel foglio Excel.');
    final headers = lines[headerIndex].map((k,v) => MapEntry(k,v.trim().toLowerCase()));
    return lines.skip(headerIndex + 1).where((row) => row.values.any((v) => v.trim().isNotEmpty)).map((row) {
      final result = <String, dynamic>{};
      for (final h in headers.entries) { if (h.value.isNotEmpty) result[h.value] = row[h.key] ?? ''; }
      return result;
    }).toList();
  }

    if (name.endsWith('.xlsx')) {
      late final xlsx.Excel workbook;
      try {
        workbook = xlsx.Excel.decodeBytes(bytes);
      } catch (e) {
        try {
          return _readXlsxXmlFallback(bytes);
        } catch (fallbackError) {
          throw Exception('Excel "${file.name}" letto (${bytes.length} byte), ma non decodificabile. Lettore standard: $e. Lettore alternativo: $fallbackError');
        }
      }
      if (workbook.tables.isEmpty) throw Exception('Il file Excel non contiene fogli leggibili.');
      final firstSheet = workbook.tables.values.first;
      final table = firstSheet.rows;
      if (table.isEmpty) throw Exception('Il foglio Excel è vuoto o non contiene righe leggibili.');

      // I file esportati da app esterne possono avere righe introduttive prima dell'intestazione.
      // Cerca la riga che contiene un campo descrizione riconosciuto, invece di assumere la prima riga.
      int headerIndex = -1;
      List<String> headers = <String>[];
      for (var rowIndex = 0; rowIndex < table.length; rowIndex++) {
        final candidate = table[rowIndex]
            .map((cell) => (cell?.value?.toString() ?? '').trim().toLowerCase())
            .toList();
        final hasDescription = candidate.any((h) =>
            h == 'descrizione_oggetto' || h == 'descrizione' || h == 'nome');
        if (hasDescription) {
          headerIndex = rowIndex;
          headers = candidate;
          break;
        }
      }
      if (headerIndex < 0) {
        throw Exception('Intestazione non trovata. Il foglio deve contenere una colonna descrizione_oggetto, descrizione o nome.');
      }

      final parsed = <Map<String, dynamic>>[];
      try {
      for (final sourceRow in table.skip(headerIndex + 1)) {
        if (!sourceRow.any((cell) => (cell?.value?.toString() ?? '').trim().isNotEmpty)) continue;
        final row = <String, dynamic>{};
        for (var i = 0; i < headers.length && i < sourceRow.length; i++) {
          final header = headers[i];
          if (header.isEmpty) continue;
          row[header] = sourceRow[i]?.value?.toString() ?? '';
        }
        parsed.add(row);
      }
      } catch (e) {
        throw Exception('Errore durante la lettura delle righe Excel (righe rilevate: ${table.length}): $e');
      }
      if (parsed.isEmpty) throw Exception('Intestazione trovata, ma non ci sono righe oggetto da importare.');
      return parsed;
    }
    if (name.endsWith('.csv')) {
      // Gestisce BOM, righe vuote iniziali e separatori comuni dei CSV esportati.
      String csvText;
      try {
        csvText = utf8.decode(bytes);
      } on FormatException {
        csvText = latin1.decode(bytes);
      }
      csvText = csvText.replaceFirst('\uFEFF', '').replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      if (csvText.trim().isEmpty) {
        throw Exception('Il file "${file.name}" è vuoto: ${bytes.length} byte letti.');
      }
      final nonEmptyLines = csvText.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (nonEmptyLines.isEmpty) {
        throw Exception('Il file "${file.name}" contiene solo righe vuote (${bytes.length} byte letti).');
      }
      final sample = nonEmptyLines.first;
      int countDelimiter(String delimiter) => delimiter.allMatches(sample).length;
      final delimiters = <String>[';', ',', '\t'];
      delimiters.sort((a, b) => countDelimiter(b).compareTo(countDelimiter(a)));
      final delimiter = countDelimiter(delimiters.first) == 0 ? ',' : delimiters.first;
      final table = CsvToListConverter(
        shouldParseNumbers: false,
        fieldDelimiter: delimiter,
        eol: '\n',
      ).convert(csvText);
      final nonEmptyRows = table.where((row) =>
          row.any((value) => value.toString().trim().isNotEmpty)).toList();
      if (nonEmptyRows.length < 2) {
        throw Exception('CSV letto (${bytes.length} byte; ${nonEmptyRows.length} righe non vuote; separatore "${delimiter == '\t' ? 'TAB' : delimiter}"), ma non contiene intestazione e righe dati.');
      }
      // Cerca l'intestazione anche se il file contiene righe introduttive.
      int headerIndex = nonEmptyRows.indexWhere((row) => row.any((value) {
        final header = value.toString().trim().toLowerCase().replaceAll(' ', '_');
        return header == 'descrizione_oggetto' || header == 'descrizione' || header == 'nome';
      }));
      if (headerIndex < 0) headerIndex = 0;
      final headers = nonEmptyRows[headerIndex].map((value) =>
          value.toString().trim().toLowerCase().replaceAll(' ', '_')).toList();
      final parsed = <Map<String, dynamic>>[];
      for (final values in nonEmptyRows.skip(headerIndex + 1)) {
        if (!values.any((value) => value.toString().trim().isNotEmpty)) continue;
        final row = <String, dynamic>{};
        for (var i = 0; i < headers.length && i < values.length; i++) {
          if (headers[i].isNotEmpty) row[headers[i]] = values[i];
        }
        parsed.add(row);
      }
      if (parsed.isEmpty) {
        throw Exception('CSV letto correttamente (${bytes.length} byte; ${nonEmptyRows.length} righe non vuote), ma dopo l’intestazione non sono state trovate righe dati.');
      }
      return parsed;
    }
    throw Exception('Formato non supportato. Usa XLSX, CSV o JSON.');
  }

  // Uniforma le intestazioni indipendentemente dal formato sorgente (CSV, XLSX, JSON).
  Map<String, dynamic> _normalizeImportRow(Map<String, dynamic> source) {
    String normalizeKey(String key) => key
        .replaceAll(RegExp(r'([a-z0-9])([A-Z])'), r'$1_$2')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_');
    final row = <String, dynamic>{};
    for (final entry in source.entries) {
      final key = normalizeKey(entry.key);
      if (key.isNotEmpty) row[key] = entry.value;
    }
    const aliases = <String, String>{
      'nome_oggetto': 'descrizione_oggetto',
      'descrizione': 'descrizione_oggetto',
      'nome': 'descrizione_oggetto',
      'codice': 'codice_oggetto',
      'codice_prodotto': 'codice_oggetto',
      'quantita_importazione': 'quantita',
      'qty': 'quantita',
      'stato': 'stato_oggetto',
      'data_inserimento': 'data_inserimento',
      'data_di_inserimento': 'data_inserimento',
      'condizioni': 'condizione',
      'note_oggetto': 'note',
    };
    for (final entry in aliases.entries) {
      if (!row.containsKey(entry.value) && row.containsKey(entry.key)) {
        row[entry.value] = row[entry.key];
      }
    }
    return row;
  }

  Future<void> _pickImport() async {
    setState(() { _busy=true; _status='Seleziona un file da analizzare…'; _rows=[]; _duplicates.clear(); _invalid.clear(); _selectedRows.clear(); });
    try {
      final picked=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:const ['xlsx','csv','json'],withData:true,withReadStream:true);
      if (picked==null || picked.files.isEmpty) { if(mounted)setState(()=>_status='Importazione annullata. Nessuna modifica eseguita.'); return; }
      final parsedRows=await _parse(picked.files.first);
      final rows=parsedRows.map(_normalizeImportRow).toList();
      final existing=await _catalog();
      final descriptions=existing.map((e)=>_norm(e['descrizione_oggetto'])).toSet();
      final codes=existing.map((e)=>_norm(e['codice_oggetto'])).toSet();
      for(var i=0;i<rows.length;i++) {
        final desc=_norm(rows[i]['descrizione_oggetto'] ?? rows[i]['descrizione'] ?? rows[i]['nome']);
        final code=_norm(rows[i]['codice_oggetto'] ?? rows[i]['codice_prodotto'] ?? rows[i]['codice']);
        if(desc.isEmpty) _invalid.add(i);
        else if(descriptions.contains(desc) || (code.isNotEmpty && codes.contains(code)) ||
          rows.take(i).any((r)=>_norm(r['descrizione_oggetto'] ?? r['descrizione'] ?? r['nome'])==desc)) _duplicates.add(i);
      }
      if(mounted)setState(() { _rows=rows; _importPage=0; _selectedRows.clear(); _status='Anteprima ' + rows.length.toString() + ' righe. Possibili duplicati: ' + _duplicates.length.toString() + '. Senza descrizione: ' + _invalid.length.toString() + '. Seleziona gli oggetti da importare. Nessun record salvato.'; });
    } catch(e) { if(mounted)setState(()=>_status='Importazione non riuscita: '+e.toString()); }
    finally { if(mounted)setState(()=>_busy=false); }
  }

  String _enumValue(dynamic value, List<String> allowed, String fallback) {
    final v=(value ?? '').toString().trim().toUpperCase();
    return allowed.contains(v) ? v : fallback;
  }

  Future<void> _confirmImport() async {
    final eligible = <Map<String, dynamic>>[];
    for (var i = 0; i < _rows.length; i++) {
      if (_selectedRows.contains(i) && !_invalid.contains(i) && !_duplicates.contains(i)) {
        eligible.add(_rows[i]);
      }
    }
    if (eligible.isEmpty) {
      setState(() => _status = 'Seleziona almeno un record valido da importare.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('CONFERMA IMPORTAZIONE'),
        content: Text(
          'Saranno caricati e verificati ${eligible.length} oggetti selezionati, poi salvati con un’unica operazione SQL in TEST. Se un oggetto non supera la validazione, l’intero lotto sarà annullato. I possibili duplicati e le righe senza descrizione saranno esclusi. Procedere?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('IMPORTA')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() {
      _busy = true;
      _status = 'Preparazione di ${eligible.length} record. Nessuna scrittura ancora eseguita.';
    });

    final session = _uuid.v4();
    var lockAcquired = false;
    try {
      final lock = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': session});
      final lockResult = lock['result'];
      if (lockResult is! Map || lockResult['acquisito'] != true) {
        final message = lockResult is Map
            ? (lockResult['messaggio'] ?? lockResult['stato'] ?? 'Blocco archivio non acquisito').toString()
            : 'Blocco archivio non acquisito';
        throw Exception(message);
      }
      lockAcquired = true;

      // Preparare il lotto in memoria. Il runtime SQL rilascia il blocco dopo una scrittura riuscita:
      // per questo PR-01 save deve essere chiamata una sola volta per tutto il lotto.
      final objects = <Map<String, dynamic>>[];
      for (final row in eligible) {
        final description = (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome'] ?? '').toString().trim();
        final qty = int.tryParse((row['quantita'] ?? row['quantita_importazione'] ?? '1').toString().trim()) ?? 1;
        final valueText = (row['valore_oggetto'] ?? '').toString().trim().replaceAll(',', '.');
        final value = valueText.isEmpty ? null : double.tryParse(valueText);
        final yearText = (row['anno_uscita'] ?? '').toString().trim();
        final year = yearText.isEmpty ? null : int.tryParse(yearText);
        objects.add({
          'descrizione': description,
          'produttore': (row['produttore'] ?? '').toString().trim().isEmpty ? null : row['produttore'].toString().trim(),
          'anno_uscita': year,
          'codice_prodotto': (row['codice_prodotto'] ?? '').toString().trim().isEmpty ? null : row['codice_prodotto'].toString().trim(),
          'condizione': _enumValue(row['condizione'], const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], 'USATO'),
          'completezza': _enumValue(row['completezza'], const ['SIGILLATO','COMPLETO','INCOMPLETO'], 'COMPLETO'),
          'destinazione': _enumValue(row['destinazione'], const ['COLLEZIONE','RIVENDITA','ALTRO'], 'COLLEZIONE'),
          'quantita': qty < 1 ? 1 : qty,
          if (value != null && value >= 0) 'valore_oggetto': value,
          'note': (row['note'] ?? '').toString().trim().isEmpty ? null : row['note'].toString().trim(),
        });
      }

      final payload = <String, dynamic>{'oggetti': objects};
      if (mounted) setState(() => _status = 'Lotto preparato: ${objects.length} record. Verifica e salvataggio unico in corso…');

      await _ValoraRuntimeApi.procedure('PR-01', 'preview', payload, sessionId: session);
      final review = Map<String, dynamic>.from(payload)
        ..['dati_confermati'] = true
        ..['altra_operazione'] = false
        ..['conferma_finale'] = false;
      await _ValoraRuntimeApi.procedure('PR-01', 'review', review, sessionId: session);

      final save = Map<String, dynamic>.from(payload)
        ..['dati_confermati'] = true
        ..['altra_operazione'] = false
        ..['conferma_finale'] = true;
      final result = await _ValoraRuntimeApi.procedure(
        'PR-01', 'save', save, sessionId: session, requestId: _uuid.v4(),
      );
      if (result['scrittura_eseguita'] != true) {
        throw Exception('Il database non ha confermato il salvataggio del lotto.');
      }
      final results = result['risultati'];
      final savedCount = results is List ? results.length : 0;
      if (savedCount != eligible.length) {
        throw Exception('Verifica incompleta: richiesti ${eligible.length}, confermati ${savedCount}. Controllare il database prima di riprovare.');
      }
      if (mounted) {
        setState(() => _status = 'Importazione conclusa. Lotto salvato e verificato: ${savedCount} record su ${eligible.length}.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Importazione non completata: ${e.toString()}');
      }
    } finally {
      // Il runtime SQL può aver rilasciato automaticamente il blocco dopo il commit.
      if (lockAcquired) {
        try {
          await _ValoraRuntimeApi.call('release_lock', {'session_id': session});
        } catch (_) {
          // Il blocco potrebbe essere già stato rilasciato dal runtime dopo il commit.
        }
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final color = appearance.colorFor('CATALOGO');
    final status = _status.trim();
    final isError = status.toLowerCase().contains('non riuscita') ||
        status.toLowerCase().contains('errore:') ||
        status.toLowerCase().contains('errori:') ||
        status.toLowerCase().contains('exception');
    final isSuccess = status.toLowerCase().contains('importazione conclusa') ||
        status.toLowerCase().contains('esportati ');
    final statusColor = isError
        ? const Color(0xFFE57373)
        : isSuccess
            ? const Color(0xFF81C784)
            : appearance.textSecondary;

    Widget sectionLabel(String label) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: TextStyle(
        color: appearance.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      )),
    );

    Widget tip(IconData icon, String title, String detail) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              Text(detail, style: TextStyle(
                color: appearance.textSecondary,
                fontSize: 13,
                height: 1.35,
              )),
            ],
          )),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(ValoraI18n.tr(widget.importMode ? 'IMPORTA OGGETTI' : 'ESPORTA OGGETTI')), 
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              widget.importMode
                  ? ValoraI18n.tr('Importa il catalogo da un file e controlla i dati prima di salvarli.')
                  : ValoraI18n.tr('Esporta una copia del catalogo nel formato che preferisci.'),
              style: TextStyle(
                color: appearance.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (widget.importMode) ...[
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  leading: Icon(Icons.tips_and_updates_outlined, color: color),
                  title: Text(ValoraI18n.tr('Preparare il file'), style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(ValoraI18n.tr('Requisiti e consigli per l’importazione')),
                  children: [
                    Align(alignment: Alignment.centerLeft, child: sectionLabel(ValoraI18n.tr('FORMATO E STRUTTURA'))),
                    tip(Icons.view_list_outlined, ValoraI18n.tr('Una riga per oggetto'), ValoraI18n.tr('Usa una riga per ogni oggetto e una colonna per ogni informazione.')),
                    tip(Icons.view_column_outlined, ValoraI18n.tr('Intestazioni riconoscibili'), ValoraI18n.tr('Mantieni le intestazioni del Master Oggetti, se disponibili. La descrizione dell’oggetto è obbligatoria.')),
                    tip(Icons.cleaning_services_outlined, ValoraI18n.tr('File pulito'), ValoraI18n.tr('Evita titoli sopra la tabella, celle unite e intestazioni duplicate. I dati mancanti possono restare vuoti.')),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Icon(Icons.file_present_outlined, size: 18, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Formati supportati: XLSX, CSV e JSON', style: TextStyle(color: appearance.textSecondary, fontSize: 13))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Prima del salvataggio vedrai l’anteprima e gli eventuali duplicati. I record già presenti non vengono aggiornati.',
                      style: TextStyle(color: appearance.textMuted, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (widget.importMode) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _pickImport,
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(ValoraI18n.tr(_busy ? 'ANALISI IN CORSO…' : 'SELEZIONA FILE E ANALIZZA')), 
                ),
              ),
              if (_rows.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Text(ValoraI18n.tr('ANTEPRIMA'), style: TextStyle(color: appearance.textSecondary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${_rows.length} record', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Selezionati: ${_selectedRows.where((i) => !_invalid.contains(i) && !_duplicates.contains(i)).length} · Esclusi: ${_invalid.length + _duplicates.length}',
                  style: TextStyle(color: appearance.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => setState(() {
                        final start = _importPage * _importPageSize;
                        final end = (start + _importPageSize) < _rows.length ? start + _importPageSize : _rows.length;
                        for (var i = start; i < end; i++) {
                          if (!_invalid.contains(i) && !_duplicates.contains(i)) {
                            _selectedRows.add(i);
                          }
                        }
                      }),
                      icon: const Icon(Icons.library_add_check, size: 18),
                      label: const Text('SELEZIONA PAGINA'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => setState(() {
                        _selectedRows
                          ..clear()
                          ..addAll(List<int>.generate(_rows.length, (i) => i).where((i) => !_invalid.contains(i) && !_duplicates.contains(i)));
                      }),
                      icon: const Icon(Icons.select_all, size: 18),
                      label: const Text('SELEZIONA TUTTI I VALIDI'),
                    ),
                    TextButton.icon(
                      onPressed: _busy ? null : () => setState(() => _selectedRows.clear()),
                      icon: const Icon(Icons.deselect, size: 18),
                      label: const Text('DESELEZIONA TUTTI'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._rows.skip(_importPage * _importPageSize).take(_importPageSize).toList().asMap().entries.map((entry) {
                  final i = _importPage * _importPageSize + entry.key;
                  final row = entry.value;
                  final desc = (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome'] ?? '').toString().trim();
                  final invalid = _invalid.contains(i);
                  final duplicate = _duplicates.contains(i);
                  final warning = invalid || duplicate;
                  final itemColor = warning ? const Color(0xFFFFB74D) : color;
                  final label = invalid
                      ? 'Non selezionabile: descrizione mancante'
                      : duplicate
                          ? 'Non selezionabile: possibile duplicato'
                          : _selectedRows.contains(i)
                              ? 'Selezionato per l’importazione'
                              : 'Disponibile per la selezione';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: !warning && _selectedRows.contains(i),
                      onChanged: warning || _busy ? null : (checked) => setState(() {
                        if (checked == true) {
                          _selectedRows.add(i);
                        } else {
                          _selectedRows.remove(i);
                        }
                        _status = 'Selezionati: ' + _selectedRows.where((n) => !_invalid.contains(n) && !_duplicates.contains(n)).length.toString() + '. Nessun record salvato.';
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: color,
                      secondary: Icon(warning ? Icons.warning_amber_rounded : Icons.inventory_2_outlined, color: itemColor),
                      title: Text(
                        desc.isEmpty ? 'Riga ${i + 2}' : desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(label, style: TextStyle(color: warning ? itemColor : appearance.textSecondary, fontSize: 12)),
                      ),
                    ),
                  );
                }),
                if (_rows.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Blocco precedente',
                          onPressed: _busy || _importPage == 0 ? null : () => setState(() => _importPage--),
                          icon: const Icon(Icons.arrow_back_ios_new),
                        ),
                        Expanded(
                          child: Text(
                            '${_importPage * _importPageSize + 1}–${((_importPage + 1) * _importPageSize) > _rows.length ? _rows.length : ((_importPage + 1) * _importPageSize)} di ${_rows.length} · Pagina ${_importPage + 1}/${((_rows.length - 1) ~/ _importPageSize) + 1}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: appearance.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Blocco successivo',
                          onPressed: _busy || (_importPage + 1) * _importPageSize >= _rows.length ? null : () => setState(() => _importPage++),
                          icon: const Icon(Icons.arrow_forward_ios),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _confirmImport,
                    icon: const Icon(Icons.save_outlined),
                    label: Text('IMPORTA ${_selectedRows.where((i) => !_invalid.contains(i) && !_duplicates.contains(i)).length} SELEZIONATI'),
                  ),
                ),
              ],
            ] else ...[
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : () => _export('xlsx'), icon: const Icon(Icons.table_view_outlined), label: const Text('ESPORTA EXCEL (.XLSX)'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _busy ? null : () => _export('csv'), icon: const Icon(Icons.description_outlined), label: const Text('ESPORTA CSV'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _busy ? null : () => _export('json'), icon: const Icon(Icons.data_object_outlined), label: const Text('ESPORTA JSON'))),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
            ],
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isError ? Icons.error_outline : isSuccess ? Icons.check_circle_outline : Icons.info_outline,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(status, style: TextStyle(color: statusColor, fontSize: 13, height: 1.4))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 15, color: appearance.textMuted),
                const SizedBox(width: 7),
                Expanded(child: Text(
                  'Ambiente TEST · L’importazione crea nuovi record e non modifica quelli esistenti.',
                  style: TextStyle(color: appearance.textMuted, fontSize: 11, height: 1.35),
                )),
              ],
            ),
          ],
        ),
      ),
    );
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

class _ObjectRuntimePageState extends State<ObjectRuntimePage> with _Pr03ControllerOwner {
  final Pr01Controller _pr01Controller = Pr01Controller();
  final Pr02Controller _pr02Controller = Pr02Controller();





  String get _condition => _pr01Controller.condition;
  set _condition(String value) => _pr01Controller.condition = value;
  String get _completeness => _pr01Controller.completeness;
  set _completeness(String value) => _pr01Controller.completeness = value;
  String get _destination => _pr01Controller.destination;
  set _destination(String value) => _pr01Controller.destination = value;
  List<Map<String, dynamic>> get _collectionCategories => _pr01Controller.collectionCategories;
  set _collectionCategories(List<Map<String, dynamic>> value) => _pr01Controller.collectionCategories = value;
  String? get _selectedCollectionCategory => _pr01Controller.selectedCollectionCategory;
  set _selectedCollectionCategory(String? value) => _pr01Controller.selectedCollectionCategory = value;
  bool get _categoriesLoading => _pr01Controller.categoriesLoading;
  set _categoriesLoading(bool value) => _pr01Controller.categoriesLoading = value;
  List<Map<String, dynamic>> get _pr01PendingObjects => _pr01Controller.pendingObjects;
  String? get _pr01PendingRequestId => _pr01Controller.pendingRequestId;
  set _pr01PendingRequestId(String? value) => _pr01Controller.pendingRequestId = value;

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
  final Pr01ImageManager _pr01ImageManager = Pr01ImageManager();
  Uint8List? get _selectedImageBytes => _pr01Controller.selectedImageBytes;
  set _selectedImageBytes(Uint8List? value) => _pr01Controller.selectedImageBytes = value;
  String? get _selectedImageName => _pr01Controller.selectedImageName;
  set _selectedImageName(String? value) => _pr01Controller.selectedImageName = value;
  String get _imageAcquisition => _pr01Controller.imageAcquisition;
  set _imageAcquisition(String value) => _pr01Controller.imageAcquisition = value;
  String? get _existingImageUrl => _pr01Controller.existingImageUrl;
  set _existingImageUrl(String? value) => _pr01Controller.existingImageUrl = value;
  String get _imageStatus => _pr01Controller.imageStatus;
  set _imageStatus(String value) => _pr01Controller.imageStatus = value;

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
  String _output = 'Pronto. Le consultazioni sono in sola lettura.';
  Map<String, dynamic>? _lastResult;
  List<dynamic> _rows = [];
  int _availablePage = 0;
  static const int _availablePageSize = 50;
  final Map<int, String> _activeReportImageUrls = <int, String>{};
  final Map<String, int> _reportImageObjectIdsByDescription = <String, int>{};
  Map<String, dynamic>? _currentObject;
  List<Map<String, dynamic>> _pr12IncompleteRecords = [];
  int _pr12NextBatchOffset = 0;
  int _pr12QueuePage = 0;
  final Set<String> _pr12SelectedRecordIds = <String>{};
  bool _pr12AiBatchRunning = false;
  String _pr12AiBatchStatus = 'Ricerca multi-fonte non ancora avviata.';
  List<Map<String, dynamic>> _pr12AiResults = [];
  List<Map<String, dynamic>> _pr12UnresolvedRecords = [];
  final Map<String, int> _pr12SelectedCandidates = {};
  bool _pr12RetryRunning = false;
  int _pr11MasterTabIndex = 0;
  List<Map<String, dynamic>> _pr11CategoryFieldDefinitions = [];
  Map<String, dynamic> _pr11CategoryValues = {};
  String? _pr11CategoryCode;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _pr11SearchFocusNode = FocusNode();
  String _lastPr11SearchQuery = '';

  String _reportPeriodMode = 'month';
  DateTime _reportStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _reportEnd = DateTime.now();
  bool get _isActiveListingsReport => const {'REPORT-ACTIVE-LISTINGS', 'REPORT-SALES-ACTIVE'}.contains(widget.apiCode);
  bool get _isPeriodReport => const {'REPORT-CASH', 'REPORT-PURCHASES', 'REPORT-SALES'}.contains(widget.apiCode);
  bool get _isCollectionThemeReport => widget.apiCode == 'REPORT-COLLECTION-THEME';
  bool get _usesStandardReportPresentation => widget.apiCode.startsWith('REPORT-') || _isActiveListingsReport;
  bool get _reportCanShowObjectImages => _usesStandardReportPresentation && widget.apiCode != 'REPORT-CASH';

  Future<void> _loadActiveReportImages(List<dynamic> records) async {
    final ids = <int>{};
    for (final raw in records.whereType<Map>()) {
      var id = int.tryParse((raw['codice_oggetto'] ?? raw['id_oggetto'] ?? '').toString());
      final description = (raw['descrizione_oggetto'] ?? raw['descrizione'] ?? raw['nome_oggetto'] ?? raw['titolo'] ?? '').toString().trim();
      if ((id == null || id <= 0) && description.isNotEmpty) {
        // Le righe acquisto spesso contengono un prefisso operativo, non la
        // descrizione catalogo esatta. Proviamo titolo pulito e codice prodotto.
        final cleaned = description.replaceFirst(
          RegExp(r'^(nuovo\\s+acquisto|acquisto)\\s+', caseSensitive: false),
          '',
        ).trim();
        final candidates = <String>[cleaned];
        final productCode = RegExp(r'\\b\\d{4,6}\\b').firstMatch(cleaned)?.group(0);
        if (productCode != null) candidates.add(productCode);
        final colon = cleaned.indexOf(':');
        if (colon > 0 && colon + 1 < cleaned.length) candidates.add(cleaned.substring(colon + 1).trim());
        for (final candidate in candidates) {
          try {
            final match = await Supabase.instance.client.schema('collection')
                .from('master_oggetti').select('codice_oggetto')
                .ilike('descrizione_oggetto', '%$candidate%').limit(1).maybeSingle();
            id = int.tryParse((match?['codice_oggetto'] ?? '').toString());
            if (id != null && id > 0) break;
          } catch (e) {
            debugPrint('VALORA: associazione immagine acquisto non disponibile: $e');
          }
        }
      }
      if (id != null && id > 0) {
        ids.add(id);
        if (description.isNotEmpty) _reportImageObjectIdsByDescription[description.toLowerCase()] = id;
      }
    }
    await Future.wait(ids.map((id) async {
      var url = '';
      try {
        final metadata = await Supabase.instance.client.schema('collection')
            .from('master_metadati').select('url_immagine').eq('codice_oggetto', id).maybeSingle();
        url = (metadata?['url_immagine'] ?? '').toString().trim();
      } catch (e) {
        debugPrint('VALORA: immagine catalogo report $id non disponibile: $e');
      }
      if (!(url.startsWith('https://') || url.startsWith('http://'))) {
        try {
          final session = Supabase.instance.client.auth.currentSession;
          final response = await Supabase.instance.client.functions.invoke(
            'collection-object-images-test',
            headers: session == null ? null : {'Authorization': 'Bearer ${session.accessToken}'},
            body: {'action': 'get', 'codice_oggetto': id},
          );
          if (response.status >= 200 && response.status < 300 && response.data is Map) {
            final data = Map<String, dynamic>.from(response.data as Map);
            url = (data['signed_url'] ?? data['url'] ?? data['image_url'] ?? data['url_immagine'] ?? '').toString().trim();
          }
        } catch (e) {
          debugPrint('VALORA: immagine storage report $id non disponibile: $e');
        }
      }
      if (url.startsWith('https://') || url.startsWith('http://')) {
        _activeReportImageUrls[id] = url;
      }
    }));
    if (!mounted || _activeReportImageUrls.isEmpty) return;
    setState(() {
      _rows = _rows.map((raw) {
        if (raw is! Map) return raw;
        final row = Map<String, dynamic>.from(raw);
        var id = int.tryParse((row['codice_oggetto'] ?? row['id'] ?? '').toString());
        final description = (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome_oggetto'] ?? '').toString().trim();
        id ??= _reportImageObjectIdsByDescription[description.toLowerCase()];
        final url = id == null ? null : _activeReportImageUrls[id];
        if (url != null && url.isNotEmpty) row['url_immagine_catalogo'] = url;
        return row;
      }).toList();
    });
  }

  Future<void> _showPurchaseReportDetail(Map<String, dynamic> item) async {
    final purchaseId = int.tryParse((item['codice_acquisto'] ?? '').toString());
    if (purchaseId == null || purchaseId <= 0) return;
    try {
      final db = Supabase.instance.client.schema('collection');
      final header = await db.from('master_acquisti')
          .select('codice_acquisto,data_acquisto,importo_totale_acquisto,valuta,descrizione')
          .eq('codice_acquisto', purchaseId).maybeSingle();
      final details = await db.from('acquisti_oggetti')
          .select('codice_oggetto,descrizione_oggetto,quantita,valore_acquisto_oggetto,valuta')
          .eq('codice_acquisto', purchaseId).order('codice_oggetto');
      final rows = (details as List).whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row)).toList();
      final ids = rows.map((row) => int.tryParse((row['codice_oggetto'] ?? '').toString()))
          .whereType<int>().where((id) => id > 0).toSet().toList();
      final names = <int, String>{};
      if (ids.isNotEmpty) {
        final catalog = await db.from('master_oggetti')
            .select('codice_oggetto,descrizione_oggetto').inFilter('codice_oggetto', ids);
        for (final raw in catalog as List) {
          if (raw is! Map) continue;
          final row = Map<String, dynamic>.from(raw);
          final id = int.tryParse((row['codice_oggetto'] ?? '').toString());
          final name = (row['descrizione_oggetto'] ?? '').toString().trim();
          if (id != null && name.isNotEmpty) names[id] = name;
        }
      }
      String money(dynamic value, [String currency = 'EUR']) {
        final amount = double.tryParse((value ?? '').toString()) ?? 0;
        return '${amount.toStringAsFixed(2).replaceAll('.', ',')} $currency';
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Acquisto #$purchaseId'),
          content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              if (header != null) ...[
                Text('Data: ${header['data_acquisto'] ?? item['data_acquisto'] ?? 'Non indicata'}'),
                const SizedBox(height: 4),
                Text('Totale: ${money(header['importo_totale_acquisto'] ?? item['importo_totale_acquisto'], (header['valuta'] ?? item['valuta'] ?? 'EUR').toString().trim())}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                if ((header['descrizione'] ?? '').toString().trim().isNotEmpty) Text(header['descrizione'].toString()),
              ],
              const Divider(height: 24),
              const Text('OGGETTI ACQUISTATI', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (rows.isEmpty) const Text('Nessun dettaglio oggetto registrato.'),
              ...rows.map((row) {
                final id = int.tryParse((row['codice_oggetto'] ?? '').toString());
                final name = (id == null ? null : names[id]) ?? row['descrizione_oggetto']?.toString() ?? 'Oggetto non descritto';
                final qty = int.tryParse((row['quantita'] ?? 1).toString()) ?? 1;
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Codice oggetto: ${id ?? 'Non assegnato'} · Quantità: $qty'),
                    Text('Importo: ${money(row['valore_acquisto_oggetto'], (row['valuta'] ?? 'EUR').toString().trim())}'),
                  ],
                ));
              }),
            ]),
          )),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(ValoraI18n.tr('CHIUDI')))],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dettaglio acquisto #$purchaseId non disponibile: $error')));
    }
  }

  String _reportCodeForApi(String apiCode) => switch (apiCode) {
    'REPORT-CASH' => 'CASH_MOVEMENTS_REPORT',
    'REPORT-PURCHASES' => 'PURCHASES_REPORT',
    'REPORT-SALES' => 'SALES_REPORT',
    _ => throw Exception('Codice report non riconosciuto: $apiCode'),
  };

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

  bool get _isWrite => const {'PR-01', 'PR-02', 'PR-03', 'PR-06', 'PR-07', 'PR-08', 'PR-09'}.contains(widget.apiCode);

  @override
  void initState() {
    super.initState();
    if (widget.apiCode == 'OBJECT_MASTER') {
      _pr11SearchFocusNode.addListener(_onPr11SearchFocusChanged);
    }
    if (widget.apiCode == 'PR-01' || widget.apiCode == 'PR-02' || widget.apiCode == 'OBJECT_MASTER') {
      // PR-01 needs the category list for insertion; OBJECT_MASTER needs it
      // when opening an existing object so its saved category is visible/editable.
      _loadCollectionCategories();
    }
    _initializePr01Page();
    if (_isActiveListingsReport || widget.apiCode == 'OBJECTS_AVAILABLE') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _run(_consult);
      });
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

  Future<void> _loadCollectionCategories() async {
    _categoriesLoading = true;
    if (mounted) setState(() {});
    try {
      final categories = await _pr01Controller.loadCategories(
        Supabase.instance.client,
      );
      if (!mounted) return;
      setState(() => _collectionCategories = categories);
    } catch (e) {
      if (mounted) {
        setState(() => _output = 'Errore caricamento categorie COLLEZIONE: $e');
      }
    } finally {
      _categoriesLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _onPr11SearchFocusChanged() {
    if (widget.apiCode != 'OBJECT_MASTER' || _pr11SearchFocusNode.hasFocus || _loading) return;
    final query = _search.text.trim();
    if (query.length < 2 || query == _lastPr11SearchQuery) return;
    _lastPr11SearchQuery = query;
    _run(_searchPr02Objects);
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
    _disposePr01Page();
    if (_lockHeld) {
      _releaseOwnedLockSilently();
    }
    _pr11SearchFocusNode.removeListener(_onPr11SearchFocusChanged);
    _pr11SearchFocusNode.dispose();
    _descriptionFocus.dispose();
    _searchFocusNode.dispose();
    _pr02Controller.dispose();
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
    if (widget.apiCode == 'PR-01') return _buildPr01Payload();
    if (widget.apiCode == 'PR-02') return _buildPr02Payload();
    if (widget.apiCode == 'PR-03') return _buildPr03ClosurePayload();
    final id = int.tryParse(_code.text.trim());
    if (id == null || id <= 0) throw Exception('Inserisci un codice oggetto valido.');
    throw Exception('Procedura di scrittura non riconosciuta.');
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

  Future<void> _loadObject({int? pr03SelectionRequestId}) async {
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

    // Il prezzo pagato appartiene alla riga di dettaglio dell'acquisto,
    // non al valore di mercato dell'oggetto. Recuperarlo separatamente
    // e usarlo solo per la presentazione della scheda.
    try {
      final purchase = await Supabase.instance.client
          .schema('collection')
          .from('acquisti_oggetti')
          .select('codice_acquisto, valore_acquisto_oggetto, valuta')
          .eq('codice_oggetto', id)
          .order('codice_acquisto', ascending: false)
          .limit(1)
          .maybeSingle();
      if (purchase != null && purchase['valore_acquisto_oggetto'] != null) {
        m['prezzo_acquisto'] = purchase['valore_acquisto_oggetto'];
        m['valuta_acquisto'] = purchase['valuta'] ?? 'EUR';
        m['codice_acquisto'] = purchase['codice_acquisto'];
      }
    } catch (error) {
      debugPrint('VALORA: prezzo di acquisto non disponibile per $id: $error');
    }

    // Carica anche i metadati di catalogo e i campi specifici della categoria.
    // Le letture sono in sola lettura e non modificano i record.
    List<Map<String, dynamic>> categoryDefinitions = [];
    Map<String, dynamic> categoryValues = {};
    // La categoria è già disponibile nel record di catalogo master_metadati.
    // Usarla come fallback evita che un errore nella lettura dei valori specifici
    // nasconda anche le definizioni dei campi della categoria.
    String? categoryCode = m['codice_categoria']?.toString();
    // Fonte autorevole per categoria e URL immagine: record catalogo master_metadati.
    // La scheda oggetto può non includere questi campi nella risposta OBJECT_MASTER.
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Sessione non valida per i metadati.');
      final response = await Supabase.instance.client.functions.invoke(
        'collection-object-images-test',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'action': 'metadata', 'codice_oggetto': id},
      );
      if (response.status < 200 || response.status >= 300 || response.data is! Map) {
        throw Exception('Endpoint metadati HTTP ${response.status}');
      }
      final payload = Map<String, dynamic>.from(response.data as Map);
      final catalog = payload['metadata'];
      if (catalog is Map) {
        final row = Map<String, dynamic>.from(catalog);
        categoryCode = row['codice_categoria']?.toString() ?? categoryCode;
        for (final entry in row.entries) {
          if (entry.value != null && entry.value.toString().trim().isNotEmpty) categoryValues[entry.key] = entry.value;
        }
      }
      final specific = payload['specific'];
      if (specific is Map) {
        final row = Map<String, dynamic>.from(specific);
        categoryCode = row['codice_categoria']?.toString() ?? categoryCode;
        final rawValues = row['valori'];
        if (rawValues is Map) categoryValues.addAll(Map<String, dynamic>.from(rawValues));
      }
      if (payload['fields'] is List) {
        categoryDefinitions = List<Map<String, dynamic>>.from((payload['fields'] as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)));
      }
    } catch (error) {
      debugPrint('VALORA: endpoint metadati non disponibile per $id: $error');
    }

    // Fallback di presentazione: le definizioni a database possono essere
    // incomplete rispetto ai metadati già salvati da PR-12. Non nascondere
    // campi LEGO disponibili solo perché il registro della categoria è parziale.
    if (categoryCode == 'CAT-001' ||
        (m['produttore']?.toString().toUpperCase() == 'LEGO') ||
        (categoryValues['produttore']?.toString().toUpperCase() == 'LEGO')) {
      const legoFields = <String, String>{
        'tema': 'Tema LEGO',
        'sezione': 'Sezione LEGO',
        'sottotema': 'Sottotema LEGO',
        'numero_pezzi': 'Numero di pezzi del set',
        'numero_minifigure': 'Numero di minifigure',
        'dettagli_pezzi': 'Dettaglio pezzi',
        'contenuto_confezione': 'Contenuto della confezione',
        'caratteristiche_tecniche': 'Caratteristiche tecniche',
        'identificativi_aggiuntivi': 'Identificativi aggiuntivi',
        'modalita_alternative': 'Modalità alternative',
        'prezzo_lancio': 'Prezzo di lancio',
        'valuta_prezzo_lancio': 'Valuta prezzo di lancio',
        'mercato_riferimento_uscita': 'Mercato di riferimento',
        'stato_verifica': 'Stato verifica metadati',
      };
      final existing = categoryDefinitions
          .map((d) => d['nome_campo']?.toString())
          .whereType<String>().toSet();
      var order = categoryDefinitions.length * 10 + 10;
      for (final entry in legoFields.entries) {
        if (existing.add(entry.key)) {
          categoryDefinitions.add({
            'codice_campo': 'LEGO-FALLBACK-${entry.key}',
            'nome_campo': entry.key,
            'tipo_dato': 'text',
            'obbligatorio': false,
            'applicabilita': 'metadato disponibile',
            'ordine_visualizzazione': order,
            'descrizione': entry.value,
          });
          order += 10;
        }
      }
      categoryDefinitions.sort((a, b) =>
          ((a['ordine_visualizzazione'] as num?)?.toInt() ?? 9999)
              .compareTo(((b['ordine_visualizzazione'] as num?)?.toInt() ?? 9999)));
    }

    String txt(List<String> keys, [String fallback = '']) {
      for (final k in keys) { if (m[k] != null) return m[k].toString(); }
      return fallback;
    }
    String? assignedCollectionCategory;
    try {
      final assignment = await Supabase.instance.client.schema('collection')
          .from('oggetto_collezione_categoria').select('codice_categoria')
          .eq('codice_oggetto', id).maybeSingle();
      assignedCollectionCategory = assignment?['codice_categoria']?.toString();
    } catch (error) { debugPrint('VALORA: categoria COLLEZIONE non letta per $id: $error'); }
    if (pr03SelectionRequestId != null &&
        !_pr03Controller.isCurrentSelectionRequest(pr03SelectionRequestId)) return;
    setState(() {
      _pr11CategoryFieldDefinitions = categoryDefinitions;
      _pr11CategoryValues = categoryValues;
      _pr11CategoryCode = categoryCode;
      _selectedCollectionCategory = assignedCollectionCategory;
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
      if (const ['SIGILLATO','COMPLETO','COMPLETO CON ISTRUZIONI','COMPLETO CON SCATOLA E ISTRUZIONI','INCOMPLETO'].contains(cp)) _completeness = cp;
      final d = txt(['destinazione'], _destination);
      if (const ['COLLEZIONE','RIVENDITA','ALTRO'].contains(d)) _destination = d;
      _output = 'Scheda corrente caricata dal database. I campi sono in sola lettura fino alla conferma della procedura.';
      _existingImageUrl = null; _selectedImageBytes = null; _selectedImageName = null;
      _imageStatus = 'Verifica immagine associata…';
    });
    // La scheda di consultazione deve caricare l'immagine indipendentemente
    // dal codice procedura che l'ha aperta (PR-11, PR-02 o accesso diretto).
    await _loadExistingImage(id);
    if (mounted && _loadedObjectId == id && _existingImageUrl == null) {
      final catalogImage = (_pr11CategoryValues['url_immagine'] ??
          _pr11CategoryValues['image_url'] ??
          _currentObject?['url_immagine'] ??
          _currentObject?['image_url'] ??
          '').toString().trim();
      if (catalogImage.startsWith('https://') || catalogImage.startsWith('http://')) {
        setState(() {
          _existingImageUrl = catalogImage;
          _imageStatus = 'Immagine caricata dal catalogo metadati.';
        });
      }
    }
  }

  Future<void> _loadIncompleteMetadataCatalog() async {
    setState(() {
      _metadataResult = 'PR-12: analisi del catalogo in corso…';
      _output = _metadataResult;
      _pr12IncompleteRecords = [];
      _pr12QueuePage = 0;
      _pr12SelectedRecordIds.clear();
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

  Future<void> _runPr12AiBatch({bool retryUnresolved = false, Map<String, dynamic>? singleRecord, List<Map<String, dynamic>>? selectedRecords}) async {
    if (singleRecord == null && _pr12IncompleteRecords.isEmpty) { setState(() => _pr12AiBatchStatus = 'Prima esegui ANALIZZA CATALOGO.'); return; }
    final List<Map<String, dynamic>> batch;
    if (singleRecord != null) {
      batch = [singleRecord];
    } else if (selectedRecords != null) {
      batch = selectedRecords.take(10).toList();
      if (batch.isEmpty) { setState(() => _pr12AiBatchStatus = 'Seleziona almeno un record nella pagina corrente.'); return; }
    } else if (retryUnresolved) {
      if (_pr12UnresolvedRecords.isEmpty) { setState(() => _pr12AiBatchStatus = 'Non ci sono record da riprovare.'); return; }
      batch = _pr12UnresolvedRecords.take(10).toList();
    } else {
      if (_pr12NextBatchOffset >= _pr12IncompleteRecords.length) { setState(() => _pr12AiBatchStatus = 'Prima passata completata. I record irrisolti restano disponibili per una nuova ricerca.'); return; }
      batch = _pr12IncompleteRecords.skip(_pr12NextBatchOffset).take(10).toList();
    }
    setState(() { _pr12AiBatchRunning = true; _pr12RetryRunning = retryUnresolved; _pr12AiBatchStatus = singleRecord != null ? 'Ricerca singola per l’oggetto ${singleRecord['codice_oggetto']}…' : (selectedRecords != null ? 'Ricerca su ${batch.length} record selezionati…' : (retryUnresolved ? 'Nuovo tentativo sui record irrisolti…' : 'Ricerca multi-fonte del lotto in corso…')); });
    try {
      final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
        'modalita_ia': 'TEST',
        'oggetti': batch.map((row) {
          // Mantieni distinti tema e sottotema: non promuovere mai un
          // sottotema (es. Polizia) al campo tema solo perché è valorizzato.
          String metadataText(List<String> keys) {
            for (final key in keys) {
              final value = row[key];
              if (value != null && value.toString().trim().isNotEmpty) {
                return value.toString().trim();
              }
            }
            return '';
          }
          return {
            'id': (row['codice_oggetto'] ?? '').toString(),
            'descrizione': (row['descrizione_oggetto'] ?? '').toString(),
            'categoria': metadataText(['categoria_principale', 'categoria_collezione']).isNotEmpty
                ? metadataText(['categoria_principale', 'categoria_collezione'])
                : _pr12CategoryFromDescription((row['descrizione_oggetto'] ?? '').toString()),
            'tema': metadataText(['tema', 'tema_lego', 'franchise_tema', 'franchise', 'linea_prodotto']),
            'sottotema': metadataText(['sottotema', 'sotto_tema', 'sottotema_lego']),
            'sezione': metadataText(['sezione', 'serie', 'linea']),
            'mercato': (row['mercato'] ?? row['market'] ?? 'Italia').toString(),
          };
        }).toList(),
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
    final year = int.tryParse(yearText);
    final genericTitles = <String>{'home', 'homepage', 'official website', 'search results', 'catalogo', 'risultati della ricerca'};
    final usefulTitle = title.length >= 5 && !genericTitles.contains(title.toLowerCase());
    if (maker.isEmpty && year == null && productCode.isEmpty && !usefulTitle) {
      setState(() => _pr12AiBatchStatus = 'La fonte non contiene metadati strutturati o un titolo prodotto utilizzabile. Nessun dato modificato.');
      return;
    }
    final client = Supabase.instance.client;
    final current = await client.schema('collection').from('master_oggetti')
        .select('descrizione_oggetto,produttore,anno_uscita,codice_prodotto')
        .eq('codice_oggetto', id).maybeSingle();
    if (current == null) throw Exception('Oggetto #$id non trovato nel catalogo TEST.');
    final currentDescription = (current['descrizione_oggetto'] ?? '').toString().trim();
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
          'Codice prodotto: ' + (productCode.isEmpty ? 'non trovato' : productCode) + '\n\n'
          'La descrizione esistente viene conservata e integrata con il titolo candidato. Gli altri campi vengono compilati soltanto se vuoti. Verifica che il candidato identifichi proprio questo oggetto.',
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
    if (patch.isEmpty) {
      setState(() => _pr12AiBatchStatus = 'Nessun campo vuoto aggiornabile per l’oggetto #$id. I dati presenti sono stati conservati.');
      return;
    }
    await client.schema('collection').from('master_oggetti').update(patch).eq('codice_oggetto', id);
    if (!mounted) return;
    setState(() => _pr12AiBatchStatus = 'Metadati applicati all’oggetto #$id: ' + patch.keys.join(', ') + '. Sono stati aggiornati soltanto campi vuoti.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Oggetto #$id aggiornato: ' + patch.keys.join(', '))));
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
      if (term.isEmpty) {
        throw Exception('Inserisci un franchise o tema, ad esempio Batman, LEGO City o Saint Seiya.');
      }

      // La ricerca passa dal runtime autenticato e dalla RPC autorizzata.
      // Nessuna lettura diretta della tabella master_oggetti dal client.
      final all = <Map<String, dynamic>>[];
      const batchSize = 500;
      var offset = 0;
      while (true) {
        final response = await _ValoraRuntimeApi.call('consultation', {
          'session_id': _sessionId,
          'consultation_code': 'REPORT-COLLECTION-THEME',
          'arguments': {
            'cerca': term,
            'limite': batchSize,
            'offset': offset,
          },
        });
        final envelope = response['result'];
        final dynamic resultRows =
            envelope is Map ? envelope['risultato'] : envelope;
        if (resultRows is! List) {
          throw Exception('Il runtime non ha restituito un elenco valido per la ricerca per tema.');
        }
        final rows = resultRows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList();
        all.addAll(rows);
        if (rows.length < batchSize) break;
        offset += batchSize;
        if (offset >= 100000) {
          throw Exception('Il catalogo supera il limite di sicurezza della ricerca.');
        }
      }

      final seen = <String>{};
      final matched = <Map<String, dynamic>>[];
      for (final row in all) {
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
      : _isActiveListingsReport
        ? <String, dynamic>{'limite': pageSize, 'offset': 0}
        : widget.apiCode == 'OBJECT_MASTER'
          ? {'codice_oggetto': int.tryParse(_code.text.trim())}
          : {'cerca': _search.text.trim(), 'limite': pageSize, 'offset': 0};
    final response = (_isPeriodReport || _isActiveListingsReport)
      ? await _ValoraRuntimeApi.call('report', {
          'session_id': _sessionId,
          'report_code': _isActiveListingsReport ? 'ACTIVE_LISTINGS_REPORT' : _reportCodeForApi(widget.apiCode),
          'arguments': args,
        })
      : await _ValoraRuntimeApi.call('consultation', {
          'session_id': _sessionId, 'consultation_code': widget.apiCode, 'arguments': args,
        });
    final result = response['result'];
    dynamic data = result is Map ? (result['risultato'] ?? result) : result;

    // Carica le pagine successive automaticamente: l'elenco completo rimane
    // scorrevole e anche l'esportazione include tutti i record recuperati.
    if (widget.apiCode != 'OBJECT_MASTER') {
      final firstList = (_isPeriodReport || _isActiveListingsReport) && data is Map
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
          final nextResponse = (_isPeriodReport || _isActiveListingsReport)
              ? await _ValoraRuntimeApi.call('report', {
                  'session_id': _sessionId,
                  'report_code': _isActiveListingsReport ? 'ACTIVE_LISTINGS_REPORT' : _reportCodeForApi(widget.apiCode),
                  'arguments': nextArgs,
                })
              : await _ValoraRuntimeApi.call('consultation', {
                  'session_id': _sessionId,
                  'consultation_code': widget.apiCode,
                  'arguments': nextArgs,
                });
          final nextResult = nextResponse['result'];
          final nextData = nextResult is Map ? (nextResult['risultato'] ?? nextResult) : nextResult;
          final nextList = (_isPeriodReport || _isActiveListingsReport) && nextData is Map
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
        if ((_isPeriodReport || _isActiveListingsReport) && data is Map) {
          data = <String, dynamic>{...Map<String, dynamic>.from(data as Map), 'record': allRows};
        } else {
          data = allRows;
        }
      }
    }
    if (_isActiveListingsReport && data is Map) {
      final report = Map<String, dynamic>.from(data);
      final records = report['record'];
      final rawList = records is List ? records : <dynamic>[];

      // Integra le righe del report con le piattaforme associate a ogni
      // codice vendita. L'endpoint è autenticato e in sola lettura.
      final platformBySale = <String, String>{};
      try {
        final salesResponse = await _ValoraRuntimeApi.call(
          'open_sales_list',
          {'session_id': _sessionId},
        );
        final salesResult = salesResponse['result'];
        final sales = salesResult is Map ? salesResult['vendite'] : null;
        if (sales is List) {
          for (final sale in sales.whereType<Map>()) {
            final saleCode = (sale['codice_vendita_aperta'] ?? '').toString();
            final links = sale['piattaforme_associate'];
            final names = links is List
                ? links.whereType<Map>()
                    .map((link) => (link['nome_piattaforma'] ?? '').toString().trim())
                    .where((name) => name.isNotEmpty)
                    .toList()
                : <String>[];
            platformBySale[saleCode] = names.isEmpty ? 'Non indicata' : names.join(' · ');
          }
        }
      } catch (_) {
        // Il report resta consultabile anche se il recupero piattaforme fallisce.
      }

      final list = rawList.map((raw) {
        if (raw is! Map) return raw;
        final item = Map<String, dynamic>.from(raw);
        final saleCode = (item['codice_vendita_aperta'] ?? '').toString();
        item['piattaforme_report'] = platformBySale[saleCode] ?? 'Non indicata';
        return item;
      }).toList();

      setState(() {
        _rows = list;
        _availablePage = 0;
        _currentObject = null;
        _output = list.isEmpty
            ? 'Nessuna vendita attiva trovata.'
            : 'Vendite attive caricate: ${list.length}. Nessun filtro temporale applicato.';
      });
      if (list.isNotEmpty) await _loadActiveReportImages(list);
      return;
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
        _availablePage = 0;
        // Per questi report mostriamo un riepilogo leggibile, non il JSON grezzo.
        _output = summary;
        _currentObject = null;
      });
      if (_reportCanShowObjectImages && list.isNotEmpty) {
        await _loadActiveReportImages(list.take(_availablePageSize).toList());
      }
      return;
    }
    final list = data is List ? data : data == null ? <dynamic>[] : <dynamic>[data];
    setState(() {
      if (widget.apiCode == 'OBJECTS_AVAILABLE' || _isCollectionThemeReport || _usesStandardReportPresentation) _availablePage = 0;
      _rows = list;
      _output = list.isEmpty ? 'Nessun risultato.' : 'Risultati: ${list.length}.';
      _currentObject = widget.apiCode == 'OBJECT_MASTER' && list.isNotEmpty && list.first is Map
        ? Map<String, dynamic>.from(list.first as Map) : null;
    });
    if ((widget.apiCode == 'OBJECTS_AVAILABLE' || _isCollectionThemeReport || _reportCanShowObjectImages) && list.isNotEmpty) {
      await _loadActiveReportImages(list.take(_availablePageSize).toList());
    }
  }

  Future<void> _changeAvailablePage(int nextPage) async {
    final pageCount = (_rows.length / _availablePageSize).ceil();
    if (_loading || nextPage < 0 || nextPage >= pageCount || nextPage == _availablePage) return;
    setState(() => _availablePage = nextPage);
    final visible = _rows.skip(nextPage * _availablePageSize).take(_availablePageSize).toList();
    await _loadActiveReportImages(visible);
  }

  Future<void> _changePurchaseReportPage(int nextPage) async {
    if (widget.apiCode != 'REPORT-PURCHASES') return;
    await _changeAvailablePage(nextPage);
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

  Widget _pr11MetadataTab(Map<String, dynamic> object) {
    const sourceMetadataKeys = <String>{
      'fonte', 'url_fonte', 'fonte_dati', 'fonte_dati_prodotto',
      'fonte_dati_catalogo', 'fonte_dati_oggetto', 'fonte_catalogo',
      'fonte_oggetto', 'url_fonte_oggetto', 'url_fonte_catalogo',
      'url_fonte_prodotto', 'fonte_metadati', 'fonte_immagine',
      'url_fonte_immagine',
    };
    const baseKeys = [
      'produttore', 'anno_uscita', 'codice_prodotto', 'categoria', 'tema',
      'sezione', 'sottotema', 'nome_ufficiale', 'numero_pezzi',
      'numero_minifigure', 'dettagli_pezzi', 'contenuto_confezione',
      'modalita_altern', 'attributi_specifici', 'url_immagine',
      'stato_verifica', 'prezzo_lancio',
    ];
    String labelFor(String key) => key
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
    final values = <String, dynamic>{};
    for (final key in baseKeys) {
      if (object.containsKey(key) && object[key] != null) values[key] = object[key];
    }
    // Il record OBJECT_MASTER spesso contiene chiavi nulle o placeholder:
    // i valori del catalogo e del JSON specifico sono la fonte più completa.
    for (final entry in _pr11CategoryValues.entries) {
      final value = entry.value;
      if (!sourceMetadataKeys.contains(entry.key) &&
          value != null && value.toString().trim().isNotEmpty) {
        values[entry.key] = value;
      }
    }
    // Alcuni import hanno inserito i campi LEGO sotto attributi_specifici.
    // Espandere questi valori prima di mostrare "Da completare".
    final rawSpecific = _pr11CategoryValues['attributi_specifici'];
    if (rawSpecific is Map) {
      for (final entry in Map<String, dynamic>.from(rawSpecific).entries) {
        if (!sourceMetadataKeys.contains(entry.key) &&
            entry.value != null && entry.value.toString().trim().isNotEmpty) {
          values.putIfAbsent(entry.key, () => entry.value);
        }
      }
    }
    for (final definition in _pr11CategoryFieldDefinitions) {
      final key = definition['nome_campo']?.toString();
      if (key != null && key.isNotEmpty && !values.containsKey(key)) {
        values[key] = null;
      }
    }
    final categoryFields = _pr11CategoryFieldDefinitions
        .map((d) => d['nome_campo']?.toString() ?? '')
        .where((k) => k.isNotEmpty && !sourceMetadataKeys.contains(k))
        .toSet();
    // I campi specifici di altre categorie non devono finire nella sezione
    // "IDENTIFICAZIONE" come se fossero metadati generali (es. personaggi
    // secondari nei fumetti, contenuti musicali nei CD, parti intercambiabili
    // nelle Myth Cloth). Restano disponibili solo nella rispettiva categoria.
    const fieldsOwnedByOtherCategories = <String>{
      'fazione', 'gruppo_sottogruppo', 'tipo_opera_provenienza',
      'titolo_opera_provenienza', 'continuita_universo', 'classe_scala',
      'tipo_variante', 'genere_fumetto', 'numero_ristampa',
      'tipologia_ristampa', 'autore_storia', 'disegnatore',
      'personaggio_soggetto', 'personaggi_secondari', 'titolo_storia',
      'colorista', 'grade', 'mobile_suit_modello', 'serie_provenienza',
      'scala', 'tipo_kit', 'versione_modello', 'materiali_caratteristiche',
      'accessori_inclusi', 'materiale', 'altezza', 'opera_provenienza',
      'numero_collezione_edicola', 'confezione_presente', 'linea_serie',
      'articolazioni', 'numero_pop', 'licenza_universo', 'linea_funko',
      'variante_funko', 'formato_funko', 'modalita_catalogazione',
      'serie_completa', 'numero_componenti_serie', 'dettagli_componenti',
      'linea_prodotto', 'rango_personaggio', 'costellazione_simbolo',
      'tipo_armatura_cloth', 'versione_narrativa', 'versione_variante',
      'configurazione_armatura', 'parti_intercambiabili', 'artista_interprete',
      'titolo_album_contenuto', 'genere_musicale', 'tipo_edizione_musicale',
      'numero_supporti', 'contenuti_extra_musicali', 'titolo_concerto',
      'tour_concerto', 'data_registrazione', 'luogo_registrazione',
      'durata_minuti', 'formato_video',
    };
    final common = values.keys.where((k) =>
        !categoryFields.contains(k) &&
        !sourceMetadataKeys.contains(k) &&
        !fieldsOwnedByOtherCategories.contains(k)).toList();
    final category = _pr11CategoryFieldDefinitions
        .map((d) => d['nome_campo']?.toString() ?? '')
        .where((k) => k.isNotEmpty && !sourceMetadataKeys.contains(k))
        .toList();
    Widget field(String key, {Map<String, dynamic>? definition}) {
      final value = values[key];
      final required = definition?['obbligatorio'] == true;
      final applicability = definition?['applicabilita']?.toString();
      final shown = value == null || value.toString().trim().isEmpty
          ? 'Da completare'
          : value is Map || value is List
              ? const JsonEncoder.withIndent('  ').convert(value)
              : value.toString();
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${labelFor(key)}${required ? ' · OBBLIGATORIO' : ''}',
                style: TextStyle(color: sectionColor, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              SelectableText(shown),
              if (definition?['descrizione'] != null &&
                  definition!['descrizione'].toString().trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(definition['descrizione'].toString(),
                    style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 12)),
                ),
              if (applicability != null && applicability.isNotEmpty)
                Text('Applicabilità: $applicability',
                  style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
            ]),
          ),
        ),
      );
    }
    final definitionsByName = <String, Map<String, dynamic>>{
      for (final d in _pr11CategoryFieldDefinitions)
        if (d['nome_campo'] != null) d['nome_campo'].toString(): d,
    };
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('METADATI DEL PRODOTTO',
          style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(_pr11CategoryCode == null
            ? 'Categoria non assegnata: sono mostrati i metadati generali disponibili.'
            : 'Categoria: $_pr11CategoryCode · campi specifici caricati dal catalogo VALORA.',
          style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 12)),
        const SizedBox(height: 12),
        Text('IDENTIFICAZIONE', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...common.map((key) => field(key)),
        if (_pr11CategoryFieldDefinitions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('CAMPI SPECIFICI DELLA CATEGORIA',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...category.map((key) => field(key, definition: definitionsByName[key])),
        ] else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Non risultano definizioni di campi specifici per questa categoria.'),
          ),
      ],
    )));
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
    final purchasePrice = item['prezzo_acquisto'];
    final hasPurchasePrice = purchasePrice != null && purchasePrice.toString().trim().isNotEmpty;
    final rawValue = hasPurchasePrice
        ? purchasePrice
        : (item['valore_oggetto'] ?? item['valore'] ?? item['valore_stimato']);
    final currency = (hasPurchasePrice
        ? (item['valuta_acquisto'] ?? 'EUR')
        : (item['valuta_valore'] ?? 'EUR')).toString().toUpperCase();
    final valueLabel = hasPurchasePrice ? 'Prezzo di acquisto' : 'Valore registrato';
    final value = rawValue == null || rawValue.toString().trim().isEmpty
        ? 'Non indicato'
        : _formatPr11Currency(rawValue, currency);
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
          _pr11SummaryValue(valueLabel, value),
        ]),
      ),
    );
  }

  String _formatPr11Currency(dynamic raw, String currency) {
    final amount = raw is num ? raw : num.tryParse(raw.toString().trim().replaceAll(',', '.'));
    if (amount == null) return raw.toString();
    final fixed = amount.abs().toStringAsFixed(2).split('.');
    final integer = fixed[0];
    final grouped = integer.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    final sign = amount < 0 ? '-' : '';
    final symbol = currency == 'EUR' ? '€' : currency == 'USD' ? r'$' : currency == 'GBP' ? '£' : currency == 'JPY' ? '¥' : currency;
    final formatted = '$sign$grouped,${fixed[1]}';
    return currency == 'EUR' ? '$formatted €' : '$symbol $formatted';
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

  Future<void> _openObjectForEdit() async {
    final id = _loadedObjectId;
    if (id == null || _currentObject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona prima una scheda oggetto valida.')),
      );
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ObjectRuntimePage(
        title: 'Modifica oggetto',
        apiCode: 'PR-02',
        initialObjectCode: id,
      ),
    ));
    if (mounted) await _run(_loadObject);
  }

  Future<void> _putObjectForSale() async {
    final id = _loadedObjectId;
    final object = _currentObject;
    if (id == null || object == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona prima una scheda oggetto valida.')),
      );
      return;
    }
    final state = (object['stato'] ?? '').toString().trim().toUpperCase();
    if (state != 'DISPONIBILE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile mettere in vendita: lo stato attuale è ${state.isEmpty ? 'non indicato' : state}.')),
      );
      return;
    }
    final currentDestination = (object['destinazione'] ?? '').toString().trim().toUpperCase();
    final needsDestinationChange = currentDestination != 'RIVENDITA';
    if (needsDestinationChange) {
      final accepted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Metti in vendita'),
          content: Text(
            'L’oggetto “${(object['descrizione_oggetto'] ?? object['descrizione'] ?? 'Oggetto #$id').toString()}” '
            'ha destinazione ${currentDestination.isEmpty ? 'non indicata' : currentDestination}. '
            'Vuoi impostare RIVENDITA e proseguire alla maschera NUOVA VENDITA?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ANNULLA')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('CONFERMA')),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }

    try {
      if (needsDestinationChange) {
        await _acquireLock();
        final payload = <String, dynamic>{
          'oggetti': [{'codice_oggetto': id, 'destinazione': 'RIVENDITA'}],
          'dati_confermati': true,
          'altra_operazione': false,
          'conferma_finale': true,
        };
        final preview = await _ValoraRuntimeApi.procedure(
          'PR-02', 'preview', payload, sessionId: _sessionId);
        if (preview['errore'] != null) {
          throw Exception(preview['errore'].toString());
        }
        await _ValoraRuntimeApi.procedure(
          'PR-02', 'review', payload, sessionId: _sessionId);
        final saved = await _ValoraRuntimeApi.procedure(
          'PR-02', 'save', payload, sessionId: _sessionId, requestId: _uuid.v4());
        if (saved['scrittura_eseguita'] != true) {
          throw Exception('Il database non ha confermato il cambio di destinazione.');
        }
        if (saved['blocco_rilasciato_automaticamente'] != true) {
          throw Exception('Il cambio è stato segnalato come salvato, ma il rilascio del blocco non è stato confermato.');
        }
        if (mounted) setState(() => _lockHeld = false);
      }

      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => NewSalePage(initialObjectCode: id),
      ));
      if (mounted) await _run(_loadObject);
    } catch (e) {
      if (_lockHeld) {
        try { await _releaseLock(); } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operazione non completata: $e'), duration: const Duration(seconds: 6)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apiCode == 'PR-01') return _buildPr01Page();
    if (widget.apiCode == 'PR-02') return _buildPr02Page();
    final code = widget.apiCode;
    final isAvailableList = code == 'OBJECTS_AVAILABLE';
    final availablePageCount = (_rows.length / _availablePageSize).ceil();
    final useStandardReportPaging = _usesStandardReportPresentation;
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
                                          _valoraImageProxyUrl(imageUrl),
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
                      const SizedBox(height: 12),
                      Text('RECORD INCOMPLETI · PAGINA ${_pr12QueuePage + 1} DI ${(_pr12IncompleteRecords.length / 10).ceil()}', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Mostro 10 record alla volta. Puoi verificare un singolo oggetto oppure selezionarne fino a 10 per una ricerca combinata.', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || _pr12QueuePage == 0 ? null : () => setState(() { _pr12QueuePage--; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(ValoraI18n.tr('PRECEDENTE')),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || (_pr12QueuePage + 1) * 10 >= _pr12IncompleteRecords.length ? null : () => setState(() { _pr12QueuePage++; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(ValoraI18n.tr('SUCCESSIVA')),
                        )),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: Text('Selezionati: ${_pr12SelectedRecordIds.length}/10', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold))),
                        TextButton(onPressed: _pr12SelectedRecordIds.isEmpty ? null : () => setState(() => _pr12SelectedRecordIds.clear()), child: const Text('ANNULLA SELEZIONE')),
                      ]),
                      SizedBox(width: double.infinity, child: FilledButton.icon(
                        onPressed: _pr12AiBatchRunning || _pr12SelectedRecordIds.isEmpty ? null : () {
                          final selected = _pr12IncompleteRecords.where((row) => _pr12SelectedRecordIds.contains((row['codice_oggetto'] ?? '').toString())).take(10).toList();
                          _runPr12AiBatch(selectedRecords: selected);
                        },
                        icon: const Icon(Icons.travel_explore),
                        label: Text('VERIFICA ${_pr12SelectedRecordIds.length} SELEZIONATI'),
                      )),
                      const SizedBox(height: 8),
                      ..._pr12IncompleteRecords.skip(_pr12QueuePage * 10).take(10).map((row) {
                        final id = (row['codice_oggetto'] ?? '').toString();
                        final missing = <String>[
                          if ((row['produttore'] ?? '').toString().trim().isEmpty) 'produttore',
                          if (row['anno_uscita'] == null) 'anno',
                          if ((row['codice_prodotto'] ?? '').toString().trim().isEmpty) 'codice prodotto',
                        ];
                        final selected = _pr12SelectedRecordIds.contains(id);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Checkbox(
                                value: selected,
                                activeColor: sectionColor,
                                onChanged: _pr12AiBatchRunning ? null : (value) => setState(() {
                                  if (value == true) {
                                    if (_pr12SelectedRecordIds.length < 10) {
                                      _pr12SelectedRecordIds.add(id);
                                      _pr12AiBatchStatus = 'Selezionato il record $id.';
                                    } else {
                                      _pr12AiBatchStatus = 'Puoi selezionare al massimo 10 record.';
                                    }
                                  } else {
                                    _pr12SelectedRecordIds.remove(id);
                                  }
                                }),
                              ),
                              Expanded(child: Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 8),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('#$id · ${row['descrizione_oggetto'] ?? 'Senza descrizione'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('Mancano: ${missing.join(', ')}', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
                                ]),
                              )),
                              IconButton(
                                tooltip: ValoraI18n.tr('Verifica solo questo record'),
                                onPressed: _pr12AiBatchRunning ? null : () => _runPr12AiBatch(singleRecord: row),
                                icon: const Icon(Icons.search),
                              ),
                            ]),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || _pr12QueuePage == 0 ? null : () => setState(() { _pr12QueuePage--; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(ValoraI18n.tr('INDIETRO')),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(
                          onPressed: _pr12AiBatchRunning || (_pr12QueuePage + 1) * 10 >= _pr12IncompleteRecords.length ? null : () => setState(() { _pr12QueuePage++; _pr12SelectedRecordIds.clear(); }),
                          icon: const Icon(Icons.arrow_forward),
                          label: Text(ValoraI18n.tr('AVANTI')),
                        )),
                      ]),
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
        if (_isWrite && widget.apiCode == 'PR-03')
          Pr03ClosureSection(
            searchController: _search,
            notesController: _notes,
            pendingClosures: _pr03PendingClosures,
            selectedObject: _currentObject,
            hasSelectedObject: _currentObject != null,
            closeReason: _closeReason,
            onCloseReasonChanged: (value) => setState(() => _closeReason = value),
            loading: _loading,
            sectionColor: sectionColor,
            onSearch: () => _run(_searchPr02Objects),
            onConfirm: () => _run(_confirmPr03Closure),
          ),
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
        if ((!_isWrite || code == 'PR-08' || code == 'PR-07' || code == 'PR-09') && !isMaster && !isHistory && !isAvailableList && !_isPeriodReport && !_isActiveListingsReport)
          _field(_search, 'Cerca'),
        if (_isWrite && code == 'PR-03') ...[
          const SizedBox.shrink(),
        ] else if (_isWrite && code != 'PR-01') ...[
          WriteProcedureActionPanel(
            loading: _loading,
            hasPreview: _lastResult != null,
            dataConfirmed: _dataConfirmed,
            finalReady: _finalReady,
            lockHeld: _lockHeld,
            onPreview: () => _run(_preview),
            onConfirm: () => _run(_confirmData),
            onSave: () => _run(_save),
            onReleaseLock: () => _run(_releaseLock),
          ),
        ] else if (!isMaster && !isAvailableList && !_isActiveListingsReport)
          FilledButton.icon(
            onPressed: _loading ? null : () => _run(isHistory ? _searchPr02Objects : _consult),
            icon: const Icon(Icons.search),
            label: Text(_loading ? 'RICERCA...' : isHistory ? 'VISUALIZZA STORICO OGGETTO' : 'ESEGUI CONSULTAZIONE'),
          ),
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
                  for (final tab in const [
                    (label: 'OGGETTO', icon: Icons.inventory_2_outlined),
                    (label: 'METADATI', icon: Icons.fact_check_outlined),
                    (label: 'DATI TECNICI', icon: Icons.analytics_outlined),
                  ]) ...[
                    if (tab.label != 'OGGETTO') const SizedBox(width: 4),
                    Expanded(child: FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 14),
                        backgroundColor: _pr11MasterTabIndex == (tab.label == 'OGGETTO' ? 0 : tab.label == 'METADATI' ? 1 : 2)
                            ? sectionColor : ValoraAppearance.instance.card,
                        foregroundColor: _pr11MasterTabIndex == (tab.label == 'OGGETTO' ? 0 : tab.label == 'METADATI' ? 1 : 2)
                            ? Colors.black : ValoraAppearance.instance.textPrimary,
                      ),
                      onPressed: () => setState(() => _pr11MasterTabIndex = tab.label == 'OGGETTO' ? 0 : tab.label == 'METADATI' ? 1 : 2),
                      child: FittedBox(fit: BoxFit.scaleDown, child: Text(tab.label, maxLines: 1, softWrap: false)),
                    )),
                  ],
                ]),
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
                    Text('DATI DELL’OGGETTO',
                      style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _masterDetails(_currentObject!),
                  ]),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _openObjectForEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('MODIFICA OGGETTO', textAlign: TextAlign.center),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _putObjectForSale,
                      icon: const Icon(Icons.sell_outlined),
                      label: const Text('METTI IN VENDITA', textAlign: TextAlign.center),
                      style: FilledButton.styleFrom(
                        backgroundColor: ValoraAppearance.instance.colorFor('VENDITE'),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_pr11MasterTabIndex == 1)
              _pr11MetadataTab(_currentObject!)
            else
              _pr11TechnicalDetails(_currentObject!),
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
                    }.contains(e.key) && !const {
                      'fonte', 'fonte_dati', 'fonte_dati_prodotto',
                      'fonte_dati_catalogo', 'fonte_dati_oggetto',
                      'fonte_catalogo', 'fonte_oggetto', 'url_fonte',
                      'url_fonte_oggetto', 'url_fonte_catalogo',
                      'url_fonte_prodotto', 'fonte_metadati',
                      'fonte_immagine', 'url_fonte_immagine',
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
          ...((isAvailableList || useStandardReportPaging)
              ? _rows.skip(_availablePage * _availablePageSize).take(_availablePageSize)
              : _rows).map((r) {
            if (r is! Map) return Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(r.toString())));
            final item = Map<String, dynamic>.from(r);
            if (isHistory) return _historyCard(item);
            if (_isPeriodReport) {
              final dateValue = item['data_vendita'] ?? item['data_acquisto'] ?? item['data'] ?? item['data_inizio_vendita'] ?? 'Data non indicata';
              final description = item['descrizione_oggetto'] ?? item['descrizione'] ?? item['tipologia'] ?? item['tipo_movimento'] ?? (widget.apiCode == 'REPORT-PURCHASES' ? 'Acquisto #${item['codice_acquisto'] ?? ''}' : 'Operazione');
              final amount = item['importo_vendita'] ?? item['importo_totale_acquisto'] ?? item['importo'] ?? item['prezzo_di_vendita'];
              final imageUrl = (item['url_immagine_catalogo'] ?? item['url_immagine'] ?? '').toString().trim();
              final objectId = int.tryParse((item['codice_oggetto'] ?? item['id_oggetto'] ?? '').toString())
                  ?? _reportImageObjectIdsByDescription[(item['descrizione_oggetto'] ?? item['descrizione'] ?? item['nome_oggetto'] ?? item['titolo'] ?? '').toString().trim().toLowerCase()];
              return ReportOperationCard(
                sectionColor: sectionColor,
                showImage: _reportCanShowObjectImages,
                imageUrl: imageUrl,
                title: description.toString(),
                subtitle: '$dateValue · ${item['codice_vendita'] ?? item['codice_acquisto'] ?? item['codice_movimento'] ?? ''}',
                trailingText: amount == null ? null : '${(double.tryParse(amount.toString()) ?? 0).toStringAsFixed(2).replaceAll('.', ',')} ${item['valuta'] ?? 'EUR'}',
                onTap: widget.apiCode == 'REPORT-PURCHASES'
                    ? () => _showPurchaseReportDetail(item)
                    : objectId != null && objectId > 0 && widget.apiCode != 'REPORT-CASH'
                    ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ObjectRuntimePage(
                        title: 'Scheda oggetto', apiCode: 'OBJECT_MASTER', initialObjectCode: objectId,
                      )))
                    : () => showDialog<void>(context: context, builder: (context) => AlertDialog(
                        title: const Text('Dettaglio operazione'),
                        content: SingleChildScrollView(child: SelectableText(_pretty(item))),
                        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(ValoraI18n.tr('CHIUDI')))],
                      )),
              );
            }
            return _objectCard(item, availableStyle: isAvailableList || _isCollectionThemeReport || _isActiveListingsReport, activeListing: _isActiveListingsReport, onTap: (isAvailableList || _isCollectionThemeReport || _isActiveListingsReport)
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ObjectRuntimePage(
                      title: 'Visualizza scheda',
                      apiCode: 'OBJECT_MASTER',
                      initialObjectCode: int.tryParse(item['codice_oggetto']?.toString() ?? item['id']?.toString() ?? ''),
                    )
                  )).then((_) {})
              : null);
          }),
          if ((isAvailableList || useStandardReportPaging) && availablePageCount > 1) ...[
            const SizedBox(height: 8),
            ReportPaginationControls(
              currentPage: _availablePage,
              pageSize: _availablePageSize,
              totalItems: _rows.length,
              pageCount: availablePageCount,
              textColor: ValoraAppearance.instance.textSecondary,
              onPrevious: _loading || _availablePage == 0
                  ? null
                  : () => _changeAvailablePage(_availablePage - 1),
              onNext: _loading || _availablePage + 1 >= availablePageCount
                  ? null
                  : () => _changeAvailablePage(_availablePage + 1),
            ),
          ],
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
                  final kind = '${row['tipologia'] ?? row['tipo'] ?? row['tipo_movimento'] ?? row['categoria'] ?? ''}'.toLowerCase();
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
              return ReportSummaryPanel(
                sectionColor: sectionColor,
                padding: const EdgeInsets.all(14),
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
              final label = widget.apiCode == 'REPORT-SALES' || widget.apiCode == 'REPORT-SALES-ACTIVE'
                  ? 'TOTALE VENDITE'
                  : widget.apiCode == 'REPORT-PURCHASES'
                      ? 'TOTALE ACQUISTI'
                      : 'TOTALE OPERAZIONI';
              final money = total.toStringAsFixed(2).replaceAll('.', ',');
              return ReportSummaryPanel(
                sectionColor: sectionColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        ] else if (isAvailableList && !_loading && _rows.isEmpty) ...[
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
              const Text('Nessun oggetto disponibile trovato',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('La consultazione automatica non ha restituito record.',
                style: TextStyle(color: ValoraAppearance.instance.textSecondary), textAlign: TextAlign.center),
            ]),
          ),
        ],
        if (code != 'PR-01' && code != 'PR-02' && code != 'PR-03' && !isMaster && !isAvailableList && !isHistory && !_isActiveListingsReport && code != 'REPORT-CASH' && code != 'REPORT-PURCHASES' && code != 'REPORT-SALES' && code != 'REPORT-SALES-ACTIVE') ...[
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
  }
}



class _PurchaseItemDraft {
  final description = TextEditingController();
  final price = TextEditingController();
  final notes = TextEditingController();
  Uint8List? photoBytes;
  String? photoName;
  String? photoUrl;
  String? metadataProducer;
  String? metadataCode;
  int? metadataYear;
  String? metadataSourceUrl;
  String photoStatus = 'Nessuna foto selezionata.';
  String destination = 'COLLEZIONE';
  String? collectionCategoryCode;
  String condition = 'USATO';
  String completeness = 'COMPLETO';
  double? get amount {
    var s = price.text.trim().replaceAll('€', '').replaceAll(' ', '');
    if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }
  Map<String, dynamic> json() => {
    'descrizione': description.text.trim(), 'valore_acquisto': amount,
    if (notes.text.trim().isNotEmpty) 'note': notes.text.trim(),
    'destinazione': destination, 'condizione': condition,
    if (destination == 'COLLEZIONE' && collectionCategoryCode != null) 'codice_categoria_collezione': collectionCategoryCode,
    'completezza': completeness, 'quantita': 1,
    if (metadataProducer != null) 'produttore': metadataProducer,
    if (metadataCode != null) 'codice_prodotto': metadataCode,
    if (metadataYear != null) 'anno_uscita': metadataYear,
    if (metadataSourceUrl != null) 'fonte_dati_prodotto': metadataSourceUrl,
    if (metadataProducer != null || metadataCode != null || metadataYear != null)
      'stato_verifica_dati': 'DA_VERIFICARE',
    if (photoUrl != null) 'url_immagine_catalogo': photoUrl,
  };
  void dispose() { description.dispose(); price.dispose(); notes.dispose(); }
}

/// PR-04: una transazione sola; un record oggetto distinto per ogni elemento.

class NewPurchasePage extends StatefulWidget {
  const NewPurchasePage({super.key, this.initialMetadata, this.suggestedMarketValue, this.valoraMode = false});
  final Map<String, dynamic>? initialMetadata;
  final double? suggestedMarketValue;
  final bool valoraMode;
  @override
  State<NewPurchasePage> createState() => _NewPurchasePageState();
}

class _NewPurchasePageState extends State<NewPurchasePage> {
  int _step = 0;
  String _type = 'SINGOLO';
  final _count = TextEditingController(text: '2');
  DateTime _date = DateTime.now();
  final List<_PurchaseItemDraft> _items = [_PurchaseItemDraft()];
  // Gli acquisti confermati restano in coda fino al salvataggio finale unico.
  final List<Map<String, dynamic>> _pendingPurchases = [];
  List<Map<String, dynamic>> _collectionCategories = [];
  bool _categoriesLoading = false;
  final String _session = _uuid.v4();
  bool _busy = false, _locked = false, _dataConfirmed = false;
  Map<String, dynamic>? _preview;
  String _status = 'Bozza locale: nessun acquisto registrato.';

  @override
  void initState() {
    super.initState();
    final metadata = widget.initialMetadata;
    if (metadata != null) {
      final item = _items.first;
      item.description.text = (metadata['descrizione'] ?? '').toString();
      item.metadataProducer = _nonEmptyMetadata(metadata['produttore']);
      item.metadataCode = _nonEmptyMetadata(metadata['codice_prodotto']);
      item.metadataYear = metadata['anno_uscita'] is num
          ? (metadata['anno_uscita'] as num).toInt()
          : int.tryParse((metadata['anno_uscita'] ?? '').toString());
      item.metadataSourceUrl = _nonEmptyMetadata(metadata['fonte_dati_prodotto']);
      final imageUrl = _nonEmptyMetadata(metadata['url_immagine_catalogo']);
      item.photoUrl = imageUrl != null &&
          (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'))
          ? imageUrl : null;
      item.photoStatus = item.photoUrl == null
          ? 'Metadati VALORA precompilati. Foto utente non importata come immagine definitiva.'
          : 'Metadati e immagine catalogo selezionata da fonte online. Verifica prima del salvataggio.';
      // Il costo resta intenzionalmente vuoto: il valore di mercato non è un costo d’acquisto.
    }
    _loadCollectionCategories();
  }

  String? _nonEmptyMetadata(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  Future<void> _loadCollectionCategories() async {
    _categoriesLoading = true;
    try {
      final rows = await Supabase.instance.client.schema('collection').from('master_categorie_collezione')
          .select('codice_categoria, descrizione, ordine_menu, visibile').eq('visibile', true)
          .order('ordine_menu').order('descrizione');
      if (!mounted) return;
      setState(() => _collectionCategories = (rows as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) { if (mounted) setState(() => _status = 'Errore caricamento categorie: $e'); }
    finally { _categoriesLoading = false; }
  }

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
        context: context,
        barrierDismissible: false,
        builder: (_) => Pr04RecognitionDialog(
          photoBytes: bytes,
          clues: clues,
          results: results,
          imageCandidates: imageCandidates,
        ),
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

  Widget _itemEditor(int n) => Pr04ItemEditor(
    key: ValueKey('pr04-item-' + n.toString()),
    index: n,
    item: _items[n],
    busy: _busy,
    categories: _collectionCategories,
    categoriesLoading: _categoriesLoading,
    onChanged: () => setState(_invalidate),
    onPhoto: () => _photoAndRecognize(_items[n]),
    suggestedMarketValue: widget.suggestedMarketValue,
  );

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, color: bold ? goldColor : null))),
      const SizedBox(width: 8), Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: bold ? goldColor : null))),
    ]));

  Widget _valoraContent() {
    final item = _items.first;
    final marketValue = widget.suggestedMarketValue;
    if (_preview != null) {
      return Pr04ValoraPurchaseReview(
        description: item.description.text.trim(),
        dateLabel: _dateLabel(_date),
        purchaseCost: item.amount ?? 0,
        marketValue: marketValue,
        preview: _preview!,
        busy: _busy,
        onEdit: () => setState(_invalidate),
        onConfirm: () {
          setState(() => _dataConfirmed = true);
          _save();
        },
      );
    }
    return Pr04ValoraPurchaseForm(
      itemEditor: _itemEditor(0),
      metadataDetails: [
        if ((item.metadataProducer ?? '').trim().isNotEmpty) 'Produttore/Editore: ${item.metadataProducer}',
        if ((item.metadataCode ?? '').trim().isNotEmpty) 'Codice prodotto: ${item.metadataCode}',
        if (item.metadataYear != null) 'Anno: ${item.metadataYear}',
        if ((item.metadataSourceUrl ?? '').trim().isNotEmpty) 'Fonte metadati: ${item.metadataSourceUrl}',
      ],
      dateLabel: _dateLabel(_date),
      busy: _busy,
      status: _status,
      onPickDate: _pickDate,
      onPreview: _runPreview,
    );
  }

  Widget _content() {
    if (widget.valoraMode) return _valoraContent();
    return Pr04PurchaseStepContent(
    step: _step,
    type: _type,
    dateLabel: _dateLabel(_date),
    countController: _count,
    items: _items,
    total: _total,
    pendingPurchaseCount: _pendingPurchases.length,
    pendingTotal: _pendingTotal,
    busy: _busy,
    itemEditor: _itemEditor,
    onSelectSingle: () => setState(() { _type = 'SINGOLO'; _resize(1); _count.text = '1'; }),
    onSelectLot: () => setState(() { _type = 'LOTTO'; if (_items.length < 2) _resize(2); _count.text = _items.length.toString(); }),
    onContinue: () => setState(() => _step = 1),
    onBackToType: () => setState(() => _step = 0),
    onBackToDetails: () => setState(() => _step = 1),
    onPickDate: _pickDate,
    onContinueToItems: () {
      if (_type == 'LOTTO') {
        final n = int.tryParse(_count.text.trim());
        if (n == null || n < 2 || n > 500) { _notice('Inserisci un numero compreso fra 2 e 500.'); return; }
        _resize(n);
      } else {
        _resize(1);
      }
      setState(() => _step = 2);
    },
    onContinueToSummary: () {
      if (!_valid()) return;
      setState(() => _step = 3);
    },
    onRunPreview: _runPreview,
    onQueueAnother: _queueCurrentAndStartNext,
    onSaveAndExit: () {
      setState(() { _dataConfirmed = true; });
      _save();
    },
    onEditObjects: () => setState(() => _step = 2),
    onEditData: () => setState(() { _step = 2; _invalidate(); }),
  );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.valoraMode) {
      return Pr04ValoraPurchasePageFrame(busy: _busy, content: _content());
    }
    return Pr04PurchasePageFrame(
      step: _step,
      busy: _busy,
      color: ValoraAppearance.instance.colorFor('ACQUISTI'),
      status: _status,
      content: _content(),
    );
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

  Widget _line(String a,String b)=>Padding(padding:const EdgeInsets.symmetric(vertical:4),child:Row(children:[Expanded(child:Text(a)),Flexible(child:Text(b,textAlign:TextAlign.end))]));
  @override
  Widget build(BuildContext context) => Pr05EditPurchaseForm(
    queryController: _query,
    dateController: _date,
    totalController: _total,
    descriptionController: _description,
    busy: _busy,
    confirmed: _confirmed,
    status: _status,
    found: _found,
    purchase: _purchase,
    items: _items,
    lastResult: _last,
    purchaseCode: _purchase == null ? '' : _code(_purchase!),
    purchaseName: _purchase == null ? '' : _name(_purchase!),
    foundSummary: (row) => 'Codice: ${_code(row)} · Totale: ${((_money(_totalValue(row)) ?? 0).toStringAsFixed(2))} €',
    itemSummary: (item) => (
      (item['descrizione_oggetto'] ?? item['descrizione'] ?? item['nome'] ?? 'Oggetto collegato').toString(),
      'Codice oggetto: ${(item['codice_oggetto'] ?? item['object_code'] ?? item['id'] ?? 'non disponibile').toString()}',
      '€ ${((_money(item['importo'] ?? item['prezzo_acquisto'] ?? item['valore']) ?? 0).toStringAsFixed(2))}'
    ),
    allocated: _allocated,
    currentTotal: _money(_total.text) ?? 0,
    onSearch: _search,
    onLoad: _load,
    onDateChanged: () => setState(() { _last = null; _confirmed = false; }),
    onTotalChanged: () => setState(() { _last = null; _confirmed = false; }),
    onPreview: _preview,
    onSave: _save,
    onConfirmedChanged: (value) => setState(() => _confirmed = value),
  );

}
