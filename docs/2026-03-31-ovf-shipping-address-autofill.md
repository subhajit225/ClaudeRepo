# OVF Shipping Address Auto-Fill from Account

**Date:** 2026-03-31
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Auto-fill the address fields in the OVF form (on the RubrikQuotePortal Visualforce page) from the shipping address of the Account linked to the Quote. If a shipping address field is blank on the Account, the corresponding form field should remain blank (no defaulting).

Field mapping:
- `Account.ShippingStreet` (line 1) -> `ovf_Address_1__c`
- `Account.ShippingStreet` (line 2) -> `ovf_Address_2__c` (if present)
- `Account.ShippingCity` -> `ovf_City__c`
- `Account.ShippingState` -> `ovf_State__c`
- `Account.ShippingPostalCode` -> `ovf_Zip_Code__c`
- `Account.ShippingCountry` -> `ovf_Country__c`

### Business Objective

When a customer successfully identifies themselves on the Rubrik Quote Portal by submitting a valid quote number and email, the OVF order form should pre-populate their shipping address so they do not have to type it manually. The address is pulled from the Account record linked to the CPQ Quote, which is already maintained by the Salesforce admin team.

### Summary

Six shipping address fields were added to the `QuoteLookupResult` inner class in `RubrikQuoteLookupController`. The controller's SOQL query was extended to fetch Account shipping address data, and a street-splitting algorithm parses multi-line `ShippingStreet` values into discrete address lines. The `RubrikQuotePortal` Visualforce page captures those values from the RemoteAction response and injects them into the OVF form immediately after it renders.

---

## Components Created

### Admin Components (Declarative)

No declarative components were created or modified. All OVF address fields (`Address_1__c`, `Address_2__c`, `City__c`, `State__c`, `Zip_Code__c`, `Country__c`) already existed on `OVF__c`. Account shipping address fields (`ShippingStreet`, `ShippingCity`, `ShippingState`, `ShippingPostalCode`, `ShippingCountry`) are standard Salesforce fields.

---

### Development Components (Code)

#### Apex Classes

| Class Name | Type | Change Description |
|------------|------|--------------------|
| `RubrikQuoteLookupController` | Controller / Service | Added 6 shipping fields to `QuoteLookupResult`; extended SOQL; added street-splitting logic |

#### Apex Triggers

None created or modified.

#### Test Classes

| Test Class | Tests For | Key New Scenarios |
|------------|-----------|-------------------|
| `RubrikQuoteLookupControllerTest` | `RubrikQuoteLookupController` | Shipping field assertions added to two existing success tests; `@TestSetup` Account now includes a full two-line shipping address |

#### Visualforce Pages

| Page | Change Description |
|------|--------------------|
| `RubrikQuotePortal.page` | 6 JS variables declared; captured from RemoteAction result; auto-filled into OVF form fields after `renderOVFFields()` |

#### Lightning Web Components

None created or modified.

---

## Data Flow

### How It Works

```
1. User enters quote number + email on the Rubrik Quote Portal landing form
2. handleSubmit() fires a Visualforce RemoteAction call to lookupQuoteVF()
3. lookupQuoteVF() delegates to lookupQuote() -> GuestQueryHelper.findQuote()
4. findQuote() queries SBQQ__Quote__c with a cross-object traversal to
   SBQQ__Account__r, retrieving ShippingStreet, ShippingCity, ShippingState,
   ShippingPostalCode, and ShippingCountry
5. ShippingStreet is normalised (\r stripped) and split on \n (limit 2):
     line 1 -> result.shippingAddress1
     line 2 -> result.shippingAddress2 (null if only one line)
6. City, State, PostalCode, Country are assigned directly (null stays null)
7. The QuoteLookupResult JSON is returned to the browser
8. handleSubmit() callback stores the 6 shipping values in module-level
   JS variables (currentShippingAddress1 … currentShippingCountry)
9. After renderOVFFields() paints the OVF form, each address element is
   located by getElementById and its .value is set from the stored variable
10. User sees shipping address pre-filled; they may edit before submitting
```

### Architecture Diagram

```
┌──────────────────────┐     ┌────────────────────────────┐
│  Quote Portal (VF)   │────>│  lookupQuoteVF             │
│  handleSubmit()      │     │  (@RemoteAction)            │
│  RemoteAction call   │     └────────────┬───────────────┘
└──────────────────────┘                  │
                                          v
                              ┌────────────────────────────┐
                              │  GuestQueryHelper          │
                              │  (without sharing)         │
                              │  findQuote()               │
                              │                            │
                              │  SELECT ... ShippingStreet,│
                              │    ShippingCity, ...       │
                              │  FROM SBQQ__Quote__c       │
                              │  WHERE Name = :quoteName   │
                              └────────────┬───────────────┘
                                          │
                                          v
                              ┌────────────────────────────┐
                              │  Street-splitting logic     │
                              │  strip \r, split on \n     │
                              │  line[0] -> address1       │
                              │  line[1] -> address2       │
                              └────────────┬───────────────┘
                                          │
                                          v
                              ┌────────────────────────────┐
                              │  QuoteLookupResult         │
                              │  shippingAddress1/2        │
                              │  shippingCity/State/       │
                              │  ZipCode/Country           │
                              └────────────┬───────────────┘
                                          │  JSON response
                                          v
┌──────────────────────┐     ┌────────────────────────────┐
│  OVF Form fields     │<────│  handleSubmit() callback   │
│  ovf_Address_1__c    │     │  currentShippingAddress1…  │
│  ovf_Address_2__c    │     │  currentShippingCountry    │
│  ovf_City__c         │     │  getElementById + .value   │
│  ovf_State__c        │     │  (after renderOVFFields()) │
│  ovf_Zip_Code__c     │     └────────────────────────────┘
│  ovf_Country__c      │
└──────────────────────┘
```

