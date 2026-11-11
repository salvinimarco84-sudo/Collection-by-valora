part of '../main.dart';

/// Lettura paginata del catalogo usato dall'Assistente VALORA.
Future<List<Map<String, dynamic>>> _fetchValoraCatalogObjects() async {
  const pageSize = 500;
  var offset = 0;
  final rows = <Map<String, dynamic>>[];
  const excludedStatuses = {
    'VENDUTO', 'SOLD', 'PERSO', 'LOST', 'DISTRUTTO', 'DESTROYED',
    'USCITO', 'EXITED', 'ACCORPATO', 'MERGED',
  };

  // Legge tutte le pagine senza fermarsi ai primi 500 record.
  while (true) {
    final page = await Supabase.instance.client.schema('collection')
        .from('master_oggetti')
        .select('codice_oggetto,descrizione_oggetto,produttore,codice_prodotto,stato,destinazione,condizione,completezza,valore_mercato')
        .or('archiviato_test.is.null,archiviato_test.eq.false')
        .order('descrizione_oggetto')
        .order('codice_oggetto')
        .range(offset, offset + pageSize - 1);

    final pageRows = (page as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((row) => !excludedStatuses.contains(
            (row['stato'] ?? '').toString().trim().toUpperCase()))
        .toList();
    rows.addAll(pageRows);

    if (page.length < pageSize) break;
    offset += pageSize;
  }
  return rows;
}
