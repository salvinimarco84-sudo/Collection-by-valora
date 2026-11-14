part of '../main.dart';

extension _ObjectSearchWorkflow on _ObjectRuntimePageState {
  Future<void> _searchPr02Objects() async {
    final query = _search.text.trim();
    if (query.isEmpty) throw Exception('Inserisci una parola, parte della descrizione o un codice.');
    final pr03SearchRequestId = widget.apiCode == 'PR-03' ? _pr03Controller.nextSearchRequestId() : null;

    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9àèéìòù]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    Future<List<Map<String, dynamic>>> searchPhrase(String phrase) async {
      final searchRpc = (widget.apiCode == 'OBJECT_MASTER' || widget.apiCode == 'EXPLORE_RECORDS')
          ? 'pr_21_ricerca_schede'
          : 'pr_02_ricerca_oggetti';
      final response = await Supabase.instance.client.schema('collection').rpc(
        searchRpc,
        params: {'p_cerca': phrase},
      );
      dynamic payload = response;
      if (payload is List && payload.length == 1 && payload.first is Map) {
        payload = payload.first;
      }
      if (payload is! Map) {
        throw Exception('Risposta PR-02 non valida per la ricerca: ' + phrase);
      }
      final raw = payload['oggetti'];
      final found = raw is List
          ? raw.whereType<Map>().map((entry) => Map<String, dynamic>.from(entry)).toList()
          : <Map<String, dynamic>>[];

      // Fallback diretto sul catalogo: le RPC testuali possono non trovare
      // codici prodotto presenti nella descrizione (es. "LEGO 4433").
      // La lettura è limitata alla tabella master e resta in sola lettura.
      try {
        final escapedPhrase = phrase.replaceAll('%', r'\%').replaceAll('_', r'\_').trim();
        if (escapedPhrase.isNotEmpty) {
          final direct = await Supabase.instance.client
              .schema('collection')
              .from('master_oggetti')
              .select()
              .ilike('descrizione_oggetto', '%$escapedPhrase%')
              .limit(100);
          if (direct is List) {
            for (final entry in direct.whereType<Map>()) {
              final item = Map<String, dynamic>.from(entry);
              final id = (item['codice_oggetto'] ?? '').toString().trim();
              if (!found.any((existing) =>
                  (existing['codice_oggetto'] ?? '').toString().trim() == id && id.isNotEmpty)) {
                found.add(item);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('VALORA: fallback ricerca diretta catalogo non disponibile: $e');
      }
      return found;
    }

    String descriptionOf(Map<String, dynamic> item) =>
        (item['descrizione_oggetto'] ?? item['descrizione'] ?? item['nome'] ?? '').toString();
    String codeOf(Map<String, dynamic> item) =>
        (item['codice_oggetto'] ?? '').toString().trim();

    // La RPC può restituire risultati troppo ampi (per esempio tutti gli
    // oggetti LEGO quando si cerca una descrizione precisa). Restringiamo
    // sempre i risultati alla frase richiesta prima di mostrarli.
    final normalizedQuery = normalize(query);
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
    List<Map<String, dynamic>> results = await searchPhrase(query);

    // Un codice numerico va cercato anche direttamente nella tabella master:
    // le RPC testuali possono non includere un record se non corrisponde alla
    // descrizione o se la loro selezione applica filtri di stato.
    final exactCode = int.tryParse(query);
    if (exactCode != null) {
      try {
        final direct = await Supabase.instance.client
            .schema('collection')
            .from('master_oggetti')
            .select()
            .eq('codice_oggetto', exactCode)
            .limit(1);
        if (direct is List) {
          for (final row in direct.whereType<Map>()) {
            final item = Map<String, dynamic>.from(row);
            if (!results.any((existing) => codeOf(existing) == codeOf(item))) {
              results.insert(0, item);
            }
          }
        }
      } catch (_) {
        // La ricerca RPC resta disponibile se la lettura diretta non è autorizzata.
      }
    }

    bool matchesPhrase(Map<String, dynamic> item, String phrase) {
      final q = normalize(phrase);
      if (q.isEmpty) return false;
      return normalize(descriptionOf(item)).contains(q) || codeOf(item) == phrase.trim();
    }

    results = results.where((item) => matchesPhrase(item, query)).toList();

    // Se il prefisso digitato non è presente nella descrizione archiviata,
    // prova le frasi complete più corte, mantenendo sempre il filtro stretto.
    if (results.isEmpty && tokens.length > 1) {
      for (var startAt = 1; startAt < tokens.length; startAt++) {
        final candidate = tokens.skip(startAt).join(' ').trim();
        if (candidate.isEmpty) continue;
        final candidateResults = await searchPhrase(candidate);
        final narrowed = candidateResults.where((item) => matchesPhrase(item, candidate)).toList();
        if (narrowed.isNotEmpty) {
          results = narrowed;
          break;        }
      }
    }

    // La ricerca per singola parola è consentita solo per una query di una
    // sola parola. Evita di unire risultati generici di ogni token, causa
    // frequente di elenchi enormi e irrilevanti.
    if (results.isEmpty && tokens.length == 1) {
      results = (await searchPhrase(tokens.first))
          .where((item) => matchesPhrase(item, tokens.first))
          .toList();
    }

    if (pr03SearchRequestId != null && !_pr03Controller.isCurrentSearchRequest(pr03SearchRequestId)) return;

    // Prima le descrizioni identiche, poi le corrispondenze parziali pertinenti.
    final exact = results.where((item) => normalize(descriptionOf(item)) == normalizedQuery).toList();
    if (exact.isNotEmpty) results = exact;

    results.sort((a, b) =>
      (int.tryParse(codeOf(a)) ?? 0).compareTo(int.tryParse(codeOf(b)) ?? 0));
    if (pr03SearchRequestId != null && !_pr03Controller.isCurrentSearchRequest(pr03SearchRequestId)) return;
    setState(() {
      _pr02SearchResults = results;
      _pr02SearchCompleted = true;
      _output = results.isEmpty
          ? 'Nessun oggetto corrispondente alla descrizione: ' + query
          : 'Trovati ' + results.length.toString() + ' risultati pertinenti. Seleziona il record.';
    });

    if (!mounted) return;
    if (widget.apiCode == 'PR-02') return;
    if (results.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: ValoraAppearance.instance.card,
          title: Text('NESSUN RISULTATO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
          content: Text('Non ho trovato oggetti per “' + query + '”. Prova con una parte più breve della descrizione o con il codice oggetto.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: ValoraAppearance.instance.card,
        title: Text('RISULTATI RICERCA (' + results.length.toString() + ')',
          style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 560,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: results.map((item) => Card(
                  child: ListTile(
                    title: Text(codeOf(item) + ' · ' + descriptionOf(item)),
                    subtitle: Text('Stato: ' + (item['stato'] ?? 'Non indicato').toString() +
                      ' · Quantità: ' + (item['quantita'] ?? 'Non indicata').toString() +
                      ' · Prezzo unitario: € ' + (item['valore_oggetto'] ?? 'Non indicato').toString()),
                    trailing: Icon(Icons.chevron_right, color: sectionColor),
                    onTap: () => Navigator.of(dialogContext).pop(item),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('ANNULLA')),
        ],
      ),
    );
    if (pr03SearchRequestId != null && !_pr03Controller.isCurrentSearchRequest(pr03SearchRequestId)) return;
    if (selected != null && mounted) {
      if (widget.apiCode == 'PR-03') {
        await _selectPr03Object(selected);
      } else if (widget.apiCode == 'OBJECT_MASTER') {
        await _selectPr11Object(selected);
      } else if (widget.apiCode == 'EXPLORE_RECORDS') {
        await _selectHistoryObject(selected);
      } else {
        await _selectPr02Object(selected);
      }
    }
  }
}
