part of '../main.dart';

class Pr09CancelSalesPreviewCard extends StatelessWidget {
  const Pr09CancelSalesPreviewCard({
    super.key,
    required this.lines,
    required this.reviewReady,
    required this.loading,
    required this.onConfirmData,
    required this.onSave,
    required this.onCancel,
  });

  final List<String> lines;
  final bool reviewReady;
  final bool loading;
  final VoidCallback onConfirmData;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final appearance = ValoraAppearance.instance;
    final sectionColor = appearance.colorFor('VENDITE');
    return Card(
      color: appearance.card,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fact_check_outlined, color: sectionColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reviewReady ? 'RIEPILOGO CONFERMATO' : 'ANTEPRIMA ANNULLAMENTI',
                    style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(line),
            )),
            const Divider(height: 20),
            const Text(
              'RETTIFICA DI CASSA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Per ogni vendita annullata verrà registrata un’USCITA compensativa collegata alla vendita originaria. L’incasso precedente resterà nello storico e non verrà cancellato.',
              style: TextStyle(color: appearance.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              'La prima opzione crea un nuovo ciclo di vendita. La seconda riporta l’oggetto in COLLEZIONE con stato DISPONIBILE.',
              style: TextStyle(color: appearance.textSecondary, height: 1.35),
            ),
            const SizedBox(height: 12),
            if (!reviewReady)
              FilledButton.icon(
                onPressed: loading ? null : onConfirmData,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('CONFERMO I DATI'),
              )
            else ...[
              const Row(
                children: [
                  Icon(Icons.verified, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dati confermati. Nessuna modifica è stata ancora salvata.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: loading ? null : onSave,
                icon: const Icon(Icons.save_outlined),
                label: const Text('CONFERMA DEFINITIVA E SALVA'),
              ),
            ],
            TextButton(
              onPressed: loading ? null : onCancel,
              child: const Text('ANNULLA OPERAZIONE E MODIFICA SELEZIONE'),
            ),
          ],
        ),
      ),
    );
  }
}
