/// Stato isolato della procedura PR-03 (chiusura oggetti).
class Pr03Controller {
  final List<Map<String, dynamic>> pendingClosures =
      <Map<String, dynamic>>[];
  String closeReason = 'SMARRITO';

  void clearPendingClosures() => pendingClosures.clear();
}
