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
}
