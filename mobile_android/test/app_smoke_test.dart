import 'package:flutter_test/flutter_test.dart';
import 'package:valora_mobile/src/app.dart';

void main() {
  testWidgets('TEST2 configuration screen renders', (tester) async {
    await tester.pumpWidget(const ValoraApp(configurationError: true));

    expect(find.text('TEST2 configuration is missing.'), findsOneWidget);
  });
}
