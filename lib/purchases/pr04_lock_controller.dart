part of '../main.dart';

extension _Pr04LockController on _NewPurchasePageState {
  Future<bool> _acquire() async {
    final r = await _ValoraRuntimeApi.call('acquire_lock', {'session_id': _session});
    final data = r['result'];
    if (data is Map && data['acquisito'] == true) {
      _locked = true;
      return true;
    }
    if (mounted) {
      setState(() => _status =
          (data is Map ? data['messaggio'] : null)?.toString() ??
          'Blocco archivio non acquisito.');
    }
    return false;
  }

  Future<void> _release() async {
    if (!_locked) return;
    try {
      await _ValoraRuntimeApi.call('release_lock', {'session_id': _session});
    } finally {
      _locked = false;
    }
  }
}
