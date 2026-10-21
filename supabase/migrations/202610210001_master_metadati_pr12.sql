-- PR12: master strutturato dei metadati confermati.
-- Questa migrazione è destinata all'ambiente TEST; non aggiorna automaticamente i record esistenti.
create table if not exists collection.master_metadati (
  codice_oggetto bigint primary key
    references collection.master_oggetti(codice_oggetto) on delete cascade,
  codice_identificativo text,
  nome_ufficiale text,
  produttore text,
  anno_uscita smallint,
  versione_variante text,
  descrizione_ufficiale text,
  tema text,
  sezione text,
  sottotema text,
  isbn text,
  editore text,
  url_fonte text,
  url_immagine text,
  stato_verifica text not null default 'DA_VERIFICARE'
    check (stato_verifica in ('DA_VERIFICARE','PARZIALMENTE_VERIFICATO','VERIFICATO')),
  data_conferma timestamptz,
  aggiornato_il timestamptz not null default now(),
  constraint master_metadati_anno_check
    check (anno_uscita is null or anno_uscita between 1000 and 9999)
);

comment on table collection.master_metadati is
  'Metadati catalografici confermati per oggetto. Un record per codice_oggetto; i candidati PR12 non vengono salvati qui prima della conferma utente.';
comment on column collection.master_metadati.codice_identificativo is
  'Identificativo ufficiale prodotto/pubblicazione; distinto dal codice_oggetto interno.';
comment on column collection.master_metadati.nome_ufficiale is
  'Nome ufficiale confermato. Dopo conferma può sostituire master_oggetti.descrizione_oggetto.';
comment on column collection.master_metadati.url_fonte is
  'Fonte scelta dall’utente per i metadati confermati.';
comment on column collection.master_metadati.url_immagine is
  'URL dell’immagine scelta dall’utente.';

alter table collection.master_metadati enable row level security;
grant select, insert, update on collection.master_metadati to authenticated;
grant all on collection.master_metadati to service_role;

-- Le policy di accesso saranno allineate alle policy esistenti di master_oggetti
-- prima di abilitare la scrittura dalla PR12; questa migrazione non apre accessi anonimi.
