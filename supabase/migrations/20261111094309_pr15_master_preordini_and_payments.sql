-- PR-15 PREORDER: independent master register, payment ledger and immutable event history.
-- Applied only to COLLECTION by VALORA TEST. No production database changes.
create table if not exists collection.master_preordini (
  codice_preordine bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  descrizione_oggetto text not null check (length(btrim(descrizione_oggetto)) > 0),
  categoria text,
  fornitore text not null check (length(btrim(fornitore)) > 0),
  riferimento_ordine text,
  data_prenotazione date not null default current_date,
  data_uscita_prevista date,
  prezzo_concordato numeric(14,2) not null check (prezzo_concordato > 0),
  valuta char(3) not null default 'EUR' check (valuta ~ '^[A-Z]{3}$'),
  immagine_riferimento text,
  note text,
  stato text not null default 'PRENOTATO'
    check (stato in ('PRENOTATO','PAGAMENTO_PARZIALE','PAGATO','DISPONIBILE','SPEDITO','RICEVUTO','CONVERTITO','ANNULLATO','RIMBORSATO')),
  data_ricezione timestamptz,
  codice_acquisto_convertito bigint references collection.master_acquisti(codice_acquisto) on delete set null,
  creato_il timestamptz not null default now(),
  aggiornato_il timestamptz not null default now(),
  convertito_il timestamptz,
  constraint ck_preordine_conversione check (
    (stato = 'CONVERTITO' and codice_acquisto_convertito is not null and convertito_il is not null)
    or (stato <> 'CONVERTITO' and codice_acquisto_convertito is null and convertito_il is null)
  )
);

create table if not exists collection.pagamenti_preordini (
  codice_pagamento bigint generated always as identity primary key,
  codice_preordine bigint not null references collection.master_preordini(codice_preordine) on delete restrict,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data_pagamento date not null default current_date,
  importo numeric(14,2) not null check (importo > 0),
  metodo_pagamento text,
  riferimento_pagamento text,
  note text,
  creato_il timestamptz not null default now()
);

create table if not exists collection.storico_preordini (
  codice_evento bigint generated always as identity primary key,
  codice_preordine bigint not null references collection.master_preordini(codice_preordine) on delete restrict,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  tipo_evento text not null,
  stato_precedente text,
  stato_nuovo text,
  dettaglio jsonb not null default '{}'::jsonb,
  registrato_il timestamptz not null default now()
);

create index if not exists ix_preordini_user_stato on collection.master_preordini(user_id, stato);
create index if not exists ix_preordini_data_prevista on collection.master_preordini(user_id, data_uscita_prevista);
create index if not exists ix_pagamenti_preordine on collection.pagamenti_preordini(codice_preordine, data_pagamento);
create index if not exists ix_storico_preordine on collection.storico_preordini(codice_preordine, registrato_il);

alter table collection.master_preordini enable row level security;
alter table collection.pagamenti_preordini enable row level security;
alter table collection.storico_preordini enable row level security;

create policy "preordini_select_own" on collection.master_preordini
 for select to authenticated using (user_id = (select auth.uid()));
create policy "preordini_insert_own" on collection.master_preordini
 for insert to authenticated with check (user_id = (select auth.uid()));
create policy "preordini_update_own" on collection.master_preordini
 for update to authenticated using (user_id = (select auth.uid()))
 with check (user_id = (select auth.uid()));

create policy "pagamenti_preordini_select_own" on collection.pagamenti_preordini
 for select to authenticated using (user_id = (select auth.uid()));
create policy "pagamenti_preordini_insert_own" on collection.pagamenti_preordini
 for insert to authenticated with check (
   user_id = (select auth.uid()) and exists (
     select 1 from collection.master_preordini p
     where p.codice_preordine = codice_preordine and p.user_id = (select auth.uid())
   )
 );

create policy "storico_preordini_select_own" on collection.storico_preordini
 for select to authenticated using (user_id = (select auth.uid()));
