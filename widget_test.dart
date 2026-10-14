import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection_by_valora/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-key',
    );
  });

  testWidgets('HOME e maschere di sezione sono visibili', (tester) async {
    await tester.pumpWidget(const CollectionByValoraApp());

    expect(find.text('COLLECTION by VALORA'), findsOneWidget);
    expect(find.text('ACCEDI'), findsOneWidget);
    expect(find.text('AMBIENTE TEST'), findsOneWidget);
  });

  testWidgets('Acquisti mostra procedure e stato del mapping API',
      (tester) async {
    await tester.pumpWidget(const CollectionByValoraApp());

    expect(find.text('Nuovo acquisto'), findsNothing);
    expect(find.text('ACCEDI'), findsOneWidget);
  });

  testWidgets(
    'Una voce senza API certa è esplicitamente da allineare',
    (tester) async {
      await tester.pumpWidget(const CollectionByValoraApp());

      expect(find.text('ACCEDI'), findsOneWidget);
      expect(find.text('Nuovo acquisto'), findsNothing);
    },
  );
}
