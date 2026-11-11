part of '../main.dart';

/// Sezione mercato di riferimento, preparazione PR-18 e riepilogo del risultato.
extension _ValoraMarketValuationPresentation on _ValoraServicePageState {
  Widget buildMarketValuationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _market,
                    decoration: InputDecoration(border: const OutlineInputBorder(), labelText: ValoraI18n.tr('Mercato di riferimento')), 
                    items: [
                      DropdownMenuItem(value: 'ITALIA', child: Text(ValoraI18n.tr('Italia'))),
                      DropdownMenuItem(value: 'EUROPA', child: Text(ValoraI18n.tr('Europa'))),
                      DropdownMenuItem(value: 'MONDO', child: Text(ValoraI18n.tr('Mondo'))),
                    ],
                    onChanged: (value) => setState(() { _market = value ?? 'ITALIA'; _prepared = null; }),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _preparing || _selectedId == null ? null : _prepareValuation,
                    icon: _preparing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
                    label: Text(_preparing ? ValoraI18n.tr('Preparazione in corso…') : ValoraI18n.tr('PREPARA VALUTAZIONE')),
                  ),
                  if (_error != null) Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                  ),
                  if (_prepared != null) Padding(padding: const EdgeInsets.only(top: 12), child: FilledButton.icon(onPressed: _preparing ? null : _continueToPr06Valora, icon: const Icon(Icons.sell_outlined), label: const Text('VALUTAZIONE COMPLETATA · CONTINUA A PR06 VALORA'))),
                  if (_prepared != null) Card(
                    margin: const EdgeInsets.only(top: 16),
                    child: Padding(padding: const EdgeInsets.all(14), child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ValoraI18n.tr('ESITO PREPARAZIONE'), style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(ValoraI18n.tr('La richiesta è stata inviata al runtime. Questo esito non rappresenta ancora una valutazione di mercato definitiva né genera automaticamente inserzioni.')), 
                        const SizedBox(height: 8),
                        SelectableText(_prepared.toString()),
                      ],
                    )),
                  ),
      ],
    );
  }
}
