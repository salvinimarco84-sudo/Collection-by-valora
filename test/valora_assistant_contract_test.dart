import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final assistant = File('lib/procedures/valora_assistant_page.dart').readAsStringSync();

  group('VALORA assistant module contract', () {
    test('the assistant page is declared in its dedicated procedure module', () {
      expect(mainSource, contains("part 'procedures/valora_assistant_page.dart';"));
      expect(mainSource, isNot(contains('class ValoraAssistantPage extends StatefulWidget')));
      expect(assistant, contains('class ValoraAssistantPage extends StatefulWidget'));
      expect(assistant, contains('class _ValoraAssistantPageState extends State<ValoraAssistantPage>'));
    });

    test('voice, text command and TEST read-only contract remain intact', () {
      expect(assistant, contains('SpeechToText()'));
      expect(assistant, contains('_toggleListening()'));
      expect(assistant, contains('_sendCommand()'));
      expect(assistant, contains("'valora-assistant'"));
      expect(assistant, contains("'modalita': 'TEST'"));
      expect(assistant, contains("'sola_lettura': true"));
      expect(assistant, contains('Nessuna modifica al database è stata eseguita.'));
    });
  });
}
