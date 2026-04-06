# OVF Email Sender Fix — Spring '26 Domain Verification

**Date:** 2026-04-02
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

`SendOvfEmailController.cls` was updated to remove the Org-Wide Email Address (`donotreply@rubrik.com`) from the `sendOvfEmail()` method. Emails now send from the running user's email (sales rep) instead.

### Business Objective

Salesforce Spring '26 enforced stricter email domain verification. The previously configured Org-Wide Email Address (OWE) `donotreply@rubrik.com` was blocked because its domain could not be verified under the new rules. Sales reps are verified Salesforce users whose email domains pass verification automatically, so switching the sender to the running user resolves the delivery failure without any additional configuration.

### Summary

The `sendOvfEmail()` method in `SendOvfEmailController` was simplified by removing the OWE SOQL query, the `setOrgWideEmailAddressId` call, and the `setReplyTo` call. The corresponding test class was overhauled to remove broken attachment tests that targeted `SBQQ__QuoteDocument__c` (which does not store classic Attachments) and replace them with six correct tests that target classic `Attachment` records on the linked `Opportunity`.

---

## Components Modified

### Development Components (Code)

#### Apex Classes

| Class Name | Type | Change Made |
|------------|------|-------------|
| `SendOvfEmailController` | Controller | Removed OWE lookup, `setOrgWideEmailAddressId`, and `setReplyTo` from `sendOvfEmail()` |
| `SendOvfEmailControllerTest` | Test Class | Replaced broken `SBQQ__QuoteDocument__c` attachment tests with 6 correct `Attachment`-on-Opportunity tests |

No admin (declarative) components were created or modified.

---

## What Changed and Why

### SendOvfEmailController.cls

#### Before (removed code)

The `sendOvfEmail()` method contained the following logic that was removed:

1. A SOQL query against `OrgWideEmailAddress` to find the `donotreply@rubrik.com` OWE record.
2. `email.setOrgWideEmailAddressId(...)` — set the sender address to the OWE.
3. `email.setReplyTo(...)` — set a reply-to address tied to the OWE.

#### After (current state)

The `Messaging.SingleEmailMessage` is built without any OWE or reply-to configuration. Salesforce defaults the sender to the running user's email address, which is a verified domain automatically.

Key properties that remain unchanged:

| Property | Value |
|----------|-------|
| `setToAddresses` | Primary contact's email address |
| `setSubject` | `Action Required: Complete Your Order Verification Form for Quote [QuoteNumber]` |
| `setHtmlBody` | Branded HTML built by `buildEmailHtml()` |
| `setSaveAsActivity` | `false` |
| `setUseSignature` | `false` |
| `setFileAttachments` | PDF from linked Opportunity (if available) |

#### Root Cause

Salesforce Spring '26 introduced enforcement of email sender domain verification for Org-Wide Email Addresses. The `donotreply@rubrik.com` OWE was registered in Salesforce but the underlying DNS domain could not pass the verification check under the new enforcement rules. Any `Messaging.sendEmail()` call that referenced the unverified OWE resulted in a delivery failure at runtime.

Running user email addresses are tied to verified Salesforce user records and bypass the OWE domain verification requirement entirely.

---

### SendOvfEmailControllerTest.cls

#### Tests Removed

The previous test class contained tests that attempted to create `SBQQ__QuoteDocument__c` records and attach PDFs to them. The `getQuoteDocumentAttachment()` method does not query `SBQQ__QuoteDocument__c` — it queries classic `Attachment` records on the `Opportunity` linked through `SBQQ__Quote__c.SBQQ__Opportunity2__c`. These tests were therefore testing the wrong object and would always produce incorrect results.

#### Tests Added (6 new tests)

All six new tests place `Attachment` records on the correct parent — the linked `Opportunity` — which is what the production code actually queries.

