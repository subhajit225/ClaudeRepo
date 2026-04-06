# Exception Type Migration Pattern

## Context
When a controller's guard clause changes from throwing `AuraHandledException` to throwing
`IllegalArgumentException` or `CalloutException`, test catch blocks that name the old type
will silently pass through to the `Assert.fail` line — which means the test crashes rather
than passes, because the uncaught exception propagates out of the try block.

## The Bug Pattern to Watch For
```apex
// OLD test — will FAIL after bug fix because IllegalArgumentException propagates past the catch
try {
    SomeController.method('');
    Assert.fail('Expected exception');
} catch (AuraHandledException ahe) {   // <-- wrong type, never reached
    exceptionThrown = true;
}
```

## The Fix Pattern
Replace the catch type to match what the controller actually throws:

```apex
// NEW test — catches the correct type
try {
    SomeController.method('');
    Assert.fail('Expected IllegalArgumentException was not thrown');
} catch (IllegalArgumentException iae) {
    exceptionThrown = true;
    Assert.isTrue(
        iae.getMessage().contains('expected fragment'),
        'Message should contain expected text; got: ' + iae.getMessage()
    );
}
Assert.isTrue(exceptionThrown, 'IllegalArgumentException should have been thrown');
```

## Rules
1. Always catch the specific type the controller throws — not `Exception` as a catch-all
   for the primary expected scenario (broad catch is acceptable only as a fallback for
   unexpected org-configuration differences).
2. After catching, assert on `getMessage()` to verify the message content, not just that
   something was thrown.
3. When a single guard covers blank, null, and whitespace, add a separate test for each
   variant (the `String.isBlank` function treats all three identically, but explicit tests
   document that intent and give full branch coverage).

## CalloutException for DML Failure Path
When the controller wraps DML failures in `CalloutException`:
```apex
} catch (CalloutException ce) {
    exceptionThrown = true;
    Assert.isTrue(
        ce.getMessage().contains('Failed to submit OVF'),
        'Message prefix check; got: ' + ce.getMessage()
    );
} catch (Exception ex) {
    // Org-specific DML behavior may produce a different exception in sandbox vs scratch
    exceptionThrown = true;
}
```
Include the broad `catch (Exception ex)` fallback only for the DML-failure test, not for
the guard-clause tests where the exception type is deterministic.
