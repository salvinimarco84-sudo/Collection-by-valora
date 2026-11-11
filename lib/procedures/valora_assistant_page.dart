part of '../main.dart';

class ValoraAssistantPage extends StatefulWidget {
  const ValoraAssistantPage({super.key, this.screenContext = 'Dashboard'});
  final String screenContext;
  @override
  State<ValoraAssistantPage> createState() => _ValoraAssistantPageState();
}

class _ValoraAssistantPageState extends State<ValoraAssistantPage> {
  final _textController = TextEditingController();
  final _speech = SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  bool _working = false;
  String _answer = '';
  String _status = 'Scrivi oppure premi il microfono per impartire un comando.';
  final List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildAssistantPage(context);
}
