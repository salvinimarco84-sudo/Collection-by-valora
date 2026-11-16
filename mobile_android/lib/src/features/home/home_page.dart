import 'package:flutter/material.dart';

import '../auth/auth_copy.dart';
import '../auth/auth_repository.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.repository});
  final AuthRepository repository;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(authText(context, 'home')),
      actions: [IconButton(
        tooltip: authText(context, 'logout'),
        onPressed: repository.signOut,
        icon: const Icon(Icons.logout),
      )],
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Image.asset(
          'valora_logo.png',
          width: 360,
          height: 360,
          fit: BoxFit.contain,
          semanticLabel: 'COLLECTION by VALORA',
        ),
      ),
    ),
  );
}
