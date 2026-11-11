part of '../main.dart';

/// Presentazione autonoma dell'esito PR-18 per la schermata VALORA.
Widget _buildValoraMarketValuationResult(_ValoraServicePageState state) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state._error != null)
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(state._error!, style: const TextStyle(color: Colors.redAccent)),
        ),
      if (state._prepared != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton.icon(
            onPressed: state._preparing ? null : state._continueToPr06Valora,
            icon: const Icon(Icons.sell_outlined),
            label: const Text('VALUTAZIONE COMPLETATA · CONTINUA A PR06 VALORA'),
          ),
        ),
      if (state._prepared != null)
        Card(
          margin: const EdgeInsets.only(top: 16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ValoraI18n.tr('ESITO PREPARAZIONE'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(ValoraI18n.tr('La richiesta è stata inviata al runtime. Questo esito non rappresenta ancora una valutazione di mercato definitiva né genera automaticamente inserzioni.')),
                const SizedBox(height: 8),
                SelectableText(state._prepared.toString()),
              ],
            ),
          ),
        ),
    ],
  );
}
