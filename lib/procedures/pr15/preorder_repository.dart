import 'package:supabase_flutter/supabase_flutter.dart';

import 'preorder_domain.dart';

/// Accesso dati PR-15. Le scritture sono limitate dall'RLS all'utente autenticato.
class PreorderRepository {
  PreorderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _masterTable = 'master_preordini';
  static const _paymentsTable = 'pagamenti_preordini';
  static const _historyTable = 'storico_preordini';

  Future<String> create({
    required String description,
    required String supplier,
    required DateTime orderDate,
    required int agreedPriceCents,
    DateTime? expectedReleaseDate,
    String category = '',
    String? imageReference,
    String notes = '',
    String? orderReference,
  }) async {
    _validateText(description, 'Descrizione');
    _validateText(supplier, 'Fornitore');
    if (agreedPriceCents <= 0) {
      throw ArgumentError.value(agreedPriceCents, 'agreedPriceCents', 'Deve essere maggiore di zero.');
    }
    final row = await _client.schema('collection').from(_masterTable).insert({
      'descrizione_oggetto': description.trim(),
      'fornitore': supplier.trim(),
      'data_prenotazione': _date(orderDate),
      'prezzo_concordato': _money(agreedPriceCents),
      if (expectedReleaseDate != null) 'data_uscita_prevista': _date(expectedReleaseDate),
      if (category.trim().isNotEmpty) 'categoria': category.trim(),
      if (imageReference != null && imageReference.trim().isNotEmpty)
        'immagine_riferimento': imageReference.trim(),
      if (notes.trim().isNotEmpty) 'note': notes.trim(),
      if (orderReference != null && orderReference.trim().isNotEmpty)
        'riferimento_ordine': orderReference.trim(),
    }).select('codice_preordine').single();
    return row['codice_preordine'].toString();
  }

