import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';

const supabaseUrl = 'https://eeiekkflpnkummxtvljy.supabase.co';
const publishableKey = 'sb_publishable_a2TYRwP1XCAqgE5mXh8yZw_vIZiaFNz';
const runtimeUrl = '$supabaseUrl/functions/v1/collection-procedure-runtime-test';
const uuid = Uuid();

const procedureNames = <String, String>{
  'PR-01': 'NUOVO OGGETTO',
  'PR-02': 'MODIFICA OGGETTO',
  'PR-03': 'CHIUDI OGGETTO',
  'PR-04': 'NUOVO ACQUISTO',
  'PR-05': 'MODIFICA ACQUISTO',
  'PR-06': 'NUOVA VENDITA',
  'PR-07': 'MODIFICA VENDITA',
  'PR-08': 'CHIUDI VENDITA',
  'PR-09': 'ANNULLA VENDITA',
  'PR-10': 'SCAMBIO',
  'GESTIONE PIATTAFORME': 'GESTIONE PIATTAFORME',
};

const reportRuntimeCodes = <String, String>{
  'REPORT-ACTIVE-LISTINGS': 'ACTIVE_LISTINGS_REPORT',
  'REPORT-CASH': 'CASH_MOVEMENTS_REPORT',
  'REPORT-HISTORY': 'HISTORY_REPORT',
  'REPORT-INVENTORY': 'INVENTORY_SUMMARY_REPORT',
  'REPORT-PURCHASES': 'PURCHASES_REPORT',
  'REPORT-SALES': 'SALES_REPORT',
};

Map<String, dynamic> reportArgumentsTemplate(String code) => switch (code) {
  'REPORT-ACTIVE-LISTINGS' => {'limite': 100, 'offset': 0},
  'REPORT-CASH' => {'data_da': '2026-01-01', 'data_a': '2026-12-31', 'limite': 100, 'offset': 0},
  'REPORT-HISTORY' => {'anno': 2026, 'mese': 10, 'limite': 100, 'offset': 0},
  'REPORT-INVENTORY' => {'stato': 'DISPONIBILE', 'limite': 100, 'offset': 0, 'destinazione': 'COLLEZIONE'},
  'REPORT-PURCHASES' => {'anno': 2026, 'mese': 10, 'data_da': '2026-10-01', 'data_a': '2026-10-31', 'limite': 100, 'offset': 0},
  'REPORT-SALES' => {'anno': 2026, 'mese': 10, 'data_da': '2026-10-01', 'data_a': '2026-10-31', 'limite': 100, 'offset': 0},
  _ => <String, dynamic>{'limite': 100, 'offset': 0},
};

const readActions = <String, String>{
  'COMMAND_RESOLVE': 'RISOLVI COMANDO ESATTO',
  'OBJECTS_EDITABLE': 'ELENCA OGGETTI MODIFICABILI',
  'OBJECTS_AVAILABLE': 'ELENCA OGGETTI DISPONIBILI',
  'OBJECT_MASTER': 'LEGGI SCHEDA OGGETTO',
  'OBJECTS_SELLABLE': 'ELENCA OGGETTI VENDIBILI',
  'OBJECT_SALE_SHEET': 'LEGGI SCHEDA VENDITA',
  'TABLE_STRUCTURE': 'MOSTRA STRUTTURA',
  'TABLE_VALUES': 'MOSTRA VALORI',
  'EXPLORE_RECORDS': 'ESPLORA RECORD',
  'MARKET_VALUATION_PREPARE': 'PREPARA VALUTAZIONE DI MERCATO',
  'SEARCH_SOURCES': 'CERCA FONTI',
  'FRANCHISE_SOURCES': 'CERCA FONTI FRANCHISE',
};

Map<String, dynamic> templateFor(String code) => switch (code) {
  'PR-01' => {'oggetti': [{'descrizione': '', 'condizione': 'USATO', 'completezza': 'COMPLETO', 'destinazione': 'COLLEZIONE', 'quantita': 1}]},
  'PR-02' => {'oggetti': [{'codice_oggetto': null}]},
  'PR-03' => {'oggetti': [{'codice_oggetto': null, 'motivo_chiusura': 'SMARRITO'}]},
  'PR-04' => {'operazioni': [{'data_acquisto': '', 'importo_totale': 0, 'valuta': 'EUR', 'oggetti': [{'descrizione': '', 'valore_acquisto': 0, 'condizione': 'USATO', 'completezza': 'COMPLETO', 'destinazione': 'COLLEZIONE', 'quantita': 1}]}]},
  'PR-05' => {'operazioni': [{'codice_acquisto': null, 'data_acquisto': '', 'importo_totale': null}]},
  'PR-06' => {'operazioni': [{'codice_oggetto': null, 'prezzo_di_vendita': 0, 'codici_piattaforme': [1]}]},
  'PR-07' => {'operazioni': [{'codice_vendita_aperta': null, 'modifica_prezzo': true, 'prezzo_di_vendita': 0}]},
  'PR-08' => {'operazioni': [{'codice_vendita_aperta': null, 'esito': 'VENDITA EFFETTIVA', 'data_vendita': '', 'importo_vendita': 0, 'codice_piattaforma': 1}]},
  'PR-09' => {'operazioni': [{'codice_vendita': null, 'rimetti_in_vendita': false}]},
  'PR-10' => {'operazioni': [{'codice_vendita_aperta': null, 'data_scambio': '', 'nuovo_oggetto': {'descrizione': '', 'condizione': 'USATO', 'completezza': 'COMPLETO', 'destinazione': 'COLLEZIONE', 'quantita': 1}}]},
  'GESTIONE PIATTAFORME' => {'operazioni': [{'azione': 'INSERISCI', 'nome': ''}]},
  'PR04-ACCORPA-COLLEZ' => {'operazioni': [{'codici_oggetti': [], 'descrizione_finale': '', 'condizione_finale': 'USATO', 'completezza_finale': 'COMPLETO', 'destinazione_finale': 'COLLEZIONE', 'metodo_valore': 'MANUALE', 'valore_manual': 0}]},
  'CMD-DATA-OUT' => {'codice_oggetto': null, 'azione': 'DATA_DI_USCITA', 'mercato': 'ITALIA', 'data_prima_commercializzazione': '', 'fonti': []},
  'CMD-PRICE-OUT' => {'codice_oggetto': null, 'azione': 'PREZZO_DI_USCITA', 'mercato': 'ITALIA', 'prezzo_lancio': null, 'valuta_prezzo_lancio': 'EUR', 'fonti': []},
  'CMD-DATE-PRICE-OUT' => {'codice_oggetto': null, 'azione': 'DATA_E_PREZZO_DI_USCITA', 'mercato': 'ITALIA', 'data_prima_commercializzazione': '', 'prezzo_lancio': null, 'valuta_prezzo_lancio': 'EUR', 'fonti': []},
  _ => <String, dynamic>{},
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
  }
  await LocalStore.instance.open();
  await Supabase.initialize(url: supabaseUrl, anonKey: publishableKey);
  runApp(const CollectionApp());
}

