# OVF Auto-Fill: Company Name and Buyer Name

**Date:** 2026-03-31
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

In addition to Contact Name/Email/Phone (previous task), also auto-populate:
- `Company_Name__c` — from the Account Name linked to the Quote (`SBQQ__Account__r.Name`)
- `Buyer_Name__c` — from the Contact Name (same primary OCR contact, per business decision: Buyer Name = Contact Name)

### Business Objective

After the previous task pre-filled the Contact Details section of the OVF form, two additional
fields — Company Name and Buyer Name — still required manual entry. Company Name is reliably
available from the Account linked to the CPQ Quote (the same record already queried during the
lookup). The business explicitly confirmed that Buyer Name should default to the primary contact's
full name, since the buyer contact is the same person identified during the portal authentication
step. Auto-filling both fields reduces data-entry burden and human error without requiring any
new queries.

### Summary

`RubrikQuoteLookupController` was extended with one new field on `QuoteLookupResult`
(`companyName`) sourced from `SBQQ__Account__r.Name` on the quote. The `RubrikQuotePortal`
Visualforce page was updated to capture and write that value into the `Company_Name__c` OVF
input, and to write the already-available `currentContactName` value into the `Buyer_Name__c`
OVF input. The test class was updated with new assertions and a new edge-case test. No new
files, objects, or declarative metadata were created.

---

## Components Created

### Admin Components (Declarative)

None. `Company_Name__c` and `Buyer_Name__c` already exist as fields on `OVF__c` and are
members of `AWSOVFFieldSet`. No new fields, objects, validation rules, flows, or permission
sets were needed.

---

### Development Components (Code)

#### Apex Classes Modified

| Class Name | Type | Change Summary |
|------------|------|----------------|
| `RubrikQuoteLookupController` | Controller / Service | Added `companyName` to `QuoteLookupResult`; added `SBQQ__Account__r.Name` to quote SOQL; populated `result.companyName` |

#### Apex Classes — Inner Classes Modified

| Inner Class | Outer Class | Change |
|-------------|-------------|--------|
| `QuoteLookupResult` | `RubrikQuoteLookupController` | Added `companyName` (`@AuraEnabled public String`) as the sixth field |
| `GuestQueryHelper` | `RubrikQuoteLookupController` | Added `SBQQ__Account__r.Name` to the `SBQQ__Quote__c` SELECT clause; populated `result.companyName` from `quotes[0].SBQQ__Account__r.Name` |

#### Visualforce Pages Modified

| Page Name | Change Summary |
|-----------|----------------|
| `RubrikQuotePortal` | Added `currentCompanyName` JS variable; captured `result.companyName` in remoting callback; auto-filled `Company_Name__c` and `Buyer_Name__c` inputs after `renderOVFFields()` |

#### Test Classes Modified

| Test Class | Changes Made |
|------------|-------------|
| `RubrikQuoteLookupControllerTest` | Added `companyName` assertion to `testLookupQuoteVF_emailMatchesContact_returnsResult`; added `companyName` assertion to `testQuoteLookupResult_fieldPopulation`; added new test `testLookupQuote_noAccount_companyNameIsNull` |

---

## Data Flow

### How It Works

