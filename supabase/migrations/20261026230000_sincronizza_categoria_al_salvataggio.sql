-- Sincronizza la categoria principale quando PR-01 salva/inserisce metadati specifici.
-- Applicare esclusivamente al progetto COLLECTION by VALORA TEST.
begin;

create or replace function collection.sincronizza_categoria_da_metadati()
returns trigger
language plpgsql
set search_path = collection, pg_temp
as $$
declare
  v_categoria text;
  v_codice_categoria text;
  v_tema text;
  v_id_tema bigint;
  v_destinazione text;
  v_archiviato boolean;
begin
  v_categoria := upper(btrim(coalesce(new.valori->>'categoria','')));
  v_codice_categoria := case
    when v_categoria = 'LEGO' then 'LEGO'
    when v_categoria in ('SAINT SEIYA','SAINT_SEIYA') then 'SAINT_SEIYA'
    when v_categoria in ('TRANSFORMERS','TRANSFORMER') then 'TRANSFORMERS'
    when v_categoria in ('FUMETTI','FUMETTO','COMICS','MANGA') then 'FUMETTI'
    when v_categoria = 'GUNDAM' then 'GUNDAM'
    when v_categoria in ('MOTO DIE-CAST','MOTO DIE CAST','DIE-CAST','DIE CAST') then 'MOTO_DIE_CAST'
    else null
  end;

  -- Non classificare indovinando dalla descrizione: serve categoria esplicita nei metadati.
  if v_codice_categoria is null then
    return new;
  end if;

  select destinazione, coalesce(archiviato_test,false)
    into v_destinazione, v_archiviato
  from collection.master_oggetti
  where codice_oggetto = new.codice_oggetto;

  if v_destinazione is distinct from 'COLLEZIONE' or v_archiviato then
    return new;
  end if;

  v_tema := nullif(btrim(coalesce(new.valori->>'tema','')), '');
  v_id_tema := null;
  if v_tema is not null then
    insert into collection.temi_collezione
      (codice_categoria, codice_tema, descrizione, ordine, attivo)
    values (
      v_codice_categoria,
      upper(regexp_replace(v_tema, '[^[:alnum:]]+', '_', 'g')),
      v_tema, 100, true
    )
    on conflict (codice_categoria, codice_tema) do nothing;

    select id_tema into v_id_tema
    from collection.temi_collezione
    where codice_categoria = v_codice_categoria
      and upper(btrim(descrizione)) = upper(v_tema)
    limit 1;
  end if;

  insert into collection.oggetto_collezione_categoria
    (codice_oggetto, codice_categoria, id_tema, fonte_assegnazione, stato_verifica, aggiornato_il)
  values
    (new.codice_oggetto, v_codice_categoria, v_id_tema, 'METADATI', 'DA_VERIFICARE', now())
  on conflict (codice_oggetto) do update
    set codice_categoria = excluded.codice_categoria,
        id_tema = excluded.id_tema,
        fonte_assegnazione = 'METADATI',
        stato_verifica = 'DA_VERIFICARE',
        aggiornato_il = now();

  return new;
end;
$$;

drop trigger if exists trg_sincronizza_categoria_da_metadati
  on collection.metadati_specifici_oggetto;

create trigger trg_sincronizza_categoria_da_metadati
after insert or update of valori, codice_oggetto
on collection.metadati_specifici_oggetto
for each row execute function collection.sincronizza_categoria_da_metadati();

commit;
