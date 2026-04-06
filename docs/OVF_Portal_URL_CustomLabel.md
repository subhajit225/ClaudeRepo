# OVF Portal URL: Replace Hardcoded URL with Custom Label

**Date:** 2026-03-29
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Replace a hardcoded sandbox URL in `SendOvfEmailController.cls` with a Salesforce Custom Label so the OVF portal URL can be changed per environment (sandbox, production) via Setup > Custom Labels without code changes.

### Business Objective

The OVF (Order Verification Form) email sent to customers contains a button that links to the Rubrik Quote Portal. The URL for this portal differs between Salesforce environments: sandbox orgs use a domain containing `--claudepoc.sandbox`, while production uses a clean production domain. A hardcoded URL in Apex code means that when the package is promoted to production, customers would receive emails linking to the sandbox portal. A Custom Label solves this by making the URL an admin-configurable value that is stored per environment and never requires a code change to update.

### Summary

The constant `OVF_PORTAL_URL` in `SendOvfEmailController.cls` was changed from a string literal to a reference to the Custom Label `OVF_Portal_URL`. A new `CustomLabels.labels-meta.xml` file was created to define and ship the label. The test class assertion was updated to reference the same label rather than a literal string, ensuring the test stays correct in every environment.

---

## Components Changed

### Admin Components (Declarative)

#### Custom Labels

| Label API Name | Category | Language | Protected | Default Value | Description |
|----------------|----------|----------|-----------|---------------|-------------|
| `OVF_Portal_URL` | OVF | en_US | false | `https://rubrikinc--claudepoc.sandbox.my.salesforce-sites.com/rubrikquote` | Customer-facing OVF portal URL - change per environment |

The label is shipped with the sandbox URL as its default value. In each target environment (production, other sandboxes) an admin must update this value after deployment. See the "How to Update the URL" section below.

---

### Development Components (Code)

#### Apex Classes Modified

| Class Name | Type | Change Made |
|------------|------|-------------|
| `SendOvfEmailController` | Service / @AuraEnabled controller | Line 12: replaced hardcoded string literal with `Label.OVF_Portal_URL` |
| `SendOvfEmailControllerTest` | Test class | Line 621: updated assertion to compare against `Label.OVF_Portal_URL` instead of a literal string |

---

## What Changed and Why

### Before

```apex
private static final String OVF_PORTAL_URL =
    'https://rubrikinc--claudepoc.sandbox.my.salesforce-sites.com/rubrikquote';
```

The URL was a compile-time string literal baked into the class. It worked in the sandbox where the code was written but would send customers to the sandbox portal after any promotion to production.

### After

```apex
private static final String OVF_PORTAL_URL = Label.OVF_Portal_URL;
```

At runtime Salesforce resolves `Label.OVF_Portal_URL` to the value stored in the Custom Label for the current org. An admin can change that value in Setup without touching code or doing a deployment.

### Test Class Change

Before (fragile — would fail in production because the label value would differ):
```apex
Assert.isTrue(html.contains('https://rubrikinc--claudepoc.sandbox.my.salesforce-sites.com/rubrikquote'),
    'HTML should contain the OVF portal URL');
```

After (environment-safe — always checks for whatever the label resolves to):
```apex
Assert.isTrue(html.contains(Label.OVF_Portal_URL),
    'HTML should contain the OVF portal URL from the Custom Label');
```

---

## Data Flow

### How the URL Reaches the Customer Email

```
1. Sales Rep clicks "Send OVF" quick action on a CPQ Quote record
2. LWC calls SendOvfEmailController.sendOvfEmail(quoteId)
3. sendOvfEmail calls buildEmailHtml(), which embeds OVF_PORTAL_URL
   into the CTA button href
4. OVF_PORTAL_URL is resolved at runtime from Label.OVF_Portal_URL
5. Salesforce reads the Custom Label value for the current org
6. The correct, environment-specific URL appears in the email body
7. Customer clicks the button and lands on the right portal
```

### Architecture Diagram

