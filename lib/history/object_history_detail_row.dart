import 'package:flutter/material.dart';

/// Riga compatta usata per mostrare un dettaglio nella cronologia dell'oggetto.
class ObjectHistoryDetailRow extends StatelessWidget {
  const ObjectHistoryDetailRow({
    super.key,
    required this.label,
    required this.value,
    required this.labelColor,
  });

  final String label;
  final String value;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 1),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      );
}
