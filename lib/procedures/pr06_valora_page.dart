part of '../main.dart';

/// PR-06 VALORA è un ingresso guidato alla PR-06 standard.
/// Riutilizza gli stessi campi, validazioni, anteprima, blocco e salvataggio:
/// cambia soltanto la precompilazione e nasconde la selezione dell'oggetto.
class Pr06ValoraPage extends StatelessWidget {
  const Pr06ValoraPage({
    super.key,
    required this.initialObjectCode,
    this.marketValue,
  });

  final int initialObjectCode;
  final double? marketValue;

  @override
  Widget build(BuildContext context) => NewSalePage(
    initialObjectCode: initialObjectCode,
    initialSalePrice: marketValue,
    valoraMode: true,
  );
}
