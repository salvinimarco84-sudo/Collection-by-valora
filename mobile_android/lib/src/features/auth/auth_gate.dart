import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';
import 'password_update_page.dart';
import 'sign_in_page.dart';
import '../home/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthRepository _repository;
  StreamSubscription<AuthState>? _subscription;
  bool _passwordRecovery = false;

  @override
  void initState() {
    super.initState();
    _repository = AuthRepository(Supabase.instance.client);
    _subscription = _repository.changes.listen((state) {
      if (!mounted) return;
      setState(() {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _passwordRecovery = true;
        } else if (state.event == AuthChangeEvent.signedOut) {
          _passwordRecovery = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_passwordRecovery) {
      return PasswordUpdatePage(
        repository: _repository,
        onCompleted: () => setState(() => _passwordRecovery = false),
      );
    }
    if (_repository.currentSession == null) {
      return SignInPage(repository: _repository);
    }
    return HomePage(repository: _repository);
  }
}
