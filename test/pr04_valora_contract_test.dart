import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainSource = File('lib/main.dart').readAsStringSync();
  final page = File('lib/purchases/pr04_valora_page.dart').readAsStringSync();
  final runtime = File('lib/purchases/pr04_runtime_procedure.dart').readAsStringSync();
  final form = File('lib/purchases/pr04_form_content.dart').readAsStringSync();
  final frame = File('lib/purchases/pr04_page_frame.dart').readAsStringSync();
  final valora = File('lib/procedures/valora_service_page.dart').readAsStringSync();
  final edge = File('supabase/functions/pr-04-valora-test/index.ts').readAsStringSync();
  final baseMigration = File('supabase/migrations/20261110151505_pr04_valora_independent_purchase.sql').readAsStringSync();
  final migration = File('supabase/migrations/20261110151749_pr04_valora_validate_purchase_payload.sql').readAsStringSync();
  final historyMigration = File('supabase/migrations/20261110152422_pr04_valora_align_history_origin.sql').readAsStringSync();
  final provenanceMigration = File('supabase/migrations/20261110152539_pr04_valora_require_metadata_provenance.sql').readAsStringSync();

  group('Contratto PR-04 VALORA indipendente', () {
    test('PR-04 originale mantiene runtime, form e frame separati', () {
      expect(mainSource, contains("part 'purchases/pr04_runtime_procedure.dart';"));
      expect(mainSource, contains("part 'purchases/pr04_form_content.dart';"));
      expect(mainSource, contains("part 'purchases/pr04_page_frame.dart';"));
      expect(runtime, isNot(contains('PR-04 VALORA')));
      expect(form, isNot(contains('PR-04 VALORA')));
      expect(frame, isNot(contains('PR-04 VALORA')));
      expect(page, contains('class Pr04ValoraPage'));
      expect(page, isNot(contains('class NewPurchasePage')));
    });

    test('il candidato confermato apre solo PR-04 VALORA', () {
      expect(valora, contains('Pr04ValoraPage('));
      expect(valora, isNot(contains('builder: (_) => NewPurchasePage(')));
      expect(mainSource, contains("part 'purchases/pr04_valora_page.dart';"));
    });

    test('nessuna scrittura prima della doppia conferma', () {
      final confirmDialog = page.indexOf('showDialog<bool>');
      final saveCall = page.indexOf("functions.invoke(\n        'pr-04-valora-test'");
      expect(confirmDialog, greaterThanOrEqualTo(0));
      expect(saveCall, greaterThan(confirmDialog));
      expect(page, contains('_reviewed'));
      expect(page, contains('bool _dateConfirmed = false;'));
      expect(page, contains('Seleziona destinazione, condizione e completezza.'));
      expect(page, contains('bool _saveAttempted = false;'));
      expect(page, contains('_saveAttempted = true'));
      expect(page, contains('RIPROVA LA STESSA REGISTRAZIONE'));
      expect(page, contains("'conferma_finale': true"));
    });

    test('il costo effettivo resta distinto dal valore di mercato', () {
      expect(page, contains('final _cost = TextEditingController();'));
      expect(page, contains('labelText: \'Costo effettivo di acquisto (€) *\''));
      expect(page, contains('Campo volutamente vuoto.'));
      expect(page, contains("'valore_acquisto': double.parse(amount.toStringAsFixed(2))"));
      expect(page, isNot(contains("'valore_acquisto': widget.suggestedMarketValue")));
    });

    test('backend crea sempre un nuovo oggetto e rende idempotente la richiesta', () {
      expect(edge, contains('pr_04_valora_nuovo_acquisto'));
      expect(baseMigration, contains('pr04_valora_requests'));
      expect(migration, contains('pg_advisory_xact_lock'));
      expect(migration, contains('insert into collection.master_oggetti'));
      expect(migration, contains('insert into collection.acquisti_oggetti'));
      expect(migration, contains('collection.verifica_quadratura_acquisto'));
      expect(historyMigration, contains("'NUOVO ACQUISTO'"));
      expect(historyMigration, isNot(contains("'CREAZIONE','PR-04 VALORA'")));
      expect(provenanceMigration, contains('ogni metadato prodotto richiede la fonte effettiva'));
      expect(migration, contains('oggetto_nuovo_creato'));
      expect(migration, isNot(contains('select mo.codice_oggetto')));
      expect(edge, contains('app_authorized_users'));
    });

    test('PR18 viene salvata solo dopo la verifica acquisto e sul nuovo codice oggetto', () {
      final purchaseVerified = page.indexOf("_purchaseSaved = true");
      final valuationCall = page.indexOf("'pr-18-valuation-test'");
      expect(purchaseVerified, greaterThanOrEqualTo(0));
      expect(valuationCall, greaterThan(purchaseVerified));
      expect(page, contains("'codice_oggetto': objectId"));
      expect(page, contains("if (objectId == null || valuation == null || _valuationSaved) return;"));
    });
  });
}