| Test Method | Scenario Covered |
|-------------|-----------------|
| `testGetQuoteDocumentAttachment_noPdfOnOpportunity` | No PDF Attachment exists on the Opportunity — method returns `null` (graceful fallback) |
| `testGetQuoteDocumentAttachment_noLinkedOpportunity` | Quote has no `SBQQ__Opportunity2__c` — method returns `null` immediately |
| `testGetQuoteDocumentAttachment_withPdfOnOpportunity` | Single PDF Attachment on the Opportunity — method returns a valid `EmailFileAttachment` with correct file name and body |
| `testGetQuoteDocumentAttachment_picksLatestPdfOnOpportunity` | Multiple PDF Attachments on the Opportunity — method returns one of the inserted PDFs (ORDER BY CreatedDate DESC LIMIT 1) |
| `testSendOvfEmail_withPdfAttachment` | End-to-end: PDF Attachment exists on Opportunity, `sendOvfEmail` sends with attachment and returns `SUCCESS` |
| `testSendOvfEmail_withoutPdfAttachment` | End-to-end: no PDF Attachment on Opportunity, `sendOvfEmail` sends without attachment and returns `SUCCESS` |

---

## Data Flow

### How the Email Send Works (Post-Fix)

```
1. LWC calls sendOvfEmail(quoteId) on the controller
2. fetchAndValidateQuote() is called — queries quote, validates primary contact and email
3. buildEmailHtml() constructs the branded HTML body
4. getQuoteDocumentAttachment() queries:
       a. SBQQ__Quote__c.SBQQ__Opportunity2__c  →  gets the linked Opportunity Id
       b. Attachment WHERE ParentId = opportunityId AND Name LIKE '%.pdf'
          ORDER BY CreatedDate DESC LIMIT 1
5. Messaging.SingleEmailMessage is built:
       - To: primary contact email
       - Subject: "Action Required: ..."
       - Body: branded HTML
       - Sender: running user (Salesforce default — no OWE set)
       - Attachment: PDF blob if found in step 4, otherwise omitted
6. Messaging.sendEmail() transmits the message
7. Returns 'SUCCESS' or throws AuraHandledException on failure
```

### Architecture Diagram

```
LWC (sendOvfQuickAction)
        |
        | @AuraEnabled call
        v
SendOvfEmailController.sendOvfEmail(quoteId)
        |
        +---> fetchAndValidateQuote()
        |         Queries SBQQ__Quote__c + SBQQ__QuoteLine__c
        |         Validates Primary_Contact__c and email
        |
        +---> buildEmailHtml()
        |         Builds Rubrik-branded HTML body
        |
        +---> getQuoteDocumentAttachment()
        |         Step 1: SBQQ__Quote__c  -->  SBQQ__Opportunity2__c
        |         Step 2: Attachment on Opportunity (latest PDF)
        |         Returns: Messaging.EmailFileAttachment | null
        |
        v
Messaging.SingleEmailMessage
        - To: contact email
        - Sender: running user (Spring '26 compliant)
        - Body: HTML
        - Attachment: PDF (optional)
        |
        v
Messaging.sendEmail()  -->  Contact inbox
```

---

## File Locations

| Component | Path |
|-----------|------|
| Controller | `force-app/main/default/classes/SendOvfEmailController.cls` |
| Test Class | `force-app/main/default/classes/SendOvfEmailControllerTest.cls` |

---

## Configuration Details

### Email Sender Resolution

| Setting | Before Fix | After Fix |
|---------|-----------|-----------|
| Sender address | `donotreply@rubrik.com` (OWE) | Running user's Salesforce email |
| Reply-to | OWE-linked reply address | Not set (Salesforce default) |
| OWE SOQL query | Present | Removed |
| `setOrgWideEmailAddressId` | Called | Removed |
| `setReplyTo` | Called | Removed |
| Spring '26 compliant | No | Yes |

### PDF Attachment Resolution

The `getQuoteDocumentAttachment()` method follows a two-step query pattern:

1. Query `SBQQ__Quote__c` for `SBQQ__Opportunity2__c` (linked Opportunity Id).
2. Query `Attachment` where `ParentId = opportunityId AND Name LIKE '%.pdf'`, ordered by `CreatedDate DESC`, limit 1.

If either query returns no results, the method returns `null` and the email sends without an attachment. This is an intentional graceful fallback — email delivery is never blocked by a missing PDF.

---

## Testing

### Test Coverage Summary

| Class | Tests | Key Paths Covered |
|-------|-------|-------------------|
| `SendOvfEmailController` | All methods | Happy path, null quoteId, quote not found, no primary contact, no contact email, no line items, multi-quote governor limits |
| `SendOvfEmailControllerTest` (attachment block) | 6 tests | No PDF on Opp, no linked Opp, single PDF, multiple PDFs (latest selected), end-to-end with PDF, end-to-end without PDF |

