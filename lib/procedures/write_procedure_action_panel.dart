part of '../main.dart';

class WriteProcedureActionPanel extends StatelessWidget {
  const WriteProcedureActionPanel({
    super.key,
    required this.loading,
    required this.hasPreview,
    required this.dataConfirmed,
    required this.finalReady,
    required this.lockHeld,
    required this.onPreview,
    required this.onConfirm,
    required this.onSave,
    required this.onReleaseLock,
  });

  final bool loading;
  final bool hasPreview;
  final bool dataConfirmed;
  final bool finalReady;
  final bool lockHeld;
  final VoidCallback onPreview;
  final VoidCallback onConfirm;
  final VoidCallback onSave;
  final VoidCallback onReleaseLock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: loading ? null : onPreview,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('1 · CONTROLLA DATI E ANTEPRIMA'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: loading || !hasPreview ? null : onConfirm,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('2 · CONFERMO I DATI'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: loading || !dataConfirmed || !finalReady ? null : onSave,
          icon: const Icon(Icons.save_outlined),
          label: const Text('3 · CONFERMA DEFINITIVA E SALVA'),
        ),
        const SizedBox(height: 8),
        if (lockHeld)
          OutlinedButton.icon(
            onPressed: loading ? null : onReleaseLock,
            icon: const Icon(Icons.lock_open),
            label: const Text('RILASCIA BLOCCO ARCHIVIO'),
          ),
      ],
    );
  }
}
