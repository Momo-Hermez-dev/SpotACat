create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_length check (username is null or char_length(username) between 3 and 32),
  constraint profiles_username_format check (username is null or username ~ '^[a-zA-Z0-9_]+$')
);

create table public.areas (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  city text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name, city),
  constraint areas_name_length check (char_length(name) between 1 and 80),
  constraint areas_city_length check (char_length(city) between 1 and 80)
);

create table public.cats (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete restrict,
  nickname text,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint cats_nickname_length check (nickname is null or char_length(nickname) between 1 and 80),
  constraint cats_description_length check (description is null or char_length(description) <= 2000)
);

create table public.cat_sightings (
  id uuid primary key default gen_random_uuid(),
  cat_id uuid not null references public.cats(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete restrict,
  photo_path text,
  note text,
  area_id uuid references public.areas(id) on delete set null,
  exact_latitude double precision,
  exact_longitude double precision,
  public_latitude double precision not null,
  public_longitude double precision not null,
  spotted_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint cat_sightings_note_length check (note is null or char_length(note) <= 2000),
  constraint cat_sightings_latitude_range check (exact_latitude is null or exact_latitude between -90 and 90),
  constraint cat_sightings_longitude_range check (exact_longitude is null or exact_longitude between -180 and 180),
  constraint cat_sightings_public_latitude_range check (public_latitude between -90 and 90),
  constraint cat_sightings_public_longitude_range check (public_longitude between -180 and 180)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete cascade,
  sighting_id uuid not null references public.cat_sightings(id) on delete cascade,
  reason text not null check (reason in ('inappropriate_image','private_location','personal_information','spam','animal_welfare','other')),
  description text,
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete set null,
  constraint reports_description_length check (description is null or char_length(description) <= 2000)
);

create index cats_created_by_idx on public.cats(created_by);
create index cat_sightings_cat_id_idx on public.cat_sightings(cat_id);
create index cat_sightings_user_id_idx on public.cat_sightings(user_id);
create index cat_sightings_area_id_idx on public.cat_sightings(area_id);
create index cat_sightings_created_at_idx on public.cat_sightings(created_at desc);
create index cat_sightings_public_location_idx on public.cat_sightings(public_latitude, public_longitude);
create index reports_reporter_id_idx on public.reports(reporter_id);
create index reports_sighting_id_idx on public.reports(sighting_id);
create index reports_status_idx on public.reports(status);

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at before update on public.profiles for each row execute function public.set_updated_at();
create trigger areas_set_updated_at before update on public.areas for each row execute function public.set_updated_at();
create trigger cats_set_updated_at before update on public.cats for each row execute function public.set_updated_at();

create view public.public_sightings with (security_invoker = true) as
select s.id, s.cat_id, c.nickname, c.description, s.photo_path, s.public_latitude, s.public_longitude, s.area_id, a.name as area_name, a.city as area_city, s.spotted_at, s.created_at
from public.cat_sightings s
join public.cats c on c.id = s.cat_id
left join public.areas a on a.id = s.area_id;

alter table public.profiles enable row level security;
alter table public.areas enable row level security;
alter table public.cats enable row level security;
alter table public.cat_sightings enable row level security;
alter table public.reports enable row level security;

create policy profiles_public_read on public.profiles for select to authenticated using (true);
create policy profiles_insert_own on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy profiles_update_own on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy areas_public_read on public.areas for select to anon, authenticated using (true);

create policy cats_public_read on public.cats for select to anon, authenticated using (true);
create policy cats_insert_own on public.cats for insert to authenticated with check ((select auth.uid()) = created_by);
create policy cats_update_own on public.cats for update to authenticated using ((select auth.uid()) = created_by) with check ((select auth.uid()) = created_by);
create policy cats_delete_own on public.cats for delete to authenticated using ((select auth.uid()) = created_by);

create policy sightings_public_read on public.cat_sightings for select to anon, authenticated using (true);
create policy sightings_insert_own on public.cat_sightings for insert to authenticated with check ((select auth.uid()) = user_id);
create policy sightings_update_own on public.cat_sightings for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy sightings_delete_own on public.cat_sightings for delete to authenticated using ((select auth.uid()) = user_id);

create policy reports_insert_own on public.reports for insert to authenticated with check ((select auth.uid()) = reporter_id);
create policy reports_select_own on public.reports for select to authenticated using ((select auth.uid()) = reporter_id);
create policy reports_update_own on public.reports for update to authenticated using ((select auth.uid()) = reporter_id) with check ((select auth.uid()) = reporter_id);

revoke all on public.public_sightings from anon, authenticated;
grant select on public.public_sightings to anon, authenticated;

insert into public.areas (name, city, description) values
  ('Observatory', 'Cape Town', 'Lively streets and sunny steps.'),
  ('Woodstock', 'Cape Town', 'Creative corners with plenty of curious cats.'),
  ('Gardens', 'Cape Town', 'Leafy blocks and quiet garden walls.')
on conflict (name, city) do nothing;

-- Exact coordinates are intentionally excluded from the public view. The trusted
-- server-side spotting flow must fuzz or otherwise derive public_* before insert.
-- Direct client writes should later be replaced by a server-controlled RPC.

comment on column public.cat_sightings.exact_latitude is 'Private input; never expose through public queries.';
comment on column public.cat_sightings.exact_longitude is 'Private input; never expose through public queries.';
comment on column public.cat_sightings.public_latitude is 'Server-derived approximate coordinate for map display.';
comment on column public.cat_sightings.public_longitude is 'Server-derived approximate coordinate for map display.';

-- Future hardening: move inserts behind a SECURITY DEFINER RPC with a pinned
-- search_path that computes public coordinates from the exact input.
