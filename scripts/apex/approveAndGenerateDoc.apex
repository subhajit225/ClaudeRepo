// Approve Q-848689 and generate quote document
Id quoteId = 'a6TU8000000ZO97MAG';

// Step 1: Approve the quote
SBQQ__Quote__c q = new SBQQ__Quote__c(
    Id                = quoteId,
    SBQQ__Status__c   = 'Approved',
    ApprovalStatus__c = 'Approved'
);
update q;
System.debug('Quote approved.');

// Step 2: Trigger CPQ document generation
SBQQ__Quote__c gen = new SBQQ__Quote__c(
    Id                    = quoteId,
    Generate_Document__c  = true,
    SBQQ__DocumentStatus__c = 'Ready for Preview'
);
update gen;
System.debug('Document generation triggered.');

// Verify final state
SBQQ__Quote__c result = [
    SELECT Name, SBQQ__Status__c, ApprovalStatus__c,
           SBQQ__DocumentStatus__c, SBQQ__QuoteTemplateId__c
    FROM SBQQ__Quote__c WHERE Id = :quoteId
];
System.debug('Status: ' + result.SBQQ__Status__c);
System.debug('ApprovalStatus: ' + result.ApprovalStatus__c);
System.debug('DocumentStatus: ' + result.SBQQ__DocumentStatus__c);
System.debug('Template: ' + result.SBQQ__QuoteTemplateId__c);
