-- MK Itinerary Maker: agent accounts, profiles and saved trips (Supabase / Postgres)
create sequence if not exists public.agent_code_seq start 1001;

create table public.agents (
  id uuid primary key references auth.users(id) on delete cascade,
  agent_code text unique not null default ('MK' || nextval('public.agent_code_seq')),
  name text,
  company text,
  phone text,
  email text,
  profile jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.trips (
  id text primary key,
  agent_id uuid not null default auth.uid() references public.agents(id) on delete cascade,
  title text,
  client text,
  data jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index trips_agent_idx on public.trips(agent_id, updated_at desc);

alter table public.agents enable row level security;
alter table public.trips enable row level security;

create policy "agent reads own row" on public.agents for select to authenticated using ((select auth.uid()) = id);
create policy "agent updates own row" on public.agents for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "agent manages own trips" on public.trips for all to authenticated using ((select auth.uid()) = agent_id) with check ((select auth.uid()) = agent_id);

-- agents can edit their details but never their Agent ID
revoke insert, update, delete on public.agents from anon, authenticated;
grant select on public.agents to authenticated;
grant update (name, company, phone, profile, updated_at) on public.agents to authenticated;
revoke all on public.trips from anon;
grant select, insert, update, delete on public.trips to authenticated;

-- create the agent row (with its NK Agent ID) when someone registers
create or replace function public.handle_new_agent()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.agents (id, name, company, phone, email)
  values (new.id, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'company',
          new.raw_user_meta_data->>'phone', new.email);
  return new;
end $$;
revoke execute on function public.handle_new_agent() from public, anon, authenticated;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_agent();
