# OVF Contact Auto-Fill from Opportunity Contact Role

**Date:** 2026-03-31
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

On the Rubrik Quote Portal (VF page at /rubrikquote), the OVF form's Contact Details section
(Contact Name, Contact Email, Contact Phone) should be auto-populated from the primary
OpportunityContactRole on the quote's linked Opportunity when the user successfully looks up
their quote.

### Business Objective

When a prospect or customer accesses the Rubrik Quote Portal to complete an Order Verification
Form (OVF), the Contact Details section previously required manual entry. Since the portal
already validates the user against the primary OpportunityContactRole on the linked Opportunity,
that same contact record contains the Name, Email, and Phone the user would normally type.
Auto-populating these fields reduces friction and data-entry errors, while still allowing the
user to edit the values before submitting.

### Summary

The `RubrikQuoteLookupController` Apex class was extended so its `QuoteLookupResult` inner class
carries three additional fields — `contactName`, `contactEmail`, and `contactPhone` — populated
from the `OpportunityContactRole` record that already validates access. The `RubrikQuotePortal`
Visualforce page was updated to store those values from the JavaScript Remoting callback and
write them into the rendered OVF input fields immediately after the OVF section is displayed.
The test class was updated and extended with two new tests to verify both the null-phone and
populated-phone branches.

No new metadata, objects, or classes were created. All changes are confined to three existing
files.

---

## Components Created

### Admin Components (Declarative)

None. All required OVF fields (`Contact_Name__c`, `Contact_Email__c`, `Contact_Phone__c`) and
their membership in the `AWSOVFFieldSet` field set already existed before this task.

---

### Development Components (Code)

#### Apex Classes Modified

| Class Name | Type | Change Summary |
|------------|------|----------------|
| `RubrikQuoteLookupController` | Controller / Service | Added 3 fields to `QuoteLookupResult`; expanded OCR `SELECT`; populated new fields after validation |

#### Apex Classes — Inner Classes Modified

| Inner Class | Outer Class | Change |
|-------------|-------------|--------|
| `QuoteLookupResult` | `RubrikQuoteLookupController` | Added `contactName`, `contactEmail`, `contactPhone` (`@AuraEnabled public String`) |
| `GuestQueryHelper` | `RubrikQuoteLookupController` | Expanded `findQuote()` OCR `SELECT` clause; populated 3 new result fields |

#### Visualforce Pages Modified

| Page Name | Change Summary |
|-----------|----------------|
| `RubrikQuotePortal` | Added 3 script-scope variables; stored contact data in remoting callback; auto-populated 3 OVF inputs after `renderOVFFields()` |

#### Test Classes Modified

| Test Class | Changes Made |
|------------|-------------|
| `RubrikQuoteLookupControllerTest` | Added `contactName`/`contactEmail` assertions to two existing success tests; added 2 new test methods for `contactPhone` null and populated branches |

---

## Data Flow

### How It Works

```
1. User enters quote number + email on the portal lookup form, clicks "View OVF"
2. VF page calls Visualforce.remoting.Manager.invokeAction → lookupQuoteVF(@RemoteAction)
3. lookupQuoteVF delegates to lookupQuote, which delegates to GuestQueryHelper.findQuote()
4. GuestQueryHelper (without sharing) runs two SOQL queries:
     a. SBQQ__Quote__c WHERE Name = :quoteName  → gets quoteId + opportunityId
     b. OpportunityContactRole WHERE OpportunityId = :oppId AND IsPrimary = true
                                 AND Contact.Email = :email
        SELECT Id, Contact.Name, Contact.Email, Contact.Phone
5. If no OCR match → returns null (access denied, no form shown)
6. If match found → QuoteLookupResult populated with quoteUrl, quoteId,
   contactName, contactEmail, contactPhone
7. Remoting callback on VF page stores the 3 contact values in JS variables:
     currentContactName, currentContactEmail, currentContactPhone
8. Staged animation transitions from lookup form → OVF section
9. renderOVFFields() is called (clears & recreates all OVF <input> elements)
10. Immediately after renderOVFFields(): JS writes stored contact values into
     ovf_Contact_Name__c, ovf_Contact_Email__c, ovf_Contact_Phone__c inputs
     (Phone field is always reset to '' if absent, preventing stale values on re-lookup)
11. User reviews pre-filled fields, edits if needed, submits OVF
```

