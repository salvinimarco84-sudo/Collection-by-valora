part of '../main.dart';

/// Azioni contestuali dell'oggetto selezionato e aggiornamento della collezione.
extension _ValoraCatalogActionsPresentation on _ValoraServicePageState {
  Widget buildValoraCatalogActionsSection(Map<String, dynamic>? selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_selectedId != null && selected != null) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _preparing ||
                    (selected['stato'] ?? '').toString().trim().toUpperCase() != 'DISPONIBILE'
                ? null
                : _openCatalogObjectForSale,
            icon: const Icon(Icons.sell_outlined),
            label: const Text('AVVIA PROCEDURA DI VENDITA'),
          ),
          const SizedBox(height: 6),
          Text(
            'La vendita è indipendente dalla valutazione. Se esiste già un valore di mercato, verrà proposto come prezzo iniziale; altrimenti potrai inserirlo nella procedura di vendita.',
            style: TextStyle(
              color: ValoraAppearance.instance.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _loadObjects,
          icon: const Icon(Icons.refresh),
          label: Text(ValoraI18n.tr('AGGIORNA OGGETTI')),
        ),
      ],
    );
  }
}
