part of '../main.dart';

/// Conferma esplicita del passaggio dal candidato PR-12 a PR-04 VALORA.
Widget _buildValoraCatalogIntakeReviewDialog(
  BuildContext dialogContext,
  String valuationText,
) {
  return AlertDialog(
    title: const Text('Valutazione PR18'),
    content: Text('$valuationText\\n\\nVuoi procedere con PR-04 Nuovo Acquisto?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(false),
        child: const Text('ANNULLA'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(true),
        child: const Text('PROCEDI A PR-04'),
      ),
    ],
  );
}
