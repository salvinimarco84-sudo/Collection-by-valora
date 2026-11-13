import 'package:flutter_test/flutter_test.dart';
import '../lib/procedures/pr02_controller.dart';

void main() {
  group('Pr02Controller', () {
    late Pr02Controller controller;

    setUp(() => controller = Pr02Controller());

    tearDown(() => controller.dispose());

    test('inizializza lo stato della ricerca e della scheda', () {
      expect(controller.searchResults, isEmpty);
      expect(controller.searchCompleted, isFalse);
      expect(controller.showTechnicalTab, isFalse);
      expect(controller.awaitingNextChoice, isFalse);
      expect(controller.pendingChanges, isEmpty);
      expect(controller.pendingImages, isEmpty);
      expect(controller.scrollController.hasClients, isFalse);
    });

    test('mantiene risultati, modifiche confermate e immagini in attesa', () {
      controller.searchResults = [
        {'codice_oggetto': 42, 'descrizione_oggetto': 'Oggetto di prova'},
      ];
      controller.searchCompleted = true;
      controller.showTechnicalTab = true;
      controller.awaitingNextChoice = true;
      controller.pendingChanges.add({'codice_oggetto': 42});
      controller.pendingImages['42'] = {
        'bytes': [1, 2, 3],
        'name': 'foto.jpg',
        'acquisition': 'FOTOCAMERA',
      };

      expect(controller.searchResults.single['codice_oggetto'], 42);
      expect(controller.searchCompleted, isTrue);
      expect(controller.showTechnicalTab, isTrue);
      expect(controller.awaitingNextChoice, isTrue);
      expect(controller.pendingChanges.single['codice_oggetto'], 42);
      expect(controller.pendingImages['42']?['name'], 'foto.jpg');
    });
  });
}
