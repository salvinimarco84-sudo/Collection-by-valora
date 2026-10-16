-- Applicare solo al progetto Supabase TEST eeiekkflpnkummxtvljy.
create table if not exists collection.app_authorized_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  ruolo text not null default 'BETA_OWNER' check (ruolo in ('BETA_OWNER','BETA_TESTER','ADMIN')),
  attivo boolean not null default true,
  note text,
  creato_il timestamptz not null default now(),
  aggiornato_il timestamptz not null default now()
);
alter table collection.app_authorized_users enable row level security;
revoke all on table collection.app_authorized_users from anon, authenticated;
grant select on table collection.app_authorized_users to service_role;
