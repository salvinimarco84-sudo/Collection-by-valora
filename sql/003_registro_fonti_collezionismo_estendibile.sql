-- Collection by VALORA: extensible source registry (TEST-first migration).
-- Additive only. Does not alter existing collection records or production data.
create schema if not exists collection;

create table if not exists collection.registro_fonti (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  url_base text not null,
  ambito text not null default 'generale',
  categoria text not null default 'universale',
  marchio_editore text,
  franchise text,
  mercato text not null default 'globale',
  tipo_fonte text not null default 'specialistica'
    check (tipo_fonte in ('ufficiale','specialistica','bibliografica','comunita','mercato','personale')),
  priorita smallint not null default 50 check (priorita between 1 and 100),
  attendibilita_dichiarata text not null default 'da_verificare'
    check (attendibilita_dichiarata in ('ufficiale','alta','media','da_verificare')),
  stato_verifica text not null default 'da_verificare'
    check (stato_verifica in ('da_verificare','verificata','non_raggiungibile','non_pertinente')),
  origine_configurazione text not null default 'utente'
    check (origine_configurazione in ('sistema','condivisa','utente')),
  proprietario_utente uuid,
  condivisa boolean not null default false,
  attiva boolean not null default true,
  note text,
  data_creazione timestamptz not null default now(),
  data_modifica timestamptz not null default now(),
  constraint registro_fonti_url_non_vuoto check (length(trim(url_base)) > 0),
  constraint registro_fonti_nome_non_vuoto check (length(trim(nome)) > 0)
);

create index if not exists registro_fonti_lookup_idx
  on collection.registro_fonti (attiva, mercato, categoria, priorita);

create index if not exists registro_fonti_owner_idx
  on collection.registro_fonti (proprietario_utente, condivisa);

create table if not exists collection.registro_fonti_categorie (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  categoria_padre_id uuid references collection.registro_fonti_categorie(id) on delete set null,
  schema_campi jsonb not null default '[]'::jsonb,
  attiva boolean not null default true,
  origine_configurazione text not null default 'sistema'
    check (origine_configurazione in ('sistema','condivisa','utente')),
  proprietario_utente uuid,
  data_creazione timestamptz not null default now(),
  data_modifica timestamptz not null default now(),
  constraint registro_fonti_categorie_nome_unico unique (nome, proprietario_utente)
);

create table if not exists collection.registro_fonti_ambiti (
  id uuid primary key default gen_random_uuid(),
  fonte_id uuid not null references collection.registro_fonti(id) on delete cascade,
  categoria text not null default 'universale',
  marchio_editore text,
  franchise text,
  mercato text not null default 'globale',
  priorita_override smallint check (priorita_override between 1 and 100),
  note text,
  unique (fonte_id, categoria, marchio_editore, franchise, mercato)
);

comment on table collection.registro_fonti is
'Registro espandibile di fonti ufficiali, specialistiche e personali per ricerche di collezionismo. La fiducia dichiarata non equivale a verifica automatica.';
comment on table collection.registro_fonti_categorie is
'Categorie e campi specialistici configurabili senza modificare lo schema principale degli oggetti.';
comment on table collection.registro_fonti_ambiti is
'Associa una fonte a più categorie, marchi, franchise e mercati.';
