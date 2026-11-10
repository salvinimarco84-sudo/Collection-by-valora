create table if not exists collection.pr04_valora_requests (
  request_id uuid primary key,
  user_id uuid not null,
  result jsonb,
  created_at timestamptz not null default now()
);
alter table collection.pr04_valora_requests enable row level security;
revoke all on collection.pr04_valora_requests from public, anon, authenticated;
grant select, insert, update on collection.pr04_valora_requests to service_role;

CREATE OR REPLACE FUNCTION collection.pr_04_valora_nuovo_acquisto(p_request_id uuid, p_user_id uuid, p_payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'collection', 'pg_temp'
AS $function$
declare
  v_existing jsonb;
  v_acquisto_id bigint;
  v_oggetto_id bigint;
  v_data date;
  v_total numeric(14,2);
  v_cost numeric(14,2);
  v_currency_input text;
  v_currency char(3);
  v_description text;
  v_condition text;
  v_completeness text;
  v_destination text;
  v_note text;
  v_category text;
  v_producer text;
  v_year smallint;
  v_product_code text;
  v_source_url text;
  v_image_url text;
  v_result jsonb;
  v_cash numeric(14,2);
  v_linked numeric(14,2);
begin
  if p_request_id is null or p_user_id is null then
    raise exception 'PR-04 VALORA: identificativo richiesta o utente mancante.';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_request_id::text, 0));

  select result into v_existing from collection.pr04_valora_requests
  where request_id=p_request_id and user_id=p_user_id;
  if found then
    if v_existing is null then
      raise exception 'PR-04 VALORA: richiesta già in elaborazione; attendere e verificare prima di riprovare.';
    end if;
    return v_existing || jsonb_build_object('idempotente',true);
  end if;

  if not exists(select 1 from collection.app_authorized_users where user_id=p_user_id and attivo=true) then
    raise exception 'PR-04 VALORA: utente non autorizzato.';
  end if;
  if p_payload is null or jsonb_typeof(p_payload)<>'object'
     or jsonb_typeof(p_payload->'oggetto')<>'object' then
    raise exception 'PR-04 VALORA: payload acquisto non valido.';
  end if;
  if coalesce((p_payload->>'conferma_finale')::boolean,false) is not true then
    raise exception 'PR-04 VALORA: conferma finale obbligatoria.';
  end if;

  insert into collection.pr04_valora_requests(request_id,user_id) values(p_request_id,p_user_id);

  v_data := nullif(btrim(p_payload->>'data_acquisto'),'')::date;
  v_total := nullif(btrim(p_payload->>'importo_totale'),'')::numeric(14,2);
  v_currency_input := upper(coalesce(nullif(btrim(p_payload->>'valuta'),''),'EUR'));
  v_currency := v_currency_input::char(3);
  v_description := nullif(btrim(p_payload->>'descrizione'),'');
  v_condition := nullif(btrim(p_payload->'oggetto'->>'condizione'),'');
  v_completeness := nullif(btrim(p_payload->'oggetto'->>'completezza'),'');
  v_destination := nullif(btrim(p_payload->'oggetto'->>'destinazione'),'');
  v_note := nullif(btrim(p_payload->'oggetto'->>'note'),'');
  v_cost := nullif(btrim(p_payload->'oggetto'->>'valore_acquisto'),'')::numeric(14,2);
  v_category := nullif(btrim(p_payload->'oggetto'->>'codice_categoria_collezione'),'');
  v_producer := nullif(btrim(p_payload->'oggetto'->>'produttore'),'');
  v_year := nullif(btrim(p_payload->'oggetto'->>'anno_uscita'),'')::smallint;
  v_product_code := nullif(btrim(p_payload->'oggetto'->>'codice_prodotto'),'');
  v_source_url := nullif(btrim(p_payload->'oggetto'->>'fonte_dati_prodotto'),'');
  v_image_url := nullif(btrim(p_payload->'oggetto'->>'url_immagine_catalogo'),'');

  if v_data is null or v_total is null or v_total<=0 or v_cost is null or v_cost<=0 or v_total<>v_cost then
    raise exception 'PR-04 VALORA: data e costo effettivo obbligatori; il totale deve coincidere con il costo dell’oggetto.';
  end if;
  if v_currency_input !~ '^[A-Z]{3}$' then raise exception 'PR-04 VALORA: valuta non valida.'; end if;
  if v_description is null or length(v_description)<2 then raise exception 'PR-04 VALORA: descrizione oggetto obbligatoria.'; end if;
  if v_condition is null or v_condition not in ('NUOVO','COME NUOVO','OTTIMO','BUONO','DISCRETO','USATO','USATO CON SEGNI','DA RESTAURARE','DANNEGGIATO') then
    raise exception 'PR-04 VALORA: condizione non valida.';
  end if;
  if v_completeness is null or v_completeness not in ('SIGILLATO','COMPLETO','INCOMPLETO') then
    raise exception 'PR-04 VALORA: completezza non valida.';
  end if;
  if v_destination is null or v_destination not in ('COLLEZIONE','RIVENDITA','ALTRO') then
    raise exception 'PR-04 VALORA: destinazione non valida.';
  end if;
  if v_destination='COLLEZIONE' then
    if v_category is null or not exists(
      select 1 from collection.master_categorie_collezione
      where codice_categoria=v_category and visibile=true
    ) then raise exception 'PR-04 VALORA: seleziona una categoria collezione valida.'; end if;
  elsif v_category is not null then
    raise exception 'PR-04 VALORA: categoria collezione non ammessa per questa destinazione.';
  end if;
  if v_source_url is not null and v_source_url !~* '^https?://' then raise exception 'PR-04 VALORA: URL fonte non valido.'; end if;
  if v_image_url is not null and v_image_url !~* '^https?://' then raise exception 'PR-04 VALORA: URL immagine non valido.'; end if;

  insert into collection.master_acquisti(data_acquisto,importo_totale_acquisto,valuta,descrizione)
  values(v_data,v_total,v_currency,v_description) returning codice_acquisto into v_acquisto_id;

  insert into collection.master_oggetti(
    descrizione_oggetto,data_inserimento,condizione,completezza,destinazione,stato,
    note,quantita,produttore,anno_uscita,codice_prodotto,fonte_dati_prodotto,stato_verifica_dati
  ) values(
    v_description,v_data,v_condition,v_completeness,v_destination,'DISPONIBILE',
    v_note,1,v_producer,v_year,v_product_code,v_source_url,
    case when v_producer is not null or v_year is not null or v_product_code is not null then 'DA_VERIFICARE' else null end
  ) returning codice_oggetto into v_oggetto_id;

  insert into collection.storico(data_evento,codice_acquisto,tipo_evento,origine_evento,note)
  values(v_data,v_acquisto_id,'ACQUISTO','PR-04 VALORA','Registrazione acquisto tramite PR-04 VALORA');
  insert into collection.storico(data_evento,codice_oggetto,codice_acquisto,tipo_evento,origine_evento,note)
  values(v_data,v_oggetto_id,v_acquisto_id,'CREAZIONE','PR-04 VALORA','Nuovo oggetto creato da VALORA; costo acquisto separato dal valore di mercato.');

  if v_category is not null then
    insert into collection.oggetto_collezione_categoria(
      codice_oggetto,codice_categoria,fonte_assegnazione,stato_verifica,aggiornato_il
    ) values(v_oggetto_id,v_category,'METADATI','DA_VERIFICARE',now());
  end if;
  if v_image_url is not null then
    insert into collection.immagini_oggetto(
      codice_oggetto,riferimento_immagine,tipo_immagine,fonte_immagine,url_fonte,
      immagine_principale,data_registrazione,note,stato_verifica,confermata_il,
      confermata_da,modalita_acquisizione,procedura_origine
    ) values(
      v_oggetto_id,v_image_url,'RIFERIMENTO_PRODOTTO','RICERCA_WEB',v_image_url,
      true,now(),'Immagine catalogo selezionata da candidato PR-12; in attesa di conferma.',
      'IN_ATTESA_CONFERMA',null,null,'ACQUISIZIONE_INIZIALE','PR-04 VALORA'
    );
  end if;

  insert into collection.acquisti_oggetti(
    codice_acquisto,codice_oggetto,descrizione_oggetto,valore_acquisto_oggetto,valuta,quantita
  ) values(v_acquisto_id,v_oggetto_id,v_description,v_cost,v_currency,1);
  insert into collection.cassa(data,descrizione,tipo_movimento,importo,valuta,tipologia,codice_acquisto)
  values(v_data,'Acquisto '||v_acquisto_id||' · PR-04 VALORA','ACQUISTO',v_total,v_currency,'USCITA',v_acquisto_id);

  if not collection.verifica_quadratura_acquisto(v_acquisto_id) then raise exception 'PR-04 VALORA: quadratura acquisto non superata.'; end if;
  select importo into v_cash from collection.cassa
  where codice_acquisto=v_acquisto_id and tipo_movimento='ACQUISTO'
  order by codice_movimento desc limit 1;
  select coalesce(sum(valore_acquisto_oggetto),0) into v_linked
  from collection.acquisti_oggetti where codice_acquisto=v_acquisto_id and incluso_nella_quadratura=true;
  if v_cash is distinct from v_total or v_linked is distinct from v_total then
    raise exception 'PR-04 VALORA: rilettura o quadratura post-salvataggio fallita.';
  end if;
  if not exists(select 1 from collection.acquisti_oggetti where codice_acquisto=v_acquisto_id and codice_oggetto=v_oggetto_id)
     or not exists(select 1 from collection.master_oggetti where codice_oggetto=v_oggetto_id and stato='DISPONIBILE') then
    raise exception 'PR-04 VALORA: collegamento oggetto-acquisto non verificato.';
  end if;

  v_result := jsonb_build_object(
    'procedura','PR-04 VALORA','stato','SALVATO_E_VERIFICATO',
    'scrittura_eseguita',true,'codice_acquisto',v_acquisto_id,'codice_oggetto',v_oggetto_id,
    'importo_totale',v_total,'valuta',v_currency,'quadratura_verificata',true,
    'oggetto_nuovo_creato',true,
    'verifiche',jsonb_build_object(
      'master_acquisti',true,'master_oggetti',true,'acquisti_oggetti',true,
      'cassa',true,'storico',true,'quadratura',true
    )
  );
  update collection.pr04_valora_requests set result=v_result
  where request_id=p_request_id and user_id=p_user_id;
  return v_result;
end;
$function$
;

revoke all on function collection.pr_04_valora_nuovo_acquisto(uuid,uuid,jsonb) from public, anon, authenticated;
grant execute on function collection.pr_04_valora_nuovo_acquisto(uuid,uuid,jsonb) to service_role;
