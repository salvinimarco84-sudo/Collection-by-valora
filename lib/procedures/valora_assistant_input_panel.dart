part of '../main.dart';

/// Pannello di inserimento e invio dei comandi PR-14.
extension _ValoraAssistantInputPanel on _ValoraAssistantPageState {
  Widget buildAssistantInputPanel() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.psychology_alt_outlined, color: goldColor, size: 44),
          const SizedBox(height: 8),
          const Text('Parla con VALORA', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('L’assistente riceve il contesto della schermata: ${widget.screenContext}. In questa fase i comandi sono in sola lettura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            minLines: 2,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              labelText: 'Comando vocale o scritto',
              hintText: 'Esempio: cerca il prodotto esatto del record 7 e confronta le fonti',
              prefixIcon: Icon(Icons.chat_bubble_outline),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _working ? null : _toggleListening,
              icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic),
              label: Text(_listening ? 'FERMA ASCOLTO' : 'PARLA'),
            )),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(
              onPressed: _working ? null : _sendCommand,
              icon: _working
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
              label: const Text('ESEGUI'),
            )),
          ]),
          const SizedBox(height: 10),
          Text(_status, style: TextStyle(
            color: ValoraAppearance.instance.textMuted, fontSize: 12)),
        ],
      ),
    ),
  );
}
