# Bug Fix: Script-thrown Exception on OVF Form Submission

**Date:** 2026-03-27
**Author:** Documentation Agent
**Status:** Completed

---

## Overview

### Original Request

Fix "Script-thrown exception" error on OVF form submission in RubrikQuotePortal Visualforce page.

Root Cause: `submitOVF` method in `RubrikQuoteLookupController` was annotated with `@RemoteAction` but threw `AuraHandledException`, which is only compatible with `@AuraEnabled` Lightning methods. Visualforce Remote Actions surface this as a generic "Script-thrown exception".

Changes Made:
1. `RubrikQuoteLookupController.cls` — Added `OVFSubmitException extends Exception` inner class. Replaced `AuraHandledException` with `IllegalArgumentException` (for blank quoteId guard) and `OVFSubmitException` (for DML errors). Fixed double-wrap bug in catch block by adding `catch (OVFSubmitException oe) { throw oe; }` before the general catch.
2. `RubrikQuoteLookupControllerTest.cls` — Updated test methods to catch `IllegalArgumentException` and `RubrikQuoteLookupController.OVFSubmitException` instead of `AuraHandledException`/`CalloutException`. Added whitespace quoteId test case.

### Business Objective

When a buyer submits the OVF form on the public RubrikQuotePortal Visualforce page, the JavaScript remoting callback receives a `status` of `"EXCEPTION"` from Salesforce. If the server-side Apex throws `AuraHandledException`, the Visualforce remoting framework cannot unwrap it and surfaces only the generic message "Script-thrown exception" to the browser — hiding the real error message from both the user and any diagnostic logging. This bug fix ensures that meaningful, user-readable error messages propagate correctly through the Visualforce JavaScript Remoting API's `event.message` property.

### Summary

The `submitOVF` @RemoteAction method in `RubrikQuoteLookupController` incorrectly threw `AuraHandledException`, an exception type designed exclusively for `@AuraEnabled` Lightning methods. Replacing those throws with `IllegalArgumentException` (for input validation failures) and a new inner class `OVFSubmitException` (for DML failures) restores correct error propagation. The corresponding test class was updated to assert on the correct exception types and a new whitespace-only quoteId test case was added.

---

## Components Modified

### Development Components (Code)

#### Apex Classes

| Class Name | Type | Change Summary |
|------------|------|----------------|
| `RubrikQuoteLookupController` | Controller | Added `OVFSubmitException` inner class; replaced `AuraHandledException` with `IllegalArgumentException` and `OVFSubmitException` in `submitOVF`; fixed re-throw catch block ordering |
| `RubrikQuoteLookupControllerTest` | Test Class | Updated exception assertions from `AuraHandledException`/`CalloutException` to `IllegalArgumentException` and `OVFSubmitException`; added whitespace quoteId test case |

No admin components, triggers, LWC components, or flows were modified.

---

## Root Cause Analysis

### The Incompatibility

Salesforce exposes two distinct remoting mechanisms:

| Mechanism | Annotation | Exception Surface |
|-----------|------------|-------------------|
| Visualforce JavaScript Remoting | `@RemoteAction` | `event.message` in JS callback receives the exception `getMessage()` string |
| Lightning / Aura | `@AuraEnabled` | `AuraHandledException` message is passed to the LWC/Aura error handler |

`AuraHandledException` is a special Salesforce-internal exception. When thrown from an `@AuraEnabled` method, the platform serializes its message into the Lightning error envelope. When the same exception type is thrown from an `@RemoteAction` method, the Visualforce remoting framework does not know how to unwrap it and instead replaces the message with the generic string `"Script-thrown exception"`.

### Before the Fix (Broken State)

```
submitOVF (@RemoteAction)
  |
  |-- blank quoteId guard
  |     throw new AuraHandledException(...)   <-- wrong exception type
  |
  |-- DML save result errors
  |     throw new AuraHandledException(...)   <-- wrong exception type
  |
  |-- catch (AuraHandledException ahe) { throw ahe; }   <-- unnecessary re-throw
  |
  |-- catch (Exception ex)
        throw new AuraHandledException(...)   <-- wrong exception type
```

All three throws produced "Script-thrown exception" in the Visualforce page's JavaScript remoting callback, making it impossible for users or developers to identify what actually failed.

### The Double-Wrap Bug

The original code had a secondary problem. The general `catch (Exception ex)` block would have caught an `AuraHandledException` thrown inside the try block and wrapped it in a second `AuraHandledException`. The intermediate `catch (AuraHandledException ahe) { throw ahe; }` was the original developer's attempted workaround. Because the DML throw was replaced with `OVFSubmitException`, the correct fix is to keep a `catch (OVFSubmitException oe) { throw oe; }` block so that DML-sourced `OVFSubmitException` instances are not re-wrapped by the general catch.

### After the Fix (Correct State)

