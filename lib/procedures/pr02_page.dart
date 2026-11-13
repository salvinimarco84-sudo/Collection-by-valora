import 'package:flutter/material.dart';

/// Contenitore dedicato della procedura PR-02.
/// La composizione dei campi e i callback restano forniti dal workflow runtime.
class Pr02Page extends StatelessWidget {
  const Pr02Page({
    super.key,
    required this.sectionColor,
    required this.userLabel,
    required this.lockHeld,
    required this.loading,
    required this.content,
    required this.status,
    required this.scrollController,
  });

  final Color sectionColor;
  final String userLabel;
  final bool lockHeld;
  final bool loading;
  final Widget content;
  final String status;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PR-02 · MODIFICA OGGETTO')),
    body: ListView(
      controller: scrollController,
      key: const PageStorageKey<String>('pr02-dedicated-screen'),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'COLLECTION by VALORA\nUtente: $userLabel\n'
              '${lockHeld ? 'Blocco archivio: ATTIVO' : 'Blocco archivio: non acquisito'}',
              style: TextStyle(color: sectionColor),
            ),
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        content,
        if (status.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(status, style: const TextStyle(fontSize: 13)),
            ),
          ),
      ],
    ),
  );
}
