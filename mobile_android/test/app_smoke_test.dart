import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valora_mobile/src/app.dart';
import 'package:valora_mobile/src/features/auth/auth_copy.dart';
import 'package:valora_mobile/src/features/auth/auth_repository.dart';
import 'package:valora_mobile/src/features/auth/sign_in_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('TEST2 configuration screen renders', (tester) async {
    await tester.pumpWidget(const ValoraApp(configurationError: true));

    expect(find.text('TEST2 configuration is missing.'), findsOneWidget);
  });

  testWidgets('MaterialLocalizations are available at the app root', (tester) async {
    await tester.pumpWidget(const ValoraApp(configurationError: true));

    final context = tester.element(find.text('TEST2 configuration is missing.'));
    expect(MaterialLocalizations.of(context).backButtonTooltip, isNotEmpty);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(
      app.localizationsDelegates,
      contains(GlobalMaterialLocalizations.delegate),
    );
    expect(
      app.localizationsDelegates,
      contains(GlobalWidgetsLocalizations.delegate),
    );
    expect(
      app.localizationsDelegates,
      contains(GlobalCupertinoLocalizations.delegate),
    );
  });


  testWidgets('signup screen always exposes confirmation resend', (tester) async {
    final client = SupabaseClient('https://example.supabase.co', 'test-anon-key');
    await tester.pumpWidget(MaterialApp(
      home: SignInPage(repository: AuthRepository(client)),
    ));

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Resend confirmation email'), findsOneWidget);
  });

  test('the eight initial interface languages remain supported', () {
    expect(
      authLocales.map((locale) => locale.languageCode).toList(),
      ['it', 'en', 'fr', 'de', 'es', 'pt', 'zh', 'ja'],
    );
  });

  test('signup recovery messages are present in all eight languages', () {
    const requiredKeys = [
      'invalidEmail',
      'passwordRequirements',
      'accountMayExist',
      'resendConfirmation',
      'confirmationResent',
      'rateLimited',
    ];
    for (final locale in authLocales) {
      final copy = authCopy[locale.languageCode]!;
      for (final key in requiredKeys) {
        expect(copy[key], isNotNull, reason: '${locale.languageCode}: $key');
        expect(copy[key], isNotEmpty, reason: '${locale.languageCode}: $key');
      }
    }
  });

  test('the VALORA brand logo is bundled as an application asset', () async {
    final logo = await rootBundle.load('valora_logo.png');
    expect(logo.lengthInBytes, greaterThan(0));
  });
}