```
submitOVF (@RemoteAction)
  |
  |-- blank quoteId guard
  |     throw new IllegalArgumentException(...)   <-- standard exception, message propagates
  |
  |-- DML save result errors
  |     throw new OVFSubmitException(...)          <-- custom inner exception, message propagates
  |
  |-- catch (OVFSubmitException oe) { throw oe; } <-- prevents double-wrap
  |
  |-- catch (Exception ex)
        throw new OVFSubmitException('Failed to submit OVF: ' + ex.getMessage())
```

---

## Data Flow

### OVF Form Submission (Error Path — Before Fix)

```
Browser: user submits OVF form
        |
        v
Visualforce.remoting.Manager.invokeAction('submitOVF', ...)
        |
        v
RubrikQuoteLookupController.submitOVF (@RemoteAction)
        |
        v  [validation failure or DML error]
throw new AuraHandledException('...')
        |
        v
Visualforce remoting framework cannot unwrap AuraHandledException
        |
        v
JavaScript callback: event.status = "EXCEPTION"
                     event.message = "Script-thrown exception"   <-- message lost
```

### OVF Form Submission (Error Path — After Fix)

```
Browser: user submits OVF form
        |
        v
Visualforce.remoting.Manager.invokeAction('submitOVF', ...)
        |
        v
RubrikQuoteLookupController.submitOVF (@RemoteAction)
        |
        v  [validation failure]
throw new IllegalArgumentException('Quote Id is required to submit an OVF.')
        |     OR
        v  [DML error]
throw new OVFSubmitException('<database error message>')
        |
        v
Visualforce remoting framework serializes standard exception message
        |
        v
JavaScript callback: event.status = "EXCEPTION"
                     event.message = "Quote Id is required to submit an OVF."
                                     OR "<database error message>"   <-- message preserved
```

### Architecture Context

```
+---------------------------+     JavaScript Remoting      +----------------------------------+
|  RubrikQuotePortal.page   | --------------------------> |  RubrikQuoteLookupController     |
|  (Visualforce)            |                             |  submitOVF (@RemoteAction)       |
|                           | <-------------------------- |                                  |
|  event.message displayed  |  Id (success) OR exception  |  throws IllegalArgumentException |
|  to user                  |  message (failure)          |  OR OVFSubmitException           |
+---------------------------+                             +----------------------------------+
                                                                        |
                                                                        v
                                                          +----------------------------------+
                                                          |  OVF__c (custom object)          |
                                                          |  Database.insert(ovfRecord)      |
                                                          +----------------------------------+
```

---

## File Locations

| Component | Path |
|-----------|------|
| Apex Controller | `force-app/main/default/classes/RubrikQuoteLookupController.cls` |
| Apex Test Class | `force-app/main/default/classes/RubrikQuoteLookupControllerTest.cls` |
| Visualforce Page | `force-app/main/default/pages/RubrikQuotePortal.page` |

---

## Configuration Details

### Inner Class: OVFSubmitException

```
public class OVFSubmitException extends Exception {}
```

- Declared as a top-level inner class of `RubrikQuoteLookupController` (public access, so tests and other callers can catch it explicitly using `RubrikQuoteLookupController.OVFSubmitException`).
- Extends `Exception` with no additional fields or methods. The built-in `getMessage()` / `getCause()` from the base class are sufficient.
- Used exclusively in `submitOVF` for two scenarios: (1) DML save result returned errors, (2) an unexpected runtime exception was thrown inside the try block.

### Exception Usage in submitOVF

| Scenario | Exception Type | Message |
|----------|---------------|---------|
| `quoteId` is null, blank, or whitespace-only | `IllegalArgumentException` | `Quote Id is required to submit an OVF.` |
| `Database.insert` returns `!sr.isSuccess()` | `OVFSubmitException` | Concatenated `Database.Error.getMessage()` strings, trimmed |
| Any other unexpected `Exception` in the try block | `OVFSubmitException` | `Failed to submit OVF: ` + original exception message |

### Catch Block Ordering

The `submitOVF` try-catch uses a specific ordering to prevent double-wrapping:

```apex
} catch (OVFSubmitException oe) {
    throw oe;                                             // pass through unchanged
} catch (Exception ex) {
    throw new OVFSubmitException('Failed to submit OVF: ' + ex.getMessage());
}
```

The `OVFSubmitException` catch must appear before the general `Exception` catch. If reversed, an `OVFSubmitException` thrown inside the try block (from the DML error branch) would be caught by the general `Exception` handler and re-wrapped with a redundant "Failed to submit OVF:" prefix, losing the original DML error detail.

### Input Truncation (Unchanged)

All 15 optional string parameters are truncated to 255 characters using `String.abbreviate(255)` before the DML operation. This behavior was not changed by this bug fix.

### DML Access Level (Unchanged)

`Database.insert(ovfRecord)` uses the class-level `with sharing` enforcement rather than `AccessLevel.USER_MODE`. This is intentional: the CPQ managed-package lookup field (`Quote__c` -> `SBQQ__Quote__c`) causes `USER_MODE` DML to fail in orgs where the guest user lacks direct FLS on managed objects. This note is documented in an inline comment at line 109-112.

---

## Testing

### Test Coverage Summary

