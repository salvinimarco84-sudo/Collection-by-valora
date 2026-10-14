import 'package:flutter_test/flutter_test.dart';
import 'package:collection_by_valora/main.dart';

void main() {
  testWidgets('HOME e maschere di sezione sono visibili', (tester) async {
    await tester.pumpWidget(const CollectionByValoraApp());

    expect(find.text('COLLECTION by VALORA'), findsOneWidget);
    expect(find.text('CENTRO DI CONTROLLO'), findsOneWidget);
  });

  testWidgets('Acquisti mostra procedure e stato del mapping API',
      (tester) async {
    await tester.pumpWidget(const CollectionByValoraApp());

    await tester.tap(find.text('Acquisti').first);
    await tester.pumpAndSettle();

    expect(find.text('Nuovo acquisto'), findsOneWidget);
    expect(find.text('WRITE-PR-04'), findsOneWidget);
    expect(find.text('MAPPING CANDIDATO'), findsWidgets);
    expect(find.text('DA ALLINEARE'), findsWidgets);
  });

  testWidgets(
      'Una voce senza API certa è esplicitamente da allineare',
      (tester) async {
    await tester.pumpWidget(const CollectionByValoraApp());

    await tester.tap(find.text('Acquisti').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Acquisti comparati'));
    await tester.pumpAndSettle();

    expect(find.text('Acquisti comparati'), findsOneWidget);

    await tester.tap(find.text('Acquisti comparati').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Nessuna API certa è stata associata'),
      findsOneWidget,
    );
  });
}
