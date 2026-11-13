part of '../../main.dart';

class Pr15PreorderPage extends StatefulWidget {
  const Pr15PreorderPage({super.key});
  @override
  State<Pr15PreorderPage> createState() => _Pr15PreorderPageState();
}

class _Pr15PreorderPageState extends State<Pr15PreorderPage> {
  final PreorderRepository _repository = PreorderRepository();
  List<PreorderRecord> _records = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _busy = true; _error = null; });
    try {
      final rows = await _repository.list();
      if (mounted) setState(() => _records = rows);
    } catch (e) {
      if (mounted) setState(() => _error = 'Caricamento preorder non riuscito: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _Pr15CreateDialog(),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final id = await _repository.create(
        description: result['description'] as String,
        supplier: result['supplier'] as String,
        orderDate: result['orderDate'] as DateTime,
        expectedReleaseDate: result['expectedDate'] as DateTime?,
        agreedPriceCents: result['priceCents'] as int,
        category: result['category'] as String,
        orderReference: result['reference'] as String,
        notes: result['notes'] as String,
      );
      await _load();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Pr15PreorderDetailPage(preorderId: id),
      ));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Creazione preorder non riuscita: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _money(int cents) => '€ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  String _status(PreorderStatus status) => switch (status) {
    PreorderStatus.reserved => 'PRENOTATO',
    PreorderStatus.partiallyPaid => 'PAGAMENTO PARZIALE',
    PreorderStatus.fullyPaid => 'PAGATO',
    PreorderStatus.available => 'DISPONIBILE',
    PreorderStatus.shipped => 'SPEDITO',
    PreorderStatus.received => 'RICEVUTO',
    PreorderStatus.converted => 'CONVERTITO',
    PreorderStatus.cancelled => 'ANNULLATO',
    PreorderStatus.refunded => 'RIMBORSATO',
  };

  @override
  Widget build(BuildContext context) {
    final accent = ValoraAppearance.instance.colorFor('ACQUISTI');
    return Scaffold(
      appBar: AppBar(title: const Text('PR-15 · PREORDER'), actions: [
        IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Aggiorna'),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _create,
        icon: const Icon(Icons.add),
        label: const Text('NUOVO PREORDER'),
        backgroundColor: accent,
      ),
      body: SafeArea(child: _busy && _records.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('REGISTRO PRENOTAZIONI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('${_records.where((r) => r.isActive).length} preorder attivi · ${_records.length} complessivi'),
                  const SizedBox(height: 4),
                  Text('Acconti e pagamenti restano nel registro PR-15 fino alla conversione in acquisto ordinario.',
                    style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
                ]),
              )),
              if (_error != null) Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              if (_records.isEmpty && !_busy) const Padding(
                padding: EdgeInsets.symmetric(vertical: 42),
                child: Column(children: [
                  Icon(Icons.inventory_2_outlined, size: 48),
                  SizedBox(height: 12),
                  Text('Nessun preorder registrato.'),
                  SizedBox(height: 4),
                  Text('Usa NUOVO PREORDER per inserire la prima prenotazione.'),
                ]),
              ),
              ..._records.map((record) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(backgroundColor: accent.withOpacity(.14),
                    child: Icon(Icons.bookmark_outline, color: accent)),
                  title: Text(record.description, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Fornitore: ${record.supplier}'),
                      Text('Stato: ${_status(record.status)}'),
                      Text('Versato ${_money(record.paidCents)} · Residuo ${_money(record.remainingCents)}'),
                    ]),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => Pr15PreorderDetailPage(preorderId: record.id),
                    ));
                    if (mounted) _load();
                  },
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pr15CreateDialog extends StatefulWidget {
  const _Pr15CreateDialog();
  @override
  State<_Pr15CreateDialog> createState() => _Pr15CreateDialogState();
}

class _Pr15CreateDialogState extends State<_Pr15CreateDialog> {
  final _description = TextEditingController();
  final _supplier = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _reference = TextEditingController();
  final _notes = TextEditingController();
  DateTime _orderDate = DateTime.now();
  DateTime? _expectedDate;

  @override
  void dispose() {
    _description.dispose(); _supplier.dispose(); _category.dispose();
    _price.dispose(); _reference.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
    context: context, initialDate: initial, firstDate: DateTime(2000),
    lastDate: DateTime(2100), cancelText: 'ANNULLA', confirmText: 'CONFERMA');

