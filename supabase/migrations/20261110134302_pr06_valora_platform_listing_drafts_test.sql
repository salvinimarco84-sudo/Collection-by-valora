-- PR-06 VALORA: bozze indipendenti per ogni piattaforma selezionata.
-- TEST only. No production migration or publication integration.
create table if not exists collection.bozze_inserzioni_valora (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  codice_vendita_aperta bigint not null references collection.master_oggetti_in_vendita(codice_vendita_aperta) on delete cascade,
  codice_oggetto bigint not null references collection.master_oggetti(codice_oggetto) on delete cascade,
  codice_piattaforma bigint not null references collection.piattaforme(codice_piattaforma),
  nome_piattaforma text not null,
  titolo text not null default '',
  descrizione text not null default '',
  categoria text,
  prezzo numeric(12,2) not null check (prezzo > 0),
  valuta char(3) not null default 'EUR' check (valuta ~ '^[A-Z]{3}$'),
  condizione text,
  completezza text,
  immagini jsonb not null default '[]'::jsonb,
  dati_fonte jsonb not null default '{}'::jsonb,
  avvisi jsonb not null default '[]'::jsonb,
  stato text not null default 'BOZZA'
    check (stato in ('BOZZA','REVISIONATA','APPROVATA','ESPORTATA')),
  creato_il timestamptz not null default now(),
  aggiornato_il timestamptz not null default now(),
  constraint uq_bozza_valora_vendita_piattaforma unique (codice_vendita_aperta, codice_piattaforma)
);

create index if not exists ix_bozze_valora_user_created
  on collection.bozze_inserzioni_valora (user_id, creato_il desc);
create index if not exists ix_bozze_valora_sale
  on collection.bozze_inserzioni_valora (codice_vendita_aperta);

alter table collection.bozze_inserzioni_valora enable row level security;
grant usage on schema collection to authenticated;
grant select, insert, update, delete on collection.bozze_inserzioni_valora to authenticated;

drop policy if exists bozze_valora_select_own on collection.bozze_inserzioni_valora;
create policy bozze_valora_select_own
  on collection.bozze_inserzioni_valora for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists bozze_valora_insert_own on collection.bozze_inserzioni_valora;
create policy bozze_valora_insert_own
  on collection.bozze_inserzioni_valora for insert to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists bozze_valora_update_own on collection.bozze_inserzioni_valora;
create policy bozze_valora_update_own
  on collection.bozze_inserzioni_valora for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists bozze_valora_delete_own on collection.bozze_inserzioni_valora;
create policy bozze_valora_delete_own
  on collection.bozze_inserzioni_valora for delete to authenticated
  using ((select auth.uid()) = user_id);
