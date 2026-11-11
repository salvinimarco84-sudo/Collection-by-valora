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
