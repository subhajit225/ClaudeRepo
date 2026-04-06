/**
* @Author      : Vijay Kumar K R
* @CreatedDate : Apr 20, 2023 
* @TstClass    : OktaUserMigrationCsvBatchableTest
* @Description : After SF Portal User migrated into Okta, This batch is used to Update Okta_UserId & API_Status__c on Migrated SF User records based on Email.
* @execute     : database.executebatch(new OktaUserMigrationCsvBatchable(), 1000);
* -------------------------- @History -------------------------------------
* Story Number       Modified By              Date           Description
* 
* -------------------------------------------------------------------------
*/
global with sharing class OktaUserMigrationCsvBatchable implements Database.batchable<String>, Database.Stateful{
   
    global Iterable<String> start(Database.batchableContext batchableContext){ 
        Document objDoc = [SELECT Id, Body FROM Document WHERE DeveloperName = 'Okta_users'];
        String stringBody = objDoc.Body.tostring();
        return new CSVIterator(stringBody, '\r\n');
    }

    global void execute(Database.BatchableContext batchableContext, List<String> scope)  {

        try {
            Map<String, String> oktaUserIdByEmailMap = new Map<String, String>();
            for (Integer i=1; i<scope.size(); i++)
            {
                list<String> columnValues = new list<String>();
                columnValues = scope[i].split(',');
                System.debug('columnValues: '+columnValues);
                String Email = columnValues[0];
                if(Email.containsIgnoreCase('@')){
                    oktaUserIdByEmailMap.put(Email, columnValues[1]);
                }
            }
            System.debug('oktaUserIdByEmailMap: '+oktaUserIdByEmailMap);

            Map<Id, User> userUpdateMap = new Map<Id, User>();
            if(!oktaUserIdByEmailMap.isEmpty()){
                for(User objUser : [SELECT Id, Name, Email, Okta_UserId__c
                                    FROM User 
                                    WHERE Email IN: oktaUserIdByEmailMap.keySet()
                                    AND Okta_UserId__c = null
                                    AND API_Status__c != 'Success']){
                    if(oktaUserIdByEmailMap.containsKey(objUser.Email)){
                        String oktaUserId = oktaUserIdByEmailMap.get(objUser.Email);
                        objUser.Okta_UserId__c = oktaUserId;
                        objUser.API_Status__c = 'Success';   
                        userUpdateMap.put(objUser.Id, objUser);
                    }
                }
            }

            System.debug('userUpdateMap: '+userUpdateMap);
            if(!userUpdateMap.isEmpty()){
                List<Database.SaveResult> results = Database.update(userUpdateMap.values(), false);
                Map<Id, User> userStateUpdateMap = new Map<Id, User>();
                for (Database.SaveResult result : results) {
                    if (!result.isSuccess()){
                        for (Database.Error err : result.getErrors()){
                            System.debug('errId: '+ result.getId()+' Error: '+ err.getStatusCode() + ' ' + err.getMessage());
                            String errMsg = err.getMessage();
                            if(errMsg.containsIgnoreCase('Please select a state from the list of valid states')
                                || errMsg.containsIgnoreCase('doesn\'t recognize the state value for field')){
                                    System.debug('Update err User rec: '+ result.getId());
                                    userStateUpdateMap.put(result.getId(), new User(Id = result.getId(), StateCode = 'None', State = 'None'));
                            }
                        }
                    }
                }

                System.debug('userStateUpdateMap: '+userStateUpdateMap);
                // Update failed Users
                if(!userStateUpdateMap.isEmpty()){
                    userStateUpdateMap.values();
                }
            }

        } catch (Exception e) {
            System.debug('Message: '+e.getMessage()+' LineNumber: '+e.getLineNumber());
        }
        
   }

   global void finish(Database.BatchableContext batchableContext){
    
   }
}