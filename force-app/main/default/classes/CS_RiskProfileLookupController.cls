/**
 * @author Sushant Arora
 * @date 2024-11-19
 * @description 
 * This controller class provides methods to handle dynamic lookup searches and recently created records 
 * in Salesforce. It facilitates complex querying and filtering based on parameters and lookup functions.
 * 
 * @TestClass - CS_RiskProfileLookupControllerTest
 */
public class CS_RiskProfileLookupController {

    /**
     * @description Searches for lookup records based on the provided JSON configuration.
     * @param lookupJSON JSON string containing parameters for lookup search.
     * @return List<LookupSearchResult> A list of lookup search results with Id, title, and subtitle.
     * @throws AuraHandledException If an error occurs during the dynamic query execution.
     */
    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> searchLookupRecords(String lookupJSON) {
        
        Lookup lookup = (Lookup) JSON.deserialize(lookupJSON, Lookup.class);

        String searchTerm = lookup.lookupFxParam.searchTerm;
        List<String> selectedIds = lookup.lookupFxParam.selectedIds;
        String sObjectName = lookup.lookupFxParam.sObjectName;
        String field = lookup.lookupFxParam.field;
        String subField = lookup.lookupFxParam.subField;
        String sortBy = lookup.lookupFxParam.sortBy;
        String searchBy = lookup.lookupFxParam.searchBy;
        String additionalFields = lookup.lookupFxParam.additionalFields;
        Integer maxResults = lookup.lookupFxParam.maxResults;
        
        List<LookupSearchResult> results = new List<LookupSearchResult>();
        
        Map<String, Object> bindVariablesMap = new Map<String, Object>{'selectedIds' => selectedIds, 'maxResults'=>maxResults};
        Map<String, String> featureToActivationStatus= new Map<String,String>();
        Map<Id, Id> productToEntitlementMap = new Map<Id, Id>();
        Map<Id, Id> componentToProductMap = new Map<Id, Id>();

        // if(lookup.lookupFx.endsWithIgnoreCase('pdms')){//commented for Component
        //     additionalFields = 'Status__c, Product_Name__c';
        // }

        String strQuery = 'SELECT Id, '+field + (String.isNotBlank(subField) ? ' ,'+subField : '')+(String.isNotBlank(searchBy) ? ' ,'+searchBy : '')+(String.isNotBlank(additionalFields) ? ' ,'+additionalFields : '')+' FROM '+sObjectName;
        strQuery += ' WHERE '+(String.isNotBlank(searchBy)? searchBy : field) +' LIKE \'' + searchTerm + '%\' AND ';  
        strQuery += ' Id NOT IN :selectedIds';

        switch on lookup.lookupFx {
            when 'riskProfilePDMs'{
                if(lookup.lookupFxParam.additional.containsKey('Entitlement__c')){
                    List<String> entitlementIds = lookup.lookupFxParam.additional.get('Entitlement__c');
                    strQuery += ' AND Product_Name__c in (SELECT Product__c FROM Entitlement WHERE Id IN :entitlementIds)';
                    bindVariablesMap.put('entitlementIds', entitlementIds);
                }
            }
            when 'opportunityPDMs' {
                if(lookup.lookupFxParam.additional.containsKey('accountId') && lookup.lookupFxParam.additional.containsKey('Entitlement__c')){
                    List<String> entitlementIds = lookup.lookupFxParam.additional.get('Entitlement__c');
                    List<String> accountIds = lookup.lookupFxParam.additional.get('accountId');
                    strQuery += ' AND Product_Name__c in (SELECT Product__c FROM Entitlement WHERE Id IN :entitlementIds)';
                    bindVariablesMap.put('entitlementIds', entitlementIds);
                }
            }
            when 'entitlement' {
                if(lookup.lookupFxParam.additional.containsKey('accountId')) {
                    List<String> accountIds = lookup.lookupFxParam.additional.get('accountId');
                    strQuery += ' AND AccountId = :accountIds ';
                    System.debug(LoggingLevel.FINEST,'strQuery==>'+strQuery);
                    bindVariablesMap.put('accountIds', accountIds);
                }
            }
            when 'accountEntitlements'{
                if(lookup.lookupFxParam.additional.containsKey('accountId')) {
                    List<String> accountIds = lookup.lookupFxParam.additional.get('accountId');
                    String subQuery = '(SELECT Entitlement__c FROM Account_Score__b WHERE Account__c IN :accountIds )';
                    strQuery += ' AND Id IN ' + subQuery;
                    bindVariablesMap.put('accountIds', accountIds);
                }
            }
            when 'accountPDMs' {
                if(lookup.lookupFxParam.additional.containsKey('accountId') && lookup.lookupFxParam.additional.containsKey('Entitlement__c')) {
                    List<String> entitlementIds = lookup.lookupFxParam.additional.get('Entitlement__c');
                    List<String> accountIds = lookup.lookupFxParam.additional.get('accountId');
                    List<String> features = new List<String>();
            
                    for (Entitlement ent : [SELECT Id, Product__c FROM Entitlement WHERE Id IN :entitlementIds AND AccountId IN: accountIds]) {
                        if (ent.Product__c != null) {
                            productToEntitlementMap.put(ent.Product__c, ent.Id);
                        }
                    }
                    for(Bundle_Components_Allocation__c component : [SELECT Id, Product_SKU__c,Product_Name__c FROM Bundle_Components_Allocation__c  WHERE Component_Status__c ='Current' AND Product_Name__c IN :productToEntitlementMap.keySet() WITH SYSTEM_MODE]){
                        features.add((String)component.Id);
                        componentToProductMap.put(component.Id,component.Product_Name__c);
                    }
                    strQuery += ' AND Id IN :features';
                    bindVariablesMap.put('features', features);
                }
            }
            when 'opportunityEntitlements' {
                if(lookup.lookupFxParam.additional.containsKey('accountId') && lookup.lookupFxParam.additional.containsKey('Opportunity__c')) {
                    List<String> opportunityIds = lookup.lookupFxParam.additional.get('Opportunity__c');
                    SBQQ__QuoteLine__c[] quotelines = [select SBQQSC__RenewedContractLine__c from SBQQ__QuoteLine__c where SBQQ__Quote__c in (select SBQQ__PrimaryQuote__c from Opportunity where id = :opportunityIds) and SBQQSC__RenewedContractLine__c <> null];
                    List<String> contractLineIds = new List<String>();
                    for (SBQQ__QuoteLine__c ql : quoteLines) {
                        contractLineIds.add(ql.SBQQSC__RenewedContractLine__c);
                    }
                    strQuery += ' AND ContractLineItemId IN :contractLineIds';
                    bindVariablesMap.put('contractLineIds', contractLineIds);
                }
            }
            when 'riskProfileWatcher' {
                strQuery += ' AND IsPortalEnabled <> true and IsActive = true';
            }
        }
        
        strQuery +=' ORDER BY '+ (String.isNotBlank(sortBy) ? sortBy : searchBy) +' LIMIT :maxResults';
        List<sObject> searchResults = Database.queryWithBinds(strQuery, bindVariablesMap, AccessLevel.SYSTEM_MODE);
        Set<String> distinctRecords = new Set<String>();
        if(searchResults != NUll && !searchResults.isEmpty()){
            for(sObject sObj : searchResults){
                LookupSearchResult res = new LookupSearchResult();
                res.Id = sObj.Id;
                res.title = String.valueOf(sObj.get(field));
                if(String.isNotBlank(searchBy) && sObj.get(searchBy) != NULL){
                    res.title = String.valueOf(sObj.get(searchBy));
                }
                
                if(String.isNotBlank(subField) && sObj.get(subField) != NULL){
                    res.subtitle = String.valueOf(sObj.get(subField));
                }else{
                    res.subtitle = sObj.getSObjectType().getDescribe().getLabel();
                }
                if(lookup.lookupFx.endsWithIgnoreCase('Entitlements')){
                    res.subtitle = res.Id;
                }
                if(lookup.lookupFx.endsWithIgnoreCase('PDMs')){
                    if(!componentToProductMap.isEmpty() && !productToEntitlementMap.isEmpty()){
                        if(componentToProductMap.containsKey(res.Id)){
                            res.relatedRecordId = productToEntitlementMap.get((String)componentToProductMap.get(res.Id));
                        }
                    }
                }                
                results.add(res);
            } 
        }
        
        return results;        
    }

