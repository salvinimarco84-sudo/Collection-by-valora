-- Include compensating sale-cancellation movements in cash reports and expose net totals.

CREATE OR REPLACE FUNCTION collection.runtime_esegui_report(p_user_id uuid, p_codice text, p_argomenti jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog', 'collection'
AS $function$
declare
  v_code text := upper(btrim(coalesce(p_codice,'')));
  v_args jsonb := coalesce(p_argomenti,'{}'::jsonb);
  v_from date := nullif(v_args->>'data_da','')::date;
  v_to date := nullif(v_args->>'data_a','')::date;
  v_year integer := nullif(v_args->>'anno','')::integer;
  v_month integer := nullif(v_args->>'mese','')::integer;
  v_limit integer := greatest(1,least(coalesce(nullif(v_args->>'limite','')::integer,100),500));
  v_offset integer := greatest(0,coalesce(nullif(v_args->>'offset','')::integer,0));
  v_records jsonb;
  v_count bigint;
  v_total numeric(14,2);
  v_summary jsonb;
begin
  if p_user_id is null or not exists(select 1 from collection.app_authorized_users u where u.user_id=p_user_id and u.attivo=true) then
    raise exception 'Account non autorizzato alla beta TEST.';
  end if;
  if jsonb_typeof(v_args)<>'object' then raise exception 'Gli argomenti del report devono essere un oggetto JSON.'; end if;
  if v_from is not null and v_to is not null and v_from>v_to then raise exception 'data_da non può essere successiva a data_a.'; end if;
  if v_month is not null and (v_month<1 or v_month>12) then raise exception 'mese deve essere compreso tra 1 e 12.'; end if;
  if v_year is not null and (v_year<1000 or v_year>9999) then raise exception 'anno non valido.'; end if;

  case v_code
    when 'SALES_REPORT' then
      select count(*),coalesce(sum(m.importo_vendita),0)
        into v_count,v_total
      from collection.master_vendite m
      where m.stato_vendita='CONCLUSA'
        and (v_from is null or m.data_vendita>=v_from)
        and (v_to is null or m.data_vendita<=v_to)
        and (v_year is null or extract(year from m.data_vendita)=v_year)
        and (v_month is null or extract(month from m.data_vendita)=v_month);
      select coalesce(jsonb_agg(to_jsonb(x) order by x.data_vendita,x.codice_vendita),'[]'::jsonb)
        into v_records
      from (
        select m.* from collection.master_vendite m
        where m.stato_vendita='CONCLUSA'
          and (v_from is null or m.data_vendita>=v_from)
          and (v_to is null or m.data_vendita<=v_to)
          and (v_year is null or extract(year from m.data_vendita)=v_year)
          and (v_month is null or extract(month from m.data_vendita)=v_month)
        order by m.data_vendita,m.codice_vendita limit v_limit offset v_offset
      ) x;
      return jsonb_build_object('codice',v_code,'sola_lettura',true,'totale_venduto',v_total,'numero_vendite',v_count,'limite',v_limit,'offset',v_offset,'record',v_records,'filtri',v_args);

    when 'PURCHASES_REPORT' then
      select count(*),coalesce(sum(m.importo_totale_acquisto),0)
        into v_count,v_total
      from collection.master_acquisti m
      where (v_from is null or m.data_acquisto>=v_from)
        and (v_to is null or m.data_acquisto<=v_to)
        and (v_year is null or extract(year from m.data_acquisto)=v_year)
        and (v_month is null or extract(month from m.data_acquisto)=v_month);
      select coalesce(jsonb_agg(to_jsonb(x) order by x.data_acquisto,x.codice_acquisto),'[]'::jsonb)
        into v_records
      from (
        select m.* from collection.master_acquisti m
        where (v_from is null or m.data_acquisto>=v_from)
          and (v_to is null or m.data_acquisto<=v_to)
          and (v_year is null or extract(year from m.data_acquisto)=v_year)
          and (v_month is null or extract(month from m.data_acquisto)=v_month)
        order by m.data_acquisto,m.codice_acquisto limit v_limit offset v_offset
      ) x;
      return jsonb_build_object('codice',v_code,'sola_lettura',true,'totale_acquisti',v_total,'numero_acquisti',v_count,'limite',v_limit,'offset',v_offset,'record',v_records,'filtri',v_args);

    when 'ACTIVE_LISTINGS_REPORT' then
      select count(*),coalesce(sum(m.prezzo_di_vendita),0)
        into v_count,v_total
      from collection.master_oggetti_in_vendita m
      where m.stato_ciclo_vendita='APERTO'
        and (v_from is null or m.data_inizio_vendita>=v_from)
        and (v_to is null or m.data_inizio_vendita<=v_to)
        and (v_year is null or extract(year from m.data_inizio_vendita)=v_year)
        and (v_month is null or extract(month from m.data_inizio_vendita)=v_month);
      select coalesce(jsonb_agg(
        to_jsonb(x) || jsonb_build_object(
          'destinazione',o.destinazione,
          'condizione',o.condizione,
          'completezza',o.completezza,
          'stato',o.stato,
          'valore_oggetto',o.valore_oggetto,
          'valuta_valore',o.valuta_valore,
          'quantita',o.quantita
        )
        order by x.data_inizio_vendita,x.codice_vendita_aperta
      ),'[]'::jsonb)
        into v_records
      from (
        select m.*
        from collection.master_oggetti_in_vendita m
        where m.stato_ciclo_vendita='APERTO'
          and (v_from is null or m.data_inizio_vendita>=v_from)
          and (v_to is null or m.data_inizio_vendita<=v_to)
          and (v_year is null or extract(year from m.data_inizio_vendita)=v_year)
          and (v_month is null or extract(month from m.data_inizio_vendita)=v_month)
        order by m.data_inizio_vendita,m.codice_vendita_aperta
        limit v_limit offset v_offset
      ) x
      left join collection.master_oggetti o on o.codice_oggetto=x.codice_oggetto;
      return jsonb_build_object('codice',v_code,'sola_lettura',true,'valore_nominale_inserzioni_attive',v_total,'numero_inserzioni_attive',v_count,'limite',v_limit,'offset',v_offset,'record',v_records,'filtri',v_args);

    when 'CASH_MOVEMENTS_REPORT' then
      select count(*),coalesce(sum(c.importo),0)
        into v_count,v_total
      from collection.cassa c
      where c.tipo_movimento in ('ACQUISTO','VENDITA','VENDITA ANNULLATA')
        and (v_from is null or c.data>=v_from)
        and (v_to is null or c.data<=v_to)
        and (v_year is null or extract(year from c.data)=v_year)
        and (v_month is null or extract(month from c.data)=v_month);
      select coalesce(jsonb_agg(to_jsonb(x) order by x.data,x.codice_movimento),'[]'::jsonb)
        into v_records
      from (
        select c.* from collection.cassa c
        where c.tipo_movimento in ('ACQUISTO','VENDITA','VENDITA ANNULLATA')
          and (v_from is null or c.data>=v_from)
          and (v_to is null or c.data<=v_to)
          and (v_year is null or extract(year from c.data)=v_year)
          and (v_month is null or extract(month from c.data)=v_month)
        order by c.data,c.codice_movimento limit v_limit offset v_offset
      ) x;
      select coalesce(jsonb_agg(to_jsonb(s)),'[]'::jsonb) into v_summary
      from (
        select c.tipo_movimento,count(*) as numero_movimenti,coalesce(sum(c.importo),0) as totale_importi
        from collection.cassa c
        where c.tipo_movimento in ('ACQUISTO','VENDITA','VENDITA ANNULLATA')
          and (v_from is null or c.data>=v_from)
          and (v_to is null or c.data<=v_to)
          and (v_year is null or extract(year from c.data)=v_year)
          and (v_month is null or extract(month from c.data)=v_month)
        group by c.tipo_movimento order by c.tipo_movimento
      ) s;
      return jsonb_build_object(
        'codice',v_code,'sola_lettura',true,
        'somma_importi_movimenti',v_total,'numero_movimenti',v_count,
        'entrate_vendite',(select coalesce(sum(c.importo),0) from collection.cassa c where c.tipo_movimento='VENDITA' and (v_from is null or c.data>=v_from) and (v_to is null or c.data<=v_to) and (v_year is null or extract(year from c.data)=v_year) and (v_month is null or extract(month from c.data)=v_month)),
        'uscite_vendite_annullate',(select coalesce(sum(c.importo),0) from collection.cassa c where c.tipo_movimento='VENDITA ANNULLATA' and c.tipologia='USCITA' and (v_from is null or c.data>=v_from) and (v_to is null or c.data<=v_to) and (v_year is null or extract(year from c.data)=v_year) and (v_month is null or extract(month from c.data)=v_month)),
        'saldo_vendite',(select coalesce(sum(case when c.tipologia='ENTRATA' then c.importo when c.tipologia='USCITA' then -c.importo else 0 end),0) from collection.cassa c where c.tipo_movimento in ('VENDITA','VENDITA ANNULLATA') and (v_from is null or c.data>=v_from) and (v_to is null or c.data<=v_to) and (v_year is null or extract(year from c.data)=v_year) and (v_month is null or extract(month from c.data)=v_month)),
        'totale_entrate',(select coalesce(sum(c.importo),0) from collection.cassa c where c.tipologia='ENTRATA' and c.tipo_movimento in ('ACQUISTO','VENDITA','VENDITA ANNULLATA') and (v_from is null or c.data>=v_from) and (v_to is null or c.data<=v_to) and (v_year is null or extract(year from c.data)=v_year) and (v_month is null or extract(month from c.data)=v_month)),
        'totale_uscite',(select coalesce(sum(c.importo),0) from collection.cassa c where c.tipologia='USCITA' and c.tipo_movimento in ('ACQUISTO','VENDITA','VENDITA ANNULLATA') and (v_from is null or c.data>=v_from) and (v_to is null or c.data<=v_to) and (v_year is null or extract(year from c.data)=v_year) and (v_month is null or extract(month from c.data)=v_month)),
        'saldo_netto',(select coalesce(sum(case when c.tipologia='ENTRATA' then c.importo when c.tipologia='USCITA' then -c.importo else 0 end),0) from collection.cassa c where c.tipo_movimento in ('ACQUISTO','VENDITA','VENDITA ANNULLATA') and (v_from is null or c.data>=v_from) and (v_to is null or c.data<=v_to) and (v_year is null or extract(year from c.data)=v_year) and (v_month is null or extract(month from c.data)=v_month)),
        'uscite_acquisti',(select coalesce(sum(c.importo),0) from collection.cassa c where c.tipo_movimento='ACQUISTO' and (v_from is null or c.data>=v_from) and (v_to is null or c.data<=v_to) and (v_year is null or extract(year from c.data)=v_year) and (v_month is null or extract(month from c.data)=v_month)),
        'riepilogo_per_tipo',v_summary,'limite',v_limit,'offset',v_offset,'record',v_records,'filtri',v_args);

    when 'INVENTORY_SUMMARY_REPORT' then
      select count(*),coalesce(sum(coalesce(m.valore_oggetto,0)*m.quantita),0)
        into v_count,v_total
      from collection.master_oggetti m
      where (v_args->>'destinazione' is null or m.destinazione=v_args->>'destinazione')
        and (v_args->>'stato' is null or m.stato=v_args->>'stato');
      select coalesce(jsonb_agg(to_jsonb(s)),'[]'::jsonb) into v_summary
      from (
        select m.stato,m.destinazione,count(*) as numero_record,coalesce(sum(m.quantita),0) as quantita_totale,
          coalesce(sum(coalesce(m.valore_oggetto,0)*m.quantita),0) as valore_storico
        from collection.master_oggetti m
        where (v_args->>'destinazione' is null or m.destinazione=v_args->>'destinazione')
          and (v_args->>'stato' is null or m.stato=v_args->>'stato')
        group by m.stato,m.destinazione order by m.stato,m.destinazione
      ) s;
      select coalesce(jsonb_agg(to_jsonb(x) order by x.codice_oggetto),'[]'::jsonb) into v_records
      from (select m.* from collection.master_oggetti m
        where (v_args->>'destinazione' is null or m.destinazione=v_args->>'destinazione')
          and (v_args->>'stato' is null or m.stato=v_args->>'stato')
        order by m.codice_oggetto limit v_limit offset v_offset) x;
      return jsonb_build_object('codice',v_code,'sola_lettura',true,'numero_record',v_count,'valore_storico_oggetti',v_total,'riepilogo',v_summary,'limite',v_limit,'offset',v_offset,'record',v_records,'filtri',v_args);

    when 'HISTORY_REPORT' then
      select count(*) into v_count from collection.storico s
      where (v_from is null or s.data_evento>=v_from)
        and (v_to is null or s.data_evento<=v_to)
        and (v_year is null or extract(year from s.data_evento)=v_year)
        and (v_month is null or extract(month from s.data_evento)=v_month);
      select coalesce(jsonb_agg(to_jsonb(x) order by x.data_evento,x.codice_storico),'[]'::jsonb) into v_records
      from (select s.* from collection.storico s
        where (v_from is null or s.data_evento>=v_from)
          and (v_to is null or s.data_evento<=v_to)
          and (v_year is null or extract(year from s.data_evento)=v_year)
          and (v_month is null or extract(month from s.data_evento)=v_month)
        order by s.data_evento,s.codice_storico limit v_limit offset v_offset) x;
      return jsonb_build_object('codice',v_code,'sola_lettura',true,'numero_eventi',v_count,'limite',v_limit,'offset',v_offset,'record',v_records,'filtri',v_args);

    else
      raise exception 'Report non autorizzato o non implementato: %',v_code;
  end case;
end;
$function$
;
