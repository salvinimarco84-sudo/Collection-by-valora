import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_copy.dart';
import 'auth_repository.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.repository});
  final AuthRepository repository;
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validPassword(String value) =>
      value.length >= 8 &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  Future<void> _run(Future<void> Function() action, String successKey) async {
    setState(() { _busy = true; _message = null; });
    try {
      await action();
      if (mounted) setState(() => _message = authText(context, successKey));
    } on AuthException {
      if (mounted) setState(() => _message = authText(context, 'error'));
    } catch (_) {
      if (mounted) setState(() => _message = authText(context, 'error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || email.length < 5 ||
        (_register && !_validPassword(password))) {
      setState(() => _message = authText(context, 'error'));
      return;
    }
    if (_register) {
      await _run(() => widget.repository.signUp(email: email, password: password), 'checkEmail');
    } else {
      setState(() { _busy = true; _message = null; });
      try {
        await widget.repository.signIn(email: email, password: password);
      } on AuthException {
        if (mounted) setState(() => _message = authText(context, 'error'));
      } catch (_) {
        if (mounted) setState(() => _message = authText(context, 'error'));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@') || email.length < 5) {
      setState(() => _message = authText(context, 'error'));
      return;
    }
    await _run(() => widget.repository.requestPasswordReset(email), 'resetSent');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(authText(context, 'title'))),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
        Center(
          child: Image.asset(
            'valora_logo.png',
            height: 190,
            fit: BoxFit.contain,
            semanticLabel: 'COLLECTION by VALORA',
          ),
        ),
        const SizedBox(height: 20),
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: InputDecoration(labelText: authText(context, 'email'))),
        const SizedBox(height: 16),
        TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: authText(context, 'password'))),
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const CircularProgressIndicator() : Text(authText(context, _register ? 'signUp' : 'signIn'))),
        TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _message = null; }), child: Text(authText(context, _register ? 'signIn' : 'signUp'))),
        if (!_register) TextButton(onPressed: _busy ? null : _forgot, child: Text(authText(context, 'forgot'))),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, textAlign: TextAlign.center)),
      ]),
    )),
  );
}
