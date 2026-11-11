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

  Future<void> _initializeSpeech() async {
    try {
      final ready = await _speech.initialize(
        onStatus: (status) { if (mounted) setState(() => _listening = status == 'listening'); },
        onError: (error) { if (mounted) setState(() => _status = 'Microfono: ${error.errorMsg}'); },
      );
      if (mounted) setState(() {
        _speechReady = ready;
        _status = ready
          ? 'Assistente pronto. Puoi parlare in $_speechLanguageName.'
          : 'Riconoscimento vocale non disponibile: puoi comunque scrivere il comando.';
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Microfono non disponibile: $e');
    }
  }

  String get _speechLocaleId => switch (ValoraI18n.instance.code) {
    'en' => 'en_US',
    'fr' => 'fr_FR',
    'de' => 'de_DE',
    'es' => 'es_ES',
    'pt' => 'pt_BR',
    'zh' => 'zh_CN',
    'ja' => 'ja_JP',
    'ru' => 'ru_RU',
    _ => 'it_IT',
  };

  String get _speechLanguageName => switch (ValoraI18n.instance.code) {
    'en' => 'English',
    'fr' => 'français',
    'de' => 'Deutsch',
    'es' => 'español',
    'pt' => 'português',
    'zh' => '普通话',
    'ja' => '日本語',
    'ru' => 'русский',
    _ => 'italiano',
  };

  Future<void> _toggleListening() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    if (!_speechReady) {
      await _initializeSpeech();
      if (!_speechReady) return;
    }
    setState(() { _status = 'Ti ascolto…'; _listening = true; });
    await _speech.listen(
      localeId: _speechLocaleId,
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 4),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
          if (result.finalResult) {
            _status = 'Comando riconosciuto. Controllalo e premi ESEGUI.';
            _listening = false;
          }
        });
      },
    );
  }

  Future<void> _sendCommand() async {
    final command = _textController.text.trim();
    if (command.isEmpty || _working) return;
    setState(() { _working = true; _answer = ''; _status = 'ChatGPT sta elaborando il comando…'; });
    _history.add({'ruolo': 'utente', 'testo': command});
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'valora-assistant',
        body: {
          'comando': command,
          'schermata_corrente': widget.screenContext,
          'cronologia': _history.take(12).toList(),
          'modalita': 'TEST',
          'sola_lettura': true,
        },
      );
      final data = response.data;
      if (data is Map && data['ok'] == true) {
        final answer = (data['risposta'] ?? data['message'] ?? '').toString();
        setState(() {
          _answer = answer.isEmpty ? 'Risposta ricevuta senza testo.' : answer;
          _status = 'Risposta completata. Nessuna modifica al database è stata eseguita.';
        });
        _history.add({'ruolo': 'assistente', 'testo': _answer});
      } else {
        final detail = data is Map ? (data['error'] ?? data['message'] ?? 'Risposta non valida').toString() : 'Risposta non valida dal servizio.';
        setState(() { _answer = detail; _status = 'Servizio IA non disponibile.'; });
      }
    } on FunctionException catch (e) {
      setState(() {
        _answer = 'Il servizio ChatGPT di VALORA non è ancora configurato o ha restituito un errore. Dettaglio: ${e.details ?? e.reasonPhrase ?? e.status}';
        _status = 'Verifica la configurazione del motore IA.';
      });
    } catch (e) {
      setState(() {
        _answer = 'Non è stato possibile contattare il motore IA: $e';
        _status = 'Comando non eseguito.';
      });
    } finally {
      if (mounted) setState(() => _working = false);
    }
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
