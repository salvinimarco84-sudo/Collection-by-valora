import 'package:flutter/material.dart';

class DashboardAssistantFab extends StatelessWidget {
  const DashboardAssistantFab({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
        heroTag: 'valora_global_assistant',
        onPressed: onPressed,
        icon: const Icon(Icons.mic_none),
        label: Text(label),
      );
}
