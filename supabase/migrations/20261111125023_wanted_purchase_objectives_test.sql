create table if not exists collection.wanted_obiettivi (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  titolo text not null check (length(trim(titolo)) > 0),
  categoria_tema text not null check (length(trim(categoria_tema)) > 0),
  priorita text not null default 'MEDIA' check (priorita in ('ALTA', 'MEDIA', 'BASSA')),
  note text,
  data_creazione timestamptz not null default now(),
  data_aggiornamento timestamptz not null default now()
);

create index if not exists wanted_obiettivi_user_priority_idx
  on collection.wanted_obiettivi (user_id, priorita, data_creazione desc);

alter table collection.wanted_obiettivi enable row level security;

create policy wanted_obiettivi_select_own
  on collection.wanted_obiettivi for select to authenticated
  using ((select auth.uid()) = user_id);

create policy wanted_obiettivi_insert_own
  on collection.wanted_obiettivi for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy wanted_obiettivi_update_own
  on collection.wanted_obiettivi for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy wanted_obiettivi_delete_own
  on collection.wanted_obiettivi for delete to authenticated
  using ((select auth.uid()) = user_id);

grant select, insert, update, delete on collection.wanted_obiettivi to authenticated;
