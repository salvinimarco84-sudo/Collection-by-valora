part of '../main.dart';

/// Esito PR-18, messaggi di errore e prosecuzione controllata verso PR-06 VALORA.
extension _ValoraMarketValuationResultPresentation on _ValoraServicePageState {
  Widget buildMarketValuationResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ),
        if (_prepared != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: FilledButton.icon(
              onPressed: _preparing ? null : _continueToPr06Valora,
              icon: const Icon(Icons.sell_outlined),
              label: const Text('VALUTAZIONE COMPLETATA · CONTINUA A PR06 VALORA'),
            ),
          ),
        if (_prepared != null)
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
                  SelectableText(_prepared.toString()),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
