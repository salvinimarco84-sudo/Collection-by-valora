import 'package:flutter/material.dart';

/// Componente visuale autonomo della procedura PR-03.
class Pr03ClosureSection extends StatelessWidget {
  const Pr03ClosureSection({
    super.key,
    required this.searchController,
    required this.notesController,
    required this.pendingCount,
    required this.hasSelectedObject,
    required this.closeReason,
    required this.onCloseReasonChanged,
    required this.loading,
    required this.sectionColor,
    required this.onSearch,
    required this.onConfirm,
  });

  final TextEditingController searchController;
  final TextEditingController notesController;
  final int pendingCount;
  final bool hasSelectedObject;
  final String closeReason;
  final ValueChanged<String> onCloseReasonChanged;
  final bool loading;
  final Color sectionColor;
  final VoidCallback onSearch;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _field(searchController, 'Cerca oggetto per descrizione o codice'),
      FilledButton.icon(
        onPressed: loading ? null : onSearch,
        icon: const Icon(Icons.search),
        label: const Text('CERCA E SELEZIONA OGGETTO'),
      ),
      if (pendingCount > 0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Chiusure confermate in attesa: $pendingCount',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold),
          ),
        ),
      if (hasSelectedObject) ...[
        _dropdown(
          'Motivo chiusura',
          closeReason,
          const ['SMARRITO', 'DISTRUTTO', 'DATO VIA'],
          (value) {
            if (value != null) onCloseReasonChanged(value);
          },
        ),
        _field(notesController, 'Note', lines: 2),
        FilledButton.icon(
          onPressed: loading ? null : onConfirm,
          icon: const Icon(Icons.verified_outlined),
          label: const Text('CONFERMA CHIUSURA'),
        ),
      ],
    ],
  );

  Widget _field(TextEditingController controller, String label, {int lines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _dropdown(
    String label,
    String current,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          value: current,
          decoration: InputDecoration(labelText: label),
          items: options
              .map((value) => DropdownMenuItem(value: value, child: Text(value)))
              .toList(),
          onChanged: onChanged,
        ),
      );
}
