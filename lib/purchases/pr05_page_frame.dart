part of '../main.dart';

class Pr05EditPurchasePageFrame extends StatelessWidget {
  const Pr05EditPurchasePageFrame({
    super.key,
    required this.busy,
    required this.status,
    required this.children,
  });

  final bool busy;
  final String status;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PR-05 · MODIFICA ACQUISTO')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...children,
              if (busy) const LinearProgressIndicator(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(status),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