### Architecture Diagram

```
  Browser (RubrikQuotePortal VF page)
  ┌────────────────────────────────────────────────────────────────┐
  │  Lookup Form                                                   │
  │  [Quote Number] [Email]  → "View OVF" button                  │
  └──────────────────────────────┬─────────────────────────────────┘
                                 │ Visualforce.remoting (lookupQuoteVF)
                                 ▼
  ┌────────────────────────────────────────────────────────────────┐
  │  RubrikQuoteLookupController  (with sharing)                   │
  │  lookupQuoteVF(@RemoteAction) → lookupQuote(@AuraEnabled)      │
  │    └── GuestQueryHelper.findQuote()  (without sharing)         │
  │         ├── SOQL 1: SBQQ__Quote__c WHERE Name = :quoteName     │
  │         └── SOQL 2: OpportunityContactRole                     │
  │               WHERE OpportunityId = :oppId                     │
  │                 AND IsPrimary = true                           │
  │                 AND Contact.Email = :email                     │
  │               SELECT Id, Contact.Name, Contact.Email,          │
  │                      Contact.Phone                             │
  └──────────────────────────────┬─────────────────────────────────┘
                                 │ QuoteLookupResult
                                 │  { quoteId, quoteUrl,
                                 │    contactName, contactEmail, contactPhone }
                                 ▼
  ┌────────────────────────────────────────────────────────────────┐
  │  JS Remoting Callback                                          │
  │  currentContactName  = result.contactName  || ''               │
  │  currentContactEmail = result.contactEmail || ''               │
  │  currentContactPhone = result.contactPhone || ''               │
  │                                                                │
  │  → Animate to OVF section                                     │
  │  → renderOVFFields()    (recreates all <input> elements)       │
  │  → getElementById('ovf_Contact_Name__c').value  = name         │
  │  → getElementById('ovf_Contact_Email__c').value  = email       │
  │  → getElementById('ovf_Contact_Phone__c').value  = phone || '' │
  └────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
  ┌────────────────────────────────────────────────────────────────┐
  │  OVF Form (editable)                                           │
  │  Contact Name:  [pre-filled]                                   │
  │  Contact Email: [pre-filled]                                   │
  │  Contact Phone: [pre-filled or blank]                          │
  │  ... other OVF fields ...                                      │
  │                     [Submit OVF]                               │
  └────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Reuse the validation OCR query instead of adding a second query | Avoids extra SOQL governor limit consumption; the OCR already validated the user's identity, so its contact data is already the "correct" contact |
| Keep `GuestQueryHelper` without sharing for the expanded query | The Site guest user has no sharing access to CPQ or CRM records; the access gate is the quote-number + primary-email check, not Salesforce sharing |
| Auto-populate after `renderOVFFields()`, not before | `renderOVFFields()` destroys and recreates all input DOM elements; writing values before would be overwritten |
| Phone always resets to `''` if absent | Prevents a stale phone number appearing on a second lookup attempt within the same page session |
| Fields remain fully editable | The user may have a different contact preference; auto-fill is a convenience, not a lock |

---

## File Locations

| Component | Path |
|-----------|------|
| Apex Controller | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |
| Apex Controller Test | `force-app/main/default/classes/RubrikQuoteLookupControllerTest.cls` |
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |

---

## Configuration Details

### QuoteLookupResult Inner Class — Fields

| Field | Type | Annotated | Description |
|-------|------|-----------|-------------|
| `quoteUrl` | `String` | `@AuraEnabled` | URL path `/quotes/{quoteId}` (pre-existing) |
| `quoteId` | `String` | `@AuraEnabled` | Salesforce Id of the matched `SBQQ__Quote__c` (pre-existing) |
| `contactName` | `String` | `@AuraEnabled` | Full name from `Contact.Name` on the matched OCR (new) |
| `contactEmail` | `String` | `@AuraEnabled` | Email from `Contact.Email` on the matched OCR (new) |
| `contactPhone` | `String` | `@AuraEnabled` | Phone from `Contact.Phone` on the matched OCR; `null` if not set (new) |

### GuestQueryHelper — OCR SOQL Change

Before this task the OCR query selected only `Id`:

```sql
SELECT Id
FROM OpportunityContactRole
WHERE OpportunityId = :quotes[0].SBQQ__Opportunity2__c
  AND IsPrimary = true
  AND Contact.Email = :email
