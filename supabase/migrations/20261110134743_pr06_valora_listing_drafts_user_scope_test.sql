-- Scope the uniqueness of saved drafts to the authenticated owner.
alter table collection.bozze_inserzioni_valora
  drop constraint if exists uq_bozza_valora_vendita_piattaforma;
alter table collection.bozze_inserzioni_valora
  drop constraint if exists uq_bozza_user_vendita_piattaforma;
alter table collection.bozze_inserzioni_valora
  add constraint uq_bozza_user_vendita_piattaforma
  unique (user_id, codice_vendita_aperta, codice_piattaforma);