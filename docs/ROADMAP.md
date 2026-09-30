# SpotACat Production Roadmap

## Phase 2 — Repository/architecture preparation

**Objective:** Create stable domain, data, validation, and component boundaries without changing the product experience.

**Likely files:** `app/page.tsx`, new `components/`, `lib/domain/types.ts`, `lib/domain/validation.ts`, `lib/data/mock.ts`, `lib/location/privacy.ts`, tests, and `package.json`.

**Dependencies:** Existing Next.js/TypeScript stack.

**Acceptance criteria:** Separate `Cat`/`CatSighting` contracts exist; map/detail/spotting components accept typed props; mock data implements the contracts; privacy and draft validation have unit coverage; responsive QA covers the documented viewport/browser matrix; `npm run build` remains green.

**Risks:** Over-splitting a small prototype or accidentally redesigning the UI. Keep this phase behavior-preserving.

## Phase 3 — Supabase database + RLS

**Objective:** Create the small MVP schema and enforce database-level isolation.

**Likely files:** `supabase/migrations/*.sql`, `lib/supabase/server.ts`, `lib/supabase/client.ts`, `lib/data/sightings.ts`, environment configuration.

**Dependencies:** Supabase project, reviewed schema, PostGIS decision.

**Acceptance criteria:** Profiles, cats, sightings, areas, photos, reports, and private location storage exist; indexes and constraints are applied; RLS policies and negative tests pass; no service-role credential reaches client bundles.

**Risks:** Accidental public exact coordinates, recursive policies, and migrations that cannot be rolled back.

## Phase 4 — Authentication

**Objective:** Add Supabase Auth and session-aware navigation/writes.

**Likely files:** `app/auth/*`, `middleware`/proxy if required, Supabase SSR helpers, profile components, route protection boundaries.

**Dependencies:** Phase 3 profiles/RLS and environment-scoped redirect URLs.

**Acceptance criteria:** Sign-in/sign-out works in preview and production environments; server reads use the authenticated session; unauthenticated users can explore public content but cannot submit or report; own profile updates are scoped.

**Risks:** Cookie/redirect configuration and confusing auth prompts in the spotting flow.

## Phase 5 — Real image storage

**Objective:** Replace the no-op upload step with a safe Supabase Storage pipeline.

**Likely files:** `components/spotting/spot-cat-flow.tsx`, upload route/action, `lib/media/image-validation.ts`, storage policies, photo queries.

**Dependencies:** Auth, storage bucket, photo schema.

**Acceptance criteria:** JPEG/PNG/WebP uploads are validated, EXIF is removed, derivatives are generated, photo rows link to sightings, failed uploads clean up, and only approved derivatives are displayed.

**Risks:** Orphaned objects, large files, malicious content, and mobile camera compatibility.

## Phase 6 — Real map

**Objective:** Replace the CSS map placeholder behind a provider-neutral map adapter.

**Likely files:** `components/map/map-surface.tsx`, `components/map/cat-marker.tsx`, map provider module, environment config.

**Dependencies:** Privacy-safe public coordinate contract from Phase 3 and provider/style selection.

**Acceptance criteria:** Markers, clustering, selection, viewport changes, attribution, and mobile performance work; map tokens are public-only; no exact location is rendered; phone portrait/landscape and tablet/desktop layouts pass responsive QA without overflow.

**Risks:** Tile cost, token restrictions, hydration, marker performance, and accessibility.

## Phase 7 — Real cat sightings

**Objective:** Wire map, detail, explore, collection, and spotting confirmation to database data.

**Likely files:** `app/page.tsx`, server data functions, `components/cats/*`, `components/spotting/*`, API/server actions.

**Dependencies:** Auth, photos, map adapter, RLS.

**Acceptance criteria:** A signed-in user can submit a sighting, see a confirmation, and see the privacy-safe result on the map; cat creation is separate from sighting semantics; counters derive from visible records.

**Risks:** Duplicate submissions, stale map cache, and confusing cat identity with observation identity.

## Phase 8 — Location privacy

**Objective:** Harden exact/public location separation and nearby discovery.

**Likely files:** `lib/location/privacy.ts`, migration for private location storage, sighting creation action, map/nearby queries, privacy tests.

**Dependencies:** Real sighting writes and map queries.

**Acceptance criteria:** Exact coordinates are never client-readable; public points are snapped/fuzzed; radius and bbox inputs are bounded; sensitive areas use stricter precision; EXIF GPS is removed.

**Risks:** Re-identification through repeated queries or sparse datasets.

## Phase 9 — Reports/moderation

**Objective:** Add user reporting and the minimum admin queue.

**Likely files:** report dialog/form, `app/admin/reports/*`, report actions, moderation audit model/policies.

**Dependencies:** Auth, sightings/photos, admin role model.

**Acceptance criteria:** All required categories submit successfully; reporters cannot read other reports; admins can hide/redact/resolve; moderation actions are audited.

**Risks:** Exposing private evidence or allowing untrusted admin role escalation.

## Phase 10 — Game/collection persistence

**Objective:** Persist the basic collection experience without expanding scope.

**Likely files:** collection queries/components, derived counter utilities, optional achievement migrations only after product rules are approved.

**Dependencies:** Stable sightings and profile data.

**Acceptance criteria:** Cats spotted, areas explored, recent activity, and collection are accurate for the current user; duplicate/retry behavior is idempotent; achievements remain derived unless a clear persistence requirement exists.

**Risks:** Counter drift from denormalization and premature gamification schema.

## Phase 11 — Testing/security audit

**Objective:** Validate critical user journeys and security boundaries.

**Likely files:** unit/component/integration/E2E test directories, CI workflow, RLS test fixtures, dependency scripts.

**Dependencies:** All user-facing MVP flows.

**Acceptance criteria:** Unit validation, component interaction, RLS/storage integration, and the complete E2E journey pass in preview; security review confirms secrets, location, uploads, and reports are protected.

**Risks:** Tests coupled to visual implementation or production data.

## Phase 12 — Production deployment

**Objective:** Launch through GitHub -> Vercel -> Supabase with operational safeguards.

**Likely files:** Vercel project settings, environment configuration, migration runbook, headers/rate limiting configuration, monitoring setup.

**Dependencies:** Completed security audit, production Supabase project, map provider billing/limits.

**Acceptance criteria:** Preview and production are isolated; migrations are reviewed and backed up; domains/redirects work; monitoring and alerts exist; rollback procedure is documented; no server secret is exposed to the client.

**Risks:** Environment drift, provider quotas, migration timing, and unmonitored abuse.

## Recommended next step

Start Phase 2 only. Extract contracts and validation while preserving the current mocked UI. Do not connect Supabase until `Cat`/`CatSighting`, public/private location, photo, and report contracts are reviewed and tested.
