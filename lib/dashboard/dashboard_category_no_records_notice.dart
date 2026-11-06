import 'package:flutter/material.dart';

/// Avviso mostrato quando una categoria non contiene record riconosciuti.
class DashboardCategoryNoRecordsNotice extends StatelessWidget {
  const DashboardCategoryNoRecordsNotice({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(4, 10, 4, 5),
        child: Text(
          'Nessun record riconosciuto in questa categoria.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      );
}
