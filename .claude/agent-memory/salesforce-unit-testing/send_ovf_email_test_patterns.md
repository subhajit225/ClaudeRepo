# SendOvfEmailController Test Patterns

## AuraHandledException Dual-Check (Critical)

`AuraHandledException.getMessage()` in test context returns `'Script-thrown exception'`
instead of the original string. Always use OR to handle both:

```apex
Assert.isTrue(
    e.getMessage().contains('Quote Id is required') ||
    e.getMessage().contains('Script-thrown exception'),
    'Exception should indicate Quote Id is required'
);
```

## Fake Id Construction

```apex
Id fakeId = SBQQ__Quote__c.sObjectType.getDescribe().getKeyPrefix() + '000000000001AAA';
```
Use distinct suffixes (001AAA, 002AAA) for multiple fake IDs in the same class.

## @TestVisible Private Method Calls

Both formatCurrency and buildEmailHtml are @TestVisible and can be called directly:

```apex
String result = SendOvfEmailController.formatCurrency(1234.56);
String html   = SendOvfEmailController.buildEmailHtml('FirstName', 'Q-0001', linesList);
```

## buildEmailHtml with Null Line Item Fields

A bare `new SBQQ__QuoteLine__c()` (no fields set) is safe to pass to buildEmailHtml —
the method guards every field with null checks and renders '-' for nulls.
Assert with: `html.contains('>-<')` to cover the null branches.

## SBQQ__QuoteLine__c Relationship Field in Tests

To get `SBQQ__Product__r.Name` populated on lines, always SOQL-query after insert:

```apex
List<SBQQ__QuoteLine__c> lines = [
    SELECT SBQQ__Product__r.Name, SBQQ__Quantity__c, SBQQ__ListPrice__c, SBQQ__NetTotal__c
    FROM SBQQ__QuoteLine__c
    WHERE SBQQ__Quote__c = :quote.Id
    ORDER BY SBQQ__Number__c ASC
];
```

## Primary_Contact__c Field

On SBQQ__Quote__c in this org, the OVF controller uses `Primary_Contact__c` (custom
lookup to Contact), NOT the standard SBQQ__PrimaryContact__c. Set this field on insert
when the test needs a primary contact.

## Contact Without FirstName

Omitting FirstName entirely is sufficient to exercise the fallback branch in sendOvfEmail
that uses `quote.Primary_Contact__r.Name` instead of `FirstName`.

## formatCurrency Coverage Map

| Branch | Input | Expected |
|--------|-------|----------|
| null guard | null | '-' |
| zero | 0 | '$0.00' |
| no separator | 99.99 | '$99.99' |
| thousands | 1234.56 | '$1,234.56' |
| large | 1234567.89 | '$1,234,567.89' |
| negative | -500.00 | starts with '-$' |
| rounding | 10.555 | '$10.56' |
| single decimal | 25.5 | contains '25.50' |
| exact thousand | 1000 | '$1,000.00' |

## getQuoteDocumentAttachment — Correct Test Target

The controller does NOT use SBQQ__QuoteDocument__c or ContentVersion/ContentDocumentLink.
It queries:
  1. SBQQ__Quote__c.SBQQ__Opportunity2__c
  2. Attachment WHERE ParentId = opportunityId AND Name LIKE '%.pdf' ORDER BY CreatedDate DESC LIMIT 1

Tests MUST place Attachment records on the linked Opportunity, not on any QuoteDocument.
ContentVersion-based tests will always yield null and fail Assert.isNotNull checks.

Correct setup pattern:
```apex
SBQQ__Quote__c quote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
Attachment att = new Attachment(
    ParentId    = quote.SBQQ__Opportunity2__c,
    Name        = 'QuoteProposal.pdf',
    Body        = Blob.valueOf('Mock PDF Body'),
    ContentType = 'application/pdf'
);
insert att;
```

Null return cases:
- Quote has no SBQQ__Opportunity2__c → null
- No Attachment on Opportunity matching '%.pdf' → null
- Attachment.Body is null → null

## OWE (Org-Wide Email Address) — Removed in March 2026

The OWE query (donotreply@rubrik.com) and setReplyTo call were removed from sendOvfEmail.
Emails now send from the running user automatically.
No test setup for OrgWideEmailAddress is needed or valid for this controller.
