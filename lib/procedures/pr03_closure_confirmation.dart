part of '../main.dart';

/// Conferma singola chiusura, accodamento e scelta dell'oggetto successivo.
extension _Pr03ClosureConfirmation on _ObjectRuntimePageState {
  Future<void> _confirmPr03Closure() async {
    if (!_pr03Controller.beginClosureConfirmation()) return;
    try {
    if (_currentObject == null || _loadedObjectId == null ||
        _loadedObjectId != int.tryParse(_code.text.trim())) {
      throw Exception('Cerca e seleziona prima l’oggetto da chiudere.');
    }
    final id = _loadedObjectId!;
    if (_pr03Controller.containsClosure(id)) {
      throw Exception('L’oggetto $id è già presente nell’elenco delle chiusure da confermare.');
    }
    final reason = _closeReason;
    final notes = _notes.text.trim();
    final description = (_currentObject?['descrizione_oggetto'] ?? _currentObject?['descrizione'] ?? 'Oggetto $id').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('CONFERMA CHIUSURA'),
        content: Text('Oggetto: $id · $description\nMotivo: $reason\nNote: ${notes.isEmpty ? "Nessuna" : notes}\n\nConfermi questa chiusura?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('CONFERMA')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _pr03Controller.addPendingClosure({
        'codice_oggetto': id,
        'motivo_chiusura': reason,
        'note': notes.isEmpty ? null : notes,
        'descrizione': description,
      });
      _output = 'Chiusure confermate in attesa di salvataggio: ${_pr03PendingClosures.length}.';
    });
    final addAnother = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('ALTRO OGGETTO?'),
        content: Text('Vuoi chiudere un altro oggetto?\n\nOggetti confermati: ${_pr03PendingClosures.length}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('NO, SALVA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('SÌ, CERCA ALTRO')),
        ],
      ),
    );
    if (!mounted) return;
    if (addAnother == true) {
      setState(() {
        _search.clear();
        _code.clear();
        _notes.clear();
        _currentObject = null;
        _loadedObjectId = null;
        _lastResult = null;
        _dataConfirmed = false;
        _finalReady = false;
        _output = 'Cerca il prossimo oggetto da chiudere.';
      });
      return;
    }
    await _savePr03PendingClosures();
    } finally {
      _pr03Controller.endClosureConfirmation();
    }
  }
}
