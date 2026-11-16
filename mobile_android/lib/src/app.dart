import 'package:flutter/material.dart';

import 'features/auth/auth_copy.dart';
import 'features/auth/auth_gate.dart';

class ValoraApp extends StatelessWidget {
  const ValoraApp({super.key, this.configurationError = false});
  final bool configurationError;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    supportedLocales: authLocales,
    localeResolutionCallback: (locale, supported) {
      if (locale == null) return const Locale('it');
      return supported.firstWhere(
        (item) => item.languageCode == locale.languageCode,
        orElse: () => const Locale('it'),
      );
    },
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFB88924),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF111111),
      useMaterial3: true,
    ),
    home: configurationError
        ? _ConfigurationPage()
        : const AuthGate(),
  );
}

class _ConfigurationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(authText(context, 'config'), textAlign: TextAlign.center),
      ),
    ),
  );
}
