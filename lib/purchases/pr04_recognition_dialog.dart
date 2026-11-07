part of '../main.dart';

class Pr04RecognitionDialog extends StatefulWidget {
  const Pr04RecognitionDialog({
    super.key,
    required this.photoBytes,
    required this.clues,
    required this.results,
    required this.imageCandidates,
  });

  final Uint8List photoBytes;
  final Map<String, dynamic> clues;
  final List<Map<String, dynamic>> results;
  final List<Map<String, dynamic>> imageCandidates;

  @override
  State<Pr04RecognitionDialog> createState() => _Pr04RecognitionDialogState();
}

class _Pr04RecognitionDialogState extends State<Pr04RecognitionDialog> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('PR-12 · Verifica oggetto e immagine'),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Descrizione proposta: ' + (widget.clues['descrizione_provvisoria'] ?? 'Non rilevata').toString()),
            Text('Marchio: ' + (widget.clues['marchio'] ?? 'Non rilevato').toString()),
            Text('Codice prodotto: ' + (widget.clues['codice_prodotto'] ?? 'Non rilevato').toString()),
            if ((widget.clues['categoria'] ?? '').toString().trim().isNotEmpty)
              Text('Categoria: ' + widget.clues['categoria'].toString()),
            if (widget.clues['incertezze'] is List && (widget.clues['incertezze'] as List).isNotEmpty)
              Text('Da verificare: ' + (widget.clues['incertezze'] as List).join(' · ')),
            const Divider(),
            const Text('Scegli l’immagine da associare all’oggetto',
              style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<int>(
              value: -1,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v ?? -1),
              title: const Text('Mantieni la foto scattata'),
              subtitle: const Text('La foto del tuo esemplare'),
              secondary: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(widget.photoBytes, width: 58, height: 58, fit: BoxFit.cover),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            if (widget.imageCandidates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Nessuna immagine online utilizzabile. Puoi mantenere la foto originale.'),
              ),
            for (var i = 0; i < widget.imageCandidates.length; i++)
              RadioListTile<int>(
                value: i,
                groupValue: _selected,
                onChanged: (v) => setState(() => _selected = v ?? -1),
                contentPadding: EdgeInsets.zero,
                title: Text((widget.imageCandidates[i]['title'] ?? 'Immagine trovata online').toString()),
                subtitle: Text(
                  (widget.imageCandidates[i]['motore'] ?? widget.imageCandidates[i]['url'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    (widget.imageCandidates[i]['image_url'] ??
                      widget.imageCandidates[i]['immagine_url'] ??
                      widget.imageCandidates[i]['url_immagine']).toString(),
                    width: 58,
                    height: 58,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 36),
                  ),
                ),
              ),
            const Divider(),
            Text('Risultati catalografici PR-12: ${widget.results.length}. I metadati proposti restano da verificare.'),
            const Text('La ricerca non salva dati nel database.'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, <String, dynamic>{'annulla': true}),
        child: const Text('ANNULLA'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, <String, dynamic>{
          'use_original': _selected < 0,
          if (_selected >= 0) 'candidate': widget.imageCandidates[_selected],
        }),
        child: const Text('USA SELEZIONE'),
      ),
    ],
  );
}
