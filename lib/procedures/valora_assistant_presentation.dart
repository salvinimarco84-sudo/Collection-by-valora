part of '../main.dart';

/// Presentazione della schermata PR-14. Lo stato e le azioni restano nel controller.
extension _ValoraAssistantPresentation on _ValoraAssistantPageState {
  Widget buildAssistantPage(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(ValoraI18n.tr('ASSISTENTE VALORA'))),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        buildAssistantInputPanel(),
        if (_answer.isNotEmpty) buildAssistantAnswerPanel(),
        const SizedBox(height: 8),
        Text('SICUREZZA: in questa versione l’assistente non salva, cancella o modifica record. Le azioni sui dati richiederanno conferma esplicita.',
          style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12)),
      ],
    )),
  );
}
