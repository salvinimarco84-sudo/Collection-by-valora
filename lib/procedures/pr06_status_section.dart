part of '../main.dart';

extension _Pr06StatusSection on _NewSalePageState {
  List<Widget> _buildPr06StatusSection(Color sectionColor) => [
        OutlinedButton.icon(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
          label: const Text('AGGIORNA OGGETTI DISPONIBILI'),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _status.contains('non riuscito') ||
                          _status.contains('non confermato')
                      ? Icons.error_outline
                      : Icons.info_outline,
                  color: sectionColor,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_status)),
              ],
            ),
          ),
        ),
      ];
}
