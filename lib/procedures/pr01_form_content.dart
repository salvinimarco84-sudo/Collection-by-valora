import 'package:flutter/material.dart';
import '../themes/valora_theme.dart';

class Pr01FormContent extends StatelessWidget {
  const Pr01FormContent({
    super.key,
    required this.sectionColor,
    required this.descriptionField,
    required this.imageField,
    required this.producerField,
    required this.yearField,
    required this.productCodeField,
    required this.conditionField,
    required this.completenessField,
    required this.destinationField,
    required this.quantityField,
    required this.unitPriceField,
    required this.totalValueField,
    required this.notesField,
    required this.marketValueField,
    this.collectionCategoryField,
  });

  final Color sectionColor;
  final Widget descriptionField;
  final Widget imageField;
  final Widget producerField;
  final Widget yearField;
  final Widget productCodeField;
  final Widget conditionField;
  final Widget completenessField;
  final Widget destinationField;
  final Widget? collectionCategoryField;
  final Widget quantityField;
  final Widget unitPriceField;
  final Widget totalValueField;
  final Widget notesField;
  final Widget marketValueField;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('IDENTIFICAZIONE OGGETTO', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Codice oggetto: assegnato automaticamente dal database al salvataggio.', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
            const SizedBox(height: 8),
            descriptionField,
            const SizedBox(height: 10),
            imageField,
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DATI IDENTIFICATIVI · INSERIMENTO MANUALE', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            producerField,
            yearField,
            productCodeField,
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DATI INSERIBILI', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            conditionField,
            completenessField,
            destinationField,
            if (collectionCategoryField != null) collectionCategoryField!,
            quantityField,
            unitPriceField,
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: totalValueField,
            ),
            notesField,
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('VALORI DETERMINATI DA ALTRE PROCEDURE', style: TextStyle(color: sectionColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Valore di mercato attuale (€)', style: TextStyle(color: ValoraAppearance.instance.textSecondary)),
            const SizedBox(height: 4),
            marketValueField,
            const SizedBox(height: 8),
            Text('La stima verrà valorizzata dalla procedura di valutazione del mercato, non inserita manualmente.', style: TextStyle(color: ValoraAppearance.instance.textSubtle, fontSize: 11)),
          ]),
        ),
      ),
    ],
  );
}
