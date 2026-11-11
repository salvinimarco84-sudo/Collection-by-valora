part of '../main.dart';

/// Sezione mercato di riferimento, preparazione PR-18 e riepilogo del risultato.
extension _ValoraMarketValuationPresentation on _ValoraServicePageState {
  Widget buildMarketValuationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                  _buildValoraMarketValuationControls(this),
                  _buildValoraMarketValuationResult(this),
      ],
    );
  }
}
