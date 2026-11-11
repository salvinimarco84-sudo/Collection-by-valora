part of '../main.dart';

/// Normalizza i metadati del candidato PR-12 prima della valutazione PR-18.
/// Funzione isolata e senza effetti collaterali: non scrive nel catalogo.
Map<String, dynamic> _buildValoraCandidateMetadata({
  required String title,
  required Map<String, dynamic> candidate,
  required Map<String, dynamic> clues,
}) {
  final maker = (candidate['produttore'] ?? candidate['editore'] ?? clues['marchio'] ?? '').toString().trim();
  final code = (candidate['codice_prodotto'] ?? candidate['isbn'] ?? clues['codice_prodotto'] ?? '').toString().trim();
  final yearValue = candidate['anno_uscita'] ?? candidate['anno_pubblicazione'] ?? candidate['year'];
  final yearMatch = RegExp(r'(19\d{2}|20\d{2})').firstMatch(yearValue?.toString() ?? '');
  final sourceUrl = (candidate['url'] ?? '').toString().trim();
  final imageUrl = (candidate['image_url'] ?? candidate['immagine_url'] ?? candidate['url_immagine'] ?? '').toString().trim();
  return <String, dynamic>{
    'descrizione': title,
    if (maker.isNotEmpty) 'produttore': maker,
    if (code.isNotEmpty) 'codice_prodotto': code,
    if (yearMatch != null) 'anno_uscita': int.tryParse(yearMatch.group(1)!),
    if (sourceUrl.startsWith('https://') || sourceUrl.startsWith('http://')) 'fonte_dati_prodotto': sourceUrl,
    if (imageUrl.startsWith('https://') || imageUrl.startsWith('http://')) 'url_immagine_catalogo': imageUrl,
  };
}
