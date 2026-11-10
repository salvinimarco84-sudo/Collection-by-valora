create table if not exists collection.pr04_valora_requests (
  request_id uuid primary key,
  user_id uuid not null,
  result jsonb,
  created_at timestamptz not null default now()
);
alter table collection.pr04_valora_requests enable row level security;
revoke all on collection.pr04_valora_requests from public, anon, authenticated;
grant select, insert, update on collection.pr04_valora_requests to service_role;
