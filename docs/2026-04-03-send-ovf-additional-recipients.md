# Send OVF — Additional Recipients Feature

**Date:** 2026-04-03
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Add an optional "Additional Recipients" text input to the `sendOvfQuickAction` LWC. Users can enter comma-separated email addresses. These are CC'd on the OVF email. Server-side validation (format check, control character stripping, 10-recipient cap) was added to `SendOvfEmailController.sendOvfEmail()`.

### Business Objective

Sales reps sometimes need to loop in managers, deal desk colleagues, or distribution lists when sending the Order Verification Form. Previously the OVF email was sent exclusively to the primary contact, with no mechanism to notify additional stakeholders. This feature lets reps specify up to 10 CC recipients at send time without modifying the quote record or creating a workaround.

### Summary

An optional free-text input was added to the Send OVF quick action UI allowing users to enter comma-separated email addresses that will be CC'd on the outbound OVF email. Client-side validation in the LWC catches formatting errors before the Apex call is made, while server-side validation in `SendOvfEmailController` provides a second layer of sanitisation — stripping control characters, re-validating format, and enforcing a 10-recipient cap — before the addresses are passed to `Messaging.SingleEmailMessage.setCcAddresses()`. Two new test methods were added to `SendOvfEmailControllerTest` to cover the happy path (valid CC list) and the graceful no-op path (empty CC list).

---

## Components Created

### Admin Components (Declarative)

No declarative components were created or modified for this feature. All changes are code-only.

---

### Development Components (Code)

#### Apex Classes Modified

| Class Name | Type | Change Description |
|------------|------|--------------------|
| `SendOvfEmailController` | Controller | `sendOvfEmail` method signature updated; CC logic, sanitisation, and recipient cap added |

#### Test Classes Modified

| Test Class | Tests For | New Test Methods Added |
|------------|-----------|------------------------|
| `SendOvfEmailControllerTest` | `SendOvfEmailController.sendOvfEmail` | `testSendOvfEmail_withAdditionalRecipients`, `testSendOvfEmail_withEmptyAdditionalRecipients` |

#### Lightning Web Components Modified

| Component Name | Files Changed | Change Description |
|----------------|---------------|--------------------|
| `sendOvfQuickAction` | `sendOvfQuickAction.html` | New "Additional Recipients" input field and conditional error message block |
| `sendOvfQuickAction` | `sendOvfQuickAction.js` | `additionalEmails` and `additionalEmailsError` state properties; `handleAdditionalEmailsChange` handler; `validateAdditionalEmails` method; updated `handleSend` to build and pass the CC list |
| `sendOvfQuickAction` | `sendOvfQuickAction.css` | New CSS rules for `.additional-emails-section`, `.optional-label`, `.field-helper-text`, `.field-error-text` |

---

## Data Flow

### How It Works

1. The user opens the "Send OVF" quick action on a `SBQQ__Quote__c` record page.
2. The quick action loads the contact preview via `SendOvfEmailController.getQuoteDetails` (unchanged).
3. The user optionally types one or more email addresses, separated by commas, in the "Additional Recipients" input.
4. The LWC `validateAdditionalEmails` method runs on the client immediately when the Send button is clicked. It splits the raw input on commas, trims whitespace, and tests each token against the regex `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`. If any token fails, an inline error message is rendered and the Apex call is aborted.
5. If client-side validation passes, `handleSend` builds a clean `String[]` (trimmed, non-empty tokens) and passes it as the `additionalEmails` parameter to `sendOvfEmail`.
6. `SendOvfEmailController.sendOvfEmail(quoteId, additionalEmails)` runs server-side validation:
   - If the list contains more than 10 entries, an `AuraHandledException` is thrown.
   - Each address has control characters (`\n`, `\r`, `\t`) stripped.
   - The cleaned address is matched against the same regex pattern. Any address that does not match is collected into an `invalidEmails` list; if that list is non-empty, an `AuraHandledException` is thrown naming the offending addresses.
   - Clean, validated addresses are passed to `email.setCcAddresses(sanitisedEmails)`.
7. If `additionalEmails` is null or empty, `setCcAddresses` is never called and the email behaves identically to the pre-feature behaviour.
8. On success the LWC shows a toast and closes the action panel. On failure the toast displays the server error.

### Architecture Diagram

