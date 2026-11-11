part of '../main.dart';

/// Azioni di ricerca fotografica PR-12 di VALORA.
/// Gestisce analisi immagini, selezione/conferma candidati e ricerche estese.
extension _ValoraPhotoSearchActions on _ValoraServicePageState {
  
    Future<void> _analyzeSelectedPhotos() async {
      if (_selectedImages.isEmpty && _selectedFiles.isEmpty) {
        setState(() => _error = 'Seleziona almeno una foto o un file immagine da usare nella ricerca.');
        return;
      }
      setState(() { _analyzingPhotos = true; _error = null; _photoSearchResults.clear(); });
      try {
        final inputs = <({String name, Future<Uint8List> bytes})>[
          ..._selectedImages.map((image) => (name: image.name, bytes: image.readAsBytes())),
          ..._selectedFiles.map((file) => (name: file.name, bytes: Future.value(file.bytes ?? Uint8List(0)))),
        ];
        for (final input in inputs) {
          final data = await _analyzeValoraImageBytes(await input.bytes, input.name, _market);
          if (!mounted) return;
          setState(() => _photoSearchResults.add({
            'nome_foto': input.name,
            'identificazione': data['identificazione'] is Map ? Map<String, dynamic>.from(data['identificazione']) : <String, dynamic>{},
            'risultati': data['risultati'] is List ? List<dynamic>.from(data['risultati']) : <dynamic>[],
            'diagnostica': data['diagnostica_ricerca'],
            'query_eseguite': data['query_eseguite'] is List ? List<String>.from(data['query_eseguite']) : <String>[],
            'categoria': (data['identificazione'] is Map ? data['identificazione']['categoria'] : '').toString(),
            'tema': (data['identificazione'] is Map ? data['identificazione']['marchio'] : '').toString(),
            'ricerche_estese': 0,
            'scrittura_database': false,
          }));
        }
      } catch (e) {
        if (mounted) setState(() => _error = 'Ricerca da foto non completata: $e');
      } finally {
        if (mounted) setState(() => _analyzingPhotos = false);
      }
    }
  

}
