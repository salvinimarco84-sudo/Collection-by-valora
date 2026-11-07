part of '../main.dart';

extension _ObjectCardsPresentation on _ObjectRuntimePageState {
  Widget _objectCard(
    Map<String, dynamic> item, {
    VoidCallback? onTap, bool availableStyle = false, bool showImagePlaceholder = true,
    bool activeListing = false,
  }) {
    final code = _valueFor(item, ['codice_oggetto', 'id'], 'Codice n/d');
    final desc = _valueFor(item, ['descrizione_oggetto', 'descrizione', 'nome'], 'Oggetto senza descrizione');
    String firstImage(dynamic value, {bool allowDirectUrl = false}) {
      const imageKeys = <String>[
        'url_immagine_catalogo', 'url_immagine', 'immagine_url', 'foto_url',
        'image_url', 'immagine_principale', 'url_foto', 'foto', 'immagine',
        'image', 'imageUrl', 'photo_url', 'main_image_url', 'image_uri',
        'photo_uri', 'url_foto_principale', 'percorso_immagine',
        'immagini', 'images', 'gallery', 'galleria_foto',
      ];
      bool isHttpUrl(dynamic candidate) => candidate is String &&
          (candidate.trim().startsWith('https://') || candidate.trim().startsWith('http://'));
      if (value is Map) {
        for (final key in imageKeys) {
          final candidate = value[key];
          final found = firstImage(candidate, allowDirectUrl: true);
          if (found.isNotEmpty) return found;
        }
        // Esplora i metadati annidati, ma non interpreta URL generici come immagini:
        // potrebbero essere link alle fonti o alle pagine prodotto.
        for (final nested in value.values) {
          final found = firstImage(nested);
          if (found.isNotEmpty) return found;
        }
      } else if (value is Iterable) {
        for (final nested in value) {
          final found = firstImage(nested, allowDirectUrl: allowDirectUrl);
          if (found.isNotEmpty) return found;
        }
      } else if (allowDirectUrl && isHttpUrl(value)) {
        return (value as String).trim();
      }
      return '';
    }
    final imageUrl = firstImage(item);
    final destination = _valueFor(item, ['destinazione'], 'Non indicata');
    final condition = _valueFor(item, ['condizione'], 'Non indicata');
    final state = _valueFor(item, ['stato', 'stato_oggetto'], 'Non indicato');
    final value = _valueFor(item, ['valore_oggetto', 'valore', 'valore_stimato'], 'Non indicato');
    final saleCode = _valueFor(item, ['codice_vendita_aperta'], 'N/D');
    final salePrice = _valueFor(item, ['prezzo_di_vendita'], 'Non indicato');
    final currency = _valueFor(item, ['valuta'], 'EUR');
    final platforms = _valueFor(item, ['piattaforme_report', 'piattaforme'], 'Non indicata');
    final completeness = _valueFor(item, ['completezza'], 'Non indicata');
    final objectValue = _valueFor(item, ['valore_oggetto'], 'Non indicato');
    final objectValueCurrency = _valueFor(item, ['valuta_valore'], 'EUR');
    String formatMoney(String amount, String currencyCode) {
      if (amount == 'Non indicato') return amount;
      final normalized = amount.replaceAll('.', ',');
      return '${normalized} ${currencyCode == 'EUR' ? '€' : currencyCode}';
    }
    final formattedSalePrice = formatMoney(salePrice, currency);
    final formattedObjectValue = formatMoney(objectValue, objectValueCurrency);
    final imageSize = availableStyle ? 104.0 : 88.0;
    Widget infoChip(IconData icon, String label) => ObjectInfoChip(
      icon: icon,
      label: label,
      color: sectionColor,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: availableStyle ? sectionColor.withValues(alpha: 0.35) : ValoraAppearance.instance.neutralOverlay,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(availableStyle ? 14 : 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (showImagePlaceholder) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: imageUrl.startsWith('http')
                  ? Image.network(_valoraImageProxyUrl(imageUrl), width: imageSize, height: imageSize, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(size: imageSize))
                  : _imagePlaceholder(size: imageSize),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(
                  'CODICE $code',
                  style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold, fontSize: 12),
                )),
                if (onTap != null) Icon(Icons.chevron_right, color: sectionColor, size: 20),
              ]),
              if (activeListing) ...[
                const SizedBox(height: 2),
                Text('VENDITA N. $saleCode', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 5),
              Text(desc, style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: availableStyle ? 16 : 16,
              )),
              const SizedBox(height: 9),
              if (activeListing) ...[
                Text('PREZZO DI VENDITA: $formattedSalePrice',
                  style: TextStyle(color: sectionColor, fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 7),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  infoChip(Icons.storefront_outlined, platforms),
                  if (destination != 'Non indicata') infoChip(Icons.inventory_2_outlined, destination),
                  if (condition != 'Non indicata') infoChip(Icons.verified_outlined, condition),
                  if (completeness != 'Non indicata') infoChip(Icons.checklist_outlined, completeness),
                ]),
                const SizedBox(height: 7),
                Row(children: [
                  Icon(Icons.circle, size: 8, color: sectionColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Stato oggetto: $state',
                    style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12))),
                ]),
                const SizedBox(height: 5),
                Text('Valore oggetto: $formattedObjectValue',
                  style: TextStyle(color: sectionColor, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 5),
                Text('Data inizio vendita: ${_valueFor(item, ['data_inizio_vendita'], 'Non indicata')}',
                  style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12)),
              ] else if (availableStyle) ...[
                if (destination != 'Non indicata' || condition != 'Non indicata')
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    if (destination != 'Non indicata')
                      infoChip(Icons.inventory_2_outlined, destination),
                    if (condition != 'Non indicata')
                      infoChip(Icons.verified_outlined, condition),
                  ]),
                if (destination != 'Non indicata' || condition != 'Non indicata')
                  const SizedBox(height: 7),
                Row(children: [
                  Icon(Icons.circle, size: 8, color: sectionColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Stato: $state', style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12))),
                ]),
                const SizedBox(height: 5),
                Text(
                  'Valore: $value',
                  style: TextStyle(color: sectionColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ] else ...[
                Text('Destinazione: $destination'),
                Text('Condizione: $condition'),
                Text('Stato: $state'),
                Text('Valore: $value'),
              ],
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _imagePlaceholder({double size = 88}) => ObjectImagePlaceholder(
    size: size,
    backgroundColor: ValoraAppearance.instance.neutralOverlay,
    iconColor: ValoraAppearance.instance.textFaint,
  );

  Widget _historyCard(Map<String, dynamic> event) {
    final date = _valueFor(event, ['data_evento', 'data', 'created_at'], 'Data non indicata');
    final rawType = _valueFor(event, ['tipo_evento', 'tipo', 'azione'], 'Evento');
    final field = (event['campo_modificato'] ?? '').toString().trim();
    final previous = (event['valore_precedente'] ?? '').toString().trim();
    final next = (event['valore_nuovo'] ?? '').toString().trim();
    final reason = (event['motivo'] ?? event['motivazione'] ?? '').toString().trim();
    final note = (event['note'] ?? event['descrizione'] ?? event['dettaglio'] ?? '').toString().trim();
    final isPr03Closure = rawType == 'CAMBIO_STATO' &&
        (reason == 'DISTRUTTO' || reason == 'SMARRITO' || reason == 'DATO VIA' ||
         next == 'DISTRUTTO' || next == 'PERSO' || next == 'USCITO');
    final type = isPr03Closure ? 'CHIUSURA OGGETTO · PR-03' : rawType;
    String fieldLabel(String value) {
      const labels = <String, String>{
        'quantita': 'Quantità',
        'valore_oggetto': 'Valore oggetto',
        'stato': 'Stato',
        'descrizione_oggetto': 'Descrizione',
        'condizione': 'Condizione',
        'completezza': 'Completezza',
        'destinazione': 'Destinazione',
      };
      return labels[value] ?? (value.isEmpty ? 'Campo modificato' : value.replaceAll('_', ' '));
    }
    final isStateChange = field == 'stato' || isPr03Closure;
    final details = <Widget>[];
    if (field.isNotEmpty && !isStateChange) {
      details.add(_historyDetailRow('Campo', fieldLabel(field)));
    }
    if (previous.isNotEmpty || next.isNotEmpty) {
      if (isStateChange) {
        details.add(_historyDetailRow('Stato precedente', previous.isEmpty ? 'Non indicato' : previous));
        details.add(_historyDetailRow('Stato finale', next.isEmpty ? 'Non indicato' : next));
      } else if (previous.isNotEmpty && next.isNotEmpty) {
        details.add(_historyDetailRow('Valore precedente', previous));
        details.add(_historyDetailRow('Valore nuovo', next));
      } else {
        details.add(_historyDetailRow('Valore registrato', next.isEmpty ? previous : next));
      }
    }
    if (reason.isNotEmpty) details.add(_historyDetailRow('Motivo', reason));
    if (note.isNotEmpty) details.add(_historyDetailRow('Note', note));
    if (details.isEmpty) {
      details.add(Text('Nessun dettaglio registrato', style: TextStyle(color: ValoraAppearance.instance.textSecondary)));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(isPr03Closure ? Icons.logout : Icons.history, color: sectionColor),
              const SizedBox(width: 10),
              Expanded(child: Text(type, style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Text(date, style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: item,
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyDetailRow(String label, String value) => ObjectHistoryDetailRow(
    label: label,
    value: value,
    labelColor: ValoraAppearance.instance.textMuted,
  );

}
