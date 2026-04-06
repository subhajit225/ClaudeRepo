/**
 * @Author      : Vijay Kumar K R
 * @CreatedDate : Aug 1, 2022 
 * @TstClass    : DynamicLookupControllerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-1206          Vijay Kumar K R          Aug 1, 2022    Replace "Support Tunnel number" with "Cluster UUID" picklist on Support Portal case submission form
 * -------------------------------------------------------------------------
 */
public without sharing class DynamicLookupController {

    public static final String ORDER_RECORDS = 'Order By CreatedDate DESC';

    // Method to fetch lookup search result   
    @AuraEnabled(cacheable=true)
    public static List<sObject> fetchLookupData(String fields, String searchKey, String sObjectApiName, String filter, String addonsearchfield) {   
        
        try {
            // records by filter and search keyword
            if(String.isNotBlank(filter)){
                return fetchFilteredRecords(fields, searchKey, sObjectApiName, filter, addonsearchfield);
            }
            // records by search keyword
            else if(String.isNotBlank(searchKey)){
                return fetchSearchedRecords(fields, searchKey, sObjectApiName, addonsearchfield);
            }
            // get default records
            else{
                return fetchDefaultRecords(fields, sObjectApiName);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    /**
     * Method: fetchFilteredRecords 
     * params: String fields, String searchKey, String sObjectApiName, String filter
     * return: List<sObject>
     **/
    public static List<sObject> fetchFilteredRecords(String fields, String searchKey, String sObjectApiName, String filter, String addonsearchfield) {
        User loggedInUser = [ SELECT Id, Name, AccountId, UserType FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Boolean isPortalUser = loggedInUser.UserType == 'CspLitePortal'; 
        String portalUserAccountId = loggedInUser.AccountId;    

        String sWildCardText = 'Name Like \'%'+searchKey+'%\'';
        if(String.isNotBlank(addonsearchfield)){
             sWildCardText = '(Name Like \'%'+searchKey+'%\'';
            if(addonsearchfield.contains(';')){
                List<String> multipleFields = addonsearchfield.split(';');
                for(String field : multipleFields){
                     sWildCardText += ' OR '+field+' Like \'%'+searchKey+'%\'';
                }
                sWildCardText += ')';
            }else{
                sWildCardText += ' OR '+addonsearchfield+' Like \'%'+searchKey+'%\')';
            }
           
        }
        if(isPortalUser && sObjectApiName == 'RSCInstance__c'){
            Set<String> allowedStatuses = new Set<String>{'ACTIVE','GRACE','PENDING_CREATION','SUSPENDED','MARKED_FOR_DELETION'};
            filter = '(AccountId__c = \''+portalUserAccountId+'\' OR SDPEndUser__c = \''+portalUserAccountId+'\') AND Status__c IN :allowedStatuses';
        } else if (isPortalUser && sObjectApiName == 'Cluster__c'){
            filter = 'Account__c = \''+portalUserAccountId+'\' AND Archived__c = false';
        }
        String query = 'SELECT {0} FROM {1} WHERE {2} AND {3} {4}';
        query = String.format(query, new List<String>{
                                            fields,
                                            sObjectApiName,
                                            sWildCardText,
                                            filter,
                                            ORDER_RECORDS
                                        });
        return Database.query(query);
    }

    /**
     * Method: fetchSearchedRecords 
     * params: String fields, String searchKey, String sObjectApiName
     * return: List<sObject>
     **/
    public static List<sObject> fetchSearchedRecords(String fields, String searchKey, String sObjectApiName, String addonsearchfield) {
        String sWildCardText = 'Name Like \'%'+searchKey+'%\'';
        if(String.isNotBlank(addonsearchfield)){
            sWildCardText = '(Name Like \'%'+searchKey+'%\' OR '+addonsearchfield+' Like \'%'+searchKey+'%\')';
        }
        String query = 'SELECT {0} FROM {1} WHERE {2} {3}';
        query = String.format(query, new List<String>{
                                            fields,
                                            sObjectApiName,
                                            sWildCardText,
                                            ORDER_RECORDS
                                        });
        return Database.query(query);
    }

    /**
     * Method: fetchDefaultRecords 
     * params: String fields, String sObjectApiName
     * return: List<sObject>
     **/
    public static List<sObject> fetchDefaultRecords(String fields, String sObjectApiName) {
        String query = 'SELECT {0} FROM {1} {2} Limit 100';
        query = String.format(query, new List<String>{
                                            fields,
                                            sObjectApiName,
                                            ORDER_RECORDS
                                        });
        return Database.query(query);
    }
    
    /**
     * Method: fetchDefaultRecord : Method to fetch lookup default value by recordId
     * params: String recordId , String sObjectApiName
     * return: sObject
     **/
    @AuraEnabled
    public static sObject fetchRecordById(String recordId , String sObjectApiName) {
         
        String fields = 'Id, Name';
        String filter = 'Id = \''+recordId+'\' LIMIT 1';

        try {
            String query = 'SELECT {0} FROM {1} WHERE {2}';
            query = String.format(query, new List<String>{
                                                fields,
                                                sObjectApiName,
                                                filter
                                            });
            return Database.query(query);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}