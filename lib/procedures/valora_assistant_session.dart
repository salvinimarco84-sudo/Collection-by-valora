part of '../main.dart';

/// Stato e risorse della sessione PR-14, separati dal ciclo di vita della pagina.
class _ValoraAssistantSession {
  final TextEditingController textController = TextEditingController();
  final SpeechToText speech = SpeechToText();
  bool speechReady = false;
  bool listening = false;
  bool working = false;
  String answer = '';
  String status = 'Scrivi oppure premi il microfono per impartire un comando.';
  final List<Map<String, String>> history = [];

  void dispose() {
    speech.stop();
    textController.dispose();
  }
}
