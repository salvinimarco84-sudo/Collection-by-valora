import 'package:flutter_test/flutter_test.dart';
import 'package:collection_by_valora/procedures/pr15/preorder_domain.dart';

void main() {
  group('PR-15 PREORDER domain', () {
    final ordered = PreorderRecord(
      id: 'PO-001',
      description: 'Set collezionabile prenotato',
      supplier: 'Fornitore',
      orderDate: DateTime(2026, 11, 11),
      expectedReleaseDate: DateTime(2027, 1, 15),
      agreedPriceCents: 20000,
    );

    test('calcola acconti e saldo senza superare il prezzo concordato', () {
      final withDeposit = ordered.addPayment(PreorderPayment(
        id: 'PAY-1', amountCents: 5000, date: DateTime(2026, 11, 11),
      ));
      expect(withDeposit.paidCents, 5000);
      expect(withDeposit.remainingCents, 15000);
      expect(withDeposit.status, PreorderStatus.partiallyPaid);
      expect(() => withDeposit.addPayment(PreorderPayment(
        id: 'PAY-2', amountCents: 16000, date: DateTime(2026, 11, 12),
      )), throwsStateError);
    });

    test('impedisce pagamenti duplicati', () {
      final withDeposit = ordered.addPayment(PreorderPayment(
        id: 'PAY-1', amountCents: 5000, date: DateTime(2026, 11, 11),
      ));
      expect(() => withDeposit.addPayment(PreorderPayment(
        id: 'PAY-1', amountCents: 5000, date: DateTime(2026, 11, 12),
      )), throwsStateError);
    });

    test('converte solo dopo ricezione e saldo completo', () {
      final fullyPaid = ordered
          .addPayment(PreorderPayment(id: 'PAY-1', amountCents: 20000, date: DateTime(2026, 11, 11)))
          .markReceived();
      final draft = fullyPaid.preparePurchase();
      expect(draft.acquisitionCostCents, 20000);
      expect(draft.previouslyPaidCents, 20000);
      final converted = fullyPaid.markConverted('PURCHASE-123');
      expect(converted.status, PreorderStatus.converted);
      expect(converted.purchaseId, 'PURCHASE-123');
      expect(converted.isActive, isFalse);
    });

    test('non crea conversione se saldo non completo o ID PR-04 assente', () {
      final received = ordered.markReceived();
      expect(received.preparePurchase, throwsStateError);
      final paidReceived = ordered
          .addPayment(PreorderPayment(id: 'PAY-1', amountCents: 20000, date: DateTime(2026, 11, 11)))
          .markReceived();
      expect(() => paidReceived.markConverted(' '), throwsArgumentError);
    });
  });
}
