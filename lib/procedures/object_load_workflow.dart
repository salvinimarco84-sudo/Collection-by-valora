part of '../main.dart';

/// Caricamento condiviso della scheda oggetto e dei metadati associati.
extension _ObjectLoadWorkflow on _ObjectRuntimePageState {
  Future<void> _loadObject({int? pr03SelectionRequestId}) async {
    final id = int.tryParse(_code.text.trim());
    if (id == null || id <= 0) throw Exception('Inserisci un codice oggetto valido.');
    final response = await _ValoraRuntimeApi.call('consultation', {
      'session_id': _sessionId,
      'consultation_code': 'OBJECT_MASTER',
      'arguments': {'codice_oggetto': id},
    });
    final outer = response['result'];
    dynamic data = outer is Map ? outer['risultato'] : null;
    if (data is List) {
      if (data.isEmpty) throw Exception('Nessuna scheda trovata per il codice $id.');
      data = data.first;
    }
    if (data is! Map) throw Exception('Scheda non disponibile per il codice $id.');
    final m = Map<String, dynamic>.from(data);

    // Il prezzo pagato appartiene alla riga di dettaglio dell'acquisto,
    // non al valore di mercato dell'oggetto. Recuperarlo separatamente
    // e usarlo solo per la presentazione della scheda.
    try {
      final purchase = await Supabase.instance.client
          .schema('collection')
          .from('acquisti_oggetti')
          .select('codice_acquisto, valore_acquisto_oggetto, valuta')
          .eq('codice_oggetto', id)
          .order('codice_acquisto', ascending: false)
          .limit(1)
          .maybeSingle();
      if (purchase != null && purchase['valore_acquisto_oggetto'] != null) {
        m['prezzo_acquisto'] = purchase['valore_acquisto_oggetto'];
        m['valuta_acquisto'] = purchase['valuta'] ?? 'EUR';
        m['codice_acquisto'] = purchase['codice_acquisto'];
      }
    } catch (error) {
      debugPrint('VALORA: prezzo di acquisto non disponibile per $id: $error');
    }

    // Carica anche i metadati di catalogo e i campi specifici della categoria.
    // Le letture sono in sola lettura e non modificano i record.
    List<Map<String, dynamic>> categoryDefinitions = [];
    Map<String, dynamic> categoryValues = {};
    // La categoria è già disponibile nel record di catalogo master_metadati.
    // Usarla come fallback evita che un errore nella lettura dei valori specifici
    // nasconda anche le definizioni dei campi della categoria.
    String? categoryCode = m['codice_categoria']?.toString();
    // Fonte autorevole per categoria e URL immagine: record catalogo master_metadati.
    // La scheda oggetto può non includere questi campi nella risposta OBJECT_MASTER.
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Sessione non valida per i metadati.');
      final response = await Supabase.instance.client.functions.invoke(
        'collection-object-images-test',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {'action': 'metadata', 'codice_oggetto': id},
      );
      if (response.status < 200 || response.status >= 300 || response.data is! Map) {
        throw Exception('Endpoint metadati HTTP ${response.status}');
      }
      final payload = Map<String, dynamic>.from(response.data as Map);
      final catalog = payload['metadata'];
      if (catalog is Map) {
        final row = Map<String, dynamic>.from(catalog);
        categoryCode = row['codice_categoria']?.toString() ?? categoryCode;
        for (final entry in row.entries) {
          if (entry.value != null && entry.value.toString().trim().isNotEmpty) categoryValues[entry.key] = entry.value;
        }
      }
      final specific = payload['specific'];
      if (specific is Map) {
        final row = Map<String, dynamic>.from(specific);
        categoryCode = row['codice_categoria']?.toString() ?? categoryCode;
        final rawValues = row['valori'];
        if (rawValues is Map) categoryValues.addAll(Map<String, dynamic>.from(rawValues));
      }
      if (payload['fields'] is List) {
        categoryDefinitions = List<Map<String, dynamic>>.from((payload['fields'] as List).whereType<Map>().map((row) => Map<String, dynamic>.from(row)));
      }
    } catch (error) {
      debugPrint('VALORA: endpoint metadati non disponibile per $id: $error');
    }

