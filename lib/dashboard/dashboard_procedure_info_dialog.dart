import 'package:flutter/material.dart';

/// Finestra informativa riutilizzabile per la descrizione di una procedura.
class DashboardProcedureInfoDialog extends StatelessWidget {
  const DashboardProcedureInfoDialog({
    super.key,
    required this.title,
    required this.description,
    required this.closeLabel,
    required this.onClose,
  });

  final String title;
  final String description;
  final String closeLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(description)],
        ),
        actions: [
          TextButton(onPressed: onClose, child: Text(closeLabel)),
        ],
      );
}
