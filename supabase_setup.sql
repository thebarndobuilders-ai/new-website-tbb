-- ============================================================
-- THE BARNDO BUILDERS — MULTI-USER SETUP (paste into Supabase)
-- Dashboard → SQL Editor → New query → paste ALL of this → Run.
-- Safe to run more than once.
-- ============================================================

-- 1) Per-user key/value store (the tool's personal cloud storage).
create table if not exists kv_store (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  k text not null,
  v text,
  updated_at timestamptz not null default now(),
  primary key (user_id, k)
);
alter table kv_store enable row level security;
drop policy if exists kv_own on kv_store;
create policy kv_own on kv_store for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 2) Teams (companies) + membership.
create table if not exists companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  join_code text not null unique,
  created_by uuid not null default auth.uid(),
  created_at timestamptz not null default now()
);
create table if not exists company_members (
  company_id uuid not null references companies(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text,
  role text not null default 'member',
  joined_at timestamptz not null default now(),
  primary key (company_id, user_id)
);

-- 3) Team-shared key/value store (leads, projects, pricing bundle, models).
create table if not exists team_kv (
  company_id uuid not null references companies(id) on delete cascade,
  k text not null,
  v text,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid(),
  primary key (company_id, k)
);

-- 4) Membership check used by the policies.
create or replace function bb_is_member(cid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from company_members
    where company_id = cid and user_id = auth.uid()
  );
$$;

alter table companies enable row level security;
alter table company_members enable row level security;
alter table team_kv enable row level security;

drop policy if exists companies_select on companies;
create policy companies_select on companies for select to authenticated
  using (bb_is_member(id) or created_by = auth.uid());
drop policy if exists companies_insert on companies;
create policy companies_insert on companies for insert to authenticated
  with check (created_by = auth.uid());

drop policy if exists members_select on company_members;
create policy members_select on company_members for select to authenticated
  using (user_id = auth.uid() or bb_is_member(company_id));
-- the team creator seeds their own owner row; everyone else joins via the
-- bb_join_company() function below (which runs with elevated rights)
drop policy if exists members_creator_insert on company_members;
create policy members_creator_insert on company_members for insert to authenticated
  with check (
    user_id = auth.uid()
    and exists (select 1 from companies c where c.id = company_id and c.created_by = auth.uid())
  );
drop policy if exists members_leave on company_members;
create policy members_leave on company_members for delete to authenticated
  using (user_id = auth.uid());

drop policy if exists team_kv_members on team_kv;
create policy team_kv_members on team_kv for all to authenticated
  using (bb_is_member(company_id)) with check (bb_is_member(company_id));

-- 5) Join a team with its join code (bypasses RLS safely).
create or replace function bb_join_company(code text, member_email text default null)
returns json language plpgsql security definer set search_path = public as $$
declare c companies%rowtype;
begin
  select * into c from companies where join_code = upper(trim(code));
  if c.id is null then
    return json_build_object('ok', false, 'error', 'No team found with that join code.');
  end if;
  insert into company_members (company_id, user_id, email, role)
  values (c.id, auth.uid(), member_email, 'member')
  on conflict (company_id, user_id) do nothing;
  return json_build_object('ok', true, 'company_id', c.id, 'name', c.name);
end $$;
grant execute on function bb_join_company(text, text) to authenticated;