```
1. User enters quote number + email on the portal lookup form and clicks "View OVF"
2. VF page calls Visualforce.remoting.Manager.invokeAction → lookupQuoteVF(@RemoteAction)
3. lookupQuoteVF delegates to lookupQuote, which delegates to GuestQueryHelper.findQuote()
4. GuestQueryHelper (without sharing) runs two SOQL queries:
     a. SBQQ__Quote__c WHERE Name = :quoteName
        SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Account__r.Name
        → returns quoteId, opportunityId, and Account Name in a single relationship hop
     b. OpportunityContactRole WHERE OpportunityId = :oppId AND IsPrimary = true
                                 AND Contact.Email = :email
        SELECT Id, Contact.Name, Contact.Email, Contact.Phone
        → validates the user's identity and returns contact fields
5. If no match at either step → returns null (access denied, form not shown)
6. If matched → QuoteLookupResult populated:
     { quoteId, quoteUrl, contactName, contactEmail, contactPhone, companyName }
7. Remoting callback on VF page stores values in JS page-scope variables:
     currentQuoteId, currentContactName, currentContactEmail,
     currentContactPhone, currentCompanyName
8. Staged animation transitions from lookup form to OVF section
9. renderOVFFields() is called (destroys and recreates all OVF <input> elements)
10. Immediately after renderOVFFields(), JS writes stored values into OVF inputs:
     ovf_Contact_Name__c   ← currentContactName
     ovf_Contact_Email__c  ← currentContactEmail
     ovf_Contact_Phone__c  ← currentContactPhone ('' if absent)
     ovf_Company_Name__c   ← currentCompanyName  ('' if absent)
     ovf_Buyer_Name__c     ← currentContactName  (business decision: Buyer = Contact)
11. User reviews pre-filled fields, edits if needed, and submits OVF
```

### Architecture Diagram

