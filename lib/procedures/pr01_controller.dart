import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Stato e regole di dominio della procedura PR-01.
/// La pagina runtime fornisce solo i campi condivisi e i servizi di persistenza.
class Pr01Controller {
  String condition = 'USATO';
  String completeness = 'COMPLETO';
  String destination = 'COLLEZIONE';

  List<Map<String, dynamic>> collectionCategories = <Map<String, dynamic>>[];
  String? selectedCollectionCategory;
  bool categoriesLoading = false;

  // Stato fotografico condiviso dal flusso PR-01 e dalla scheda oggetto.
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  String imageAcquisition = 'CARICAMENTO_FILE';
  String? existingImageUrl;
  String imageStatus = 'Nessuna immagine selezionata.';

  final List<Map<String, dynamic>> pendingObjects = <Map<String, dynamic>>[];
  String? pendingRequestId;

  Future<List<Map<String, dynamic>>> loadCategories(SupabaseClient client) async {
    categoriesLoading = true;
    try {
      final rows = await client.schema('collection')
          .from('master_categorie_collezione')
          .select('codice_categoria, descrizione, ordine_menu, visibile')
          .eq('visibile', true)
          .order('ordine_menu')
          .order('descrizione');
      return (rows as List)
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } finally {
      categoriesLoading = false;
    }
  }

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

  /// Salva in modo transazionale-logico il blocco PR-01 già confermato.
  /// La UI fornisce soltanto le operazioni runtime e la persistenza degli allegati.
  Future<void> savePendingObjects({
    required String sessionId,
    required Future<void> Function() acquireLock,
    required Future<void> Function() releaseLock,
    required bool Function() isLockHeld,
    required Future<Map<String, dynamic>> Function(
      String action,
      Map<String, dynamic> payload,
      String? requestId,
    ) executeProcedure,
    required Future<void> Function(Map<String, dynamic> entry, int objectId)
        persistObjectExtras,
    required void Function() onLockReleased,
    required void Function(String message) onStatus,
  }) async {
    if (pendingObjects.isEmpty) {
      throw Exception('Il blocco PR-01 è vuoto: nessun oggetto da salvare.');
    }

    final pending = List<Map<String, dynamic>>.from(pendingObjects);
    final payload = <String, dynamic>{
      'oggetti': pending
          .map((entry) => Map<String, dynamic>.from(entry['oggetto'] as Map))
          .toList(),
      'dati_confermati': true,
      'altra_operazione': false,
      'conferma_finale': true,
    };

    await acquireLock();
    try {
      final preview = await executeProcedure('preview', payload, null);
      if (preview['errore'] != null) {
        throw Exception(preview['errore'].toString());
      }

      final review = await executeProcedure('review', payload, null);
      if (review['errore'] != null) {
        throw Exception(review['errore'].toString());
      }

      final requestId = pendingRequestId ??= const Uuid().v4();
      final result = await executeProcedure('save', payload, requestId);
      if (result['scrittura_eseguita'] != true) {
        throw Exception(
          'Il runtime non ha confermato il salvataggio del blocco PR-01.',
        );
      }
      if (result['blocco_rilasciato_automaticamente'] != true) {
        throw Exception(
          'Blocco salvato, ma il rilascio del blocco non è stato confermato.',
        );
      }
      onLockReleased();

      final savedRows = result['risultati'];
      if (savedRows is! List || savedRows.length != pending.length) {
        throw Exception(
          'Il runtime non ha restituito tutti i codici oggetto del blocco.',
        );
      }

      for (var index = 0; index < pending.length; index++) {
        final savedRow = savedRows[index] is Map
            ? Map<String, dynamic>.from(savedRows[index] as Map)
            : <String, dynamic>{};
        final savedId = int.tryParse(
          (savedRow['codice_oggetto'] ?? '').toString(),
        );
        if (savedId == null) {
          throw Exception(
            'Codice oggetto mancante nell’elemento ${index + 1}.',
          );
        }
        await persistObjectExtras(pending[index], savedId);
      }

      pendingObjects.clear();
      pendingRequestId = null;
      onStatus('Blocco PR-01 salvato e verificato: ${pending.length} oggetti.');
    } catch (error) {
      if (isLockHeld()) {
        try {
          await releaseLock();
        } catch (_) {
          // Conserva l'errore originale; il rilascio può essere ritentato.
        }
      }
      onStatus(
        'ERRORE nel salvataggio del blocco PR-01. '
        'Gli oggetti restano in attesa: $error',
      );
      rethrow;
    }
  }

}
