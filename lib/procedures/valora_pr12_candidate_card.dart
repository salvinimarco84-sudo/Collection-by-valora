part of '../main.dart';

/// Presenta un singolo candidato PR-12 senza gestire lo stato della coda.
class Pr12CandidateCard extends StatelessWidget {
  const Pr12CandidateCard({
    super.key,
    required this.result,
    required this.item,
    required this.index,
    required this.selected,
    required this.accentColor,
    required this.onSelect,
    required this.onApply,
  });

  final Map<String, dynamic> result;
  final Map<String, dynamic> item;
  final int index;
  final bool selected;
  final Color accentColor;
  final VoidCallback onSelect;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item['image_url'] ?? item['immagine'] ?? '').toString().trim();
    final title = (item['title'] ?? 'Titolo non disponibile').toString().trim();
    final snippet = (item['snippet'] ?? '').toString().trim();
    final url = (item['url'] ?? '').toString().trim();
    final maker = (item['produttore'] ?? item['editore'] ?? '').toString().trim();
    final year = (item['anno_uscita'] ?? item['anno'] ?? '').toString().trim();
    final productCode = (item['codice_prodotto'] ?? item['codice'] ?? item['isbn'] ?? '').toString().trim();
    final source = Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '');

    return InkWell(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? accentColor : ValoraAppearance.instance.neutralOverlayStrong,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected ? ValoraAppearance.instance.neutralOverlay : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _valoraImageProxyUrl(imageUrl),
                        width: 92,
                        height: 112,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Container(
                          width: 92,
                          height: 112,
                          alignment: Alignment.center,
                          color: ValoraAppearance.instance.neutralOverlay,
                          child: const Icon(Icons.image_not_supported_outlined, size: 28),
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 92,
                      height: 112,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ValoraAppearance.instance.neutralOverlay,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_search_outlined, size: 30),
                          SizedBox(height: 5),
                          Text('Nessuna immagine', textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: selected ? accentColor : null,
                          ),
                          const SizedBox(width: 5),
                          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        ],
                      ),
                      if (maker.isNotEmpty) Text('Produttore / editore: $maker'),
                      if (year.isNotEmpty) Text('Anno: $year'),
                      if (productCode.isNotEmpty) Text('Codice / ISBN: $productCode'),
                      Text(
                        'Fonte: ' + (source.isEmpty ? 'sito non identificato' : source),
                        style: TextStyle(color: accentColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (snippet.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(snippet, maxLines: 5, overflow: TextOverflow.ellipsis),
              ),
            if (url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SelectableText(url, style: TextStyle(color: accentColor, fontSize: 12)),
              ),
            if (selected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('APPLICA METADATI SE DISPONIBILI'),
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Candidato da verificare: selezionalo per applicare eventuali metadati strutturati.',
              style: TextStyle(color: ValoraAppearance.instance.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
