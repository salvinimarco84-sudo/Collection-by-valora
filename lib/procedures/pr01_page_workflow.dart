part of '../main.dart';

/// Composizione della pagina PR-01 e lifecycle dei suoi listener.
/// Il caricamento categorie resta condiviso con PR-02 e OBJECT_MASTER.
extension _Pr01PageWorkflow on _ObjectRuntimePageState {
  void _initializePr01Page() {
    if (widget.apiCode != 'PR-01') return;
    _quantity.addListener(_recalculateTotal);
    _unitPrice.addListener(_recalculateTotal);
  }

  void _disposePr01Page() {
    if (widget.apiCode != 'PR-01') return;
    _quantity.removeListener(_recalculateTotal);
    _unitPrice.removeListener(_recalculateTotal);
  }

  Widget _buildPr01Page() {
    return Pr01Page(
        title: widget.title,
        sectionColor: sectionColor,
        userLabel: Supabase.instance.client.auth.currentUser?.email ?? 'sessione autenticata',
        lockHeld: _lockHeld,
        loading: _loading,
        status: _output,
        form: Pr01FormContent(
          sectionColor: sectionColor,
          descriptionField: _field(_description, 'Descrizione oggetto *', lines: 2, focusNode: _descriptionFocus),
          imageField: _imageField(),
          producerField: _field(_producer, 'Produttore (facoltativo)'),
          yearField: _field(_line, 'Anno di uscita (facoltativo)', type: TextInputType.number),
          productCodeField: _field(_family, 'Codice prodotto (facoltativo)'),
          conditionField: _dropdown('Condizione *', _condition, const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], (v) => setState(() => _condition = v!)),
          completenessField: _dropdown('Completezza *', _completeness, const ['SIGILLATO','COMPLETO','COMPLETO CON ISTRUZIONI','COMPLETO CON SCATOLA E ISTRUZIONI','INCOMPLETO'], (v) => setState(() => _completeness = v!)),
          destinationField: _dropdown('Destinazione *', _destination, const ['COLLEZIONE','RIVENDITA','ALTRO'], (v) => setState(() { _destination = v!; if (_destination != 'COLLEZIONE') _selectedCollectionCategory = null; })),
          collectionCategoryField: _destination == 'COLLEZIONE' ? _collectionCategoryField() : null,
          quantityField: _field(_quantity, 'Quantità', type: TextInputType.number),
          unitPriceField: _field(_unitPrice, 'Prezzo unitario (€)', type: const TextInputType.numberWithOptions(decimal: true)),
          totalValueField: TextField(
            controller: _totalValue,
            readOnly: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valore totale calcolato (€)',
              helperText: 'Quantità × prezzo unitario. Il totale viene registrato in valore_oggetto.',
            ),
          ),
          notesField: _field(_notes, 'Note', lines: 2),
          marketValueField: TextField(
            controller: _marketValue,
            readOnly: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0,00',
              helperText: 'Valore restituito dalla procedura di valutazione. 0,00 finché non è disponibile una stima.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        onSave: _loading ? null : () => _run(_confirmAndSaveNewObject),
        onReleaseLock: _loading || !_lockHeld ? null : () => _run(_releaseLock),
      );
  }
}