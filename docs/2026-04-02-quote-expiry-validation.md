# Quote Expiry Date Validation on View OVF Lookup Form

**Date:** 2026-04-02
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Add quote expiry date validation to the Rubrik Quote Portal OVF lookup form. Previously, the portal had no expiry awareness — if a customer entered a quote number that had already passed its expiry date, the portal would still redirect them into the OVF form. The fix should show a clear, friendly error message when a quote is expired, rather than redirecting.

### Business Objective

The Rubrik Quote Portal is an Experience Cloud site that allows customers to look up their quote and fill out an Order Verification Form (OVF). Without expiry validation, customers could attempt to complete an OVF against a quote that the sales team no longer intended to be active. This feature blocks that path at the lookup step and directs the customer to contact their Rubrik account team, reducing downstream processing errors and improving the customer experience.

### Summary

Two backend changes and one frontend change were made. The Apex controller's SOQL query was extended to retrieve the quote's expiration date, and a new expiry check was inserted into the lookup flow. The LWC's response handler was updated to prioritise the new `errorMessage` field returned by the controller. Three new Apex test methods were added to cover the expired, future-expiry, and null-expiry scenarios.

---

## Components Created

### Admin Components (Declarative)

No declarative components were created or modified for this feature.

---

### Development Components (Code)

#### Apex Classes

| Class Name | Type | Description |
|------------|------|-------------|
| `RubrikQuoteLookupController` | Controller | Modified to add `errorMessage` field to `QuoteLookupResult`, add `SBQQ__ExpirationDate__c` to the SOQL query, and perform the expiry check after OCR email validation |

#### Apex Triggers

No triggers were created or modified.

#### Test Classes

| Test Class | Tests For | New Methods Added |
|------------|-----------|-------------------|
| `RubrikQuoteLookupControllerTest` | `RubrikQuoteLookupController` | 3 new methods covering expired, future-expiry, and null-expiry scenarios |

#### Lightning Web Components

| Component Name | File Modified | Description |
|----------------|--------------|-------------|
| `rubrikQuoteLookup` | `rubrikQuoteLookup.js` | Updated `.then()` handler to check `result.errorMessage` before checking `result.quoteUrl` |
| `rubrikQuoteLookup` | `rubrikQuoteLookup.html` | No changes — the existing `{serverError}` block already renders the error message |

---

## Data Flow

### How It Works

The lookup form collects a quote number and email address from the customer. The sequence of validation steps inside `GuestQueryHelper.findQuote()` is:

```
1. Customer enters quote number + email on the portal form
2. rubrikQuoteLookup LWC calls lookupQuote (AuraEnabled) on submit
3. Controller trims and lowercases inputs, delegates to GuestQueryHelper.findQuote()
4. Step 1 — SOQL query fetches SBQQ__Quote__c by Name, including SBQQ__ExpirationDate__c
5. Step 2 — SOQL query fetches OpportunityContactRole to validate the email
         (returns null if no match — does not reveal the quote exists)
6. Step 3 — Expiry check: if ExpirationDate < today, return QuoteLookupResult
         with errorMessage populated and quoteUrl left null
7. If valid — return QuoteLookupResult with quoteUrl and contact/address data populated
8. LWC .then() handler:
         a. If result.errorMessage is set — display it in the serverError alert block
         b. Else if result.quoteUrl is set — show success state and redirect after 1.5 s
         c. Else — display "No quote found" fallback message
```

### Architecture Diagram

```
  Customer Browser
        |
        | (quote number + email)
        v
  rubrikQuoteLookup.js  (handleSubmit)
        |
        | lookupQuote(@AuraEnabled)
        v
  RubrikQuoteLookupController.lookupQuote()
        |
        | delegates to
        v
  GuestQueryHelper.findQuote()   [without sharing — guest user context]
        |
        |-- Step 1: SELECT SBQQ__Quote__c WHERE Name = :quoteName
        |           (includes SBQQ__ExpirationDate__c)
        |
        |-- Step 2: SELECT OpportunityContactRole
        |           WHERE IsPrimary = true AND Contact.Email = :email
        |           --> returns null if no match (hides quote existence)
        |
        |-- Step 3: Expiry check
        |           ExpirationDate < Date.today()?
        |           YES --> return QuoteLookupResult { errorMessage: "..." }
        |           NO  --> continue to success result
        |
        v
  QuoteLookupResult
        |
        |-- .errorMessage set?  --> LWC shows error alert
        |-- .quoteUrl set?      --> LWC shows success + redirects
        |-- neither?            --> LWC shows "No quote found" fallback
```