```
  ┌─────────────────────────────────┐
  │  Setup > Custom Labels          │
  │  OVF_Portal_URL = <url>         │  <-- Admin sets correct value
  └────────────────┬────────────────┘       per environment
                   │ resolved at runtime
                   ▼
  ┌─────────────────────────────────┐
  │  SendOvfEmailController.cls     │
  │  OVF_PORTAL_URL = Label.OVF_... │
  │  buildEmailHtml() embeds URL    │
  │  into CTA button href           │
  └────────────────┬────────────────┘
                   │
                   ▼
  ┌─────────────────────────────────┐
  │  HTML Email                     │
  │  <a href="[correct URL]">       │
  │  Complete Order Verification    │
  │  Form</a>                       │
  └────────────────┬────────────────┘
                   │
                   ▼
  ┌─────────────────────────────────┐
  │  Customer Inbox                 │
  │  Clicks button -> lands on      │
  │  correct portal for that org    │
  └─────────────────────────────────┘
```

---

## File Locations

| Component | Path |
|-----------|------|
| Custom Labels metadata | `force-app/main/default/labels/CustomLabels.labels-meta.xml` |
| Apex Controller | `force-app/main/default/classes/SendOvfEmailController.cls` |
| Apex Controller metadata | `force-app/main/default/classes/SendOvfEmailController.cls-meta.xml` |
| Apex Test Class | `force-app/main/default/classes/SendOvfEmailControllerTest.cls` |

---

## How to Update the URL in a New Environment

After deploying to any new environment (production, QA sandbox, UAT sandbox, etc.):

1. Log in to the target org as an admin.
2. Navigate to **Setup > Custom Labels** (search "Custom Labels" in Quick Find).
3. Find **OVF_Portal_URL** in the list.
4. Click **Edit**.
5. Change the **Value** field to the correct Experience Cloud / Site URL for that environment.
6. Click **Save**.

No code deployment is required. The change takes effect on the next email sent.

### Example Values by Environment Type

| Environment | Example URL Pattern |
|-------------|---------------------|
| Sandbox | `https://rubrikinc--<sandboxname>.sandbox.my.salesforce-sites.com/rubrikquote` |
| Production | `https://rubrikinc.my.salesforce-sites.com/rubrikquote` |
| Developer Edition | `https://<devorgdomain>.my.salesforce-sites.com/rubrikquote` |

Obtain the exact URL from the Experience Cloud site configuration in each org: **Setup > Digital Experiences > All Sites**, then check the site URL column for the Rubrik Quote site.

---

## Testing

### Test Coverage

The label reference is exercised by the existing test `testBuildEmailHtml_withLineItems` in `SendOvfEmailControllerTest.cls`. The assertion confirms that the rendered HTML contains whatever value `Label.OVF_Portal_URL` resolves to, which makes the test pass correctly in every environment without modification.

| Scenario | Test Method | Assertion |
|----------|-------------|-----------|
| Email HTML contains portal URL | `testBuildEmailHtml_withLineItems` | `html.contains(Label.OVF_Portal_URL)` |

---

## Security

No security model changes were introduced by this change.

- `SendOvfEmailController` continues to use `with sharing`.
- All SOQL queries continue to use `WITH USER_MODE`.
- Custom Labels are readable by all profiles by default; the label value (a URL) is not sensitive.
- The label is marked `protected = false`, meaning it is visible to subscribers if the package is distributed as a managed package.

---

## Notes and Considerations

### Known Limitations

- The Custom Label ships with the sandbox URL as its default value. An admin **must** update it after deploying to production before the first OVF email is sent. There is no automated mechanism to detect a mismatch between the label value and the current org's site URL.
- Custom Label values are org-wide. If a single org hosts multiple Experience Cloud sites, only one URL can be stored in this label.

### Future Enhancements

- Add a health-check Apex method (callable from a Flow or a scheduled job) that verifies the label value is reachable and alerts admins if it returns an HTTP error.
- Consider using a Custom Metadata Type instead of a Custom Label if per-profile or per-record-type URL variations are ever needed, as Custom Metadata supports more granular configuration.

### Dependencies

| Dependency | Notes |
|------------|-------|
| `SBQQ__Quote__c` (CPQ Quote object) | The controller operates on CPQ quote records. |
| Experience Cloud / Salesforce Sites | The URL in the label must point to a live, active Site. |
| `SendOvfEmailControllerTest` | Test class references the same label; both files must be deployed together. |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-29 | Documentation Agent | Initial creation |
