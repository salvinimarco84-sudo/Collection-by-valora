/// PR-15 PREORDER: dominio indipendente, senza scritture dirette nel database.
enum PreorderStatus { reserved, partiallyPaid, fullyPaid, available, shipped, received, converted, cancelled, refunded }

class PreorderPayment {
  const PreorderPayment({required this.id, required this.amountCents, required this.date, this.note = ''});
  final String id;
  final int amountCents;
  final DateTime date;
  final String note;
}

class PreorderRecord {
  const PreorderRecord({
    required this.id, required this.description, required this.supplier,
    required this.orderDate, this.expectedReleaseDate,
    required this.agreedPriceCents, this.category = '', this.imageReference,
    this.notes = '', this.orderReference = '', this.payments = const [],
    this.status = PreorderStatus.reserved, this.purchaseId,
  });

  final String id;
  final String description;
  final String supplier;
  final DateTime orderDate;
  final DateTime? expectedReleaseDate;
  final int agreedPriceCents;
  final String category;
  final String? imageReference;
  final String notes;
  final String orderReference;
  final List<PreorderPayment> payments;
  final PreorderStatus status;
  final String? purchaseId;

  int get paidCents => payments.fold<int>(0, (sum, payment) => sum + payment.amountCents);
  int get remainingCents => agreedPriceCents - paidCents;
  bool get isActive => !{PreorderStatus.converted, PreorderStatus.cancelled, PreorderStatus.refunded}.contains(status);

  PreorderRecord addPayment(PreorderPayment payment) {
    if (!isActive || status == PreorderStatus.received) throw StateError('Preorder non pagabile.');
    if (payment.amountCents <= 0 || agreedPriceCents <= 0) throw ArgumentError('Importo non valido.');
    if (payments.any((entry) => entry.id == payment.id)) throw StateError('Pagamento duplicato.');
    if (paidCents + payment.amountCents > agreedPriceCents) throw StateError('Importo superiore al residuo.');
    final next = List<PreorderPayment>.unmodifiable([...payments, payment]);
    // La ricezione è uno stato logistico: un saldo pagato dopo la consegna
    // non deve riportare il preorder a PAGATO/PAGAMENTO_PARZIALE.
    if (status == PreorderStatus.received) return _copy(payments: next);
    return _copy(payments: next, status: paidCents + payment.amountCents == agreedPriceCents
        ? PreorderStatus.fullyPaid : PreorderStatus.partiallyPaid);
  }

  PreorderRecord markAvailable() {
    if (!isActive) throw StateError('Preorder chiuso.');
    return _copy(status: PreorderStatus.available);
  }

  PreorderRecord markShipped() {
    if (!isActive) throw StateError('Preorder chiuso.');
    return _copy(status: PreorderStatus.shipped);
  }

  PreorderRecord markReceived() {
    if (!isActive) throw StateError('Preorder chiuso.');
    return _copy(status: PreorderStatus.received);
  }

  /// Prepara il payload da consegnare a PR-04. Non crea un acquisto.
  PreorderPurchaseDraft preparePurchase() {
    if (status != PreorderStatus.received) throw StateError('Ricezione non confermata.');
    if (agreedPriceCents <= 0 || remainingCents != 0) throw StateError('Saldo preorder non completo.');
    return PreorderPurchaseDraft(
      preorderId: id, description: description, category: category,
      supplier: supplier, acquisitionCostCents: agreedPriceCents,
      previouslyPaidCents: paidCents, imageReference: imageReference,
    );
  }

  /// Chiamare solo dopo conferma del salvataggio riuscito in PR-04.
  PreorderRecord markConverted(String confirmedPurchaseId) {
    preparePurchase();
    if (confirmedPurchaseId.trim().isEmpty) throw ArgumentError('ID acquisto PR-04 obbligatorio.');
    return _copy(status: PreorderStatus.converted, purchaseId: confirmedPurchaseId);
  }

  PreorderRecord _copy({List<PreorderPayment>? payments, PreorderStatus? status, String? purchaseId}) =>
      PreorderRecord(
        id: id, description: description, supplier: supplier, orderDate: orderDate,
        expectedReleaseDate: expectedReleaseDate, agreedPriceCents: agreedPriceCents,
        category: category, imageReference: imageReference, notes: notes,
        orderReference: orderReference, payments: payments ?? this.payments,
        status: status ?? this.status,
        purchaseId: purchaseId ?? this.purchaseId,
      );
}

class PreorderPurchaseDraft {
  const PreorderPurchaseDraft({
    required this.preorderId, required this.description, required this.category,
    required this.supplier, required this.acquisitionCostCents,
    required this.previouslyPaidCents, this.imageReference,
  });
  final String preorderId;
  final String description;
  final String category;
  final String supplier;
  final int acquisitionCostCents;
  final int previouslyPaidCents;
  final String? imageReference;
}
