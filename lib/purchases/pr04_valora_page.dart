part of '../main.dart';

/// PR-04 VALORA: percorso singolo semplificato che riusa il runtime PR-04 originale.
class Pr04ValoraPage extends StatelessWidget {
  const Pr04ValoraPage({
    super.key,
    required this.initialMetadata,
    this.suggestedMarketValue,
  });

  final Map<String, dynamic> initialMetadata;
  final double? suggestedMarketValue;

  @override
  Widget build(BuildContext context) => NewPurchasePage(
    valoraMode: true,
    initialMetadata: initialMetadata,
    suggestedMarketValue: suggestedMarketValue,
  );
}