create policy "storico_preordini_insert_own" on collection.storico_preordini
 for insert to authenticated with check (
   user_id = (select auth.uid()) and exists (
     select 1 from collection.master_preordini p
     where p.codice_preordine = codice_preordine and p.user_id = (select auth.uid())
   )
 );

grant usage on schema collection to authenticated;
grant select, insert, update on collection.master_preordini to authenticated;
grant select, insert on collection.pagamenti_preordini to authenticated;
grant select, insert on collection.storico_preordini to authenticated;
grant usage, select on all sequences in schema collection to authenticated;

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
    return new;
  end if;
  new.aggiornato_il := now();
  if old.stato is distinct from new.stato then
    insert into collection.storico_preordini(codice_preordine, user_id, tipo_evento, stato_precedente, stato_nuovo, dettaglio)
    values (new.codice_preordine, new.user_id, 'CAMBIO_STATO', old.stato, new.stato,
      jsonb_build_object('codice_acquisto_convertito', new.codice_acquisto_convertito));
  end if;
  return new;
end;
$$;

create trigger trg_pr15_preorder_evento
before insert or update on collection.master_preordini
for each row execute function collection.pr15_preorder_registra_evento();

create or replace function collection.pr15_preorder_valida_pagamento()
returns trigger
language plpgsql
set search_path = collection, pg_temp
as $$
declare
  v_prezzo numeric(14,2);
  v_totale numeric(14,2);
  v_stato text;
  v_user uuid;
begin
  select prezzo_concordato, stato, user_id into v_prezzo, v_stato, v_user
    from collection.master_preordini where codice_preordine = new.codice_preordine for update;
  if not found then raise exception 'PR-15: preorder non trovato.'; end if;
  if v_user <> new.user_id then raise exception 'PR-15: proprietario pagamento non coerente.'; end if;
  if v_stato in ('RICEVUTO','CONVERTITO','ANNULLATO','RIMBORSATO') then
    raise exception 'PR-15: non è possibile registrare pagamenti in questo stato.';
  end if;
  select coalesce(sum(importo),0) into v_totale from collection.pagamenti_preordini
   where codice_preordine = new.codice_preordine
     and (tg_op <> 'UPDATE' or codice_pagamento <> new.codice_pagamento);
  if v_totale + new.importo > v_prezzo then
    raise exception 'PR-15: il pagamento supera il saldo residuo.';
  end if;
  return new;
end;
$$;

create trigger trg_pr15_valida_pagamento
before insert or update on collection.pagamenti_preordini
for each row execute function collection.pr15_preorder_valida_pagamento();

create or replace function collection.pr15_preorder_aggiorna_stato_pagamento()
returns trigger
language plpgsql
set search_path = collection, pg_temp
as $$
declare
  v_totale numeric(14,2);
  v_prezzo numeric(14,2);
  v_stato text;
begin
  select prezzo_concordato, stato into v_prezzo, v_stato
    from collection.master_preordini where codice_preordine = new.codice_preordine for update;
  select coalesce(sum(importo),0) into v_totale
    from collection.pagamenti_preordini where codice_preordine = new.codice_preordine;
  if v_stato in ('PRENOTATO','PAGAMENTO_PARZIALE','PAGATO') then
    update collection.master_preordini
       set stato = case when v_totale = 0 then 'PRENOTATO'
                        when v_totale = v_prezzo then 'PAGATO'
                        else 'PAGAMENTO_PARZIALE' end
     where codice_preordine = new.codice_preordine;
  end if;
  insert into collection.storico_preordini(codice_preordine, user_id, tipo_evento, dettaglio)
  values (new.codice_preordine, new.user_id, 'PAGAMENTO_REGISTRATO',
    jsonb_build_object('codice_pagamento', new.codice_pagamento, 'importo', new.importo, 'totale_versato', v_totale));
  return new;
end;
$$;

create trigger trg_pr15_aggiorna_stato_pagamento
after insert on collection.pagamenti_preordini
for each row execute function collection.pr15_preorder_aggiorna_stato_pagamento();
