# RubrikQuotePortal -- Dynamic OVF Form via Field Sets

**Date:** 2026-03-29
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Make the OVF form on RubrikQuotePortal.page dynamic, driven by Field Sets defined on OVF__c, so that the form fields rendered to the guest user are determined by whichever Field Set is active. For now, default to AWSOVFFieldSet. Three field sets are required (AWS, Azure, GCP), all containing the same 15 fields initially.

### Business Objective

The OVF (Order Verification Form) on the Rubrik Quote Portal is a Salesforce Site guest page where marketplace buyers complete order details. Previously the 15 form fields were hardcoded in the Visualforce markup, making it impossible to vary the form layout by marketplace (AWS, Azure, GCP) without a code deployment. This change replaces the hardcoded fields with a Field Set-driven rendering pipeline, so that a Salesforce admin can control which fields appear for each marketplace by editing a Field Set declaratively — no code change required.

### Summary

Three Field Sets were created on OVF__c (AWS, Azure, GCP), each containing the same 15 fields. The Visualforce controller was extended with a wrapper class and two new getters that read the active Field Set at page-render time and serialize field metadata into a JavaScript config array embedded directly in the page. A new `@RemoteAction` method (`submitOVFDynamic`) accepts a JSON payload of field values, validates each key against the active Field Set as a server-side allowlist, and inserts the record via the existing guest DML helper. Six new test methods were added covering the success path, blank input guards, invalid JSON, and unknown-field filtering.

---

## Components Created

### Admin Components (Declarative)

#### Field Sets on OVF__c

| Field Set API Name | Label | Description |
|--------------------|-------|-------------|
| `AWSOVFFieldSet` | AWS OVF Field Set | Fields displayed on the OVF form for AWS marketplace orders |
| `AzureOVFFieldSet` | Azure OVF Field Set | Fields displayed on the OVF form for Azure marketplace orders |
| `GCPOVFFieldSet` | GCP OVF Field Set | Fields displayed on the OVF form for GCP marketplace orders |

All three field sets contain the same 15 fields in the same order:

| # | Field API Name | Notes |
|---|----------------|-------|
| 1 | `Buyer_Name__c` | All `isFieldManaged: false`, `isRequired: false` in current metadata |
| 2 | `Buyer_Billing_ID__c` | |
| 3 | `Buyer_Tenant_ID__c` | |
| 4 | `Reseller_Name__c` | |
| 5 | `Marketplace_Seller_ID__c` | |
| 6 | `Company_Name__c` | |
| 7 | `Address_1__c` | |
| 8 | `Address_2__c` | |
| 9 | `City__c` | |
| 10 | `State__c` | |
| 11 | `Zip_Code__c` | |
| 12 | `Country__c` | |
| 13 | `Contact_Name__c` | |
| 14 | `Contact_Email__c` | |
| 15 | `Contact_Phone__c` | |

Note: `isRequired` in the field set metadata controls whether the HTML `required` attribute is rendered on the input. All 15 are currently `false`, so no field is currently required client-side. This can be changed declaratively in the Field Set without any code change.

---

### Development Components (Code)

#### Apex Classes Modified

| Class | Change Type | Description |
|-------|-------------|-------------|
| `RubrikQuoteLookupController` | Modified | Added `OVFFieldMember` inner class, `getActiveFieldSetName()`, `getOvfFieldSetMembers()`, and `submitOVFDynamic()` |

#### New Inner Class

`OVFFieldMember` -- a public wrapper class added to `RubrikQuoteLookupController`, used to pass field metadata from Apex to the Visualforce `<apex:repeat>` block.

| Property | Type | Source |
|----------|------|--------|
| `fieldApiName` | `String` | `FieldSetMember.getFieldPath()` |
| `label` | `String` | `FieldSetMember.getLabel()` |
| `fieldType` | `String` | `DescribeFieldResult.getType().name().toLowerCase()` |
| `isRequired` | `Boolean` | `FieldSetMember.getRequired() \|\| FieldSetMember.getDbRequired()` |
| `maxLength` | `Integer` | `DescribeFieldResult.getLength()`, defaults to 255 if 0 |

All properties carry the `@AuraEnabled` annotation (for potential future LWC consumption).

#### New Methods in RubrikQuoteLookupController

**`getActiveFieldSetName()` -- public instance getter**

