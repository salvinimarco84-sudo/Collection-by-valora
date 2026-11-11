part of '../main.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});
  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> with SalesReportDataMixin {
  Future<void> _export({required bool pdf}) async {
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non ci sono vendite da esportare.')));
      return;
    }
    try {
      final path = await SalesReportExportService.createAndSave(
        rows: _rows, pdf: pdf, period: _periodArguments(), amount: _amount, money: _money,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(path == null ? 'Esportazione annullata.' : 'File ${pdf ? 'pdf' : 'xlsx'} creato: $path'),
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Esportazione non riuscita: $error')));
    }
  }
  Future<void> _changePage(int nextPage) async {
    if (nextPage < 0 || nextPage >= (_rows.length / _pageSize).ceil()) return;
    setState(() => _page = nextPage);
    final start = nextPage * _pageSize;
    await _loadImages(_rows.skip(start).take(_pageSize).toList());
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
          return SalesReportCard(
            row: row, imageUrl: image,
            amountLabel: _money(_amount(row)),
            onTap: id == null ? () {} : () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ObjectRuntimePage(title: 'Scheda oggetto', apiCode: 'OBJECT_MASTER', initialObjectCode: id),
            )),
          );
        }),
        if (count > 1) ReportPaginationControls(
          currentPage: _page, pageSize: _pageSize, totalItems: _rows.length,
          pageCount: count, textColor: appearance.textSecondary,
          onPrevious: _loading || _page == 0 ? null : () => _changePage(_page - 1),
          onNext: _loading || _page + 1 >= count ? null : () => _changePage(_page + 1),
        ),
        if (_loading && _rows.isNotEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _export(pdf: false), icon: const Icon(Icons.file_download_outlined), label: const Text('CREA FILE EXCEL'))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(onPressed: _loading ? null : () => _export(pdf: true), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('CREA FILE PDF'))),
        ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close), label: const Text('CHIUDI E TORNA AL BLOCCO VENDITE')),
      ]),
    );
  }
}
