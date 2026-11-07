import 'package:flutter/material.dart';

class StartupFailurePage extends StatelessWidget {
  const StartupFailurePage({
    super.key,
    required this.error,
    required this.accentColor,
  });

  final String error;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: accentColor, size: 64),
                    const SizedBox(height: 20),
                    Text(
                      'COLLECTION by VALORA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Avvio non completato. Il dettaglio seguente aiuta a individuare la causa.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      error,
                      style: const TextStyle(color: Color(0xFFE35D5D)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
