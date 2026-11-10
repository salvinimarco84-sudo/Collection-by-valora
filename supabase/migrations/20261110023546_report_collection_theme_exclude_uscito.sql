-- Esclude gli oggetti USCITO dal report per franchise/tema.
-- Il filtro è applicato prima della paginazione, quindi vale anche per tutti i risultati esportati.

DO $patch$
DECLARE
  v_definition text;
  v_old text := $old$
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
$old$;
  v_new text := $new$
        where o.stato IS DISTINCT FROM 'USCITO'
          and (
            to_jsonb(o)::text ilike '%' || v_search || '%'
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
          )
        order by o.codice_oggetto limit v_limit offset v_offset
$new$;
BEGIN
  SELECT pg_get_functiondef('collection.runtime_esegui_consultazione(uuid,text,jsonb)'::regprocedure)
    INTO v_definition;

  IF position(v_old in v_definition) = 0 THEN
    IF position(v_new in v_definition) > 0 THEN
      RAISE NOTICE 'Filtro USCITO già presente: nessuna modifica necessaria.';
      RETURN;
    END IF;
    RAISE EXCEPTION 'Blocco SQL originale non trovato: migrazione interrotta.';
  END IF;

  v_definition := replace(v_definition, v_old, v_new);
  EXECUTE v_definition;
END
$patch$;
