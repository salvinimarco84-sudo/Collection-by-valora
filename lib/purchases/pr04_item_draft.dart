part of '../main.dart';

/// Modello locale di un singolo elemento della bozza PR-04.
class _PurchaseItemDraft {
  final description = TextEditingController();
  final price = TextEditingController();
  final notes = TextEditingController();
  Uint8List? photoBytes;
  String? photoName;
  String? photoUrl;
  String? metadataProducer;
  String? metadataCode;
  int? metadataYear;
  String? metadataSourceUrl;
  String photoStatus = 'Nessuna foto selezionata.';
  String destination = 'COLLEZIONE';
  String? collectionCategoryCode;
  String condition = 'USATO';
  String completeness = 'COMPLETO';

  double? get amount {
    var s = price.text.trim().replaceAll('€', '').replaceAll(' ', '');
    if (s.contains(',')) s = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  Map<String, dynamic> json() => {
    'descrizione': description.text.trim(),
    'valore_acquisto': amount,
    if (notes.text.trim().isNotEmpty) 'note': notes.text.trim(),
    'destinazione': destination,
    'condizione': condition,
    if (destination == 'COLLEZIONE' && collectionCategoryCode != null)
      'codice_categoria_collezione': collectionCategoryCode,
    'completezza': completeness,
    'quantita': 1,
    if (metadataProducer != null) 'produttore': metadataProducer,
    if (metadataCode != null) 'codice_prodotto': metadataCode,
    if (metadataYear != null) 'anno_uscita': metadataYear,
    if (metadataSourceUrl != null) 'fonte_dati_prodotto': metadataSourceUrl,
    if (metadataProducer != null || metadataCode != null || metadataYear != null)
      'stato_verifica_dati': 'DA_VERIFICARE',
    if (photoUrl != null) 'url_immagine_catalogo': photoUrl,
  };

  void dispose() {
    description.dispose();
    price.dispose();
    notes.dispose();
  }
}
