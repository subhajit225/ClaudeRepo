/** @description 
* -------------------------- @History------------------------------------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* FY26WL-353         Asif Hussain          4-Dec-2025      Wrapper Class
* --------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class EntitlementResponseWrapper {
    @AuraEnabled public String entitlementIdsForResponse;
    @AuraEnabled public String opportunityId;
    @AuraEnabled public String opportunityName;
    @AuraEnabled public String quoteId;
    @AuraEnabled public String quoteLineId;
    @AuraEnabled public String quoteLineNumber;
    @AuraEnabled public String productName;
    public Set<String> entitlementIds;

}