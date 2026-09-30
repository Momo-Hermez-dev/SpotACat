# SpotACat Architecture Audit

## Scope and current status

This document audits the committed frontend prototype on branch `v0/spotacat-prototype` (commit `ab85f8a`). It is intentionally a blueprint only: no backend, authentication, Supabase, map provider, or production tables are introduced here.

## Repository audit

### Stack and configuration

- Framework: Next.js App Router, currently resolved from `next: latest` (Next.js 16-compatible project configuration).
- Runtime/UI: React, TypeScript strict mode, client-rendered interactive page.
- Package manager: npm, evidenced by `package-lock.json` lockfile version 3 and no `packageManager` field.
- Styling: Tailwind CSS v4 through `@tailwindcss/postcss`, plus a small CSS token layer in `app/globals.css`.
- Icons: `lucide-react`.
- Fonts: Google Fonts imports for DM Sans and Space Grotesk.
- Aliases: `@/*` maps to the repository root in `tsconfig.json`.
- Scripts: `dev`, `build`, `start`, `lint`. No test script exists.
- Build: `npm run build` passes per the existing project record.
- Lint/type checking: strict TypeScript is configured; lint is declared but there is no separate typecheck script and no test runner.
- Assets: no local image assets; cat images are remote Unsplash URLs in mock data.
- Environment variables: no application env file or runtime integration is currently required. `NEXT_PUBLIC_DEV_SUPABASE_REDIRECT_URL` is available in the project environment but is not used by this prototype.
- Deployment: no `vercel.json`, CI workflow, database migration directory, or provider configuration is present. The repository is GitHub-backed and intended for Vercel deployment.

### Routes and feature locations

There is one route: `/`, rendered by `app/page.tsx`. The page is a client component because it owns view, selection, wizard, and toast state. There are no route groups, API routes, server actions, loading/error boundaries, or nested layouts.

The current feature map is:

- Map-first home: `MapView` in `app/page.tsx`.
- Mock sightings and domain shape: `CatSighting` type and `cats` array in `app/page.tsx`.
- Marker interaction: buttons inside `MapView`.
- Cat detail: `Detail` component.
- Explore: `ExploreView`.
- Collection: `CollectionView` and `Stat`.
- Profile activity: `ProfileView`.
- Spot-a-cat wizard: `SpotView`, controlled by `spotStep` in `Home`.
- Success state: `newCat` state and inline confirmation panel in `Home`.
- Responsive navigation: desktop `aside` and mobile bottom navigation in `Home`.
- Styling and map placeholder: `app/globals.css` and Tailwind classes in `app/page.tsx`.

There are no shared components, utilities, hooks, state stores, data-access modules, tests, or generated API clients yet.

## Responsive architecture requirement

Responsiveness is a first-class product constraint, not a finishing pass. The map remains the primary surface on phones, with thumb-friendly floating controls and a bottom-sheet detail panel; tablets may overlay detail content; laptops and desktops use a navigation rail with a constrained detail panel. Layouts are content-driven and must avoid horizontal overflow from 320px through wide desktop. All controls use keyboard-visible focus, touch targets of at least 44px, safe-area padding where controls meet viewport edges, semantic labels, and reduced-motion fallbacks. Images use stable aspect ratios and `object-fit` so cat photography never changes layout unexpectedly.

The responsive QA matrix and browser coverage are maintained in `docs/RESPONSIVE.md`. Backend work must preserve these interaction contracts when replacing mocked data.

## Frontend architecture assessment

The prototype is appropriate as a visual baseline and is intentionally simple. A backend can be added incrementally, but the current single-file client boundary should not become the production architecture.

### Keep

- The map/detail relationship is clear: markers emit a selected domain object and `Detail` renders it.
- The spotting wizard is already a discrete component with a step contract.
- Navigation is represented by a small typed `View` union.
- The UI is responsive and has a coherent mobile primary surface.
- The mock object already distinguishes a cat-like entity from metadata such as area, date, and number of sightings, even though it currently conflates a cat and a sighting.

