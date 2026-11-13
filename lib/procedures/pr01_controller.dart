import 'package:flutter/material.dart';

/// Stato e regole di dominio della procedura PR-01.
/// La pagina runtime fornisce solo i campi condivisi e i servizi di persistenza.
class Pr01Controller {
  String condition = 'USATO';
  String completeness = 'COMPLETO';
  String destination = 'COLLEZIONE';

  List<Map<String, dynamic>> collectionCategories = <Map<String, dynamic>>[];
  String? selectedCollectionCategory;
  bool categoriesLoading = false;

  final List<Map<String, dynamic>> pendingObjects = <Map<String, dynamic>>[];
  String? pendingRequestId;

  String? calculateTotal({required String quantity, required String unitPrice}) {
    final parsedQuantity = int.tryParse(quantity.trim());
    final priceText = unitPrice.trim();
    if (parsedQuantity == null || parsedQuantity < 1 || priceText.isEmpty) {
      return null;
    }
    final parsedPrice = double.tryParse(priceText.replaceAll(',', '.'));
    if (parsedPrice == null || parsedPrice < 0) return null;
    final cents = (parsedPrice * 100 * parsedQuantity).round();
    return (cents / 100).toStringAsFixed(2);
  }

  Map<String, dynamic> buildObjectPayload({
    required TextEditingController description,
    required TextEditingController producer,
    required TextEditingController year,
    required TextEditingController productCode,
    required TextEditingController quantity,
    required TextEditingController unitPrice,
    required TextEditingController notes,
    required bool hasMetadata,
    required String? metadataSourceUrl,
    required bool metadataSearchExecuted,
  }) {
    final descriptionValue = description.text.trim();
    if (descriptionValue.isEmpty) {
      throw Exception('La descrizione è obbligatoria.');
    }

    final yearText = year.text.trim();
    int? parsedYear;
    if (yearText.isNotEmpty) {
      parsedYear = int.tryParse(yearText);
      if (parsedYear == null || parsedYear < 1000 ||
          parsedYear > DateTime.now().year + 2) {
        throw Exception('Anno di uscita non valido. Inserisci un anno plausibile oppure lascia il campo vuoto.');
      }
    }

    if (destination == 'COLLEZIONE' &&
        (selectedCollectionCategory == null ||
         !collectionCategories.any((item) =>
           item['codice_categoria'] == selectedCollectionCategory))) {
      throw Exception('Seleziona una categoria COLLEZIONE valida.');
    }

    final parsedQuantity = int.tryParse(quantity.text.trim());
    if (parsedQuantity == null || parsedQuantity < 1) {
      throw Exception('La quantità deve essere un intero positivo.');
    }

    final priceText = unitPrice.text.trim();
    double? totalValue;
    if (priceText.isNotEmpty) {
      final parsedPrice = double.tryParse(priceText.replaceAll(',', '.'));
      if (parsedPrice == null || parsedPrice < 0) {
        throw Exception('Prezzo unitario non valido. Inserisci un importo positivo o zero, oppure lascia vuoto.');
      }
      totalValue = ((parsedPrice * 100 * parsedQuantity).round() / 100.0);
    }

    return <String, dynamic>{
      'oggetti': <Map<String, dynamic>>[
        <String, dynamic>{
          'descrizione': descriptionValue,
          'produttore': producer.text.trim().isEmpty ? null : producer.text.trim(),
          'anno_uscita': parsedYear,
          'codice_prodotto': productCode.text.trim().isEmpty
              ? null : productCode.text.trim(),
          if (hasMetadata)
            'fonte_dati_prodotto': metadataSourceUrl?.trim().isNotEmpty == true
                ? metadataSourceUrl!.trim()
                : (metadataSearchExecuted
                    ? 'RICERCA_ESEGUITA_NESSUNA_FONTE_SELEZIONATA'
                    : 'RICERCA_NON_ESEGUITA'),
          if (hasMetadata) 'stato_verifica_dati': 'DA_VERIFICARE',
          'condizione': condition,
          'completezza': completeness,
          'destinazione': destination,
          'quantita': parsedQuantity,
          if (destination == 'COLLEZIONE')
            'codice_categoria_collezione': selectedCollectionCategory,
          if (totalValue != null) 'valore_oggetto': totalValue,
          'note': notes.text.trim().isEmpty ? null : notes.text.trim(),
        },
      ],
    };
  }
}
