part of '../main.dart';

/// Conferma riepilogo e persistenza delle chiusure accodate in PR-03.
extension _Pr03ClosureSave on _ObjectRuntimePageState {
  Future<void> _savePr03PendingClosures() async {
    if (!_pr03Controller.beginSavingClosures()) return;
    try {
    if (_pr03PendingClosures.isEmpty) throw Exception('Non ci sono chiusure confermate da salvare.');
    final summary = _pr03PendingClosures.map((item) =>
      '${item['codice_oggetto']} · ${item['descrizione']} · ${item['motivo_chiusura']}'
    ).join('\n');
    final finalConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('RIEPILOGO FINALE'),
        content: SingleChildScrollView(child: Text('Saranno salvate queste chiusure:\n\n$summary\n\nConfermi il salvataggio?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('SALVA TUTTO')),
        ],
      ),
    );
    if (finalConfirmed != true) return;
    final saved = <int>[];
    for (final item in _pr03Controller.pendingClosuresSnapshot()) {
      final id = int.parse(item['codice_oggetto'].toString());
      final payload = <String, dynamic>{
        'oggetti': [{
          'codice_oggetto': id,
          'motivo_chiusura': item['motivo_chiusura'],
          'note': item['note'],
        }]
      };
      try {
        if (!_lockHeld) await _acquireLock();
        await _ValoraRuntimeApi.procedure('PR-03', 'preview', payload, sessionId: _sessionId);
        final reviewPayload = Map<String, dynamic>.from(payload)
          ..['dati_confermati'] = true
          ..['altra_operazione'] = false
          ..['conferma_finale'] = false;
        await _ValoraRuntimeApi.procedure('PR-03', 'review', reviewPayload, sessionId: _sessionId);
        final savePayload = Map<String, dynamic>.from(payload)
          ..['dati_confermati'] = true
          ..['altra_operazione'] = false
          ..['conferma_finale'] = true;
        final result = await _ValoraRuntimeApi.procedure(
          'PR-03', 'save', savePayload, sessionId: _sessionId, requestId: _uuid.v4());
        if (result['scrittura_eseguita'] != true) {
          throw Exception('Il runtime non ha confermato la scrittura per l’oggetto $id.');
        }
        // La scrittura è già avvenuta: rimuovi subito l'elemento dalla coda,
        // così un errore successivo non lo ripropone al tentativo seguente.
        _pr03Controller.removePendingClosure(id);
        saved.add(id);
        if (result['blocco_rilasciato_automaticamente'] != true) {
          throw Exception('Scrittura eseguita, ma rilascio del blocco non confermato per l’oggetto $id.');
        }
        // Il runtime ha confermato il rilascio automatico: riallinea anche
        // lo stato locale prima di processare la chiusura successiva.
        _lockHeld = false;
        if (mounted) setState(() { _lastResult = result; _output = _pretty(result); });
      } catch (error) {
        var releaseError;
        if (_lockHeld) {
          try {
            await _releaseLock();
          } catch (caughtReleaseError) {
            releaseError = caughtReleaseError;
          }
        }
        if (mounted) {
          final lockMessage = releaseError == null
              ? ''
              : ' Anche il rilascio del blocco non è riuscito: $releaseError.';
          setState(() => _output =
              'Salvate: ${saved.join(', ')}. Errore sull’oggetto $id: $error.$lockMessage Le restanti chiusure restano non elaborate.');
        }
        rethrow;
      }
    }
    if (!mounted) return;
    setState(() {
      _pr03Controller.clearPendingClosures();
      _currentObject = null;
      _loadedObjectId = null;
      _code.clear();
      _search.clear();
      _notes.clear();
      _lastResult = null;
      _output = 'Chiusure salvate e scrittura confermata per: ${saved.join(', ')}.';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Chiusure salvate: ${saved.join(', ')}')),
    );
    } finally {
      _pr03Controller.endSavingClosures();
    }
  }

}