  String _date(DateTime? value) => value == null ? 'Non indicata'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  void _submit() {
    final amount = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (_description.text.trim().isEmpty || _supplier.text.trim().isEmpty ||
        amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci descrizione, fornitore e prezzo valido.')),
      );
      return;
    }
    Navigator.of(context).pop({
      'description': _description.text.trim(),
      'supplier': _supplier.text.trim(),
      'category': _category.text.trim(),
      'priceCents': (amount * 100).round(),
      'reference': _reference.text.trim(),
      'notes': _notes.text.trim(),
      'orderDate': _orderDate,
      'expectedDate': _expectedDate,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('NUOVA PRENOTAZIONE'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _description, autofocus: true, decoration: const InputDecoration(labelText: 'Oggetto / descrizione *')),
      TextField(controller: _supplier, decoration: const InputDecoration(labelText: 'Fornitore *')),
      TextField(controller: _category, decoration: const InputDecoration(labelText: 'Categoria')),
      TextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Prezzo concordato (€) *')),
      TextField(controller: _reference, decoration: const InputDecoration(labelText: 'Riferimento ordine')),
      TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Note')),
      const SizedBox(height: 10),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Data prenotazione'),
        subtitle: Text(_date(_orderDate)), trailing: const Icon(Icons.calendar_today),
        onTap: () async { final d = await _pick(_orderDate); if (d != null) setState(() => _orderDate = d); }),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Uscita prevista'),
        subtitle: Text(_date(_expectedDate)), trailing: const Icon(Icons.event),
        onTap: () async { final d = await _pick(_expectedDate ?? DateTime.now()); if (d != null) setState(() => _expectedDate = d); }),
    ]))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULLA')),
      FilledButton(onPressed: _submit, child: const Text('CREA PREORDER')),
    ],
  );
}

class _Pr15EditDialog extends StatefulWidget {
  const _Pr15EditDialog({required this.record});
  final PreorderRecord record;

  @override
  State<_Pr15EditDialog> createState() => _Pr15EditDialogState();
}

class _Pr15EditDialogState extends State<_Pr15EditDialog> {
  late final TextEditingController _description;
  late final TextEditingController _supplier;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _reference;
  late final TextEditingController _notes;
  late DateTime _orderDate;
  DateTime? _expectedDate;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _description = TextEditingController(text: r.description);
    _supplier = TextEditingController(text: r.supplier);
    _category = TextEditingController(text: r.category);
    _price = TextEditingController(text: (r.agreedPriceCents / 100).toStringAsFixed(2));
    _reference = TextEditingController(text: r.orderReference);
    _notes = TextEditingController(text: r.notes);
    _orderDate = r.orderDate;
    _expectedDate = r.expectedReleaseDate;
  }

  @override
  void dispose() {
    _description.dispose(); _supplier.dispose(); _category.dispose();
    _price.dispose(); _reference.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
    context: context, initialDate: initial, firstDate: DateTime(2000),
    lastDate: DateTime(2100), cancelText: 'ANNULLA', confirmText: 'CONFERMA');

  String _date(DateTime? value) => value == null ? 'Non indicata'
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  void _submit() {
    final amount = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    if (_description.text.trim().isEmpty || _supplier.text.trim().isEmpty ||
        amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci descrizione, fornitore e prezzo valido.')),
      );
      return;
    }
    Navigator.of(context).pop({
      'description': _description.text.trim(),
      'supplier': _supplier.text.trim(),
      'category': _category.text.trim(),
      'priceCents': (amount * 100).round(),
      'reference': _reference.text.trim(),
      'notes': _notes.text.trim(),
      'orderDate': _orderDate,
      'expectedDate': _expectedDate,
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('MODIFICA PREORDER'),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(
      mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _description, decoration: const InputDecoration(labelText: 'Oggetto / descrizione *')),
        TextField(controller: _supplier, decoration: const InputDecoration(labelText: 'Fornitore *')),
        TextField(controller: _category, decoration: const InputDecoration(labelText: 'Categoria')),
        TextField(controller: _price,
          readOnly: widget.record.payments.isNotEmpty,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Prezzo concordato (€) *',
            helperText: widget.record.payments.isNotEmpty
              ? 'Bloccato perché sono già presenti pagamenti.' : null,
          )),
        TextField(controller: _reference, decoration: const InputDecoration(labelText: 'Riferimento ordine')),
        TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Note')),
        const SizedBox(height: 10),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Data prenotazione'),
          subtitle: Text(_date(_orderDate)), trailing: const Icon(Icons.calendar_today),
          onTap: () async { final d = await _pick(_orderDate); if (d != null) setState(() => _orderDate = d); }),
        ListTile(contentPadding: EdgeInsets.zero, title: const Text('Uscita prevista'),
          subtitle: Text(_date(_expectedDate)), trailing: const Icon(Icons.event),
          onTap: () async { final d = await _pick(_expectedDate ?? DateTime.now()); if (d != null) setState(() => _expectedDate = d); }),
      ],
    ))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('ANNULLA')),
      FilledButton(onPressed: _submit, child: const Text('SALVA MODIFICHE')),
    ],
  );
}

