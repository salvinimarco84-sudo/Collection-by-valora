part of '../main.dart';

/// Ingresso controllato da candidato PR-12 a valutazione PR-18 e acquisto PR-04 VALORA.
/// Richiede candidato confermato, non scrive automaticamente e mantiene separati costo e valore.
extension _ValoraCatalogIntakeActions on _ValoraServicePageState {
    Future<void> _openUncataloguedCandidate(int index) async {
      if (index < 0 || index >= _photoSearchResults.length) return;
      final candidate = _confirmedPhotoCandidates[index];
      if (candidate == null) {
        setState(() => _error = 'Conferma prima il candidato PR-12. Nessun record verrà creato da un candidato non verificato.');
        return;
      }
      final result = _photoSearchResults[index];
      final clues = Map<String, dynamic>.from(result['identificazione'] as Map? ?? {});
      final title = (candidate['title'] ?? clues['descrizione_provvisoria'] ?? '').toString().trim();
      if (title.isEmpty) {
        setState(() => _error = 'Il candidato confermato non contiene una descrizione utilizzabile. Completa prima i metadati.');
        return;
      }
      final maker = (candidate['produttore'] ?? candidate['editore'] ?? clues['marchio'] ?? '').toString().trim();
      final code = (candidate['codice_prodotto'] ?? candidate['isbn'] ?? clues['codice_prodotto'] ?? '').toString().trim();
      final yearValue = candidate['anno_uscita'] ?? candidate['anno_pubblicazione'] ?? candidate['year'];
      final yearMatch = RegExp(r'(19\d{2}|20\d{2})').firstMatch(yearValue?.toString() ?? '');
      final sourceUrl = (candidate['url'] ?? '').toString().trim();
      final imageUrl = (candidate['image_url'] ?? candidate['immagine_url'] ?? candidate['url_immagine'] ?? '').toString().trim();
      final metadata = <String, dynamic>{
        'descrizione': title,
        if (maker.isNotEmpty) 'produttore': maker,
        if (code.isNotEmpty) 'codice_prodotto': code,
        if (yearMatch != null) 'anno_uscita': int.tryParse(yearMatch.group(1)!),
        if (sourceUrl.startsWith('https://') || sourceUrl.startsWith('http://')) 'fonte_dati_prodotto': sourceUrl,
        if (imageUrl.startsWith('https://') || imageUrl.startsWith('http://')) 'url_immagine_catalogo': imageUrl,
      };
      if (!mounted) return;
      setState(() { _error = null; _analyzingPhotos = true; });
      Map<String, dynamic>? valuation;
      try {
        final response = await Supabase.instance.client.functions.invoke(
          'pr-18-valuation-test',
          body: {
            'metadati': metadata,
            'mercato_riferimento': _market,
          },
        );
        final data = response.data;
        if (data is! Map || data['ok'] != true) {
          throw Exception(data is Map
              ? (data['error'] ?? 'PR18 non ha completato la valutazione').toString()
              : 'Risposta PR18 non valida.');
        }
        valuation = Map<String, dynamic>.from(data);
        final marketValue = valuation['valore_mercato'];
        final reliability = (valuation['affidabilita'] ?? 'NON DISPONIBILE').toString();
        if (mounted) {
          setState(() => _metadataValuationStatus[index] = marketValue is num
              ? 'PR18: € ${marketValue.toStringAsFixed(2)} · affidabilità $reliability'
              : 'PR18: nessun prezzo verificabile · affidabilità $reliability');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _metadataValuationStatus[index] = 'PR18_NON_COMPLETATA: $e');
        }
      } finally {
        if (mounted) setState(() => _analyzingPhotos = false);
      }
      if (!mounted) return;
      final valuationText = valuation == null
          ? 'PR18 non ha restituito una valutazione. Puoi comunque inserire l’oggetto, ma il valore di mercato resterà da determinare.'
          : (valuation['valore_mercato'] is num
              ? 'Valore indicativo: € ${(valuation['valore_mercato'] as num).toStringAsFixed(2)}\\n'
                  'Fascia: € ${valuation['fascia_minima'] ?? 'n.d.'} - € ${valuation['fascia_massima'] ?? 'n.d.'}\\n'
                  'Affidabilità: ${valuation['affidabilita'] ?? 'NON DISPONIBILE'}\\n'
                  'Comparabili con prezzo: ${valuation['numero_comparabili_con_prezzo_estratto'] ?? 0}. I prezzi estratti vanno verificati.'
              : 'PR18 ha completato la ricerca, ma non ha trovato prezzi verificabili. Non verrà inventato un valore.');
      final addObject = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Valutazione PR18'),
          content: Text('$valuationText\\n\\nVuoi procedere con PR-04 Nuovo Acquisto?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('ANNULLA')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('PROCEDI A PR-04')),
          ],
        ),
      );
      if (addObject != true || !mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => Pr04ValoraPurchasePage(
          initialMetadata: metadata,
          suggestedMarketValue: valuation?['valore_mercato'] is num
              ? (valuation!['valore_mercato'] as num).toDouble()
              : null,
        ),
      ));
      if (mounted) {
        setState(() {
          _descriptionQuery.text = title;
          _selectedId = null;
          _prepared = null;
        });
        await _loadObjects();
      }
    }
}
