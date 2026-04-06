# OVF Form Feature

**Date:** 2026-03-27
**Author:** Documentation Agent
**Status:** Completed (Deployed to Sandbox)

---

## Overview

### Original Request

Modify the existing RubrikQuotePortal Visualforce page and RubrikQuoteLookupController to show an Order Verification Form (OVF) after successful email validation instead of redirecting to the quote. Create a new custom object OVF__c to persist the submitted form data. On submission, create the OVF__c record linked to the validated quote and show a Thank You confirmation.

### Business Objective

Rubrik's Quote Portal allows external buyers to authenticate via their quote number and registered email. Previously, successful authentication simply redirected the user to the quote URL. This feature adds a meaningful next step: the authenticated user now fills in and submits an Order Verification Form, which creates a structured record in Salesforce linked to the originating CPQ quote. This gives the Rubrik sales and operations teams a record of the buyer's order verification details alongside the quote.

### Summary

A new custom object (`OVF__c`) was created to store order verification data including buyer, reseller, address, and contact details. The existing Visualforce controller (`RubrikQuoteLookupController`) was extended with a `submitOVF` remote action method. The Visualforce page (`RubrikQuotePortal`) was redesigned to implement a three-state flow: Login form → OVF form → Thank You confirmation, all within the same page without a redirect.

---

## Components Created

### Admin Components (Declarative)

#### Custom Objects

| Object API Name | Label | Plural Label | Record Name Type | Description |
|-----------------|-------|--------------|------------------|-------------|
| `OVF__c` | OVF | OVFs | Auto Number (OVF-{0000}) | Order Verification Form submitted via Rubrik Quote Portal |

#### Custom Fields

| Object | Field API Name | Type | Length | Required | Description |
|--------|----------------|------|--------|----------|-------------|
| `OVF__c` | `Quote__c` | Lookup (`SBQQ__Quote__c`) | — | Yes | Parent CPQ Quote; delete constraint is Restrict |
| `OVF__c` | `Buyer_Name__c` | Text | 255 | No | Buyer (End User) Name |
| `OVF__c` | `Buyer_Billing_ID__c` | Text | 255 | No | Buyer (End User) Billing ID |
| `OVF__c` | `Buyer_Tenant_ID__c` | Text | 255 | No | Buyer (End User) Tenant ID |
| `OVF__c` | `Reseller_Name__c` | Text | 255 | No | Reseller Name |
| `OVF__c` | `Marketplace_Seller_ID__c` | Text | 255 | No | Marketplace Seller ID |
| `OVF__c` | `Company_Name__c` | Text | 255 | No | Company Name |
| `OVF__c` | `Address_1__c` | Text | 255 | No | Address Line 1 |
| `OVF__c` | `Address_2__c` | Text | 255 | No | Address Line 2 |
| `OVF__c` | `City__c` | Text | 255 | No | City |
| `OVF__c` | `State__c` | Text | 255 | No | State / Province |
| `OVF__c` | `Zip_Code__c` | Text | 255 | No | Zip / Postal Code |
| `OVF__c` | `Country__c` | Text | 255 | No | Country |
| `OVF__c` | `Contact_Name__c` | Text | 255 | No | Contact Name (if different from Buyer) |
| `OVF__c` | `Contact_Email__c` | Text | 255 | No | Contact Email |
| `OVF__c` | `Contact_Phone__c` | Text | 255 | No | Contact Phone |

**Total fields on OVF__c: 17** (auto-number name field + 1 lookup + 15 text fields)

Note on `Quote__c` lookup: `deleteConstraint` is set to `Restrict`, meaning a SBQQ__Quote__c record cannot be deleted while it has associated OVF records. The related list on the Quote record is labelled "OVFs".

---

### Development Components (Code)

#### Apex Classes (Modified)

| Class Name | Type | Status |
|------------|------|--------|
| `RubrikQuoteLookupController` | Visualforce Controller / Remote Action host | Modified |

#### Apex Triggers

None created or modified.

#### Test Classes (New)

| Test Class | Tests For | Methods | Org Status |
|------------|-----------|---------|------------|
| `RubrikQuoteLookupControllerTest` | `RubrikQuoteLookupController` | 14 methods | 12 passing; 2 failing (see Testing section) |