class Pr15PreorderDetailPage extends StatefulWidget {
  const Pr15PreorderDetailPage({super.key, required this.preorderId});
  final String preorderId;
  @override
  State<Pr15PreorderDetailPage> createState() => _Pr15PreorderDetailPageState();
}

class _Pr15PreorderDetailPageState extends State<Pr15PreorderDetailPage> {
  final PreorderRepository _repository = PreorderRepository();
  PreorderRecord? _record;
  List<Map<String, dynamic>> _history = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _busy = true; _error = null; });
    try {
      final record = await _repository.get(widget.preorderId);
      final history = await _repository.history(widget.preorderId);
      if (mounted) setState(() { _record = record; _history = history; });
    } catch (e) {
      if (mounted) setState(() => _error = 'Lettura preorder non riuscita: $e');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  String _money(int cents) => '€ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';
  String _date(DateTime? d) => d == null ? 'Non indicata' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _edit(PreorderRecord record) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _Pr15EditDialog(record: record),
    );
    if (result == null || !mounted) return;
    try {
      setState(() => _busy = true);
      await _repository.updateDetails(
        id: record.id,
        description: result['description'] as String,
        supplier: result['supplier'] as String,
        category: result['category'] as String,
        agreedPriceCents: result['priceCents'] as int,
        orderDate: result['orderDate'] as DateTime,
        expectedReleaseDate: result['expectedDate'] as DateTime?,
        orderReference: result['reference'] as String,
        notes: result['notes'] as String,
      );
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preorder aggiornato.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Modifica preorder non riuscita: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payment() async {
    final amount = TextEditingController();
    final note = TextEditingController();
    final reference = TextEditingController();
    String method = 'Carta';
    final result = await showDialog<Map<String, dynamic>>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialog) => AlertDialog(
        title: const Text('REGISTRA PAGAMENTO'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'Importo (€)', hintText: _money(_record!.remainingCents))),
          DropdownButtonFormField<String>(value: method, decoration: const InputDecoration(labelText: 'Metodo'),
            items: ['Carta','Bonifico','Contanti','PayPal','Altro'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) { if (v != null) setDialog(() => method = v); }),
          TextField(controller: reference, decoration: const InputDecoration(labelText: 'Riferimento pagamento')),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ANNULLA')),
          FilledButton(onPressed: () {
            final parsed = double.tryParse(amount.text.trim().replaceAll(',', '.'));
            if (parsed == null || parsed <= 0) return;
            Navigator.pop(dialogContext, {'amountCents': (parsed * 100).round(), 'method': method,
              'reference': reference.text.trim(), 'note': note.text.trim()});
          }, child: const Text('REGISTRA')),
        ],
      ),
    ));
    amount.dispose(); note.dispose(); reference.dispose();
    if (result == null) return;
    try {
      setState(() => _busy = true);
      await _repository.addPayment(id: widget.preorderId,
        amountCents: result['amountCents'] as int, date: DateTime.now(),
        method: result['method'] as String, reference: result['reference'] as String,
        note: result['note'] as String);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pagamento non registrato: $e')));
    }
  }

  Future<void> _convertToPurchase(PreorderRecord record) async {
    if (record.status != PreorderStatus.received || record.remainingCents != 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('CONVERSIONE IN ACQUISTO'),
        content: Text('PR-15 passerà i dati a PR-04.\n\nOggetto: ${record.description}\nCosto d’acquisto: ${_money(record.agreedPriceCents)}\nGià versato: ${_money(record.paidCents)}\n\nPR-04 registrerà un unico acquisto ordinario per il costo complessivo. I pagamenti PR-15 non verranno duplicati come movimenti di cassa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ANNULLA')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('APRI PR-04')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final purchaseId = await Navigator.of(context).push<String>(MaterialPageRoute(
      builder: (_) => NewPurchasePage(
        preorderConversion: true,
        initialMetadata: {
          'descrizione': record.description,
          'categoria_preorder': record.category,
          'prezzo_acquisto_preorder': record.agreedPriceCents / 100,
          'codice_preordine': record.id,
          if (record.imageReference != null) 'url_immagine_catalogo': record.imageReference,
        },
      ),
    ));
    if (!mounted || purchaseId == null || purchaseId.trim().isEmpty) return;
    try {
      setState(() => _busy = true);
      await _repository.markConverted(id: record.id, confirmedPurchaseId: purchaseId);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preorder ${record.id} convertito nell’acquisto PR-04 #$purchaseId.')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Acquisto PR-04 salvato, ma collegamento PR-15 non completato: $e. Riprova la conversione dalla scheda.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeStatus(Future<PreorderRecord> Function(String) action, String label) async {
    try {
      setState(() => _busy = true);
      await action(widget.preorderId);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label non riuscito: $e')));
    }
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) =>
      OutlinedButton.icon(onPressed: _busy ? null : onTap, icon: Icon(icon), label: Text(label));

  @override
  Widget build(BuildContext context) {
    final r = _record;
    final accent = ValoraAppearance.instance.colorFor('ACQUISTI');
    return Scaffold(
      appBar: AppBar(title: const Text('DETTAGLIO PREORDER'), actions: [
        IconButton(onPressed: _busy ? null : _load, icon: const Icon(Icons.refresh)),
      ]),
      body: SafeArea(child: _busy && r == null
        ? const Center(child: CircularProgressIndicator())
        : r == null
          ? Center(child: Text(_error ?? 'Preorder non disponibile.'))
          : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.description, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Fornitore: ${r.supplier}'),
              Text('Categoria: ${r.category.isEmpty ? 'Non indicata' : r.category}'),
              Text('Stato: ${r.status.name.toUpperCase()}'),
              Text('Prenotazione: ${_date(r.orderDate)}'),
              Text('Uscita prevista: ${_date(r.expectedReleaseDate)}'),
              const Divider(),
              Text('Prezzo concordato: ${_money(r.agreedPriceCents)}'),
              Text('Totale versato: ${_money(r.paidCents)}'),
              Text('Saldo residuo: ${_money(r.remainingCents)}',
                style: TextStyle(fontWeight: FontWeight.w900, color: r.remainingCents == 0 ? Colors.green : accent)),
              if (r.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Note: ${r.notes}')),
              if (r.purchaseId != null) Text('Acquisto PR-04: #${r.purchaseId}'),
              if (r.status != PreorderStatus.converted &&
                  r.status != PreorderStatus.cancelled &&
                  r.status != PreorderStatus.refunded)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _edit(r),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('MODIFICA PREORDER'),
                    ),
                  ),
                ),
            ]))),
            if (r.status == PreorderStatus.received && r.remainingCents == 0 && r.purchaseId == null)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity,
                child: FilledButton.icon(onPressed: _busy ? null : () => _convertToPurchase(r),
                  icon: const Icon(Icons.shopping_bag_outlined), label: const Text('CONVERTI IN ACQUISTO ORDINARIO · PR-04')))),
            if (r.isActive) Wrap(spacing: 8, runSpacing: 8, children: [
              if (r.status != PreorderStatus.shipped && r.remainingCents > 0)
                _action('REGISTRA PAGAMENTO', Icons.payments_outlined, _payment),
              if ({PreorderStatus.reserved, PreorderStatus.partiallyPaid, PreorderStatus.fullyPaid}.contains(r.status))
                _action('DISPONIBILE', Icons.inventory_2_outlined, () => _changeStatus(_repository.markAvailable, 'Aggiornamento')),
              if (r.status == PreorderStatus.available)
                _action('SPEDITO', Icons.local_shipping_outlined, () => _changeStatus(_repository.markShipped, 'Spedizione')),
              if (r.status == PreorderStatus.shipped || r.status == PreorderStatus.available)
                _action('RICEVUTO', Icons.check_circle_outline, () => _changeStatus(_repository.markReceived, 'Ricezione')),
            ]),
            const SizedBox(height: 16),
            Text('PAGAMENTI E STORICO', style: TextStyle(fontWeight: FontWeight.w900, color: accent, letterSpacing: 1)),
            const SizedBox(height: 8),
            ...r.payments.map((p) => ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(_money(p.amountCents)),
              subtitle: Text('${_date(p.date)} ${p.note.isEmpty ? '' : '· ${p.note}'}'),
            )),
            if (r.payments.isEmpty) const ListTile(title: Text('Nessun pagamento registrato.')),
            const Divider(),
            ..._history.map((event) => ListTile(
              dense: true, leading: const Icon(Icons.history),
              title: Text((event['tipo_evento'] ?? 'Evento').toString().replaceAll('_', ' ')),
              subtitle: Text('${event['stato_precedente'] ?? ''} → ${event['stato_nuovo'] ?? ''} · ${event['registrato_il'] ?? ''}'),
            )),
          ])),
      ),
    );
  }
}
