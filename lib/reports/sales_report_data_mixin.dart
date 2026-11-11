part of '../main.dart';

mixin SalesReportDataMixin on State<SalesReportPage> {
  static const int _pageSize = 50;
  static const int _batchSize = 100;
  final String _sessionId = _uuid.v4();
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  final Map<int, String> _imageUrls = {};
  int _page = 0;
  String _periodMode = 'month';
  DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _end = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _load(); });
  }

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  Map<String, String> _periodArguments() {
    final now = DateTime.now();
    final from = _periodMode == 'year'
        ? DateTime(now.year, 1, 1)
        : _periodMode == 'month'
            ? DateTime(now.year, now.month, 1)
            : DateTime(_start.year, _start.month, _start.day);
    final to = _periodMode == 'custom'
        ? DateTime(_end.year, _end.month, _end.day)
        : DateTime(now.year, now.month, now.day);
    if (from.isAfter(to)) throw Exception('La data iniziale non può essere successiva alla data finale.');
    String iso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {'data_da': iso(from), 'data_a': iso(to)};
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2000), lastDate: DateTime(2100),
      helpText: isStart ? 'Scegli la data iniziale' : 'Scegli la data finale',
      cancelText: 'ANNULLA', confirmText: 'CONFERMA',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
        if (_start.isAfter(_end)) _end = picked;
      } else {
        _end = picked;
        if (_end.isBefore(_start)) _start = picked;
      }
    });
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final period = _periodArguments();
      final all = <Map<String, dynamic>>[];
      var offset = 0;
      while (true) {
        final response = await _ValoraRuntimeApi.call('report', {
          'session_id': _sessionId,
          'report_code': 'SALES_REPORT',
          'arguments': {...period, 'limite': _batchSize, 'offset': offset},
        });
        final envelope = response['result'];
        final data = envelope is Map ? (envelope['risultato'] ?? envelope) : envelope;
        if (data is! Map) throw Exception('Risposta del report vendite non valida.');
        final raw = data['record'];
        final rows = raw is List
            ? raw.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList()
            : <Map<String, dynamic>>[];
        all.addAll(rows);
        if (rows.length < _batchSize) break;
        offset += _batchSize;
        if (offset >= 100000) throw Exception('Il report supera il limite di sicurezza di 100.000 record.');
      }
      if (!mounted) return;
      setState(() { _rows = all; _page = 0; _imageUrls.clear(); });
      await _loadImages(all.take(_pageSize).toList());
    } catch (error) {
      if (mounted) setState(() { _error = 'Impossibile caricare il report vendite: $error'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadImages(List<Map<String, dynamic>> rows) async {
    final ids = rows.map((row) => int.tryParse((row['codice_oggetto'] ?? row['id_oggetto'] ?? '').toString()))
        .whereType<int>().where((id) => id > 0).toSet();
    await Future.wait(ids.map((id) async {
      var url = '';
      try {
        final metadata = await Supabase.instance.client.schema('collection')
            .from('master_metadati').select('url_immagine').eq('codice_oggetto', id).maybeSingle();
        url = (metadata?['url_immagine'] ?? '').toString().trim();
      } catch (_) {}
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
        } catch (_) {}
      }
      if (url.startsWith('https://') || url.startsWith('http://')) _imageUrls[id] = url;
    }));
    if (mounted && _imageUrls.isNotEmpty) setState(() {});
  }

  double _amount(Map<String, dynamic> row) {
    for (final key in const ['importo_vendita', 'prezzo_di_vendita', 'importo_totale', 'importo', 'totale', 'prezzo']) {
      final value = row[key];
      if (value == null || value.toString().trim().isEmpty) continue;
      if (value is num) return value.toDouble();
      var raw = value.toString().trim().replaceAll('€', '').replaceAll('EUR', '').replaceAll(RegExp(r'\s+'), '');
      if (raw.contains(',') && raw.contains('.')) {
        raw = raw.lastIndexOf(',') > raw.lastIndexOf('.') ? raw.replaceAll('.', '').replaceAll(',', '.') : raw.replaceAll(',', '');
      } else if (raw.contains(',')) { raw = raw.replaceAll(',', '.'); }
      return double.tryParse(raw) ?? 0;
    }
    return 0;
  }

  String _money(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse((value ?? 0).toString().replaceAll(',', '.')) ?? 0;
    final parts = number.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return '$whole,${parts[1]} €';
  }

  String _description(Map<String, dynamic> row) =>
      (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome_oggetto'] ?? row['titolo'] ?? 'Vendita senza descrizione').toString();

}
