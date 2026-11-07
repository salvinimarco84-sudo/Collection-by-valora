part of '../main.dart';

extension _ObjectMasterPresentation on _ObjectRuntimePageState {
  String _italianFieldLabel(String key) {
    const labels = <String, String>{
      'id': 'ID record',
      'codice_oggetto': 'Codice oggetto',
      'descrizione_oggetto': 'Descrizione oggetto',
      'descrizione': 'Descrizione',
      'nome': 'Nome',
      'produttore': 'Produttore',
      'linea': 'Linea',
      'famiglia': 'Famiglia / categoria',
      'categoria': 'Categoria',
      'condizione': 'Condizione',
      'completezza': 'Completezza',
      'destinazione': 'Destinazione',
      'quantita': 'Quantità',
      'note': 'Note',
      'valore_oggetto': 'Valore oggetto (€)',
      'valore': 'Valore (€)',
      'valore_stimato': 'Valore stimato (€)',
      'stato': 'Stato',
      'stato_oggetto': 'Stato oggetto',
      'url_immagine': 'Immagine',
      'immagine_url': 'Immagine',
      'foto_url': 'Immagine',
      'image_url': 'Immagine',
      'data_inserimento': 'Data inserimento',
      'data_creazione': 'Data creazione',
      'data_modifica': 'Data ultima modifica',
      'created_at': 'Data creazione',
      'updated_at': 'Data ultima modifica',
      'data_evento': 'Data evento',
      'tipo_evento': 'Tipo evento',
      'motivo_chiusura': 'Motivo chiusura',
      'prezzo_acquisto': 'Prezzo di acquisto (€)',
      'prezzo_vendita': 'Prezzo di vendita (€)',
      'piattaforma': 'Piattaforma',
      'fonte': 'Fonte',
    };
    if (labels.containsKey(key)) return labels[key]!;
    final normalized = key
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return 'Campo';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _displayFieldValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return 'Non indicato';
    if (value is bool) return value ? 'Sì' : 'No';
    final text = value.toString().trim();
    if (text.toLowerCase() == 'true') return 'Sì';
    if (text.toLowerCase() == 'false') return 'No';
    return text;
  }

  Widget _detailFieldCard(String key, dynamic value) {
    final label = _italianFieldLabel(key);
    final text = _displayFieldValue(value);
    final isUrl = text.startsWith('https://') || text.startsWith('http://');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(
              color: sectionColor, fontSize: 13, fontWeight: FontWeight.w600,
            )),
            const SizedBox(height: 5),
            SelectableText(text, style: TextStyle(fontSize: 15)),
            if (isUrl) ...[
              const SizedBox(height: 4),
              Text('Fonte esterna', style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _masterDetails(Map<String, dynamic> object) {
    const sourceKeys = {
      'fonte', 'fonte_dati_prodotto', 'url_fonte', 'fonte_dati',
      'fonte_dati_catalogo', 'fonte_dati_oggetto', 'fonte_catalogo',
      'fonte_oggetto', 'url_fonte_oggetto', 'url_fonte_catalogo',
      'url_fonte_prodotto', 'fonte_metadati', 'fonte_immagine', 'url_fonte_immagine',
    };
    const imageKeys = {
      'url_immagine', 'immagine_url', 'foto_url', 'image_url',
      'immagine_principale', 'url_foto', 'foto', 'immagine',
      'image', 'imageUrl', 'photo_url', 'main_image_url',
    };
    const summaryKeys = {
      'id', 'codice_oggetto', 'descrizione_oggetto', 'descrizione', 'nome',
      'destinazione', 'condizione', 'stato', 'stato_oggetto',
      'valore_oggetto', 'valore', 'valore_stimato',
    };
    const identityKeys = {
      'produttore', 'linea', 'famiglia', 'categoria', 'anno_uscita',
      'codice_prodotto', 'codice', 'serie', 'licenza', 'franchise',
    };
    const conditionKeys = {
      'completezza', 'quantita', 'note', 'data_inserimento',
      'data_creazione', 'data_modifica', 'created_at', 'updated_at',
      'fonte', 'fonte_dati_prodotto', 'url_fonte', 'fonte_dati',
    };
    const valueKeys = {
      'valore_mercato', 'valore_mercato_eur', 'valore_stimato',
      'valuta_valore', 'valuta', 'prezzo_acquisto', 'prezzo_vendita',
      'valore_oggetto', 'valore',
    };
    const technicalKeys = {
      'collegato_vendita', 'modificabile_pr02', 'motivo_esclusione',
      'collegato_acquisto', 'collegato_inserzione', 'collegato_piattaforma',
      'stato_verifica_dati', 'id', 'created_at', 'updated_at',
      'record_id', 'deleted_at', 'versione_record',
    };

    final entries = object.entries.where((e) =>
      !imageKeys.contains(e.key) && !summaryKeys.contains(e.key) && !sourceKeys.contains(e.key)
    ).toList();
    List<MapEntry<String, dynamic>> group(Set<String> keys) =>
      entries.where((e) => keys.contains(e.key)).toList();
    final identity = group(identityKeys);
    final condition = group(conditionKeys).where((e) => !technicalKeys.contains(e.key)).toList();
    final values = group(valueKeys);
    final technical = entries.where((e) => technicalKeys.contains(e.key)).toList();
    final assigned = <String>{
      ...identity.map((e) => e.key),
      ...condition.map((e) => e.key),
      ...values.map((e) => e.key),
      ...technical.map((e) => e.key),
    };
    final other = entries.where((e) => !assigned.contains(e.key)).toList();

    Widget section(String title, IconData icon, List<MapEntry<String, dynamic>> fields) {
      if (fields.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: sectionColor, size: 19),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(
                color: sectionColor, fontSize: 16, fontWeight: FontWeight.bold,
              ))),
            ]),
            const SizedBox(height: 8),
            ...fields.map((e) => _detailFieldCard(e.key, e.value)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('IDENTIFICAZIONE', Icons.qr_code_2, identity),
        section('GESTIONE OGGETTO', Icons.inventory_2_outlined, condition),
        section('VALORI E VALUTAZIONE', Icons.euro_outlined, values),
        section('ALTRI DETTAGLI', Icons.info_outline, other),
      ],
    );
  }

}
