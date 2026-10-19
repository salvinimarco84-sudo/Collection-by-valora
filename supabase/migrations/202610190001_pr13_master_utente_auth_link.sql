-- PR-13 GESTIONE UTENTE
-- Migration proposal for Supabase TEST only.
-- Review and apply only to project eeiekkflpnkummxtvljy after validation.
-- Never apply to production (bufwceckrmbocctarthj).

begin;

alter table collection.master_utente
  add column if not exists auth_user_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'master_utente_auth_user_id_fkey'
      and conrelid = 'collection.master_utente'::regclass
  ) then
    alter table collection.master_utente
      add constraint master_utente_auth_user_id_fkey
      foreign key (auth_user_id) references auth.users(id) on delete restrict;
  end if;
end $$;

create unique index if not exists master_utente_auth_user_id_uidx
  on collection.master_utente(auth_user_id)
  where auth_user_id is not null;

-- Initial catalogue values, using only the existing table's confirmed columns.
insert into collection.mercati (livello_mercato, nome_mercato, descrizione)
select v.livello_mercato, v.nome_mercato, v.descrizione
from (values
  ('NAZIONALE', 'Italia', 'Mercato nazionale principale'),
  ('CONTINENTALE', 'Europa', 'Mercato europeo'),
  ('GLOBALE', 'Mondo', 'Mercato globale')
) as v(livello_mercato, nome_mercato, descrizione)
where not exists (
  select 1 from collection.mercati m
  where lower(m.nome_mercato) = lower(v.nome_mercato)
);

alter table collection.master_utente enable row level security;

drop policy if exists master_utente_select_own on collection.master_utente;
create policy master_utente_select_own
  on collection.master_utente
  for select to authenticated
  using (
    auth_user_id = (select auth.uid())
    and exists (
      select 1 from collection.app_authorized_users a
      where a.user_id = (select auth.uid()) and a.attivo = true
    )
  );

drop policy if exists master_utente_insert_own on collection.master_utente;
create policy master_utente_insert_own
  on collection.master_utente
  for insert to authenticated
  with check (
    auth_user_id = (select auth.uid())
    and exists (
      select 1 from collection.app_authorized_users a
      where a.user_id = (select auth.uid()) and a.attivo = true
    )
  );

drop policy if exists master_utente_update_own on collection.master_utente;
create policy master_utente_update_own
  on collection.master_utente
  for update to authenticated
  using (
    auth_user_id = (select auth.uid())
    and exists (
      select 1 from collection.app_authorized_users a
      where a.user_id = (select auth.uid()) and a.attivo = true
    )
  )
  with check (
    auth_user_id = (select auth.uid())
    and exists (
      select 1 from collection.app_authorized_users a
      where a.user_id = (select auth.uid()) and a.attivo = true
    )
  );

grant select, insert, update on collection.master_utente to authenticated;
grant select on collection.mercati to authenticated;

commit;

-- Acceptance tests required before enabling profile persistence:
-- 1. Anonymous and authenticated-but-not-allowlisted users cannot read/write.
-- 2. Allowlisted user can create exactly one profile and read/update only theirs.
-- 3. Duplicate auth_user_id and changing auth_user_id are rejected.
-- 4. The three market options load from the TEST catalogue.
-- 5. Login on another device reads the same database-backed profile.
-- 6. No changes to objects, purchases, sales, cashflow, or production.
