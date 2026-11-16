import 'package:flutter/widgets.dart';

const authLocales = <Locale>[
  Locale('it'), Locale('en'), Locale('fr'), Locale('de'),
  Locale('es'), Locale('pt'), Locale('zh'), Locale('ja'),
];

const authCopy = <String, Map<String, String>>{
  'it': {'title':'COLLECTION by VALORA','email':'Email','password':'Password','signIn':'Accedi','signUp':'Crea account','forgot':'Password dimenticata?','resetSent':'Se l’indirizzo è registrato, riceverai un link per reimpostare la password.','checkEmail':'Controlla la tua email per confermare la registrazione.','error':'Operazione non riuscita.','newPassword':'Nuova password','savePassword':'Salva password','passwordUpdated':'Password aggiornata.','home':'Menu principale','logout':'Esci','config':'Configurazione TEST2 non impostata.'},
  'en': {'title':'COLLECTION by VALORA','email':'Email','password':'Password','signIn':'Sign in','signUp':'Create account','forgot':'Forgot password?','resetSent':'If the address is registered, you will receive a password reset link.','checkEmail':'Check your email to confirm your registration.','error':'The operation failed.','newPassword':'New password','savePassword':'Save password','passwordUpdated':'Password updated.','home':'Main menu','logout':'Sign out','config':'TEST2 configuration is missing.'},
  'fr': {'title':'COLLECTION by VALORA','email':'E-mail','password':'Mot de passe','signIn':'Se connecter','signUp':'Créer un compte','forgot':'Mot de passe oublié ?','resetSent':'Si cette adresse est enregistrée, vous recevrez un lien de réinitialisation.','checkEmail':'Vérifiez votre e-mail pour confirmer votre inscription.','error':'Échec de l’opération.','newPassword':'Nouveau mot de passe','savePassword':'Enregistrer','passwordUpdated':'Mot de passe mis à jour.','home':'Menu principal','logout':'Déconnexion','config':'Configuration TEST2 manquante.'},
  'de': {'title':'COLLECTION by VALORA','email':'E-Mail','password':'Passwort','signIn':'Anmelden','signUp':'Konto erstellen','forgot':'Passwort vergessen?','resetSent':'Wenn die Adresse registriert ist, erhalten Sie einen Link zum Zurücksetzen.','checkEmail':'Bitte E-Mail zur Bestätigung prüfen.','error':'Vorgang fehlgeschlagen.','newPassword':'Neues Passwort','savePassword':'Passwort speichern','passwordUpdated':'Passwort aktualisiert.','home':'Hauptmenü','logout':'Abmelden','config':'TEST2-Konfiguration fehlt.'},
  'es': {'title':'COLLECTION by VALORA','email':'Correo electrónico','password':'Contraseña','signIn':'Iniciar sesión','signUp':'Crear cuenta','forgot':'¿Olvidaste tu contraseña?','resetSent':'Si la dirección está registrada, recibirás un enlace para restablecerla.','checkEmail':'Revisa tu correo para confirmar el registro.','error':'La operación ha fallado.','newPassword':'Nueva contraseña','savePassword':'Guardar contraseña','passwordUpdated':'Contraseña actualizada.','home':'Menú principal','logout':'Cerrar sesión','config':'Falta la configuración de TEST2.'},
  'pt': {'title':'COLLECTION by VALORA','email':'E-mail','password':'Palavra-passe','signIn':'Entrar','signUp':'Criar conta','forgot':'Esqueceu a palavra-passe?','resetSent':'Se o endereço estiver registado, receberá um link de reposição.','checkEmail':'Verifique o e-mail para confirmar o registo.','error':'A operação falhou.','newPassword':'Nova palavra-passe','savePassword':'Guardar palavra-passe','passwordUpdated':'Palavra-passe atualizada.','home':'Menu principal','logout':'Sair','config':'Falta a configuração TEST2.'},
  'zh': {'title':'COLLECTION by VALORA','email':'电子邮件','password':'密码','signIn':'登录','signUp':'创建账户','forgot':'忘记密码？','resetSent':'如果该邮箱已注册，您将收到密码重置链接。','checkEmail':'请检查电子邮件以确认注册。','error':'操作失败。','newPassword':'新密码','savePassword':'保存密码','passwordUpdated':'密码已更新。','home':'主菜单','logout':'退出登录','config':'缺少 TEST2 配置。'},
  'ja': {'title':'COLLECTION by VALORA','email':'メールアドレス','password':'パスワード','signIn':'ログイン','signUp':'アカウントを作成','forgot':'パスワードをお忘れですか？','resetSent':'登録済みの場合、再設定リンクが届きます。','checkEmail':'登録確認メールを確認してください。','error':'処理に失敗しました。','newPassword':'新しいパスワード','savePassword':'保存','passwordUpdated':'パスワードを更新しました。','home':'メインメニュー','logout':'ログアウト','config':'TEST2 の設定がありません。'},
};

String authText(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  return authCopy[language]?[key] ?? authCopy['it']![key]!;
}