Returns the API name of the active Field Set. Currently hardcoded to `'AWSOVFFieldSet'`. This is the single point of change when condition logic is added (e.g., routing by cloud type). No other code needs to change to switch between the three field sets.

**`getOvfFieldSetMembers()` -- public instance getter**

Reads the active Field Set from `Schema.SObjectType.OVF__c.fieldSets.getMap()`, maps each `FieldSetMember` to an `OVFFieldMember` instance, and returns the list. Result is memoized in the instance variable `cachedOvfFieldMembers` to avoid redundant schema describes if the getter is called more than once during the page request lifecycle. Returns an empty list if the Field Set is not found (safe degradation).

**`submitOVFDynamic(String quoteId, String fieldValuesJson)` -- @RemoteAction**

Accepts a JSON string mapping field API names to values. Key behaviors:

- Throws `IllegalArgumentException` if `quoteId` is blank (same guard as legacy `submitOVF`)
- Throws `OVFSubmitException` if `fieldValuesJson` cannot be deserialized
- Builds an allowlist `Set<String>` from the active Field Set members (lowercase) before touching the sObject
- `Quote__c` is explicitly removed from the allowlist even if it somehow appears in a Field Set
- For each key in the parsed JSON, skips any key not in the allowlist
- Truncates each string value to the field's `maxLength` using `.abbreviate(maxLen)`
- Inserts via `GuestDmlHelper.insertOvf()` (existing `without sharing` inner class)
- Returns the new record Id, or throws `OVFSubmitException` on DML failure

The legacy `submitOVF` method (16 parameters) is unchanged.

#### Apex Triggers

No triggers were created or modified.

#### Test Classes Modified

`RubrikQuoteLookupControllerTest` -- 6 new test methods added. All existing methods are preserved unchanged.

| Test Method | Scenario | Expected Outcome |
|-------------|----------|-----------------|
| `testGetActiveFieldSetName` | Instantiate controller, call getter | Returns `'AWSOVFFieldSet'` |
| `testGetOvfFieldSetMembers_returnsFields` | Instantiate controller, call getter | Returns non-null list (may be empty in sandbox if field set not deployed) |
| `testSubmitOVFDynamic_success` | Valid quote Id + JSON with 2 fields | Non-null 15/18-char Id returned; OVF__c record exists with correct Quote__c |
| `testSubmitOVFDynamic_blankQuoteId` | Blank quote Id | `IllegalArgumentException` thrown, message contains "Quote Id is required" |
| `testSubmitOVFDynamic_invalidJson` | Malformed JSON string | `OVFSubmitException` thrown, message contains "Invalid field values JSON" |
| `testSubmitOVFDynamic_unknownFieldIgnored` | JSON includes `NonExistentField__c` | Succeeds silently; valid Id returned |

#### Visualforce Pages Modified

`RubrikQuotePortal.page` -- the OVF form section was converted from static to dynamic rendering.

| Change | Before | After |
|--------|--------|-------|
| OVF form field markup | 15 hardcoded `<div class="field-group">` blocks | Single empty `<div id="ovf-fields-container" class="ovf-grid">` |
| Field metadata delivery | N/A | `<apex:repeat>` emits `OVF_FIELDS` JS array inline at page load |
| Field rendering | Static HTML | `renderOVFFields()` JS function builds DOM from `OVF_FIELDS` |
| Form submission | `submitOVF` (16 individual params) | `submitOVFDynamic` (quoteId + JSON string) |
| Required validation | None (no required fields) | Client-side loop over `OVF_FIELDS[i].isRequired` before remoting call |

---

## Data Flow

### Page Load -- Field Metadata Delivery

```
Controller instantiated by VF runtime
        |
        v
getOvfFieldSetMembers() called during expression evaluation
        |
        v
getActiveFieldSetName() --> returns 'AWSOVFFieldSet'
        |
        v
Schema.SObjectType.OVF__c.fieldSets.getMap().get('AWSOVFFieldSet').getFields()
        |
        v
Each FieldSetMember mapped to OVFFieldMember (apiName, label, fieldType, isRequired, maxLength)
        |
        v
<apex:repeat> iterates list, emits JS array literal into <script> block:
  var OVF_FIELDS = [ {apiName:'Buyer_Name__c', label:'...', ...}, ... ];
        |
        v
Page HTML delivered to browser -- OVF_FIELDS is available immediately
```

