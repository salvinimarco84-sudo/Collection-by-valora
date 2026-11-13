part of '../main.dart';

extension _Pr03RuntimeProcedure on _ObjectRuntimePageState {
  Future<void> _confirmPr03Closure() async {
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
  }

  Future<void> _savePr03PendingClosures() async {
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
        if (result['blocco_rilasciato_automaticamente'] != true) {
          throw Exception('Il runtime non ha confermato il rilascio del blocco per l’oggetto $id.');
        }
        saved.add(id);
        if (mounted) setState(() { _lastResult = result; _output = _pretty(result); });
      } catch (error) {
        if (mounted) setState(() => _output = 'Salvate: ${saved.join(', ')}. Errore sull’oggetto $id: $error. Le restanti chiusure restano non elaborate.');
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
  }

}

/// Presentazione dedicata della procedura PR-03: ricerca, coda e conferma.
extension _Pr03ClosurePresentation on _ObjectRuntimePageState {
  List<Widget> _buildPr03ClosureSection() => [
    _field(_search, 'Cerca oggetto per descrizione o codice'),
    FilledButton.icon(
      onPressed: _loading ? null : () => _run(_searchPr02Objects),
      icon: const Icon(Icons.search),
      label: const Text('CERCA E SELEZIONA OGGETTO'),
    ),
    if (_pr03PendingClosures.isNotEmpty)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chiusure confermate in attesa: ${_pr03PendingClosures.length}',
          style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold),
        ),
      ),
    if (_currentObject != null) ...[
      _dropdown(
        'Motivo chiusura',
        _closeReason,
        const ['SMARRITO', 'DISTRUTTO', 'DATO VIA'],
        (value) => setState(() => _closeReason = value!),
      ),
      _field(_notes, 'Note', lines: 2),
      FilledButton.icon(
        onPressed: _loading ? null : () => _run(_confirmPr03Closure),
        icon: const Icon(Icons.verified_outlined),
        label: const Text('CONFERMA CHIUSURA'),
      ),
    ],
  ];
}
