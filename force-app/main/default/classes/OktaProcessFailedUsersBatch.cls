/**
* @Author      : Gaurav (partner) + Vijay Kumar K R (Customer)
* @CreatedDate : Mar 20, 2023 
* @TstClass    : 
* @Description :
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
global class OktaProcessFailedUsersBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, schedulable {

    global Database.QueryLocator start(Database.BatchableContext bc){
        
        // Users Fields from Mtd
        Set<String> userFieldSet = new Set<String>();
        for(SF_Okta_Field_Mapping__mdt objMtd : [SELECT SF_Field_API_Name__c, Okta_Field_API_Name__c 
                                                 FROM SF_Okta_Field_Mapping__mdt]){
                                                     userFieldSet.add(objMtd.SF_Field_API_Name__c);
        }

        // UserType Filter String
        String portalProfileFilter = 'UserType = \'CspLitePortal\' OR UserType = \'PowerPartner\'';
        // Query String
        String userQueryString = 'SELECT Okta_UserId__c, API_Status__c, UserType, '+ String.escapeSingleQuotes(String.join(new List<String>(userFieldSet), ', ')) + ' FROM ';
        userQueryString += 'User WHERE ('+portalProfileFilter+') AND (API_Status__c != \''+'Success'+'\' AND API_Status__c != null)'+(Test.isRunningTest()?' LIMIT 200':'') ;
        
        return Database.getQueryLocator(userQueryString);
    }
    
    global void execute(Database.BatchableContext bc, List<User> failedUsersList){
        OktaUserFailureSync.processFailedUserRecords(failedUsersList);
    }

    global void finish(Database.BatchableContext bc){
    }
    global void execute (SchedulableContext sc){
        database.executebatch(new OktaProcessFailedUsersBatch());
    }
}