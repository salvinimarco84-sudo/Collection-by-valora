part of '../main.dart';

/// Persistenza e verifica delle modifiche confermate da PR-02.
extension _Pr02SaveWorkflow on _ObjectRuntimePageState {
  Future<void> _savePr02PendingChanges({bool closeOnComplete = true}) async {
    final pending = _pr02PendingChanges
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    for (final item in pending) {
      final categoryCode = item['categoria_collezione_selezionata']?.toString();
      final objectPayload = Map<String, dynamic>.from(item)..remove('categoria_collezione_selezionata');
      final objectHasChanges = objectPayload.keys.any((key) => key != 'codice_oggetto');
      final payload = <String, dynamic>{
        'oggetti': [objectPayload],
        'dati_confermati': true,
        'altra_operazione': false,
        'conferma_finale': true,
      };
      final pendingImage = _pr02PendingImages[item['codice_oggetto'].toString()];
      if (objectHasChanges) await _acquireLock();
      try {
        if (objectHasChanges) {
        final preview = await _ValoraRuntimeApi.procedure(
          'PR-02', 'preview', payload, sessionId: _sessionId);
        if (preview['errore'] != null) {
          throw Exception(preview['errore'].toString());
        }
        await _ValoraRuntimeApi.procedure(
          'PR-02', 'review', payload, sessionId: _sessionId);
        final result = await _ValoraRuntimeApi.procedure(
          'PR-02', 'save', payload, sessionId: _sessionId, requestId: _uuid.v4());
        if (result['scrittura_eseguita'] != true) {
          throw Exception('Salvataggio non confermato per oggetto ${item['codice_oggetto']}.');
        }
        if (result['blocco_rilasciato_automaticamente'] == true) {
          setState(() => _lockHeld = false);
        } else {
          throw Exception('Salvataggio eseguito ma rilascio del blocco non confermato.');
        }
        }
        final objectIdForCategory = int.tryParse(item['codice_oggetto'].toString());
        if (objectIdForCategory != null) {
          if (categoryCode != null && categoryCode.isNotEmpty) {
            await Supabase.instance.client.schema('collection').from('oggetto_collezione_categoria').upsert({
              'codice_oggetto': objectIdForCategory, 'codice_categoria': categoryCode,
              'fonte_assegnazione': 'MANUALE', 'stato_verifica': 'VERIFICATO',
              'aggiornato_il': DateTime.now().toIso8601String(),
            }, onConflict: 'codice_oggetto');
          } else {
            await Supabase.instance.client.schema('collection').from('oggetto_collezione_categoria')
              .delete().eq('codice_oggetto', objectIdForCategory);
          }
        }
        if (pendingImage != null) {
          final signedUrl = await _uploadAndRegisterImage(
            objectId: int.parse(item['codice_oggetto'].toString()), bytes: pendingImage['bytes'] as Uint8List,
            fileName: pendingImage['name'] as String, acquisition: pendingImage['acquisition'] as String, procedure: 'PR-02');
          _pr02PendingImages.remove(item['codice_oggetto'].toString());
          if (_loadedObjectId == int.tryParse(item['codice_oggetto'].toString()) && mounted) {
            setState(() { _existingImageUrl = signedUrl; _imageStatus = 'Immagine associata e verificata.'; });
          }
        }
      } catch (_) {
        if (_lockHeld) {
          try { await _releaseLock(); } catch (_) {}
        }
        rethrow;
      }
    }
    _pr02PendingChanges.clear();
    if (!mounted || !closeOnComplete) return;
    Navigator.of(context).pop();
  }
}
