part of '../main.dart';

extension _Pr04PhotoController on _NewPurchasePageState {
  Future<void> _photoAndRecognize(_PurchaseItemDraft item) async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2000, maxHeight: 2000);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) throw Exception('Foto vuota o superiore a 10 MB.');
      setState(() {
        item.photoBytes = bytes;
        item.photoName = picked.name.isNotEmpty ? picked.name : 'foto_acquisto.jpg';
        item.photoUrl = null;
        item.photoStatus = 'Foto acquisita. Riconoscimento PR-12 in corso…';
      });
      final mime = (item.photoName ?? '').toLowerCase().endsWith('.png') ? 'image/png' : ((item.photoName ?? '').toLowerCase().endsWith('.webp') ? 'image/webp' : 'image/jpeg');
      final response = await Supabase.instance.client.functions.invoke('pr-12-engine-test', body: {
        'azione': 'ANALIZZA_FOTO', 'modalita_ia': 'TEST',
        'image_data_url': 'data:$mime;base64,${base64Encode(bytes)}', 'mercato': 'Italia',
      });
      final data = response.data;
      if (data is! Map || data['ok'] != true) throw Exception(data is Map ? (data['error'] ?? 'Riconoscimento non riuscito').toString() : 'Risposta PR-12 non valida');
      final clues = data['identificazione'] is Map ? Map<String,dynamic>.from(data['identificazione']) : <String,dynamic>{};
      final results = data['risultati'] is List ? (data['risultati'] as List).whereType<Map>().map((v)=>Map<String,dynamic>.from(v)).toList() : <Map<String,dynamic>>[];
      if (!mounted) return;
      final imageCandidates = results.where((r) {
        final u = (r['image_url'] ?? r['immagine_url'] ?? r['url_immagine'] ?? '').toString().trim();
        return u.startsWith('https://') || u.startsWith('http://');
      }).toList();
      final selection = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => Pr04RecognitionDialog(
          photoBytes: bytes,
          clues: clues,
          results: results,
          imageCandidates: imageCandidates,
        ),
      );
      if (selection == null || selection['annulla'] == true) {
        if (mounted) setState(() => item.photoStatus = 'Ricerca terminata. Foto originale conservata; nessuna proposta applicata.');
        return;
      }
      final selectedCandidate = selection['candidate'] is Map
          ? Map<String,dynamic>.from(selection['candidate'] as Map)
          : (results.isNotEmpty ? results.first : <String,dynamic>{});
      final description = (clues['descrizione_provvisoria'] ?? selectedCandidate['title'] ?? '').toString().trim();
      final maker = (clues['marchio'] ?? selectedCandidate['produttore'] ?? selectedCandidate['editore'] ?? '').toString().trim();
      final code = (clues['codice_prodotto'] ?? selectedCandidate['codice_prodotto'] ?? selectedCandidate['isbn'] ?? '').toString().trim();
      final yearValue = selectedCandidate['anno_uscita'] ?? selectedCandidate['anno_pubblicazione'] ?? selectedCandidate['year'];
      final yearText = yearValue?.toString() ?? '';
      final yearMatch = RegExp(r'(19\d{2}|20\d{2})').firstMatch(yearText);
      final selectedUrl = selection['use_original'] == true ? null
          : (selectedCandidate['image_url'] ?? selectedCandidate['immagine_url'] ?? selectedCandidate['url_immagine'] ?? '').toString().trim();
      if (mounted) setState(() {
        if (description.isNotEmpty) item.description.text = description;
        item.metadataProducer = maker.isEmpty ? null : maker;
        item.metadataCode = code.isEmpty ? null : code;
        item.metadataYear = yearMatch == null ? null : int.tryParse(yearMatch.group(1)!);
        item.metadataSourceUrl = (selectedCandidate['url'] ?? '').toString().trim().isEmpty ? null : selectedCandidate['url'].toString();
        item.photoUrl = selectedUrl != null && (selectedUrl.startsWith('https://') || selectedUrl.startsWith('http://')) ? selectedUrl : null;
        item.photoStatus = item.photoUrl == null
          ? 'Metadati PR-12 proposti. Foto originale selezionata; verifica i dati prima di salvare.'
          : 'Metadati PR-12 proposti. Immagine online selezionata; verifica i dati prima di salvare.';
        _invalidate();
      });
    } catch (e) {
      if (mounted) setState(() => item.photoStatus = 'Riconoscimento non riuscito: $e');
    }
  }
}