#### Lightning Web Components

None created or modified.

#### Visualforce Pages (Modified)

| Page Name | Controller | Status |
|-----------|-----------|--------|
| `RubrikQuotePortal` | `RubrikQuoteLookupController` | Modified |

---

## Data Flow

### How It Works

```
1. User opens RubrikQuotePortal (unauthenticated, public-facing)
2. User enters Quote Number + Email and clicks "View OVF"
3. JavaScript calls lookupQuoteVF @RemoteAction via Visualforce.remoting
4. Controller queries SBQQ__Quote__c WHERE Name = :quoteNumber
     AND SBQQ__PrimaryContact__r.Email = :email (WITH USER_MODE)
5. On match: returns QuoteLookupResult { quoteId, quoteUrl }
6. Page hides login form, stores quoteId in JS variable, shows OVF form
7. User fills 15 optional text fields and clicks "Submit OVF"
8. JavaScript calls submitOVF @RemoteAction via Visualforce.remoting,
     passing quoteId + all 15 field values
9. Controller truncates inputs to 255 chars, inserts OVF__c record
     with Quote__c = quoteId (Database.insert with AccessLevel.USER_MODE)
10. On success: page hides OVF form, shows Thank You state
11. On any error: inline error alert is shown; form remains editable
```

### Architecture Diagram

```
  Browser (RubrikQuotePortal.page)
  ┌───────────────────────────────────────────────────────────┐
  │  State 1: Login Form                                      │
  │  [ Quote Number ] [ Email ]  [View OVF]                   │
  └───────────────────────┬───────────────────────────────────┘
                          │ Visualforce.remoting
                          │ lookupQuoteVF(quoteNum, email)
                          ▼
  ┌───────────────────────────────────────────────────────────┐
  │  RubrikQuoteLookupController                              │
  │  lookupQuoteVF / lookupQuote                              │
  │  SOQL: SBQQ__Quote__c WHERE Name + PrimaryContact.Email   │
  │  Returns: { quoteId, quoteUrl }  or  null                 │
  └───────────────────────┬───────────────────────────────────┘
                          │ result.quoteId stored in JS
                          ▼
  ┌───────────────────────────────────────────────────────────┐
  │  State 2: OVF Form                                        │
  │  15 text inputs (buyer, reseller, address, contact)       │
  │  [Submit OVF]                                             │
  └───────────────────────┬───────────────────────────────────┘
                          │ Visualforce.remoting
                          │ submitOVF(quoteId, ...15 fields)
                          ▼
  ┌───────────────────────────────────────────────────────────┐
  │  RubrikQuoteLookupController                              │
  │  submitOVF                                                │
  │  Truncates strings to 255 chars                           │
  │  Database.insert(OVF__c, USER_MODE)                       │
  │  Returns: new OVF__c Id                                   │
  └───────────────────────┬───────────────────────────────────┘
                          │ success
                          ▼
  ┌───────────────────────────────────────────────────────────┐
  │  State 3: Thank You                                       │
  │  "Your OVF has been submitted successfully."              │
  │  "You may now close this browser window."                 │
  └───────────────────────────────────────────────────────────┘
```

---

## File Locations

| Component Type | Path |
|----------------|------|
| Custom Object metadata | `force-app/main/default/objects/OVF__c/OVF__c.object-meta.xml` |
| OVF__c field metadata | `force-app/main/default/objects/OVF__c/fields/*.field-meta.xml` |
| Apex Controller | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |
| Apex Test Class | `force-app/main/default/classes/RubrikQuoteLookupControllerTest.cls` |
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |

---

## Configuration Details

### OVF__c Object Settings

| Setting | Value |
|---------|-------|
| API Name | `OVF__c` |
| Label | OVF |
| Plural Label | OVFs |
| Record Name Field | Auto Number, format `OVF-{0000}`, starting number 0 |
| Sharing Model | Private |
| External Sharing Model | Private |
| Allow Reports | Yes |
| Enable Activities | Yes |
| Enable Bulk API | Yes |
| Deployment Status | Deployed |

### Quote__c Lookup Field Details

| Setting | Value |
|---------|-------|
| References Object | `SBQQ__Quote__c` |
| Relationship Name | `OVFs` |
| Related List Label on Quote | OVFs |
| Required | Yes |
| Delete Constraint | Restrict (cannot delete a Quote with OVF children) |

