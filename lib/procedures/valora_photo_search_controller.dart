part of '../main.dart';

/// Azioni di ricerca fotografica PR-12 di VALORA.
/// Gestisce analisi immagini, selezione/conferma candidati e ricerche estese.
extension _ValoraPhotoSearchActions on _ValoraServicePageState {
    Future<Map<String, dynamic>> _analyzeImageBytes(Uint8List bytes, String fileName) async {
      if (bytes.isEmpty) throw Exception('Il file $fileName è vuoto o non leggibile.');
      if (bytes.length > 10 * 1024 * 1024) throw Exception('Il file $fileName supera il limite di 10 MB.');
      final name = fileName.toLowerCase();
      final mime = name.endsWith('.png') ? 'image/png' : name.endsWith('.webp') ? 'image/webp' : 'image/jpeg';
      final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
        'azione': 'ANALIZZA_FOTO',
        'modalita_ia': 'TEST',
        'image_data_url': 'data:$mime;base64,${base64Encode(bytes)}',
        'mercato': _market,
      });
      final data = response.data;
      if (data is! Map || data['ok'] != true) {
        throw Exception(data is Map ? (data['error'] ?? 'Ricerca foto non riuscita').toString() : 'Risposta PR-12 non valida.');
      }
      return Map<String, dynamic>.from(data);
    }
  
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
          final data = await _analyzeImageBytes(await input.bytes, input.name);
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
