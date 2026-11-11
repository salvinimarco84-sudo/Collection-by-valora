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
                  buildMarketValuationResultSection(),
      ],
    );
  }
}
