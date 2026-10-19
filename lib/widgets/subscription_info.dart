import 'package:flutter/material.dart';

/// Informativa premium riutilizzabile. Da posizionare in fondo al modulo RM9
/// di registrazione, senza trasformarla in un consenso contrattuale.
class SubscriptionInfoButton extends StatelessWidget {
  const SubscriptionInfoButton({super.key, this.compact = false});

  final bool compact;

  static const String title = 'Abbonamento e funzioni premium';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(title),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VALORA (PR-19) e VALORE COLLEZIONE (PR-18) sono '
                    'servizi premium soggetti a un abbonamento a pagamento.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'VALORA permette la valutazione specialistica del singolo '
                    'oggetto e la preparazione di bozze di inserzione. '
                    'VALORE COLLEZIONE riguarda la stima complessiva della '
                    'collezione e i relativi confronti e report.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'La ricerca metadati PR-12 è una funzione distinta e non '
                    'è soggetta all’abbonamento VALORA. VALUTA ACQUISTO '
                    '(PR-20) è una funzione autonoma di analisi della '
                    'convenienza di un’offerta e non richiama il motore '
                    'premium di VALORA.',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Questa informativa descrive la distinzione tra le '
                    'funzioni. Non sostituisce le condizioni contrattuali, '
                    'il prezzo, la durata, il rinnovo o le modalità di '
                    'disdetta dell’abbonamento, che devono essere mostrati '
                    'separatamente prima dell’acquisto.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('CHIUDI'),
              ),
            ],
          ),
        ),
        icon: const Icon(Icons.workspace_premium_outlined),
        label: Text(compact ? 'ABBONAMENTO PREMIUM' : title.toUpperCase()),
      ),
    );
  }
}
