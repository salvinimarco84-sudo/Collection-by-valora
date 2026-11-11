part of '../main.dart';

extension _ValoraCatalogObjectsController on _ValoraServicePageState {
  List<Map<String, dynamic>> get _matchingObjects {
    final query = _descriptionQuery.text.trim().toLowerCase();
    if (query.isEmpty) return _objects;
    return _objects.where((object) =>
      (object['descrizione_oggetto'] ?? '').toString().toLowerCase().contains(query)
    ).toList();
  }

  Future<void> _loadObjects() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rows = await _fetchValoraCatalogObjects();
      if (!mounted) return;
      setState(() { _objects = rows; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Impossibile caricare gli oggetti della collezione: $e'; _loading = false; });
    }
  }
}
