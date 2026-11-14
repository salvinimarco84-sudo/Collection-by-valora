import 'package:flutter_test/flutter_test.dart';

import '../lib/procedures/pr03_controller.dart';

void main() {
  group('Pr03Controller', () {
    test('accetta una chiusura valida e conserva una copia immutabile', () {
      final controller = Pr03Controller();
      final closure = <String, dynamic>{
        'codice_oggetto': 2581,
        'motivo_chiusura': 'SMARRITO',
        'note': 'Verificato',
      };

      controller.addPendingClosure(closure);
      closure['note'] = 'Modificato dopo l’inserimento';

      expect(controller.pendingClosures, hasLength(1));
      expect(controller.pendingClosures.single['note'], 'Verificato');
      expect(controller.containsClosure(2581), isTrue);
      expect(
        () => controller.pendingClosures.single['note'] = 'Modifica',
        throwsUnsupportedError,
      );
      expect(
        () => controller.pendingClosures.clear(),
        throwsUnsupportedError,
      );
    });

    test('rifiuta codici non validi e duplicati', () {
      final controller = Pr03Controller();

      expect(
        () => controller.addPendingClosure({'codice_oggetto': 'abc'}),
        throwsArgumentError,
      );
      expect(
        () => controller.addPendingClosure({'codice_oggetto': 0}),
        throwsArgumentError,
      );

      controller.addPendingClosure({'codice_oggetto': 2581});
      expect(
        () => controller.addPendingClosure({'codice_oggetto': '2581'}),
        throwsStateError,
      );
      expect(controller.pendingClosures, hasLength(1));
    });

    test('rimuove solo la chiusura salvata e conserva le altre in coda', () {
      final controller = Pr03Controller()
        ..addPendingClosure({'codice_oggetto': 2581})
        ..addPendingClosure({'codice_oggetto': 2582})
        ..addPendingClosure({'codice_oggetto': 2583});

      expect(controller.removePendingClosure(2582), isTrue);
      expect(controller.pendingClosures.map((e) => e['codice_oggetto']),
          [2581, 2583]);
      expect(controller.removePendingClosure(9999), isFalse);
      expect(controller.containsClosure(2582), isFalse);
      expect(controller.containsClosure(2583), isTrue);
    });

    test('espone uno snapshot non modificabile e svuota la coda', () {
      final controller = Pr03Controller()
        ..addPendingClosure({'codice_oggetto': 2581})
        ..addPendingClosure({'codice_oggetto': 2582});

      final snapshot = controller.pendingClosuresSnapshot();
      expect(snapshot.map((entry) => entry['codice_oggetto']), [2581, 2582]);
      expect(() => snapshot.clear(), throwsUnsupportedError);

      controller.clearPendingClosures();
      expect(controller.pendingClosures, isEmpty);
      expect(snapshot, hasLength(2));
      expect(controller.containsClosure(2581), isFalse);
    });

    test('impedisce conferme e salvataggi duplicati e rilascia i guard dopo il flusso', () {
      final controller = Pr03Controller();

      expect(controller.beginClosureConfirmation(), isTrue);
      expect(controller.beginClosureConfirmation(), isFalse);
      expect(controller.isConfirmingClosure, isTrue);

      // Il salvataggio può partire dal flusso di conferma corrente.
      expect(controller.beginSavingClosures(), isTrue);
      expect(controller.beginSavingClosures(), isFalse);
      expect(controller.isSavingClosures, isTrue);

      controller.endSavingClosures();
      expect(controller.isSavingClosures, isFalse);
      controller.endClosureConfirmation();
      expect(controller.isConfirmingClosure, isFalse);

      // Dopo il completamento, una nuova operazione è consentita.
      expect(controller.beginClosureConfirmation(), isTrue);
      controller.endClosureConfirmation();
      expect(controller.beginSavingClosures(), isTrue);
      expect(controller.beginClosureConfirmation(), isFalse);
      controller.endSavingClosures();
    });
  });
}
