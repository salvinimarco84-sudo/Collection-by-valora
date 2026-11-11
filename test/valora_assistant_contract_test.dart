import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final assistant = File('lib/procedures/valora_assistant_page.dart').readAsStringSync();
  final presentation = File('lib/procedures/valora_assistant_presentation.dart').readAsStringSync();
  final speech = File('lib/procedures/valora_assistant_speech.dart').readAsStringSync();
  final command = File('lib/procedures/valora_assistant_command.dart').readAsStringSync();

  group('VALORA assistant module contract', () {
    test('the assistant page is declared in its dedicated procedure module', () {
      expect(mainSource, contains("part 'procedures/valora_assistant_page.dart';"));
      expect(mainSource, isNot(contains('class ValoraAssistantPage extends StatefulWidget')));
      expect(assistant, contains('class ValoraAssistantPage extends StatefulWidget'));
      expect(assistant, contains('class _ValoraAssistantPageState extends State<ValoraAssistantPage>'));
    });

    test('voice, text command and TEST read-only contract remain intact', () {
      expect(assistant, contains('SpeechToText()'));
      expect(speech, isNot(contains('SpeechToText')));
      expect(speech, contains('Future<void> _toggleListening() async'));
      expect(speech, contains('_speechLocaleId'));
      expect(speech, contains('_speechLanguageName'));
      expect(assistant, contains('_initializeSpeech()'));
      expect(presentation, contains('_sendCommand'));
      expect(command, contains('Future<void> _sendCommand() async'));
      expect(command, contains('extension _ValoraAssistantCommand'));
      expect(mainSource, contains("part 'procedures/valora_assistant_command.dart';"));
      expect(command, contains("'valora-assistant'"));
      expect(command, contains("'modalita': 'TEST'"));
      expect(command, contains("'sola_lettura': true"));
      expect(presentation, contains('Nessuna modifica al database è stata eseguita.'));
      expect(assistant, contains('buildAssistantPage(context)'));
      expect(presentation, contains('extension _ValoraAssistantPresentation'));
      expect(presentation, contains('Widget buildAssistantPage(BuildContext context)'));
    });
  });
}
