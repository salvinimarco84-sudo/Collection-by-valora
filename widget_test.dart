import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection_by_valora/main.dart';

void main() {
TestWidgetsFlutterBinding.ensureInitialized();

setUpAll(() async {
SharedPreferences.setMockInitialValues({});

await Supabase.initialize(
  url: 'https://example.supabase.co',
  anonKey: 'test-key',
);

});

testWidgets('La schermata di accesso è visibile', (tester) async {
await tester.pumpWidget(const CollectionValoraApp());
await tester.pump();

expect(find.text('COLLECTION by VALORA'), findsOneWidget);
expect(find.text('ACCEDI'), findsOneWidget);
expect(
  find.text('AMBIENTE TEST'),
  findsOneWidget,
);

});

testWidgets('La schermata di accesso contiene i campi necessari',
(tester) async {
await tester.pumpWidget(const CollectionValoraApp());
await tester.pump();

expect(find.byType(TextField), findsNWidgets(2));
expect(find.text('Email'), findsOneWidget);
expect(find.text('Password'), findsOneWidget);
expect(find.text('ACCEDI'), findsOneWidget);

});

testWidgets('Le procedure operative non sono accessibili senza login',
(tester) async {
await tester.pumpWidget(const CollectionValoraApp());
await tester.pump();

expect(find.text('ACCEDI'), findsOneWidget);
expect(find.text('Nuovo acquisto'), findsNothing);
expect(find.text('Verifica runtime'), findsNothing);

});
}
