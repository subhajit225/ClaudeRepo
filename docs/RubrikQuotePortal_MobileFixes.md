# Rubrik Quote Portal — Mobile UX Fixes

**Date:** 2026-03-29
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Applied mobile responsiveness improvements to the customer-facing OVF (Order Verification Form) portal page.

### Business Objective

The Rubrik Quote Portal is a customer-facing Visualforce page used by buyers to look up their quotes and submit Order Verification Forms (OVF). On mobile devices the page had several usability problems: the decorative left panel consumed significant vertical space before the form was visible, iOS Safari auto-zoomed into input fields making the layout jump, OVF mode padding was too wide for phone-width screens, and the canvas animation ran continuously on mobile wasting battery. These fixes make the OVF flow usable on phones and tablets without changing any desktop behavior.

### Summary

Six categories of changes were applied to `force-app/main/default/pages/RubrikQuotePortal.page`. The changes span CSS layout, HTML semantics, and JavaScript animation gating, all contained within a single Visualforce page file. No Apex, no new components, and no new metadata files were created or modified.

---

## File Modified

| File | Path |
|------|------|
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |

---

## Changes Applied

### 1. CSS — Left Panel Mobile Collapse

**Problem:** On screens at or below 768px the left decorative panel (which contains the matrix rain canvas animation and the "Securing the world's data" tagline) was rendered at 220px of vertical height. This pushed the quote lookup form below the visible fold on most phones.

**Fix:** Within the `@media (max-width: 768px)` breakpoint the left panel is collapsed to a fixed 64px header bar. The matrix canvas (`#matrix`) and brand overlay (`.brand-overlay`) are hidden with `display: none`. The brand logo wrap (`.brand-logo-wrap`) is set to `position: static` so it flows naturally inside the 64px bar. The logo is scaled from 44px to 32px and the wordmark font-size is reduced from 22px to 17px to fit the compact bar.

**CSS rules added or changed in the mobile breakpoint:**

```css
@media (max-width: 768px) {
    .split { flex-direction: column; }
    .left-panel { width: 100%; height: 64px; min-height: 0; flex-shrink: 0;
                  justify-content: flex-start; padding: 0 20px; }
    #matrix { display: none; }
    .brand-overlay { display: none; }
    .brand-logo-wrap { position: static; }
    .brand-logo { width: 32px; height: 32px; }
    .brand-wordmark { font-size: 17px; }
    ...
}
```

---

### 2. CSS — iOS Input Zoom Prevention

**Problem:** iOS Safari automatically zooms the viewport into any focused input field whose `font-size` is less than 16px. The base `.field-input` style sets `font-size: 14px`, causing the zoom-on-focus behavior on iPhones.

**Fix:** `font-size: 16px` is applied to `.field-input` inside the `@media (max-width: 768px)` breakpoint. This meets the iOS minimum threshold and prevents the zoom without affecting desktop rendering.

```css
@media (max-width: 768px) {
    ...
    .field-input { font-size: 16px; }
}
```

---

### 3. CSS — OVF Mode Mobile Padding and Cascade Fix

**Problem:** When a quote is successfully validated the page adds the `ovf-mode` class to `.split`, which hides the left panel and expands the right panel to full width with `padding: 48px 80px`. On a 375px-wide phone the 80px horizontal padding left only 215px of usable content width, making the form fields extremely narrow.

A secondary problem was a CSS source-order bug: the `.split.ovf-mode .right-panel` base rule was declared after the `@media (max-width: 768px)` block in the original stylesheet. Because both rules have the same specificity, the base rule won by cascade order, making the mobile override effectively dead.

**Fix (two parts):**

1. The `.split.ovf-mode .right-panel { width: 100%; padding: 48px 80px; }` base rule is now placed before the responsive media query blocks in the stylesheet so the mobile rule can correctly override it.
2. A targeted rule is added inside the `@media (max-width: 768px)` block:

```css
@media (max-width: 768px) {
    ...
    .right-panel { width: 100%; padding: 28px 20px; }
    .split.ovf-mode .right-panel { padding: 28px 20px; }
}
```

This reduces horizontal padding to 20px on mobile for both the default split view and the OVF full-width mode.

---

### 4. HTML — autocomplete Attributes on OVF Fields

