# SpotACat Responsive QA

## Viewport strategy

SpotACat uses fluid sizing with content-driven transitions rather than device-specific layouts. The baseline is 320px wide, with comfortable touch targets, readable text, and no horizontal page overflow. The map is the dominant phone surface; desktop adds a navigation rail and an anchored detail panel. Shared content is constrained with `max-width` while the map may use the available viewport.

The mobile navigation and map controls account for `env(safe-area-inset-bottom)` and `env(safe-area-inset-top)`. Interactive controls should remain at least 44px square. Focus-visible outlines, semantic buttons, visible labels, and reduced-motion behavior are required for all new controls.

## Layout rules

- Phone: map fills the available content area; selected cats open a bottom sheet with a capped height and internal scrolling.
- Large phone/small tablet: preserve the map-first flow and allow cards to breathe without fixed widths.
- Tablet: detail can overlay the map as a contained panel when space permits.
- Laptop/desktop: use the navigation rail and a right-side detail panel; keep reading surfaces constrained.
- Wide desktop: do not stretch text-heavy views indefinitely; let the map absorb spare space.
- Landscape: controls must not depend on vertical room; bottom navigation and sheets must remain scrollable above the safe area.
- Images: use stable aspect ratios and `object-fit: cover`; never rely on a fixed pixel image size.

## Map behavior

Markers are buttons with accessible names and touch-friendly dimensions. Hover labels are enhancement only; selecting a marker must work by touch and keyboard. Floating layer/location controls have accessible labels. Detail sheets must support a clear close action, internal scrolling, and focus management when converted to a production dialog/sheet.

## Spot-a-cat flow

The four-step flow must remain single-column and scrollable on phones, avoid horizontal overflow, preserve draft state between steps, and expose labels/errors to assistive technology. Camera/file inputs must use browser-supported capture and the same validation pipeline on every device. Primary actions remain reachable above the mobile navigation and safe area.

## Accessibility requirements

Use native semantic controls before adding ARIA. Every icon-only action has an accessible name. Focus-visible states must remain visible against the paper, dark, lime, and map surfaces. Respect `prefers-reduced-motion`. Do not make essential information hover-only. Test keyboard Tab/Shift+Tab, Enter/Space activation, Escape for dismissible panels, browser zoom, and larger text settings.

## Viewport QA matrix

Test at: **320, 360, 375, 390, 414, 430, 600, 768, 820, 1024, 1280, 1440, 1920, and 2560px** wide. At each width, check both portrait and landscape where meaningful, plus browser zoom at 200%.

Check for horizontal overflow, clipped headings, map/detail collisions, reachable controls, readable labels, stable image cropping, sheet overflow, and form progression.

## Browser/device matrix

- iOS Safari: small/standard phone portrait and landscape; camera/file affordance and safe areas.
- Android Chrome: phone portrait and landscape; touch controls and browser UI overlap.
- Desktop Chrome: keyboard navigation, zoom, standard and wide desktop.
- Desktop Safari: typography, focus, safe-area CSS fallback, responsive panels.
- Desktop Firefox: form controls, overflow, reduced motion.
- Edge: practical smoke pass for navigation and map/detail interaction.

Browser automation was not available during the original architecture audit. The current validation should record the actual browser/viewport used rather than claiming coverage that was not run.

## Release gate

A responsive change is complete only when `npm run build` and available lint/type checks pass, the mobile 390x525 surface has no overflow or clipped controls, and the documented matrix has either been exercised or clearly marked as pending.