---

## File Locations

| Component | Path |
|-----------|------|
| Apex Controller | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |
| Apex Test Class | `force-app/main/default/classes/RubrikQuoteLookupControllerTest.cls` |
| LWC JavaScript | `force-app/main/default/lwc/rubrikQuoteLookup/rubrikQuoteLookup.js` |
| LWC HTML Template | `force-app/main/default/lwc/rubrikQuoteLookup/rubrikQuoteLookup.html` (unchanged) |

---

## Configuration Details

### QuoteLookupResult Inner Class

The `QuoteLookupResult` inner class on `RubrikQuoteLookupController` was extended with one new field:

| Field | Type | AuraEnabled | Purpose |
|-------|------|-------------|---------|
| `errorMessage` | `String` | Yes | Populated when the quote is expired; null on success |

All pre-existing fields (`quoteUrl`, `quoteId`, `contactName`, `contactEmail`, `contactPhone`, `companyName`, `shippingAddress1`–`shippingCountry`) remain unchanged.

### SOQL Change — GuestQueryHelper.findQuote()

`SBQQ__ExpirationDate__c` was added to the SELECT clause of the `SBQQ__Quote__c` query. No other changes were made to the query, filter, or limit.

### Expiry Check Placement

The check occupies Step 3 in the three-step validation sequence:

1. Quote lookup by name (returns `null` if not found)
2. OCR email match (returns `null` if email is not the primary contact)
3. Expiry check (returns `QuoteLookupResult` with `errorMessage` if expired)

Placing the expiry check **after** email validation is a deliberate security decision: a caller who cannot prove they are the primary contact receives `null` (quote not found), not an expiry message that would confirm the quote's existence. See the Security section below.

### Expiry Logic

```apex
if (quotes[0].SBQQ__ExpirationDate__c != null
        && quotes[0].SBQQ__ExpirationDate__c < Date.today()) {
    QuoteLookupResult expired = new QuoteLookupResult();
    expired.errorMessage = 'This quote expired on '
        + quotes[0].SBQQ__ExpirationDate__c.format()
        + ' and is no longer available. Please contact your Rubrik account team.';
    return expired;
}
```

Quotes with a null `SBQQ__ExpirationDate__c` are treated as non-expiring and pass through to the success path.

### LWC Response Handler Change

The `.then()` callback in `rubrikQuoteLookup.js` was restructured to evaluate `errorMessage` first:

```javascript
.then(result => {
    if (result && result.errorMessage) {
        this.serverError = result.errorMessage;
    } else if (result && result.quoteUrl) {
        this.showSuccess = true;
        setTimeout(() => { window.location.href = result.quoteUrl; }, 1500);
    } else {
        this.serverError = 'No quote found matching the details provided. Please check and try again.';
    }
})
```

The `{serverError}` binding in `rubrikQuoteLookup.html` (lines 91–99) already renders any non-empty `serverError` value inside a styled `alert-error` div, so no HTML changes were required.

---

## Testing

### Test Coverage Summary

Three new test methods were added to the existing `RubrikQuoteLookupControllerTest` class:

| Test Method | Scenario | Expected Outcome |
|-------------|----------|-----------------|
| `testLookupQuote_expiredQuote_returnsErrorMessage` | `SBQQ__ExpirationDate__c` set to `Date.today().addDays(-1)` | `result.errorMessage` is non-blank, contains "expired"; `result.quoteUrl` is null |
| `testLookupQuote_futureExpiryQuote_returnsSuccess` | `SBQQ__ExpirationDate__c` set to `Date.today().addDays(30)` | `result.quoteId` matches the test quote; `result.errorMessage` is null |
| `testLookupQuote_nullExpiryQuote_returnsSuccess` | `SBQQ__ExpirationDate__c` left null (default from `@TestSetup`) | `result.quoteId` matches the test quote; `result.errorMessage` is null |

### Pre-existing Test Coverage

The following tests continued to pass without modification and provide coverage for all other branches of the controller:

