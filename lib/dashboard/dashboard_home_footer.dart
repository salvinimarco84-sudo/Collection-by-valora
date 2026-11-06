import 'package:flutter/material.dart';

/// Footer grafico della dashboard nella modalità lista.
class DashboardHomeFooter extends StatelessWidget {
  const DashboardHomeFooter({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Text(
          'COLLECTION by VALORA',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 11,
            letterSpacing: 1,
          ),
        ),
      );
}
