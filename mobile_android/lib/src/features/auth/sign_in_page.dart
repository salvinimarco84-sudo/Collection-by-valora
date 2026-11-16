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
  bool _accountMayAlreadyExist = false;
  bool _showPassword = false;
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
    } on AuthException catch (error) {
      if (!mounted) return;
      final key = error.statusCode == '429' ? 'rateLimited' : 'error';
      setState(() => _message = authText(context, key));
    } catch (_) {
      if (mounted) setState(() => _message = authText(context, 'error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || email.length < 5) {
      setState(() => _message = authText(context, 'invalidEmail'));
      return;
    }
    if (_register && !_validPassword(password)) {
      setState(() => _message = authText(context, 'passwordRequirements'));
      return;
    }
    if (_register) {
      setState(() { _busy = true; _message = null; _accountMayAlreadyExist = false; });
      try {
        final outcome = await widget.repository.signUp(email: email, password: password);
        if (!mounted) return;
        setState(() {
          _accountMayAlreadyExist = outcome == SignUpOutcome.accountMayAlreadyExist;
          _message = authText(
            context,
            _accountMayAlreadyExist ? 'accountMayExist' : 'checkEmail',
          );
        });
      } on AuthException catch (error) {
        if (mounted) {
          setState(() => _message = authText(
            context,
            error.statusCode == '429' ? 'rateLimited' : 'error',
          ));
        }
      } catch (_) {
        if (mounted) setState(() => _message = authText(context, 'error'));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    } else {
      setState(() { _busy = true; _message = null; });
      try {
        await widget.repository.signIn(email: email, password: password);
      } on AuthException catch (error) {
        if (mounted) {
          setState(() => _message = authText(
            context,
            error.statusCode == '429' ? 'rateLimited' : 'error',
          ));
        }
      } catch (_) {
        if (mounted) setState(() => _message = authText(context, 'error'));
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  Future<void> _resendConfirmation() async {
    final email = _email.text.trim();
    if (!email.contains('@') || email.length < 5) {
      setState(() => _message = authText(context, 'invalidEmail'));
      return;
    }
    await _run(
      () => widget.repository.resendSignupConfirmation(email),
      'confirmationResent',
    );
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@') || email.length < 5) {
      setState(() => _message = authText(context, 'invalidEmail'));
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
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onChanged: (_) {
            if (_accountMayAlreadyExist) {
              setState(() { _accountMayAlreadyExist = false; _message = null; });
            }
          },
          decoration: InputDecoration(labelText: authText(context, 'email')),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: authText(context, 'password'),
            suffixIcon: IconButton(
              tooltip: authText(context, _showPassword ? 'hidePassword' : 'showPassword'),
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const CircularProgressIndicator()
              : Text(authText(context, _register ? 'signUp' : 'signIn')),
        ),
        TextButton(
          onPressed: _busy ? null : () => setState(() {
            _register = !_register;
            _message = null;
            _accountMayAlreadyExist = false;
          }),
          child: Text(authText(context, _register ? 'signIn' : 'signUp')),
        ),
        if (_register)
          TextButton(
            onPressed: _busy ? null : _resendConfirmation,
            child: Text(authText(context, 'resendConfirmation')),
          ),
        if (!_register)
          TextButton(
            onPressed: _busy ? null : _forgot,
            child: Text(authText(context, 'forgot')),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_message!, textAlign: TextAlign.center),
          ),
      ]),
    )),
  );
}