**Problem:** The OVF form fields had no HTML5 `autocomplete` attributes. Mobile browsers (and password managers) could not match fields to stored addresses or contact information, so users had to type all 10 address/contact fields manually on a phone keyboard.

**Fix:** Semantic HTML5 autocomplete tokens were added to 10 OVF input fields.

| Field ID | autocomplete Token |
|----------|--------------------|
| `companyName` | `organization` |
| `address1` | `address-line1` |
| `address2` | `address-line2` |
| `city` | `address-level2` |
| `state` | `address-level1` |
| `zipCode` | `postal-code` |
| `country` | `country-name` |
| `contactName` | `name` |
| `contactEmail` | `email` |
| `contactPhone` | `tel` |

Fields that are Rubrik-specific and have no meaningful autocomplete token (`buyerName`, `buyerBillingId`, `buyerTenantId`, `resellerName`, `marketplaceSellerId`) retain `autocomplete="off"`.

---

### 5. HTML — Semantic Input Types

**Problem:** `contactEmail` was `type="text"` and `contactPhone` was `type="text"`. On mobile devices, a `type="text"` field presents the standard QWERTY keyboard regardless of the expected data, making email and phone entry slower.

**Fix:**
- `contactEmail` changed to `type="email"` — triggers the email keyboard on iOS and Android (shows `@` and `.` prominently).
- `contactPhone` changed to `type="tel"` — triggers the phone dialer keyboard (numeric pad with `+`, `*`, `#`).

Note: The lookup form's `emailAddr` field already had `type="email"` prior to this change.

---

### 6. JavaScript — Matrix Animation Mobile Guard

**Problem:** The matrix rain canvas animation ran its `setInterval` loop on all devices including phones, consuming CPU cycles and battery even though the canvas is hidden on mobile via CSS (`#matrix { display: none; }`). There were also no null-safety guards on `canvas.getContext('2d')` or inside the `draw()` function.

**Fix (three parts):**

1. The initial `resize()` call and the `setInterval(draw, 40)` startup are both gated behind `window.innerWidth > 768`. The animation only starts on screens wider than 768px.

2. A `resize` event listener manages the animation across viewport threshold crossings in both directions: if the window grows above 768px the animation starts; if it shrinks to 768px or below, `clearInterval` is called and `animId` is reset to `null`.

3. Null guards are added:
   - `var ctx = canvas ? canvas.getContext('2d') : null;` — guards against a missing canvas element.
   - `if (!ctx) return;` at the top of `draw()` — prevents drawing errors if context is unavailable.

```javascript
if (window.innerWidth > 768) { resize(); }
var animId = null;
if (window.innerWidth > 768) { animId = setInterval(draw, 40); }

window.addEventListener('resize', function() {
    if (window.innerWidth > 768) {
        resize();
        if (!animId) { animId = setInterval(draw, 40); }
    } else {
        if (animId) { clearInterval(animId); animId = null; }
    }
});
```

---

## Bugs Fixed During Code Review

### CSS Cascade Bug

The `.split.ovf-mode .right-panel` base rule was originally placed after the `@media (max-width: 768px)` block in the stylesheet. Because CSS applies rules in source order when specificity is equal, the base rule was overriding the mobile media query rule, meaning the mobile padding fix had no effect. Resolution: the OVF mode base rules were moved to appear before the responsive breakpoints.

### inputmode="numeric" Removed from zipCode

`inputmode="numeric"` was initially considered for the `zipCode` field to trigger a numeric keyboard on mobile. It was removed because international postal codes — UK (e.g. "SW1A 1AA"), Canadian (e.g. "M5V 3A8") — contain letters. A numeric-only keyboard would block correct entry for international customers.

---

## Page Architecture

### Page Sections (Runtime State Machine)

The portal renders three mutually exclusive sections inside `.form-wrap`. JavaScript toggles the `hidden` class to transition between states.

```
State 1: Quote Lookup               State 2: OVF Form               State 3: Thank You
┌──────────────────────┐            ┌──────────────────────┐         ┌──────────────────┐
│  #form-section       │            │  #ovf-section        │         │  #thankyou-sect. │
│  - Quote Number      │  success   │  - 3-column OVF grid │  submit │  - Success icon  │
│  - Email Address     │ ─────────▶ │  - 15 OVF fields     │ ───────▶│  - Confirmation  │
│  - View OVF button   │            │  - Submit OVF button │         │  message         │
└──────────────────────┘            └──────────────────────┘         └──────────────────┘
         │
         │ adds .ovf-mode to .split
         ▼
   Left panel hidden,
   right panel = 100% width
```

