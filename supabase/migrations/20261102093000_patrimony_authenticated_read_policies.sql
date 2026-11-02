-- Read-only access for authenticated, explicitly authorized application users.
-- Applied and verified on COLLECTION by VALORA TEST.
grant usage on schema collection to authenticated;
grant select on table
  collection.acquisti_oggetti,
  collection.master_oggetti_in_vendita,
  collection.master_vendite,
  collection.cassa
to authenticated;

drop policy if exists acquisti_oggetti_select_autorizzati on collection.acquisti_oggetti;
create policy acquisti_oggetti_select_autorizzati
on collection.acquisti_oggetti
for select to authenticated
using (exists (
  select 1 from collection.app_authorized_users u
  where u.user_id = (select auth.uid()) and u.attivo = true
));

drop policy if exists master_oggetti_in_vendita_select_autorizzati on collection.master_oggetti_in_vendita;
create policy master_oggetti_in_vendita_select_autorizzati
on collection.master_oggetti_in_vendita
for select to authenticated
using (exists (
  select 1 from collection.app_authorized_users u
  where u.user_id = (select auth.uid()) and u.attivo = true
));

drop policy if exists master_vendite_select_autorizzati on collection.master_vendite;
create policy master_vendite_select_autorizzati
on collection.master_vendite
for select to authenticated
using (exists (
  select 1 from collection.app_authorized_users u
  where u.user_id = (select auth.uid()) and u.attivo = true
));

drop policy if exists cassa_select_autorizzati on collection.cassa;
create policy cassa_select_autorizzati
on collection.cassa
for select to authenticated
using (exists (
  select 1 from collection.app_authorized_users u
  where u.user_id = (select auth.uid()) and u.attivo = true
));
