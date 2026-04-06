# SBQQ Quote Test Patterns

## Trigger Bypass Before Inserting SBQQ__Quote__c

Always do both of these before inserting quotes in @TestSetup:

```apex
ShGl_DisableBusinessLogic__c dbl = new ShGl_DisableBusinessLogic__c(
    SetupOwnerId                           = UserInfo.getOrganizationId(),
    Disable_Account_Triggers__c            = true,
    Disable_Opportunity_Triggers__c        = true,
    Disable_Opportunity_Validation_Rules__c = true,
    Disable_SBQQ_Quote_Triggers__c         = true,
    Disable_SBQQ_Quote_Validation_Rules__c = true,
    Disable_SBQQ_QuoteLine_Triggers__c     = true,
    Disable_SBQQ_QuoteLine_Validation_Rules__c = true
);
insert dbl;
TriggerControls.disableQuoteTrigger     = true;
TriggerControls.disableQuoteLineTrigger = true;
```

## Quote Name is Auto-Generated

SBQQ__Quote__c.Name is an autonumber (Q-XXXXXXXX). After insert, always query it:

```apex
private static SBQQ__Quote__c getTestQuote() {
    return [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
}
```

## Email-Match SOQL Requires Real PrimaryContact

The `lookupQuote` SOQL filters on `SBQQ__PrimaryContact__r.Email`. The Contact must exist and be linked as SBQQ__PrimaryContact__c on the quote:

```apex
Contact primaryContact = new Contact(
    FirstName = 'Test', LastName = 'User',
    Email = 'test@example.com', AccountId = acct.Id
);
insert primaryContact;

SBQQ__Quote__c quote = new SBQQ__Quote__c(
    SBQQ__Account__c          = acct.Id,
    SBQQ__Opportunity2__c     = opp.Id,
    SBQQ__Primary__c          = true,
    SBQQ__Status__c           = 'Draft',
    SBQQ__Type__c             = 'Quote',
    SBQQ__PrimaryContact__c   = primaryContact.Id,
    SBQQ__StartDate__c        = System.today(),
    SBQQ__SubscriptionTerm__c = 12,
    SBQQ__PriceBook__c        = Test.getStandardPricebookId()
);
insert quote;
```

## AuraHandledException in Tests

When the controller throws `new AuraHandledException('message')`, the test catches it.
The `.getMessage()` may return `'Script-thrown exception'` in test context instead of
the original string. Assert with OR:

```apex
Assert.isTrue(
    ahe.getMessage().contains('Quote Id is required') ||
    ahe.getMessage().contains('Script-thrown exception'),
    'Should reference missing Quote Id'
);
```

## OVF__c Required Field

OVF__c.Quote__c is required (Lookup to SBQQ__Quote__c). Always pass a real quote Id
to submitOVF for success-path tests. The OVF Name field is also an AutoNumber (OVF-0000).

## Database.insert with USER_MODE

`Database.insert(record, AccessLevel.USER_MODE)` — System Administrator profile in tests
provides the CRUD rights needed. No special mock or bypass needed.
