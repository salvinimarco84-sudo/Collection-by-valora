part of '../main.dart';

/// Persistenza del blocco PR-01 già confermato.
extension _Pr01SaveWorkflow on _ObjectRuntimePageState {
  Future<void> _savePr01PendingObjects() async {
    await _pr01Controller.savePendingObjects(
      sessionId: _sessionId,
      acquireLock: _acquireLock,
      releaseLock: _releaseLock,
      isLockHeld: () => _lockHeld,
      executeProcedure: (action, payload, requestId) =>
          _ValoraRuntimeApi.procedure(
        'PR-01',
        action,
        payload,
        sessionId: _sessionId,
        requestId: requestId,
      ),
      persistObjectExtras: (entry, objectId) async {
        final category = entry['categoria']?.toString();
        if (category != null && category.isNotEmpty) {
          await Supabase.instance.client
              .schema('collection')
              .from('oggetto_collezione_categoria')
              .upsert({
            'codice_oggetto': objectId,
            'codice_categoria': category,
            'fonte_assegnazione': 'MANUALE',
            'stato_verifica': 'VERIFICATO',
            'aggiornato_il': DateTime.now().toIso8601String(),
          }, onConflict: 'codice_oggetto');
        }

        final bytes = entry['image_bytes'];
        final name = entry['image_name'];
        if (bytes is Uint8List && name is String && name.isNotEmpty) {
          await _uploadAndRegisterImage(
            objectId: objectId,
            bytes: bytes,
            fileName: name,
            acquisition: entry['image_acquisition'] as String? ??
                _imageAcquisition,
            procedure: 'PR-01',
          );
        }
      },
      onLockReleased: () {
        if (mounted) setState(() => _lockHeld = false);
      },
      onStatus: (message) {
        if (mounted) {
          setState(() {
            _output = message;
            if (message.startsWith('Blocco PR-01 salvato')) {
              _description.clear();
              _producer.clear();
              _line.clear();
              _family.clear();
              _notes.clear();
              _quantity.text = '1';
              _unitPrice.clear();
              _totalValue.clear();
              _value.clear();
              _marketValue.text = '0.00';
              _selectedCollectionCategory = null;
              _selectedImageBytes = null;
              _selectedImageName = null;
              _imageStatus = 'Nessuna immagine selezionata.';
            }
          });
        }
      },
    );
  }
}
