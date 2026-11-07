import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({
    super.key,
    required this.authenticatedBuilder,
    required this.unauthenticatedBuilder,
  });

  final WidgetBuilder authenticatedBuilder;
  final WidgetBuilder unauthenticatedBuilder;

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) =>
            Supabase.instance.client.auth.currentSession != null
                ? authenticatedBuilder(context)
                : unauthenticatedBuilder(context),
      );
}
