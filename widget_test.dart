import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection_by_valora/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-key',
    );
  });

  testWidgets('HOME di accesso e ambiente TEST sono visibili',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CollectionApp());
    await tester.pump();

    expect(find.text('COLLECTION by VALORA'), findsOneWidget);
    expect(find.text('ACCEDI'), findsOneWidget);
    expect(find.text('Beta tecnica · ambiente TEST'), findsOneWidget);
  });

  testWidgets('La schermata di accesso contiene email e password',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CollectionApp());
    await tester.pump();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('ACCEDI'), findsOneWidget);
  });

  testWidgets('La schermata iniziale non apre procedure prima dell accesso',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CollectionApp());
    await tester.pump();

    expect(find.text('ACCEDI'), findsOneWidget);
    expect(find.text('Nuovo acquisto'), findsNothing);
  });
}