| Test Method | Covers |
|-------------|--------|
| `testLookupQuoteVF_emailMatchesContact_returnsResult` | Full success path with field population |
| `testLookupQuoteVF_emailMismatch_returnsNull` | Wrong email returns null |
| `testLookupQuoteVF_unknownQuoteNumber_returnsNull` | Non-existent quote number returns null |
| `testLookupQuote_blankQuoteNumber_returnsNull` | Blank input guard |
| `testLookupQuote_blankEmail_returnsNull` | Blank input guard |
| `testLookupQuote_nullInputs_returnsNull` | Null input guard |
| `testLookupQuote_emailCaseInsensitive_returnsResult` | Case-insensitive email matching |
| `testLookupQuote_whitespaceInputs_returnsResult` | Input trimming |
| `testSubmitOVF_validData_createsRecordAndReturnsId` | OVF submission success |
| `testSubmitOVF_*` | OVF submission error branches |
| `testSubmitOVFDynamic_*` | Dynamic OVF submission branches |
| `testGetOvfFieldSetMembers_returnsFields` | Field set member retrieval |

### Key Test Conventions

- `@TestSetup` uses `ShGl_DisableBusinessLogic__c` and `TriggerControls` flags to suppress heavy CPQ triggers before any DML.
- Tests that update the quote's expiry date also set `TriggerControls.disableQuoteTrigger = true` before calling `update quote`.
- The helper `getTestQuote()` reads `SBQQ__Quote__c LIMIT 1` to retrieve the auto-generated quote Name — this is a non-deterministic SOQL pattern flagged in the code review as a minor warning.

---

## Security

### Sharing Model

| Class | Sharing | Rationale |
|-------|---------|-----------|
| `RubrikQuoteLookupController` | `with sharing` | Outer controller enforces standard record sharing |
| `GuestQueryHelper` | `without sharing` | Guest Site user has no sharing access to CPQ/Opportunity records; access is gated by the quote-number + email check |
| `GuestDmlHelper` | `without sharing` | Guest user cannot DML against OVF__c records that reference an SBQQ__Quote__c they do not own |

### SOQL Mode

`GuestQueryHelper` queries do not use `WITH USER_MODE`. This is a pre-existing, intentional design choice (flagged as a minor warning in the code review but not changed). The guest user context is enforced by Salesforce Site security at the network level; record-level access control is implemented by the quote-number + email validation logic.

### Information Disclosure Prevention

The expiry check is deliberately placed **after** the OCR email validation step. If the email does not match the primary contact, the method returns `null` before it can reach the expiry check. This prevents an unauthenticated caller from probing whether a given quote number exists by observing whether they receive an expiry message.

### Required Permissions

No new permissions are required. The feature operates entirely within the existing Experience Cloud Site guest user profile. No new fields, objects, or permission sets were created.

---

## Notes and Considerations

### Known Limitations

- **Expiry message format** — The date in the error message is formatted using `Date.format()`, which returns the date in the org's locale-specific format. This may vary between orgs if the org locale is changed.
- **No expiry buffer** — The check uses a strict `< Date.today()` comparison. A quote that expires today (i.e., `ExpirationDate == Date.today()`) is treated as still valid. If business rules require blocking same-day expiry, the condition would need to change to `<= Date.today()`.
- **`WITH USER_MODE` absent** — Pre-existing limitation in `GuestQueryHelper`. Flagged by code review as a minor warning; intentional by design.
- **Silent catch in LWC** — The `.catch()` block in `rubrikQuoteLookup.js` does not log errors to the console. This was flagged by code review as a minor warning.

### Future Enhancements

- Add a configurable "expiry buffer" (e.g., warn N days before expiry) via a Custom Metadata type or Custom Label.
- Surface expiry date on the OVF form confirmation page so valid-but-near-expiry quotes show a warning.
- Add console logging in the LWC `.catch()` block for easier debugging in production.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `SBQQ__Quote__c.SBQQ__ExpirationDate__c` | CPQ managed package field | Must exist in the org; standard CPQ field |
| `OpportunityContactRole` | Standard object | Used for email validation in the lookup flow |
| `TriggerControls` | Custom Apex class | Used in test setup to suppress CPQ triggers |
| `ShGl_DisableBusinessLogic__c` | Custom Setting | Used in test setup to disable heavy automation |

### Deployment Target

- **Org:** RubrikClaudePOC (Sandbox)
- **Components deployed:** `RubrikQuoteLookupController`, `RubrikQuoteLookupControllerTest`, `rubrikQuoteLookup` (JS only)

---

## Change History

| Date | Author | Change Description |
|------|--------|--------------------|
| 2026-04-02 | Documentation Agent | Initial creation |
