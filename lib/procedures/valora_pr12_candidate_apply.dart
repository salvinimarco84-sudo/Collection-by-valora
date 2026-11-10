part of '../main.dart';

extension _ObjectRuntimePagePr12CandidateApply on _ObjectRuntimePageState {
    Future<void> _pr12ApplySelectedCandidate(Map<String, dynamic> result, Map<String, dynamic> candidate) async {
      final id = int.tryParse((result['oggetto_id'] ?? '').toString());
      if (id == null) {
        setState(() => _pr12AiBatchStatus = 'Non posso applicare: codice oggetto non valido.');
        return;
      }
      final nested = candidate['metadati'] is Map
          ? Map<String, dynamic>.from(candidate['metadati'] as Map)
          : <String, dynamic>{};
      String valueFor(List<String> keys) {
        for (final key in keys) {
          final value = candidate[key] ?? nested[key];
          if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
        }
        return '';
      }
      final maker = valueFor(['produttore', 'editore', 'manufacturer', 'publisher']);
      final yearText = valueFor(['anno_uscita', 'anno', 'release_year', 'year']);
      final productCode = valueFor(['codice_prodotto', 'codice', 'product_code', 'set_num', 'isbn', 'item_number']);
      final title = valueFor(['titolo_prodotto', 'nome_prodotto', 'product_name', 'title', 'titolo']);
      final year = int.tryParse(yearText);
      final genericTitles = <String>{'home', 'homepage', 'official website', 'search results', 'catalogo', 'risultati della ricerca'};
      final usefulTitle = title.length >= 5 && !genericTitles.contains(title.toLowerCase());
      if (maker.isEmpty && year == null && productCode.isEmpty && !usefulTitle) {
        setState(() => _pr12AiBatchStatus = 'La fonte non contiene metadati strutturati o un titolo prodotto utilizzabile. Nessun dato modificato.');
        return;
      }
      final client = Supabase.instance.client;
      final current = await client.schema('collection').from('master_oggetti')
          .select('descrizione_oggetto,produttore,anno_uscita,codice_prodotto')
          .eq('codice_oggetto', id).maybeSingle();
      if (current == null) throw Exception('Oggetto #$id non trovato nel catalogo TEST.');
      final currentDescription = (current['descrizione_oggetto'] ?? '').toString().trim();
      final appendTitle = usefulTitle && !currentDescription.toLowerCase().contains(title.toLowerCase());
      final proposedDescription = appendTitle
          ? (currentDescription.isEmpty ? title : currentDescription + ' · ' + title)
          : currentDescription;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('CONFERMA APPLICAZIONE METADATI'),
          content: Text(
            'Oggetto #$id\n'
            'Descrizione proposta: ' + (proposedDescription.isEmpty ? 'nessuna modifica' : proposedDescription) + '\n'
            'Produttore: ' + (maker.isEmpty ? 'non trovato' : maker) + '\n'
            'Anno: ' + (year?.toString() ?? 'non trovato') + '\n'
            'Codice prodotto: ' + (productCode.isEmpty ? 'non trovato' : productCode) + '\n\n'
            'La descrizione esistente viene conservata e integrata con il titolo candidato. Gli altri campi vengono compilati soltanto se vuoti. Verifica che il candidato identifichi proprio questo oggetto.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULLA')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFERMO')),
          ],
        ),
      );
      if (accepted != true) return;
      final patch = <String, dynamic>{};
      if (appendTitle) patch['descrizione_oggetto'] = proposedDescription;
      if ((current['produttore'] ?? '').toString().trim().isEmpty && maker.isNotEmpty) patch['produttore'] = maker;
      if (current['anno_uscita'] == null && year != null && year >= 1800 && year <= DateTime.now().year + 2) patch['anno_uscita'] = year;
      if ((current['codice_prodotto'] ?? '').toString().trim().isEmpty && productCode.isNotEmpty) patch['codice_prodotto'] = productCode;
      if (patch.isEmpty) {
        setState(() => _pr12AiBatchStatus = 'Nessun campo vuoto aggiornabile per l’oggetto #$id. I dati presenti sono stati conservati.');
        return;
      }
      await client.schema('collection').from('master_oggetti').update(patch).eq('codice_oggetto', id);
      if (!mounted) return;
      setState(() => _pr12AiBatchStatus = 'Metadati applicati all’oggetto #$id: ' + patch.keys.join(', ') + '. Sono stati aggiornati soltanto campi vuoti.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Oggetto #$id aggiornato: ' + patch.keys.join(', '))));
    }
    String _pr12CategoryFromDescription(String description) {
      final v = description.toLowerCase();
      if (RegExp(r'lego|minifig|brickheadz|technic|duplo|bricklink').hasMatch(v)) return 'LEGO';
      if (RegExp(r'fumett|comic|manga|panini|salda|bonelli|graphic novel|isbn').hasMatch(v)) return 'FUMETTI';
      if (RegExp(r'orolog|watch|swatch|rolex|omega|seiko|casio|tissot|longines|tag heuer|cartier').hasMatch(v)) return 'WATCHES';
      if (RegExp(r'vinile|vinyl|disco|record|lp|musicassett|music tape').hasMatch(v)) return 'MUSIC';
      if (RegExp(r'moneta|monete|numismatic|coin|banconot|banknote|francoboll|stamp collection').hasMatch(v)) return 'NUMISMATICS';
      if (RegExp(r'carta collezionabile|trading card|pokemon card|magic the gathering|tcg|sports card').hasMatch(v)) return 'TRADING_CARDS';
      if (RegExp(r'myth cloth|saint seiya|bandai|gundam|gunpla|dragon ball|action figure|statua|transformers|optimus prime|bumblebee|megatron|star wars|naruto|one piece').hasMatch(v)) return 'ACTION_FIGURE';
      if (RegExp(r'maisto|die.?cast|modellino|motorbike|motocicletta|modellismo|auto in scala|hot wheels|matchbox').hasMatch(v)) return 'DIECAST';
      return 'COLLEZIONABILE';
    }
}