  Future<List<PreorderRecord>> list({bool activeOnly = false}) async {
    var query = _client.schema('collection').from(_masterTable).select();
    if (activeOnly) {
      query = query.not('stato', 'in', '(CONVERTITO,ANNULLATO,RIMBORSATO)');
    }
    final rows = await query.order('data_prenotazione', ascending: false)
        .order('codice_preordine', ascending: false);
    final masterRows = (rows as List).whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row)).toList();
    if (masterRows.isEmpty) return const [];
    final ids = masterRows.map((row) => row['codice_preordine']).toList();
    final paymentRows = await _client.schema('collection').from(_paymentsTable)
        .select().inFilter('codice_preordine', ids)
        .order('data_pagamento').order('codice_pagamento');
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final raw in (paymentRows as List).whereType<Map>()) {
      final payment = Map<String, dynamic>.from(raw);
      grouped.putIfAbsent(payment['codice_preordine'].toString(), () => []).add(payment);
    }
    return masterRows.map((row) => _fromRow(row,
      paymentRows: grouped[row['codice_preordine'].toString()] ?? const [],
    )).toList(growable: false);
  }

  Future<PreorderRecord> get(String id) async {
    final code = _parseId(id);
    final row = await _client.schema('collection').from(_masterTable)
        .select().eq('codice_preordine', code).single();
    final payments = await _client.schema('collection').from(_paymentsTable)
        .select().eq('codice_preordine', code)
        .order('data_pagamento').order('codice_pagamento');
    return _fromRow(Map<String, dynamic>.from(row),
      paymentRows: (payments as List).whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry)).toList());
  }

  Future<PreorderRecord> updateDetails({
    required String id,
    required String description,
    required String supplier,
    required DateTime orderDate,
    DateTime? expectedReleaseDate,
    required int agreedPriceCents,
    String category = '',
    String? imageReference,
    String notes = '',
    String? orderReference,
  }) async {
    final code = _parseId(id);
    _validateText(description, 'Descrizione');
    _validateText(supplier, 'Fornitore');
    if (agreedPriceCents <= 0) throw ArgumentError('Il prezzo concordato deve essere maggiore di zero.');
    final existing = await get(id);
    if (existing.status == PreorderStatus.converted ||
        existing.status == PreorderStatus.cancelled ||
        existing.status == PreorderStatus.refunded) {
      throw StateError('Un preorder chiuso non può essere modificato.');
    }
    if (existing.payments.isNotEmpty && agreedPriceCents != existing.agreedPriceCents) {
      throw StateError('Il prezzo concordato non può cambiare dopo il primo pagamento.');
    }
    await _client.schema('collection').from(_masterTable).update({
      'descrizione_oggetto': description.trim(),
      'fornitore': supplier.trim(),
      'data_prenotazione': _date(orderDate),
      'data_uscita_prevista': expectedReleaseDate == null ? null : _date(expectedReleaseDate),
      'prezzo_concordato': _money(agreedPriceCents),
      'categoria': category.trim().isEmpty ? null : category.trim(),
      'immagine_riferimento': imageReference,
      'note': notes.trim().isEmpty ? null : notes.trim(),
      'riferimento_ordine': orderReference,
    }).eq('codice_preordine', code);
    return get(id);
  }

  Future<PreorderRecord> addPayment({
    required String id,
    required int amountCents,
    required DateTime date,
    String method = '',
    String reference = '',
    String note = '',
  }) async {
    final code = _parseId(id);
    if (amountCents <= 0) throw ArgumentError('Il pagamento deve essere maggiore di zero.');
    final record = await get(id);
    if (!record.isActive || record.status == PreorderStatus.received) {
      throw StateError('Il preorder non accetta altri pagamenti in questo stato.');
    }
    if (amountCents > record.remainingCents) {
      throw StateError('Il pagamento supera il saldo residuo.');
    }
    await _client.schema('collection').from(_paymentsTable).insert({
      'codice_preordine': code,
      'data_pagamento': _date(date),
      'importo': _money(amountCents),
      if (method.trim().isNotEmpty) 'metodo_pagamento': method.trim(),
      if (reference.trim().isNotEmpty) 'riferimento_pagamento': reference.trim(),
      if (note.trim().isNotEmpty) 'note': note.trim(),
    });
    return get(id);
  }

  Future<PreorderRecord> markAvailable(String id) =>
      _changeStatus(id, PreorderStatus.available, allowed: {
        PreorderStatus.reserved, PreorderStatus.partiallyPaid,
        PreorderStatus.fullyPaid,
      });

  Future<PreorderRecord> markShipped(String id) =>
      _changeStatus(id, PreorderStatus.shipped, allowed: {
        PreorderStatus.available,
      });

  Future<PreorderRecord> markReceived(String id) =>
      _changeStatus(id, PreorderStatus.received, allowed: {
        PreorderStatus.shipped, PreorderStatus.available,
      });

  Future<List<Map<String, dynamic>>> history(String id) async {
    final code = _parseId(id);
    final rows = await _client.schema('collection').from(_historyTable)
        .select().eq('codice_preordine', code)
        .order('registrato_il', ascending: false);
    return (rows as List).whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  Future<PreorderRecord> _changeStatus(
    String id,
    PreorderStatus next, {
    required Set<PreorderStatus> allowed,
  }) async {
    final code = _parseId(id);
    final current = await get(id);
    if (!allowed.contains(current.status)) {
      throw StateError('Transizione non consentita: ${current.status.name} → ${next.name}.');
    }
    await _client.schema('collection').from(_masterTable)
        .update({'stato': _statusToDb(next)})
        .eq('codice_preordine', code);
    return get(id);
  }

  PreorderRecord _fromRow(
    Map<String, dynamic> row, {
    List<Map<String, dynamic>> paymentRows = const [],
  }) {
    final payments = paymentRows.map((entry) => PreorderPayment(
      id: entry['codice_pagamento'].toString(),
      amountCents: _cents(entry['importo']),
      date: DateTime.parse(entry['data_pagamento'].toString()),
      note: (entry['note'] ?? '').toString(),
    )).toList(growable: false);
    return PreorderRecord(
      id: row['codice_preordine'].toString(),
      description: (row['descrizione_oggetto'] ?? '').toString(),
      supplier: (row['fornitore'] ?? '').toString(),
      orderDate: DateTime.parse(row['data_prenotazione'].toString()),
      expectedReleaseDate: row['data_uscita_prevista'] == null
          ? null : DateTime.parse(row['data_uscita_prevista'].toString()),
      agreedPriceCents: _cents(row['prezzo_concordato']),
      category: (row['categoria'] ?? '').toString(),
      imageReference: row['immagine_riferimento']?.toString(),
      notes: (row['note'] ?? '').toString(),
      payments: payments,
      status: _statusFromDb(row['stato']?.toString()),
      purchaseId: row['codice_acquisto_convertito']?.toString(),
    );
  }

  static PreorderStatus _statusFromDb(String? value) {
    switch (value) {
      case 'PAGAMENTO_PARZIALE': return PreorderStatus.partiallyPaid;
      case 'PAGATO': return PreorderStatus.fullyPaid;
      case 'DISPONIBILE': return PreorderStatus.available;
      case 'SPEDITO': return PreorderStatus.shipped;
      case 'RICEVUTO': return PreorderStatus.received;
      case 'CONVERTITO': return PreorderStatus.converted;
      case 'ANNULLATO': return PreorderStatus.cancelled;
      case 'RIMBORSATO': return PreorderStatus.refunded;
      case 'PRENOTATO':
      default: return PreorderStatus.reserved;
    }
  }

  static String _statusToDb(PreorderStatus value) {
    switch (value) {
      case PreorderStatus.reserved: return 'PRENOTATO';
      case PreorderStatus.partiallyPaid: return 'PAGAMENTO_PARZIALE';
      case PreorderStatus.fullyPaid: return 'PAGATO';
      case PreorderStatus.available: return 'DISPONIBILE';
      case PreorderStatus.shipped: return 'SPEDITO';
      case PreorderStatus.received: return 'RICEVUTO';
      case PreorderStatus.converted: return 'CONVERTITO';
      case PreorderStatus.cancelled: return 'ANNULLATO';
      case PreorderStatus.refunded: return 'RIMBORSATO';
    }
  }

  static int _parseId(String id) {
    final value = int.tryParse(id);
    if (value == null || value <= 0) throw ArgumentError.value(id, 'id', 'Codice preorder non valido.');
    return value;
  }

  static int _cents(dynamic value) {
    final amount = value is num ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return (amount * 100).round();
  }

  static double _money(int cents) => cents / 100;
  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static void _validateText(String value, String label) {
    if (value.trim().isEmpty) throw ArgumentError('$label obbligatoria.');
  }
}