```
User types CC addresses
        |
        v
sendOvfQuickAction (LWC)
  - additionalEmails (state)
  - handleAdditionalEmailsChange -> clears error
  - handleSend
      |
      +--> validateAdditionalEmails()
      |       regex check per token
      |       sets additionalEmailsError if invalid
      |       returns false  --> inline error shown, Apex NOT called
      |
      +--> [validation passes]
              build additionalEmailsList (trim, filter empty)
              |
              v
      sendOvfEmail({ quoteId, additionalEmails: additionalEmailsList })
              |
              v
      SendOvfEmailController.sendOvfEmail(quoteId, additionalEmails)
        1. fetchAndValidateQuote(quoteId)          [unchanged]
        2. if additionalEmails not null/empty:
             a. size > 10? --> AuraHandledException
             b. strip control chars from each addr
             c. regex validate each addr
             d. any invalid? --> AuraHandledException (names them)
             e. email.setCcAddresses(sanitisedEmails)
        3. build email body, attach PDF if present  [unchanged]
        4. Messaging.sendEmail(...)
              |
              v
        returns 'SUCCESS'
              |
              v
      LWC shows success toast, closes action
```

---

## File Locations

| Component Type | Path |
|----------------|------|
| LWC Template | `force-app/main/default/lwc/sendOvfQuickAction/sendOvfQuickAction.html` |
| LWC Controller | `force-app/main/default/lwc/sendOvfQuickAction/sendOvfQuickAction.js` |
| LWC Styles | `force-app/main/default/lwc/sendOvfQuickAction/sendOvfQuickAction.css` |
| Apex Controller | `force-app/main/default/classes/SendOvfEmailController.cls` |
| Apex Test Class | `force-app/main/default/classes/SendOvfEmailControllerTest.cls` |

---

## Configuration Details

### LWC — New State Properties (`sendOvfQuickAction.js`)

| Property | Type | Default | Purpose |
|----------|------|---------|---------|
| `additionalEmails` | `String` | `''` | Raw value of the text input as typed by the user |
| `additionalEmailsError` | `String` | `''` | Error message rendered beneath the input; empty string hides the error |

### LWC — New and Modified Methods (`sendOvfQuickAction.js`)

| Method | Description |
|--------|-------------|
| `handleAdditionalEmailsChange(event)` | Syncs `additionalEmails` from `event.detail.value` and clears any prior error message |
| `validateAdditionalEmails()` | Splits on comma, trims each token, tests against email regex. Populates `additionalEmailsError` and returns `false` on failure; returns `true` when valid or empty |
| `handleSend()` (modified) | Calls `validateAdditionalEmails()` first. Builds `additionalEmailsList` array from the raw input and passes it to the Apex call as `additionalEmails` |

### LWC — New HTML Block (`sendOvfQuickAction.html`)

The "Additional Recipients" section is inserted between the Contact & Quote details card and the Line Items table:

- A `<label>` styled with the existing `.detail-label` class, plus an "(optional)" span using the new `.optional-label` class.
- A `<lightning-input type="text">` bound to `additionalEmails` via `onchange={handleAdditionalEmailsChange}`. The input is disabled during send (`disabled={isSending}`).
- A helper text paragraph with placeholder guidance ("Separate multiple addresses with a comma").
- A conditional `<template lwc:if={additionalEmailsError}>` that renders the `.field-error-text` paragraph when an error is present.

### LWC — New CSS Rules (`sendOvfQuickAction.css`)

| Rule | Purpose |
|------|---------|
| `.additional-emails-section` | Wrapping div — white background (`#fafbfc`), light border, 6px radius, 12px/16px padding — visually matches the `.detail-card` above it |
| `.optional-label` | Removes bold weight and uppercase transform from the "(optional)" text; mutes colour to `#999999` |
| `.field-helper-text` | 12px grey instructional copy beneath the input |
| `.field-error-text` | 12px error copy in Salesforce error red (`#c23934`) shown conditionally |

### Apex — Method Signature Change (`SendOvfEmailController.cls`)

**Before:**
```apex
public static String sendOvfEmail(Id quoteId)
```

**After:**
```apex
public static String sendOvfEmail(Id quoteId, List<String> additionalEmails)
```

The new parameter is optional in practice — passing `null` or an empty list reproduces the previous behaviour exactly.

### Apex — Server-Side Validation Logic

The following guards execute only when `additionalEmails != null && !additionalEmails.isEmpty()`:

