-- Prepara una richiesta di valutazione da metadati confermati senza creare record inventario.
-- La funzione è read-only: non inserisce né aggiorna oggetti, acquisti o valori di mercato.

CREATE OR REPLACE FUNCTION collection.pr_valuta_prepara_richiesta_metadati(
  p_metadati jsonb,
  p_mercato_riferimento text DEFAULT 'ITALIA'
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SET search_path TO 'collection', 'pg_temp'
AS $function$
DECLARE
  v_metadata jsonb := coalesce(p_metadati, '{}'::jsonb);
  v_descrizione text;
  v_produttore text;
  v_codice text;
  v_anno text;
  v_linea text;
  v_famiglia text;
  v_mercato text;
  v_config collection.config_valutazione_mercato%ROWTYPE;
  v_fonti jsonb;
BEGIN
  IF jsonb_typeof(v_metadata) <> 'object' THEN
    RAISE EXCEPTION 'VALUTA: i metadati devono essere un oggetto JSON.';
  END IF;

  v_descrizione := left(btrim(coalesce(v_metadata->>'descrizione', v_metadata->>'title', '')), 500);
  v_produttore := left(btrim(coalesce(v_metadata->>'produttore', v_metadata->>'editore', '')), 160);
  v_codice := left(btrim(coalesce(v_metadata->>'codice_prodotto', v_metadata->>'isbn', '')), 120);
  v_anno := left(btrim(coalesce(v_metadata->>'anno_uscita', v_metadata->>'anno_pubblicazione', '')), 10);
  v_linea := left(btrim(coalesce(v_metadata->>'linea_serie', v_metadata->>'linea', v_metadata->>'tema', '')), 160);
  v_famiglia := left(btrim(coalesce(v_metadata->>'categoria', v_metadata->>'famiglia', '')), 100);
  v_mercato := upper(nullif(btrim(p_mercato_riferimento), ''));
  
  IF length(v_descrizione) < 2 THEN
    RAISE EXCEPTION 'VALUTA: descrizione confermata obbligatoria.';
  END IF;
  IF v_mercato IS NULL OR v_mercato NOT IN
    ('ITALIA','EUROPA','NORD_AMERICA','SUD_AMERICA','ASIA','OCEANIA','AFRICA','MONDO') THEN
    RAISE EXCEPTION 'VALUTA: mercato di riferimento non valido.';
  END IF;

  SELECT * INTO v_config
  FROM collection.config_valutazione_mercato
  WHERE attiva = true
  ORDER BY codice_configurazione
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'VALUTA: configurazione di mercato attiva non disponibile.';
  END IF;

  v_fonti := collection.pr_prepara_fonti_ricerca_testo(
    v_descrizione,
    nullif(v_produttore, ''),
    nullif(v_linea, ''),
    nullif(v_famiglia, ''),
    'MERCATO',
    v_mercato
  );

  RETURN jsonb_build_object(
    'contratto', 'COLLECTION_VALORA_VALUTAZIONE_METADATA_V1',
    'stato_integrazione', 'RICHIESTA_PREPARATA_IN_ATTESA_RICERCA_MERCATO',
    'origine', 'COLLECTION_BY_VALORA',
    'codice_oggetto', null,
    'oggetto', jsonb_build_object(
      'descrizione', v_descrizione,
      'produttore', nullif(v_produttore, ''),
      'codice_prodotto', nullif(v_codice, ''),
      'anno_uscita', nullif(v_anno, ''),
      'linea_serie', nullif(v_linea, ''),
      'categoria', nullif(v_famiglia, ''),
      'fonte_metadati_confermati', coalesce(nullif(v_metadata->>'fonte_dati_prodotto',''), nullif(v_metadata->>'url','')),
      'url_immagine_catalogo', coalesce(nullif(v_metadata->>'url_immagine_catalogo',''), nullif(v_metadata->>'image_url',''))
    ),
    'richiesta', jsonb_build_object(
      'mercato_riferimento', v_mercato,
      'data_riferimento', current_date,
      'preferenza_vendite_concluse', v_config.preferenza_vendite_concluse,
      'numero_comparabili_obiettivo', v_config.numero_comparabili_obiettivo,
      'risultati_richiesti', jsonb_build_array(
        'intervallo_valore_minimo_massimo',
        'valore_centrale_se_supportato',
        'mercato_e_valuta',
        'comparabili_con_fonti_e_date',
        'numero_comparabili',
        'affidabilita_e_limiti',
        'probabilita_di_vendita_se_supportata',
        'indicazioni_commerciali'
      ),
      'disclaimer_obbligatorio', v_config.disclaimer_obbligatorio
    ),
    'fonti_ricerca', v_fonti->'fonti_generali',
    'numero_fonti', v_fonti->'numero_fonti_generali',
    'fonti_specialistiche_franchise', v_fonti->'fonti_specialistiche_franchise',
    'numero_fonti_franchise', v_fonti->'numero_fonti_franchise',
    'franchise_rilevati', v_fonti->'franchise_rilevati',
    'ricerca_franchise_obbligatoria', v_fonti->'ricerca_franchise_obbligatoria',
    'regola_fonti', v_fonti->'regola_fonti',
    'ricerca_esterna_eseguita', false,
    'valutazione_numerica_disponibile', false,
    'valore_mercato', null,
    'affidabilita', null,
    'vincoli', jsonb_build_array(
      'sola_preparazione_senza_ricerca_esterna',
      'nessuna_scrittura_in_inventario',
      'nessun_valore_di_mercato_inventato',
      'non_confondere_costo_di_acquisto_e_valore_di_mercato',
      'la_stima_sara_calcolata_solo_dopo_acquisizione_di_comparabili'
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION collection.pr_valuta_prepara_richiesta_metadati(jsonb, text) FROM PUBLIC, anon, authenticated;

DO $patch$
DECLARE
  v_definition text;
  v_old text := $old$
    when 'MARKET_VALUATION_PREPARE' then
      if v_id is null then raise exception 'codice_oggetto obbligatorio.'; end if;
      v_result := collection.pr_valuta_prepara_richiesta(v_id,coalesce(v_args->>'mercato_riferimento','ITALIA'));
    when 'SEARCH_SOURCES' then
$old$;
  v_new text := $new$
    when 'MARKET_VALUATION_PREPARE' then
      if v_id is null then raise exception 'codice_oggetto obbligatorio.'; end if;
      v_result := collection.pr_valuta_prepara_richiesta(v_id,coalesce(v_args->>'mercato_riferimento','ITALIA'));
    when 'MARKET_VALUATION_PREPARE_METADATA' then
      v_result := collection.pr_valuta_prepara_richiesta_metadati(
        coalesce(v_args->'metadati','{}'::jsonb),
        coalesce(v_args->>'mercato_riferimento','ITALIA')
      );
    when 'SEARCH_SOURCES' then
$new$;
BEGIN
  SELECT pg_get_functiondef(
    'collection.runtime_esegui_consultazione(uuid,text,jsonb)'::regprocedure
  ) INTO v_definition;

  IF position('MARKET_VALUATION_PREPARE_METADATA' in v_definition) > 0 THEN
    RAISE NOTICE 'Ingresso metadata-only già presente.';
    RETURN;
  END IF;

  IF position(v_old in v_definition) = 0 THEN
    RAISE EXCEPTION 'Blocco MARKET_VALUATION_PREPARE non trovato: patch interrotta.';
  END IF;

  v_definition := replace(v_definition, v_old, v_new);
  EXECUTE v_definition;
END;
$patch$;
