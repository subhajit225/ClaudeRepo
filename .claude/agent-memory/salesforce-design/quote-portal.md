# RubrikQuotePortal Details

## Files
- VF Page: force-app/main/default/pages/RubrikQuotePortal.page
- Controller: force-app/main/default/classes/RubrikQuoteLookupController.cls

## Controller
- Class: RubrikQuoteLookupController (with sharing)
- Inner class: QuoteLookupResult (has quoteUrl field, @AuraEnabled)
- Methods:
  - lookupQuoteVF(@RemoteAction) - delegates to lookupQuote
  - lookupQuote(@AuraEnabled) - validates quoteNumber + email against SBQQ__PrimaryContact__r.Email
- Returns QuoteLookupResult with quoteUrl or null if not found

## VF Page
- No header/sidebar, custom HTML5 page
- Split layout: left panel (Rubrik brand + matrix rain canvas), right panel (form)
- Uses Visualforce.remoting.Manager.invokeAction for @RemoteAction calls
- CSS classes: .field-group, .field-label, .field-input, .btn-submit, .success-state
- Current flow: validate quote+email -> show success -> redirect to quoteUrl after 1.5s

## SOQL Query
SELECT Id, Name, SBQQ__Opportunity2__c
FROM SBQQ__Quote__c
WHERE Name = :sanitisedQuote
  AND SBQQ__PrimaryContact__r.Email = :sanitisedEmail
LIMIT 1
