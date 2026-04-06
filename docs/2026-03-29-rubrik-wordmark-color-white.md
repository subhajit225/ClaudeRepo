# Rubrik Wordmark Color Change — View Page Left Panel

**Date:** 2026-03-29
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Change the "rubrik" wordmark text color to white in the Rubrik Quote Portal Visualforce page. Specifically, the `.brand-wordmark` CSS class (used in the dark left panel of the OVF view page at `/rubrikquote`) should render white instead of teal.

### Business Objective

The Rubrik Quote Portal (`/rubrikquote`) has a split-panel layout. The left panel has a solid black (`#000000`) background with an animated particle sphere. The wordmark "rubrik" displayed beside the diamond logo in that panel was teal (`#009dac`), which provided adequate but not maximum contrast. Changing it to white (`#ffffff`) delivers a 21:1 contrast ratio — the theoretical maximum against pure black — improving brand clarity and accessibility on the dark background.

### Summary

A single CSS `color` property was changed in `RubrikQuotePortal.page`. The `.brand-wordmark` class, which governs the "rubrik" text in the left panel of the view page, was updated from `#009dac` (Rubrik teal) to `#ffffff` (white). The two other wordmark classes used in the OVF form header and the thank-you confirmation section were deliberately left teal, because those render on a light `#F4FAFB` background where white text would be invisible.

---

## Components Modified

### Before and After Comparison

| CSS Class | Location | Background | Before | After | Rationale |
|-----------|----------|------------|--------|-------|-----------|
| `.brand-wordmark` | View page — dark left panel | `#000000` (black) | `color: #009dac` | `color: #ffffff` | Changed per user request; white gives 21:1 contrast on black |
| `.ovf-logo-header .ovf-brand-wordmark` | OVF form header (light panel) | `#F4FAFB` (near-white) | `color: #009dac` | `color: #009dac` | Kept teal — white on this background would be invisible |
| `.thankyou-logo .ty-brand-wordmark` | Thank-you confirmation section | `#F4FAFB` (near-white) | `color: #009dac` | `color: #009dac` | Kept teal — same reason as OVF header |

### Files Modified

| File | Type | Change |
|------|------|--------|
| `force-app/main/default/pages/RubrikQuotePortal.page` | Visualforce Page | CSS `color` value on `.brand-wordmark` changed from `#009dac` to `#ffffff` (line ~61) |
| `force-app/main/default/pages/RubrikQuotePortal.page-meta.xml` | Page Metadata | No changes — deployed alongside the page as required by the Salesforce metadata API |

---

## Data Flow

### How the Page Renders

The Rubrik Quote Portal is a single Visualforce page with three distinct visual states controlled by Apex logic and CSS classes toggled by JavaScript:

```
User visits /rubrikquote
        |
        v
RubrikQuoteLookupController (Apex)
        |
        v
RubrikQuotePortal.page renders in VIEW state
        |
        +-- Left panel (.left-panel, background #000000)
        |       |
        |       +-- .brand-logo-wrap (top-left corner, z-index: 2)
        |               |
        |               +-- Diamond SVG (.brand-logo)
        |               +-- "rubrik" text (.brand-wordmark) <-- NOW WHITE
        |
        +-- Right panel (.right-panel, background #F4FAFB)
                |
                +-- Quote lookup form
```

When the user submits the lookup and an OVF form is displayed, the page switches to `ovf-mode`. The left panel is hidden and the OVF logo header appears inside the right panel — that header uses `.ovf-brand-wordmark` (teal, unchanged).

### Architecture Context

```
┌──────────────────────────────────────────────────────────┐
│  VIEW STATE  (/rubrikquote)                              │
│                                                          │
│  ┌─────────────────────┐  ┌──────────────────────────┐  │
│  │  LEFT PANEL         │  │  RIGHT PANEL             │  │
│  │  bg: #000000        │  │  bg: #F4FAFB             │  │
│  │                     │  │                          │  │
│  │  [diamond] rubrik   │  │  Quote lookup form       │  │
│  │           ^^^^^^^^  │  │                          │  │
│  │           NOW WHITE │  │                          │  │
│  │  (.brand-wordmark)  │  │                          │  │
│  └─────────────────────┘  └──────────────────────────┘  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  OVF FORM STATE  (js adds .ovf-mode class)               │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  OVF HEADER (inside right panel area)              │  │
│  │  bg: #ffffff                                       │  │
│  │                                                    │  │
│  │  [diamond] rubrik  <-- TEAL (#009dac), UNCHANGED   │  │
│  │  (.ovf-brand-wordmark)                             │  │
│  └────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────┐  │
│  │  OVF FORM BODY (bg: #F4FAFB)                       │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  THANK-YOU STATE  (after OVF submission)                 │
│                                                          │
│  ┌────────────────────────────────────────────────────┐  │
│  │  THANK-YOU SECTION (bg: #F4FAFB)                   │  │
│  │                                                    │  │
│  │  [diamond] rubrik  <-- TEAL (#009dac), UNCHANGED   │  │
│  │  (.ty-brand-wordmark)                              │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

---

## File Locations

| Component | Path |
|-----------|------|
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |
| Page Metadata | `force-app/main/default/pages/RubrikQuotePortal.page-meta.xml` |

---

## Configuration Details

### Changed CSS Rule

```css
/* BEFORE */
.brand-wordmark {
    font-size: 22px;
    font-weight: 600;
    color: #009dac;          /* Rubrik teal */
    letter-spacing: 1.2px;
    text-transform: lowercase;
    filter: drop-shadow(0 0 12px rgba(0,220,200,0.2));
}

