# Send OVF Quick Action

**Date:** 2026-03-27
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Create a quick action named "Send OVF" on the SBQQ__Quote__c detail page. When a sales rep clicks this button:

1. The primary contact associated with the Quote receives a professional email
2. The email contains:
   - A professional subject line
   - The OVF portal link: https://rubrikinc--claudepoc.sandbox.my.salesforce-sites.com/rubrikquote
   - The Quote Number
   - Quote line items details (product name, quantity, price, etc.)
   - A request for the contact to fill in the OVF details from the portal link
3. The email must look very professional and polished

### Business Objective

OVF stands for Order Verification Form. When Rubrik closes a deal through Salesforce CPQ, the customer must complete an Order Verification Form through a self-service portal before licenses can be provisioned. Previously there was no in-product way for a sales rep to send the OVF invitation directly from the Quote record. This feature gives sales reps a single-click button on the Quote detail page that sends a branded, data-rich email to the right contact with all the information they need to complete the form — reducing friction and manual steps.

### Summary

A "Send OVF" quick action button was added to the SBQQ__Quote__c record page. Clicking the button opens a confirmation modal (LWC) that previews the recipient's contact details and the quote line items before the email is sent. The Apex controller validates the quote and contact, then sends a professionally branded HTML email with the OVF portal link. The email is logged as an Activity on the Quote record.

---

## Components Created

### Admin Components (Declarative)

#### Quick Actions

| Quick Action API Name | Object | Type | LWC Reference | Label |
|-----------------------|--------|------|---------------|-------|
| `SBQQ__Quote__c.Send_OVF` | `SBQQ__Quote__c` | LightningWebComponent | `sendOvfQuickAction` | Send OVF |

No custom objects, custom fields, validation rules, flows, or permission sets were created as part of this feature.

---

### Development Components (Code)

#### Apex Classes

| Class Name | Type | API Version | Sharing | Description |
|------------|------|-------------|---------|-------------|
| `SendOvfEmailController` | Controller | 66.0 | `with sharing` | Provides `getQuoteDetails` and `sendOvfEmail` AuraEnabled methods, plus private helpers for validation, HTML generation, and currency formatting |

**Inner Classes / Wrappers inside SendOvfEmailController:**

| Wrapper Class | Purpose | AuraEnabled Fields |
|---------------|---------|-------------------|
| `QuoteDetailsWrapper` | Carries preview data and raw SObject references from `fetchAndValidateQuote` to both public methods | `quoteNumber`, `contactName`, `contactEmail`, `lineItems` |
| `QuoteLineItem` | Represents a single quote line for display in the LWC and email | `id`, `productName`, `quantity`, `listPrice`, `netTotal` |

**Private / TestVisible Methods inside SendOvfEmailController:**

| Method | Visibility | Description |
|--------|-----------|-------------|
| `fetchAndValidateQuote(Id quoteId)` | `@TestVisible private static` | Shared helper that runs all SOQL and validation for both public methods; throws `AuraHandledException` on any failure |
| `buildEmailHtml(String, String, List<SBQQ__QuoteLine__c>)` | `@TestVisible private static` | Constructs the full HTML email body with inline CSS, branded header, quote number badge, line items table, CTA button, and footer |
| `formatCurrency(Decimal value)` | `@TestVisible private static` | Formats a Decimal as a USD string (e.g., `$1,234.56`) with thousand separators, two decimal places, and HALF_UP rounding |

#### Apex Triggers

No triggers were created for this feature.

#### Test Classes

| Test Class | Tests For | Test Methods | Coverage Target |
|------------|-----------|-------------|----------------|
| `SendOvfEmailControllerTest` | `SendOvfEmailController` | 30+ methods | ~95% |

#### Lightning Web Components

| Component Name | Target | Action Type | Description |
|----------------|--------|-------------|-------------|
| `sendOvfQuickAction` | `lightning__RecordAction` | ScreenAction | Quick action modal that previews the OVF email recipient and line items, then sends the email via Apex on confirmation |

**Component Files:**