LIMIT 1
```

After this task:

```sql
SELECT Id, Contact.Name, Contact.Email, Contact.Phone
FROM OpportunityContactRole
WHERE OpportunityId = :quotes[0].SBQQ__Opportunity2__c
  AND IsPrimary = true
  AND Contact.Email = :email
LIMIT 1
```

The `WHERE` clause and validation logic are unchanged. The extra fields add no query cost
beyond returning the additional columns.

### VF Page — JavaScript Variables Added

Declared at page-script scope alongside `currentQuoteId` (line ~1180):

```javascript
var currentContactName  = null;
var currentContactEmail = null;
var currentContactPhone = null;
```

### VF Page — Remoting Callback Storage (line ~1215)

After `currentQuoteId = result.quoteId`:

```javascript
currentContactName  = result.contactName  || '';
currentContactEmail = result.contactEmail || '';
currentContactPhone = result.contactPhone || '';
```

### VF Page — Auto-Populate (line ~1265, inside Stage 3 setTimeout)

Executed immediately after `renderOVFFields()`:

```javascript
var cnEl = document.getElementById('ovf_Contact_Name__c');
var ceEl = document.getElementById('ovf_Contact_Email__c');
var cpEl = document.getElementById('ovf_Contact_Phone__c');
if (cnEl && currentContactName)  { cnEl.value = currentContactName; }
if (ceEl && currentContactEmail) { ceEl.value = currentContactEmail; }
if (cpEl) { cpEl.value = currentContactPhone || ''; }
```

OVF input IDs follow the pattern `ovf_` + field API name, as established by
`createFieldElement()` in the VF page.

---

## Testing

### Test Coverage Summary

| Class | New Tests Added | Existing Tests Updated | Notes |
|-------|-----------------|----------------------|-------|
| `RubrikQuoteLookupControllerTest` | 2 | 2 | All pre-existing tests continued passing |

### New Test Methods

| Test Method | Purpose |
|-------------|---------|
| `testLookupQuote_contactPhoneNull_whenContactHasNoPhone` | Asserts `contactPhone` is `null` when the matched Contact has no Phone value set (the `@TestSetup` contact omits Phone) |
| `testLookupQuote_contactPhonePopulated_whenContactHasPhone` | Creates an independent data set with a Contact that has a Phone value; asserts `contactPhone`, `contactName`, and `contactEmail` are all correctly returned |

### Existing Tests Updated

| Test Method | Assertion Added |
|-------------|----------------|
| `testLookupQuoteVF_emailMatchesContact_returnsResult` | `Assert.areEqual(TEST_CONTACT_FIRST + ' ' + TEST_CONTACT_LAST, result.contactName, ...)` and `Assert.areEqual(TEST_CONTACT_EMAIL, result.contactEmail, ...)` |
| `testQuoteLookupResult_fieldPopulation` | Same `contactName` and `contactEmail` assertions as above |

### Key Test Scenarios Covered

- Success path: OCR match returns all three contact fields populated
- Success path: OCR match with no Contact.Phone returns `contactPhone = null`
- Success path: OCR match with Contact.Phone returns `contactPhone` correctly
- Failure path: email mismatch returns `null` (existing, unchanged)
- Failure path: unknown quote number returns `null` (existing, unchanged)
- Blank/null input guard returns `null` before any query (existing, unchanged)
- Case-insensitive email matching (existing, unchanged)
- Whitespace trimming of inputs (existing, unchanged)

---

## Security

### Sharing Model

| Class / Helper | Sharing | Reason |
|----------------|---------|--------|
| `RubrikQuoteLookupController` | `with sharing` | Outer class follows project convention |
| `GuestQueryHelper` | `without sharing` | Site guest user has no sharing access to `SBQQ__Quote__c` or `OpportunityContactRole`; access is gated by quote-number + primary-email validation |
| `GuestDmlHelper` | `without sharing` | Site guest user cannot satisfy cross-reference checks on `SBQQ__Quote__c` in a `with sharing` DML context |

### Access Control for Contact Data

The contact fields are only returned when the supplied email matches `IsPrimary = true` on the
Opportunity's `OpportunityContactRole`. An anonymous user who cannot supply the correct primary
contact email receives `null` from the controller and never sees the OVF form. Contact data is
therefore scoped to the contact whose email was used to authenticate the lookup — it cannot
be used to harvest other contacts' data.

### Client-Side Handling

The auto-populated values are written to standard `<input>` elements using `.value`. No `readonly`
or `disabled` attributes are set, so the auto-fill is purely a convenience. The values are also
not used in any hidden fields — they flow through `submitOVF`/`submitOVFDynamic` only when the
user submits the form, at which point server-side truncation (`.abbreviate(255)`) and field-set
allowlist enforcement apply.

---

## Notes and Considerations

### Known Limitations

- **IsPrimary requirement.** The validation AND the auto-fill both depend on `IsPrimary = true`
  on the `OpportunityContactRole`. If the matched contact role is not marked as primary, the
  lookup returns `null` (access denied) and the form is not shown. There is no fallback to "first
  contact role if no primary." This is consistent with existing behavior and an intentional
  design constraint.

- **Standard Phone field only.** `Contact.Phone` is the standard phone field. If the org uses a
  custom phone field as the canonical phone, the query would need adjustment.

- **Single OCR per lookup.** Only the first matching primary OCR is used (`LIMIT 1`). Multiple
  primary contact roles on the same Opportunity with the same email are unlikely but theoretically
  possible; only the first returned would be used.

- **Phone always resets on re-lookup.** If the user clicks "View OVF" a second time (navigating
  back and re-entering details), `currentContactPhone` is overwritten. If the new contact has
  no phone, the phone field is cleared. This is intentional to prevent stale data.

### Future Enhancements

- If business requirements change to allow a non-primary OCR to validate access, the fallback
  query would need to be added as a separate secondary query in `GuestQueryHelper.findQuote()`.
- The `getActiveFieldSetName()` method currently returns a hardcoded value. Future work may
  make it condition-based (e.g., different field sets for different customer segments).
- The three contact variables could be consolidated into a single JS object for cleaner state
  management if additional contact fields are added in the future.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `SBQQ__Quote__c.SBQQ__Opportunity2__c` | CPQ managed package field | Relationship path from quote to opportunity |
| `OpportunityContactRole` (standard object) | CRM standard | Must have at least one record with `IsPrimary = true` for the email match to succeed |
| `Contact.Name`, `Contact.Email`, `Contact.Phone` | Standard Contact fields | All standard; no managed package dependency |
| `OVF__c.Contact_Name__c`, `OVF__c.Contact_Email__c`, `OVF__c.Contact_Phone__c` | Custom fields | Must exist on `OVF__c` and be in `AWSOVFFieldSet` for the OVF submission path |
| `AWSOVFFieldSet` field set | Custom metadata | Server-side write allowlist for `submitOVFDynamic`; also used to render form inputs |
| `ShGl_DisableBusinessLogic__c` | Custom Setting | Used in test setup to suppress CPQ automation during test data creation |
| `TriggerControls` | Custom Apex class | Used in test setup to disable quote and quoteline triggers |

---

## Change History

| Date | Author | Change Description |
|------|--------|--------------------|
| 2026-03-31 | Documentation Agent | Initial creation |
