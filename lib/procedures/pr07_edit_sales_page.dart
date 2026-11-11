part of '../main.dart';

class Pr07EditSalesPage extends StatefulWidget {
  const Pr07EditSalesPage({super.key});

  @override
  State<Pr07EditSalesPage> createState() => _Pr07EditSalesPageState();
}

class _Pr07EditSalesPageState extends State<Pr07EditSalesPage>
    with Pr07EditSalesDataMixin {
  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final color = appearance.colorFor('VENDITE');
    final visibleSales = filteredPr07Sales;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PR-07 · MODIFICA VENDITA'),
        actions: [
          IconButton(
            tooltip: 'Aggiorna vendite aperte',
            onPressed: pr07Loading ? null : () => runPr07(loadPr07Sales),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        controller: pr07ScrollController,
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            'Modifica i dati di una vendita ancora APERTA. Le modifiche vengono applicate soltanto dopo anteprima, conferma dei dati e salvataggio definitivo.',
            style: TextStyle(color: appearance.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pr07SearchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Cerca per codice vendita, oggetto o descrizione',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Pulisci ricerca',
                onPressed: () {
                  pr07SearchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'VENDITE APERTE: ${pr07Sales.length}',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: pr07Loading ? null : () => runPr07(loadPr07Sales),
                icon: const Icon(Icons.sync),
                label: const Text('AGGIORNA'),
              ),
            ],
          ),
          if (pr07Loading) const LinearProgressIndicator(),
          if (pr07Error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(pr07Error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            ),
          if (visibleSales.isEmpty && !pr07Loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessuna vendita aperta corrisponde alla ricerca.'),
              ),
            ),
          ...visibleSales.map((sale) => Pr07SaleEditCard(
                row: sale,
                selected: pr07SelectedSale?['codice_vendita_aperta']?.toString() ==
                    sale['codice_vendita_aperta']?.toString(),
                priceController: pr07PriceController,
                notesController: pr07NotesController,
                modifyDate: pr07ModifyDate,
                modifyPrice: pr07ModifyPrice,
                modifyPlatforms: pr07ModifyPlatforms,
                modifyNotes: pr07ModifyNotes,
                selectedDate: pr07SelectedDate,
                platforms: pr07Platforms,
                selectedPlatformCodes: pr07SelectedPlatformCodes,
                loading: pr07Loading,
                onSelect: () => setState(() => selectPr07Sale(sale)),
                onModifyDate: (value) => setState(() => invalidatePr07Draft(() => pr07ModifyDate = value)),
                onModifyPrice: (value) => setState(() => invalidatePr07Draft(() => pr07ModifyPrice = value)),
                onModifyPlatforms: (value) => setState(() => invalidatePr07Draft(() => pr07ModifyPlatforms = value)),
                onModifyNotes: (value) => setState(() => invalidatePr07Draft(() => pr07ModifyNotes = value)),
                onDateTap: () => runPr07(pickPr07Date),
                onPlatformChanged: (id, checked) => setState(() {
                  if (checked) {
                    pr07SelectedPlatformCodes.add(id);
                  } else {
                    pr07SelectedPlatformCodes.remove(id);
                  }
                  invalidatePr07Draft();
                }),
                onDraftChanged: () => setState(invalidatePr07Draft),
              )),
          if (pr07Preview != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ANTEPRIMA MODIFICHE', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SelectableText(const JsonEncoder.withIndent('  ').convert(pr07Preview)),
                  ],
                ),
              ),
            ),
          ],
          if (pr07Preview != null && pr07Review == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: pr07Loading ? null : () => runPr07(confirmPr07Changes),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('CONFERMA I DATI'),
              ),
            ),
          if (pr07Review != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATI CONFERMATI · NESSUNA SCRITTURA ANCORA ESEGUITA',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Il riepilogo è stato confermato. Il database verrà modificato solo con il pulsante di salvataggio definitivo.'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: pr07Loading ? null : () => runPr07(savePr07Changes),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('CONFERMA DEFINITIVA E SALVA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (pr07Success != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(pr07Success!, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ),
            ),
          if (pr07SelectedSale != null && pr07Review == null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: pr07Loading ? null : () => runPr07(previewPr07Changes),
                icon: const Icon(Icons.preview_outlined),
                label: const Text('ANTEPRIMA MODIFICHE'),
              ),
            ),
          ],
          if (pr07LockHeld)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: pr07Loading ? null : () => runPr07(releasePr07Lock),
                icon: const Icon(Icons.lock_open),
                label: const Text('RILASCIA BLOCCO'),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('CHIUDI E TORNA AL BLOCCO VENDITE'),
          ),
        ],
      ),
    );
  }
}
