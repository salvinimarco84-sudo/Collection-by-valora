import 'package:flutter/material.dart';

/// Componente visuale autonomo della procedura PR-03.
class Pr03ClosureSection extends StatelessWidget {
  const Pr03ClosureSection({
    super.key,
    required this.searchController,
    required this.notesController,
    required this.pendingClosures,
    required this.selectedObject,
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
  final List<Map<String, dynamic>> pendingClosures;
  final Map<String, dynamic>? selectedObject;
  final bool hasSelectedObject;
  final String closeReason;
  final ValueChanged<String> onCloseReasonChanged;
  final bool loading;
  final Color sectionColor;
  final VoidCallback onSearch;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _field(searchController, 'Cerca oggetto per descrizione o codice'),
      FilledButton.icon(
        onPressed: loading ? null : onSearch,
        icon: const Icon(Icons.search),
        label: const Text('CERCA E SELEZIONA OGGETTO'),
      ),
      if (selectedObject != null) ...[
        const SizedBox(height: 12),
        _selectedObjectCard(selectedObject!),
      ],
      if (pendingClosures.isNotEmpty) ...[
        const SizedBox(height: 12),
        _pendingClosuresCard(),
      ],
      if (hasSelectedObject) ...[
        const SizedBox(height: 12),
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

  Widget _selectedObjectCard(Map<String, dynamic> object) {
    final id = object['codice_oggetto']?.toString() ?? 'Non disponibile';
    final description = (object['descrizione_oggetto'] ??
        object['descrizione'] ?? 'Descrizione non disponibile').toString();
    final status = (object['stato'] ?? object['stato_oggetto'] ?? 'Non indicato').toString();
    final quantity = (object['quantita'] ?? 'Non indicata').toString();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OGGETTO SELEZIONATO', style: TextStyle(
              color: sectionColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('$id · $description', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Stato: $status · Quantità: $quantity'),
          ],
        ),
      ),
    );
  }

  Widget _pendingClosuresCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHIUSURE IN ATTESA · ${pendingClosures.length}', style: TextStyle(
            color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final closure in pendingClosures)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${closure['codice_oggetto']} · ${closure['descrizione'] ?? 'Oggetto'} · ${closure['motivo_chiusura']}',
              ),
            ),
        ],
      ),
    ),
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
