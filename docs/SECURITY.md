# SpotACat Security and Privacy Plan

## Trust boundaries

The browser is untrusted. It may submit a draft, coordinates, file metadata, or a requested cat id, but the server must derive the authenticated user, validate every field, enforce ownership, and calculate public projections. Supabase anon keys may be public; service-role keys must remain server-only.

## RLS policy plan

### Profiles

- Authenticated users may read only the profile fields intended for public attribution, if that product behavior is enabled.
- A user may insert/update/delete only their own profile where `profiles.id = auth.uid()`.
- No user may change another user's identity, moderation role, or internal fields.

### Cats

- Public/authorized users may read cats whose status is `active` and whose visible sightings exist.
- Authenticated users may create a cat only through a server action or tightly validated insert path.
- Ordinary users may not arbitrarily edit or delete a cat after it is referenced by sightings.
- Admins may hide, merge, or restore cats. Merges preserve an audit trail and do not rewrite historical authorship.

### Sightings

- Visible sightings are readable through a privacy-safe view or API projection, not by exposing private location columns.
- An authenticated user may insert a sighting only with their own `spotted_by` value, ideally through a server action that also creates the cat and public projection.
- A user may update/delete only their own pending or recently-created sighting under explicit product rules; they cannot update ownership, moderation status, or public coordinates directly.
- Admins may hide, redact, or restore sightings.

### Photos and storage

- Users may upload only into paths scoped to their own id and an authorized sighting.
- A user may delete only photos they uploaded, subject to moderation retention rules.
- Reads should expose only processed, approved derivatives; quarantined/original objects are not public.
- Storage paths must not contain raw user filenames or private coordinates.

### Reports

- Authenticated users may create reports targeting visible content.
- Users may read only their own report receipt/status, if that is needed.
- Users may not list, update, or delete other users' reports.
- Moderators/admins may read and update the moderation queue, with audit logging.

## Admin model

Use a server-checked role claim or a protected admin table; never trust a client-supplied `is_admin` field. Admin actions should be explicit and logged: hide content, redact location, reject photo, resolve report, merge cats, and restore content. RLS must protect the data even if an admin UI is bypassed.

## Location privacy

Exact coordinates must never be returned to the browser or included in public PostgREST views. Store them separately with no client role access, or do not retain them after deriving the public point. Public coordinates should be rounded/snapped and queried with caps and clustering. Tune precision downward for private homes, schools, shelters, and other sensitive areas. Remove GPS EXIF before any public derivative is created.

Avoid API shapes that let a user triangulate an exact point by repeatedly querying tiny bounding boxes. Clamp radius, add result caps, use stable privacy projections, and consider minimum aggregation thresholds.

## Upload security

Allow only JPEG, PNG, and WebP after checking file signature, not merely extension or browser MIME. Enforce byte and pixel limits, reject SVG/executable content, recompress images, strip EXIF, randomize object names, and scan or moderate content before public display. Clean up orphan objects when DB creation fails. Rate-limit upload and sighting creation.

## Abuse and safety controls

- Rate-limit authentication, uploads, reports, and sighting writes per user/IP.
- Validate text length and normalize user input; escape on render and avoid unsafe HTML.
- Do not expose private email, exact home location, or hidden moderation notes.
- Include report categories for inappropriate images, private locations, personal information, spam, animal welfare, and other.
- Use observation-focused copy: do not encourage approaching, feeding, chasing, or claiming unfamiliar animals.
- Provide a takedown/redaction path for accidental people, private properties, schools, businesses, and vulnerable individuals.
- Treat “needs help” as a concern signal, not a declaration that a cat is abandoned.

## Environment separation

Use separate Supabase and Vercel environment values for development, preview, and production. Only `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, and explicitly public map configuration belong in browser-exposed variables. Service-role, webhook, image-processing, and integration secrets are server-only.

## Mobile and responsive privacy considerations

Responsive layouts must not reveal sensitive locations through accidental overflow, screenshots, or touch-only affordances. Exact coordinates remain server-side regardless of viewport. Bottom sheets and full-screen mobile panels must trap or clearly manage focus when implemented, support Escape where applicable, and keep report/redaction actions reachable above browser safe areas. Camera uploads must use the same validation and EXIF stripping pipeline on mobile as on desktop.

## Security acceptance criteria before launch

- RLS tests prove cross-user reads/writes fail.
- Exact coordinates and EXIF GPS cannot be retrieved through any client role or response.
- Uploads cannot publish unprocessed originals.
- Reporters cannot enumerate reports.
- Admin actions are role-checked and audited.
- Preview and production credentials/data are isolated.
- Headers, rate limiting, validation, and error redaction are in place.
