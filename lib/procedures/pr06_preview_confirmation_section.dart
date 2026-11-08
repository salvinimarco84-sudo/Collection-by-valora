part of '../main.dart';

extension _Pr06PreviewConfirmationSection on _NewSalePageState {
  Widget _buildPr06PreviewConfirmationSection(Color sectionColor) =>
      Card(
        color: ValoraAppearance.instance.card,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '3. RIEPILOGO PRIMA DEL SALVATAGGIO',
                style: TextStyle(
                  color: sectionColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                const JsonEncoder.withIndent('  ').convert(_preview),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                title: Text(
                  _lotMode
                      ? 'Confermo oggetti, prezzo totale del lotto e piattaforme.'
                      : 'Confermo che oggetto, prezzo e piattaforme sono corretti.',
                ),
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _confirmed = v == true),
              ),
              FilledButton.icon(
                onPressed: _busy || !_confirmed ? null : _saveSale,
                icon: const Icon(Icons.save_outlined),
                label: const Text('SALVA LOTTO'),
              ),
            ],
          ),
        ),
      );
}
