-- PR-04: persist the collection category selected on each purchased object.
-- Apply only to COLLECTION by VALORA TEST.
BEGIN;

CREATE OR REPLACE FUNCTION collection.pr_04_nuovo_acquisto(p_operazioni jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'collection', 'pg_temp'
AS $function$
DECLARE
  v_payload jsonb;
  v_ops jsonb;
  v_item jsonb;
  v_result jsonb;
  v_saved jsonb := '[]'::jsonb;
  v_verified jsonb := '[]'::jsonb;
  v_confirm boolean := false;
  v_data_confirmed boolean := false;
  v_other boolean := false;
  v_total numeric(14,2);
  v_sum numeric(14,2);
  v_id bigint;
  v_row record;
  v_cash numeric(14,2);
  v_linked_sum numeric(14,2);
  v_object jsonb;
  v_category text;
  v_object_id bigint;
  v_descr text;
  v_cond text;
  v_completezza text;
  v_dest text;
  v_note text;
  v_category_matches integer;
BEGIN
  IF p_operazioni IS NULL OR jsonb_typeof(p_operazioni)<>'object' THEN
    RAISE EXCEPTION 'PR-04: il payload deve essere un oggetto JSON.';
  END IF;

  v_payload := p_operazioni;
  v_confirm := COALESCE((v_payload->>'conferma_finale')::boolean,false);
  v_data_confirmed := COALESCE((v_payload->>'dati_confermati')::boolean,false);
  v_other := COALESCE((v_payload->>'altra_operazione')::boolean,false);

  v_ops := CASE
    WHEN v_payload ? 'operazioni' THEN v_payload->'operazioni'
    WHEN v_payload ? 'data_acquisto' THEN jsonb_build_array(v_payload - 'conferma_finale' - 'dati_confermati' - 'altra_operazione')
    ELSE NULL
  END;

  IF jsonb_typeof(v_ops)<>'array' OR jsonb_array_length(v_ops)=0 THEN
    RAISE EXCEPTION 'PR-04: inserire almeno un acquisto.';
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(v_ops) LOOP
    IF jsonb_typeof(v_item)<>'object'
       OR NULLIF(BTRIM(v_item->>'data_acquisto'),'') IS NULL
       OR NULLIF(BTRIM(v_item->>'importo_totale'),'') IS NULL
       OR jsonb_typeof(v_item->'oggetti')<>'array'
       OR jsonb_array_length(v_item->'oggetti')=0 THEN
      RAISE EXCEPTION 'PR-04: ogni acquisto richiede data, importo totale e almeno un oggetto.';
    END IF;

    v_total := (v_item->>'importo_totale')::numeric(14,2);
    SELECT COALESCE(SUM((x.value->>'valore_acquisto')::numeric(14,2)),0)
      INTO v_sum
      FROM jsonb_array_elements(v_item->'oggetti') x(value);

    IF v_total<=0 OR v_sum IS DISTINCT FROM v_total THEN
      RAISE EXCEPTION 'PR-04: quadratura non valida. Totale dichiarato %, somma oggetti %.',v_total,v_sum;
    END IF;
  END LOOP;

  IF NOT v_data_confirmed THEN
    RETURN jsonb_build_object(
      'procedura','PR-04','stato','BOZZA',
      'scrittura_eseguita',false,
      'numero_acquisti',jsonb_array_length(v_ops),
      'riepilogo',v_ops,
      'quadratura_verificata',true,
      'conferma_dati_richiesta',true,
      'altra_operazione_richiesta',true,
      'conferma_finale_richiesta',true
    );
  END IF;

  IF v_other THEN
    RETURN jsonb_build_object(
      'procedura','PR-04','stato','BOZZA_DA_CONTINUARE',
      'scrittura_eseguita',false,
      'numero_acquisti',jsonb_array_length(v_ops),
      'messaggio','Nessuna scrittura eseguita. Aggiungere il nuovo ciclo e ripresentare l’intero lotto.'
    );
  END IF;

  IF NOT v_confirm THEN
    RETURN jsonb_build_object(
      'procedura','PR-04','stato','IN_ATTESA_CONFERMA_FINALE',
      'scrittura_eseguita',false,
      'conferma_finale_richiesta',true,
      'riepilogo',v_ops
    );
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(v_ops) LOOP
    SELECT to_jsonb(r) INTO v_result
    FROM collection.pr_03_nuovo_acquisto(v_item) r;
    v_saved := v_saved || jsonb_build_array(v_result);
    v_id := (v_result->>'codice_acquisto')::bigint;

    -- Persist the collection category selected on each purchase item.
    IF EXISTS (
      SELECT 1
      FROM jsonb_array_elements(v_item->'oggetti') a(value)
      JOIN jsonb_array_elements(v_item->'oggetti') b(value)
        ON a.value->>'descrizione' = b.value->>'descrizione'
       AND COALESCE(a.value->>'condizione','') = COALESCE(b.value->>'condizione','')
       AND COALESCE(a.value->>'completezza','') = COALESCE(b.value->>'completezza','')
       AND COALESCE(a.value->>'destinazione','') = COALESCE(b.value->>'destinazione','')
       AND NULLIF(BTRIM(a.value->>'note'),'') IS NOT DISTINCT FROM NULLIF(BTRIM(b.value->>'note'),'')
      WHERE NULLIF(BTRIM(a.value->>'codice_categoria_collezione'),'')
            IS DISTINCT FROM NULLIF(BTRIM(b.value->>'codice_categoria_collezione'),'')
    ) THEN
      RAISE EXCEPTION 'PR-04: lo stesso oggetto non può essere associato a due categorie COLLEZIONE diverse nello stesso acquisto.';
    END IF;

    FOR v_object IN SELECT value FROM jsonb_array_elements(v_item->'oggetti') LOOP
      v_descr := NULLIF(BTRIM(v_object->>'descrizione'),'');
      v_cond := NULLIF(BTRIM(v_object->>'condizione'),'');
      v_completezza := NULLIF(BTRIM(v_object->>'completezza'),'');
      v_dest := NULLIF(BTRIM(v_object->>'destinazione'),'');
      v_note := NULLIF(BTRIM(v_object->>'note'),'');
      v_category := NULLIF(BTRIM(v_object->>'codice_categoria_collezione'),'');

      IF v_dest = 'COLLEZIONE' THEN
        IF v_category IS NULL OR NOT EXISTS (
          SELECT 1 FROM collection.categorie_merceologiche cm
          WHERE cm.codice_categoria = v_category
        ) THEN
          RAISE EXCEPTION 'PR-04: categoria COLLEZIONE mancante o non valida per l''oggetto "%".', v_descr;
        END IF;

        v_category_matches := 0;
        FOR v_object_id IN
          SELECT DISTINCT ao.codice_oggetto
          FROM collection.acquisti_oggetti ao
          JOIN collection.master_oggetti mo ON mo.codice_oggetto = ao.codice_oggetto
          WHERE ao.codice_acquisto = v_id
            AND ao.descrizione_oggetto = v_descr
            AND mo.condizione IS NOT DISTINCT FROM v_cond
            AND mo.completezza IS NOT DISTINCT FROM v_completezza
            AND mo.destinazione IS NOT DISTINCT FROM v_dest
            AND mo.note IS NOT DISTINCT FROM v_note
        LOOP
          INSERT INTO collection.oggetto_collezione_categoria
            (codice_oggetto, codice_categoria, fonte_assegnazione, stato_verifica, aggiornato_il)
          VALUES
            (v_object_id, v_category, 'MANUALE', 'VERIFICATO', now())
          ON CONFLICT (codice_oggetto) DO UPDATE SET
            codice_categoria = EXCLUDED.codice_categoria,
            fonte_assegnazione = EXCLUDED.fonte_assegnazione,
            stato_verifica = EXCLUDED.stato_verifica,
            aggiornato_il = EXCLUDED.aggiornato_il;
          v_category_matches := v_category_matches + 1;
        END LOOP;

        IF v_category_matches = 0 THEN
          RAISE EXCEPTION 'PR-04: impossibile collegare la categoria COLLEZIONE all''oggetto "%" dell''acquisto %.', v_descr, v_id;
        END IF;
      ELSIF v_category IS NOT NULL THEN
        RAISE EXCEPTION 'PR-04: una categoria COLLEZIONE non può essere assegnata a un oggetto con destinazione %.', v_dest;
      END IF;
    END LOOP;

    SELECT ma.importo_totale_acquisto,
           COALESCE(SUM(ao.valore_acquisto_oggetto),0)
      INTO v_row
      FROM collection.master_acquisti ma
      LEFT JOIN collection.acquisti_oggetti ao ON ao.codice_acquisto=ma.codice_acquisto
     WHERE ma.codice_acquisto=v_id
     GROUP BY ma.importo_totale_acquisto;

    SELECT c.importo INTO v_cash
    FROM collection.cassa c
    WHERE c.codice_acquisto=v_id AND c.tipo_movimento='ACQUISTO'
    ORDER BY c.codice_movimento DESC LIMIT 1;

    SELECT COALESCE(SUM(ao.valore_acquisto_oggetto),0) INTO v_linked_sum
    FROM collection.acquisti_oggetti ao
    WHERE ao.codice_acquisto=v_id AND ao.incluso_nella_quadratura=true;

    IF v_row.importo_totale_acquisto IS NULL
       OR v_row.importo_totale_acquisto<>v_cash
       OR v_linked_sum<>v_row.importo_totale_acquisto THEN
      RAISE EXCEPTION 'PR-04: rilettura o quadratura post-salvataggio fallita per acquisto %.',v_id;
    END IF;

    v_verified := v_verified || jsonb_build_array(jsonb_build_object(
      'codice_acquisto',v_id,
      'importo_totale',v_row.importo_totale_acquisto,
      'somma_oggetti',v_linked_sum,
      'movimento_cassa',v_cash,
      'verificato',true
    ));
  END LOOP;

  RETURN jsonb_build_object(
    'procedura','PR-04','stato','SALVATO_E_VERIFICATO',
    'scrittura_eseguita',true,
    'numero_acquisti',jsonb_array_length(v_ops),
    'risultati',v_saved,
    'verifica_post_salvataggio',v_verified
  );
END;
$function$


COMMIT;
