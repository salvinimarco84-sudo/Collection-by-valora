-- VALORA collection-wide valuation jobs. TEST-first migration; apply only to TEST project.
create schema if not exists collection;

create table if not exists collection.valuation_jobs (
  id uuid primary key default gen_random_uuid(),
  requested_by uuid not null,
  market text not null default 'ITALIA' check (market in ('ITALIA','EUROPA','MONDO')),
  status text not null default 'queued' check (status in ('queued','running','completed','completed_with_gaps','failed','cancelled')),
  total_items integer not null default 0,
  processed_items integer not null default 0,
  priced_items integer not null default 0,
  unpriced_items integer not null default 0,
  failed_items integer not null default 0,
  last_error text,
  started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists collection.valuation_job_items (
  id bigint generated always as identity primary key,
  job_id uuid not null references collection.valuation_jobs(id) on delete cascade,
  object_code text not null,
  description text not null,
  category text,
  quantity numeric not null default 1,
  state text not null default 'queued' check (state in ('queued','running','priced','unpriced','failed')),
  candidates jsonb not null default '[]'::jsonb,
  quote_min numeric,
  quote_indicative numeric,
  quote_max numeric,
  currency text,
  source_urls jsonb not null default '[]'::jsonb,
  confidence numeric,
  error text,
  attempts integer not null default 0,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(job_id, object_code)
);

create index if not exists valuation_jobs_requested_by_created_idx
  on collection.valuation_jobs(requested_by, created_at desc);
create index if not exists valuation_job_items_queue_idx
  on collection.valuation_job_items(job_id, state, id);

alter table collection.valuation_jobs enable row level security;
alter table collection.valuation_job_items enable row level security;

drop policy if exists valuation_jobs_owner_read on collection.valuation_jobs;
create policy valuation_jobs_owner_read on collection.valuation_jobs
  for select to authenticated using (requested_by = auth.uid());

drop policy if exists valuation_items_owner_read on collection.valuation_job_items;
create policy valuation_items_owner_read on collection.valuation_job_items
  for select to authenticated using (
    exists (select 1 from collection.valuation_jobs j where j.id = job_id and j.requested_by = auth.uid())
  );

grant usage on schema collection to authenticated;
grant select on collection.valuation_jobs, collection.valuation_job_items to authenticated;

-- Authenticated users can manage only jobs they own; item access is tied to job ownership.
drop policy if exists valuation_jobs_owner_insert on collection.valuation_jobs;
create policy valuation_jobs_owner_insert on collection.valuation_jobs
  for insert to authenticated with check (requested_by = auth.uid());
drop policy if exists valuation_jobs_owner_update on collection.valuation_jobs;
create policy valuation_jobs_owner_update on collection.valuation_jobs
  for update to authenticated using (requested_by = auth.uid()) with check (requested_by = auth.uid());

drop policy if exists valuation_items_owner_insert on collection.valuation_job_items;
create policy valuation_items_owner_insert on collection.valuation_job_items
  for insert to authenticated with check (
    exists (select 1 from collection.valuation_jobs j where j.id = job_id and j.requested_by = auth.uid())
  );
drop policy if exists valuation_items_owner_update on collection.valuation_job_items;
create policy valuation_items_owner_update on collection.valuation_job_items
  for update to authenticated using (
    exists (select 1 from collection.valuation_jobs j where j.id = job_id and j.requested_by = auth.uid())
  ) with check (
    exists (select 1 from collection.valuation_jobs j where j.id = job_id and j.requested_by = auth.uid())
  );
grant insert, update on collection.valuation_jobs, collection.valuation_job_items to authenticated;
grant usage, select on sequence collection.valuation_job_items_id_seq to authenticated;
