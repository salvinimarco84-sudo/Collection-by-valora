part of '../main.dart';

/// Avviso di sicurezza sempre visibile nell'assistente PR-14.
extension _ValoraAssistantSafetyNotice on _ValoraAssistantPageState {
  Widget buildAssistantSafetyNotice() => Text(
    'SICUREZZA: in questa versione l’assistente non salva, cancella o modifica record. Le azioni sui dati richiederanno conferma esplicita.',
    style: TextStyle(color: ValoraAppearance.instance.textMuted, fontSize: 12),
  );
}
