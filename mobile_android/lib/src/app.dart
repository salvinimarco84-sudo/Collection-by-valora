import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/auth_config.dart';

const supportedLocales = <Locale>[
  Locale('it'), Locale('en'), Locale('fr'), Locale('de'),
  Locale('es'), Locale('pt'), Locale('zh'), Locale('ja'),
];

const _copy = <String, Map<String, String>>{
  'it': {'title':'COLLECTION by VALORA','email':'Email','password':'Password','signIn':'Accedi','signUp':'Crea account','forgot':'Password dimenticata?','resetSent':'Se l’indirizzo è registrato, riceverai un link per reimpostare la password.','missingConfig':'Configurazione TEST2 non impostata.','checkEmail':'Controlla la tua email per confermare la registrazione.','error':'Operazione non riuscita.'},
  'en': {'title':'COLLECTION by VALORA','email':'Email','password':'Password','signIn':'Sign in','signUp':'Create account','forgot':'Forgot password?','resetSent':'If the address is registered, you will receive a password reset link.','missingConfig':'TEST2 configuration is missing.','checkEmail':'Check your email to confirm your registration.','error':'The operation failed.'},
  'fr': {'title':'COLLECTION by VALORA','email':'E-mail','password':'Mot de passe','signIn':'Se connecter','signUp':'Créer un compte','forgot':'Mot de passe oublié ?','resetSent':'Si cette adresse est enregistrée, vous recevrez un lien de réinitialisation.','missingConfig':'Configuration TEST2 manquante.','checkEmail':'Vérifiez votre e-mail pour confirmer votre inscription.','error':'Échec de l’opération.'},
  'de': {'title':'COLLECTION by VALORA','email':'E-Mail','password':'Passwort','signIn':'Anmelden','signUp':'Konto erstellen','forgot':'Passwort vergessen?','resetSent':'Wenn die Adresse registriert ist, erhalten Sie einen Link zum Zurücksetzen.','missingConfig':'TEST2-Konfiguration fehlt.','checkEmail':'Bitte E-Mail zur Bestätigung prüfen.','error':'Vorgang fehlgeschlagen.'},
  'es': {'title':'COLLECTION by VALORA','email':'Correo electrónico','password':'Contraseña','signIn':'Iniciar sesión','signUp':'Crear cuenta','forgot':'¿Olvidaste tu contraseña?','resetSent':'Si la dirección está registrada, recibirás un enlace para restablecerla.','missingConfig':'Falta la configuración de TEST2.','checkEmail':'Revisa tu correo para confirmar el registro.','error':'La operación ha fallado.'},
  'pt': {'title':'COLLECTION by VALORA','email':'E-mail','password':'Palavra-passe','signIn':'Entrar','signUp':'Criar conta','forgot':'Esqueceu a palavra-passe?','resetSent':'Se o endereço estiver registado, receberá um link de reposição.','missingConfig':'Falta a configuração TEST2.','checkEmail':'Verifique o e-mail para confirmar o registo.','error':'A operação falhou.'},
  'zh': {'title':'COLLECTION by VALORA','email':'电子邮件','password':'密码','signIn':'登录','signUp':'创建账户','forgot':'忘记密码？','resetSent':'如果该邮箱已注册，您将收到密码重置链接。','missingConfig':'缺少 TEST2 配置。','checkEmail':'请检查电子邮件以确认注册。','error':'操作失败。'},
  'ja': {'title':'COLLECTION by VALORA','email':'メールアドレス','password':'パスワード','signIn':'ログイン','signUp':'アカウントを作成','forgot':'パスワードをお忘れですか？','resetSent':'登録済みの場合、再設定リンクが届きます。','missingConfig':'TEST2 の設定がありません。','checkEmail':'登録確認メールを確認してください。','error':'処理に失敗しました。'},
};

class ValoraApp extends StatelessWidget {
  const ValoraApp({super.key, this.configurationError = false});
  final bool configurationError;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    supportedLocales: supportedLocales,
    localeResolutionCallback: (locale, supported) {
      if (locale == null) return const Locale('it');
      return supported.firstWhere(
        (item) => item.languageCode == locale.languageCode,
        orElse: () => const Locale('it'),
      );
    },
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB88924), brightness: Brightness.dark), scaffoldBackgroundColor: const Color(0xFF111111), useMaterial3: true),
    home: configurationError ? const _ConfigurationPage() : const _AuthPage(),
  );
}

class _ConfigurationPage extends StatelessWidget {
  const _ConfigurationPage();
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(body: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(_copy[lang]?['missingConfig'] ?? _copy['it']!['missingConfig']!, textAlign: TextAlign.center),
    )));
  }
}

class _AuthPage extends StatefulWidget {
  const _AuthPage();
  @override
  State<_AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<_AuthPage> {
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

  String get _lang => Localizations.localeOf(context).languageCode;
  String tr(String key) => _copy[_lang]?[key] ?? _copy['it']![key]!;

  bool _validPassword(String value) =>
      value.length >= 8 &&
      RegExp(r'[a-z]').hasMatch(value) &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(value);

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = tr('error'));
      return;
    }
    if (_register && !_validPassword(password)) {
      setState(() => _message = tr('error'));
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        await auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: ValoraAuthConfig.callbackUrl,
        );
        if (mounted) setState(() => _message = tr('checkEmail'));
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException {
      if (mounted) setState(() => _message = tr('error'));
    } catch (_) {
      if (mounted) setState(() => _message = tr('error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _message = tr('error'));
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: ValoraAuthConfig.callbackUrl,
      );
      if (mounted) setState(() => _message = tr('resetSent'));
    } on AuthException {
      if (mounted) setState(() => _message = tr('error'));
    } catch (_) {
      if (mounted) setState(() => _message = tr('error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('title'))),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
        TextField(controller: _email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: InputDecoration(labelText: tr('email'))),
        const SizedBox(height: 16),
        TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: tr('password'))),
        const SizedBox(height: 24),
        FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const CircularProgressIndicator() : Text(tr(_register ? 'signUp' : 'signIn'))),
        TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _message = null; }), child: Text(tr(_register ? 'signIn' : 'signUp'))),
        if (!_register) TextButton(onPressed: _busy ? null : _sendPasswordReset, child: Text(tr('forgot'))),
        if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, textAlign: TextAlign.center)),
      ]),
    )),
  );
}