| File | Role |
|------|------|
| `sendOvfQuickAction.js` | Component controller — lifecycle, Apex calls, state management, currency formatting, error extraction |
| `sendOvfQuickAction.html` | Template — three conditional states: loading spinner, error alert, and preview/confirmation screen |
| `sendOvfQuickAction.css` | Scoped styles — Rubrik brand color (#009dac), detail card, line items table, spinner overlays, button bar |
| `sendOvfQuickAction.js-meta.xml` | Component metadata — target `lightning__RecordAction`, action type `ScreenAction`, API 66.0 |

---

## Data Flow

### How It Works

```
1. Sales rep opens a SBQQ__Quote__c record page and clicks "Send OVF"
2. Salesforce opens the sendOvfQuickAction LWC modal (ScreenAction)
3. connectedCallback fires -> loadQuoteDetails() calls getQuoteDetails({ quoteId }) imperatively
4. getQuoteDetails delegates to fetchAndValidateQuote():
   a. Queries SBQQ__Quote__c for Name, Primary_Contact__c, Primary_Contact__r.Name/FirstName/Email
   b. Throws AuraHandledException if quote not found, contact is null, or contact has no email
   c. Queries SBQQ__QuoteLine__c (ordered by SBQQ__Number__c ASC)
   d. Builds and returns QuoteDetailsWrapper with contact info + mapped QuoteLineItem list
5. LWC renders the preview screen: contact name, email, quote number, and line items table
6. Sales rep reviews and clicks "Send Email"
7. handleSend() calls sendOvfEmail({ quoteId }) imperatively
8. sendOvfEmail calls fetchAndValidateQuote() again (re-validates at send time)
9. buildEmailHtml() generates the full HTML body with inline CSS
10. Messaging.SingleEmailMessage is constructed with:
    - setToAddresses -> contact email
    - setTargetObjectId -> contact Id (logs as Activity on Contact)
    - setWhatId -> quote Id (links Activity to Quote)
    - setSaveAsActivity(true)
    - setUseSignature(false)
11. Messaging.sendEmail() sends the email
12. On success: LWC shows a success toast ("OVF email sent successfully to [email]") and closes the modal
13. On failure: LWC shows a sticky error toast with the extracted message; modal stays open
```

### Architecture Diagram

```
  Quote Record Page
  ┌───────────────────────────────────────────────────────────────┐
  │  [Send OVF] button (Quick Action: SBQQ__Quote__c.Send_OVF)   │
  └─────────────────────────┬─────────────────────────────────────┘
                            │ opens
                            v
  ┌───────────────────────────────────────────────────────────────┐
  │              sendOvfQuickAction (LWC ScreenAction)            │
  │                                                               │
  │  connectedCallback                                            │
  │    -> getQuoteDetails (Apex)  ─────────────────────────────┐  │
  │                                                            │  │
  │  [Loading spinner]                                         │  │
  │                                                            │  │
  │  [Preview Screen]                                          │  │
  │    Contact Name / Email / Quote Number                     │  │
  │    Line Items Table (Product, Qty, List Price, Net Total)  │  │
  │    [Cancel]   [Send Email]                                 │  │
  │                   |                                        │  │
  │                   | handleSend                             │  │
  │                   v                                        │  │
  │    -> sendOvfEmail (Apex)                                  │  │
  │       [Sending spinner overlay]                            │  │
  │                   |                                        │  │
  │          success  |  error                                 │  │
  │          toast    |  toast (sticky)                        │  │
  │          close    |  modal stays open                      │  │
  └───────────────────────────────────────────────────────────┘  │
                                                                  │
  SendOvfEmailController (Apex)  <──────────────────────────────-┘
  ┌───────────────────────────────────────────────────────────────┐
  │  getQuoteDetails(quoteId)                                     │
  │    -> fetchAndValidateQuote()  ──────────────────────────┐    │
  │         SOQL: SBQQ__Quote__c                             │    │
  │         SOQL: SBQQ__QuoteLine__c                         │    │
  │         Validation: contact + email                      │    │
  │         Returns: QuoteDetailsWrapper                     │    │
  │                                                          │    │
  │  sendOvfEmail(quoteId)                                   │    │
  │    -> fetchAndValidateQuote()  ──────────────────────────┘    │
  │    -> buildEmailHtml()                                        │
  │    -> Messaging.sendEmail()                                   │
  │         Logged as Activity on Contact + Quote                 │
  └───────────────────────────────────────────────────────────────┘
```

---

## File Locations

| Component Type | Path |
|----------------|------|
| Quick Action Metadata | `force-app/main/default/quickActions/SBQQ__Quote__c.Send_OVF.quickAction-meta.xml` |
| Apex Controller | `force-app/main/default/classes/SendOvfEmailController.cls` |
| Apex Class Metadata | `force-app/main/default/classes/SendOvfEmailController.cls-meta.xml` |
| Apex Test Class | `force-app/main/default/classes/SendOvfEmailControllerTest.cls` |
| LWC JavaScript | `force-app/main/default/lwc/sendOvfQuickAction/sendOvfQuickAction.js` |
| LWC HTML Template | `force-app/main/default/lwc/sendOvfQuickAction/sendOvfQuickAction.html` |
| LWC CSS | `force-app/main/default/lwc/sendOvfQuickAction/sendOvfQuickAction.css` |
| LWC Metadata | `force-app/main/default/lwc/sendOvfQuickAction/sendOvfQuickAction.js-meta.xml` |

---

## Configuration Details

### Quick Action

| Property | Value |
|----------|-------|
| API Name | `Send_OVF` (full: `SBQQ__Quote__c.Send_OVF`) |
| Action Type | `LightningWebComponent` |
| LWC Reference | `sendOvfQuickAction` |
| Label | Send OVF |
| Object | `SBQQ__Quote__c` (Salesforce CPQ Quote) |

The quick action must be added to the SBQQ__Quote__c Lightning record page layout via the Page Layout editor or Lightning App Builder to be visible to users.

### Apex Controller Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `OVF_PORTAL_URL` | `https://rubrikinc--claudepoc.sandbox.my.salesforce-sites.com/rubrikquote` | CTA link in the email body |
| `BRAND_COLOR` | `#009dac` | Rubrik brand color used in email header, quote badge, table headers, and CTA button |

### Apex Method Signatures

| Method | Annotation | Return Type | Parameters |
|--------|-----------|-------------|-----------|
| `getQuoteDetails` | `@AuraEnabled(cacheable=false)` | `QuoteDetailsWrapper` | `Id quoteId` |
| `sendOvfEmail` | `@AuraEnabled(cacheable=false)` | `String` | `Id quoteId` |

Both methods are `cacheable=false` because they perform DML-adjacent operations (email send) and the data must be fresh on every call.

### Email Configuration

| Property | Value |
|----------|-------|
| Subject | `Action Required: Complete Your Order Verification Form for Quote [Quote Name]` |
| To Address | Primary Contact email (`Primary_Contact__r.Email`) |
| Target Object Id | `Primary_Contact__c` (Contact Id) — logs email as Activity on Contact |
| What Id | Quote Id — links Activity to the Quote |
| Save As Activity | `true` |
| Use Signature | `false` |
| Body | Full HTML with inline CSS |

### SOQL Queries

**Quote query (fetchAndValidateQuote):**
```
SELECT Id, Name, Primary_Contact__c,
       Primary_Contact__r.Name, Primary_Contact__r.FirstName,
       Primary_Contact__r.Email
FROM SBQQ__Quote__c
WHERE Id = :quoteId
WITH USER_MODE
LIMIT 1
```

**Quote Lines query (fetchAndValidateQuote):**
```
SELECT Id,
       SBQQ__Product__r.Name,
       SBQQ__Quantity__c,
       SBQQ__ListPrice__c,
       SBQQ__NetTotal__c
FROM SBQQ__QuoteLine__c
WHERE SBQQ__Quote__c = :quoteId
WITH USER_MODE
ORDER BY SBQQ__Number__c ASC
```

Both queries use `WITH USER_MODE` (API 65.0+ feature) to enforce the running user's field- and record-level security.

### LWC State Model

| Property | Type | Initial Value | Description |
|----------|------|---------------|-------------|
| `recordId` | `@api` | — | Quote Id injected by the quick action framework |
| `quoteNumber` | String | `''` | Populated after `getQuoteDetails` resolves |
| `contactName` | String | `''` | Populated after `getQuoteDetails` resolves |
| `contactEmail` | String | `''` | Populated after `getQuoteDetails` resolves |
| `lineItems` | Array | `[]` | Mapped from `QuoteLineItem` wrapper; adds `formattedListPrice` and `formattedNetTotal` client-side |
| `isLoading` | Boolean | `true` | Controls initial loading spinner |
| `isSending` | Boolean | `false` | Controls send-in-progress spinner and disables buttons |
| `hasError` | Boolean | `false` | Switches template to the error state |
| `errorMessage` | String | `''` | Displayed in the error alert panel |

**Computed getters:**

| Getter | Returns | Logic |
|--------|---------|-------|
| `showPreview` | Boolean | `!isLoading && !hasError` |
| `hasLineItems` | Boolean | `lineItems.length > 0` |
| `lineItemCount` | Number | `lineItems.length` |

### LWC Template States

The template uses `lwc:if` / `lwc:elseif` / `lwc:else` to render exactly one of three top-level states:

1. **Loading** — `lightning-spinner` while `getQuoteDetails` is in flight
2. **Error** — SLDS error alert with the message and a Close button
3. **Preview/Confirmation** — contact details, line items table, Cancel and Send Email buttons; a sending overlay (`lightning-spinner` + text) appears on top during email transmission

### Email HTML Structure

The email body is built entirely in Apex (`buildEmailHtml`) using string concatenation with inline CSS for broad email-client compatibility. Structure:

```
Outer table (background: #f4f6f9, full-width wrapper)
  Inner card table (max-width 600px, white, rounded, shadow)
    Header row      — brand color (#009dac) background, RUBRIK wordmark in white
    Body content    — padding 36px 40px
      Greeting      — "Dear [FirstName],"
      Introduction  — explains the OVF purpose
      Quote badge   — left-bordered box showing "QUOTE NUMBER" label + quote number
      Products heading
      Line items table — brand-color header row, alternating white/#f9fafb rows
                         columns: Product | Qty | List Price | Net Total
                         "No line items found" fallback row when empty
      Instructions  — directs contact to click button with quote number + email
      CTA button    — brand color, "Complete Order Verification Form", links to OVF_PORTAL_URL
      Closing       — contact Rubrik account team, "Best regards, The Rubrik Team"
    Footer row      — light grey, company tagline + automated message disclaimer
```

All user-supplied values (contact name, quote number, product names) are HTML-escaped with `escapeHtml4()` before insertion to prevent HTML injection.

---

## Testing

### Test Coverage Summary

| Class | Target Coverage | Status |
|-------|----------------|--------|
| `SendOvfEmailController` | ~95% | Passed |

### Test Setup

`@TestSetup` inserts the following hierarchy used across most test methods:

- `Account` — OVF Test Account
- `Contact` — OvfFirst OvfLast, email: ovf.test@example.com
- `Opportunity` — OVF Test Opp
- `SBQQ__Quote__c` — linked to Opportunity, `Primary_Contact__c` = Contact
- `Product2` x2 — Rubrik Cloud Vault, Rubrik Support Premium
- `PricebookEntry` x2 — standard pricebook entries for both products
- `SBQQ__QuoteLine__c` x2 — line 1 (qty 3, $10,000 list, $27,000 net), line 2 (qty 1, $2,500 list, $2,500 net)

### Key Test Scenarios

**getQuoteDetails — positive:**
- Valid quote with primary contact and two line items returns fully populated wrapper
- Quote with no line items returns empty `lineItems` list without error
- `QuoteLineItem` wrapper fields map correctly (quantity, list price, id)

**getQuoteDetails — negative:**
- Null quoteId throws `AuraHandledException`
- Non-existent quoteId throws `AuraHandledException`
- Quote with no `Primary_Contact__c` throws `AuraHandledException`
- Quote whose primary contact has no email throws `AuraHandledException`

**sendOvfEmail — positive:**
- Valid quote returns `'SUCCESS'`
- Contact with no `FirstName` (falls back to full Name in greeting) still succeeds
- Multiple quotes processed sequentially within governor limits all return `'SUCCESS'`

**sendOvfEmail — negative:**
- Null quoteId, non-existent quoteId, missing contact, missing email all throw `AuraHandledException` (mirrors getQuoteDetails negative cases)

**buildEmailHtml (via @TestVisible):**
- HTML with line items contains DOCTYPE, contact name, quote number, OVF portal URL, product names, brand color
- Empty list renders "No line items found" placeholder
- Null list renders "No line items found" placeholder
- HTML characters in contact name / quote number are escaped (`<script>` tag is neutralized)
- Two-row table produces both alternating row colors (`#ffffff`, `#f9fafb`)
- Line items with all-null fields render dashes without throwing exceptions

**formatCurrency (via @TestVisible):**
- `0` formats as `$0.00`
- `99.99` formats as `$99.99`
- `1234.56` formats as `$1,234.56`
- `1234567.89` formats as `$1,234,567.89`
- `-500.00` formats starting with `-$`
- `10.555` rounds up to `$10.56` (HALF_UP)
- `25.5` is padded to `$25.50`
- `null` returns `'-'`
- `1000` formats as `$1,000.00`

**Wrapper class instantiation:**
- `QuoteDetailsWrapper` and `QuoteLineItem` can be instantiated and their `@AuraEnabled` fields are writable and readable

---

## Security

### Sharing Model

- `SendOvfEmailController` is declared `public with sharing`, meaning it respects the running user's record sharing rules.
- Both SOQL queries use `WITH USER_MODE`, which enforces the running user's object and field-level security at the query level (Apex API 65.0+ feature).

### HTML Injection Prevention

All dynamic values written into the email HTML body are passed through `String.escapeHtml4()` before insertion:
- Contact first name / full name
- Quote number
- Product names

### Email Logging

The email is sent via `setTargetObjectId(contactId)` and `setWhatId(quoteId)` with `setSaveAsActivity(true)`, so the email is automatically logged as a completed Task / Email Activity record visible on both the Contact and the Quote. This creates a full audit trail of when each OVF invitation was sent.

### Required Permissions for Users

For a sales rep to use this feature, they need:

- Read access to `SBQQ__Quote__c` and `SBQQ__QuoteLine__c`
- Read access to `Contact` (including the Email field)
- Read access to `Product2` (for product name in line items)
- "Send Email" permission (standard Salesforce user permission)
- The quick action must be on the Quote page layout or Lightning App Builder page

---

## Notes and Considerations

### Known Limitations

- **Primary Contact dependency** — The feature requires `Primary_Contact__c` to be populated on the Quote. This field is a custom field populated by `QuoteTriggerHelper.cls` from the CPQ-managed `SBQQ__PrimaryContact__c` field. If the trigger has not run or the CPQ field is blank, the "Send OVF" button will display an error in the modal rather than failing silently.
- **Single recipient only** — The email is sent only to the primary contact. There is no option to add CC recipients or send to multiple contacts.
- **Email deliverability limits** — Subject to the org's daily Salesforce email limits (1,000 external emails per org per day in Developer/sandbox editions; higher in production). The `Messaging.sendEmail` call uses a single `SingleEmailMessage`, so each click consumes one unit.
- **Sandbox URL hardcoded** — The OVF portal URL (`OVF_PORTAL_URL`) is hardcoded to the sandbox site URL (`rubrikinc--claudepoc.sandbox.my.salesforce-sites.com`). This must be updated to the production Experience Site URL before going live in production.
- **Currency locale** — `formatCurrency` in Apex formats amounts as USD (`$`) with no locale detection. `formatCurrency` in the LWC uses `Intl.NumberFormat('en-US', ...)` for client-side display. Quotes in non-USD currencies will still show a `$` prefix.

### Future Enhancements

- Move `OVF_PORTAL_URL` to a Custom Metadata Type or Custom Setting so it can be environment-specific without a code change.
- Add a "Resend" detection: check if an OVF email Activity already exists on the Quote and warn the rep before sending a duplicate.
- Support CC addresses or additional recipients from the LWC confirmation screen.
- Add a field on `SBQQ__Quote__c` to timestamp when the OVF email was last sent (e.g., `OVF_Email_Sent_Date__c`) for reporting and de-duplication.
- Localize the `formatCurrency` helper to respect the Quote's `CurrencyIsoCode` when the org has multi-currency enabled.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `SBQQ__Quote__c` | Managed object (Salesforce CPQ) | Source object for the quick action |
| `SBQQ__QuoteLine__c` | Managed object (Salesforce CPQ) | Child line items queried for the email table |
| `SBQQ__Product__r.Name` | Managed relationship | Product name pulled via relationship from QuoteLine |
| `Primary_Contact__c` | Custom field on `SBQQ__Quote__c` | Populated by `QuoteTriggerHelper.cls`; required for email send |
| `OVF__c` | Custom object (existing) | Not directly used by this feature, but the OVF portal that receives submissions is served by `RubrikQuoteLookupController.cls` |
| `QuoteTriggerHelper.cls` | Existing Apex | Upstream dependency — copies `SBQQ__PrimaryContact__c` into `Primary_Contact__c` |
| Salesforce Experience Site | Infrastructure | The OVF portal at the hardcoded URL must be active and accessible |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-27 | Documentation Agent | Initial creation |
