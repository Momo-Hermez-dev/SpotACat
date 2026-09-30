# SpotACat MVP Data Model

## Principles

1. A `cat` is a discovered animal/entity; a `cat_sighting` is one observation.
2. A new submission may create a new cat without proving identity.
3. Exact submitted location is private; public map location is derived and coarse.
4. Supabase Auth owns identity; `profiles` stores product-facing profile data.
5. MVP stores only data required for discovery, collection, photos, and reports.

## MVP tables

### `profiles`

- `id uuid primary key references auth.users(id) on delete cascade`
- `display_name text not null`
- `avatar_path text null`
- `city text null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Index: optional city index only if profile discovery is introduced; do not make profiles publicly searchable in MVP.

### `areas`

- `id uuid primary key default gen_random_uuid()`
- `name text not null`
- `slug text not null unique`
- `city text not null`
- `boundary geometry(MultiPolygon, 4326) or a server-maintained geography equivalent`
- `created_at timestamptz not null default now()`

Indexes: unique `slug`; spatial index on boundary if PostGIS is enabled. Areas are curated/reference data and should be admin-managed.

### `cats`

- `id uuid primary key default gen_random_uuid()`
- `display_name text null` — user-provided label, not a verified identity
- `description text null`
- `status text not null default 'active'` — `active`, `hidden`, `merged`
- `merged_into_cat_id uuid null references cats(id)`
- `created_by uuid null references profiles(id) on delete set null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Indexes: `status`; `merged_into_cat_id`; `created_at desc`.

### `cat_sightings`

- `id uuid primary key default gen_random_uuid()`
- `cat_id uuid not null references cats(id) on delete cascade`
- `spotted_by uuid not null references profiles(id) on delete restrict`
- `area_id uuid null references areas(id) on delete set null`
- `observed_at timestamptz not null default now()`
- `public_latitude numeric(8,5) not null`
- `public_longitude numeric(8,5) not null`
- `city text not null`
- `concern text null` — controlled values such as `needs_help`; not a diagnosis
- `status text not null default 'visible'` — `visible`, `hidden`, `under_review`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`

Private exact coordinates should live in a restricted `sighting_private_locations` table or an equivalent server-only store, not in this public-facing row.

Indexes: `(status, observed_at desc)`, `(city, observed_at desc)`, `area_id`, and a PostGIS point/spatial index on public coordinates if geography queries are used. Add a bounded query strategy; do not allow unrestricted map scans.

### `sighting_private_locations`

- `sighting_id uuid primary key references cat_sightings(id) on delete cascade`
- `exact_latitude numeric(9,6) not null`
- `exact_longitude numeric(9,6) not null`
- `accuracy_meters numeric null`
- `captured_at timestamptz null`
- `created_at timestamptz not null default now()`

This table is not exposed to anon/authenticated client roles. Access is server/admin-only and may be omitted entirely if exact coordinates are not operationally needed after projection.

### `photos`

- `id uuid primary key default gen_random_uuid()`
- `sighting_id uuid not null references cat_sightings(id) on delete cascade`
- `uploaded_by uuid not null references profiles(id) on delete restrict`
- `storage_path text not null unique`
- `thumbnail_path text null unique`
- `mime_type text not null`
- `byte_size integer not null`
- `width integer not null`
- `height integer not null`
- `processing_status text not null default 'pending'` — `pending`, `ready`, `rejected`, `deleted`
- `created_at timestamptz not null default now()`
- `deleted_at timestamptz null`

Indexes: `(sighting_id, created_at)`, `(uploaded_by, created_at desc)`, `processing_status`.

### `reports`

- `id uuid primary key default gen_random_uuid()`
- `reported_by uuid not null references profiles(id) on delete restrict`
- `sighting_id uuid null references cat_sightings(id) on delete set null`
- `photo_id uuid null references photos(id) on delete set null`
- `category text not null` — `inappropriate_image`, `private_location`, `personal_information`, `spam`, `animal_welfare`, `other`
- `details text null`
- `status text not null default 'open'` — `open`, `reviewing`, `resolved`, `dismissed`
- `moderator_id uuid null references profiles(id) on delete set null`
- `resolution_note text null`
- `created_at timestamptz not null default now()`
- `resolved_at timestamptz null`

Indexes: `(status, created_at)`, `reported_by`, `sighting_id`, `photo_id`. A check constraint should require at least one target. Consider a dedupe constraint for an open report by the same user/target/category.

## Future tables

Add only when behavior is defined and tested:

- `achievements`: stable achievement definitions and versioned criteria.
- `user_achievements`: idempotent unlock records with `user_id`, `achievement_id`, and `unlocked_at`.
- `cat_aliases` or a merge history table: auditable identity changes.
- `activity_events`: only if derived activity cannot meet product needs.
- `integration_exports`: outbound Cat Distribution System handoff state and idempotency.

## Relationships

```text
auth.users 1--1 profiles
profiles 1--many cats (created_by)
profiles 1--many cat_sightings (spotted_by)
cats 1--many cat_sightings
areas 1--many cat_sightings
cat_sightings 1--many photos
cat_sightings 1--many reports
photos 1--many reports
cat_sightings 1--1 sighting_private_locations
```

Counters such as cats spotted, areas explored, and recent activity should initially be derived from visible sightings with scoped queries. Denormalize only after measured performance evidence.

## Identity uncertainty

MVP should not require a `cat` to be globally unique by appearance or name. `display_name` is a label and may be null or duplicated. A future merge operation must be admin-audited and preserve the original sighting records. This makes the system honest about uncertain identification while retaining a path to richer collections later.
