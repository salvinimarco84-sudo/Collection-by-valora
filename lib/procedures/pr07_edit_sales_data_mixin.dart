part of '../main.dart';

mixin Pr07EditSalesDataMixin on State<Pr07EditSalesPage> {
  final String pr07SessionId = _uuid.v4();
  final ScrollController pr07ScrollController = ScrollController();
  final TextEditingController pr07SearchController = TextEditingController();
  final TextEditingController pr07PriceController = TextEditingController();
  final TextEditingController pr07NotesController = TextEditingController();

  bool pr07Loading = false;
  bool pr07LockHeld = false;
  bool pr07ModifyDate = false;
  bool pr07ModifyPrice = false;
  bool pr07ModifyPlatforms = false;
  bool pr07ModifyNotes = false;
  List<Map<String, dynamic>> pr07Sales = [];
  List<Map<String, dynamic>> pr07Platforms = [];
  Map<String, dynamic>? pr07SelectedSale;
  DateTime? pr07SelectedDate;
  final Set<int> pr07SelectedPlatformCodes = <int>{};
  Map<String, dynamic>? pr07Preview;
  Map<String, dynamic>? pr07Review;
  String? pr07Error;
  String? pr07Success;

  List<Map<String, dynamic>> get filteredPr07Sales {
    final query = pr07SearchController.text.trim().toLowerCase();
    if (query.isEmpty) return pr07Sales;
    return pr07Sales.where((sale) {
      final haystack = [
        sale['codice_vendita_aperta'],
        sale['codice_oggetto'],
        sale['descrizione_oggetto'],
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runPr07(loadPr07Sales);
    });
  }

  @override
  void dispose() {
    pr07ScrollController.dispose();
    pr07SearchController.dispose();
    pr07PriceController.dispose();
    pr07NotesController.dispose();
    if (pr07LockHeld) {
      _ValoraRuntimeApi.call('release_lock', {'session_id': pr07SessionId})
          .catchError((_) => <String, dynamic>{});
    }
    super.dispose();
  }

  Future<void> runPr07(Future<void> Function() action) async {
    if (pr07Loading) return;
    setState(() { pr07Loading = true; pr07Error = null; });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => pr07Error = error.toString());
    } finally {
      if (mounted) setState(() => pr07Loading = false);
    }
  }

  Future<void> loadPr07Sales() async {
    final response = await _ValoraRuntimeApi.call('open_sales_list', {'session_id': pr07SessionId});
    final result = response['result'];
    if (result is! Map) throw Exception('Risposta elenco vendite aperte non valida.');
    final rawSales = result['vendite'];
    final rawPlatforms = result['piattaforme'];
    final sales = rawSales is List
        ? rawSales.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
        : <Map<String, dynamic>>[];
    final platforms = rawPlatforms is List
        ? rawPlatforms.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
        : <Map<String, dynamic>>[];

    // Il runtime espone le piattaforme e i cicli aperti; le note vengono lette
    // separatamente perché non fanno parte del payload dell'endpoint elenco.
    if (sales.isNotEmpty) {
      try {
        final ids = sales.map((row) => int.tryParse('${row['codice_vendita_aperta']}'))
            .whereType<int>().toList();
        final notes = await Supabase.instance.client.schema('collection')
            .from('master_oggetti_in_vendita')
            .select('codice_vendita_aperta,note')
            .inFilter('codice_vendita_aperta', ids);
        for (final noteRow in (notes as List).whereType<Map>()) {
          final id = noteRow['codice_vendita_aperta']?.toString();
          final target = sales.where((row) => row['codice_vendita_aperta']?.toString() == id);
          if (target.isNotEmpty) target.first['note'] = noteRow['note'];
        }
      } catch (_) {
        // Il flusso resta disponibile; l'utente può comunque impostare nuove note.
      }
    }
    if (!mounted) return;
    setState(() {
      pr07Sales = sales;
      pr07Platforms = platforms;
      final selectedId = pr07SelectedSale?['codice_vendita_aperta']?.toString();
      Map<String, dynamic>? retainedSelection;
      if (selectedId != null) {
        for (final row in sales) {
          if (row['codice_vendita_aperta']?.toString() == selectedId) {
            retainedSelection = row;
            break;
          }
        }
      }
      pr07SelectedSale = retainedSelection;
    });
  }

  void selectPr07Sale(Map<String, dynamic> sale) {
    pr07SelectedSale = sale;
    pr07PriceController.text = (sale['prezzo_di_vendita'] ?? '').toString();
    pr07NotesController.text = (sale['note'] ?? '').toString();
    pr07SelectedDate = DateTime.tryParse((sale['data_inizio_vendita'] ?? '').toString());
    pr07SelectedPlatformCodes
      ..clear()
      ..addAll(((sale['piattaforme_associate'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => int.tryParse((item['codice_piattaforma'] ?? '').toString()))
          .whereType<int>());
    pr07ModifyDate = false;
    pr07ModifyPrice = false;
    pr07ModifyPlatforms = false;
    pr07ModifyNotes = false;
    pr07Preview = null;
    pr07Review = null;
    pr07Success = null;
    pr07Error = null;
  }

  void invalidatePr07Draft([VoidCallback? change]) {
    change?.call();
    pr07Preview = null;
    pr07Review = null;
  }

  String pr07DateString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> pickPr07Date() async {
    final initial = pr07SelectedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Data iniziale della vendita',
      cancelText: 'ANNULLA',
      confirmText: 'CONFERMA',
    );
    if (picked != null && mounted) {
      setState(() {
        pr07SelectedDate = picked;
        invalidatePr07Draft();
      });
    }
  }

  Map<String, dynamic> pr07Payload() {
    final sale = pr07SelectedSale;
    if (sale == null) throw Exception('Seleziona una vendita aperta da modificare.');
    final id = int.tryParse((sale['codice_vendita_aperta'] ?? '').toString());
    if (id == null || id <= 0) throw Exception('Codice vendita aperta non valido.');
    if (!pr07ModifyDate && !pr07ModifyPrice && !pr07ModifyPlatforms && !pr07ModifyNotes) {
      throw Exception('Seleziona almeno un campo da modificare.');
    }
    final operation = <String, dynamic>{
      'codice_vendita_aperta': id,
      'modifica_data': pr07ModifyDate,
      'modifica_prezzo': pr07ModifyPrice,
      'modifica_piattaforme': pr07ModifyPlatforms,
      'modifica_note': pr07ModifyNotes,
    };
    if (pr07ModifyDate) {
      final date = pr07SelectedDate;
      if (date == null) throw Exception('Seleziona una data iniziale valida.');
      operation['data_inizio_vendita'] = pr07DateString(date);
    }
    if (pr07ModifyPrice) {
      final raw = pr07PriceController.text.trim().replaceAll(',', '.');
      final price = double.tryParse(raw);
      if (price == null || !price.isFinite || price <= 0) {
        throw Exception('Il prezzo richiesto deve essere maggiore di zero.');
      }
      operation['prezzo_di_vendita'] = price;
    }
    if (pr07ModifyPlatforms) {
      if (pr07SelectedPlatformCodes.isEmpty) {
        throw Exception('Seleziona almeno una piattaforma di vendita.');
      }
      operation['codici_piattaforme'] = pr07SelectedPlatformCodes.toList()..sort();
    }
    if (pr07ModifyNotes) operation['note'] = pr07NotesController.text.trim();
    return {'operazioni': [operation]};
  }

  Future<void> previewPr07Changes() async {
    final payload = pr07Payload();
    if (!pr07LockHeld) {
      final lock = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': pr07SessionId});
      final result = lock['result'];
      if (result is! Map || result['acquisito'] != true) {
        throw Exception(result is Map
            ? (result['messaggio'] ?? 'Archivio bloccato da un’altra sessione.')
            : 'Blocco esclusivo non acquisito.');
      }
      pr07LockHeld = true;
    }
    try {
      final result = await _ValoraRuntimeApi.procedure(
        'PR-07', 'preview', payload, sessionId: pr07SessionId);
      if (!mounted) return;
      setState(() { pr07Preview = result; pr07Review = null; });
    } catch (_) {
      await releasePr07Lock();
      rethrow;
    }
  }

  Future<void> confirmPr07Changes() async {
    final payload = pr07Payload()
      ..['dati_confermati'] = true
      ..['altra_operazione'] = false
      ..['conferma_finale'] = false;
    final result = await _ValoraRuntimeApi.procedure(
      'PR-07', 'review', payload, sessionId: pr07SessionId);
    if (result['stato'] != 'IN_ATTESA_CONFERMA_FINALE') {
      throw Exception('PR-07 non è arrivata alla conferma finale. Stato: ${result['stato'] ?? 'non disponibile'}');
    }
    if (mounted) setState(() => pr07Review = result);
  }

  Future<void> savePr07Changes() async {
    if (pr07Review == null) throw Exception('Conferma prima il riepilogo delle modifiche.');
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Conferma definitiva PR-07'),
        content: Text('Stai per modificare la vendita #${pr07SelectedSale?['codice_vendita_aperta']}. Vuoi procedere?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('CONFERMA E SALVA')),
        ],
      ),
    );
    if (accepted != true) return;
    final payload = pr07Payload()
      ..['dati_confermati'] = true
      ..['altra_operazione'] = false
      ..['conferma_finale'] = true;
    final result = await _ValoraRuntimeApi.procedure(
      'PR-07', 'save', payload,
      sessionId: pr07SessionId,
      requestId: _uuid.v4(),
    );
    if (result['scrittura_eseguita'] != true) {
      throw Exception('Il runtime non ha confermato il salvataggio PR-07.');
    }
    if (result['blocco_rilasciato_automaticamente'] == true) {
      pr07LockHeld = false;
    } else {
      await releasePr07Lock();
    }
    if (!mounted) return;
    setState(() {
      pr07Success = 'Vendita modificata e riletta dal database: #${pr07SelectedSale?['codice_vendita_aperta']}.';
      pr07SelectedSale = null;
      pr07Preview = null;
      pr07Review = null;
      pr07ModifyDate = false;
      pr07ModifyPrice = false;
      pr07ModifyPlatforms = false;
      pr07ModifyNotes = false;
    });
    await loadPr07Sales();
  }

  Future<void> releasePr07Lock() async {
    if (!pr07LockHeld) return;
    try {
      final response = await _ValoraRuntimeApi.call('release_lock', {'session_id': pr07SessionId});
      final result = response['result'];
      if (result is Map && result['rilasciato'] == true) pr07LockHeld = false;
    } catch (_) {}
  }
}
