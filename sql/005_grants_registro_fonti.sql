-- API grants for authenticated users; row-level policies remain the access boundary.
grant usage on schema collection to authenticated;
grant select, insert, update, delete on collection.registro_fonti to authenticated;
grant select, insert, update, delete on collection.registro_fonti_categorie to authenticated;
grant select, insert, update, delete on collection.registro_fonti_ambiti to authenticated;
