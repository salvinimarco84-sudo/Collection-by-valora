part of '../main.dart';

extension _Pr04RuntimeProcedure on _NewPurchasePageState {
  Future<void> _runPreview() async {
    if (!_valid()) return;
    setState(() { _busy = true; _status = 'Controllo preliminare in TEST…'; _invalidate(); });
    try {
      if (!await _acquire()) return;
      final expectedPurchases = _pendingPurchases.length + 1;
      final r = await _ValoraRuntimeApi.procedure('PR-04', 'preview', _payload(), sessionId: _session);
      if (r['scrittura_eseguita'] == true || r['numero_acquisti'] != expectedPurchases) {
        throw StateError('Anteprima incoerente: attesi $expectedPurchases acquisti, ricevuti ${r['numero_acquisti'] ?? 'nessun conteggio'}. Nessuna scrittura autorizzata.');
      }
      if (!mounted) return;
      setState(() { _preview = r; _step = 4; _status = 'Riepilogo pronto: $expectedPurchases acquisti inclusi. SÌ aggiunge un altro; NO salva l’intera coda.'; });
    } catch (e) {
      if (mounted) setState(() => _status = 'Controllo non riuscito: ' + e.toString());
    } finally { await _release(); if (mounted) setState(() => _busy = false); }
  }



}