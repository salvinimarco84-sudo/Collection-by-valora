-- PR-15: write creation/state events only after the parent preorder row exists.
drop trigger if exists trg_pr15_preorder_evento on collection.master_preordini;
drop function if exists collection.pr15_preorder_registra_evento();

create or replace function collection.pr15_preorder_aggiorna_timestamp()
returns trigger
language plpgsql
set search_path = collection, pg_temp
as $$
begin
  new.aggiornato_il := now();
  return new;
end;
$$;

create trigger trg_pr15_preorder_timestamp
before update on collection.master_preordini
for each row execute function collection.pr15_preorder_aggiorna_timestamp();

create or replace function collection.pr15_preorder_registra_evento()
returns trigger
language plpgsql
set search_path = collection, pg_temp
as $$
begin
  if tg_op = 'INSERT' then
    insert into collection.storico_preordini(codice_preordine, user_id, tipo_evento, stato_nuovo, dettaglio)
    values (new.codice_preordine, new.user_id, 'CREAZIONE', new.stato,
      jsonb_build_object('descrizione_oggetto', new.descrizione_oggetto, 'prezzo_concordato', new.prezzo_concordato));
  elsif old.stato is distinct from new.stato then
    insert into collection.storico_preordini(codice_preordine, user_id, tipo_evento, stato_precedente, stato_nuovo, dettaglio)
    values (new.codice_preordine, new.user_id, 'CAMBIO_STATO', old.stato, new.stato,
      jsonb_build_object('codice_acquisto_convertito', new.codice_acquisto_convertito));
  end if;
  return new;
end;
$$;

create trigger trg_pr15_preorder_evento
after insert or update on collection.master_preordini
for each row execute function collection.pr15_preorder_registra_evento();
