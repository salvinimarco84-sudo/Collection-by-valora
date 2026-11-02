-- PR-08: single transaction for multiple individually listed items.
-- TEST environment migration. Production is intentionally untouched.

CREATE OR REPLACE FUNCTION collection.pr_08_chiudi_vendita_multipla(p_payload jsonb, p_salva boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'collection', 'pg_temp'
AS $function$
DECLARE
  v_ops jsonb;
  v_item jsonb;
  v_cycle record;
  v_n integer;
  v_distinct integer;
  v_date date;
  v_total numeric(14,2);
  v_list_total numeric(14,2) := 0;
  v_alloc numeric(14,2);
  v_allocated numeric(14,2) := 0;
  v_i integer := 0;
  v_currency text;
  v_platform bigint;
  v_channel text;
  v_channel_name text;
  v_note text;
  v_allocations jsonb := '[]'::jsonb;
  v_results jsonb := '[]'::jsonb;
  v_group uuid;
  v_first_sale bigint;
  v_sale_id bigint;
  v_sales_count integer;
  v_cash_count integer;
  v_closed_count integer;
  v_description text;
BEGIN
  IF p_payload IS NULL OR jsonb_typeof(p_payload) <> 'object' THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: payload non valido.';
  END IF;
  v_ops := p_payload->'operazioni';
  IF jsonb_typeof(v_ops) <> 'array' OR jsonb_array_length(v_ops) < 2 THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: selezionare almeno due vendite aperte.';
  END IF;
  SELECT count(*), count(DISTINCT value->>'codice_vendita_aperta')
    INTO v_n, v_distinct
  FROM jsonb_array_elements(v_ops);
  IF v_n <> v_distinct THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: una vendita è stata selezionata più di una volta.';
  END IF;

  v_date := NULLIF(btrim(p_payload->>'data_vendita'),'')::date;
  v_total := NULLIF(btrim(p_payload->>'importo_totale_effettivo'),'')::numeric(14,2);
  v_platform := NULLIF(btrim(p_payload->>'codice_piattaforma'),'')::bigint;
  v_channel := NULLIF(btrim(p_payload->>'canale_esterno'),'');
  v_note := NULLIF(btrim(p_payload->>'note'),'');
  IF v_date IS NULL THEN RAISE EXCEPTION 'PR-08 MULTIPLA: data vendita obbligatoria.'; END IF;
  IF v_total IS NULL OR v_total <= 0 THEN RAISE EXCEPTION 'PR-08 MULTIPLA: importo totale effettivo non valido.'; END IF;
  IF (v_platform IS NULL AND v_channel IS NULL) OR (v_platform IS NOT NULL AND v_channel IS NOT NULL) THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: indicare una piattaforma oppure un canale esterno, non entrambi.';
  END IF;
  IF v_platform IS NOT NULL THEN
    SELECT nome_piattaforma INTO v_channel_name
    FROM collection.piattaforme WHERE codice_piattaforma = v_platform;
    IF NOT FOUND THEN RAISE EXCEPTION 'PR-08 MULTIPLA: piattaforma effettiva inesistente.'; END IF;
  ELSE
    v_channel_name := v_channel;
  END IF;

  FOR v_item IN SELECT value FROM jsonb_array_elements(v_ops) LOOP
    IF jsonb_typeof(v_item) <> 'object'
       OR NULLIF(btrim(v_item->>'codice_vendita_aperta'),'') IS NULL
       OR (v_item->>'codice_vendita_aperta') !~ '^[0-9]+$'
       OR btrim(coalesce(v_item->>'esito','')) <> 'VENDITA EFFETTIVA' THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: ogni riga deve identificare una vendita aperta con esito VENDITA EFFETTIVA.';
    END IF;
    IF EXISTS (
      SELECT 1 FROM jsonb_object_keys(v_item) AS k(key)
      WHERE key NOT IN ('codice_vendita_aperta','esito')
    ) THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: importo, data e piattaforma devono essere unici a livello di transazione.';
    END IF;
  END LOOP;

  FOR v_cycle IN
    SELECT oiv.codice_vendita_aperta, oiv.codice_oggetto, oiv.descrizione_oggetto,
           oiv.prezzo_di_vendita, oiv.valuta, oiv.stato_ciclo_vendita, oiv.codice_lotto,
           mo.stato AS stato_oggetto, mo.destinazione
    FROM collection.master_oggetti_in_vendita oiv
    JOIN collection.master_oggetti mo ON mo.codice_oggetto = oiv.codice_oggetto
    WHERE oiv.codice_vendita_aperta IN (
      SELECT (value->>'codice_vendita_aperta')::bigint
      FROM jsonb_array_elements(v_ops)
    )
    ORDER BY oiv.codice_vendita_aperta
    FOR UPDATE OF oiv, mo
  LOOP
    IF v_cycle.stato_ciclo_vendita <> 'APERTO'
       OR v_cycle.stato_oggetto <> 'IN VENDITA'
       OR v_cycle.destinazione <> 'RIVENDITA' THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: vendita aperta % non più chiudibile.', v_cycle.codice_vendita_aperta;
    END IF;
    IF v_cycle.codice_lotto IS NOT NULL THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: vendita aperta % appartiene già a un lotto di inserzione; usare la procedura lotto.', v_cycle.codice_vendita_aperta;
    END IF;
    IF v_cycle.prezzo_di_vendita IS NULL OR v_cycle.prezzo_di_vendita <= 0 THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: prezzo di inserzione non valido per la vendita %.', v_cycle.codice_vendita_aperta;
    END IF;
    IF v_currency IS NULL THEN
      v_currency := btrim(v_cycle.valuta::text);
    ELSIF v_currency <> btrim(v_cycle.valuta::text) THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: le inserzioni selezionate hanno valute differenti.';
    END IF;

    v_list_total := v_list_total + v_cycle.prezzo_di_vendita;
    v_i := v_i + 1;
    IF v_i = v_n THEN
      v_alloc := round(v_total - v_allocated, 2);
    ELSE
      v_alloc := round(
        v_total * v_cycle.prezzo_di_vendita /
        NULLIF((
          SELECT sum(oiv2.prezzo_di_vendita)
          FROM collection.master_oggetti_in_vendita oiv2
          WHERE oiv2.codice_vendita_aperta IN (
            SELECT (value->>'codice_vendita_aperta')::bigint
            FROM jsonb_array_elements(v_ops)
          )
        ), 0), 2);
    END IF;
    IF v_alloc <= 0 THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: importo totale troppo basso per attribuire un ricavo positivo a ogni oggetto.';
    END IF;
    v_allocated := v_allocated + v_alloc;
    v_allocations := v_allocations || jsonb_build_array(jsonb_build_object(
      'codice_vendita_aperta', v_cycle.codice_vendita_aperta,
      'codice_oggetto', v_cycle.codice_oggetto,
      'descrizione_oggetto', v_cycle.descrizione_oggetto,
      'prezzo_inserzione', v_cycle.prezzo_di_vendita,
      'valuta', v_currency,
      'importo_allocato', v_alloc
    ));
  END LOOP;

  IF v_i <> v_n THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: una o più vendite selezionate non esistono o non sono più aperte.';
  END IF;
  IF v_list_total <= 0 OR v_currency IS NULL THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: totale dei prezzi di inserzione non valido.';
  END IF;
  IF v_currency <> 'EUR' THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: la chiusura aggregata supporta al momento solo inserzioni in EUR.';
  END IF;

  IF NOT p_salva THEN
    RETURN jsonb_build_object(
      'procedura','PR-08 MULTIPLA','stato','BOZZA','scrittura_eseguita',false,
      'numero_oggetti',v_n,'totale_prezzi_inserzione',v_list_total,
      'importo_totale_effettivo',v_total,'data_vendita',v_date,
      'piattaforma_effettiva',v_channel_name,'allocazioni',v_allocations,
      'conferma_dati_richiesta',true,'conferma_finale_richiesta',true
    );
  END IF;

  v_description := 'Transazione vendita multipla · ' || v_n || ' oggetti · ' || v_date::text;
  INSERT INTO collection.lotti_vendita
    (descrizione_lotto, prezzo_totale_inserzione, valuta, stato_lotto, chiuso_il, importo_effettivo, note)
  VALUES
    (v_description, v_list_total, v_currency, 'CHIUSO', v_date, v_total, v_note)
  RETURNING codice_lotto INTO v_group;

  FOR v_item IN SELECT value FROM jsonb_array_elements(v_allocations) LOOP
    INSERT INTO collection.master_vendite
      (codice_oggetto, descrizione_oggetto, data_vendita, importo_vendita, valuta,
       codice_piattaforma, canale_effettivo, codice_vendita_aperta, stato_vendita, note, codice_lotto)
    VALUES
      ((v_item->>'codice_oggetto')::bigint,
       v_item->>'descrizione_oggetto',
       v_date,
       (v_item->>'importo_allocato')::numeric(14,2),
       v_currency,
       v_platform,
       v_channel_name,
       (v_item->>'codice_vendita_aperta')::bigint,
       'CONCLUSA',
       concat_ws(' · ', v_note, 'Ricavo ripartito proporzionalmente nella transazione ' || v_group::text),
       v_group)
    RETURNING codice_vendita INTO v_sale_id;
    IF v_first_sale IS NULL THEN v_first_sale := v_sale_id; END IF;

    UPDATE collection.master_oggetti
      SET stato = 'VENDUTO'
      WHERE codice_oggetto = (v_item->>'codice_oggetto')::bigint;
    UPDATE collection.master_oggetti_in_vendita
      SET stato_ciclo_vendita = 'CHIUSO'
      WHERE codice_vendita_aperta = (v_item->>'codice_vendita_aperta')::bigint;

    INSERT INTO collection.storico
      (data_evento, codice_oggetto, codice_vendita, codice_vendita_aperta,
       tipo_evento, origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
    VALUES
      (CURRENT_DATE, (v_item->>'codice_oggetto')::bigint, v_sale_id,
       (v_item->>'codice_vendita_aperta')::bigint, 'VENDITA', 'CHIUDI VENDITA',
       'stato', 'IN VENDITA', 'VENDUTO',
       'Transazione ' || v_group::text || ' · Ricavo attribuito: ' || (v_item->>'importo_allocato')),
      (CURRENT_DATE, (v_item->>'codice_oggetto')::bigint, v_sale_id,
       (v_item->>'codice_vendita_aperta')::bigint, 'CHIUSURA_VENDITA', 'CHIUDI VENDITA',
       'stato_ciclo_vendita', 'APERTO', 'CHIUSO',
       'Chiusura come parte della transazione ' || v_group::text);
    v_results := v_results || jsonb_build_array(v_item || jsonb_build_object('codice_vendita',v_sale_id));
  END LOOP;

  INSERT INTO collection.cassa
    (data, descrizione, tipo_movimento, importo, valuta, tipologia,
     codice_piattaforma, codice_vendita, codice_lotto)
  VALUES
    (v_date, v_description || ' · ' || v_channel_name, 'VENDITA', v_total, v_currency,
     'ENTRATA', v_platform, v_first_sale, v_group);

  SELECT count(*) INTO v_sales_count
  FROM collection.master_vendite
  WHERE codice_lotto = v_group AND stato_vendita = 'CONCLUSA';
  SELECT count(*) INTO v_cash_count
  FROM collection.cassa
  WHERE codice_lotto = v_group AND tipologia = 'ENTRATA' AND importo = v_total;
  SELECT count(*) INTO v_closed_count
  FROM collection.master_oggetti_in_vendita
  WHERE codice_vendita_aperta IN (
    SELECT (value->>'codice_vendita_aperta')::bigint FROM jsonb_array_elements(v_ops)
  ) AND stato_ciclo_vendita = 'CHIUSO';

  IF v_sales_count <> v_n OR v_cash_count <> 1 OR v_closed_count <> v_n THEN
    RAISE EXCEPTION 'PR-08 MULTIPLA: verifica finale non superata (vendite %, incassi %, cicli chiusi %).', v_sales_count, v_cash_count, v_closed_count;
  END IF;

  RETURN jsonb_build_object(
    'procedura','PR-08 MULTIPLA','stato','SALVATO_E_VERIFICATO','scrittura_eseguita',true,
    'codice_transazione',v_group,'numero_oggetti',v_n,
    'totale_prezzi_inserzione',v_list_total,'importo_totale_effettivo',v_total,
    'movimenti_incasso',1,'vendite',v_results
  );
END;
$function$


REVOKE ALL ON FUNCTION collection.pr_08_chiudi_vendita_multipla(jsonb,boolean) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION collection.pr_08_chiudi_vendita_multipla(jsonb,boolean) TO service_role;

CREATE OR REPLACE FUNCTION collection.pr_08_chiudi_vendita(p_operazioni jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'collection', 'pg_temp'
AS $function$
declare
  v_payload jsonb;
  v_ops jsonb;
  v_item jsonb;
  v_preview jsonb := '[]'::jsonb;
  v_saved jsonb;
  v_verified jsonb := '[]'::jsonb;
  v_id bigint;
  v_esito text;
  v_confirm_data boolean := false;
  v_confirm_final boolean := false;
  v_other boolean := false;
  v_current jsonb;
  v_result jsonb;
begin
  if p_operazioni is null or jsonb_typeof(p_operazioni) <> 'object' then
    raise exception 'PR-08: il payload deve essere un oggetto JSON.';
  end if;

  v_payload := p_operazioni;
  v_confirm_data := coalesce((v_payload->>'dati_confermati')::boolean,false);
  v_confirm_final := coalesce((v_payload->>'conferma_finale')::boolean,false);
  v_other := coalesce((v_payload->>'altra_operazione')::boolean,false);

  IF coalesce((v_payload->>'modalita_vendita_multipla')::boolean,false) THEN
    IF v_other THEN
      RAISE EXCEPTION 'PR-08 MULTIPLA: non è possibile aggiungere ulteriori operazioni nella stessa transazione.';
    END IF;
    IF NOT v_confirm_data THEN
      RETURN collection.pr_08_chiudi_vendita_multipla(v_payload,false);
    END IF;
    IF NOT v_confirm_final THEN
      v_result := collection.pr_08_chiudi_vendita_multipla(v_payload,false);
      RETURN jsonb_build_object(
        'procedura','PR-08',
        'stato','IN_ATTESA_CONFERMA_FINALE',
        'scrittura_eseguita',false,
        'numero_operazioni',jsonb_array_length(v_payload->'operazioni'),
        'riepilogo',v_result->'allocazioni',
        'dettaglio_transazione',v_result,
        'conferma_finale_richiesta',true
      );
    END IF;
    RETURN collection.pr_08_chiudi_vendita_multipla(v_payload,true);
  END IF;

  v_ops := case
    when v_payload ? 'operazioni' then v_payload->'operazioni'
    when v_payload ? 'codice_vendita_aperta' then
      jsonb_build_array(v_payload - 'dati_confermati' - 'conferma_finale' - 'altra_operazione')
    else null
  end;

  if jsonb_typeof(v_ops) <> 'array' or jsonb_array_length(v_ops)=0 then
    raise exception 'PR-08: selezionare almeno una vendita aperta da chiudere.';
  end if;

  for v_item in select value from jsonb_array_elements(v_ops) loop
    if jsonb_typeof(v_item) <> 'object'
       or nullif(v_item->>'codice_vendita_aperta','') is null
       or nullif(btrim(v_item->>'esito'),'') is null then
      raise exception 'PR-08: ogni chiusura richiede codice_vendita_aperta ed esito.';
    end if;

    if exists (
      select 1 from jsonb_object_keys(v_item) k
      where k not in (
        'codice_vendita_aperta','esito','data_vendita',
        'importo_vendita','codice_piattaforma','canale_esterno','note'
      )
    ) then
      raise exception 'PR-08: campo non previsto nel payload.';
    end if;

    v_id := (v_item->>'codice_vendita_aperta')::bigint;
    v_esito := btrim(v_item->>'esito');

    if v_esito not in ('VENDITA EFFETTIVA','CHIUSURA SENZA VENDITA') then
      raise exception 'PR-08: esito non valido per la vendita %.',v_id;
    end if;

    if not exists (
      select 1 from collection.master_oggetti_in_vendita
      where codice_vendita_aperta=v_id and stato_ciclo_vendita='APERTO'
    ) then
      raise exception 'PR-08: vendita aperta % inesistente o non APERTA.',v_id;
    end if;

    if v_esito='VENDITA EFFETTIVA' then
      if nullif(btrim(v_item->>'data_vendita'),'') is null then
        raise exception 'PR-08: data_vendita obbligatoria per la vendita %.',v_id;
      end if;
      if nullif(btrim(v_item->>'importo_vendita'),'') is null
         or (v_item->>'importo_vendita')::numeric <= 0 then
        raise exception 'PR-08: importo_vendita deve essere maggiore di zero per la vendita %.',v_id;
      end if;
      if (
        nullif(btrim(v_item->>'codice_piattaforma'),'') is null
        and nullif(btrim(v_item->>'canale_esterno'),'') is null
      ) or (
        nullif(btrim(v_item->>'codice_piattaforma'),'') is not null
        and nullif(btrim(v_item->>'canale_esterno'),'') is not null
      ) then
        raise exception 'PR-08: indicare una piattaforma registrata oppure un canale esterno, non entrambi.';
      end if;
      if nullif(btrim(v_item->>'codice_piattaforma'),'') is not null
         and not exists (
           select 1 from collection.piattaforme p
           where p.codice_piattaforma=(v_item->>'codice_piattaforma')::bigint
         ) then
        raise exception 'PR-08: piattaforma effettiva inesistente per la vendita %.',v_id;
      end if;
    else
      if nullif(btrim(v_item->>'data_vendita'),'') is not null
         or nullif(btrim(v_item->>'importo_vendita'),'') is not null
         or nullif(btrim(v_item->>'codice_piattaforma'),'') is not null
         or nullif(btrim(v_item->>'canale_esterno'),'') is not null then
        raise exception 'PR-08: una chiusura senza vendita non deve contenere dati di vendita effettiva.';
      end if;
    end if;
  end loop;

  if not v_confirm_data then
    for v_item in select value from jsonb_array_elements(v_ops) loop
      v_id := (v_item->>'codice_vendita_aperta')::bigint;

      select jsonb_build_object(
        'codice_vendita_aperta',oiv.codice_vendita_aperta,
        'codice_oggetto',oiv.codice_oggetto,
        'descrizione_oggetto',oiv.descrizione_oggetto,
        'data_inizio_vendita',oiv.data_inizio_vendita,
        'prezzo_di_vendita',oiv.prezzo_di_vendita,
        'stato_ciclo_vendita',oiv.stato_ciclo_vendita,
        'stato_oggetto',mo.stato,
        'esito_proposto',v_item->>'esito',
        'dati_chiusura',v_item
      )
      into v_current
      from collection.master_oggetti_in_vendita oiv
      join collection.master_oggetti mo on mo.codice_oggetto=oiv.codice_oggetto
      where oiv.codice_vendita_aperta=v_id;

      v_preview := v_preview || jsonb_build_array(v_current);
    end loop;

    return jsonb_build_object(
      'procedura','PR-08',
      'stato','BOZZA',
      'scrittura_eseguita',false,
      'numero_operazioni',jsonb_array_length(v_ops),
      'riepilogo',v_preview,
      'conferma_dati_richiesta',true,
      'altra_operazione_richiesta',true,
      'conferma_finale_richiesta',true
    );
  end if;

  if v_other then
    return jsonb_build_object(
      'procedura','PR-08',
      'stato','BOZZA_DA_CONTINUARE',
      'scrittura_eseguita',false,
      'messaggio','Nessuna scrittura. Avviare un nuovo ciclo e ripresentare le chiusure al salvataggio finale.'
    );
  end if;

  if not v_confirm_final then
    return jsonb_build_object(
      'procedura','PR-08',
      'stato','IN_ATTESA_CONFERMA_FINALE',
      'scrittura_eseguita',false,
      'riepilogo',v_ops,
      'conferma_finale_richiesta',true
    );
  end if;

  v_saved := collection.pr_08_chiudi_vendite_batch(v_ops);

  for v_item in select value from jsonb_array_elements(v_ops) loop
    v_id := (v_item->>'codice_vendita_aperta')::bigint;

    if exists (
      select 1 from collection.master_oggetti_in_vendita
      where codice_vendita_aperta=v_id and stato_ciclo_vendita<>'CHIUSO'
    ) then
      raise exception 'PR-08: rilettura post-salvataggio fallita per vendita %: ciclo non chiuso.',v_id;
    end if;

    select jsonb_build_object(
      'codice_vendita_aperta',oiv.codice_vendita_aperta,
      'codice_oggetto',oiv.codice_oggetto,
      'stato_ciclo_vendita',oiv.stato_ciclo_vendita,
      'stato_oggetto',mo.stato,
      'codice_vendita',(
        select mv.codice_vendita
        from collection.master_vendite mv
        where mv.codice_vendita_aperta=oiv.codice_vendita_aperta
        order by mv.codice_vendita desc limit 1
      )
    )
    into v_current
    from collection.master_oggetti_in_vendita oiv
    join collection.master_oggetti mo on mo.codice_oggetto=oiv.codice_oggetto
    where oiv.codice_vendita_aperta=v_id;

    if v_current is null then
      raise exception 'PR-08: rilettura post-salvataggio fallita per vendita %.',v_id;
    end if;

    v_verified := v_verified || jsonb_build_array(v_current);
  end loop;

  return jsonb_build_object(
    'procedura','PR-08',
    'stato','SALVATO_E_VERIFICATO',
    'scrittura_eseguita',true,
    'numero_operazioni',jsonb_array_length(v_ops),
    'risultati',v_saved,
    'rilettura_database',v_verified
  );
end;
$function$

