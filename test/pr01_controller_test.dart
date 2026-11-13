import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/procedures/pr01_controller.dart';

void main() {
  late Pr01Controller controller;
  late TextEditingController description;
  late TextEditingController producer;
  late TextEditingController year;
  late TextEditingController productCode;
  late TextEditingController quantity;
  late TextEditingController unitPrice;
  late TextEditingController notes;

  setUp(() {
    controller = Pr01Controller();
    controller.collectionCategories = [
      {'codice_categoria': 'LEGO', 'descrizione': 'LEGO'},
    ];
    controller.selectedCollectionCategory = 'LEGO';
    description = TextEditingController(text: 'Set di prova');
    producer = TextEditingController(text: 'LEGO');
    year = TextEditingController(text: '2020');
    productCode = TextEditingController(text: '12345');
    quantity = TextEditingController(text: '2');
    unitPrice = TextEditingController(text: '12,50');
    notes = TextEditingController();
  });

  tearDown(() {
    description.dispose();
    producer.dispose();
    year.dispose();
    productCode.dispose();
    quantity.dispose();
    unitPrice.dispose();
    notes.dispose();
  });

  Map<String, dynamic> buildPayload() => controller.buildObjectPayload(
    description: description,
    producer: producer,
    year: year,
    productCode: productCode,
    quantity: quantity,
    unitPrice: unitPrice,
    notes: notes,
    hasMetadata: false,
    metadataSourceUrl: null,
    metadataSearchExecuted: false,
  );

  test('mantiene lo stato delle immagini nel controller PR-01', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(controller.selectedImageBytes, isNull);
    expect(controller.selectedImageName, isNull);
    expect(controller.imageAcquisition, 'CARICAMENTO_FILE');
    expect(controller.existingImageUrl, isNull);
    expect(controller.imageStatus, 'Nessuna immagine selezionata.');

    controller
      ..selectedImageBytes = bytes
      ..selectedImageName = 'foto.jpg'
      ..imageAcquisition = 'FOTOCAMERA'
      ..existingImageUrl = 'https://example.test/foto.jpg'
      ..imageStatus = 'Foto pronta.';

    expect(controller.selectedImageBytes, bytes);
    expect(controller.selectedImageName, 'foto.jpg');
    expect(controller.imageAcquisition, 'FOTOCAMERA');
    expect(controller.existingImageUrl, 'https://example.test/foto.jpg');
    expect(controller.imageStatus, 'Foto pronta.');
  });

  test('calcola il totale quantità per prezzo unitario', () {
    expect(controller.calculateTotal(quantity: '2', unitPrice: '12,50'), '25.00');
  });

  test('costruisce payload con categoria e valore totale', () {
    final payload = buildPayload();
    final item = (payload['oggetti'] as List).single as Map;
    expect(item['descrizione'], 'Set di prova');
    expect(item['codice_categoria_collezione'], 'LEGO');
    expect(item['valore_oggetto'], 25.0);
    expect(item['quantita'], 2);
  });

  test('rifiuta descrizione vuota', () {
    description.clear();
    expect(buildPayload, throwsA(isA<Exception>()));
  });

  test('rifiuta anno non valido', () {
    year.text = 'abc';
    expect(buildPayload, throwsA(isA<Exception>()));
  });

  test('rifiuta categoria collezione non selezionata', () {
    controller.selectedCollectionCategory = null;
    expect(buildPayload, throwsA(isA<Exception>()));
  });

  // Copre il percorso positivo completo del lotto PR-01.
  test('salva il blocco solo dopo preview e review e persiste ogni oggetto', () async {
    controller.pendingObjects.add({
      'oggetto': {'descrizione': 'Set di prova', 'quantita': 2},
      'categoria': 'LEGO',
    });
    final actions = <String>[];
    final persistedIds = <int>[];
    final statuses = <String>[];
    var lockHeld = false;
    var lockReleasedByRuntime = false;

    await controller.savePendingObjects(
      sessionId: 'session-test',
      acquireLock: () async { lockHeld = true; },
      releaseLock: () async { lockHeld = false; },
      isLockHeld: () => lockHeld,
      executeProcedure: (action, payload, requestId) async {
        actions.add(action);
        expect(payload['conferma_finale'], isTrue);
        expect(payload['dati_confermati'], isTrue);
        if (action == 'save') {
          expect(requestId, isNotNull);
          return {
            'scrittura_eseguita': true,
            'blocco_rilasciato_automaticamente': true,
            'risultati': [
              {'codice_oggetto': 101},
            ],
          };
        }
        return {'errore': null};
      },
      persistObjectExtras: (entry, objectId) async {
        persistedIds.add(objectId);
      },
      onLockReleased: () {
        lockHeld = false;
        lockReleasedByRuntime = true;
      },
      onStatus: statuses.add,
    );

    expect(actions, ['preview', 'review', 'save']);
    expect(persistedIds, [101]);
    expect(lockReleasedByRuntime, isTrue);
    expect(lockHeld, isFalse);
    expect(controller.pendingObjects, isEmpty);
    expect(controller.pendingRequestId, isNull);
    expect(statuses.single, contains('1 oggetti'));
  });

  test('mantiene il blocco in coda e rilascia il lock se il runtime non conferma', () async {
    controller.pendingObjects.add({
      'oggetto': {'descrizione': 'Set da salvare'},
      'categoria': 'LEGO',
    });
    var lockHeld = false;
    var releaseCount = 0;
    final statuses = <String>[];

    await expectLater(
      controller.savePendingObjects(
        sessionId: 'session-test',
        acquireLock: () async { lockHeld = true; },
        releaseLock: () async {
          releaseCount++;
          lockHeld = false;
        },
        isLockHeld: () => lockHeld,
        executeProcedure: (action, payload, requestId) async {
          if (action == 'save') {
            return {
              'scrittura_eseguita': false,
              'blocco_rilasciato_automaticamente': false,
            };
          }
          return {'errore': null};
        },
        persistObjectExtras: (entry, objectId) async {},
        onLockReleased: () {},
        onStatus: statuses.add,
      ),
      throwsA(isA<Exception>()),
    );

    expect(releaseCount, 1);
    expect(lockHeld, isFalse);
    expect(controller.pendingObjects, hasLength(1));
    expect(controller.pendingRequestId, isNotNull);
    expect(statuses.single, contains('Gli oggetti restano in attesa'));
  });
}