---

## File Locations

| Component | Path |
|-----------|------|
| Apex controller | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |
| Apex test class | `force-app/main/default/classes/RubrikQuoteLookupControllerTest.cls` |
| Visualforce page | `force-app/main/default/pages/RubrikQuotePortal.page` |

---

## Configuration Details

### QuoteLookupResult Inner Class — New Fields

| Field Name | Apex Type | Source Field | Notes |
|------------|-----------|--------------|-------|
| `shippingAddress1` | `String` | `SBQQ__Account__r.ShippingStreet` line 1 | Null if `ShippingStreet` is blank |
| `shippingAddress2` | `String` | `SBQQ__Account__r.ShippingStreet` line 2 | Null if only one line or `ShippingStreet` is blank |
| `shippingCity` | `String` | `SBQQ__Account__r.ShippingCity` | Direct assignment; null propagates |
| `shippingState` | `String` | `SBQQ__Account__r.ShippingState` | Direct assignment; null propagates |
| `shippingZipCode` | `String` | `SBQQ__Account__r.ShippingPostalCode` | Direct assignment; null propagates |
| `shippingCountry` | `String` | `SBQQ__Account__r.ShippingCountry` | Direct assignment; null propagates |

### Street-Splitting Logic

`ShippingStreet` may contain Windows-style (`\r\n`) or Unix-style (`\n`) line endings because Salesforce stores whatever the user typed in the Address UI.

```
String street = quotes[0].SBQQ__Account__r.ShippingStreet;
if (String.isNotBlank(street)) {
    List<String> lines = street.replaceAll('\\r', '').split('\n', 2);
    result.shippingAddress1 = lines[0].trim();
    result.shippingAddress2 = lines.size() > 1 ? lines[1].trim() : null;
}
```

- `replaceAll('\\r', '')` removes all carriage-return characters before splitting.
- `split('\n', 2)` splits into at most 2 parts; any extra newlines in the second part are left intact.
- Each extracted line is trimmed of leading/trailing whitespace.

### SOQL Changes

Five cross-object fields were added to the existing `SELECT` on `SBQQ__Quote__c` inside `GuestQueryHelper.findQuote()`. The `SBQQ__Account__r` relationship was already traversed for `.Name`, so no additional join is incurred.

```sql
SELECT Id, Name, SBQQ__Opportunity2__c, SBQQ__Account__r.Name,
       SBQQ__Account__r.ShippingStreet,
       SBQQ__Account__r.ShippingCity,
       SBQQ__Account__r.ShippingState,
       SBQQ__Account__r.ShippingPostalCode,
       SBQQ__Account__r.ShippingCountry
FROM SBQQ__Quote__c
WHERE Name = :quoteName
LIMIT 1
```

### Visualforce Page JS Changes

**Variable declarations** (after `var currentCompanyName = null;`):

```javascript
var currentShippingAddress1 = null;
var currentShippingAddress2 = null;
var currentShippingCity     = null;
var currentShippingState    = null;
var currentShippingZipCode  = null;
var currentShippingCountry  = null;
```

**Capture in RemoteAction callback** (after `currentCompanyName` assignment):

```javascript
currentShippingAddress1 = result.shippingAddress1 || '';
currentShippingAddress2 = result.shippingAddress2 || '';
currentShippingCity     = result.shippingCity     || '';
currentShippingState    = result.shippingState    || '';
currentShippingZipCode  = result.shippingZipCode  || '';
currentShippingCountry  = result.shippingCountry  || '';
```

**Auto-fill block** (after `renderOVFFields()`, following the existing company/buyer name block):

```javascript
var addr1El   = document.getElementById('ovf_Address_1__c');
var addr2El   = document.getElementById('ovf_Address_2__c');
var cityEl    = document.getElementById('ovf_City__c');
var stateEl   = document.getElementById('ovf_State__c');
var zipEl     = document.getElementById('ovf_Zip_Code__c');
var countryEl = document.getElementById('ovf_Country__c');
if (addr1El)   { addr1El.value   = currentShippingAddress1; }
if (addr2El)   { addr2El.value   = currentShippingAddress2; }
if (cityEl)    { cityEl.value    = currentShippingCity; }
if (stateEl)   { stateEl.value   = currentShippingState; }
if (zipEl)     { zipEl.value     = currentShippingZipCode; }
if (countryEl) { countryEl.value = currentShippingCountry; }
```