### User Interaction -- OVF Form Render

```
User submits quote lookup form
        |
        v
lookupQuoteVF @RemoteAction validates quote number + contact email
        |
        v
On success: currentQuoteId stored, renderOVFFields() called, ovf-section shown
        |
        v
renderOVFFields() iterates OVF_FIELDS array
  - Maps fieldType to HTML input type (email->email, phone->tel, textarea->textarea, others->text)
  - Looks up browser autocomplete token by apiName
  - Creates <div class="field-group"> with <label> and <input>
  - Sets id="ovf_{apiName}", maxlength, autocomplete, placeholder
  - If isRequired: sets 'required' attribute, appends ' *' to label text
        |
        v
Form rendered to user with correct field types and labels
```

### User Interaction -- OVF Form Submit

```
User clicks Submit OVF
        |
        v
handleOVFSubmit() runs client-side required field validation
  (loops OVF_FIELDS, checks .isRequired, marks .has-error if blank)
        |
        v
On pass: collects values by iterating OVF_FIELDS, reads document.getElementById('ovf_' + apiName).value
  fieldValues = { 'Buyer_Name__c': 'Acme', 'City__c': 'San Jose', ... }
        |
        v
Visualforce.remoting.Manager.invokeAction(submitOVFDynamic, currentQuoteId, JSON.stringify(fieldValues))
        |
        v
submitOVFDynamic on server:
  1. Blank-check quoteId
  2. JSON.deserializeUntyped(fieldValuesJson) --> Map<String, Object>
  3. Build allowlist Set<String> from active FieldSet members (lowercase)
  4. Remove 'quote__c' from allowlist
  5. Create OVF__c(Quote__c = quoteId)
  6. For each key in JSON map: if in allowlist, ovfRecord.put(apiName, value.abbreviate(maxLen))
  7. GuestDmlHelper.insertOvf(ovfRecord) --> Database.SaveResult
  8. Return record Id
        |
        v
On success: hide ovf-section, show thankyou-section
```

### Architecture Diagram

```
  Browser (Guest User)
  ┌──────────────────────────────────────────────────────────────────┐
  │  Page Load                                                       │
  │  OVF_FIELDS JS array (baked in at server render time)           │
  │                                                                  │
  │  Step 1: Quote Lookup Form                                       │
  │  [Quote Number] [Email] --> lookupQuoteVF @RemoteAction          │
  │                                                                  │
  │  Step 2: OVF Form (rendered by renderOVFFields from OVF_FIELDS) │
  │  [Dynamic inputs] --> handleOVFSubmit --> submitOVFDynamic       │
  │                                                                  │
  │  Step 3: Thank You screen                                        │
  └──────────────────────────────────────────────────────────────────┘
         |                                    |
         | lookupQuoteVF                      | submitOVFDynamic
         v                                    v
  ┌────────────────────┐           ┌──────────────────────────┐
  │ GuestQueryHelper   │           │ RubrikQuoteLookupCtrl    │
  │ (without sharing)  │           │ (with sharing)           │
  │ SBQQ__Quote__c     │           │                          │
  │ OpportunityContact │           │ FieldSet allowlist check │
  │ Role query         │           │ sObject.put() per field  │
  └────────────────────┘           └──────────┬───────────────┘
                                              |
                                              v
                                   ┌──────────────────────────┐
                                   │ GuestDmlHelper           │
                                   │ (without sharing)        │
                                   │ Database.insert(OVF__c)  │
                                   └──────────────────────────┘
```

---

## File Locations

| Component | Path |
|-----------|------|
| AWS Field Set | `force-app/main/default/objects/OVF__c/fieldSets/AWSOVFFieldSet.fieldSet-meta.xml` |
| Azure Field Set | `force-app/main/default/objects/OVF__c/fieldSets/AzureOVFFieldSet.fieldSet-meta.xml` |
| GCP Field Set | `force-app/main/default/objects/OVF__c/fieldSets/GCPOVFFieldSet.fieldSet-meta.xml` |
| Apex Controller | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |
| Apex Test Class | `force-app/main/default/classes/RubrikQuoteLookupControllerTest.cls` |
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |

---

## Configuration Details

### How to Switch the Active Field Set

The active Field Set is determined entirely by `getActiveFieldSetName()` in `RubrikQuoteLookupController`. Currently returns the hardcoded string `'AWSOVFFieldSet'`.