class LocalStore {
  LocalStore._();
  static final instance = LocalStore._();
  Database? _db;
  String? sessionId;

  Future<void> open() async {
    final dir = await getApplicationSupportDirectory();
    await Directory(dir.path).create(recursive: true);
    final path = p.join(dir.path, 'collection_by_valora_test.sqlite');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''CREATE TABLE app_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)''');
      await db.execute('''CREATE TABLE operation_queue (
        request_id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        procedure_code TEXT NOT NULL,
        operation_kind TEXT NOT NULL DEFAULT 'procedure',
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        last_error TEXT
      )''');
      await db.execute('CREATE INDEX idx_operation_queue_fifo ON operation_queue(status, created_at)');
    }, onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 1) {
        await db.execute('''CREATE TABLE IF NOT EXISTS app_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE IF NOT EXISTS operation_queue (
          request_id TEXT PRIMARY KEY, session_id TEXT NOT NULL, procedure_code TEXT NOT NULL,
          operation_kind TEXT NOT NULL DEFAULT 'procedure', payload TEXT NOT NULL,
          created_at TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'PENDING', last_error TEXT)''');
      }
    });
    final rows = await _db!.query('app_meta', where: 'key=?', whereArgs: ['session_id'], limit: 1);
    if (rows.isEmpty) {
      sessionId = uuid.v4();
      await _db!.insert('app_meta', {'key': 'session_id', 'value': sessionId});
    } else {
      sessionId = rows.first['value'] as String;
    }
  }

  Database get db => _db!;
  Future<List<Map<String, Object?>>> queue() => db.query('operation_queue', orderBy: 'created_at ASC');
  Future<int> queueCount() async => Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM operation_queue')) ?? 0;

  Future<void> enqueue({required String requestId, required String procedure, required String kind, required Map<String, dynamic> payload}) async {
    await db.insert('operation_queue', {
      'request_id': requestId,
      'session_id': sessionId,
      'procedure_code': procedure,
      'operation_kind': kind,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'PENDING',
      'last_error': null,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> updateQueue(String id, String status, [String? error]) async {
    await db.update('operation_queue', {'status': status, 'last_error': error}, where: 'request_id=?', whereArgs: [id]);
  }
  Future<void> deleteQueue(String id) async { await db.delete('operation_queue', where: 'request_id=?', whereArgs: [id]); }
}

class RuntimeFailure implements Exception {
  RuntimeFailure(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class RuntimeClient {
  RuntimeClient(this.store);
  final LocalStore store;
  final http.Client _http = http.Client();
  SupabaseClient get _sb => Supabase.instance.client;

  Future<Map<String, dynamic>> request({
    String? action,
    String? procedure,
    String? step,
    String? consultationCode,
    String? reportCode,
    Map<String, dynamic> payload = const {},
    Map<String, dynamic>? arguments,
    String? requestId,
    Map<String, dynamic> extra = const {},
  }) async {
    final session = _sb.auth.currentSession;
    if (session == null) throw RuntimeFailure('Sessione scaduta. Accedi di nuovo.');
    final body = <String, dynamic>{
      'session_id': store.sessionId,
      if (action != null) 'action': action,
      if (procedure != null) 'procedure': procedure,
      if (step != null) 'step': step,
      if (consultationCode != null) 'consultation_code': consultationCode,
      if (reportCode != null) 'report_code': reportCode,
      'payload': payload,
      if (arguments != null) 'arguments': arguments,
      if (requestId != null) 'request_id': requestId,
      ...extra,
    };
    http.Response response;
    try {
      response = await _http.post(Uri.parse(runtimeUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${session.accessToken}', 'apikey': publishableKey},
        body: jsonEncode(body)).timeout(const Duration(seconds: 35));
    } on TimeoutException {
      throw RuntimeFailure('Timeout HTTP: esito non certo. L’operazione resta in coda e va riconciliata con lo stesso request_id.');
    } on SocketException catch (e) {
      throw RuntimeFailure('Connessione assente: ${e.message}');
    } on http.ClientException catch (e) {
      throw RuntimeFailure('Errore di rete: ${e.message}');
    }
    dynamic decoded;
    try { decoded = jsonDecode(response.body); } catch (_) { decoded = <String, dynamic>{'error': 'Risposta non JSON dal runtime'}; }
    if (response.statusCode < 200 || response.statusCode >= 300 || (decoded is Map && decoded['error'] != null)) {
      throw RuntimeFailure(decoded is Map ? '${decoded['error'] ?? 'Errore HTTP ${response.statusCode}'}' : 'Errore HTTP ${response.statusCode}', statusCode: response.statusCode);
    }
    if (decoded is! Map<String, dynamic>) throw RuntimeFailure('Formato di risposta runtime inatteso.');
    final result = decoded['result'];
    if (result is Map<String, dynamic>) return result;
    return <String, dynamic>{'result': result, 'response': decoded};
  }

  Future<Map<String, dynamic>> acquireLock() => request(action: 'acquire_lock');
  Future<Map<String, dynamic>> heartbeat() => request(action: 'heartbeat');
  Future<Map<String, dynamic>> releaseLock() => request(action: 'release_lock');
  Future<Map<String, dynamic>> setQueuePending(bool pending) => request(action: 'queue_pending', extra: {'pending': pending});
  Future<Map<String, dynamic>> syncOne(Map<String, Object?> item) async {
    final payload = jsonDecode(item['payload']! as String) as Map<String, dynamic>;
    return request(action: 'sync_operation', procedure: item['procedure_code']! as String, payload: payload, requestId: item['request_id']! as String);
  }
}

class DynamicPayloadEditor extends StatefulWidget {
  const DynamicPayloadEditor({super.key, required this.initialValue, required this.onChanged, required this.onStructureChanged});
  final Map<String, dynamic> initialValue;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final ValueChanged<Map<String, dynamic>> onStructureChanged;

  @override
  State<DynamicPayloadEditor> createState() => _DynamicPayloadEditorState();
}

class _DynamicPayloadEditorState extends State<DynamicPayloadEditor> {
  late Map<String, dynamic> value;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) { controller.dispose(); }
    super.dispose();
  }


  static const labels = <String, String>{
    'oggetti': 'Oggetti', 'operazioni': 'Operazioni', 'descrizione': 'Descrizione',
    'descrizione_oggetto': 'Descrizione oggetto', 'codice_oggetto': 'Codice oggetto',
    'codice_acquisto': 'Codice acquisto', 'codice_vendita': 'Codice vendita',
    'codice_vendita_aperta': 'Codice vendita aperta', 'data_acquisto': 'Data acquisto',
    'data_vendita': 'Data vendita', 'data_scambio': 'Data scambio',
    'importo_totale': 'Importo totale', 'importo_vendita': 'Importo vendita',
    'valore_acquisto': 'Valore di acquisto unitario', 'prezzo_di_vendita': 'Prezzo di vendita',
    'quantita': 'Quantità', 'valuta': 'Valuta', 'condizione': 'Condizione',
    'completezza': 'Completezza', 'destinazione': 'Destinazione', 'note': 'Note',
    'motivo_chiusura': 'Motivo chiusura', 'produttore': 'Produttore',
    'anno_uscita': 'Anno di uscita', 'codice_prodotto': 'Codice prodotto',
    'codici_piattaforme': 'Piattaforme', 'modifica_prezzo': 'Modifica prezzo',
    'esito': 'Esito', 'codice_piattaforma': 'Codice piattaforma',
    'rimetti_in_vendita': 'Rimettere in vendita', 'nuovo_oggetto': 'Nuovo oggetto',
    'codici_oggetti': 'Codici oggetti da accorpare', 'descrizione_finale': 'Descrizione finale',
    'condizione_finale': 'Condizione finale', 'completezza_finale': 'Completezza finale',
    'destinazione_finale': 'Destinazione finale', 'metodo_valore': 'Metodo valore',
    'valore_manual': 'Valore manuale', 'azione': 'Azione', 'mercato': 'Mercato',
    'data_prima_commercializzazione': 'Data prima commercializzazione',
    'prezzo_lancio': 'Prezzo di lancio', 'valuta_prezzo_lancio': 'Valuta prezzo di lancio',
    'fonti': 'Fonti', 'fonte': 'Fonte', 'tipo_fonte': 'Tipo fonte', 'estratto': 'Estratto', 'url': 'URL', 'titolo': 'Titolo',
    'dati_confermati': 'Dati confermati', 'altra_operazione': 'Altra operazione',
    'conferma_finale': 'Conferma finale',
  };

  @override
  void initState() {
    super.initState();
    value = _clone(widget.initialValue);
  }

  Map<String, dynamic> _clone(Map<String, dynamic> source) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);

  String _label(String key) => labels[key] ?? key.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());

  void _change(List<Object> path, dynamic next) {
    final root = _clone(value);
    dynamic cursor = root;
    for (var i = 0; i < path.length - 1; i++) {
      cursor = path[i] is int ? (cursor as List)[path[i] as int] : (cursor as Map)[path[i]];
    }
    final last = path.last;
    if (last is int) {
      (cursor as List)[last] = next;
    } else {
      (cursor as Map)[last] = next;
    }
    setState(() => value = root);
    widget.onChanged(_clone(value));
  }

  dynamic _at(List<Object> path) {
    dynamic cursor = value;
    for (final part in path) {
      cursor = part is int ? (cursor as List)[part] : (cursor as Map)[part];
    }
    return cursor;
  }

  dynamic _blankLike(String key, dynamic prototype) {
    if (prototype is Map) return <String, dynamic>{for (final entry in prototype.entries) '${entry.key}': _blankLike('${entry.key}', entry.value)};
    if (prototype is List) return key == 'codici_piattaforme' ? <dynamic>[1] : <dynamic>[];
    if (prototype is bool) return false;
    if (prototype is num) return key == 'quantita' ? 1 : 0;
    if (prototype is String) {
      if (key == 'condizione' || key == 'condizione_finale') return 'USATO';
      if (key == 'completezza' || key == 'completezza_finale') return 'COMPLETO';
      if (key == 'destinazione' || key == 'destinazione_finale') return 'COLLEZIONE';
      if (key == 'valuta' || key == 'valuta_prezzo_lancio') return 'EUR';
      if (key == 'stato_verifica_dati') return 'DA_VERIFICARE';
      return '';
    }
    return null;
  }

  dynamic _newListItem(String key, List items) {
    if (items.isNotEmpty) return _blankLike(key, items.first);
    if (key == 'codici_piattaforme') return 1;
    if (key == 'codici_oggetti') return null;
    if (key == 'fonti') return <String, dynamic>{'titolo': '', 'url': '', 'estratto': '', 'tipo_fonte': 'PRODUTTORE_UFFICIALE'};
    if (key == 'oggetti') return <String, dynamic>{'descrizione': '', 'valore_acquisto': 0, 'condizione': 'USATO', 'completezza': 'COMPLETO', 'destinazione': 'COLLEZIONE', 'quantita': 1};
    if (key == 'operazioni') return <String, dynamic>{'data_acquisto': '', 'importo_totale': 0, 'valuta': 'EUR', 'oggetti': [<String, dynamic>{'descrizione': '', 'valore_acquisto': 0, 'condizione': 'USATO', 'completezza': 'COMPLETO', 'destinazione': 'COLLEZIONE', 'quantita': 1}]};
    return <String, dynamic>{'descrizione': ''};
  }

  List<String>? _options(String key) => switch (key) {
    'condizione' || 'condizione_finale' => ['NUOVO', 'COME NUOVO', 'OTTIMO', 'BUONO', 'DISCRETO', 'USATO', 'USATO CON SEGNI', 'DA RESTAURARE', 'DANNEGGIATO'],
    'completezza' || 'completezza_finale' => ['SIGILLATO', 'COMPLETO', 'INCOMPLETO'],
    'destinazione' || 'destinazione_finale' => ['COLLEZIONE', 'RIVENDITA', 'ALTRO'],
    'valuta' || 'valuta_prezzo_lancio' => ['EUR', 'USD', 'GBP', 'CHF'],
    'mercato' => ['ITALIA', 'EUROPA', 'MONDO'],
    'esito' => ['VENDITA EFFETTIVA', 'NON VENDUTO', 'ANNULLATA'],
    'metodo_valore' => ['MANUALE', 'SOMMA', 'MEDIA'],
    'azione' => ['DATA_DI_USCITA', 'PREZZO_DI_USCITA', 'DATA_E_PREZZO_DI_USCITA'],
    'tipo_fonte' => ['PRODUTTORE_UFFICIALE', 'ARCHIVIO_UFFICIALE_PRODUTTORE'],
    _ => null,
  };

  Widget _field(String key, dynamic current, List<Object> path) {
    final title = _label(key);
    if (current is Map) {
      return Card(margin: const EdgeInsets.symmetric(vertical: 6), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ...current.entries.map((e) => _field('${e.key}', e.value, [...path, e.key])),
      ])));
    }
    if (current is List) {
      return Card(margin: const EdgeInsets.symmetric(vertical: 6), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$title (${current.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
        ...List.generate(current.length, (i) => Card(color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Padding(padding: const EdgeInsets.all(8), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: Text('$title · ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w600))), IconButton(tooltip: 'Rimuovi elemento', onPressed: () { final next = List<dynamic>.from(_at(path) as List)..removeAt(i); _change(path, next); widget.onStructureChanged(_clone(value)); }, icon: const Icon(Icons.delete_outline))]),
          _field('$i', current[i], [...path, i]),
        ])))),
        Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: () { final next = List<dynamic>.from(_at(path) as List)..add(_newListItem(key, current)); _change(path, next); widget.onStructureChanged(_clone(value)); }, icon: const Icon(Icons.add), label: Text('Aggiungi ${title.toLowerCase()}'))),
      ])));
    }
    if (current is bool) {
      return SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(title), value: current, onChanged: (v) => _change(path, v));
    }
    final options = _options(key);
    if (options != null) {
      final selected = current?.toString();
      return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: DropdownButtonFormField<String>(value: options.contains(selected) ? selected : options.first, isExpanded: true, decoration: InputDecoration(labelText: title, border: const OutlineInputBorder()), items: options.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) { if (v != null) _change(path, v); }));
    }
    final isDate = key.startsWith('data_');
    final isNumeric = current is num || key.startsWith('codice_') || key == 'quantita' || key == 'anno_uscita' || key == 'prezzo_lancio' || key == 'valore_manual' || key == 'importo_totale' || key == 'importo_vendita' || key == 'valore_acquisto' || key == 'prezzo_di_vendita';
    final fieldPath = path.join('/');
    final controller = _controllers.putIfAbsent(fieldPath, () => TextEditingController(text: current?.toString() ?? ''));
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: TextFormField(
      key: ValueKey(fieldPath),
      controller: controller,
      keyboardType: isDate ? TextInputType.datetime : (isNumeric ? const TextInputType.numberWithOptions(decimal: true, signed: false) : TextInputType.text),
      decoration: InputDecoration(labelText: title, border: const OutlineInputBorder(), hintText: isDate ? 'AAAA-MM-GG' : null,
        suffixIcon: isDate ? IconButton(tooltip: 'Scegli data', icon: const Icon(Icons.calendar_month), onPressed: () async {
          final now = DateTime.now();
          DateTime initial = DateTime(now.year, now.month, now.day);
          final existing = DateTime.tryParse(current?.toString() ?? '');
          if (existing != null) initial = existing;
          final picked = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime(1900), lastDate: DateTime(2100));
          if (picked != null) { controller.text = picked.toIso8601String().substring(0, 10); _change(path, controller.text); }
        }) : null),
      onChanged: (text) {
        dynamic next = text;
        if (isNumeric) {
          if (text.trim().isEmpty) {
            next = null;
          } else {
            next = (key == 'quantita' || key == 'anno_uscita' || key.startsWith('codice_')) ? int.tryParse(text) ?? text : num.tryParse(text) ?? text;
          }
        }
        _change(path, next);
      },
    ));
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    ...value.entries.map((e) => _field(e.key, e.value, [e.key])),
  ]);
}

class CollectionApp extends StatelessWidget {
  const CollectionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'COLLECTION by VALORA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffb5212a), brightness: Brightness.dark), useMaterial3: true),
    home: const GatePage(),
  );
}

class GatePage extends StatelessWidget {
  const GatePage({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: Supabase.instance.client.auth.onAuthStateChange,
    builder: (context, snapshot) => Supabase.instance.client.auth.currentSession == null ? const LoginPage() : const HomePage(),
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
  bool busy = false;
  String message = 'Accedi con un account beta autorizzato nel progetto TEST.';
  Future<void> login() async {
    setState(() { busy = true; message = 'Accesso in corso…'; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      if (mounted) setState(() => message = 'Accesso effettuato. Verifica autorizzazione beta in corso.');
    } on AuthException catch (e) {
      if (mounted) setState(() => message = e.message);
    } catch (e) {
      if (mounted) setState(() => message = 'Errore di accesso: $e');
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Padding(padding: const EdgeInsets.all(24), child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.widgets_outlined, size: 56), const SizedBox(height: 12), const Text('COLLECTION by VALORA', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Beta tecnica · ambiente TEST', textAlign: TextAlign.center), const SizedBox(height: 24),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())), const SizedBox(height: 12),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), onSubmitted: (_) => login()), const SizedBox(height: 16),
      FilledButton(onPressed: busy ? null : login, child: Text(busy ? 'Attendere…' : 'ACCEDI')), const SizedBox(height: 12), Text(message, textAlign: TextAlign.center),
    ])))))),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final store = LocalStore.instance;
  late final RuntimeClient runtime = RuntimeClient(store);
  final command = TextEditingController();
  final payload = TextEditingController();
  final args = TextEditingController(text: '{}');
  final recognizer = stt.SpeechToText();
  String procedure = 'PR-01';
  String mode = 'procedure';
  String readCode = 'OBJECTS_AVAILABLE';
  String reportCode = 'REPORT-INVENTORY';

  bool busy = false, lockHeld = false, listening = false;
  String phase = 'draft';
  String output = 'Nessuna operazione eseguita.';
  String? activeRequestId;
  Timer? heartbeatTimer;
  int queueCount = 0;
  bool sourceLookupPrepared = false;
  int editorRevision = 0;

  @override
  void initState() {
    super.initState();
    args.text = pretty(reportArgumentsTemplate(reportCode));
    loadTemplate();
    refreshQueue();
    heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) => _heartbeatIfHeld());
    WidgetsBinding.instance.addPostFrameCallback((_) => recoverQueuePrompt());
  }

  @override
  void dispose() {
    heartbeatTimer?.cancel();
    command.dispose(); payload.dispose(); args.dispose();
    super.dispose();
  }

  void showOutput(String value) { if (mounted) setState(() => output = value); }
  String pretty(dynamic value) => const JsonEncoder.withIndent('  ').convert(value);
  bool get isExitProcedure => procedure.startsWith('CMD-');
  bool get isReadMode => mode == 'consultation' || mode == 'report';
  bool get isQueueable => !isExitProcedure && procedureNames.containsKey(procedure);

  Future<void> refreshQueue() async {
    final count = await store.queueCount();
    if (mounted) setState(() => queueCount = count);
  }

  Future<void> checkRuntime() async {
    setState(() { busy = true; output = 'Verifica dello stato runtime TEST…'; });
    try {
      final result = await runtime.request(action: 'health');
      showOutput(pretty(result));
    } catch (e) {
      showOutput('Controllo runtime non riuscito: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> loadApiCatalog() async {
    setState(() { busy = true; output = 'Lettura catalogo API dal runtime TEST…'; });
    try {
      final result = await runtime.request(action: 'catalog');
      showOutput(pretty(result));
    } catch (e) {
      showOutput('Catalogo API non disponibile: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recoverQueuePrompt() async {
    if (await store.queueCount() > 0 && mounted) {
      showOutput('Sono presenti operazioni locali non ancora riconciliate. Il blocco non deve essere rilasciato. Premi SINCRONIZZA CODA prima di iniziare nuove modifiche.');
    }
  }

  Future<void> _heartbeatIfHeld() async {
    if (!lockHeld || !mounted) return;
    try {
      final result = await runtime.heartbeat();
      if (result['ok'] != true) {
        setState(() { lockHeld = false; output = 'ATTENZIONE: il server non conferma più il blocco esclusivo. Interrompi le modifiche e verifica lo stato.'; });
      }
    } catch (e) { showOutput('Heartbeat non riuscito: $e. Non avviare altre scritture finché il blocco non è verificato.'); }
  }

  Future<bool> ensureLock() async {
    if (lockHeld) return true;
    final pending = await store.queueCount();
    if (pending > 0) {
      showOutput('Coda locale non vuota: sincronizzala prima di iniziare nuove modifiche.');
      return false;
    }
    try {
      final result = await runtime.acquireLock();
      if (result['acquisito'] == true) {
        setState(() { lockHeld = true; output = 'Blocco esclusivo acquisito. ${result['messaggio'] ?? ''}'; });
        return true;
      }
      showOutput('Blocco non acquisito: ${result['messaggio'] ?? pretty(result)}');
      return false;
    } catch (e) { showOutput('Non posso verificare il blocco esclusivo: $e'); return false; }
  }

  void loadTemplate() {
    payload.text = pretty(templateFor(procedure));
    setState(() { phase = 'draft'; activeRequestId = null; sourceLookupPrepared = false; editorRevision++; output = 'Schema caricato. Nessuna scrittura eseguita.'; });
  }

  Future<void> toggleVoice() async {
    if (listening) {
      await recognizer.stop();
      if (mounted) setState(() => listening = false);
      return;
    }
    try {
      final available = await recognizer.initialize(
        onStatus: (status) { if (mounted && status == 'notListening') setState(() => listening = false); },
        onError: (error) { if (mounted) setState(() { listening = false; output = 'Riconoscimento vocale: ${error.errorMsg}. Puoi usare la dettatura della tastiera.'; }); },
      );
      if (!available) { showOutput('Dettatura non disponibile su questo dispositivo. Usa testo o dettatura della tastiera.'); return; }
      setState(() => listening = true);
      await recognizer.listen(localeId: 'it_IT', onResult: (result) {
        command.text = result.recognizedWords;
        if (result.finalResult) resolveExactCommand(result.recognizedWords);
      });
    } catch (e) { showOutput('Avvio dettatura non riuscito: $e'); }
  }

  void resolveExactCommand(String value) {
    final normalized = value.toUpperCase().replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    String? matched;
    for (final entry in procedureNames.entries) {
      if (normalized == entry.key || normalized == entry.value || normalized == '${entry.key} ${entry.value}') { matched = entry.key; break; }
    }
    if (matched == null) {
      for (final entry in <String, String>{
        'CMD-DATA-OUT': 'DATA DI USCITA', 'CMD-PRICE-OUT': 'PREZZO DI USCITA', 'CMD-DATE-PRICE-OUT': 'DATA E PREZZO DI USCITA',
      }.entries) {
        if (normalized == entry.key || normalized == entry.value) { matched = entry.key; break; }
      }
    }
    if (matched == null) {
      showOutput('Comando non riconosciuto: deve corrispondere esattamente a un comando ufficiale. Nessuna procedura avviata.');
      return;
    }
    setState(() { procedure = matched!; mode = 'procedure'; });
    loadTemplate();
  }

  Future<void> preview() async {
    if (isReadMode) { await runRead(); return; }
    if (isExitProcedure) { await prepareExit(); return; }
    try {
      final data = jsonDecode(payload.text);
      if (data is! Map<String, dynamic>) throw const FormatException('Il payload deve essere un oggetto JSON.');
      if (!await ensureLock()) return;
      setState(() { busy = true; phase = 'draft'; output = 'Controllo dei dati in corso. Nessuna scrittura prevista…'; });
      final result = await runtime.request(procedure: procedure, step: 'preview', payload: data);
      setState(() { phase = 'confirm'; output = pretty(result); });
    } catch (e) { showOutput('ERRORE: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> prepareExit() async {
    try {
      final data = jsonDecode(payload.text);
      if (data is! Map<String, dynamic>) throw const FormatException('Il payload deve essere un oggetto JSON.');
      final code = int.tryParse('${data['codice_oggetto'] ?? ''}');
      if (code == null || code <= 0) throw const FormatException('Inserisci un codice oggetto già presente nel catalogo. Questa procedura non crea acquisti.');
      if (!await ensureLock()) return;
      setState(() { busy = true; output = 'Preparazione delle ricerche. Le fonti devono essere controllate e ufficiali; nessun salvataggio in questa fase.'; });
      final result = await runtime.request(action: 'exit_prepare', payload: {}, extra: {
        'codice_oggetto': code, 'azione': data['azione'], 'mercato': data['mercato'] ?? 'ITALIA',
      });
      setState(() { sourceLookupPrepared = true; phase = 'confirm'; output = pretty(result); });
    } catch (e) { showOutput('ERRORE: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> appendAnotherOperation() async {
    try {
      final data = jsonDecode(payload.text);
      if (data is! Map<String, dynamic>) throw const FormatException('La bozza non è valida.');
      final template = templateFor(procedure);
      if (data['operazioni'] is List && template['operazioni'] is List) {
        final rows = List<dynamic>.from(data['operazioni'] as List);
        final prototypes = template['operazioni'] as List;
        rows.add(jsonDecode(jsonEncode(prototypes.first)));
        data['operazioni'] = rows;
      } else if (data['oggetti'] is List && template['oggetti'] is List) {
        final rows = List<dynamic>.from(data['oggetti'] as List);
        final prototypes = template['oggetti'] as List;
        rows.add(jsonDecode(jsonEncode(prototypes.first)));
        data['oggetti'] = rows;
      } else {
        throw StateError('Questa procedura non espone una lista multipla nel modello attuale.');
      }
      payload.text = pretty(data);
      setState(() { phase = 'draft'; activeRequestId = null; editorRevision++; output = 'Nuovo record aggiunto alla bozza. I record precedenti sono conservati. Nessuna scrittura eseguita.'; });
    } catch (e) {
      showOutput('Impossibile aggiungere un record: $e');
    }
  }

  Future<void> confirmData() async {
    if (isExitProcedure) {
      if (!await ensureLock()) return;
      try {
        final data = jsonDecode(payload.text) as Map<String, dynamic>;
        data['conferma_finale'] = false;
        setState(() { busy = true; output = 'Verifica della proposta di salvataggio…'; });
        final result = await runtime.request(action: 'exit_apply', payload: data, requestId: uuid.v4());
        if (result['scrittura_eseguita'] == true) throw StateError('Il server ha scritto durante la fase di conferma: interrompere e controllare l’integrità del runtime.');
        setState(() { phase = 'final'; output = 'Procedura relativa a un singolo oggetto. La proposta è verificata senza scrittura; passa alla conferma definitiva.\n\n${pretty(result)}'; });
      } catch (e) { showOutput('ERRORE: $e'); }
      finally { if (mounted) setState(() => busy = false); }
      return;
    }
    setState(() { phase = 'another'; output = 'Dati confermati. Vuoi aggiungere altre operazioni? Nessuna scrittura eseguita.'; });
  }

  Future<void> proceedToFinal() async {
    if (isExitProcedure && !await ensureLock()) return;
    try {
      final data = jsonDecode(payload.text) as Map<String, dynamic>;
      setState(() { busy = true; output = 'Preparazione riepilogo finale…'; });
      if (isExitProcedure) {
        final review = Map<String, dynamic>.from(data)..['conferma_finale'] = false;
        final result = await runtime.request(action: 'exit_apply', payload: review, requestId: uuid.v4());
        if (result['scrittura_eseguita'] == true) throw StateError('Scrittura inattesa durante review.');
        setState(() { phase = 'final'; output = pretty(result); });
      } else {
        final result = await runtime.request(procedure: procedure, step: 'review', payload: {
          ...data, 'dati_confermati': true, 'altra_operazione': false, 'conferma_finale': false,
        });
        setState(() { phase = 'final'; output = pretty(result); });
      }
    } catch (e) { showOutput('ERRORE: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> saveFinal() async {
    if (!await ensureLock()) return;
    try {
      final data = jsonDecode(payload.text);
      if (data is! Map<String, dynamic>) throw const FormatException('Il payload deve essere un oggetto JSON.');
      setState(() { busy = true; output = 'Preparazione salvataggio idempotente…'; });
      final requestId = activeRequestId ?? uuid.v4();
      activeRequestId = requestId;
      final finalPayload = <String, dynamic>{...data, 'dati_confermati': true, 'altra_operazione': false, 'conferma_finale': true};
      await store.enqueue(requestId: requestId, procedure: procedure, kind: isExitProcedure ? 'exit_apply' : 'procedure', payload: finalPayload);
      await refreshQueue();
      try {
        final result = isExitProcedure
            ? await runtime.request(action: 'exit_apply', payload: finalPayload, requestId: requestId)
            : await runtime.request(procedure: procedure, step: 'save', payload: finalPayload, requestId: requestId);
        if (result['scrittura_eseguita'] != true) {
          await store.updateQueue(requestId, 'PENDING', 'Il server non ha confermato scrittura verificata.');
          throw RuntimeFailure('Il server non ha confermato scrittura_eseguita=true. La richiesta resta in coda per riconciliazione.');
        }
        await store.deleteQueue(requestId);
        await refreshQueue();
        setState(() { phase = 'done'; output = pretty(result); activeRequestId = null; });
      } on RuntimeFailure catch (e) {
        // Authentication, authorization, rate-limit and conflict responses do not prove
        // that the queued operation is safe to discard. Preserve the original request_id
        // for every response whose server-side outcome is not a deterministic validation
        // rejection. This is especially important for 401/403 after an expired session.
        final code = e.statusCode;
        final deterministicRejection = code != null &&
            code >= 400 && code < 500 &&
            code != 401 && code != 403 && code != 408 &&
            code != 409 && code != 425 && code != 429;
        if (deterministicRejection) {
          await store.deleteQueue(requestId);
          await refreshQueue();
          rethrow;
        }
        await store.updateQueue(requestId, 'PENDING', e.message);
        try { await runtime.setQueuePending(true); } catch (_) {}
        await refreshQueue();
        setState(() { phase = 'queued'; output = 'ESITO HTTP NON CERTO: operazione conservata in SQLite con lo stesso request_id. Non avviare altre modifiche. Riconnetti e premi SINCRONIZZA CODA. Dettaglio: ${e.message}'; });
      }
    } catch (e) { showOutput('ERRORE: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> syncQueue() async {
    final items = await store.queue();
    if (items.isEmpty) { showOutput('Coda locale vuota.'); await refreshQueue(); return; }
    setState(() { busy = true; output = 'Recupero del blocco e sincronizzazione FIFO in corso…'; });
    try {
      if (!lockHeld) {
        final acquired = await runtime.acquireLock();
        if (acquired['acquisito'] != true) throw RuntimeFailure('Blocco non recuperato: ${acquired['messaggio'] ?? pretty(acquired)}');
        lockHeld = true;
      }
      final queueFlag = await runtime.setQueuePending(true);
      if (queueFlag['ok'] != true) throw RuntimeFailure('Il server non ha registrato la coda pendente: ${queueFlag['messaggio'] ?? pretty(queueFlag)}');
      for (final item in items) {
        final id = item['request_id']! as String;
        await store.updateQueue(id, 'SYNCING');
        try {
          final result = await runtime.syncOne(item);
          if (result['scrittura_eseguita'] != true && result['risposta_idempotente'] != true) {
            throw RuntimeFailure('La sincronizzazione non ha restituito un esito di scrittura verificata.');
          }
          await store.deleteQueue(id);
        } catch (e) {
          await store.updateQueue(id, 'PENDING', '$e');
          rethrow;
        }
      }
      final reset = await runtime.setQueuePending(false);
      if (reset['ok'] != true) throw RuntimeFailure('La coda è stata inviata ma il server non conferma il ripristino dello stato: ${pretty(reset)}');
      await refreshQueue();
      setState(() { output = 'Coda sincronizzata e verificata. Il blocco esclusivo resta acquisito fino a rilascio esplicito.'; phase = 'done'; });
    } catch (e) {
      await refreshQueue();
      showOutput('SINCRONIZZAZIONE SOSPESA: $e\nLa coda locale è stata conservata. Non rilasciare il blocco e non eliminare i dati.');
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> releaseLock() async {
    if (await store.queueCount() > 0) { showOutput('Blocco mantenuto: la coda locale contiene operazioni non riconciliate.'); return; }
    try {
      final result = await runtime.releaseLock();
      if (result['rilasciato'] == true) setState(() { lockHeld = false; output = 'Blocco rilasciato esplicitamente.'; });
      else showOutput('Blocco non rilasciato: ${result['messaggio'] ?? pretty(result)}');
    } catch (e) { showOutput('Rilascio non verificato: $e'); }
  }

  Future<void> runRead() async {
    try {
      final decoded = jsonDecode(args.text);
      if (decoded is! Map<String, dynamic>) throw const FormatException('Gli argomenti devono essere un oggetto JSON.');
      setState(() { busy = true; output = 'Consultazione in corso…'; });
      final runtimeReportCode = reportRuntimeCodes[reportCode];
      if (mode == 'report' && runtimeReportCode == null) {
        throw StateError('Codice report non presente nel contratto runtime: $reportCode');
      }
      final result = await runtime.request(
        action: mode == 'report' ? 'report' : 'consultation',
        payload: decoded,
        arguments: decoded,
        consultationCode: mode == 'consultation' ? readCode : null,
        reportCode: mode == 'report' ? runtimeReportCode : null,
        extra: {'code': mode == 'report' ? runtimeReportCode : readCode},
      );
      showOutput(pretty(result));
    } catch (e) { showOutput('ERRORE: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> logout() async {
    if (await store.queueCount() > 0) { showOutput('Logout bloccato: sincronizza prima la coda. Il blocco non deve essere rilasciato.'); return; }
    if (lockHeld) await releaseLock();
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('COLLECTION by VALORA'), actions: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Center(child: Text('Coda: $queueCount', style: const TextStyle(fontSize: 12)))),
      IconButton(tooltip: 'Esci', onPressed: busy ? null : logout, icon: const Icon(Icons.logout)),
    ]),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('AMBIENTE TEST · DATABASE CENTRALE', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text('Sessione locale persistente: ${store.sessionId}'),
        const SizedBox(height: 8), Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: busy ? null : () async { final ok = await ensureLock(); if (ok) showOutput('Blocco esclusivo attivo.'); }, icon: const Icon(Icons.lock_open), label: const Text('ACQUISISCI BLOCCO')),
          OutlinedButton.icon(onPressed: busy ? null : syncQueue, icon: const Icon(Icons.sync), label: const Text('SINCRONIZZA CODA')),
          OutlinedButton.icon(onPressed: busy ? null : releaseLock, icon: const Icon(Icons.lock), label: const Text('RILASCIA BLOCCO')),
          OutlinedButton.icon(onPressed: busy ? null : checkRuntime, icon: const Icon(Icons.health_and_safety), label: const Text('STATO RUNTIME')),
          OutlinedButton.icon(onPressed: busy ? null : loadApiCatalog, icon: const Icon(Icons.api), label: const Text('CATALOGO API')),
        ]),
      ]))),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('COMANDO OPERATIVO', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 10),
        TextField(controller: command, decoration: InputDecoration(labelText: 'Comando ufficiale esatto', hintText: 'Es. NUOVO ACQUISTO', border: const OutlineInputBorder(), suffixIcon: IconButton(tooltip: listening ? 'Ferma dettatura' : 'Detta comando', onPressed: toggleVoice, icon: Icon(listening ? Icons.mic : Icons.mic_none))), onSubmitted: resolveExactCommand),
        const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: OutlinedButton.icon(onPressed: () => resolveExactCommand(command.text), icon: const Icon(Icons.route), label: const Text('RICONOSCI COMANDO ESATTO'))),
        DropdownButtonFormField<String>(value: mode, decoration: const InputDecoration(labelText: 'Tipo di operazione', border: OutlineInputBorder()), items: const [
          DropdownMenuItem(value: 'procedure', child: Text('Procedure di scrittura')),
          DropdownMenuItem(value: 'consultation', child: Text('Consultazioni in sola lettura')),
          DropdownMenuItem(value: 'report', child: Text('Report in sola lettura')),
        ], onChanged: (v) { if (v != null) setState(() => mode = v); }),
        if (mode == 'procedure') ...[
          const SizedBox(height: 10), DropdownButtonFormField<String>(value: procedure, isExpanded: true, decoration: const InputDecoration(labelText: 'Procedura ufficiale', border: OutlineInputBorder()), items: [
            ...procedureNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.key} · ${e.value}'))),
            const DropdownMenuItem(value: 'CMD-DATA-OUT', child: Text('DATA DI USCITA')),
            const DropdownMenuItem(value: 'CMD-PRICE-OUT', child: Text('PREZZO DI USCITA')),
            const DropdownMenuItem(value: 'CMD-DATE-PRICE-OUT', child: Text('DATA E PREZZO DI USCITA')),
          ], onChanged: (v) { if (v != null) { setState(() => procedure = v); loadTemplate(); } }),
          const SizedBox(height: 10), const Text('Compila i campi della procedura. Le modifiche restano in bozza e non scrivono nel database.'), const SizedBox(height: 6),
          DynamicPayloadEditor(key: ValueKey('payload-$procedure-$editorRevision'), initialValue: jsonDecode(payload.text) as Map<String, dynamic>, onChanged: (value) { payload.text = pretty(value); }, onStructureChanged: (value) { payload.text = pretty(value); setState(() => editorRevision++); }),
          const SizedBox(height: 8), OutlinedButton.icon(onPressed: loadTemplate, icon: const Icon(Icons.restart_alt), label: const Text('RIPRISTINA CAMPI INIZIALI')),
          const SizedBox(height: 10), FilledButton.icon(onPressed: busy ? null : preview, icon: const Icon(Icons.fact_check), label: Text(isExitProcedure ? 'PREPARA RICERCA / PROPOSTA' : '1 · CONTROLLA E MOSTRA RIEPILOGO')),
        ],
        if (mode != 'procedure') ...[
          const SizedBox(height: 10),
          if (mode == 'consultation') DropdownButtonFormField<String>(value: readCode, isExpanded: true, decoration: const InputDecoration(labelText: 'Consultazione', border: OutlineInputBorder()), items: readActions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text('${e.key} · ${e.value}'))).toList(), onChanged: (v) { if (v != null) setState(() => readCode = v); }),
          if (mode == 'report') DropdownButtonFormField<String>(value: reportCode, isExpanded: true, decoration: const InputDecoration(labelText: 'Report', border: OutlineInputBorder()), items: const [
            DropdownMenuItem(value: 'REPORT-ACTIVE-LISTINGS', child: Text('Inserzioni attive')),
            DropdownMenuItem(value: 'REPORT-CASH', child: Text('Flussi di cassa')),
            DropdownMenuItem(value: 'REPORT-HISTORY', child: Text('Storico')),
            DropdownMenuItem(value: 'REPORT-INVENTORY', child: Text('Inventario')),
            DropdownMenuItem(value: 'REPORT-PURCHASES', child: Text('Acquisti')),
            DropdownMenuItem(value: 'REPORT-SALES', child: Text('Vendite')),
          ], onChanged: (v) {
            if (v != null) {
              setState(() {
                reportCode = v;
                args.text = pretty(reportArgumentsTemplate(v));
              });
            }
          }),
          const SizedBox(height: 10), const Text('Argomenti (JSON)'), TextField(controller: args, minLines: 4, maxLines: 10, style: const TextStyle(fontFamily: 'monospace'), decoration: const InputDecoration(border: OutlineInputBorder())),
          const SizedBox(height: 10), FilledButton(onPressed: busy ? null : runRead, child: const Text('ESEGUI CONSULTAZIONE')),
        ],
      ]))),
      if (mode == 'procedure' && phase != 'draft') Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(switch (phase) {'confirm' => '2 · CONFERMA DATI', 'another' => '3 · ALTRA OPERAZIONE?', 'final' => '4 · CONFERMA DEFINITIVA', 'queued' => 'OPERAZIONE IN CODA', 'done' => 'ESITO', _ => 'PROCEDURA'}, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8),
        if (phase == 'confirm') ...[
          const Text('Leggi l’esito prima di confermare. La fase di controllo non deve scrivere dati.'),
          FilledButton(onPressed: busy ? null : confirmData, child: const Text('SÌ · CONFERMO I DATI')),
          OutlinedButton(onPressed: () => setState(() { phase = 'draft'; output = 'Bozza riaperta. Nessuna scrittura eseguita.'; }), child: const Text('NO · TORNA A MODIFICARE')),
        ],
        if (phase == 'another') ...[
          const Text('SÌ aggiunge un record vuoto alla bozza mantenendo quelli già compilati. NO passa al riepilogo finale del lotto completo.'),
          OutlinedButton(onPressed: busy ? null : appendAnotherOperation, child: const Text('SÌ · AGGIUNGI OPERAZIONE')),
          FilledButton(onPressed: busy ? null : proceedToFinal, child: const Text('NO · PROSEGUI ALLA CONFERMA FINALE')),
        ],
        if (phase == 'final') ...[
          const Text('La scrittura parte soltanto dopo la conferma definitiva. Il request_id rimane identico in caso di retry.'),
          FilledButton(onPressed: busy ? null : saveFinal, child: const Text('CONFERMA DEFINITIVA E SALVA')),
          OutlinedButton(onPressed: () => setState(() { phase = 'draft'; activeRequestId = null; output = 'Bozza riaperta. Nessuna scrittura eseguita.'; }), child: const Text('TORNA ALLA BOZZA')),
        ],
        if (phase == 'queued') ...[
          const Text('L’esito del server non è certo. La richiesta è conservata in SQLite con lo stesso request_id. Non ripetere il salvataggio e non rilasciare il blocco.'),
          FilledButton(onPressed: busy ? null : syncQueue, child: const Text('SINCRONIZZA E VERIFICA CODA')),
        ],
        if (phase == 'done') ...[
          const Text('Il runtime deve restituire l’esito e la verifica post-salvataggio.'),
          FilledButton(onPressed: loadTemplate, child: const Text('NUOVA OPERAZIONE')),
          OutlinedButton(onPressed: () => setState(() { phase = 'draft'; output = 'Procedura chiusa.'; }), child: const Text('CHIUDI PROCEDURA')),
        ],
      ]))),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ESITO RUNTIME / VERIFICA', style: TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 8), SelectableText(output, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))]))),
      const Padding(padding: EdgeInsets.all(8), child: Text('Beta tecnica · progetto TEST eeiekkflpnkummxtvljy · produzione non collegata', textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent))),
    ])),
  );
}