/* AFTER */
.brand-wordmark {
    font-size: 22px;
    font-weight: 600;
    color: #ffffff;          /* White */
    letter-spacing: 1.2px;
    text-transform: lowercase;
    filter: drop-shadow(0 0 12px rgba(0,220,200,0.2));
}
```

### Unchanged CSS Rules (retained teal intentionally)

```css
/* OVF form header — light background, teal retained */
.ovf-logo-header .ovf-brand-wordmark {
    font-size: 20px;
    font-weight: 600;
    color: #009dac;
    letter-spacing: 1.2px;
    text-transform: lowercase;
}

/* Thank-you section — light background, teal retained */
.thankyou-logo .ty-brand-wordmark {
    font-size: 20px;
    font-weight: 600;
    color: #009dac;
    letter-spacing: 1.2px;
    text-transform: lowercase;
}
```

### Contrast Ratios

| Location | Text Color | Background | Contrast Ratio | WCAG Level |
|----------|-----------|------------|----------------|------------|
| Left panel (`.brand-wordmark`) | `#ffffff` (white) | `#000000` (black) | 21:1 | AAA |
| OVF header (`.ovf-brand-wordmark`) | `#009dac` (teal) | `#ffffff` (white) | 3.1:1 | AA Large |
| Thank-you section (`.ty-brand-wordmark`) | `#009dac` (teal) | `#F4FAFB` (near-white) | ~3.0:1 | AA Large |

### Other Occurrences of `#009dac` Not Changed

The design requirements note 15 total occurrences of `#009dac` in the file. Only the one inside `.brand-wordmark` was changed. The remaining 14 occurrences — covering gradients, borders, highlight text, SVG fills, and other UI elements — were left untouched.

---

## Testing

### Test Coverage Summary

| Class | Coverage | Status |
|-------|----------|--------|
| N/A — CSS-only change | N/A | No Apex modified |

No Apex code was created or modified. No test classes are required for this change. The change is a single CSS property value; correctness is verified by visual inspection of the rendered page.

### Verification Steps

1. Navigate to `/rubrikquote` (the portal URL) in a browser.
2. Confirm the "rubrik" wordmark in the top-left corner of the dark left panel is white.
3. Click into the OVF form (enter a valid quote ID and submit) and confirm the "rubrik" wordmark in the OVF header is still teal.
4. Confirm the "rubrik" wordmark in the thank-you confirmation screen is still teal.

---

## Security

### Sharing Model

No Apex was modified. The existing `RubrikQuoteLookupController` security model is unchanged.

### Public Page Note

`RubrikQuotePortal.page` is a public-facing Visualforce page accessible without Salesforce authentication. This change is purely cosmetic (CSS color) and introduces no security surface changes.

---

## Notes and Considerations

### Why Only the Left Panel Was Changed

The original request asked for all three wordmark locations to become white. After the design agent flagged a contrast concern — that `#ffffff` on a `#F4FAFB` near-white background would produce an effectively invisible wordmark — the user chose to apply the white color only to the left panel (dark background) and retain teal for the OVF header and thank-you section. This decision is deliberate and intentional.

### Known Limitations

- The drop-shadow filter on `.brand-wordmark` (`drop-shadow(0 0 12px rgba(0,220,200,0.2))`) is a teal-tinted glow carried over from the original design. It remains on the element after the color change. On a black background with a white wordmark the glow is faint but visible. If a neutral drop-shadow is preferred in the future, the `rgba` value can be changed to a neutral tone (e.g., `rgba(255,255,255,0.15)`).
- The responsive CSS rule at `@media (max-width: 768px)` references `.brand-wordmark { font-size: 17px; }` for scaling — this rule does not set a color and is unaffected by this change.

### Future Enhancements

- If the brand guidelines change the "rubrik" wordmark treatment across all three states consistently, all three CSS classes (`.brand-wordmark`, `.ovf-brand-wordmark`, `.ty-brand-wordmark`) should be updated together.
- Consider extracting the wordmark color into a CSS custom property (e.g., `--rubrik-wordmark-color`) to make future global changes a single-line edit.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `RubrikQuoteLookupController` | Apex Controller | Controls page state; unmodified |
| `RubrikQuotePortal.page-meta.xml` | Metadata | Deployed alongside the page; API version 66.0 |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-29 | Documentation Agent | Initial creation |
