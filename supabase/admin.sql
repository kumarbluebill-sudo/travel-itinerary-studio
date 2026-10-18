-- MK Itinerary Maker: PDF download tracking and the admin page (run once in the Supabase SQL Editor, after schema.sql)

-- one row each time an agent presses Download PDF
create table if not exists public.pdf_downloads (
  id bigint generated always as identity primary key,
  agent_id uuid not null default auth.uid() references public.agents(id) on delete cascade,
  trip_id text,
  trip_title text,
  destination text,
  created_at timestamptz not null default now()
);
create index if not exists pdf_downloads_agent_idx on public.pdf_downloads(agent_id, created_at desc);
alter table public.pdf_downloads enable row level security;
create policy "agent logs own downloads" on public.pdf_downloads for insert to authenticated with check ((select auth.uid()) = agent_id);
revoke all on public.pdf_downloads from anon, authenticated;
grant insert (agent_id, trip_id, trip_title, destination) on public.pdf_downloads to authenticated;

-- who may open admin.html. No policies and no grants, so nobody can read or change this list from the browser.
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.admins enable row level security;
revoke all on public.admins from anon, authenticated;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.admins where user_id = (select auth.uid()));
$$;
revoke execute on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- everything the admin page shows, in one call. Refuses anyone who is not in public.admins.
-- Admin accounts are left out of every count and list, so only real agencies show.
create or replace function public.admin_overview()
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if not public.is_admin() then
    raise exception 'Only the MK Solutions admin can open this page.' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'agents', coalesce((
      select jsonb_agg(row_to_json(r) order by r.signed_up desc) from (
        select a.agent_code, a.name, a.company, a.phone, a.email,
               a.created_at as signed_up,
               u.email_confirmed_at is not null as confirmed,
               u.last_sign_in_at as last_login,
               (select count(*) from public.trips t where t.agent_id = a.id) as trips,
               (select count(*) from public.pdf_downloads d where d.agent_id = a.id) as downloads,
               (select max(d.created_at) from public.pdf_downloads d where d.agent_id = a.id) as last_download
        from public.agents a join auth.users u on u.id = a.id
        where not exists (select 1 from public.admins x where x.user_id = a.id)
      ) r), '[]'::jsonb),
    'downloads', coalesce((
      select jsonb_agg(row_to_json(r) order by r.at desc) from (
        select d.created_at as at, a.agent_code, a.company, d.trip_title, d.destination
        from public.pdf_downloads d join public.agents a on a.id = d.agent_id
        where not exists (select 1 from public.admins x where x.user_id = d.agent_id)
        order by d.created_at desc limit 200
      ) r), '[]'::jsonb),
    'download_days', coalesce((
      select jsonb_agg(jsonb_build_object('day', day, 'n', n) order by day) from (
        select (created_at at time zone 'Asia/Kolkata')::date as day, count(*) as n
        from public.pdf_downloads d where created_at > now() - interval '30 days'
          and not exists (select 1 from public.admins x where x.user_id = d.agent_id) group by 1
      ) r), '[]'::jsonb),
    'signup_days', coalesce((
      select jsonb_agg(jsonb_build_object('day', day, 'n', n) order by day) from (
        select (created_at at time zone 'Asia/Kolkata')::date as day, count(*) as n
        from public.agents a where created_at > now() - interval '30 days'
          and not exists (select 1 from public.admins x where x.user_id = a.id) group by 1
      ) r), '[]'::jsonb),
    'total_downloads', (select count(*) from public.pdf_downloads d
      where not exists (select 1 from public.admins x where x.user_id = d.agent_id))
  ) into result;
  return result;
end $$;
revoke execute on function public.admin_overview() from public, anon;
grant execute on function public.admin_overview() to authenticated;

-- make yourself the admin: register on the tool first, then run this line with your login email
-- insert into public.admins (user_id) select id from auth.users where email = 'you@example.com';
