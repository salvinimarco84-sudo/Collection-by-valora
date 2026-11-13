part of '../main.dart';

/// Presentazione della scheda, dei metadati e del confronto valori PR-02.
extension _Pr02ObjectPresentation on _ObjectRuntimePageState {
  Widget _pr02MetadataCard(Map<String, dynamic> object) {
    const imageKeys = [
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    ];
    String valueFor(List<String> keys) {
      for (final key in keys) {
        final value = object[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
      }
      return 'Non disponibile';
    }
    final imageUrl = valueFor(imageKeys);
    final hasImage = imageUrl != 'Non disponibile' &&
        (imageUrl.startsWith('https://') || imageUrl.startsWith('http://'));
    final producer = valueFor(['produttore']);
    final year = valueFor(['anno_uscita', 'data_uscita', 'data_di_uscita']);
    final productCode = valueFor(['codice_prodotto']);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('METADATI DEL PRODOTTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Image.network(_valoraImageProxyUrl(imageUrl), fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported_outlined, color: ValoraAppearance.instance.textFaint, size: 36))
                  : Icon(Icons.image_outlined, color: ValoraAppearance.instance.textFaint, size: 36),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _metadataValue('Produttore', producer),
              const SizedBox(height: 8),
              _metadataValue('Data di uscita', year),
              const SizedBox(height: 8),
              _metadataValue('Codice prodotto', productCode),
            ])),
          ]),
          const SizedBox(height: 8),
          Text('Metadati informativi, non modificabili da questa scheda.',
            style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _metadataValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: sectionColor, fontSize: 11, fontWeight: FontWeight.w600)),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(color: ValoraAppearance.instance.textPrimary, fontSize: 13)),
    ],
  );

  Widget _pr02TechnicalCard(Map<String, dynamic> object) {
    const operationalKeys = {
      'codice_oggetto', 'descrizione_oggetto', 'descrizione', 'produttore',
      'anno_uscita', 'data_uscita', 'data_di_uscita', 'codice_prodotto',
      'condizione', 'completezza', 'destinazione', 'quantita',
      'valore_oggetto', 'valore', 'note', 'stato',
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    };
    final technicalEntries = object.entries
        .where((entry) => !operationalKeys.contains(entry.key))
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DATI TECNICI · SOLA LETTURA',
            style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Divider(height: 24),
          if (technicalEntries.isEmpty)
            Text('Nessun altro dato tecnico presente nel record.',
              style: TextStyle(color: ValoraAppearance.instance.textMuted))
          else
            ...technicalEntries.map((entry) => _detailFieldCard(entry.key, entry.value)),
        ]),
      ),
    );
  }

  Widget _pr02Side({required bool oldValues}) {
    final object = _currentObject ?? <String, dynamic>{};
    final title = oldValues ? 'VECCHI VALORI · SOLA LETTURA' : 'NUOVI VALORI · MODIFICABILI';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (oldValues) ...[
            _detailFieldCard('codice_oggetto', object['codice_oggetto']),
            _detailFieldCard('descrizione_oggetto', object['descrizione_oggetto']),
            _detailFieldCard('produttore', object['produttore']),
            _detailFieldCard('anno_uscita', object['anno_uscita']),
            _detailFieldCard('codice_prodotto', object['codice_prodotto']),
            _detailFieldCard('fonte_dati_prodotto', object['fonte_dati_prodotto']),
            _detailFieldCard('condizione', object['condizione']),
            _detailFieldCard('completezza', object['completezza']),
            _detailFieldCard('destinazione', object['destinazione']),
            _detailFieldCard('quantita', object['quantita']),
            _detailFieldCard('valore_oggetto', object['valore_oggetto']),
            _detailFieldCard('note', object['note']),
            _detailFieldCard('stato', object['stato']),
          ] else ...[
            _field(_description, 'Descrizione oggetto', focusNode: _descriptionFocus),
            _field(_producer, 'Produttore'),
            _field(_line, 'Anno di uscita', type: TextInputType.number),
            _field(_family, 'Codice prodotto'),
            _detailFieldCard('fonte_dati_prodotto', _metadataSourceUrl ?? object['fonte_dati_prodotto']),
            _detailFieldCard('stato_verifica_dati', object['stato_verifica_dati'] ?? 'DA_VERIFICARE'),
            _dropdown('Condizione', _condition, const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'], (v) => setState(() => _condition = v!)),
            _dropdown('Completezza', _completeness, const ['SIGILLATO','COMPLETO','COMPLETO CON ISTRUZIONI','COMPLETO CON SCATOLA E ISTRUZIONI','INCOMPLETO'], (v) => setState(() => _completeness = v!)),
            _dropdown('Destinazione', _destination, const ['COLLEZIONE','RIVENDITA','ALTRO'], (v) => setState(() => _destination = v!)),
            _field(_quantity, 'Quantità', type: TextInputType.number),
            _field(_value, 'Prezzo unitario (€)', type: const TextInputType.numberWithOptions(decimal: true)),
            _field(_notes, 'Note', lines: 2),
            const SizedBox(height: 8),
            _imageField(),
          ],
        ]),
      ),
    );
  }
}
