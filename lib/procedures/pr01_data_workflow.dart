part of '../main.dart';

/// Campi, calcolo e preparazione dei dati della procedura PR-01.
/// Il controller conserva le regole di dominio e la validazione del payload;
/// questa estensione coordina i controller UI e i campi condivisi della scheda.
extension _Pr01DataWorkflow on _ObjectRuntimePageState {
  Widget _collectionCategoryField() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          key: ValueKey(
            'collection-category-${_selectedCollectionCategory ?? 'none'}-'
            '${_collectionCategories.length}-$_categoriesLoading',
          ),
          value: _collectionCategories.any(
            (item) =>
                item['codice_categoria'] == _selectedCollectionCategory,
          )
              ? _selectedCollectionCategory
              : null,
          decoration: InputDecoration(
            labelText: 'Categoria COLLEZIONE *',
            helperText: _categoriesLoading
                ? 'Caricamento categorie…'
                : 'Seleziona la categoria principale.',
          ),
          items: _collectionCategories
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item['codice_categoria'].toString(),
                  child: Text(
                    (item['descrizione'] ?? item['codice_categoria'])
                        .toString(),
                  ),
                ),
              )
              .toList(),
          onChanged: _categoriesLoading
              ? null
              : (value) =>
                  setState(() => _selectedCollectionCategory = value),
        ),
      );

  void _recalculateTotal() {
    if (widget.apiCode != 'PR-01') return;
    final total = _pr01Controller.calculateTotal(
      quantity: _quantity.text,
      unitPrice: _unitPrice.text,
    );
    if (_totalValue.text != (total ?? '')) {
      _totalValue.text = total ?? '';
    }
  }

  Map<String, dynamic> _buildPr01Payload() =>
      _pr01Controller.buildObjectPayload(
        description: _description,
        producer: _producer,
        year: _line,
        productCode: _family,
        quantity: _quantity,
        unitPrice: _unitPrice,
        notes: _notes,
        hasMetadata: _hasAnyMetadata,
        metadataSourceUrl: _metadataSourceUrl,
        metadataSearchExecuted: _metadataSearchExecuted,
      );
}