| Class | Tests For | Key Assertions |
|-------|-----------|----------------|
| `RubrikQuoteLookupControllerTest` | `RubrikQuoteLookupController` | Exception types, exception messages, record creation, field persistence |

### Test Methods Related to This Bug Fix

| Test Method | Scenario Covered | Expected Outcome |
|-------------|-----------------|-----------------|
| `testSubmitOVF_blankQuoteId_throwsIllegalArgumentException` | `quoteId = ""` | `IllegalArgumentException` with "Quote Id is required" |
| `testSubmitOVF_nullQuoteId_throwsIllegalArgumentException` | `quoteId = null` | `IllegalArgumentException` with "Quote Id is required" |
| `testSubmitOVF_whitespaceQuoteId_throwsIllegalArgumentException` | `quoteId = "   "` | `IllegalArgumentException` with "Quote Id is required" (new test case added by this fix) |
| `testSubmitOVF_invalidQuoteId_throwsOVFSubmitException` | Syntactically valid but non-existent quoteId | `RubrikQuoteLookupController.OVFSubmitException` or graceful success if org does not enforce referential integrity in tests |
| `testSubmitOVF_validData_createsRecordAndReturnsId` | Valid quoteId, all fields provided | Record created, all 16 fields persisted, Id returned |
| `testSubmitOVF_optionalFieldsBlank_createsRecord` | Valid quoteId, all optional fields null | Record created with only Quote__c populated |

### Test Data Notes

- `@TestSetup` creates Account, Contact, Opportunity, SBQQ__Quote__c, and OpportunityContactRole in a single transaction.
- `ShGl_DisableBusinessLogic__c` custom setting and `TriggerControls` static flags suppress CPQ automation during tests.
- The whitespace quoteId test (`"   "`) was added specifically for this fix to verify that `String.isBlank()` correctly returns `true` for whitespace-only strings, closing a gap in the previous test suite.

---

## Security

### Sharing Model

- `RubrikQuoteLookupController` is declared `public with sharing`, enforcing row-level sharing rules for the `submitOVF` DML.
- The `GuestQueryHelper` inner class is `private without sharing` — this is intentional for the `lookupQuote` path only, where the Site guest user cannot see CPQ/Opportunity records. This class is not involved in `submitOVF`.

### Public-Facing Exposure

`RubrikQuotePortal` is a public Visualforce page accessible without authentication (Salesforce Site). The `submitOVF` method is accessible via JavaScript Remoting to any unauthenticated user. Input validation (blank quoteId check) and field truncation (255-char abbreviate) are the primary defenses against malformed input. There is no server-side re-validation that the provided quoteId actually belongs to the authenticated session — callers with a valid Salesforce record Id can create OVF records linked to any quote they can reference.

---

## Notes and Considerations

### Known Limitations

- `IllegalArgumentException` is a standard Apex exception but is not a Salesforce-defined type — it is a Java-heritage exception available in Apex. It has no special platform handling. Visualforce remoting will serialize its `getMessage()` string correctly, which is the desired behavior.
- The `testSubmitOVF_invalidQuoteId_throwsOVFSubmitException` test is written defensively: it does not `Assert.fail()` if no exception is thrown, because some org configurations (test isolation levels) may not enforce referential integrity on lookup fields during tests. This is explicitly documented in the test body's comments.
- Error messages from `Database.Error.getMessage()` may contain internal Salesforce strings that are not suitable for direct display to end users. The Visualforce page's JavaScript remoting callback should sanitize or translate these before rendering.

### Future Enhancements

- Consider adding server-side session validation so that `submitOVF` only creates an OVF record if the provided `quoteId` was legitimately returned by the same user's prior `lookupQuoteVF` call in the current session (e.g., store the validated quoteId in a server-side session variable).
- The exception messages are hardcoded in English. If the portal expands to non-English locales, externalize messages to Custom Labels.
- Structured error codes (in addition to human-readable messages) would allow the JavaScript layer to handle specific error types differently without string parsing.

### Dependencies

| Dependency | Type | Notes |
|------------|------|-------|
| `OVF__c` custom object | Custom Object | Target of the DML insert in `submitOVF`; all 16 fields must exist |
| `SBQQ__Quote__c` (CPQ) | Managed Package Object | Referenced via the `Quote__c` lookup field on `OVF__c` |
| `RubrikQuotePortal.page` | Visualforce Page | The consuming UI that calls `submitOVF` via JavaScript Remoting |
| `ShGl_DisableBusinessLogic__c` | Custom Setting | Required in test context to suppress CPQ automation |
| `TriggerControls` | Apex Class | Required in test context to disable quote/quoteline triggers |

### Relationship to Prior Work

This bug fix applies to the `submitOVF` method that was introduced as part of the OVF Form Feature (documented in `docs/2026-03-27-ovf-form-feature.md`). The original feature implementation used `AuraHandledException` as a placeholder exception type. This fix corrects that implementation choice for the Visualforce remoting context.

---

## Change History

| Date | Author | Change Description |
|------|--------|-------------------|
| 2026-03-27 | Documentation Agent | Initial creation |