To add condition logic (e.g., choose field set based on the quote's cloud marketplace type):

1. Modify `getActiveFieldSetName()` to accept or read the relevant condition. The method is an instance getter so it has access to any VF page properties or URL parameters set on the controller.
2. Return `'AWSOVFFieldSet'`, `'AzureOVFFieldSet'`, or `'GCPOVFFieldSet'` based on the condition.
3. The VF page JS will receive the correct field array automatically at page load -- no JS change is required unless the condition must be evaluated after page load (e.g., after the quote lookup returns, to switch field sets based on quote data). In that case the condition value would need to be passed back in the `lookupQuoteVF` result and a second mechanism (e.g., a remoting call to fetch the field list) would be needed.

### Field Type to HTML Input Type Mapping

Implemented in `getInputType(sfType)` in the VF page JavaScript:

| Salesforce Field Type | HTML Input Type |
|-----------------------|-----------------|
| `email` | `<input type="email">` |
| `phone` | `<input type="tel">` |
| `textarea` | `<textarea>` |
| All others | `<input type="text">` |

All 15 current fields are `STRING` type, so all render as `<input type="text">` today. The mapping is ready for future field additions.

### Autocomplete Token Mapping

Implemented in `getAutocomplete(apiName)` in the VF page JavaScript. Fields with a known autocomplete token:

| Field API Name | Autocomplete Token |
|----------------|--------------------|
| `Company_Name__c` | `organization` |
| `Address_1__c` | `address-line1` |
| `Address_2__c` | `address-line2` |
| `City__c` | `address-level2` |
| `State__c` | `address-level1` |
| `Zip_Code__c` | `postal-code` |
| `Country__c` | `country-name` |
| `Contact_Name__c` | `name` |
| `Contact_Email__c` | `email` |
| `Contact_Phone__c` | `tel` |
| All others | `off` |

### Value Truncation

`submitOVFDynamic` reads each field's `maxLength` from `DescribeFieldResult.getLength()` and truncates values using Apex's `String.abbreviate(maxLen)`. If `getLength()` returns 0 (which can occur for some field types), the method defaults to 255.

---

## Testing

### Test Coverage Summary

| Class | New Methods Added | Pre-Existing Methods |
|-------|-------------------|----------------------|
| `RubrikQuoteLookupControllerTest` | 6 | 11 |

### New Test Scenarios

| Test Method | Verified Behavior |
|-------------|-------------------|
| `testGetActiveFieldSetName` | `getActiveFieldSetName()` returns exactly `'AWSOVFFieldSet'` |
| `testGetOvfFieldSetMembers_returnsFields` | `getOvfFieldSetMembers()` does not throw and returns non-null |
| `testSubmitOVFDynamic_success` | Valid inputs produce an inserted OVF__c with correct Quote__c |
| `testSubmitOVFDynamic_blankQuoteId` | Blank quoteId throws `IllegalArgumentException` |
| `testSubmitOVFDynamic_invalidJson` | Malformed JSON throws `OVFSubmitException` with "Invalid field values JSON" |
| `testSubmitOVFDynamic_unknownFieldIgnored` | Field key not in Field Set is silently skipped; insert succeeds |

### Testing Limitation -- Field Set Members in @isTest Context

In an Apex `@isTest` context, `Schema.SObjectType.OVF__c.fieldSets.getMap().get('AWSOVFFieldSet').getFields()` returns an empty list unless the Field Set metadata is already deployed to the org being tested against. As a result:

- `testGetOvfFieldSetMembers_returnsFields` only asserts non-null (not a specific count)
- `testSubmitOVFDynamic_success` succeeds even in a fresh sandbox because `submitOVFDynamic` degrades gracefully when the allowlist is empty -- the record is created with only `Quote__c` populated

When running against a full sandbox with the metadata deployed, the allowlist will be populated and field values will be written correctly.

---

## Security

### Access Model

This feature runs on a Salesforce Site guest page. The relevant security layers are:

| Layer | Implementation |
|-------|----------------|
| Controller sharing | `public with sharing class RubrikQuoteLookupController` |
| DML (OVF insert) | `private without sharing class GuestDmlHelper` -- intentional; guest user has no sharing to the referenced SBQQ__Quote__c |
| Field write allowlist | `submitOVFDynamic` validates every incoming JSON key against the active Field Set member list before calling `sObject.put()` |
| Quote lookup field | `Quote__c` is explicitly removed from the allowlist in `submitOVFDynamic` even if it somehow appears in a Field Set |
| Value sanitization | Each string value is truncated to the field's declared `maxLength` via `.abbreviate()` |
| Client-side required validation | Loops `OVF_FIELDS[i].isRequired` before invoking remoting -- purely UX, not a security boundary |

### Why the Field Set is the Allowlist

The `submitOVFDynamic` method does not validate incoming field names against the full `OVF__c` field map. It validates only against the active Field Set. This is intentional:

- The Field Set is a declarative artifact controlled by a Salesforce admin, not by the guest user
- Only fields that an admin explicitly adds to the Field Set can be written by the guest page
- To allow a new field to be written, an admin adds it to the Field Set -- no code change needed
- Fields not in the Field Set (including any internal or sensitive fields on OVF__c) cannot be written regardless of what a guest user sends in the JSON payload

---

## Notes and Considerations

### Known Limitations

1. **Active Field Set is hardcoded.** `getActiveFieldSetName()` always returns `'AWSOVFFieldSet'`. The condition for selecting AWS vs. Azure vs. GCP is not yet implemented. All three Field Sets exist and are ready; only the routing logic is missing.

2. **Field Set metadata is resolved at page load, not at form render time.** The `OVF_FIELDS` JS array is emitted by the Apex controller at VF page render time. If the active Field Set needs to change after the quote lookup (e.g., based on quote data returned by `lookupQuoteVF`), a secondary mechanism is needed. See "Future Enhancements" below.

3. **No server-side required field validation.** `submitOVFDynamic` does not check required fields on the server. Client-side validation is present, but it can be bypassed. If required fields are made mandatory, add server-side validation in `submitOVFDynamic` as well.

4. **Field Set member ordering.** The form fields render in the order the Field Set members are declared in the metadata XML. Reordering fields means editing the Field Set in Salesforce Setup (drag-and-drop in the Field Set editor) and redeploying the metadata.

5. **`testGetOvfFieldSetMembers_returnsFields` only asserts non-null.** In environments where the Field Sets have been deployed, this test can be strengthened to assert `result.size() == 15`.

### Future Enhancements

1. **Add marketplace condition to `getActiveFieldSetName()`.** When the cloud marketplace type is available on the quote, pass it to or read it in `getActiveFieldSetName()` and return the corresponding Field Set API name. This is a localized change to a single method.

2. **Post-lookup Field Set selection.** If the Field Set must be chosen based on data returned after the quote lookup, one option is to return the active Field Set name (or the full `OVF_FIELDS` array) from `lookupQuoteVF` as part of the `QuoteLookupResult` wrapper, and have the JS call a new remoting method to fetch the field list dynamically after the quote is found.

3. **Server-side required field enforcement.** Currently only enforced client-side. Add validation in `submitOVFDynamic` for completeness.

4. **Field-Set-specific field ordering per cloud.** Once the routing condition is live, the three Field Sets can diverge: cloud-specific fields (e.g., Azure Tenant ID is irrelevant for GCP) can be added to only the relevant Field Set without any code change.

5. **Test coverage for populated Field Sets.** Once deployed to a full sandbox, `testGetOvfFieldSetMembers_returnsFields` and `testSubmitOVFDynamic_success` can be enhanced to assert specific field counts and individual field values.

### Dependencies

| Dependency | Type | Reason |
|------------|------|--------|
| `OVF__c` custom object | Object | Target of all DML in this feature |
| `SBQQ__Quote__c` | CPQ managed object | `OVF__c.Quote__c` is a lookup to this object |
| `GuestDmlHelper` (inner class) | Apex | Performs `without sharing` insert; must remain in the same controller |
| `GuestQueryHelper` (inner class) | Apex | Handles quote lookup for `lookupQuoteVF`; unchanged |
| `ShGl_DisableBusinessLogic__c` | Custom Setting | Used in test setup to suppress CPQ automation |
| `TriggerControls` | Apex class | Used in test setup to disable quote/quoteline triggers |
| AWSOVFFieldSet, AzureOVFFieldSet, GCPOVFFieldSet | Field Set metadata | Must be deployed before the controller runs in production |

---

## Change History

| Date | Author | Change Description |
|------|--------|--------------------|
| 2026-03-29 | Documentation Agent | Initial creation |