```
  Browser (RubrikQuotePortal VF page)
  ┌─────────────────────────────────────────────────────────────────────┐
  │  Lookup Form                                                        │
  │  [Quote Number] [Email]  → "View OVF" button                       │
  └───────────────────────────────┬─────────────────────────────────────┘
                                  │ Visualforce.remoting (lookupQuoteVF)
                                  ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │  RubrikQuoteLookupController  (with sharing)                        │
  │  lookupQuoteVF(@RemoteAction) → lookupQuote(@AuraEnabled)           │
  │    └── GuestQueryHelper.findQuote()  (without sharing)              │
  │         ├── SOQL 1: SBQQ__Quote__c WHERE Name = :quoteName          │
  │         │     SELECT Id, Name, SBQQ__Opportunity2__c,               │
  │         │            SBQQ__Account__r.Name                          │
  │         │     → one relationship hop; no extra query                │
  │         └── SOQL 2: OpportunityContactRole                          │
  │               WHERE OpportunityId = :oppId                          │
  │                 AND IsPrimary = true                                │
  │                 AND Contact.Email = :email                          │
  │               SELECT Id, Contact.Name, Contact.Email, Contact.Phone │
  └───────────────────────────────┬─────────────────────────────────────┘
                                  │ QuoteLookupResult
                                  │  { quoteId, quoteUrl,
                                  │    contactName, contactEmail, contactPhone,
                                  │    companyName }   ← NEW
                                  ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │  JS Remoting Callback                                               │
  │  currentContactName  = result.contactName  || ''                    │
  │  currentContactEmail = result.contactEmail || ''                    │
  │  currentContactPhone = result.contactPhone || ''                    │
  │  currentCompanyName  = result.companyName  || ''   ← NEW            │
  │                                                                     │
  │  → Animate to OVF section                                          │
  │  → renderOVFFields()    (recreates all <input> elements)            │
  │  → getElementById('ovf_Contact_Name__c').value  = contactName       │
  │  → getElementById('ovf_Contact_Email__c').value  = contactEmail     │
  │  → getElementById('ovf_Contact_Phone__c').value  = contactPhone     │
  │  → getElementById('ovf_Company_Name__c').value  = companyName  ← NEW│
  │  → getElementById('ovf_Buyer_Name__c').value    = contactName  ← NEW│
  └─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │  OVF Form (editable)                                                │
  │  Contact Name:  [pre-filled]                                        │
  │  Contact Email: [pre-filled]                                        │
  │  Contact Phone: [pre-filled or blank]                               │
  │  Company Name:  [pre-filled from Account]           ← NEW           │
  │  Buyer Name:    [pre-filled = Contact Name]         ← NEW           │
  │  ... other OVF fields ...                                           │
  │                     [Submit OVF]                                    │
  └─────────────────────────────────────────────────────────────────────┘
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Source `Company_Name__c` from `SBQQ__Account__r.Name` (one relationship hop) | The Quote's `SBQQ__Account__c` lookup is already on the queried `SBQQ__Quote__c` record. One hop vs. two hops via `SBQQ__Opportunity2__r.Account.Name`; same data, lower complexity |
| No new Apex field for `Buyer_Name__c` | The business confirmed Buyer Name equals Contact Name. The value is already in `result.contactName` / `currentContactName`. A JS-only write to `ovf_Buyer_Name__c` is sufficient |
| `companyName` is `null`-safe | If the Quote has no linked Account, `SBQQ__Account__r.Name` resolves to `null`. The result field carries `null`; the JS guard (`currentCompanyName || ''`) prevents writing `null` to the input |
| Auto-populate after `renderOVFFields()`, not before | `renderOVFFields()` destroys and recreates all input DOM elements. Writing before it would be overwritten immediately |
| Fields remain fully editable | Auto-fill is a convenience, not enforcement. The user can change Company Name or Buyer Name before submitting |

---

## File Locations

| Component | Path |
|-----------|------|
| Apex Controller | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |
| Apex Controller Test | `force-app/main/default/classes/RubrikQuoteLookupControllerTest.cls` |
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |

---

## Configuration Details

### QuoteLookupResult Inner Class — Complete Field List

| Field | Type | Annotated | Status | Description |
|-------|------|-----------|--------|-------------|
| `quoteUrl` | `String` | `@AuraEnabled` | Pre-existing | URL path `/quotes/{quoteId}` |
| `quoteId` | `String` | `@AuraEnabled` | Pre-existing | Salesforce Id of the matched `SBQQ__Quote__c` |
| `contactName` | `String` | `@AuraEnabled` | Added in previous task | Full name from `Contact.Name` on matched OCR |
| `contactEmail` | `String` | `@AuraEnabled` | Added in previous task | Email from `Contact.Email` on matched OCR |
| `contactPhone` | `String` | `@AuraEnabled` | Added in previous task | Phone from `Contact.Phone`; `null` if not set |
| `companyName` | `String` | `@AuraEnabled` | **Added this task** | Account Name from `SBQQ__Account__r.Name`; `null` if Quote has no Account |

### GuestQueryHelper — Quote SOQL Change

Before this task:

```sql
SELECT Id, Name, SBQQ__Opportunity2__c
FROM SBQQ__Quote__c
WHERE Name = :quoteName
LIMIT 1
```

After this task:

```sql
SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Account__r.Name
FROM SBQQ__Quote__c
WHERE Name = :quoteName
LIMIT 1
```

The `SBQQ__Account__r.Name` field traverses the standard CPQ `SBQQ__Account__c` lookup on
`SBQQ__Quote__c` in a single relationship hop. No additional query is issued; the Account Name
is returned as part of the same SOQL row.

After the OCR query, the result object is now populated as follows:

```apex
result.quoteUrl     = '/quotes/' + quotes[0].Id;
result.quoteId      = quotes[0].Id;
result.contactName  = ocrs[0].Contact.Name;
result.contactEmail = ocrs[0].Contact.Email;
result.contactPhone = ocrs[0].Contact.Phone;
result.companyName  = quotes[0].SBQQ__Account__r.Name;  // NEW
```

### VF Page — JavaScript Variables (page-scope)

Declared at page-script scope alongside `currentQuoteId` (around line 1180):

```javascript
var currentContactName  = null;   // from previous task
var currentContactEmail = null;   // from previous task
var currentContactPhone = null;   // from previous task
var currentCompanyName  = null;   // NEW — mirrors QuoteLookupResult.companyName
```

All five variables are declared at page scope so they persist across the staged animation
timeouts and are available when `renderOVFFields()` returns.

### VF Page — Remoting Callback Storage (around line 1215)

```javascript
currentQuoteId      = result.quoteId;
currentContactName  = result.contactName  || '';
currentContactEmail = result.contactEmail || '';
currentContactPhone = result.contactPhone || '';
currentCompanyName  = result.companyName  || '';  // NEW
```

### VF Page — Auto-Populate Block (inside Stage 3 setTimeout, after renderOVFFields())

Full auto-fill block as it exists after this task:

```javascript
renderOVFFields();
// Auto-fill contact fields from OCR (previous task)
var cnEl = document.getElementById('ovf_Contact_Name__c');
var ceEl = document.getElementById('ovf_Contact_Email__c');
var cpEl = document.getElementById('ovf_Contact_Phone__c');
if (cnEl && currentContactName)  { cnEl.value = currentContactName; }
if (ceEl && currentContactEmail) { ceEl.value = currentContactEmail; }
if (cpEl) { cpEl.value = currentContactPhone || ''; }
// Auto-fill company and buyer name (this task)
var cnameEl = document.getElementById('ovf_Company_Name__c');
var bnameEl = document.getElementById('ovf_Buyer_Name__c');
if (cnameEl) { cnameEl.value = currentCompanyName || ''; }
if (bnameEl) { bnameEl.value = currentContactName || ''; }
```

OVF input IDs follow the pattern `ovf_` + field API name, as established by the
`createFieldElement()` helper in the VF page. The guard pattern (`if (el)`) handles
the case where a field is not present in the active field set and therefore has no
rendered input element.

Note that `Company_Name__c` and `Buyer_Name__c` do not use an `&& currentValue`
guard — they always write (defaulting to `''`). This is consistent with the Phone
field treatment and prevents stale values on a re-lookup.

---

## Testing

### Test Coverage Summary

| Class | New Test Methods | Existing Tests Updated | Notes |
|-------|-----------------|----------------------|-------|
| `RubrikQuoteLookupControllerTest` | 1 | 2 | All pre-existing tests continued passing |

### New Test Method

| Test Method | Purpose |
|-------------|---------|
| `testLookupQuote_noAccount_companyNameIsNull` | Creates a Quote with no `SBQQ__Account__c` set and a matching OCR contact. Asserts that `result` is not null (the lookup succeeds) and that `result.companyName` is `null` (no account to read from). Exercises the null-relationship branch of `SBQQ__Account__r.Name` |

### Existing Tests Updated

| Test Method | Assertion Added |
|-------------|----------------|
| `testLookupQuoteVF_emailMatchesContact_returnsResult` | `Assert.areEqual('Test OVF Account', result.companyName, 'companyName should be populated from the quote account name')` |
| `testQuoteLookupResult_fieldPopulation` | `Assert.areEqual('Test OVF Account', result.companyName, 'companyName on QuoteLookupResult should be populated from the account')` |

Both updated tests use the Account created in `@TestSetup` with `Name = 'Test OVF Account'`
and assigned to the test quote via `SBQQ__Account__c = acct.Id`.

### Key Test Scenarios Covered

- Success path: matched quote with Account returns `companyName = 'Test OVF Account'`
- Success path: full `QuoteLookupResult` field population including `companyName`
- Edge case: matched quote with no linked Account returns `companyName = null` without
  throwing an exception
- All prior contact field scenarios from the previous task remain covered and passing

---

## Security

### Sharing Model

| Class / Helper | Sharing | Reason |
|----------------|---------|--------|
| `RubrikQuoteLookupController` | `with sharing` | Outer class follows project convention |
| `GuestQueryHelper` | `without sharing` | Site guest user has no sharing access to `SBQQ__Quote__c`, `Account`, or `OpportunityContactRole`. Access is gated by the quote-number + primary-email validation inside `findQuote()` |
| `GuestDmlHelper` | `without sharing` | Site guest user cannot satisfy cross-reference checks on `SBQQ__Quote__c` in a `with sharing` DML context |

### Data Exposure Considerations

`companyName` is the Account Name of the Account linked to the Quote being accessed. It is
returned only after the visitor supplies the correct primary contact email, so it is scoped
to the Account associated with the quote they already had legitimate access to verify.
`Buyer_Name__c` auto-fill reuses `contactName`, which was already returned to the client
and carries the same access constraint.

### Client-Side Handling

Values are written to standard rendered `<input>` elements via `.value`. They are not stored
in hidden fields. On form submission, server-side truncation (`.abbreviate(255)`) and the
field-set write allowlist in `submitOVFDynamic` enforce the final values accepted for DML.

---

## Notes and Considerations

### Known Limitations

- **Null Account.** If a Quote has no `SBQQ__Account__c`, `SBQQ__Account__r.Name` resolves to
  `null` at the Apex layer. The JS guard `currentCompanyName || ''` writes an empty string to the
  `Company_Name__c` input in that case. The user would need to fill it in manually.

- **CPQ-managed Account field.** `SBQQ__Account__c` is set by CPQ when a quote is created from
  an Opportunity. Quotes created via API without an Account will have a null relationship. In
  production this is rare but theoretically possible.

- **Buyer Name cannot diverge from Contact Name automatically.** The business decision to set
  Buyer Name = Contact Name is hardcoded in the VF page JS. If a future use case requires a
  different source for Buyer Name (e.g., a separate OVF-specific contact), a new Apex field and
  query change would be required.

- **IsPrimary requirement.** The contact name driving both `Contact_Name__c` and `Buyer_Name__c`
  comes from the primary OCR. If no primary OCR exists for the supplied email, the lookup returns
  null and the form is not shown at all.

- **Re-lookup behavior.** If the user navigates back and performs a second lookup, all five
  JS variables are overwritten with the new result, including `currentCompanyName`. This is
  intentional to prevent stale data.

### Future Enhancements

- If `Buyer_Name__c` needs to be sourced from a different contact or field, add a `buyerName`
  field to `QuoteLookupResult`, source it from a separate query in `GuestQueryHelper.findQuote()`,
  and update the VF page JS to use `result.buyerName` instead of `currentContactName`.
- `getActiveFieldSetName()` currently returns a hardcoded value (`AWSOVFFieldSet`). Future
  iterations may add conditional field-set selection (e.g., different sets per product line).
- Consider consolidating the five page-scope JS variables into a single state object
  (`currentLookupResult = {}`) if more fields are added in future auto-fill tasks.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `SBQQ__Quote__c.SBQQ__Account__c` | CPQ managed package field | Lookup to Account; `SBQQ__Account__r.Name` traverses this in a single hop |
| `SBQQ__Quote__c.SBQQ__Opportunity2__c` | CPQ managed package field | Relationship path from quote to opportunity used in the OCR query |
| `Account.Name` | Standard CRM field | Source for `companyName` on the result |
| `OpportunityContactRole` (standard object) | CRM standard | Must have a record with `IsPrimary = true` and matching email for the lookup to succeed |
| `OVF__c.Company_Name__c`, `OVF__c.Buyer_Name__c` | Custom fields (pre-existing) | Target OVF fields; must be present in `AWSOVFFieldSet` for the dynamic render and DML allowlist |
| `AWSOVFFieldSet` field set | Custom metadata (pre-existing) | Server-side write allowlist for `submitOVFDynamic`; drives field rendering |
| `ShGl_DisableBusinessLogic__c` | Custom Setting | Used in test setup to suppress CPQ automation |
| `TriggerControls` | Custom Apex class | Used in test setup to disable quote and quoteline triggers |

---

## Relationship to Previous Task

This task is a direct extension of "OVF Contact Auto-Fill from Opportunity Contact Role"
(documented in `docs/2026-03-31-ovf-contact-autofill-from-ocr.md`). That task introduced the
`QuoteLookupResult` structure and the JS auto-fill pattern. This task adds one more Apex result
field and two more OVF input writes using the same established pattern. The prior task's test
infrastructure (`@TestSetup` with Account `'Test OVF Account'` linked to the quote) was already
in place and required no additional setup changes.

---

## Change History

| Date | Author | Change Description |
|------|--------|--------------------|
| 2026-03-31 | Documentation Agent | Initial creation |
