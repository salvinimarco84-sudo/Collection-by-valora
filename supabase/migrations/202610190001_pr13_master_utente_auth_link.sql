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

alter table collection.master_utente enable row level security;

drop policy if exists master_utente_select_own on collection.master_utente;
create policy master_utente_select_own
  on collection.master_utente
  for select to authenticated
  using (auth_user_id = (select auth.uid()));

drop policy if exists master_utente_insert_own on collection.master_utente;
create policy master_utente_insert_own
  on collection.master_utente
  for insert to authenticated
  with check (auth_user_id = (select auth.uid()));

drop policy if exists master_utente_update_own on collection.master_utente;
create policy master_utente_update_own
  on collection.master_utente
  for update to authenticated
  using (auth_user_id = (select auth.uid()))
  with check (auth_user_id = (select auth.uid()));

grant select, insert, update on collection.master_utente to authenticated;

commit;

-- Notes:
-- 1. This migration intentionally does not seed collection.mercati. The market
--    catalogue and its required columns must be reviewed before inserting data.
-- 2. It does not grant delete, service_role access, or access to other users' rows.
-- 3. The app must verify the allowlist (collection.app_authorized_users) before
--    allowing first-time profile creation. Do not rely on UI checks alone.
-- 4. Test anonymous, unauthorized, authorized, duplicate-profile, and cross-user
--    access before connecting the Flutter Save button.