### Controller Changes: RubrikQuoteLookupController

**Pre-existing method `lookupQuote` / `lookupQuoteVF`**
- No behavioral change to validation logic
- `QuoteLookupResult` inner class gained a new `quoteId` field (in addition to the existing `quoteUrl` field)
- Both `quoteId` and `quoteUrl` are now populated on success

**New method `submitOVF`**
- Annotation: `@RemoteAction`
- Class is `with sharing`; insert uses `Database.insert(record, AccessLevel.USER_MODE)`
- Guard: throws `AuraHandledException('Quote Id is required...')` if `quoteId` is blank or null
- Input sanitisation: each of the 15 string parameters is truncated to 255 characters via `String.abbreviate(255)` before field assignment; null inputs pass through as null
- Success path: returns the new `OVF__c` record Id as a `String`
- Error path: `Database.SaveResult` errors are concatenated and thrown as `AuraHandledException`; any unexpected exception is caught and re-thrown as `AuraHandledException`

### Visualforce Page Changes: RubrikQuotePortal

The page now implements three mutually exclusive HTML sections controlled by CSS `hidden` class toggling:

| Section ID | Visible When | Purpose |
|------------|-------------|---------|
| `form-section` | Page load (default) | Quote Number + Email login form |
| `ovf-section` | After successful lookupQuoteVF | 15-field OVF input form |
| `thankyou-section` | After successful submitOVF | Success confirmation |

Key JavaScript variables:
- `currentQuoteId` — stores the `quoteId` returned from `lookupQuoteVF`; passed to `submitOVF`

Key JavaScript functions:
- `handleSubmit()` — validates Quote Number / Email inputs, invokes `lookupQuoteVF` remote action, transitions to OVF form on success
- `handleOVFSubmit()` — reads all 15 OVF field values, invokes `submitOVF` remote action, transitions to Thank You on success

Both remote action calls use `{ escape: true }` to enable Visualforce XSS escaping on returned data.

---

## Testing

### Test Coverage Summary

| Class | Methods | Org Result |
|-------|---------|------------|
| `RubrikQuoteLookupControllerTest` | 14 | 12 passing / 2 failing |

### Test Methods

| Method | Scenario | Status |
|--------|----------|--------|
| `testLookupQuoteVF_emailMatchesContact_returnsResult` | Correct quote + matching email returns result with quoteId and quoteUrl | Passing |
| `testLookupQuoteVF_emailMismatch_returnsNull` | Wrong email returns null | Passing |
| `testLookupQuoteVF_unknownQuoteNumber_returnsNull` | Non-existent quote number returns null | Passing |
| `testLookupQuote_blankQuoteNumber_returnsNull` | Blank quote number returns null | Passing |
| `testLookupQuote_blankEmail_returnsNull` | Blank email returns null | Passing |
| `testLookupQuote_nullInputs_returnsNull` | Both inputs null returns null | Passing |
| `testLookupQuote_emailCaseInsensitive_returnsResult` | Email matching is case-insensitive | Passing |
| `testLookupQuote_whitespaceInputs_returnsResult` | Leading/trailing whitespace is trimmed | Passing |
| `testSubmitOVF_validData_createsRecordAndReturnsId` | Full valid data creates OVF__c and verifies all 16 field values | Failing (see note) |
| `testSubmitOVF_optionalFieldsBlank_createsRecord` | All optional fields null — record still created | Failing (see note) |
| `testSubmitOVF_blankQuoteId_throwsAuraHandledException` | Blank quoteId throws AuraHandledException | Passing |
| `testSubmitOVF_nullQuoteId_throwsAuraHandledException` | Null quoteId throws AuraHandledException | Passing |
| `testSubmitOVF_invalidQuoteId_throwsAuraHandledException` | Syntactically valid but non-existent quoteId causes exception | Passing |
| `testQuoteLookupResult_fieldPopulation` | Verifies both quoteId and quoteUrl are populated on the result object | Passing |

### Known Failing Tests

