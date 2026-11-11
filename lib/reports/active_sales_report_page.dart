part of '../main.dart';

class ActiveSalesReportPage extends StatefulWidget {
  const ActiveSalesReportPage({super.key});

  @override
  State<ActiveSalesReportPage> createState() => _ActiveSalesReportPageState();
}

class _ActiveSalesReportPageState extends State<ActiveSalesReportPage> with ActiveSalesReportDataMixin {
  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final color = appearance.colorFor('VENDITE');
    final pageCount = (_rows.length / _pageSize).ceil();
    final visible = _rows.skip(_page * _pageSize).take(_pageSize).toList();
    final total = _rows.fold<double>(0, (sum, row) =>
      sum + (double.tryParse((row['prezzo_di_vendita'] ?? row['valore_nominale'] ?? row['importo_vendita'] ?? 0).toString()) ?? 0));
    return Scaffold(
      appBar: AppBar(
        title: const Text('REPORT VENDITE ATTIVE'),
        actions: [IconButton(tooltip: 'Aggiorna report', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading && _rows.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(14), children: [
              Text('Consultazione in sola lettura delle vendite ancora aperte. Nessun filtro temporale applicato.',
                style: TextStyle(color: appearance.textSecondary, height: 1.4)),
              const SizedBox(height: 12),
              ReportSummaryPanel(
                sectionColor: color,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('RIEPILOGO VENDITE ATTIVE', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Text('INSERZIONI APERTE: ${_rows.length}')),
                    Text(_money(total), style: TextStyle(color: appearance.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                  ]),
                  Text('Valore nominale complessivo delle inserzioni attive',
                    style: TextStyle(color: appearance.textSecondary, fontSize: 12)),
                ]),
              ),
              if (_error != null) Card(child: Padding(padding: const EdgeInsets.all(12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))),
              if (!_loading && _rows.isEmpty && _error == null)
                const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Nessuna vendita attiva trovata.'))),
              ...visible.map((row) {
                final id = int.tryParse((row['codice_oggetto'] ?? row['id_oggetto'] ?? '').toString());
                final image = id == null ? null : _imageUrls[id];
                return ActiveSaleReportCard(
                  row: row,
                  imageUrl: image,
                  amountLabel: _money(row['prezzo_di_vendita'] ?? row['valore_nominale'] ?? row['importo_vendita']),
                  onTap: id == null ? null : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ObjectRuntimePage(title: 'Scheda oggetto', apiCode: 'OBJECT_MASTER', initialObjectCode: id),
                  )),
                );
              }),
              if (pageCount > 1)
                ReportPaginationControls(
                  currentPage: _page, pageSize: _pageSize, totalItems: _rows.length,
                  pageCount: pageCount, textColor: appearance.textSecondary,
                  onPrevious: _loading || _page == 0 ? null : () => setState(() => _page--),
                  onNext: _loading || _page + 1 >= pageCount ? null : () => setState(() => _page++),
                ),
              if (_loading) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close), label: const Text('CHIUDI E TORNA AL BLOCCO VENDITE'),
              ),
            ]),
    );
  }
}
