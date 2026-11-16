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
    body: const Center(child: Text('COLLECTION by VALORA')),
  );
}
