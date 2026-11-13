import 'package:flutter/material.dart';

/// Dedicated PR-01 page shell. The form is supplied by the PR-01 mask;
/// runtime callbacks remain connected to the existing PR-01 procedure logic.
class Pr01Page extends StatelessWidget {
  const Pr01Page({
    super.key,
    required this.title,
    required this.sectionColor,
    required this.userLabel,
    required this.lockHeld,
    required this.loading,
    required this.status,
    required this.form,
    required this.onSave,
    required this.onReleaseLock,
  });

  final String title;
  final Color sectionColor;
  final String userLabel;
  final bool lockHeld;
  final bool loading;
  final String status;
  final Widget form;
  final VoidCallback? onSave;
  final VoidCallback? onReleaseLock;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'COLLECTION by VALORA\nUtente: $userLabel\n${lockHeld ? 'Blocco archivio: ATTIVO' : 'Blocco archivio: non acquisito'}',
              style: TextStyle(color: sectionColor),
            ),
          ),
        ),
        form,
        if (status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(status),
          ),
        FilledButton.icon(
          onPressed: onSave,
          icon: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(loading ? 'SALVATAGGIO IN CORSO…' : 'CONFERMA E SALVA OGGETTO'),
        ),
        if (lockHeld) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onReleaseLock,
            icon: const Icon(Icons.lock_open),
            label: const Text('RILASCIA BLOCCO ARCHIVIO'),
          ),
        ],
      ],
    ),
  );
}