    /**
     * @description Retrieves a recently created record for a given SObject type and ID.
     * @param sObjectName The API name of the SObject.
     * @param recordId The ID of the record to fetch.
     * @param field The field to include in the result title.
     * @param subField The field to include in the result subtitle.
     * @return LookupSearchResult Details of the recently created record.
     */
    @AuraEnabled(cacheable=true)
    public static LookupSearchResult getRecentlyCreatedRecord(String sObjectName, String recordId, String field, String subField) {
        LookupSearchResult result = new LookupSearchResult();
        String strQuery = 'SELECT Id, '+field + (String.isNotBlank(subField) ? ' ,'+subField : '')+' FROM '+sObjectName +' WHERE Id =:recordId LIMIT 1';
        //ApexSOQLInjection False Positive, Since variables are not based on user input.
        List<sObject> searchResults = Database.query(strQuery); //NOPMD
        if(searchResults != NUll && !searchResults.isEmpty()){
            sObject sObj = searchResults.get(0);
            LookupSearchResult res = new LookupSearchResult();
            result.Id = sObj.Id;
            result.title = String.valueOf(sObj.get(field));
            if(String.isNotBlank(subField) && sObj.get(subField) != NULL){
                result.subtitle = String.valueOf(sObj.get(subField));
            }else{
                result.subtitle = sObjectName;
            }
        }
        return result;        
    }

