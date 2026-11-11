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
      final metadata = _buildValoraCandidateMetadata(
        title: title,
        candidate: candidate,
        clues: clues,
      );
      if (!mounted) return;
      setState(() { _error = null; _analyzingPhotos = true; });
      Map<String, dynamic>? valuation;
      try {
        valuation = await _requestValoraCatalogIntakeValuation(metadata);

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
      final valuationText = _buildValoraCatalogIntakeValuationSummary(valuation);
      final addObject = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => _buildValoraCatalogIntakeReviewDialog(dialogContext, valuationText),
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