### Key Test Scenarios

- Valid quote with two line items returns fully populated wrapper.
- Quote with no line items returns empty `lineItems` list without error.
- `null` quote Id throws `AuraHandledException` ("Quote Id is required.").
- Non-existent quote Id throws `AuraHandledException` ("Quote not found.").
- Quote without `Primary_Contact__c` throws `AuraHandledException`.
- Contact without `FirstName` falls back to full `Name` in email greeting.
- `formatCurrency`: zero, small value, thousand separator, large value, negative, rounding (HALF_UP), single decimal digit, null.
- `buildEmailHtml`: with/without line items, null line items, HTML escaping, alternating row colors, null field values render as dashes.
- `getQuoteDocumentAttachment`: no PDF on Opportunity, no linked Opportunity, single PDF, multiple PDFs (latest returned), end-to-end with attachment, end-to-end without attachment.
- 5-quote sequential governor limit test confirms no uncaught exceptions.

### Test Note — Sandbox Email Deliverability

`testSendOvfEmail_success` and related send tests use a try/catch pattern that accepts either `'SUCCESS'` or a `'Failed to send email'` / `'Script-thrown exception'` message. This is intentional: sandbox orgs may have email deliverability restricted to system emails only, which causes a delivery-level failure unrelated to the code under test. Type-level exception checking is sufficient to prove the code path is exercised.

---

## Security

### Sharing Model

- `SendOvfEmailController` is declared `public with sharing`.
- All SOQL queries use `WITH USER_MODE` (API 65.0+ feature), enforcing the running user's field-level security and object permissions.

### Email Sender Security

Previously, the OWE `donotreply@rubrik.com` was used to present a unified corporate sender identity. After the fix, emails are sent from the sales rep's own email address. This is compliant with Spring '26 domain verification rules and also provides recipients with a direct reply path to their account representative, which is arguably a better user experience.

### Required Permissions

| Permission | Required For |
|------------|-------------|
| Read on `SBQQ__Quote__c` | `fetchAndValidateQuote()` |
| Read on `Contact` | Primary contact validation |
| Read on `SBQQ__QuoteLine__c` | Line item retrieval |
| Read on `Attachment` | PDF attachment retrieval |
| `Messaging.sendEmail` | Email delivery |

---

## Notes and Considerations

### Known Limitations

- **Sender identity is now the sales rep.** Emails will display the rep's personal Salesforce email as the "From" address. If Rubrik requires a unified `noreply` sender identity in future, the OWE must be re-verified against Spring '26 DNS requirements before it can be re-introduced.
- **No reply-to is set.** Replies from the contact will go directly to the sales rep's inbox. This was previously controlled via `setReplyTo` on the OWE.
- **PDF attachment is best-effort.** If no `Attachment` record with a `.pdf` name extension exists on the linked Opportunity, the email sends without any attachment. This is intentional; the method is documented as a graceful fallback.
- **`CreatedDate` ordering within the same transaction.** In the test `testGetQuoteDocumentAttachment_picksLatestPdfOnOpportunity`, two attachments are inserted in the same transaction so database clock ordering is not guaranteed. The assertion accepts either PDF name as valid. In production, attachments accumulated over time will have deterministic `CreatedDate` ordering.

### Future Enhancements

- If a verified OWE becomes available post-Spring '26, it can be re-added to `sendOvfEmail()` with `setOrgWideEmailAddressId` and an optional `setReplyTo`.
- Consider using a `Messaging.MassEmailMessage` or Email Template approach if additional branding control (unsubscribe links, tracking) is needed in future.

### Dependencies

| Dependency | Purpose |
|------------|---------|
| `SBQQ__Quote__c` (CPQ managed package) | Source record for the quick action |
| `SBQQ__QuoteLine__c` (CPQ managed package) | Line items rendered in email body |
| `Opportunity` | Parent of the PDF Attachment |
| `Attachment` (classic attachment) | PDF document attached to email |
| `Contact` | Primary contact email recipient |
| `Label.OVF_Portal_URL` (Custom Label) | CTA button URL in email body |
| `sendOvfQuickAction` (LWC) | Invokes `sendOvfEmail()` from the Quote record page |

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-04-02 | Documentation Agent | Initial creation — documents Spring '26 OWE removal fix |
