part of '../main.dart';

/// Controlli di mercato e avvio della preparazione PR-18 per VALORA.
Widget _buildValoraMarketValuationControls(_ValoraServicePageState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        value: state._market,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: ValoraI18n.tr('Mercato di riferimento'),
        ),
        items: [
          DropdownMenuItem(value: 'ITALIA', child: Text(ValoraI18n.tr('Italia'))),
          DropdownMenuItem(value: 'EUROPA', child: Text(ValoraI18n.tr('Europa'))),
          DropdownMenuItem(value: 'MONDO', child: Text(ValoraI18n.tr('Mondo'))),
        ],
        onChanged: (value) => state.setState(() {
          state._market = value ?? 'ITALIA';
          state._prepared = null;
        }),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: state._preparing || state._selectedId == null
            ? null
            : state._prepareValuation,
        icon: state._preparing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.travel_explore),
        label: Text(
          state._preparing
              ? ValoraI18n.tr('Preparazione in corso…')
              : ValoraI18n.tr('PREPARA VALUTAZIONE'),
        ),
      ),
    ],
  );
}
