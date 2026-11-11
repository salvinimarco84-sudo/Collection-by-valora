import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final assistant = File('lib/procedures/valora_assistant_page.dart').readAsStringSync();
  final session = File('lib/procedures/valora_assistant_session.dart').readAsStringSync();
  final presentation = File('lib/procedures/valora_assistant_presentation.dart').readAsStringSync();
  final speech = File('lib/procedures/valora_assistant_speech.dart').readAsStringSync();
  final command = File('lib/procedures/valora_assistant_command.dart').readAsStringSync();
  final inputPanel = File('lib/procedures/valora_assistant_input_panel.dart').readAsStringSync();
  final answerPanel = File('lib/procedures/valora_assistant_answer_panel.dart').readAsStringSync();
  final safetyNotice = File('lib/procedures/valora_assistant_safety_notice.dart').readAsStringSync();

  group('VALORA assistant module contract', () {
    test('the assistant page is declared in its dedicated procedure module', () {
      expect(mainSource, contains("part 'procedures/valora_assistant_page.dart';"));
      expect(mainSource, isNot(contains('class ValoraAssistantPage extends StatefulWidget')));
      expect(assistant, contains('class ValoraAssistantPage extends StatefulWidget'));
      expect(assistant, contains('class _ValoraAssistantPageState extends State<ValoraAssistantPage>'));
    });

    test('voice, text command and TEST read-only contract remain intact', () {
      expect(assistant, contains('final _session = _ValoraAssistantSession();'));
      expect(session, contains('final SpeechToText speech = SpeechToText();'));
      expect(session, contains('final TextEditingController textController = TextEditingController();'));
      expect(session, contains('void dispose()'));
      expect(assistant, contains('StatefulWidget'));
      expect(speech, contains('Future<void> _toggleListening() async'));
      expect(speech, contains('_speechLocaleId'));
      expect(speech, contains('_speechLanguageName'));
      expect(assistant, contains('_initializeSpeech()'));
      expect(presentation, contains('buildAssistantInputPanel()'));
      expect(inputPanel, contains('extension _ValoraAssistantInputPanel'));
      expect(inputPanel, contains('TextField('));
      expect(inputPanel, contains('_toggleListening'));
      expect(inputPanel, contains('_sendCommand'));
      expect(command, contains('Future<void> _sendCommand() async'));
      expect(command, contains('extension _ValoraAssistantCommand'));
      expect(mainSource, contains("part 'procedures/valora_assistant_command.dart';"));
      expect(mainSource, contains("part 'procedures/valora_assistant_input_panel.dart';"));
      expect(command, contains("'valora-assistant'"));
      expect(command, contains("'modalita': 'TEST'"));
      expect(command, contains("'sola_lettura': true"));
      expect(command, contains('Nessuna modifica al database è stata eseguita.'));
      expect(assistant, contains('buildAssistantPage(context)'));
      expect(presentation, contains('extension _ValoraAssistantPresentation'));
      expect(presentation, contains('Widget buildAssistantPage(BuildContext context)'));
    });

    test('the safety notice is isolated from the main presentation', () {
      expect(mainSource, contains("part 'procedures/valora_assistant_safety_notice.dart';"));
      expect(presentation, contains('buildAssistantSafetyNotice()'));
      expect(safetyNotice, contains('extension _ValoraAssistantSafetyNotice'));
      expect(safetyNotice, contains('non salva, cancella o modifica record'));
    });

    test('the answer panel is isolated from the main presentation', () {
      expect(mainSource, contains("part 'procedures/valora_assistant_answer_panel.dart';"));
      expect(presentation, contains('buildAssistantAnswerPanel()'));
      expect(answerPanel, contains('extension _ValoraAssistantAnswerPanel'));
      expect(answerPanel, contains('SelectableText(_answer)'));
    });
  });
}
