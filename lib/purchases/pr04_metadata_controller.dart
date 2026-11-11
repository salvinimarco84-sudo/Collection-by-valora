part of '../main.dart';

extension _Pr04MetadataController on _Pr04PageState {
  String? _nonEmptyMetadata(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  void _initializeFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return;
    final item = _items.first;
    item.description.text = (metadata['descrizione'] ?? '').toString();
    item.metadataProducer = _nonEmptyMetadata(metadata['produttore']);
    item.metadataCode = _nonEmptyMetadata(metadata['codice_prodotto']);
    item.metadataYear = metadata['anno_uscita'] is num
        ? (metadata['anno_uscita'] as num).toInt()
        : int.tryParse((metadata['anno_uscita'] ?? '').toString());
    item.metadataSourceUrl = _nonEmptyMetadata(metadata['fonte_dati_prodotto']);
    final imageUrl = _nonEmptyMetadata(metadata['url_immagine_catalogo']);
    item.photoUrl = imageUrl != null &&
        (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'))
        ? imageUrl : null;
    item.photoStatus = item.photoUrl == null
        ? 'Metadati VALORA precompilati. Foto utente non importata come immagine definitiva.'
        : 'Metadati e immagine catalogo selezionata da fonte online. Verifica prima del salvataggio.';
    // Il costo resta intenzionalmente vuoto: il valore di mercato non è un costo d’acquisto.
  }
}
