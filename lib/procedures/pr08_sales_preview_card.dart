part of '../main.dart';

class Pr08CloseSalesPreviewCard extends StatelessWidget {
  final List<String> lines;
  final Color secondaryTextColor;
  final VoidCallback? onConfirm;

  const Pr08CloseSalesPreviewCard({
    super.key,
    required this.lines,
    required this.secondaryTextColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RIEPILOGO DELLE CHIUSURE', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${lines.length} vendite selezionate. Controlla esito, importo e piattaforma prima di proseguire.',
              style: TextStyle(color: secondaryTextColor)),
            const SizedBox(height: 8),
            ...lines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line),
            )),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: onConfirm,
              child: const Text('CONFERMO I DATI'),
            ),
          ],
        ),
      ),
    );
  }
}