### Layout Breakpoints

| Viewport Width | Layout |
|----------------|--------|
| > 1024px | 3-column OVF grid; 50/50 split panels |
| 769px – 1024px | 2-column OVF grid; 50/50 split panels |
| <= 768px | 1-column stacked; left panel collapses to 64px header bar; matrix animation stopped |
| <= 600px | 1-column OVF grid |

### Visualforce Remote Action Flow

```
User enters Quote# + Email
         │
         ▼
handleSubmit() [client-side validation]
         │
         ▼
Visualforce.remoting.Manager.invokeAction
    → RubrikQuoteLookupController.lookupQuoteVF
         │
    ┌────┴────────────┐
    │  success        │  failure
    ▼                 ▼
show #ovf-section    show #serverErr
add .ovf-mode        (error message)

User fills OVF and submits
         │
         ▼
handleOVFSubmit() [collects 16 field values]
         │
         ▼
Visualforce.remoting.Manager.invokeAction
    → RubrikQuoteLookupController.submitOVF
         │
    ┌────┴────────────┐
    │  success        │  failure
    ▼                 ▼
show #thankyou-sect. show #ovfServerErr
```

---

## Mobile Behavior Before and After

| Concern | Before | After |
|---------|--------|-------|
| Left panel on phone | 220px tall, form below fold | 64px header bar, form immediately visible |
| iOS input zoom | Triggers on focus (14px font) | No zoom (16px font in mobile breakpoint) |
| OVF padding on phone | 80px horizontal — form 215px wide | 20px horizontal — full usable width |
| OVF padding CSS bug | Mobile rule overridden by cascade | Base rule reordered; mobile rule wins |
| Autocomplete | No tokens — manual entry required | 10 fields have semantic tokens |
| Email/phone keyboard | Generic QWERTY | Email keyboard / phone dialer keyboard |
| Animation on mobile | setInterval running; wasting CPU | Animation never starts; stops if resize |
| Canvas null safety | No guard | ctx null-checked at init and in draw() |
| inputmode on zipCode | Not present | Intentionally not added (international) |

---

## Security Notes

- The page uses Visualforce JavaScript Remoting with `{ escape: true }` on both remote action calls, ensuring all return values are HTML-escaped before use.
- No server-side changes were made. The Apex controller (`RubrikQuoteLookupController`) is unchanged.
- No new permissions or sharing model changes are required for these fixes.

---

## File Locations

| Component | Path |
|-----------|------|
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |
| Apex Controller (unchanged) | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |

---

## Notes and Considerations

### Known Limitations

- The 768px breakpoint is hardcoded in both CSS media queries and the JavaScript resize guard. If the breakpoint is changed in the future both locations must be updated in sync.
- The left panel header bar on mobile shows only the Rubrik logo and wordmark. The "Securing the world's data" tagline and the matrix animation are not accessible on mobile at all — this is an intentional trade-off for screen real estate.
- `zipCode` uses `type="text"` and `autocomplete="postal-code"` without `inputmode`. International postal codes require letter input, so numeric-only keyboards are inappropriate.

### Future Enhancements

- Consider a CSS custom property (e.g. `--breakpoint-mobile: 768px`) to keep the JS and CSS breakpoint values in sync and avoid drift.
- The OVF grid currently uses a fixed 3-column layout at desktop width. A future pass could make column count data-driven so it adapts to the number of required fields per quote type.
- Touch-specific validation feedback (shake animation on error, haptic feedback via the Vibration API) could further improve mobile UX.
- The matrix animation initializes on page load and uses a single `setInterval`. A future improvement could use `requestAnimationFrame` instead of `setInterval` for smoother rendering and better browser throttling behavior on background tabs.

### Dependencies

- Apex Controller: `RubrikQuoteLookupController` (provides `lookupQuoteVF` and `submitOVF` remote actions)
- No external CSS frameworks or JavaScript libraries — all styles and scripts are inline within the page

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-29 | Documentation Agent | Initial documentation of mobile UX fixes |
