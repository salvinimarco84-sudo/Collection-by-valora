/// Stato isolato della procedura PR-03 (chiusura oggetti).
class Pr03Controller {
  final List<Map<String, dynamic>> pendingClosures =
      <Map<String, dynamic>>[];
  String closeReason = 'SMARRITO';

  bool containsClosure(int objectId) =>
      pendingClosures.any((entry) => entry['codice_oggetto'] == objectId);

  void addPendingClosure(Map<String, dynamic> closure) {
    final id = int.tryParse(closure['codice_oggetto']?.toString() ?? '');
    if (id == null || id <= 0) {
      throw ArgumentError('Codice oggetto non valido per la coda PR-03.');
    }
    if (containsClosure(id)) {
      throw StateError('L’oggetto $id è già presente nella coda PR-03.');
    }
    pendingClosures.add(Map<String, dynamic>.unmodifiable(closure));
  }

  /// Rimuove dalla coda soltanto una chiusura già confermata dal runtime.
  bool removePendingClosure(int objectId) {
    final index = pendingClosures.indexWhere(
      (entry) => entry['codice_oggetto'] == objectId,
    );
    if (index < 0) return false;
    pendingClosures.removeAt(index);
    return true;
  }

  List<Map<String, dynamic>> pendingClosuresSnapshot() =>
      List<Map<String, dynamic>>.unmodifiable(pendingClosures);

  void clearPendingClosures() => pendingClosures.clear();
}
