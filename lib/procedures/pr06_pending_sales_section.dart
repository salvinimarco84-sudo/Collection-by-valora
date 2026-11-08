part of '../main.dart';

extension _Pr06PendingSalesSection on _NewSalePageState {
  Widget _buildPr06PendingSalesSection(Color sectionColor) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VENDITE IN ATTESA: '+_pendingSales.length.toString(), style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_pendingSales.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text((i + 1).toString()+'. '+_pendingDescriptions[i]+' · €'+_pendingSales[i]['prezzo_di_vendita'].toString()),
              )),
              Text('Totale prezzi richiesti: €'+_pendingSales.fold<double>(0, (sum, row) => sum + ((row['prezzo_di_vendita'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)),
              OutlinedButton.icon(onPressed: _busy ? null : _saveSale, icon: const Icon(Icons.save_outlined), label: const Text('TERMINA E SALVA IL LOTTO ORA')),
            ])));

}