    // Fallback di presentazione: le definizioni a database possono essere
    // incomplete rispetto ai metadati già salvati da PR-12. Non nascondere
    // campi LEGO disponibili solo perché il registro della categoria è parziale.
    if (categoryCode == 'CAT-001' ||
        (m['produttore']?.toString().toUpperCase() == 'LEGO') ||
        (categoryValues['produttore']?.toString().toUpperCase() == 'LEGO')) {
      const legoFields = <String, String>{
        'tema': 'Tema LEGO',
        'sezione': 'Sezione LEGO',
        'sottotema': 'Sottotema LEGO',
        'numero_pezzi': 'Numero di pezzi del set',
        'numero_minifigure': 'Numero di minifigure',
        'dettagli_pezzi': 'Dettaglio pezzi',
        'contenuto_confezione': 'Contenuto della confezione',
        'caratteristiche_tecniche': 'Caratteristiche tecniche',
        'identificativi_aggiuntivi': 'Identificativi aggiuntivi',
        'modalita_alternative': 'Modalità alternative',
        'prezzo_lancio': 'Prezzo di lancio',
        'valuta_prezzo_lancio': 'Valuta prezzo di lancio',
        'mercato_riferimento_uscita': 'Mercato di riferimento',
        'stato_verifica': 'Stato verifica metadati',
      };
      final existing = categoryDefinitions
          .map((d) => d['nome_campo']?.toString())
          .whereType<String>().toSet();
      var order = categoryDefinitions.length * 10 + 10;
      for (final entry in legoFields.entries) {
        if (existing.add(entry.key)) {
          categoryDefinitions.add({
            'codice_campo': 'LEGO-FALLBACK-${entry.key}',
            'nome_campo': entry.key,
            'tipo_dato': 'text',
            'obbligatorio': false,
            'applicabilita': 'metadato disponibile',
            'ordine_visualizzazione': order,
            'descrizione': entry.value,
          });
          order += 10;
        }
      }
      categoryDefinitions.sort((a, b) =>
          ((a['ordine_visualizzazione'] as num?)?.toInt() ?? 9999)
              .compareTo(((b['ordine_visualizzazione'] as num?)?.toInt() ?? 9999)));
    }

    String txt(List<String> keys, [String fallback = '']) {
      for (final k in keys) { if (m[k] != null) return m[k].toString(); }
      return fallback;
    }
    String? assignedCollectionCategory;
    try {
      final assignment = await Supabase.instance.client.schema('collection')
          .from('oggetto_collezione_categoria').select('codice_categoria')
          .eq('codice_oggetto', id).maybeSingle();
      assignedCollectionCategory = assignment?['codice_categoria']?.toString();
    } catch (error) { debugPrint('VALORA: categoria COLLEZIONE non letta per $id: $error'); }
    if (pr03SelectionRequestId != null &&
        !_pr03Controller.isCurrentSelectionRequest(pr03SelectionRequestId)) return;
    setState(() {
      _pr11CategoryFieldDefinitions = categoryDefinitions;
      _pr11CategoryValues = categoryValues;
      _pr11CategoryCode = categoryCode;
      _selectedCollectionCategory = assignedCollectionCategory;
      _currentObject = m;
      _loadedObjectId = id;
      _description.text = txt(['descrizione_oggetto', 'descrizione']);
      _notes.text = txt(['note']);
      _quantity.text = txt(['quantita'], '1');
      _value.text = txt(['valore_oggetto', 'valore']);
      _producer.text = txt(['produttore']);
      _line.text = txt(['anno_uscita']);
      _family.text = txt(['codice_prodotto']);
      final c = txt(['condizione'], _condition);
      if (const ['NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO'].contains(c)) _condition = c;
      final cp = txt(['completezza'], _completeness);
      if (const ['SIGILLATO','COMPLETO','COMPLETO CON ISTRUZIONI','COMPLETO CON SCATOLA E ISTRUZIONI','INCOMPLETO'].contains(cp)) _completeness = cp;
      final d = txt(['destinazione'], _destination);
      if (const ['COLLEZIONE','RIVENDITA','ALTRO'].contains(d)) _destination = d;
      _output = 'Scheda corrente caricata dal database. I campi sono in sola lettura fino alla conferma della procedura.';
      _existingImageUrl = null; _selectedImageBytes = null; _selectedImageName = null;
      _imageStatus = 'Verifica immagine associata…';
    });
    // La scheda di consultazione deve caricare l'immagine indipendentemente
    // dal codice procedura che l'ha aperta (PR-11, PR-02 o accesso diretto).
    await _loadExistingImage(id);
    if (mounted && _loadedObjectId == id && _existingImageUrl == null) {
      final catalogImage = (_pr11CategoryValues['url_immagine'] ??
          _pr11CategoryValues['image_url'] ??
          _currentObject?['url_immagine'] ??
          _currentObject?['image_url'] ??
          '').toString().trim();
      if (catalogImage.startsWith('https://') || catalogImage.startsWith('http://')) {
        setState(() {
          _existingImageUrl = catalogImage;
          _imageStatus = 'Immagine caricata dal catalogo metadati.';
        });
      }
    }
  }
}
