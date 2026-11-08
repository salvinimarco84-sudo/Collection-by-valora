-- PR-09: elenco vendite concluse, storno contabile e ripristino destinazione.

CREATE OR REPLACE FUNCTION collection.pr_09_elenca_vendite_concluse(p_cerca text DEFAULT NULL::text, p_limite integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'collection', 'pg_temp'
AS $function$
DECLARE
  v_search text := nullif(btrim(coalesce(p_cerca, '')), '');
  v_limit integer := greatest(1, least(coalesce(p_limite, 50), 500));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
  v_result jsonb;
BEGIN
  SELECT coalesce(jsonb_agg(to_jsonb(page_rows)), '[]'::jsonb)
    INTO v_result
  FROM (
    SELECT
      mv.codice_vendita,
      mv.codice_oggetto,
      mv.descrizione_oggetto,
      mv.data_vendita,
      mv.importo_vendita,
      mv.valuta,
      mv.codice_piattaforma,
      p.nome_piattaforma,
      mv.canale_effettivo,
      mv.codice_vendita_aperta,
      mv.stato_vendita,
      mv.note,
      mv.codice_lotto,
      mo.destinazione,
      mo.stato AS stato_oggetto
    FROM collection.master_vendite mv
    JOIN collection.master_oggetti mo
      ON mo.codice_oggetto = mv.codice_oggetto
    LEFT JOIN collection.piattaforme p
      ON p.codice_piattaforma = mv.codice_piattaforma
    WHERE mv.stato_vendita = 'CONCLUSA'
      AND (
        v_search IS NULL
        OR mv.codice_vendita::text ILIKE '%' || v_search || '%'
        OR mv.codice_oggetto::text ILIKE '%' || v_search || '%'
        OR mv.descrizione_oggetto ILIKE '%' || v_search || '%'
      )
    ORDER BY mv.data_vendita DESC, mv.codice_vendita DESC
    LIMIT v_limit OFFSET v_offset
  ) AS page_rows;
  RETURN coalesce(v_result, '[]'::jsonb);
END;
$function$
;

CREATE OR REPLACE FUNCTION collection.pr_annulla_vendita(p_codice_vendita bigint, p_rimetti_in_vendita boolean)
 RETURNS TABLE(codice_vendita bigint, codice_oggetto bigint, stato_vendita character varying, stato_oggetto character varying, codice_nuova_vendita_aperta bigint, rimessa_in_vendita boolean)
 LANGUAGE plpgsql
 SET search_path TO 'collection', 'pg_temp'
AS $function$
DECLARE
    v_codice_oggetto BIGINT;
    v_codice_ciclo BIGINT;
    v_descrizione TEXT;
    v_data_vendita DATE;
    v_importo NUMERIC(14,2);
    v_valuta CHAR(3);
    v_codice_piattaforma BIGINT;
    v_canale TEXT;
    v_note_vendita TEXT;
    v_stato_vendita VARCHAR(12);
    v_stato_oggetto VARCHAR(20);
    v_destinazione VARCHAR(20);
    v_data_inizio DATE;
    v_prezzo NUMERIC(14,2);
    v_note_ciclo TEXT;
    v_nuovo_ciclo BIGINT;
    v_piattaforma BIGINT;
BEGIN
    IF p_codice_vendita IS NULL OR p_codice_vendita <= 0 THEN
        RAISE EXCEPTION 'PR-08: codice vendita obbligatorio e valido.';
    END IF;

    IF p_rimetti_in_vendita IS NULL THEN
        RAISE EXCEPTION 'PR-08: indicare se rimettere l''oggetto in vendita.';
    END IF;

    SELECT mv.codice_oggetto, mv.codice_vendita_aperta,
           mv.descrizione_oggetto, mv.data_vendita, mv.importo_vendita,
           mv.valuta, mv.codice_piattaforma, mv.canale_effettivo,
           mv.note, mv.stato_vendita
      INTO v_codice_oggetto, v_codice_ciclo, v_descrizione,
           v_data_vendita, v_importo, v_valuta, v_codice_piattaforma,
           v_canale, v_note_vendita, v_stato_vendita
      FROM collection.master_vendite mv
     WHERE mv.codice_vendita = p_codice_vendita
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-08: vendita % inesistente.', p_codice_vendita;
    END IF;

    IF v_stato_vendita <> 'CONCLUSA' THEN
        RAISE EXCEPTION 'PR-08: la vendita % non è CONCLUSA oppure è già stata annullata.', p_codice_vendita;
    END IF;

    SELECT mo.stato, mo.destinazione
      INTO v_stato_oggetto, v_destinazione
      FROM collection.master_oggetti mo
     WHERE mo.codice_oggetto = v_codice_oggetto
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-08: oggetto % inesistente.', v_codice_oggetto;
    END IF;

    IF v_stato_oggetto <> 'VENDUTO' THEN
        RAISE EXCEPTION 'PR-08: l''oggetto % non risulta VENDUTO; annullamento bloccato.', v_codice_oggetto;
    END IF;

    -- La vendita effettiva deve avere un solo incasso compensabile.
    PERFORM 1
      FROM collection.cassa AS c
     WHERE c.codice_vendita = p_codice_vendita
       AND c.tipo_movimento = 'VENDITA'
       AND c.tipologia = 'ENTRATA'
       AND c.importo = v_importo
       AND c.valuta = v_valuta
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-08: movimento d''incasso coerente non trovato per la vendita %.', p_codice_vendita;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM collection.cassa AS c
         WHERE c.codice_vendita = p_codice_vendita
           AND c.tipo_movimento = 'VENDITA ANNULLATA'
    ) THEN
        RAISE EXCEPTION 'PR-08: esiste già un movimento compensativo per la vendita %.', p_codice_vendita;
    END IF;

    SELECT oiv.data_inizio_vendita, oiv.prezzo_di_vendita, oiv.note
      INTO v_data_inizio, v_prezzo, v_note_ciclo
      FROM collection.master_oggetti_in_vendita AS oiv
     WHERE oiv.codice_vendita_aperta = v_codice_ciclo
       AND oiv.codice_oggetto = v_codice_oggetto
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PR-08: ciclo originario di vendita non trovato.';
    END IF;

    IF p_rimetti_in_vendita THEN
        IF v_prezzo IS NULL OR v_prezzo <= 0 THEN
            RAISE EXCEPTION 'PR-08: prezzo del ciclo originario non valido.';
        END IF;
        IF NOT EXISTS (
            SELECT 1
              FROM collection.oggetti_in_vendita_piattaforme AS op
             WHERE op.codice_vendita_aperta = v_codice_ciclo
        ) THEN
            RAISE EXCEPTION 'PR-08: nessuna piattaforma associata al ciclo originario; impossibile ricreare la vendita senza conferma dei nuovi dati.';
        END IF;
    END IF;

    -- Aggiorna lo stato logico della vendita, senza cancellarla.
    UPDATE collection.master_vendite AS mv
       SET stato_vendita = 'ANNULLATA'
     WHERE mv.codice_vendita = p_codice_vendita;

    INSERT INTO collection.cassa
        (data, descrizione, tipo_movimento, importo, valuta, tipologia,
         codice_piattaforma, codice_vendita)
    VALUES
        (CURRENT_DATE,
         'Annullamento vendita ' || p_codice_vendita || ' - oggetto ' || v_codice_oggetto,
         'VENDITA ANNULLATA', v_importo, v_valuta, 'USCITA',
         v_codice_piattaforma, p_codice_vendita);

    INSERT INTO collection.storico
        (data_evento, codice_oggetto, codice_vendita, codice_vendita_aperta,
         tipo_evento, origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
    VALUES
        (CURRENT_DATE, v_codice_oggetto, p_codice_vendita, v_codice_ciclo,
         'ANNULLAMENTO', 'ANNULLA VENDITA', 'stato_vendita', 'CONCLUSA', 'ANNULLATA',
         'Vendita annullata; incasso compensato in cassa');

    IF p_rimetti_in_vendita THEN
        -- Il ciclo originario è già CHIUSO dalla PR-07; resta immutato.

        INSERT INTO collection.master_oggetti_in_vendita
            (codice_oggetto, descrizione_oggetto, data_inizio_vendita,
             prezzo_di_vendita, valuta, note, stato_ciclo_vendita)
        VALUES
            (v_codice_oggetto, v_descrizione, CURRENT_DATE,
             v_prezzo, v_valuta, v_note_ciclo, 'APERTO')
        RETURNING master_oggetti_in_vendita.codice_vendita_aperta
             INTO v_nuovo_ciclo;

        FOR v_piattaforma IN
            SELECT codice_piattaforma
              FROM collection.oggetti_in_vendita_piattaforme
             WHERE codice_vendita_aperta = v_codice_ciclo
             ORDER BY codice_piattaforma
        LOOP
            INSERT INTO collection.oggetti_in_vendita_piattaforme
                (codice_vendita_aperta, codice_oggetto, descrizione_oggetto, codice_piattaforma)
            VALUES
                (v_nuovo_ciclo, v_codice_oggetto, v_descrizione, v_piattaforma);
        END LOOP;

        UPDATE collection.master_oggetti AS mo
           SET stato = 'IN VENDITA',
               destinazione = 'RIVENDITA'
         WHERE mo.codice_oggetto = v_codice_oggetto;

        INSERT INTO collection.storico
            (data_evento, codice_oggetto, codice_vendita_aperta,
             tipo_evento, origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
        VALUES
            (CURRENT_DATE, v_codice_oggetto, v_nuovo_ciclo,
             'APERTURA_VENDITA', 'ANNULLA VENDITA', 'stato_ciclo_vendita', NULL, 'APERTO',
             'Nuovo ciclo aperto dopo annullamento; dati di vendita ripresi dal ciclo originario'),
            (CURRENT_DATE, v_codice_oggetto, v_nuovo_ciclo,
             'CAMBIO_STATO', 'ANNULLA VENDITA', 'stato', 'VENDUTO', 'IN VENDITA',
             'Oggetto rimesso in vendita dopo annullamento');
        IF v_destinazione IS DISTINCT FROM 'RIVENDITA' THEN
            INSERT INTO collection.storico
                (data_evento, codice_oggetto, codice_vendita_aperta, tipo_evento,
                 origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
            VALUES
                (CURRENT_DATE, v_codice_oggetto, v_nuovo_ciclo, 'CAMBIO_DESTINAZIONE',
                 'ANNULLA VENDITA', 'destinazione', v_destinazione, 'RIVENDITA',
                 'Destinazione aggiornata dopo annullamento con rimessa in vendita');
        END IF;
        v_stato_oggetto := 'IN VENDITA';
    ELSE
        UPDATE collection.master_oggetti AS mo
           SET stato = 'DISPONIBILE',
               destinazione = 'COLLEZIONE'
         WHERE mo.codice_oggetto = v_codice_oggetto;

        INSERT INTO collection.storico
            (data_evento, codice_oggetto, codice_vendita_aperta,
             tipo_evento, origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
        VALUES
            (CURRENT_DATE, v_codice_oggetto, v_codice_ciclo,
             'CAMBIO_STATO', 'ANNULLA VENDITA', 'stato', 'VENDUTO', 'DISPONIBILE',
             'Oggetto reso disponibile dopo annullamento della vendita');
        IF v_destinazione IS DISTINCT FROM 'COLLEZIONE' THEN
            INSERT INTO collection.storico
                (data_evento, codice_oggetto, codice_vendita_aperta, tipo_evento,
                 origine_evento, campo_modificato, valore_precedente, valore_nuovo, note)
            VALUES
                (CURRENT_DATE, v_codice_oggetto, v_codice_ciclo, 'CAMBIO_DESTINAZIONE',
                 'ANNULLA VENDITA', 'destinazione', v_destinazione, 'COLLEZIONE',
                 'Destinazione aggiornata dopo annullamento e ritorno in collezione');
        END IF;
        v_stato_oggetto := 'DISPONIBILE';
        v_nuovo_ciclo := NULL;
    END IF;

    codice_vendita := p_codice_vendita;
    codice_oggetto := v_codice_oggetto;
    stato_vendita := 'ANNULLATA';
    stato_oggetto := v_stato_oggetto;
    codice_nuova_vendita_aperta := v_nuovo_ciclo;
    rimessa_in_vendita := p_rimetti_in_vendita;
    RETURN NEXT;
END;
$function$
;

CREATE OR REPLACE FUNCTION collection.pr_09_annulla_vendita(p_operazioni jsonb)
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
  v_confirm_data boolean := false;
  v_confirm_final boolean := false;
  v_other boolean := false;
  v_current jsonb;
begin
  if p_operazioni is null or jsonb_typeof(p_operazioni)<>'object' then
    raise exception 'PR-09: il payload deve essere un oggetto JSON.';
  end if;

  v_payload:=p_operazioni;
  v_confirm_data:=coalesce((v_payload->>'dati_confermati')::boolean,false);
  v_confirm_final:=coalesce((v_payload->>'conferma_finale')::boolean,false);
  v_other:=coalesce((v_payload->>'altra_operazione')::boolean,false);

  v_ops:=case
    when v_payload ? 'operazioni' then v_payload->'operazioni'
    when v_payload ? 'codice_vendita' then
      jsonb_build_array(v_payload-'dati_confermati'-'conferma_finale'-'altra_operazione')
    else null
  end;

  if jsonb_typeof(v_ops)<>'array' or jsonb_array_length(v_ops)=0 then
    raise exception 'PR-09: selezionare almeno una vendita.';
  end if;

  for v_item in select value from jsonb_array_elements(v_ops) loop
    if jsonb_typeof(v_item)<>'object'
       or nullif(v_item->>'codice_vendita','') is null
       or nullif(v_item->>'rimetti_in_vendita','') is null then
      raise exception 'PR-09: ogni annullamento richiede codice_vendita e rimetti_in_vendita.';
    end if;

    if exists(select 1 from jsonb_object_keys(v_item) k
              where k not in ('codice_vendita','rimetti_in_vendita')) then
      raise exception 'PR-09: campo non previsto nel payload.';
    end if;

    v_id:=(v_item->>'codice_vendita')::bigint;

    if exists(select 1 from collection.master_vendite
              where codice_vendita=v_id and stato_vendita='CONCLUSA') is false then
      raise exception 'PR-09: vendita % inesistente o non CONCLUSA.',v_id;
    end if;
  end loop;

  if not v_confirm_data then
    for v_item in select value from jsonb_array_elements(v_ops) loop
      v_id:=(v_item->>'codice_vendita')::bigint;
      select jsonb_build_object(
        'codice_vendita',mv.codice_vendita,
        'codice_oggetto',mv.codice_oggetto,
        'descrizione_oggetto',mv.descrizione_oggetto,
        'data_vendita',mv.data_vendita,
        'importo_vendita',mv.importo_vendita,
        'stato_vendita',mv.stato_vendita,
        'rimetti_in_vendita',((v_item->>'rimetti_in_vendita')::boolean)
      ) into v_current
      from collection.master_vendite mv
      where mv.codice_vendita=v_id;
      v_preview:=v_preview||jsonb_build_array(v_current);
    end loop;

    return jsonb_build_object('procedura','PR-09','stato','BOZZA',
      'scrittura_eseguita',false,'numero_operazioni',jsonb_array_length(v_ops),
      'riepilogo',v_preview,'conferma_dati_richiesta',true,
      'altra_operazione_richiesta',true,'conferma_finale_richiesta',true);
  end if;

  if v_other then
    return jsonb_build_object('procedura','PR-09','stato','BOZZA_DA_CONTINUARE',
      'scrittura_eseguita',false,
      'messaggio','Nessuna scrittura. Avviare un nuovo ciclo e ripresentare gli annullamenti al salvataggio finale.');
  end if;

  if not v_confirm_final then
    return jsonb_build_object('procedura','PR-09','stato','IN_ATTESA_CONFERMA_FINALE',
      'scrittura_eseguita',false,'riepilogo',v_ops,'conferma_finale_richiesta',true);
  end if;

  v_saved:=collection.pr_annulla_vendita(v_ops);

  for v_item in select value from jsonb_array_elements(v_ops) loop
    v_id:=(v_item->>'codice_vendita')::bigint;

    select jsonb_build_object(
      'codice_vendita',mv.codice_vendita,
      'codice_oggetto',mv.codice_oggetto,
      'stato_vendita',mv.stato_vendita,
      'stato_oggetto',mo.stato,
      'destinazione_oggetto',mo.destinazione,
      'codice_nuova_vendita_aperta',(
        select max(oiv.codice_vendita_aperta)
        from collection.master_oggetti_in_vendita oiv
        where oiv.codice_oggetto=mv.codice_oggetto
          and oiv.stato_ciclo_vendita='APERTO'
          and oiv.codice_vendita_aperta<>mv.codice_vendita_aperta
      )
    ) into v_current
    from collection.master_vendite mv
    join collection.master_oggetti mo on mo.codice_oggetto=mv.codice_oggetto
    where mv.codice_vendita=v_id;

    if v_current is null or v_current->>'stato_vendita'<>'ANNULLATA' then
      raise exception 'PR-09: rilettura post-salvataggio fallita per vendita %.',v_id;
    end if;

    if ((v_item->>'rimetti_in_vendita')::boolean)
       and ((v_current->>'stato_oggetto')<>'IN VENDITA'
         or (v_current->>'destinazione_oggetto')<>'RIVENDITA') then
      raise exception 'PR-09: verifica rimessa in vendita fallita per vendita %.',v_id;
    end if;

    if not ((v_item->>'rimetti_in_vendita')::boolean)
       and ((v_current->>'stato_oggetto')<>'DISPONIBILE'
         or (v_current->>'destinazione_oggetto')<>'COLLEZIONE') then
      raise exception 'PR-09: verifica disponibilità fallita per vendita %.',v_id;
    end if;

    v_verified:=v_verified||jsonb_build_array(v_current);
  end loop;

  return jsonb_build_object('procedura','PR-09','stato','SALVATO_E_VERIFICATO',
    'scrittura_eseguita',true,'numero_operazioni',jsonb_array_length(v_ops),
    'risultati',v_saved,'rilettura_database',v_verified);
end;
$function$
;

CREATE OR REPLACE FUNCTION collection.runtime_esegui_consultazione(p_user_id uuid, p_codice text, p_argomenti jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'collection'
AS $function$
declare
  v_code text := upper(btrim(coalesce(p_codice,'')));
  v_args jsonb := coalesce(p_argomenti,'{}'::jsonb);
  v_result jsonb;
  v_id bigint;
  v_search text;
  v_limit integer;
  v_offset integer;
  v_table text;
  v_field text;
begin
  if p_user_id is null or not exists (
    select 1 from collection.app_authorized_users u
    where u.user_id=p_user_id and u.attivo=true
  ) then
    raise exception 'Account non autorizzato alla beta TEST.';
  end if;
  if jsonb_typeof(v_args)<>'object' then
    raise exception 'Gli argomenti devono essere un oggetto JSON.';
  end if;
  v_search := nullif(btrim(coalesce(v_args->>'cerca', v_args->>'testo', '')),'');
  v_limit := greatest(1,least(coalesce(nullif(v_args->>'limite','')::integer,100),500));
  v_offset := greatest(0,coalesce(nullif(v_args->>'offset','')::integer,0));
  v_id := nullif(v_args->>'codice_oggetto','')::bigint;
  v_table := nullif(btrim(v_args->>'tabella'),'');
  v_field := nullif(btrim(v_args->>'campo'),'');
  case v_code
    when 'COMMAND_RESOLVE' then
      select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_result
      from collection.risolvi_comando(coalesce(v_args->>'testo','')) x;
    when 'COMMAND_RESOLVE_CONTEXTUAL' then
      v_result := collection.risolvi_comando_contestuale(coalesce(v_args->>'testo',''));
    when 'COMMAND_RESOLVE_TEXT' then
      v_result := collection.risolvi_comando_testo(coalesce(v_args->>'testo',''));
    when 'OBJECTS_EDITABLE' then
      select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_result
      from collection.pr_02_elenca_schede_modificabili(v_search,v_limit,v_offset) x;
    when 'OBJECTS_AVAILABLE' then
      select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_result
      from collection.pr_02_catalogo_disponibili(v_search,v_limit,v_offset) x;
    when 'OBJECT_MASTER' then
      if v_id is null then raise exception 'codice_oggetto obbligatorio.'; end if;
      select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_result
      from collection.pr_02_scheda_master_completa(v_id) x;
    when 'OBJECTS_SELLABLE' then
      select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_result
      from (select * from collection.pr_06_elenco_oggetti_vendibili() limit v_limit offset v_offset) x;
    when 'COMPLETED_SALES' then
      v_result := collection.pr_09_elenca_vendite_concluse(v_search, v_limit, v_offset);
    when 'OBJECT_SALE_SHEET' then
      if v_id is null then raise exception 'codice_oggetto obbligatorio.'; end if;
      v_result := collection.pr_06_scheda_oggetto(v_id);
    when 'TABLE_STRUCTURE' then
      select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_result
      from collection.pr_mostra_struttura(v_table) x;
    when 'TABLE_VALUES' then
      if v_table is null or v_field is null then raise exception 'tabella e campo sono obbligatori.'; end if;
      if v_table not in ('master_oggetti','master_acquisti','acquisti_oggetti','master_oggetti_in_vendita','oggetti_in_vendita_piattaforme','master_vendite','storico','cassa','piattaforme','mercati') then
        raise exception 'Tabella non autorizzata per la consultazione valori.';
      end if;
      select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v_result
      from collection.pr_mostra_valori(v_table,v_field) x;
    when 'EXPLORE_RECORDS' then
      if v_table not in ('master_oggetti','master_acquisti','acquisti_oggetti','master_oggetti_in_vendita','oggetti_in_vendita_piattaforme','master_vendite','storico','cassa','piattaforme','mercati') then
        raise exception 'Tabella non autorizzata per esplorazione record.';
      end if;
      select coalesce(jsonb_agg(x.r),'[]'::jsonb) into v_result
      from (select r as r from collection.pr_esplora_record(v_table,v_limit,v_offset) r) x;
    when 'MARKET_VALUATION_PREPARE' then
      if v_id is null then raise exception 'codice_oggetto obbligatorio.'; end if;
      v_result := collection.pr_valuta_prepara_richiesta(v_id,coalesce(v_args->>'mercato_riferimento','ITALIA'));
    when 'SEARCH_SOURCES' then
      v_result := collection.pr_fonti_ricerca_rilevanti(coalesce(v_args->>'motore','METADATI'),v_args->>'produttore',v_args->>'linea',v_args->>'famiglia',v_args->>'mercato');
    when 'FRANCHISE_SOURCES' then
      v_result := collection.pr_fonti_franchise_rilevanti(coalesce(v_args->>'testo',''));
    when 'REPORT-COLLECTION-THEME' then
      if v_search is null or length(v_search)<1 then raise exception 'Inserisci un franchise o tema da cercare.'; end if;
      select coalesce(jsonb_agg(to_jsonb(rows_page)),'[]'::jsonb) into v_result
      from (
        select o.*,
          coalesce(nullif(btrim(mm.url_immagine),''), nullif(btrim(img.riferimento_immagine),'')) as url_immagine,
          coalesce(nullif(btrim(mm.url_fonte),''), nullif(btrim(img.url_fonte),'')) as url_fonte
        from collection.master_oggetti o
        left join collection.master_metadati mm on mm.codice_oggetto=o.codice_oggetto
        left join lateral (
          select io.riferimento_immagine, io.url_fonte
          from collection.immagini_oggetto io
          where io.codice_oggetto=o.codice_oggetto
            and nullif(btrim(io.riferimento_immagine),'') is not null
          order by io.immagine_principale desc nulls last,
                   io.confermata_il desc nulls last,
                   io.data_registrazione desc nulls last,
                   io.codice_immagine desc
          limit 1
        ) img on true
        where to_jsonb(o)::text ilike '%' || v_search || '%'
          or exists (
            select 1 from collection.metadati_specifici_oggetto m
            where m.codice_oggetto=o.codice_oggetto
              and (to_jsonb(m)::text ilike '%' || v_search || '%'
                or coalesce(m.valori::text,'') ilike '%' || v_search || '%'
                or coalesce(m.fonti_campi::text,'') ilike '%' || v_search || '%')
          )
          or exists (
            select 1 from collection.master_metadati mm_search
            where mm_search.codice_oggetto=o.codice_oggetto and to_jsonb(mm_search)::text ilike '%' || v_search || '%'
          )
        order by o.codice_oggetto limit v_limit offset v_offset
      ) as rows_page;
    when 'REPORT-ACTIVE-LISTINGS' then
      v_result := collection.runtime_esegui_report(p_user_id,'ACTIVE_LISTINGS_REPORT',v_args);
    when 'REPORT-CASH' then
      v_result := collection.runtime_esegui_report(p_user_id,'CASH_MOVEMENTS_REPORT',v_args);
    when 'REPORT-PURCHASES' then
      v_result := collection.runtime_esegui_report(p_user_id,'PURCHASES_REPORT',v_args);
    when 'REPORT-SALES' then
      v_result := collection.runtime_esegui_report(p_user_id,'SALES_REPORT',v_args);
    else
      raise exception 'Consultazione non autorizzata o non implementata: %',v_code;
  end case;
  return jsonb_build_object('codice',v_code,'sola_lettura',true,'risultato',coalesce(v_result,'null'::jsonb),'eseguito_il',now());
end;
$function$
;

REVOKE ALL ON FUNCTION collection.pr_09_elenca_vendite_concluse(text, integer, integer) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION collection.pr_09_elenca_vendite_concluse(text, integer, integer) TO service_role;
