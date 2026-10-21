-- PR12: master strutturato dei metadati confermati.
-- Questa migrazione è destinata all'ambiente TEST; non aggiorna automaticamente i record esistenti.
create table if not exists collection.master_metadati (
  codice_oggetto bigint primary key
    references collection.master_oggetti(codice_oggetto) on delete cascade,
  codice_identificativo text,
  nome_ufficiale text,
  produttore text,
  anno_uscita smallint,
  versione_variante text,
  descrizione_ufficiale text,
  tema text,
  sezione text,
  sottotema text,
  isbn text,
  editore text,
  url_fonte text,
  url_immagine text,
  stato_verifica text not null default 'DA_VERIFICARE'
    check (stato_verifica in ('DA_VERIFICARE','PARZIALMENTE_VERIFICATO','VERIFICATO')),
  data_conferma timestamptz,
  aggiornato_il timestamptz not null default now(),
  constraint master_metadati_anno_check
    check (anno_uscita is null or anno_uscita between 1000 and 9999)
);

comment on table collection.master_metadati is
  'Metadati catalografici confermati per oggetto. Un record per codice_oggetto; i candidati PR12 non vengono salvati qui prima della conferma utente.';
comment on column collection.master_metadati.codice_identificativo is
  'Identificativo ufficiale prodotto/pubblicazione; distinto dal codice_oggetto interno.';
comment on column collection.master_metadati.nome_ufficiale is
  'Nome ufficiale confermato. Dopo conferma può sostituire master_oggetti.descrizione_oggetto.';
comment on column collection.master_metadati.url_fonte is
  'Fonte scelta dall’utente per i metadati confermati.';
comment on column collection.master_metadati.url_immagine is
  'URL dell’immagine scelta dall’utente.';

alter table collection.master_metadati enable row level security;
grant all on collection.master_metadati to service_role;
drop policy if exists backend_service_only on collection.master_metadati;
create policy backend_service_only on collection.master_metadati
  for all to service_role using (true) with check (true);

-- Scrittura atomica: metadati e descrizione si aggiornano nella stessa transazione.
create or replace function collection.confirm_pr12_metadati(p_record jsonb)
returns jsonb
language plpgsql
security definer
set search_path = collection, public
as $function$
declare
  v_id bigint := (p_record->>'codice_oggetto')::bigint;
  v_nome text := nullif(btrim(p_record->>'nome_ufficiale'), '');
  v_updated bigint;
begin
  if v_id is null or v_id <= 0 then
    raise exception 'CODICE_OGGETTO non valido';
  end if;
  if v_nome is null then
    raise exception 'NOME_UFFICIALE obbligatorio';
  end if;

  insert into collection.master_metadati (
    codice_oggetto, codice_identificativo, nome_ufficiale, produttore,
    anno_uscita, versione_variante, descrizione_ufficiale, tema, sezione,
    sottotema, isbn, editore, url_fonte, url_immagine, stato_verifica,
    data_conferma, aggiornato_il
  ) values (
    v_id, nullif(p_record->>'codice_identificativo',''), v_nome,
    nullif(p_record->>'produttore',''),
    nullif(p_record->>'anno_uscita','')::smallint,
    nullif(p_record->>'versione_variante',''),
    nullif(p_record->>'descrizione_ufficiale',''),
    nullif(p_record->>'tema',''), nullif(p_record->>'sezione',''),
    nullif(p_record->>'sottotema',''), nullif(p_record->>'isbn',''),
    nullif(p_record->>'editore',''), nullif(p_record->>'url_fonte',''),
    nullif(p_record->>'url_immagine',''), 'VERIFICATO',
    now(), now()
  )
  on conflict (codice_oggetto) do update set
    codice_identificativo = excluded.codice_identificativo,
    nome_ufficiale = excluded.nome_ufficiale,
    produttore = excluded.produttore,
    anno_uscita = excluded.anno_uscita,
    versione_variante = excluded.versione_variante,
    descrizione_ufficiale = excluded.descrizione_ufficiale,
    tema = excluded.tema,
    sezione = excluded.sezione,
    sottotema = excluded.sottotema,
    isbn = excluded.isbn,
    editore = excluded.editore,
    url_fonte = excluded.url_fonte,
    url_immagine = excluded.url_immagine,
    stato_verifica = 'VERIFICATO',
    data_conferma = now(),
    aggiornato_il = now();

  update collection.master_oggetti
    set descrizione_oggetto = v_nome
    where codice_oggetto = v_id;
  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'Oggetto % non trovato in modo univoco; annullamento transazione', v_id;
  end if;

  return jsonb_build_object(
    'ok', true, 'codice_oggetto', v_id,
    'nome_ufficiale', v_nome, 'descrizione_sostituita', true,
    'master_metadati_salvato', true
  );
end;
$function$;

revoke all on function collection.confirm_pr12_metadati(jsonb) from public, anon, authenticated;
grant execute on function collection.confirm_pr12_metadati(jsonb) to service_role;
