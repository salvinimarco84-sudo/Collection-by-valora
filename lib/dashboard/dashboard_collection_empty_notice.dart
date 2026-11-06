import 'package:flutter/material.dart';

/// Avviso mostrato quando non sono configurate categorie della collezione.
class DashboardCollectionEmptyNotice extends StatelessWidget {
  const DashboardCollectionEmptyNotice({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Nessuna categoria configurata nel master.',
          style: TextStyle(color: Colors.white70),
        ),
      );
}
