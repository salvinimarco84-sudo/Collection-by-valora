part of '../main.dart';

/// Gestione isolata del riconoscimento vocale per PR-14.
extension _ValoraAssistantSpeech on _ValoraAssistantPageState {
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

}
