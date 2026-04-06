/**
* @description This Apex class serves as a centralized helper and controller for Lightning Components,
* providing reusable methods and logic to streamline component functionality and promote modular development.
*/
public with sharing class LCC_JSMQueryResultService {
    /**
     * @description This method runs the query passed and returns the List of sObject records for the query
     * @param theQuery
     * @return List<sObject>
     */
    @AuraEnabled (cacheable =true)
    public static List<sObject> executeQuery(String theQuery){
        try{
            //We do not escape  parameters here since the query must not be modified.
            //Parameters must be escaped by consumers of this method
            return Database.query(theQuery);
        }catch(Exception e){
            throw new AuraHandledException('Error doing the query: '+theQuery+' Error: '+e.getMessage());
        }
    }

    /**
     * @description Created non cache version to prevent multiple submission on submit for approval
     * @param theQuery
     * @return List<sObject>
     * Story : FY26WL-230
     */
    @AuraEnabled
    public static List<sObject> executeQueryNew(String theQuery){
        try{
            return Database.query(theQuery);
        }catch(Exception e){
            throw new AuraHandledException('Error doing the query: '+theQuery+' Error: '+e.getMessage());
        }
    }
   /* @AuraEnabled (cacheable =true)
    public static List<sObject> executeQueryCacheable(String theQuery){
        try{
            //We do not escape  parameters here since the query must not be modified.
            //Parameters must be escaped by consumers of this method
            //String field1 = '\'' + String.escapeSingleQuotes(theQuery) + '\'';
            //return Database.query(field1);
            return Database.query(theQuery);
        }catch(Exception e){
            throw new AuraHandledException('Error doing the query: '+theQuery+' Error: '+e.getMessage());
        }
    }*/

    /**
     * @description This Method executes the query for to get the sobject data for the respective Query Map passed to the method
     * @param theQuery
     * @return Map<string, List<sObject>>
     */
    @AuraEnabled
    public static Map<string, List<sObject>>  executeAllQuery(Map<string, String> theQuery){
        try{
            system.debug(logginglevel.DEBUG,'theQuery is ##### ' + theQuery);
            Map<string, List<sObject>> response = new Map<string, List<sObject>>();
            //We do not escape  parameters here since the query must not be modified.
            //Parameters must be escaped by consumers of this method
            for(string key: theQuery.keyset()){
                if(theQuery.get(key) != null && theQuery.get(key) != ''){
                    response.put(key, Database.query(theQuery.get(key)));
                }
            }
            system.debug(logginglevel.DEBUG,'response is ' + response);
            return response;
        }catch(Exception e){
            throw new AuraHandledException('Error doing the query: '+theQuery+' Error: '+e.getMessage());
        }
    }
    /**
     * @description This Method runs the query passed and returns the sObject response(single record)
     * @param theQuery
     * @return sObject
     */
    @AuraEnabled
    public static sObject executeQueryOneObject(String theQuery){
        try{
            //We do not escape  parameters here since the query must not be modified.
            //Parameters must be escaped by consumers of this method
            return Database.query(theQuery);
        }catch(Exception e){
            throw new AuraHandledException('Error doing the query: '+theQuery+' Error: '+e.getMessage());
        }
    }

    /**
     * @description This Method is used to get the user Info for the logged in user.
     * @return LCC_JSMUserInfo
     */
    @AuraEnabled
    public static LCC_JSMUserInfo getUserInfo(){
        try{
            LCC_JSMUserInfo info = new LCC_JSMUserInfo();
            info.Id = Userinfo.getUserId();
            info.FirstName = Userinfo.getFirstName();
            info.LastName = Userinfo.getLastName();
            info.UserEmail = Userinfo.getUserEmail();
            info.Name = Userinfo.getName();
            info.UserName = Userinfo.getUserName();
            return info;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description This Method is used to get the profile details for the Logged In user
     * @return Profile
     */
    @AuraEnabled
    public static Profile getProfileInfo(){
        try{
            String profileId = UserInfo.getProfileId();
            Profile profile = [SELECT Id, Name FROM Profile WHERE Id =:profileId];
            return profile;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description This Method is used to get the site deatils.
     * @return LCC_JSMSiteInfo
     */
    @AuraEnabled
    public static LCC_JSMSiteInfo getSiteInfo(){
        try{
            LCC_JSMSiteInfo info = new LCC_JSMSiteInfo();
            info.Prefix = Site.getPathPrefix();
            info.Domain = Site.getDomain();
            info.Name = Site.getName();
            return info;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description This Method returns the sObject record for the Id passed to it
     * @param recordId
     * @return sObject
     */
    @AuraEnabled
    public static sObject loadObjectInfoById(Id recordId) {

        DescribeSObjectResult objectType = recordId.getSobjectType().getDescribe();
        List<String> objectFields = new List<String>(objectType.fields.getMap().keySet());

        String query = 'SELECT ' + String.join(objectFields, ',') + ' FROM ' + objectType.getName() + ' WHERE Id = \'' + String.escapeSingleQuotes(recordId) + '\' LIMIT 1';

        return executeQueryOneObject(query);
    }

    /**
     * @description This Method gets the data from the report for the report Id passed as the parameter.
     * @param  reportDeveloperName
     * @return String
     * @ticket : PRDOPS26-313
     */
    @AuraEnabled(cacheable=true)
    public static String getReportData(String reportDeveloperName) {
        try {
            Report reportRec = [SELECT Id FROM Report WHERE DeveloperName =: reportDeveloperName];
            return JSON.serialize(Reports.ReportManager.runReport(reportRec.Id, true));
        } catch (Exception e) {
            return null;
        }
    }

     /**
     * @description This Method gets the object prefixes for all the exiting objects in the org
     * @return Map<String, String>
     * @ticket : PRDOPS26-313
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getObjectPrefixes() {
        Map<String, String> prefixMap = new Map<String, String>();
        for (Schema.SObjectType objType : Schema.getGlobalDescribe().values()) {
            Schema.DescribeSObjectResult describe = objType.getDescribe();
            String prefix = describe.getKeyPrefix();
            if (prefix != null) {
                prefixMap.put(prefix, describe.getName());
            }
        }
        return prefixMap;
    }
    /***********************************************************************************************************
    * Method Name          : getBusinessLogicSetting
    * Date Created/Modified: 09/07/2025
    * @description         : FYSR25-1460 returns custom setting
    * @return              : Map<String, Boolean>
    * Test Class           :
    /**********************************************************************************************************/
    @AuraEnabled (cacheable =true)
    public static Map<String, Boolean> getBusinessLogicSetting() {
        // For hierarchy custom setting:
        Map<String, Boolean> mapUserSetting = new Map<String, Boolean>();
        ShGl_DisableBusinessLogic__c userSetting = ReplacementQueryController.fetchBusinessLogicSetting();
        if (userSetting != null) {
            mapUserSetting.put('Replacement', userSetting.Disable_Replacement_Framework__c);
            mapUserSetting.put('OpportunityValidation', userSetting.Disable_Opportunity_Validation_Rules__c);
        }else{
            mapUserSetting.put('Replacement', false);
            mapUserSetting.put('OpportunityValidation', false);
        }
        return mapUserSetting;
    }
    /**
     * @description : This method is used to update the shipped order
     * @param rec
     * @return String
     */
    @AuraEnabled
    public static string saveShippedOrder(sobject rec){
        string message = '';
        try{
            OrderHandler.bypassShippedOrderValidation = true;
        	update rec;
            OrderHandler.bypassShippedOrderValidation = false;

        }catch(Exception e){
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                message = 'Exception occurred : '+e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
            } else {
                message = 'Exception occurred : '+e.getMessage();
            }
        }
        return message;
    }

    /**
    * @author Shrutika
    * @description This method is used to update the shipped order
    * @param rec
    * @param objectAPIName
    * @return String
    */
    @AuraEnabled
    public static string saveRecordwithBypass(sobject rec,String objectAPIName){
        string message = '';
        try{
            if(objectAPIName == 'Entitlement'){
                EntitlementTriggerHandler.bypassRecordEditValidation = true;
                update rec;
                EntitlementTriggerHandler.bypassRecordEditValidation = false;
            }
            else if(objectAPIName == 'Order'){
                message = saveShippedOrder(rec);
            }
            else{
                update rec;
            }
        }catch(Exception e){
            if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                message = 'Exception occurred : '+e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
            } else {
                message = 'Exception occurred : '+e.getMessage();
            }
        }
        return message;
    }

    /**
    * @author Shrutika
    * @description This method is used to get the fields for Generic Record Edit From LWC for User RBAC
    * @param parentRecId
    * @return String
    */
    @AuraEnabled(cacheable=true)
    public static String getAccessibleFields(String parentRecId){
        FieldsWrapper fieldsWrapper = new FieldsWrapper();
        try{
            User currentUser = [SELECT Id, User_Type__c, RBAC_Group__c, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            if(String.isNotBlank(currentUser.RBAC_Group__c)){
                fieldsWrapper.isUserGroupValid = true;
                Id recordId = Id.valueOf(parentRecId);   
                fieldsWrapper.objAPIName = getSobjAPIName(recordId);
                fieldsWrapper.fieldAPINames = getSobjFields(fieldsWrapper.objAPIName,currentUser.RBAC_Group__c);
            }
            else{
            	fieldsWrapper.isUserGroupValid = false;    
            }
        }
        catch(Exception exp){
        	throw new AuraHandledException(exp.getMessage());    
        }
    	return JSON.serialize(fieldsWrapper);    
        
    }
    
    private static String getSobjAPIName(Id recordId){
        return recordId.getSobjectType().getDescribe().getName();
    }

    private static List<String> getSobjFields(String sObjAPIName,String rbacGroup){
        RBAC_Group_Access_Management__mdt objAccess = [SELECT Id,Accessible_Field_API_Names__c FROM RBAC_Group_Access_Management__mdt WHERE Object_API_Name__c = :sObjAPIName AND RBAC_Group__c IN: rbacGroup.split(';')];
        List<String> accessibleFields = objAccess.Accessible_Field_API_Names__c.split(',');
        return accessibleFields;
    }
    /***********************************************************************************************************
    * Method Name          : FieldsWrapper
    * Date Created/Modified: 20-Nov-2025
    * @author              : Shrutika
    * @description         : This wrapper class for genericRecordEditForm LWC
    /**********************************************************************************************************/
    public class FieldsWrapper{
        @AuraEnabled
        public Boolean isUserGroupValid;
        @AuraEnabled
        public String objAPIName;
        @AuraEnabled
        public List<String> fieldAPINames;
    }

    /**
     * @description This method is used to set the Ordered Checkbox
     * @param rec
     * @param lineCount
     * @return String
     */
    @AuraEnabled
    public static String triggerOrderCreation(sObject rec, Integer lineCount) {
        String message = '';

        try {
            Opportunity opp = (Opportunity) rec;

            if (lineCount >= 200) {
                System.enqueueJob( new OpportunityBulkUpdateQueueable(new List<Opportunity>{ opp }) );
            } else {
                update opp;
            }

        } catch (Exception e) {
            if (e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                message = 'Exception occurred : ' + e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []');
            } else {
                message = 'Exception occurred : ' + e.getMessage();
            }
        }

        return message;
    }
}