# RubrikQuoteLookupController — Dynamic OVF Test Patterns

## Instance vs Static Method Testing

`getActiveFieldSetName()` and `getOvfFieldSetMembers()` are instance methods on the controller.
Always instantiate the controller before calling them:

```apex
RubrikQuoteLookupController ctrl = new RubrikQuoteLookupController();
String name = ctrl.getActiveFieldSetName();
List<RubrikQuoteLookupController.OVFFieldMember> members = ctrl.getOvfFieldSetMembers();
```

## Field Set Tests in Sandbox/Scratch Orgs

`getOvfFieldSetMembers()` returns an empty list when the AWSOVFFieldSet field set does not exist
in the target org. Assert `result != null` only — do NOT assert `result.size() > 0`, as that would
fail in orgs where the field set is absent.

## submitOVFDynamic JSON Construction

Use `JSON.serialize(new Map<String, Object>{...})` to build the JSON argument rather than
a hardcoded string literal. This avoids escaping issues and is easier to read:

```apex
String fieldValuesJson = JSON.serialize(new Map<String, Object>{
    'Buyer_Name__c'   => 'Test Buyer',
    'Company_Name__c' => 'Test Corp'
});
```

## submitOVFDynamic — Invalid JSON Exception

The controller wraps `JSON.deserializeUntyped` failures in `OVFSubmitException` with the prefix
"Invalid field values JSON:". Catch `RubrikQuoteLookupController.OVFSubmitException` and check
that the message contains `'Invalid field values JSON'`.

## submitOVFDynamic — Unknown Field Skipping

Fields not present in `Schema.SObjectType.OVF__c.fields.getMap()` are silently skipped via a
`continue` statement. Test this by including a made-up field alongside a real field and asserting
the call succeeds (returns a valid Id).

## Salesforce Id Length Assertion Pattern

After a dynamic insert, assert the Id has 15 or 18 characters as a lightweight validity check:

```apex
Assert.isTrue(
    ovfId.length() == 15 || ovfId.length() == 18,
    'Returned value should be a valid Salesforce Id; got: ' + ovfId
);
```

## Existing Setup Data Reuse

The `@TestSetup` in RubrikQuoteLookupControllerTest already creates an `SBQQ__Quote__c` record
and disables triggers. All new `submitOVFDynamic` tests reuse `getTestQuote()` to retrieve it —
no additional setup is needed for the OVF dynamic tests.
