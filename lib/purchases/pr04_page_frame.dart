part of '../main.dart';

class Pr04PurchasePageFrame extends StatelessWidget {
  const Pr04PurchasePageFrame({
    super.key,
    required this.step,
    required this.busy,
    required this.color,
    required this.status,
    required this.content,
  });

  final int step;
  final bool busy;
  final Color color;
  final String status;
  final Widget content;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PR-04 · NUOVO ACQUISTO')),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('AMBIENTE TEST · Nessun acquisto viene registrato senza conferma esplicita. Dopo il salvataggio è obbligatoria la rilettura di verifica.'),
        )),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: (step + 1) / 5, minHeight: 5, color: color),
        ),
        const SizedBox(height: 8),
        Text('PASSAGGIO ' + (step + 1).toString() + ' DI 5',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 14),
        if (busy) const LinearProgressIndicator(),
        content,
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(12), child: Text(status))),
      ]),
    ))),
  );
}
