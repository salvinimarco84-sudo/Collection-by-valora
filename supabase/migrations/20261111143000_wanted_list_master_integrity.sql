-- WANTED LIST master table integrity.
-- The master table was created in the TEST Supabase project by migration
-- 20261111120904_create_wanted_desideri. This migration adds automatic
-- update timestamps and query indexes without changing existing records.

create or replace function collection.set_wanted_desideri_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.data_aggiornamento := now();
  return new;
end;
$$;

drop trigger if exists wanted_desideri_set_updated_at
  on collection.wanted_desideri;

create trigger wanted_desideri_set_updated_at
before update on collection.wanted_desideri
for each row
execute function collection.set_wanted_desideri_updated_at();

create index if not exists wanted_desideri_user_category_status_idx
  on collection.wanted_desideri (user_id, categoria, stato);

create index if not exists wanted_desideri_acquired_object_idx
  on collection.wanted_desideri (codice_oggetto_acquistato)
  where codice_oggetto_acquistato is not null;
