part of '../main.dart';

/// Mercato personale letto dal profilo e avvio della preparazione PR-18.
Widget _buildValoraMarketValuationControls(_ValoraServicePageState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 14),
      InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: ValoraI18n.tr('Mercato di riferimento'),
          suffixIcon: state._marketLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : null,
        ),
        child: Text(
          state._marketLoading
              ? ValoraI18n.tr('Caricamento dal profilo utente…')
              : state._market.isNotEmpty
                  ? state._market
                  : ValoraI18n.tr('Mercato non configurato'),
        ),
      ),
      if (state._marketError != null) ...[
        const SizedBox(height: 8),
        Text(state._marketError!, style: const TextStyle(color: Colors.red)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: state._marketLoading ? null : state._loadUserMarket,
            icon: const Icon(Icons.refresh),
            label: Text(ValoraI18n.tr('RICARICA PROFILO')),
          ),
        ),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: state._preparing || state._selectedId == null ||
                state._marketLoading || state._market.isEmpty
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
