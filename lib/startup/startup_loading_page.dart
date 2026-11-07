import 'package:flutter/material.dart';

class StartupLoadingPage extends StatelessWidget {
  const StartupLoadingPage({
    super.key,
    required this.accentColor,
  });

  final Color accentColor;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, color: accentColor, size: 64),
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
                  const SizedBox(height: 20),
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 14),
                  const Text(
                    'Inizializzazione dell’app in corso…',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
