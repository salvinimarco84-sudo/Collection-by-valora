CREATE OR REPLACE FUNCTION collection.pr_21_ricerca_schede(p_cerca text DEFAULT NULL::text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'collection', 'pg_temp'
AS $function$
WITH params AS (
  SELECT lower(btrim(coalesce(p_cerca,''))) AS q,
         lower(btrim(coalesce(p_cerca,''))) ~ '(minifig|minifigure|collezion|serie|series|batman movie|ninjago movie|lego movie)' AS ricerca_collezioni_minifigure
),
righe AS (
  SELECT mo.codice_oggetto, mo.descrizione_oggetto, mo.condizione, mo.completezza,
         mo.destinazione, mo.stato, mo.quantita, mo.valore_oggetto, mo.valuta_valore,
         mo.archiviato_test,
         cm.codice_categoria,
         cm.nome_categoria AS categoria,
         mm.categoria_prodotto,
         mm.tema,
         mm.sottotema
  FROM collection.master_oggetti mo
  LEFT JOIN collection.master_metadati mm ON mm.codice_oggetto=mo.codice_oggetto
  LEFT JOIN collection.metadati_specifici_oggetto ms ON ms.codice_oggetto=mo.codice_oggetto
  LEFT JOIN collection.oggetto_categoria oc ON oc.codice_oggetto=mo.codice_oggetto
  LEFT JOIN collection.categorie_merceologiche cm ON cm.id_categoria=oc.id_categoria
  CROSS JOIN params p
  WHERE mo.stato='DISPONIBILE'
    AND mo.destinazione='COLLEZIONE'
    AND NOT coalesce(mo.archiviato_test,false)
    AND (
      (p.ricerca_collezioni_minifigure AND mo.codice_oggetto IN
        (1400,1404,1414,1423,1436,1450,1463,1471,1482,1505,1524,1569,1593,1658,1717,1859,1900,1932,1985,2012,2086,2102,2126,2283,2284,2285,2286,2287,2288,2291,2295,2299,2308))
      OR
      (NOT p.ricerca_collezioni_minifigure AND
        (p.q='' OR mo.codice_oggetto::text ILIKE '%'||p.q||'%' OR
         mo.descrizione_oggetto ILIKE '%'||btrim(coalesce(p_cerca,''))||'%'))
    )
)
SELECT jsonb_build_object(
  'totale',count(*),
  'oggetti',coalesce(jsonb_agg(jsonb_build_object(
    'codice_oggetto',q.codice_oggetto,
    'descrizione_oggetto',q.descrizione_oggetto,
    'condizione',q.condizione,
    'completezza',q.completezza,
    'destinazione',q.destinazione,
    'stato',q.stato,
    'quantita',q.quantita,
    'valore_oggetto',q.valore_oggetto,
    'totale_calcolato',collection.calcola_totale_prezzo_unitario(q.valore_oggetto,q.quantita),
    'valuta_valore',q.valuta_valore,
    'archiviato_test',q.archiviato_test,
    'codice_categoria',q.codice_categoria,
    'categoria',q.categoria,
    'categoria_prodotto',q.categoria_prodotto,
    'tema',q.tema,
    'sottotema',q.sottotema,
    'modificabile',false
  ) ORDER BY q.codice_oggetto),'[]'::jsonb)
)
FROM righe q;
$function$;

-- Alias di compatibilità per client non ancora aggiornati.
CREATE OR REPLACE FUNCTION collection.pr_11_ricerca_schede(p_cerca text DEFAULT NULL::text)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'collection', 'pg_temp'
AS $function$
  SELECT collection.pr_21_ricerca_schede(p_cerca);
$function$;

GRANT EXECUTE ON FUNCTION collection.pr_21_ricerca_schede(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION collection.pr_11_ricerca_schede(text) TO authenticated, service_role;