    /**
     * @description Represents a search result for lookup queries.
     */
    public class LookupSearchResult {
        /**
        * @description Id of record
        */
        @AuraEnabled public Id id{get;set;}
        /**
        * @description title to be displayed in lookup result
        */
        @AuraEnabled public String title{get;set;}
        /**
        * @description secondary text to be displayed in lookup result
        */
        @AuraEnabled public String subtitle{get;set;}
        /**
        * @description id of related record if any with lookup result
        */
        @AuraEnabled public String relatedRecordId{get;set;}
    }
    
    /**
     * @description Represents the configuration for a lookup query.
     */
    public class Lookup {
        /**
        * @description Name of lookupFx to invoke
        */
        public String lookupFx { get; set; }
        /**
        * @description parameters sent with lookupFx
        */
        public LookupFxParam lookupFxParam { get; set; }
        
    }

    /**
     * @description Represents the parameters for a lookup query function.
     */
    public class LookupFxParam {
        /**
        * @description Field name to sort the results by.
        */
        public String sortBy { get; set; }
        /**
        * @description Field name to apply the search term on.
        */
        public String searchBy { get; set; }
        /**
        * @description The Id of a specific record used in the lookup context (e.g., for exclusions or defaulting).
        */
        public String recordId { get; set; }
        /**
        * @description The term entered by the user to filter the lookup results.
        */
        public String searchTerm { get; set; }
        /**
        * @description List of record Ids already selected in the lookup.
        */
        public List<String> selectedIds { get; set; }
        /**
        * @description API name of the sObject being queried in the lookup.
        */
        public String sObjectName { get; set; }
        /**
        * @description API name of the field to display in the lookup.
        */
        public String field { get; set; }
        /**
        * @description Maximum number of lookup results to return.
        */
        public Integer maxResults { get; set; }
        /**
        * @description API name of a sub-field to be used for additional filtering or display.
        */
        public String subField {get; set;}
        /**
        * @description Comma-separated API names of additional fields to include in the lookup results.
        */
        public String additionalFields {get; set;}
        /**
        * @description Additional key-value parameters for custom logic or filters. 
        *              Each key maps to a list of string values.
        */
        public Map<String, List<String>> additional { get; set; }
    }
}