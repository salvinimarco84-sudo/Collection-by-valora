-- PR-01: la categoria selezionata nella maschera è una categoria COLLEZIONE,
-- non una categoria merceologica. La categoria COLLEZIONE viene collegata
-- dal client a oggetto_collezione_categoria dopo la conferma del salvataggio.
-- I codici categoria della maschera non sono campi accettati dalla funzione
-- master PR-01 e devono essere rimossi prima di inoltrare il singolo oggetto.

CREATE OR REPLACE FUNCTION collection.pr_01_nuovo_oggetto_runtime(p_payload jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SET search_path TO 'collection', 'pg_temp'
AS $function$
DECLARE
  v_items jsonb;
  v_item jsonb;
  v_clean jsonb;
  v_saved jsonb := '[]'::jsonb;
  v_verified jsonb := '[]'::jsonb;
  v_result record;
  v_id bigint;
  v_confirm_data boolean := false;
  v_confirm_final boolean := false;
  v_other boolean := false;
BEGIN
  IF p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object' THEN
    RAISE EXCEPTION 'PR-01: payload deve essere un oggetto JSON.';
  END IF;

  v_confirm_data := COALESCE((p_payload->>'dati_confermati')::boolean, false);
  v_confirm_final := COALESCE((p_payload->>'conferma_finale')::boolean, false);
  v_other := COALESCE((p_payload->>'altra_operazione')::boolean, false);

  v_items := CASE
    WHEN p_payload ? 'oggetti' THEN p_payload->'oggetti'
    WHEN p_payload ? 'descrizione' THEN jsonb_build_array(
      p_payload - 'dati_confermati' - 'conferma_finale' - 'altra_operazione'
    )
    ELSE NULL
  END;

  IF jsonb_typeof(v_items) <> 'array' OR jsonb_array_length(v_items) = 0 THEN
    RAISE EXCEPTION 'PR-01: inserire almeno un oggetto.';
  END IF;

  -- Validazione completa del blocco prima di qualsiasi scrittura.
  FOR v_item IN SELECT value FROM jsonb_array_elements(v_items) LOOP
    IF jsonb_typeof(v_item) <> 'object'
       OR NULLIF(btrim(v_item->>'descrizione'), '') IS NULL THEN
      RAISE EXCEPTION 'PR-01: ogni oggetto deve avere una descrizione.';
    END IF;
  END LOOP;

  IF NOT v_confirm_data THEN
    RETURN jsonb_build_object(
      'procedura', 'PR-01',
      'stato', 'BOZZA',
      'scrittura_eseguita', false,
      'riepilogo', v_items,
      'conferma_dati_richiesta', true,
      'altra_operazione_richiesta', true,
      'conferma_finale_richiesta', true
    );
  END IF;

  IF v_other THEN
    RETURN jsonb_build_object(
      'procedura', 'PR-01',
      'stato', 'BOZZA_DA_CONTINUARE',
      'scrittura_eseguita', false,
      'messaggio', 'Nessuna scrittura. Aggiungere il nuovo ciclo e ripresentare tutte le operazioni al salvataggio finale.'
    );
  END IF;

  IF NOT v_confirm_final THEN
    RETURN jsonb_build_object(
      'procedura', 'PR-01',
      'stato', 'IN_ATTESA_CONFERMA_FINALE',
      'scrittura_eseguita', false,
      'riepilogo', v_items,
      'conferma_finale_richiesta', true
    );
  END IF;

  -- Entrambi i campi categoria sono UI metadata, non campi della funzione
  -- master. La categoria COLLEZIONE resta associata dal client tramite
  -- oggetto_collezione_categoria dopo la creazione dell'oggetto.
  FOR v_item IN SELECT value FROM jsonb_array_elements(v_items) LOOP
    v_clean := v_item - 'codice_categoria' - 'codice_categoria_collezione';

    SELECT *
      INTO v_result
      FROM collection.pr_01_nuovo_oggetto(v_clean);

    v_id := v_result.codice_oggetto;

    v_saved := v_saved || jsonb_build_array(jsonb_build_object(
      'codice_oggetto', v_id,
      'data_inserimento', v_result.data_inserimento,
      'stato', v_result.stato
    ));

    IF NOT EXISTS (
      SELECT 1
      FROM collection.master_oggetti mo
      WHERE mo.codice_oggetto = v_id
        AND mo.descrizione_oggetto = v_item->>'descrizione'
    ) THEN
      RAISE EXCEPTION 'PR-01: rilettura post-salvataggio fallita per oggetto %.', v_id;
    END IF;

    v_verified := v_verified || jsonb_build_array((
      SELECT to_jsonb(mo)
      FROM collection.master_oggetti mo
      WHERE mo.codice_oggetto = v_id
    ));
  END LOOP;

  RETURN jsonb_build_object(
    'procedura', 'PR-01',
    'stato', 'SALVATO_E_VERIFICATO',
    'scrittura_eseguita', true,
    'risultati', v_saved,
    'rilettura_database', v_verified
  );
END;
$function$;
