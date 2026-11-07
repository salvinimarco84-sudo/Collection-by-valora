import 'package:flutter/material.dart';

/// Seleziona il contenuto della dashboard senza costruire il layout inattivo.
class DashboardHomeContent extends StatelessWidget {
  const DashboardHomeContent({
    super.key,
    required this.useBlockLayout,
    required this.blockContentBuilder,
    required this.listContentBuilder,
  });

  final bool useBlockLayout;
  final Widget Function() blockContentBuilder;
  final Widget Function() listContentBuilder;

  @override
  Widget build(BuildContext context) => useBlockLayout
      ? blockContentBuilder()
      : listContentBuilder();
}
