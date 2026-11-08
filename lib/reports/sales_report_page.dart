part of '../main.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});
  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
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
      await _loadImages(all);
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
      var raw = value.toString().trim().replaceAll('€', '').replaceAll('EUR', '').replaceAll(RegExp(r'\\s+'), '');
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
    final whole = parts[0].replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (_) => '.');
    return '$whole,${parts[1]} €';
  }

  String _description(Map<String, dynamic> row) =>
      (row['descrizione_oggetto'] ?? row['descrizione'] ?? row['nome_oggetto'] ?? row['titolo'] ?? 'Vendita senza descrizione').toString();

  Future<void> _export({required bool pdf}) async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non ci sono vendite da esportare.')));
      return;
    }
    try {
      final records = _rows;
      final headers = <String>[];
      for (final row in records) { for (final key in row.keys) { if (!headers.contains(key)) headers.add(key); } }
      String cell(dynamic value) => value == null ? '' : value is Map || value is List ? jsonEncode(value) : value.toString();
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final name = 'VALORA_REPORT_SALES_$stamp';
      late Uint8List bytes;
      final extension = pdf ? 'pdf' : 'xlsx';
      if (pdf) {
        final document = pw.Document();
        document.addPage(pw.MultiPage(
          pageFormat: pw_core.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (_) => [
            pw.Text('COLLECTION by VALORA', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('REPORT VENDITE · ${_periodArguments()['data_da']} / ${_periodArguments()['data_a']}'),
            pw.Text('Vendite: ${records.length} · Totale: ${_money(records.fold<double>(0, (sum, row) => sum + _amount(row)))}'),
            pw.SizedBox(height: 12),
            pw.TableHelper.fromTextArray(
              data: [headers, ...records.map((row) => headers.map((key) => cell(row[key])).toList())],
              headerStyle: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 6),
              headerDecoration: const pw.BoxDecoration(color: pw_core.PdfColor.fromInt(0xFFD6B15E)),
              cellAlignment: pw.Alignment.topLeft,
              border: pw.TableBorder.all(color: pw_core.PdfColor.fromInt(0xFFBBBBBB), width: 0.35),
            ),
          ],
        ));
        bytes = Uint8List.fromList(await document.save());
      } else {
        final workbook = xlsx.Excel.createExcel();
        final sheet = workbook['Vendite'];
        sheet.appendRow(headers.map((key) => xlsx.TextCellValue(key)).toList());
        for (final row in records) { sheet.appendRow(headers.map((key) => xlsx.TextCellValue(cell(row[key]))).toList()); }
        final encoded = workbook.encode();
        if (encoded == null) throw Exception('Creazione Excel non riuscita.');
        bytes = Uint8List.fromList(encoded);
      }
      final path = await FilePicker.platform.saveFile(
        dialogTitle: pdf ? 'Salva report PDF' : 'Salva report Excel',
        fileName: '$name.$extension',
        type: FileType.custom, allowedExtensions: [extension], bytes: bytes,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path == null ? 'Esportazione annullata.' : 'File $extension creato: $path'),
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Esportazione non riuscita: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final color = appearance.colorFor('VENDITE');
    final count = (_rows.length / _pageSize).ceil();
    final visible = _rows.skip(_page * _pageSize).take(_pageSize).toList();
    final total = _rows.fold<double>(0, (sum, row) => sum + _amount(row));
    final period = _periodArguments();
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORT VENDITE'),
        actions: [IconButton(tooltip: 'Aggiorna report', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Text('Consultazione in sola lettura delle vendite concluse nel periodo selezionato.',
          style: TextStyle(color: appearance.textSecondary, height: 1.4)),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PERIODO DI RIFERIMENTO', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'month', label: Text('Mese')),
              ButtonSegment(value: 'year', label: Text('Anno')),
              ButtonSegment(value: 'custom', label: Text('Intervallo')),
            ],
            selected: {_periodMode},
            onSelectionChanged: _loading ? null : (value) => setState(() => _periodMode = value.first),
          ),
          if (_periodMode == 'custom') ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pickDate(isStart: true), icon: const Icon(Icons.calendar_today), label: Text('DA ${_dateLabel(_start)}'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _pickDate(isStart: false), icon: const Icon(Icons.event), label: Text('A ${_dateLabel(_end)}'))),
            ]),
          ] else
            Padding(padding: const EdgeInsets.only(top: 8), child: Text(
              _periodMode == 'year' ? 'Dal 01/01/${DateTime.now().year} a oggi' : 'Dal 01/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} a oggi',
              style: TextStyle(color: appearance.textSecondary, fontSize: 12),
            )),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: FilledButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.search), label: const Text('APPLICA PERIODO'),
          )),
        ]))),
        ReportSummaryPanel(sectionColor: color, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('RIEPILOGO VENDITE', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('VENDITE CONCLUSE: ${_rows.length}')),
            Text(_money(total), style: TextStyle(color: appearance.textPrimary, fontWeight: FontWeight.bold, fontSize: 19)),
          ]),
          Text('Totale degli importi registrati nel periodo ${period['data_da']} / ${period['data_a']}',
            style: TextStyle(color: appearance.textSecondary, fontSize: 12)),
        ])),
        if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))),
        if (_loading && _rows.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (!_loading && _rows.isEmpty && _error == null)
          const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Nessuna vendita trovata nel periodo selezionato.'))),
        ...visible.map((row) {
          final id = int.tryParse((row['codice_oggetto'] ?? row['id_oggetto'] ?? '').toString());
          final date = (row['data_vendita'] ?? row['data_chiusura'] ?? row['data'] ?? 'Data non indicata').toString();
          final saleCode = (row['codice_vendita'] ?? row['codice_vendita_aperta'] ?? row['id_vendita'] ?? 'N/D').toString();
          final image = id == null ? '' : (_imageUrls[id] ?? '');
          return ReportOperationCard(
            sectionColor: color, showImage: true, imageUrl: image,
            title: _description(row),
            subtitle: 'Vendita #$saleCode · Oggetto #${id ?? 'N/D'} · Data: $date',
            trailingText: _money(_amount(row)),
            onTap: id == null ? () {} : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ObjectRuntimePage(title: 'Scheda oggetto', apiCode: 'OBJECT_MASTER', initialObjectCode: id),
            )),
          );
        }),
        if (count > 1) ReportPaginationControls(
          currentPage: _page, pageSize: _pageSize, totalItems: _rows.length,
          pageCount: count, textColor: appearance.textSecondary,
          onPrevious: _loading || _page == 0 ? null : () => setState(() => _page--),
          onNext: _loading || _page + 1 >= count ? null : () => setState(() => _page++),
        ),
        if (_loading && _rows.isNotEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _export(pdf: false), icon: const Icon(Icons.file_download_outlined), label: const Text('EXCEL'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _export(pdf: true), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('PDF'))),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close), label: const Text('CHIUDI E TORNA AL BLOCCO VENDITE')),
      ]),
    );
  }
}