### Refactor later

- Move domain types and mock fixtures into `lib/domain` and `lib/mock-data`.
- Split `Home` into shell/navigation, map surface, detail sheet, and page-level views.
- Replace repeated image/card markup with shared `CatCard`, `CatMarker`, `CatGrid`, and `StatCard` components.
- Extract the wizard's step state into a `SpotCatFlow` component and a typed draft model.
- Use a server component for initial map data and client components only for map interactions and forms.
- Introduce a data-access interface so mock and Supabase implementations have the same return shapes.
- Add a lightweight query/cache layer only when asynchronous data is introduced; do not add global state for server data prematurely.

### Change before backend integration

- Rename the current `CatSighting` type or replace it with separate `Cat` and `CatSighting` types. Production code must not treat an animal entity and an observation as the same row.
- Stop using client-owned numeric `x`/`y` map positions as the location model. The UI should consume map coordinates from a privacy-filtered location projection.
- Make the spotting flow produce a typed draft and submit through an explicit server boundary rather than simply changing local state.
- Remove direct remote image URLs from domain fixtures once production image records exist; use a media abstraction.
- Move the entire interactive surface out of one large `app/page.tsx` before adding auth and data fetching, so server/client boundaries remain understandable.

### Recommended target structure

```text
app/
  page.tsx                         # server entry, initial query and composition
  api/                             # only if route handlers are needed
components/
  app-shell.tsx
  map/map-surface.tsx
  map/cat-marker.tsx
  cats/cat-card.tsx
  cats/cat-detail-sheet.tsx
  spotting/spot-cat-flow.tsx
  collection/collection-view.tsx
lib/
  domain/types.ts
  domain/validation.ts
  data/mock.ts
  data/sightings.ts
  location/privacy.ts
  media/image-validation.ts
supabase/
  migrations/
  seed.sql
```

The exact file split can be gradual; the important boundary is domain/data/privacy logic outside presentational components.

## Production domain model

MVP requires: `profiles`, `cats`, `cat_sightings`, `areas`, `photos`, and `reports`. `achievements` and `user_achievements` should remain future-facing unless the first release requires persisted achievement unlocks. Supabase Auth supplies the user identity; an application `users` table is not necessary for MVP.

The key relationship is:

```text
Cat (discovered animal/entity)
  -> CatSighting (one observation at one time)
      -> Location (privacy-safe public projection)
      -> Photo (media attached to the observation)
```

A first submission should be allowed to create a new `cats` row and one `cat_sightings` row. The submitter does not need to prove it is the same physical animal as an existing cat. Later, moderation or an explicit merge workflow can associate additional sightings with an existing cat. This prevents false certainty and keeps MVP creation simple.

## Location architecture recommendation

Store the exact submitted coordinate only in a server-controlled, restricted field on `cat_sightings` (or a private companion table), never in a publicly selectable projection. On creation, the server validates the coordinate, strips EXIF GPS from images, derives an `area_id`, and creates a public coordinate by grid snapping plus small deterministic fuzzing. The public map and nearby queries use only the public coordinate and a coarse geography.

Recommended MVP policy:

- Accept latitude/longitude from the client only as untrusted input.
- Store exact coordinates encrypted or in a restricted `sighting_private_locations` table accessible only to trusted server/admin roles.
- Store `public_latitude` and `public_longitude` rounded to roughly 3 decimal places (about 100m) and snapped to a stable grid; never publish the original value.
- Derive `area_id` and `city` server-side from a controlled area dataset/geocoder.
- Use bounding-box or PostGIS distance queries against public coordinates for nearby results; do not expose an exact-address search endpoint.
- Do not display a marker when a sighting is too sparse or sensitive; aggregate/clusters should be the default at low zoom.

This offers a useful discovery map without making a user's home or a private animal's exact location recoverable from the public API. A later privacy review can tune the grid by area sensitivity.

## Image architecture

Current handling is display-only: `img` elements point at Unsplash URLs, and the wizard's upload button advances state without selecting a file.

