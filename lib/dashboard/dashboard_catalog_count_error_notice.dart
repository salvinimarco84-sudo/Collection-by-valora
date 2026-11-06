import 'package:flutter/material.dart';

class DashboardCatalogCountErrorNotice extends StatelessWidget {
  const DashboardCatalogCountErrorNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
        ),
      );
}