The `getElementById` null-check pattern matches the existing pattern used for contact and company fields and guards against field sets that omit certain address fields.

---

## Testing

### Test Coverage Summary

| Class | Key Scenarios Added |
|-------|---------------------|
| `RubrikQuoteLookupControllerTest` | `testLookupQuoteVF_emailMatchesContact_returnsResult` — asserts all 6 shipping fields |
| `RubrikQuoteLookupControllerTest` | `testQuoteLookupResult_fieldPopulation` — asserts all 6 shipping fields via `lookupQuote` |

### TestSetup Changes

The `@TestSetup` Account record was updated to include a full two-line shipping address:

```apex
Account acct = new Account(
    Name               = 'Test OVF Account',
    ShippingStreet     = '123 Main St\nSuite 400',
    ShippingCity       = 'San Francisco',
    ShippingState      = 'CA',
    ShippingPostalCode = '94105',
    ShippingCountry    = 'US'
);
```

### Key Test Assertions

| Scenario | Expected Behaviour |
|----------|--------------------|
| Two-line `ShippingStreet` | `shippingAddress1 = '123 Main St'`, `shippingAddress2 = 'Suite 400'` |
| `ShippingCity` populated | `shippingCity = 'San Francisco'` |
| `ShippingState` populated | `shippingState = 'CA'` |
| `ShippingPostalCode` populated | `shippingZipCode = '94105'` |
| `ShippingCountry` populated | `shippingCountry = 'US'` |
| Blank `ShippingStreet` | `shippingAddress1 = null`, `shippingAddress2 = null` |
| Any null source field | Corresponding result field is null; no defaulting |

---

## Security

### Sharing Model

- `RubrikQuoteLookupController` is declared `with sharing`.
- The SOQL that reads shipping address data runs inside `GuestQueryHelper`, which is `without sharing`. This is intentional: the Visualforce page is served to an unauthenticated Site guest user who has no sharing access to CPQ or CRM records. Access is gated by the quote-number + primary-contact-email check, not by record sharing.
- No new object permissions or field-level security changes are required. Standard Account shipping address fields are readable by the System context inside `without sharing`.

### Required Permissions

No changes to permission sets or profiles are required. The guest user context already had access to the `SBQQ__Account__r` relationship; the new fields are standard Address compound fields on Account.

---

## Notes and Considerations

### Null and Blank Field Handling

- If `ShippingStreet` is null or blank on the Account, both `shippingAddress1` and `shippingAddress2` are null on the result.
- If any other shipping field is null on the Account, the corresponding result field is null.
- In the JS callback, `result.shippingAddress1 || ''` converts null to an empty string so the module-level variable is never null after a successful lookup.
- A null/empty variable results in an empty string being written to the form element `.value`, which leaves the field visually blank — consistent with the requirement that blank Account fields produce blank form fields.

### Multi-Line Street Handling

- `split('\n', 2)` with a limit of 2 means that if `ShippingStreet` has three or more lines (uncommon but possible), lines 3+ are concatenated into `shippingAddress2` separated by `\n`. This matches the design intent: the form only has two address lines.
- Each line is trimmed, so extra whitespace introduced by copy-paste into the Account record is removed.

### OVF Field Set Dependency

The auto-fill only writes to elements that exist in the DOM at the time `renderOVFFields()` completes. If the active OVF field set (`AWSOVFFieldSet`) does not include one or more address fields, `getElementById` returns null and the null-check silently skips that field. This means the feature degrades gracefully when address fields are removed from the field set.

### No OVF Submit Changes

`submitOVF` and `submitOVFDynamic` were not modified. The address values the user ultimately submits are read from the form fields at submission time; this feature only pre-populates those fields.

### Known Limitations

- The feature relies on `SBQQ__Account__r` being populated on the CPQ Quote. Quotes without a linked Account will have all six shipping fields as null.
- `ShippingStreet` line 2 captures everything after the first newline (including any third line). If an Account has a three-line street, the second address line field will contain lines 2 and 3 joined by `\n`.
- There is no server-side validation that the address fields populated in the Apex result match what the user ultimately submits via `submitOVF` or `submitOVFDynamic`. The pre-fill is a convenience; the user may edit any field before submitting.

### Future Enhancements

- Consider falling back to billing address if shipping address is blank on the Account.
- Consider adding address auto-fill to the LWC version of the quote lookup flow (`lookupQuote` @AuraEnabled method already returns the same fields).

### Dependencies

| Dependency | Reason |
|------------|--------|
| `SBQQ__Quote__c.SBQQ__Account__c` lookup | Must be populated for shipping fields to return data |
| `OVF__c` field set `AWSOVFFieldSet` | Address fields must be members of the active field set for DOM elements to exist |
| Standard Account shipping address fields | `ShippingStreet`, `ShippingCity`, `ShippingState`, `ShippingPostalCode`, `ShippingCountry` |

---

## Change History

| Date | Author | Change Description |
|------|--------|--------------------|
| 2026-03-31 | Documentation Agent | Initial creation |
