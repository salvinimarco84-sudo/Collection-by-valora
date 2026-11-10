part of '../main.dart';

class Pr06NewSalePageFrame extends StatelessWidget {
  const Pr06NewSalePageFrame({
    super.key,
    required this.children,
    this.title = 'PR-06 · NUOVA VENDITA',
  });

  final List<Widget> children;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: children,
          ),
        ),
      ),
    ),
  );
}
