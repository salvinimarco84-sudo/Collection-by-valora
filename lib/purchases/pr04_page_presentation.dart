part of '../main.dart';

extension _Pr04PagePresentation on _NewPurchasePageState {
  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5), Text(subtitle, style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
    ]));

  Widget _choice(String title, String subtitle, IconData icon, bool selected, VoidCallback onTap) => Card(
    color: selected ? ValoraAppearance.instance.card : null,
    child: ListTile(leading: Icon(icon, color: selected ? goldColor : null), title: Text(title),
      subtitle: Text(subtitle), trailing: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off),
      onTap: _busy ? null : onTap));

  Widget _itemEditor(int n) => Pr04ItemEditor(
    key: ValueKey('pr04-item-' + n.toString()),
    index: n,
    item: _items[n],
    busy: _busy,
    categories: _collectionCategories,
    categoriesLoading: _categoriesLoading,
    onChanged: () => setState(_invalidate),
    onPhoto: () => _photoAndRecognize(_items[n]),
    suggestedMarketValue: widget.suggestedMarketValue,
  );

  Widget _line(String label, String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      Expanded(child: Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500, color: bold ? goldColor : null))),
      const SizedBox(width: 8), Flexible(child: Text(value, textAlign: TextAlign.end, style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: bold ? goldColor : null))),
    ]));

  Widget _valoraContent() {
    final item = _items.first;
    final marketValue = widget.suggestedMarketValue;
    if (_preview != null) {
      return Pr04ValoraPurchaseReview(
        description: item.description.text.trim(),
        dateLabel: _dateLabel(_date),
        purchaseCost: item.amount ?? 0,
        marketValue: marketValue,
        preview: _preview!,
        busy: _busy,
        onEdit: () => setState(_invalidate),
        onConfirm: () {
          setState(() => _dataConfirmed = true);
          _save();
        },
      );
    }
    return Pr04ValoraPurchaseForm(
      itemEditor: _itemEditor(0),
      metadataDetails: [
        if ((item.metadataProducer ?? '').trim().isNotEmpty) 'Produttore/Editore: ${item.metadataProducer}',
        if ((item.metadataCode ?? '').trim().isNotEmpty) 'Codice prodotto: ${item.metadataCode}',
        if (item.metadataYear != null) 'Anno: ${item.metadataYear}',
        if ((item.metadataSourceUrl ?? '').trim().isNotEmpty) 'Fonte metadati: ${item.metadataSourceUrl}',
      ],
      dateLabel: _dateLabel(_date),
      busy: _busy,
      status: _status,
      onPickDate: _pickDate,
      onPreview: _runPreview,
    );
  }

  Widget _content() {
    if (widget.valoraMode) return _valoraContent();
    return Pr04PurchaseStepContent(
    step: _step,
    type: _type,
    dateLabel: _dateLabel(_date),
    countController: _count,
    items: _items,
    total: _total,
    pendingPurchaseCount: _pendingPurchases.length,
    pendingTotal: _pendingTotal,
    busy: _busy,
    itemEditor: _itemEditor,
    onSelectSingle: () => setState(() { _type = 'SINGOLO'; _resize(1); _count.text = '1'; }),
    onSelectLot: () => setState(() { _type = 'LOTTO'; if (_items.length < 2) _resize(2); _count.text = _items.length.toString(); }),
    onContinue: () => setState(() => _step = 1),
    onBackToType: () => setState(() => _step = 0),
    onBackToDetails: () => setState(() => _step = 1),
    onPickDate: _pickDate,
    onContinueToItems: () {
      if (_type == 'LOTTO') {
        final n = int.tryParse(_count.text.trim());
        if (n == null || n < 2 || n > 500) { _notice('Inserisci un numero compreso fra 2 e 500.'); return; }
        _resize(n);
      } else {
        _resize(1);
      }
      setState(() => _step = 2);
    },
    onContinueToSummary: () {
      if (!_valid()) return;
      setState(() => _step = 3);
    },
    onRunPreview: _runPreview,
    onQueueAnother: _queueCurrentAndStartNext,
    onSaveAndExit: () {
      setState(() { _dataConfirmed = true; });
      _save();
    },
    onEditObjects: () => setState(() => _step = 2),
    onEditData: () => setState(() { _step = 2; _invalidate(); }),
  );
  }

  Widget _buildPr04PurchasePage(BuildContext context) {
    if (widget.valoraMode) {
      return Pr04ValoraPurchasePageFrame(busy: _busy, content: _content());
    }
    return Pr04PurchasePageFrame(
      step: _step,
      busy: _busy,
      color: ValoraAppearance.instance.colorFor('ACQUISTI'),
      status: _status,
      content: _content(),
    );
  }
}
