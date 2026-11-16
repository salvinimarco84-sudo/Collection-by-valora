import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_copy.dart';
import 'auth_repository.dart';

class PasswordUpdatePage extends StatefulWidget {
  const PasswordUpdatePage({super.key, required this.repository, required this.onCompleted});
  final AuthRepository repository;
  final VoidCallback onCompleted;
  @override
  State<PasswordUpdatePage> createState() => _PasswordUpdatePageState();
}

class _PasswordUpdatePageState extends State<PasswordUpdatePage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  String? _message;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _password.text;
    if (value.length < 8 ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value) ||
        !value.codeUnits.any((unit) =>
            (unit >= 33 && unit <= 47) ||
            (unit >= 58 && unit <= 64) ||
            (unit >= 91 && unit <= 96) ||
            (unit >= 123 && unit <= 126))) {
      setState(() => _message = authText(context, 'passwordRequirements'));
      return;
    }
    if (value != _confirm.text) {
      setState(() => _message = authText(context, 'passwordMismatch'));
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await widget.repository.updatePassword(value);
      if (mounted) {
        setState(() => _message = authText(context, 'passwordUpdated'));
        widget.onCompleted();
      }
    } on AuthException catch (error) {
      if (mounted) {
        final key = error.code == 'same_password' ? 'passwordSame' :
            (error.statusCode == '422' ? 'passwordRequirements' : 'error');
        setState(() => _message = authText(context, key));
      }
    } catch (_) {
      if (mounted) setState(() => _message = authText(context, 'error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(authText(context, 'newPassword'))),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(24), children: [
        TextField(
          controller: _password,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: authText(context, 'newPassword'),
            suffixIcon: IconButton(
              tooltip: authText(context, _showPassword ? 'hidePassword' : 'showPassword'),
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirm,
          obscureText: !_showConfirm,
          decoration: InputDecoration(
            labelText: authText(context, 'password'),
            suffixIcon: IconButton(
              tooltip: authText(context, _showConfirm ? 'hidePassword' : 'showPassword'),
              onPressed: () => setState(() => _showConfirm = !_showConfirm),
              icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _save, child: Text(authText(context, 'savePassword'))),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!)),
      ]),
    )),
  );
}