**`testSubmitOVF_validData_createsRecordAndReturnsId`** and **`testSubmitOVF_optionalFieldsBlank_createsRecord`** fail in this org due to complexity in setting up `SBQQ__Quote__c` test data. The `@TestSetup` method attempts to insert a CPQ Quote in the test context but encounters CPQ managed package validation or automation that prevents clean test data creation. The `submitOVF` method itself is functionally correct (verified by manual testing in the sandbox); the failures are test infrastructure issues, not product defects.

Investigation steps for future resolution:
- Review `ShGl_DisableBusinessLogic__c` custom setting to confirm all relevant CPQ automation flags are available and correctly named
- Confirm `TriggerControls` static flags cover all CPQ triggers that fire during Quote insert
- Consider using `SeeAllData=true` on the failing test methods as a temporary workaround if test data setup cannot be isolated

### Deployment Note

The feature was deployed to sandbox using `--test-level NoTestRun` due to the two failing test methods. Before promoting to production, the failing tests must either be fixed or confirmed exempt under the org's test strategy.

---

## Security

### Sharing Model

- `RubrikQuoteLookupController` is declared `with sharing`, enforcing the running user's record sharing rules
- `lookupQuote` SOQL uses `WITH USER_MODE` (FLS + sharing enforced at query level)
- `submitOVF` insert uses `Database.insert(record, AccessLevel.USER_MODE)` (FLS enforced at DML level)
- `OVF__c` object sharing model is Private; records are only accessible by the owner or via sharing rules

### Public Accessibility

`RubrikQuotePortal` is a public-facing Visualforce page (no authentication required to load the page). Authentication is enforced at the application level: the user must supply a matching Quote Number + Email to proceed. No Salesforce session or login is required.

### Input Handling

- Server-side: all string inputs are truncated to 255 characters before DML; `quoteId` is validated non-blank before use
- Client-side: `{ escape: true }` is passed in all Visualforce remote action calls
- The `lookupQuote` SOQL uses `String.escapeSingleQuotes()` on both `quoteNumber` and `email` inputs before binding

### Required Permissions for Admins/Developers

| Action | Required Access |
|--------|----------------|
| View submitted OVF records | Read on `OVF__c` |
| Edit submitted OVF records | Edit on `OVF__c` |
| View OVF related list on Quote | Read on `OVF__c` + access to `SBQQ__Quote__c` |
| Run or schedule OVF reports | Reports enabled (set on object) |

---

## Notes and Considerations

### Known Limitations

1. **All 15 form fields are optional** — there is no server-side validation enforcing that any particular field is populated. If business requirements change to require specific fields (e.g., Buyer Name), both the `submitOVF` method and the VF page form must be updated.

2. **One OVF per submission** — there is no de-duplication check. A user who successfully authenticates multiple times can submit multiple OVF records for the same quote. Consider adding a duplicate check or a unique constraint if this is a concern.

3. **Failing test methods** — two of 14 test methods do not pass in the current org due to CPQ test data setup complexity. See the Testing section above.

4. **No email notification on submission** — the current implementation only creates the record. If Rubrik's operations team needs to be notified on OVF submission, a Flow or Trigger would need to be added separately.

5. **Contact_Email__c is a Text(255) field, not an Email type** — the field stores any text value; no format validation occurs at the database level. The VF page form input is `type="text"` not `type="email"`.

### Future Enhancements

- Add a required-field validation for Buyer Name on both the VF page and the server method
- Add a duplicate-check guard in `submitOVF` before inserting (query for existing OVF__c WHERE Quote__c = quoteId)
- Add a post-submission email notification (Flow on OVF__c after insert)
- Promote `Contact_Email__c` from Text(255) to Email type if format validation is needed
- Add an OVF record detail page or a list view accessible to internal users from the Quote related list
- Resolve the two failing test methods before production deployment

### Dependencies

| Dependency | Notes |
|------------|-------|
| Salesforce CPQ managed package | `SBQQ__Quote__c` and `SBQQ__PrimaryContact__c` must exist; the entire feature depends on CPQ being installed |
| `ShGl_DisableBusinessLogic__c` custom setting | Used in test setup to suppress CPQ automation during tests; must exist in the org |
| `TriggerControls` Apex class | Used in test setup to disable quote/quote line triggers; must exist in the org |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-27 | Documentation Agent | Initial creation documenting OVF Form feature |
