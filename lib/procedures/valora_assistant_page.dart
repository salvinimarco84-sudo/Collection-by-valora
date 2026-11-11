part of '../main.dart';

class ValoraAssistantPage extends StatefulWidget {
  const ValoraAssistantPage({super.key, this.screenContext = 'Dashboard'});
  final String screenContext;
  @override
  State<ValoraAssistantPage> createState() => _ValoraAssistantPageState();
}

class _ValoraAssistantPageState extends State<ValoraAssistantPage> {
  final _session = _ValoraAssistantSession();

  TextEditingController get _textController => _session.textController;
  SpeechToText get _speech => _session.speech;
  bool get _speechReady => _session.speechReady;
  set _speechReady(bool value) => _session.speechReady = value;
  bool get _listening => _session.listening;
  set _listening(bool value) => _session.listening = value;
  bool get _working => _session.working;
  set _working(bool value) => _session.working = value;
  String get _answer => _session.answer;
  set _answer(String value) => _session.answer = value;
  String get _status => _session.status;
  set _status(String value) => _session.status = value;
  List<Map<String, String>> get _history => _session.history;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildAssistantPage(context);
}
