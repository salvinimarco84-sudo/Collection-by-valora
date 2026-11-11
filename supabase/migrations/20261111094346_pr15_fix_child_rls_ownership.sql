-- PR-15: qualify child foreign-key columns in ownership policies.
drop policy if exists "pagamenti_preordini_insert_own" on collection.pagamenti_preordini;
create policy "pagamenti_preordini_insert_own" on collection.pagamenti_preordini
 for insert to authenticated with check (
   user_id = (select auth.uid()) and exists (
     select 1 from collection.master_preordini p
     where p.codice_preordine = pagamenti_preordini.codice_preordine
       and p.user_id = (select auth.uid())
   )
 );

drop policy if exists "storico_preordini_insert_own" on collection.storico_preordini;
create policy "storico_preordini_insert_own" on collection.storico_preordini
 for insert to authenticated with check (
   user_id = (select auth.uid()) and exists (
     select 1 from collection.master_preordini p
     where p.codice_preordine = storico_preordini.codice_preordine
       and p.user_id = (select auth.uid())
   )
 );
