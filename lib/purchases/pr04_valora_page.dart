part of '../main.dart';

/// Ingresso PR-04 dedicato al flusso VALORA. Non è registrato nel menu:
/// riceve esclusivamente metadati già confermati da PR-12.
class Pr04ValoraPurchasePage extends StatelessWidget {
  const Pr04ValoraPurchasePage({
    super.key,
    required this.initialMetadata,
    this.suggestedMarketValue,
  });

  final Map<String, dynamic> initialMetadata;
  final double? suggestedMarketValue;

  @override
  Widget build(BuildContext context) => NewPurchasePage(
    initialMetadata: initialMetadata,
    suggestedMarketValue: suggestedMarketValue,
    valoraMode: true,
  );
}

class Pr04ValoraPurchasePageFrame extends StatelessWidget {
  const Pr04ValoraPurchasePageFrame({
    super.key,
    required this.busy,
    required this.content,
  });

  final bool busy;
  final Widget content;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PR-04 VALORA · NUOVO ACQUISTO')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'RAMO VALORA · AMBIENTE TEST\n'
                    'Metadati già identificati. Completa i dati dell’acquisto. '
                    'Nessuna scrittura avviene prima della conferma finale.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (busy) const LinearProgressIndicator(),
              content,
            ],
          ),
        ),
      ),
    ),
  );
}

class Pr04ValoraPurchaseForm extends StatelessWidget {
  const Pr04ValoraPurchaseForm({
    super.key,
    required this.itemEditor,
    required this.dateLabel,
    required this.busy,
    required this.status,
    required this.onPickDate,
    required this.onPreview,
  });

  final Widget itemEditor;
  final String dateLabel;
  final bool busy;
  final String status;
  final VoidCallback onPickDate;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'OGGETTO IDENTIFICATO DA VALORA',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      const Text(
        'Controlla i metadati proposti e inserisci il costo realmente pagato. '
        'Il valore di mercato PR-18 è solo un riferimento e non viene usato come costo.',
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: const Icon(Icons.calendar_month_outlined),
          title: const Text('Data acquisto'),
          subtitle: Text(dateLabel),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: busy ? null : onPickDate,
        ),
      ),
      const SizedBox(height: 8),
      itemEditor,
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: busy ? null : onPreview,
        icon: const Icon(Icons.fact_check_outlined),
        label: const Text('CONTROLLA E MOSTRA RIEPILOGO'),
      ),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(status),
        ),
      ),
    ],
  );
}

class Pr04ValoraPurchaseReview extends StatelessWidget {
  const Pr04ValoraPurchaseReview({
    super.key,
    required this.description,
    required this.dateLabel,
    required this.purchaseCost,
    required this.marketValue,
    required this.preview,
    required this.busy,
    required this.onEdit,
    required this.onConfirm,
  });

  final String description;
  final String dateLabel;
  final double purchaseCost;
  final double? marketValue;
  final Map<String, dynamic> preview;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final count = preview['numero_acquisti']?.toString() ?? '1';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'RIEPILOGO E CONFERMA',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Data acquisto: $dateLabel'),
                Text('Costo effettivo: € ${purchaseCost.toStringAsFixed(2)}'),
                Text(
                  marketValue != null && marketValue! > 0
                      ? 'Valore di mercato PR-18: € ${marketValue!.toStringAsFixed(2)} (dato distinto)'
                      : 'Valore di mercato PR-18: non disponibile',
                ),
                const Divider(height: 22),
                Text('Anteprima runtime TEST: $count acquisto/i'),
                const Text(
                  'L’anteprima non ha eseguito scritture. Il salvataggio sarà richiesto solo dopo la conferma qui sotto.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: busy ? null : onConfirm,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('CONFERMA E REGISTRA ACQUISTO'),
        ),
        OutlinedButton(
          onPressed: busy ? null : onEdit,
          child: const Text('MODIFICA DATI'),
        ),
      ],
    );
  }
}