Future pipeline:

```text
Camera/file input
 -> client type/size/dimension validation
 -> server-authorized upload token/path
 -> Supabase Storage quarantine
 -> server-side MIME/signature validation and image processing
 -> EXIF/GPS removal and recompression
 -> public/authorized derivative
 -> photos row linked to cat_sighting
```

MVP rules: accept JPEG, PNG, and WebP; cap the original request at 10 MB and processed dimensions at a reasonable maximum such as 4096px; generate a thumbnail and display derivative; randomize storage names; use paths scoped by `user_id` and `sighting_id`; never trust a filename or MIME header; reject SVG and executable formats; strip all EXIF, especially GPS; apply malware/content checks available in the chosen pipeline; delete storage objects and DB rows together where possible; maintain an orphan cleanup job for failed transactions. A `photos` row should track storage path, width, height, byte size, processing status, and deletion timestamp.

## API contract

Keep the first backend surface small and server-authorized:

| Operation | Auth | Input/output and rules |
|---|---|---|
| Get map sightings | Optional | `GET /api/sightings/map?bbox=&zoom=`; returns privacy-safe markers only, capped and clustered; validates bbox/zoom. |
| Get cat | Optional | `GET /api/cats/:id`; returns cat summary plus privacy-safe recent sightings and photos. |
| Get nearby sightings | Optional | `GET /api/sightings/nearby?lat=&lng=&radius=`; clamps radius, uses public coordinates, returns bounded results. |
| Create cat | Required | Server action or `POST /api/cats`; validates name/description policy; normally called as part of create sighting, not exposed as an unrestricted standalone write. |
| Create sighting | Required | `POST /api/sightings`; accepts cat draft, approximate location, time, photo reference, and concern flag; server creates/associates cat, strips location risk, and returns confirmation. |
| Upload photo | Required | `POST /api/photos/upload`; validates file and ownership, returns a temporary upload target or processed photo record. |
| Current profile | Required | `GET /api/profile`; returns own profile and safe counters. `PATCH` is scoped to the session user. |
| Collection | Required | `GET /api/me/collection`; returns the user's sightings/cats and counters, scoped server-side. |
| Report content | Required | `POST /api/reports`; accepts target, category, and optional note; returns only the reporter's receipt/id. |

Errors should use stable codes for validation, unauthenticated, forbidden, not found, rate limited, and moderation states. Every write revalidates ownership and input server-side; the browser is never trusted to supply `user_id`.

## Map provider recommendation

Use MapLibre for the first real map, with a hosted vector-tile/style provider selected separately. It supports custom markers, clustering, mobile performance, and provider portability without locking the rendering layer to Mapbox's commercial SDK. Mapbox has excellent hosted styles and developer ergonomics, but introduces stronger token/billing coupling and a more provider-specific architecture. MapLibre still requires a tile/style service and careful attribution; it does not eliminate those costs.

The map adapter should expose `setViewport`, marker/cluster data, selection, and nearby query callbacks. Keep provider-specific code behind `components/map/map-surface.tsx` so changing providers does not affect cat or sighting components. Do not install or configure either provider in this audit.

## Game layer

MVP persistence should support `cats_spotted`, `areas_explored`, recent activity, and a basic collection derived from sightings. Achievements can remain frontend-derived from those counters for the first release; adding achievement tables too early creates write and rules complexity without improving the core discovery loop. Add `achievements` and `user_achievements` only when unlock definitions, migrations, and replay/idempotency behavior are settled.

Explicitly out of MVP: leaderboards, social graphs, trading, messaging, AI recognition, and advanced gamification.

## Moderation and safety

Reports should support: `inappropriate_image`, `private_location`, `personal_information`, `spam`, `animal_welfare`, and `other`. The minimum admin workflow is an authenticated admin queue showing the report, target, evidence, status, moderator, and resolution note; moderators can hide a photo/sighting, redact a location, merge/unmerge cat records, or dismiss a report. Users can create reports and see their own submission receipt, but cannot read other reports.

