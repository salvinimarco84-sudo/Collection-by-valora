part of '../main.dart';

/// Compone il riepilogo leggibile della valutazione PR-18 prima della conferma PR-04.
String _buildValoraCatalogIntakeValuationSummary(
  Map<String, dynamic>? valuation,
) {
  if (valuation == null) {
    return 'PR18 non ha restituito una valutazione. Puoi comunque inserire l’oggetto, ma il valore di mercato resterà da determinare.';
  }
  final marketValue = valuation['valore_mercato'];
  if (marketValue is! num) {
    return 'PR18 ha completato la ricerca, ma non ha trovato prezzi verificabili. Non verrà inventato un valore.';
  }
  return 'Valore indicativo: € ${marketValue.toStringAsFixed(2)}\\n'
      'Fascia: € ${valuation['fascia_minima'] ?? 'n.d.'} - € ${valuation['fascia_massima'] ?? 'n.d.'}\\n'
      'Affidabilità: ${valuation['affidabilita'] ?? 'NON DISPONIBILE'}\\n'
      'Comparabili con prezzo: ${valuation['numero_comparabili_con_prezzo_estratto'] ?? 0}. I prezzi estratti vanno verificati.';
}
