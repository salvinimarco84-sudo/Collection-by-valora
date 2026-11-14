/// Stato isolato della procedura PR-03 (chiusura oggetti).
class Pr03Controller {
  final List<Map<String, dynamic>> pendingClosures =
      <Map<String, dynamic>>[];
  String closeReason = 'SMARRITO';
  bool _confirmingClosure = false;
  bool _savingClosures = false;

  bool beginClosureConfirmation() {
    if (_confirmingClosure || _savingClosures) return false;
    _confirmingClosure = true;
    return true;
  }

  void endClosureConfirmation() {
    _confirmingClosure = false;
  }

  bool beginSavingClosures() {
    if (_savingClosures) return false;
    _savingClosures = true;
    return true;
  }

  void endSavingClosures() {
    _savingClosures = false;
  }

  bool get isConfirmingClosure => _confirmingClosure;
  bool get isSavingClosures => _savingClosures;

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