Product safeguards: show observation-focused copy; discourage approaching, feeding, chasing, or claiming ownership of unfamiliar cats; avoid publishing exact homes, schools, or vulnerable locations; allow removal/redaction requests; blur or remove accidental people; never present a sighting as proof an animal is abandoned or lost. Rate-limit reports and submissions, and log moderation actions.

## Cat Distribution System integration boundary

Keep SpotACat standalone. Future handoff can use a stable `sighting_id`, optional `cat_id`, `photo_id`, coarse area, timestamps, concern category, and consented contact metadata. A future `needs_help` event or export contract can send a sanitized sighting to Cat Distribution System without sharing private coordinates or internal user identifiers. Do not couple schemas or auth systems now; treat any integration as an explicit outbound adapter with user consent and an idempotency key.

## Environment variables

Public client variables (future):

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_MAP_STYLE_URL` or provider public token, if required

Server-only variables (future):

- `SUPABASE_SERVICE_ROLE_KEY` or an equivalent trusted server credential, never sent to the browser
- `MAP_PROVIDER_SERVER_TOKEN`, only if server-side geocoding/tiles require one
- `IMAGE_PROCESSOR_TOKEN` or moderation provider credentials, if used
- `CAT_DISTRIBUTION_SYSTEM_WEBHOOK_SECRET`, only when the future integration exists

The existing `NEXT_PUBLIC_DEV_SUPABASE_REDIRECT_URL` is a development redirect configuration, not a database credential.

## Deployment architecture

```text
GitHub branch/PR
  -> Vercel preview deployment
  -> Next.js App Router
  -> Supabase Auth + PostgreSQL + Storage
  -> MapLibre client + selected tile/style provider
```

Use separate Supabase projects or clearly separated environments for preview and production. Keep public URL/anon key variables environment-scoped in Vercel; keep service credentials server-only. Preview deployments should use non-production data and redirect URLs. Production migrations should run from reviewed, ordered SQL migrations with backups and rollback notes. Add response headers and rate limits before launch.

## Testing strategy

Before backend integration, add unit tests for location rounding/privacy, sighting draft validation, file validation, counters, and stable error shapes; component tests for marker selection, detail sheet, wizard validation, collection rendering, and mobile navigation. Integration tests should later cover RLS, auth/session scoping, storage ownership, upload processing, and sighting creation. E2E should cover: open map -> explore -> open cat -> sign in -> spot cat -> upload photo -> choose location -> submit -> confirmation -> map visibility.

## Audit conclusion

The current prototype is a sound visual spike, not a production data architecture. The next implementation step should be Phase 2 preparation: extract domain/data contracts, split the client page at clear boundaries, add validation tests for the existing flow, and document the privacy-safe location projection before connecting Supabase. Do not add a database until those contracts are reviewed.

## Files inspected

`app/page.tsx`, `app/layout.tsx`, `app/globals.css`, `package.json`, `package-lock.json`, `tsconfig.json`, `postcss.config.mjs`, and `README.md`.

## Files created by this audit

`docs/ARCHITECTURE.md`, `docs/DATA_MODEL.md`, `docs/SECURITY.md`, and `docs/ROADMAP.md`.

## Existing issues found

- All interactive product logic and domain fixtures live in one large client component.
- `CatSighting` currently conflates cat identity and observation.
- Upload, location, search, layer, and locate controls are visual prototype interactions only.
- Remote image URLs and hardcoded counters are not production data sources.
- No tests, API layer, auth, RLS, storage pipeline, or deployment config exists yet.
- `npm run build` passes; browser verification was previously blocked by the sandbox's missing Next adapter, an environment limitation rather than an application error.

## Recommendation

Adopt a small Supabase schema centered on profiles, cats, sightings, areas, photos, and reports; protect exact locations server-side; use privacy-safe public projections; keep auth and storage separate from presentation; and bring real integrations in according to the roadmap rather than replacing the working prototype wholesale.
