part of '../main.dart';

/// Costruzione e validazione del payload di modifica PR-02.
extension _Pr02PayloadWorkflow on _ObjectRuntimePageState {
  Map<String, dynamic> _buildPr02Payload() {
  if (_loadedObjectId != id) throw Exception('Carica la scheda completa del codice selezionato prima di procedere.');
  final item = <String, dynamic>{'codice_oggetto': id};
  if (_description.text.trim() != (_currentObject?['descrizione_oggetto'] ?? _currentObject?['descrizione'] ?? '').toString()) {
    item['descrizione'] = _description.text.trim();
  }
  if (_condition != (_currentObject?['condizione'] ?? _condition)) item['condizione'] = _condition;
  if (_completeness != (_currentObject?['completezza'] ?? _completeness)) item['completezza'] = _completeness;
  if (_destination != (_currentObject?['destinazione'] ?? _destination)) item['destinazione'] = _destination;
  if (_destination == 'COLLEZIONE') {
    if (_selectedCollectionCategory == null || !_collectionCategories.any((e) => e['codice_categoria'] == _selectedCollectionCategory)) throw Exception('Seleziona una categoria COLLEZIONE valida.');
    item['categoria_collezione_selezionata'] = _selectedCollectionCategory;
  } else {
    item['categoria_collezione_selezionata'] = null;
  }
  if (_notes.text.trim() != (_currentObject?['note'] ?? '').toString()) item['note'] = _notes.text.trim().isEmpty ? null : _notes.text.trim();
  if (_quantity.text.trim() != (_currentObject?['quantita'] ?? '1').toString()) {
    final q = int.tryParse(_quantity.text.trim());
    if (q == null || q < 1) throw Exception('La quantità deve essere un intero maggiore di zero.');
    item['quantita'] = q;
  }
  if (_producer.text.trim() != (_currentObject?['produttore'] ?? '').toString()) item['produttore'] = _producer.text.trim().isEmpty ? null : _producer.text.trim();
  if (_line.text.trim() != (_currentObject?['anno_uscita'] ?? '').toString()) {
    final year = _line.text.trim().isEmpty ? null : int.tryParse(_line.text.trim());
    if (_line.text.trim().isNotEmpty && year == null) throw Exception('Anno di uscita non valido.');
    item['anno_uscita'] = year;
  }
  if (_family.text.trim() != (_currentObject?['codice_prodotto'] ?? '').toString()) item['codice_prodotto'] = _family.text.trim().isEmpty ? null : _family.text.trim();
  final currentSource = (_currentObject?['fonte_dati_prodotto'] ?? '').toString().trim();
  final proposedSource = (_metadataSourceUrl ?? '').trim();
  if (proposedSource.isNotEmpty && proposedSource != currentSource) {
    item['fonte_dati_prodotto'] = proposedSource;
    item['stato_verifica_dati'] = 'DA_VERIFICARE';
  }
  final currentValueRaw = _currentObject?['valore_oggetto'] ?? _currentObject?['valore'];
  final currentValueText = currentValueRaw == null ? '' : currentValueRaw.toString().trim();
  final proposedValueText = _value.text.trim().replaceAll(',', '.');
  if (proposedValueText != currentValueText.replaceAll(',', '.')) {
    if (proposedValueText.isEmpty) {
      item['valore_oggetto'] = null;
    } else {
      final n = double.tryParse(proposedValueText);
      if (n == null || n < 0) throw Exception('Valore oggetto non valido.');
      item['valore_oggetto'] = n;
    }
  }
  if (item.length == 1 && (_selectedImageBytes == null || _selectedImageName == null)) throw Exception('Nessuna modifica rilevata.');
  return {'oggetti': [item]};
  }
}
