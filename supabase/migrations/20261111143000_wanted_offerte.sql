create table if not exists collection.wanted_offerte (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  desiderio_id uuid not null references collection.wanted_desideri(id) on delete cascade,
  titolo text not null,
  prezzo numeric(12,2),
  valuta text not null default 'EUR',
  condizione text,
  piattaforma text,
  url_annuncio text not null,
  fonte text,
  snippet text,
  stato text not null default 'DA_VALUTARE'
    check (stato in ('DA_VALUTARE','INTERESSANTE','SCARTATA','ACQUISTATA')),
  data_ricerca timestamptz not null default now(),
  data_creazione timestamptz not null default now(),
  constraint wanted_offerte_url_http check (url_annuncio ~* '^https?://')
);
create index if not exists wanted_offerte_user_desiderio_idx
  on collection.wanted_offerte (user_id, desiderio_id, data_ricerca desc);
alter table collection.wanted_offerte enable row level security;
drop policy if exists wanted_offerte_select_own on collection.wanted_offerte;
create policy wanted_offerte_select_own on collection.wanted_offerte
  for select to authenticated using (auth.uid() = user_id);
drop policy if exists wanted_offerte_insert_own on collection.wanted_offerte;
create policy wanted_offerte_insert_own on collection.wanted_offerte
  for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists wanted_offerte_update_own on collection.wanted_offerte;
create policy wanted_offerte_update_own on collection.wanted_offerte
  for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists wanted_offerte_delete_own on collection.wanted_offerte;
create policy wanted_offerte_delete_own on collection.wanted_offerte
  for delete to authenticated using (auth.uid() = user_id);
grant select, insert, update, delete on collection.wanted_offerte to authenticated;
