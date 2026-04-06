/**
* @author Sushant Arora
* @date 2024-01-31
* @description Controller to cS_CaseSpecailHandlingAccordianLWC
* @TestClass - CS_CaseSpecialHandlingControllerTest
*/
@SuppressWarnings('PMD.ApexSOQLInjection,PMD.ApexCRUDViolation')
public with sharing class CS_CaseSpecialHandlingController {
    /**
* @description Custom exception class for handling errors in the CS_CaseSpecialHandlingController.
*/
    public class CS_CaseSpecialHandlingControllerException extends Exception {}
    
    /**
* @description Retrieves a list of Case_Special_Handling__c records associated with a given Case record.
* @param recordId The ID of the Case record to retrieve the associated Account ID.
* @param queryLimit The maximum number of records to return. If null, no limit is applied.
* @param filter Additional filter criteria to apply to the query. If null, no additional filter is applied.
* @return List<Case_Special_Handling__c> A list of Case_Special_Handling__c records that match the criteria.
* @throws CS_CaseSpecialHandlingControllerException If an error occurs during the query execution.
*/
    @AuraEnabled(cacheable=true)
    public static List<Case_Special_Handling__c> getRecords(String recordId, String queryLimit, String filter) {
        try {
            List<Case_Special_Handling__c> specialHandlingObjects = new List<Case_Special_Handling__c>();
            
            // Retrieve Account ID associated with the Case record
            List<Case> caseRec = [SELECT AccountId,RecordType.DeveloperName FROM Case WHERE Id = :recordId];
			Id accountId = caseRec[0]?.AccountId;
            
            String query = 'SELECT Icon__c, Category__c, Message__c, Account_Id__c, Show_Banner__c ' +
                'FROM Case_Special_Handling__c ' +
                'WHERE Account_Id__c = :accountId AND Is_Archived__c = false';
                
            if(caseRec[0]?.RecordType.DeveloperName != 'Support_Case'){
                query += ' AND Top_Account__c = false' ;
            }
            
            // Add filter condition if provided
            if (filter != null) {
                String newFilter = ' AND  ' + String.escapeSingleQuotes(filter);
                query += newFilter;
            }
            
            // Add query limit if provided
            if (queryLimit != null) {
                Integer limitValue = Integer.valueOf(queryLimit); // Convert string to integer
                query += ' LIMIT :limitValue';
            }
            
            // Execute the query with parameter binding
            specialHandlingObjects = Database.query(query);
            
            return specialHandlingObjects;
        } catch (Exception e) {
            throw new CS_CaseSpecialHandlingControllerException(e);
        }
    }
    
    /**
* @description Updates the Manual_Review_Requested_On__c date field to the current date for a specified Case_Special_Handling__c record. 
* @param recordId The ID of the Case_Special_Handling__c record to update.
* @return String A success message if the update is successful, or an error message if an exception occurs.
*/
    @AuraEnabled
    public static String updateDateField(String recordId) {
        try {
            if(Schema.getGlobalDescribe().get('Case_Special_Handling__c').getDescribe().isUpdateable()){
                update new Case_Special_Handling__c(Id = recordId, Manual_Review_Requested_On__c = Date.today());
            }
            else{
                return 'You have insufficient access to update the record';
            }
            return 'Success: Manual Review Requested Successfully.';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        }
    }
    /**
* @description Checks if the current user has access to a specified Salesforce object.
* @param objectName The API name of the object to check access for.
* @return Boolean True if the user has access to the object, false otherwise.
*/
    @AuraEnabled(cacheable=true)
    public static Boolean checkObjectAccess(String objectName) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType == null) {
            return false;
        }
        return objType.getDescribe().isAccessible();
    }
}