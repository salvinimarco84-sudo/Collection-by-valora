part of '../main.dart';

/// Selezione del record e caricamento della scheda per PR-02.
extension _Pr02SelectionWorkflow on _ObjectRuntimePageState {
  Future<void> _selectPr02Object(Map<String, dynamic> item) async {
    final id = int.tryParse(item['codice_oggetto']?.toString() ?? '');
    if (id == null) throw Exception('Il risultato non contiene un codice oggetto valido.');
    _code.text = id.toString();
    _showPr02TechnicalTab = false;
    await _loadObject();
    if (!mounted || _currentObject == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_descriptionFocus);
    });
  }
}
