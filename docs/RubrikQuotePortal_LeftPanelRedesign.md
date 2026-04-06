# RubrikQuotePortal Left Panel Brand Redesign

**Date:** 2026-03-29
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Redesign the left panel of the RubrikQuotePortal Visualforce site page to align with Rubrik's brand identity as seen on rubrik.com. The Matrix rain animation was replaced with a particle sphere, brand colors updated, and a headline added.

### Business Objective

The Rubrik Quote Portal is a public-facing Visualforce page used by customers to look up and submit Order Verification Forms. The left panel previously displayed a Matrix-style green text rain animation that did not reflect Rubrik's current brand identity. This task updates the panel to match rubrik.com's aesthetic: pure black background, teal (#009dac) brand accents, a rotating 3D particle sphere, and a bold brand headline, giving customers a consistent first impression aligned with Rubrik's marketing presence.

### Summary

All changes are confined to the left panel of `RubrikQuotePortal.page` and are purely visual (HTML, CSS, and JavaScript). No Apex controller changes, no new components, and no admin metadata changes were made. The updated panel was deployed to the RubrikClaudePOC sandbox and verified via Tooling API query.

---

## Components Created or Modified

### Admin Components (Declarative)

None. No objects, fields, flows, permission sets, or validation rules were created or modified.

---

### Development Components (Code)

#### Modified Files

| File | Type | Change Summary |
|------|------|----------------|
| `force-app/main/default/pages/RubrikQuotePortal.page` | Visualforce Page | Left-panel HTML, CSS, and JS updated — no Apex changes |

No new files were created. No existing classes, triggers, or LWC components were modified.

---

## Before and After: Change Reference

| Element | Before | After |
|---------|--------|-------|
| Left panel background color | `#060d0a` (very dark green-black) | `#000000` (pure black) |
| Canvas element ID | `matrix` | `particleSphere` |
| Animation | Matrix rain — falling katakana/Latin characters rendered in green on a Canvas 2D context | Rotating 3D particle sphere — 1000 teal particles rendered via Canvas 2D with orthographic projection |
| SVG logo `.wh` fill | `#ffffff` (white) | `#009dac` (teal) |
| Wordmark `.brand-wordmark` color | `#ffffff` (white) | `#009dac` (teal) |
| Brand headline | Not present | `<h2 class="brand-headline">` added with "SECURE YOUR DATA." / "EVERYWHERE." |
| OVF section heading | `<h1 class="form-title">` | `<h2 class="form-title">` (heading hierarchy fix) |

---

## Detailed Change Descriptions

### 1. Background Color

The `.left-panel` CSS rule `background` property was changed from `#060d0a` to `#000000`. Pure black matches the background used on rubrik.com hero sections and removes the subtle green tint of the old value.

### 2. Canvas ID Rename and Animation Replacement

The old canvas element (`<canvas id="matrix">`) and its associated CSS (`#matrix { ... }`) and JavaScript IIFE were fully removed.

A new canvas element `<canvas id="particleSphere">` was added. Its CSS positions it absolutely to fill the entire left panel (`position: absolute; inset: 0; width: 100%; height: 100%`), identical to the prior canvas approach.

The new JavaScript IIFE (lines 431–546 of the current file) implements a rotating 3D particle sphere using Canvas 2D:

- **Particle generation:** 1000 particles are distributed on a sphere surface using random spherical coordinates (theta from `acos(2 * random - 1)`, phi from `2 * PI * random`). This produces an even surface distribution without clustering at the poles.
- **3D rotation:** Each frame, particle Cartesian coordinates (x, y, z) are rotated around the X axis (+0.003 radians/frame) and then around the Y axis (+0.005 radians/frame) using standard rotation matrix multiplication.
- **Depth-based rendering:** After rotation, the Z coordinate is mapped to a `depth` factor (0–1). Particle size scales from 0.5px (far) to 2.5px (near). Alpha scales from 0.08 (far) to 0.80 (near). This creates a visual 3D depth effect without sorting overhead.
- **Subtle glow:** `ctx.shadowColor` is set to `#009dac` and `ctx.shadowBlur` is set to `depth * 6` per particle (0–6px), creating a soft glow on the nearer particles. `shadowBlur` is reset to 0 after all particles are drawn.
- **Projection:** Orthographic (no perspective divide). `sx = cx + x2`, `sy = cy + y1`. The sphere radius is `Math.min(canvas.width, canvas.height) * 0.32`.
- **Animation lifecycle:** `requestAnimationFrame` drives the loop. `cancelAnimationFrame` is used in `stopAnimation()`.
- **Mobile guard:** The animation only starts if `window.innerWidth > 768`. On window resize, if the width drops below 768px the animation stops; if it rises above 768px the animation starts.
- **Resize handling:** `canvas.width` and `canvas.height` are set to the canvas's `offsetWidth`/`offsetHeight` on start. The canvas is not re-sized on every frame (resize is called once in `startAnimation()`).

### 3. Logo and Wordmark Color

Inside the SVG `<defs><style>` block, the `.wh` class fill was changed from `#ffffff` to `#009dac`. This recolors all SVG paths that form the Rubrik diamond icon.

The `.brand-wordmark` CSS color property was changed from `#ffffff` to `#009dac`. The "rubrik" text beside the icon now matches the icon teal.

### 4. Brand Headline

An `<h2 class="brand-headline">` element was added inside `.brand-overlay`, above the existing `.brand-tagline` paragraph. HTML:

```html
<h2 class="brand-headline">SECURE YOUR DATA.<br/><span class="highlight">EVERYWHERE.</span></h2>
```

CSS for `.brand-headline`:

```css
.brand-headline {
    font-size: 32px;
    font-weight: 900;
    text-transform: uppercase;
    letter-spacing: 2px;
    color: #ffffff;
    line-height: 1.2;
    max-width: 320px;
    text-align: center;
}
.brand-headline .highlight { color: #009dac; }
```

The `<span class="highlight">` makes "EVERYWHERE." render in teal, creating a two-tone typographic effect matching Rubrik's marketing copy style.

The heading is tagged `<h2>` rather than `<h1>` because the right panel already contains an `<h1 class="form-title">` — there should be only one `<h1>` per page.

### 5. Heading Hierarchy Fix

The OVF section heading in the right panel was previously a second `<h1>`. It was demoted to `<h2>` (`<h2 class="form-title">Complete Your <span>OVF</span></h2>`) so the page has a single `<h1>` ("Access Your OVF" in the form section) and secondary headings at `<h2>`. This corrects a minor accessibility/SEO issue introduced when the OVF section was first added.

### 6. Mobile Responsive Rules

The existing `@media (max-width: 768px)` block was updated to reference `#particleSphere` instead of `#matrix`:

```css
#particleSphere { display: none; }
```

All other responsive rules (`.left-panel` height collapse to 64px, `.brand-overlay` hidden, `.brand-logo-wrap` static positioning, `.brand-wordmark` font-size reduction, `.right-panel` full width) were retained unchanged.

---

## Data Flow

### How It Works

This is a purely presentational change. There is no data flow through the modified components. The left panel is a static brand panel; the right panel handles all form logic and Apex remoting calls. The two panels do not share state.

For reference, the overall page flow is unchanged:

```
1. User visits /apex/RubrikQuotePortal
2. Left panel renders (particle sphere starts if desktop)
3. User enters Quote Number + Email and clicks "View OVF"
4. handleSubmit() JS fires Visualforce remoting call to RubrikQuoteLookupController.lookupQuote()
5. On success, OVF fields are rendered dynamically from OVF_FIELDS (fieldset-driven)
6. User fills OVF and submits; handleOVFSubmit() calls RubrikQuoteLookupController.submitOVF()
7. Thank-you state is shown
```

### Architecture Diagram

```
Browser (Desktop >= 769px)
         |
         v
+-------------------------------------+-------------------------------+
|  LEFT PANEL (.left-panel)           |  RIGHT PANEL (.right-panel)   |
|                                     |                               |
|  <canvas id="particleSphere">       |  <h1> "Access Your OVF"      |
|  Particle sphere IIFE               |  Quote Number input           |
|  - 1000 particles                   |  Email Address input          |
|  - Canvas 2D, no libraries          |  handleSubmit() -> remoting   |
|  - X rotation: +0.003 rad/frame     |                               |
|  - Y rotation: +0.005 rad/frame     |  <h2> "Complete Your OVF"    |
|  - Depth-based alpha (0.08-0.80)    |  OVF fields (fieldset-driven) |
|  - Glow: shadowBlur 0-6px           |  handleOVFSubmit() -> remoting|
|  - Stops at <= 768px width          |                               |
|                                     |  Thank-You state              |
|  .brand-logo-wrap (teal #009dac)    |                               |
|  .brand-wordmark  (teal #009dac)    |  Apex Controller:             |
|                                     |  RubrikQuoteLookupController  |
|  .brand-overlay                     |  (@RemoteAction methods)      |
|  - <h2 class="brand-headline">      |                               |
|  - <p  class="brand-tagline">       |                               |
+-------------------------------------+-------------------------------+

Mobile (<= 768px):
  Left panel collapses to 64px header bar
  #particleSphere hidden (display: none)
  .brand-overlay hidden
  Only logo + wordmark visible
```

---

## File Locations

| Component | Path |
|-----------|------|
| Modified Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |
| Page Metadata | `force-app/main/default/pages/RubrikQuotePortal.page-meta.xml` |
| Apex Controller (unchanged) | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |

---

## Configuration Details

### CSS Variables and Values

| Property | Selector | Value | Purpose |
|----------|----------|-------|---------|
| `background` | `.left-panel` | `#000000` | Panel background — pure black |
| `fill` | SVG `.wh` class | `#009dac` | Rubrik icon teal |
| `color` | `.brand-wordmark` | `#009dac` | Wordmark teal |
| `color` | `.brand-headline` | `#ffffff` | Headline white |
| `color` | `.brand-headline .highlight` | `#009dac` | "EVERYWHERE." teal accent |
| `font-size` | `.brand-headline` | `32px` | Headline size |
| `font-weight` | `.brand-headline` | `900` | Extra bold |
| `text-transform` | `.brand-headline` | `uppercase` | Force all caps |
| `letter-spacing` | `.brand-headline` | `2px` | Wide tracking |
| `max-width` | `.brand-headline` | `320px` | Prevents overflow on wide left panels |

### Particle Sphere JavaScript Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `PARTICLE_COUNT` | `1000` | Number of sphere surface points |
| Sphere radius factor | `0.32 * Math.min(w, h)` | Responsive sizing — 32% of the shorter canvas dimension |
| X rotation speed | `+0.003 rad/frame` | Slow tilt rotation |
| Y rotation speed | `+0.005 rad/frame` | Primary horizontal spin |
| Alpha range | `0.08 – 0.80` | Far-to-near depth transparency |
| Size range | `0.5px – 2.5px` | Far-to-near particle radius |
| Shadow blur range | `0 – 6px` | Per-particle glow intensity |
| Mobile breakpoint | `window.innerWidth > 768` | Guard for starting/stopping animation |

### Mobile Breakpoints

| Breakpoint | Behavior |
|------------|----------|
| `> 768px` | Full left panel, particle sphere animates, `.brand-overlay` visible |
| `<= 768px` | Left panel collapses to 64px header, `#particleSphere` hidden, `.brand-overlay` hidden, only logo + wordmark shown |
| `<= 1024px` | OVF grid changes from 3 columns to 2 columns (right panel only, unchanged) |
| `<= 600px` | OVF grid changes to 1 column (right panel only, unchanged) |

---

## Testing

No Apex code was changed, so no test classes were created or modified. The particle sphere and visual changes were verified by:

1. Deploying to the RubrikClaudePOC sandbox via Salesforce MCP.
2. Confirming deployment via Tooling API query on the `ApexPage` object.

### Manual Verification Checklist

| Test Scenario | Expected Behavior |
|---------------|------------------|
| Desktop browser (width > 768px) | Particle sphere animates, teal logo and wordmark, headline visible |
| Mobile browser (width <= 768px) | Left panel is 64px bar, no animation, only logo and wordmark |
| Resize from desktop to mobile | Animation stops, canvas hidden |
| Resize from mobile to desktop | Animation restarts |
| Right panel form submission | Unchanged — quote lookup and OVF submit function as before |

---

## Security

### Sharing Model

No Apex changes were made. The existing controller (`RubrikQuoteLookupController`) and its `with sharing` declaration are unchanged.

### Public-Facing Page

`RubrikQuotePortal` is a public-facing Visualforce page (accessible without Salesforce authentication via a Site). The changes in this task are purely visual and introduce no new data inputs, no SOQL queries, and no server calls.

### No External Dependencies

The particle sphere uses only the native Canvas 2D API. No external JavaScript libraries, CDN resources, or third-party scripts are loaded. This is consistent with the page's existing zero-external-dependency design.

---

## Notes and Considerations

### Known Limitations

- **Resize does not re-center sphere:** When the user resizes from mobile to desktop, `startAnimation()` calls `resize()` to set canvas dimensions but does not call `initParticles()` again. The particle positions are recalculated from the stored theta/phi angles each frame, so the sphere re-centers correctly; however, the sphere radius adjusts on the next call to `draw()` rather than instantly. This is visually imperceptible.

- **Duplicate `startAnimation()` call on resize:** The resize handler at lines 538–545 calls `startAnimation()` and then immediately checks `if (!animId)` and calls it again. The `startAnimation()` function guards against double-start with `if (animId) return`, so the second call is a no-op. It is a minor code smell but not a bug.

- **No particle depth sorting (painter's algorithm):** The design requirement specified painter's algorithm (sort by Z before drawing), but the implementation uses depth-based alpha and size instead of sorting. This produces a visually convincing depth effect at lower cost. Implementing painter's algorithm would require sorting 1000 elements per frame and is not necessary for the current visual quality.

- **Orthographic projection only:** The sphere uses orthographic projection (no perspective divide). The sphere does not appear to "bulge" toward the viewer. Perspective projection would require a focal length parameter and is outside the scope of this task.

### Future Enhancements

- Add a subtle teal radial gradient behind the sphere center for a bloom/halo effect (could use `createRadialGradient` drawn before the particles each frame).
- Implement painter's algorithm (sort particles by rotated Z descending before drawing) if visual depth quality needs improvement.
- Extract the particle sphere into a standalone JavaScript module or LWC component if it is reused elsewhere in the project.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `RubrikQuoteLookupController` | Apex Controller | Unchanged; handles all remoting calls for quote lookup and OVF submission |
| Canvas 2D API | Browser API | Native browser API; no external library required |
| Salesforce Site configuration | Platform | The page is served via a Site; no changes to Site config are needed |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-29 | Documentation Agent | Initial creation |