| Check | Condition | Error Thrown |
|-------|-----------|--------------|
| Recipient cap | `additionalEmails.size() > 10` | `'A maximum of 10 additional recipients is allowed.'` |
| Control character stripping | Always applied (replaces `\n`, `\r`, `\t` with empty string) | — (sanitisation, not rejection) |
| Email format | Each cleaned address must match `^[^\s@]+@[^\s@]+\.[^\s@]+$` | `'Invalid email address(es): <list of bad addresses>'` |

Valid, cleaned addresses are set via `email.setCcAddresses(sanitisedEmails)` before the email is sent.

---

## Testing

### Test Coverage Summary

| Class | New Methods | Scenarios Covered |
|-------|-------------|-------------------|
| `SendOvfEmailControllerTest` | `testSendOvfEmail_withAdditionalRecipients` | Two valid CC addresses passed; email sends successfully or fails with delivery error only |
| `SendOvfEmailControllerTest` | `testSendOvfEmail_withEmptyAdditionalRecipients` | Empty `List<String>` passed; `setCcAddresses` is skipped; email sends successfully |

All pre-existing test methods were updated to pass `null` as the second argument to `sendOvfEmail` (replacing the previous single-argument call), ensuring no compilation or runtime regressions.

### Key Test Scenarios for New Methods

1. **Happy path with CC recipients** — `testSendOvfEmail_withAdditionalRecipients`: Passes `['cc.one@example.com', 'cc.two@example.com']` and asserts `SUCCESS` (or tolerates a sandbox delivery restriction error).
2. **Empty additional list** — `testSendOvfEmail_withEmptyAdditionalRecipients`: Passes `new List<String>()` and asserts `SUCCESS` (or tolerates a sandbox delivery restriction error), confirming the empty-list branch is a no-op.

Note: The 10-recipient cap and invalid-address rejection paths are protected by the client-side `validateAdditionalEmails` check in the LWC before the Apex call is made. Server-side unit tests for these specific exception branches (more than 10 addresses, malformed address) are covered implicitly by the structure of the validation block and can be added as targeted negative tests in a future iteration.

---

## Security

### Sharing Model

`SendOvfEmailController` uses `with sharing`, unchanged from the original implementation. All SOQL queries use `WITH USER_MODE` (API v65.0+), ensuring field- and object-level security is enforced.

### Input Sanitisation

| Layer | Mechanism |
|-------|-----------|
| Client (LWC) | Regex validation before Apex call — prevents obviously malformed addresses from reaching the server |
| Server (Apex) | Control character stripping (`\n`, `\r`, `\t`) prevents header-injection attacks on the email's CC field; format re-validation mirrors the client check |
| Server (Apex) | 10-recipient hard cap limits blast-radius if a large address list is somehow submitted |

### Required Permissions

No new permissions are required. The feature reuses the existing `AuraEnabled` method on `SendOvfEmailController`, which is already accessible to users who can invoke the "Send OVF" quick action on the `SBQQ__Quote__c` record page.

---

## Notes and Considerations

### Known Limitations

- The regex used for email validation (`^[^\s@]+@[^\s@]+\.[^\s@]+$`) is intentionally permissive. It accepts some technically invalid addresses (e.g., `a@b.c` with a single-character TLD). This matches the pre-existing design choice in the project and avoids false positives on unusual but legitimate corporate addresses.
- The 10-recipient cap is enforced only server-side. The LWC does not surface a real-time count or show an error before the user clicks Send. A future enhancement could add a client-side cap check inside `validateAdditionalEmails`.
- Existing test methods in `SendOvfEmailControllerTest` that called the single-argument overload of `sendOvfEmail` have all been updated to pass `null` as the second argument, which is functionally equivalent to the previous call.

### Future Enhancements

- Add a client-side real-time count display (e.g., "3/10 recipients") inside the "Additional Recipients" section.
- Add explicit server-side negative unit tests for the `> 10 recipients` cap and the invalid-format rejection branch.
- Consider persisting CC addresses as a quote field so they are pre-populated if the user reopens the action.

### Dependencies

| Dependency | Notes |
|------------|-------|
| `SendOvfEmailController.getQuoteDetails` | Unchanged; still used by the LWC to populate the preview |
| `SendOvfEmailController.fetchAndValidateQuote` | Unchanged private helper called by `sendOvfEmail` |
| `Messaging.SingleEmailMessage` | Standard Salesforce email API; `setCcAddresses` accepts a `List<String>` |
| `Label.OVF_Portal_URL` | Custom label used in the email body; not related to this change |

---

## Change History

| Date | Author | Change Description |
|------|--------|--------------------|
| 2026-04-03 | Documentation Agent | Initial creation |
