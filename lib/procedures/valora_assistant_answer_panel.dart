part of '../main.dart';

/// Pannello dedicato alla visualizzazione della risposta dell'assistente PR-14.
extension _ValoraAssistantAnswerPanel on _ValoraAssistantPageState {
  Widget buildAssistantAnswerPanel() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText(_answer),
    ),
  );
}
