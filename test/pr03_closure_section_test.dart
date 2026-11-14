import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/procedures/pr03_closure_section.dart';

void main() {
  testWidgets('PR-03 mostra la scheda selezionata e tutte le chiusure in attesa',
      (tester) async {
    final search = TextEditingController(text: 'Batman');
    final notes = TextEditingController();
    var searchCalls = 0;
    var confirmCalls = 0;
    var selectedReason = 'SMARRITO';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Pr03ClosureSection(
            searchController: search,
            notesController: notes,
            pendingClosures: const [
              {
                'codice_oggetto': 2581,
                'descrizione': 'Batman Tumbler',
                'motivo_chiusura': 'SMARRITO',
              },
              {
                'codice_oggetto': 2582,
                'descrizione': 'Batmobile',
                'motivo_chiusura': 'DATO VIA',
              },
            ],
            selectedObject: const {
              'codice_oggetto': 2583,
              'descrizione_oggetto': 'Batman LEGO',
              'stato': 'DISPONIBILE',
              'quantita': 1,
            },
            hasSelectedObject: true,
            closeReason: selectedReason,
            onCloseReasonChanged: (value) => selectedReason = value,
            loading: false,
            sectionColor: Colors.amber,
            onSearch: () => searchCalls++,
            onConfirm: () => confirmCalls++,
          ),
        ),
      ),
    ));

    expect(find.text('OGGETTO SELEZIONATO'), findsOneWidget);
    expect(find.text('2583 · Batman LEGO'), findsOneWidget);
    expect(find.text('Stato: DISPONIBILE · Quantità: 1'), findsOneWidget);
    expect(find.text('CHIUSURE IN ATTESA · 2'), findsOneWidget);
    expect(find.textContaining('2581 · Batman Tumbler · SMARRITO'), findsOneWidget);
    expect(find.textContaining('2582 · Batmobile · DATO VIA'), findsOneWidget);

    await tester.tap(find.text('CERCA E SELEZIONA OGGETTO'));
    await tester.pump();
    expect(searchCalls, 1);

    await tester.tap(find.text('CONFERMA CHIUSURA'));
    await tester.pump();
    expect(confirmCalls, 1);

    search.dispose();
    notes.dispose();
  });

  testWidgets('PR-03 non mostra il riepilogo quando la coda è vuota',
      (tester) async {
    final search = TextEditingController();
    final notes = TextEditingController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Pr03ClosureSection(
          searchController: search,
          notesController: notes,
          pendingClosures: const [],
          selectedObject: null,
          hasSelectedObject: false,
          closeReason: 'SMARRITO',
          onCloseReasonChanged: (_) {},
          loading: false,
          sectionColor: Colors.amber,
          onSearch: () {},
          onConfirm: () {},
        ),
      ),
    ));

    expect(find.textContaining('CHIUSURE IN ATTESA'), findsNothing);
    search.dispose();
    notes.dispose();
  });

}
