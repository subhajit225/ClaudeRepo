/**
* @Author      : Rubrik
* @CreatedDate : Aug 02, 2019 
* @Handler     : UserTriggerHandler
* @TstClass    : UserTriggerHandler_Test
* @Description :
* -------------------------- @History ---------------------------------------------------------------------
* Story Number       Modified By              Date           Description
* CS21-1478          Vijay Kumar K R          June 23, 2022  CIAM: SF Portal Users to Okta Integration
* ---------------------------------------------------------------------------------------------------------
*/

trigger UserTrigger on User (before insert,after Insert,before update,after update) {

    if(flowControll.UserTriggerHandler && TriggerControl__c.getAll() != null && TriggerControl__c.getAll().containsKey('User') && !TriggerControl__c.getInstance('User').DisableTrigger__c){
        
        if(trigger.isAfter && trigger.isInsert){
            //UserTriggerHandler.setchannelMapping(trigger.new);
            UserTriggerHandler.updateContact(trigger.new,null);
            UserTriggerHandler.createSalesEnablementRecords(trigger.newMap, null);
            UserTriggerHandler.disableFeedStandardEmail(trigger.newMap);
            UserTriggerHandler.assignWelcomeBadge(trigger.new);
            // Chekbox to Stop User Sync into Okta
            if(Okta_Attributes__c.getInstance('Okta Attributes').get('Disable_User_Sync__c') != null
                && !Boolean.valueOf(Okta_Attributes__c.getInstance('Okta Attributes').get('Disable_User_Sync__c'))){
                UserTriggerHandler.oktaUserCreation(trigger.new, Trigger.isInsert);
            }
            //UserTriggerHandler.assignPermissionSetgroup(trigger.new,null); //SAL23-597
            UserTriggerHandler.updatePartnerRegRequest(trigger.newMap,null);
        }
        if(trigger.isBefore && trigger.isInsert){
            //Added by Ashish to restrict the Rubrik employees from creating Support Portal Community users CS21-627
            UserTriggerHandler.showErrorOnSupportPortalUserCreation(trigger.new,new Map<Id,User>(),false,true);
            UserTriggerHandler.setAuthorizeUser(trigger.new);
            UserTriggerHandler.setPOCApprover(trigger.new,null);
            //<Additions By: Anmol Baweja 27Feb, 2020 CS-582 start>
            //<Reason>
            //To restrict any community user creation which contains email domains like gmail.com,icloud.com, yahoo.com etc. as per CS-582
            //</Reason>
            UserTriggerHandler.UsersWithIgnoredDomains(trigger.new, null);
            //</Additions By: Anmol Baweja CS-582 end>
            //UserTriggerHandler.setDefaultUserRole(trigger.new);
            //Additions By: Shiva Sharma CS21-63
            UserTriggerHandler.setNoAccessProfile(trigger.new);
            UserTriggerHandler.updateReleases(trigger.new); //CS21-493
        UserTriggerHandler.setSupportPortalUsername(trigger.new); //CS21-1720
        }

        if(trigger.isBefore && trigger.isUpdate){
            
            UserTriggerHandler.removeInactiveUserFromTerritory(trigger.new,trigger.oldMap);
            //<Additions By: Anmol Baweja 27Feb, 2020 CS-582 start>
            //<Reason>
            //To restrict any community user updation which contains email domains like gmail.com,icloud.com, yahoo.com etc. as per CS-582
            //</Reason>
            UserTriggerHandler.UsersWithIgnoredDomains(trigger.new, trigger.oldMap);
            //</Additions By: Anmol Baweja CS-582 end>
            UserTriggerHandler.setPOCApprover(trigger.new,trigger.oldMap);
        }
        if(trigger.isAfter && trigger.isUpdate){
            UserTriggerHandler.showErrorOnSupportPortalUserCreation(trigger.new,trigger.oldMap,true,false);
            // Chekbox to Stop User Sync into Okta
            if(Okta_Attributes__c.getInstance('Okta Attributes').get('Disable_User_Sync__c') != null
                && !Boolean.valueOf(Okta_Attributes__c.getInstance('Okta Attributes').get('Disable_User_Sync__c'))){
                UserTriggerHandler.oktaUserCreation(trigger.new, Trigger.isInsert);
            }
            UserTriggerHandler.updateContact(trigger.new,trigger.oldMap);
            UserTriggerHandler.createSalesEnablementRecords(trigger.newMap, trigger.oldMap);
            //SAL-1341
            UserTriggerHandler.removeInactiveUserFromAccountTeams(trigger.new,trigger.oldMap);
            //freeze user when termination date is added by workday
            UserTriggerHandler.freezeTerminatedUsers(trigger.new,trigger.oldMap);
            UserTriggerHandler.deleteAllSubscriptions(trigger.newMap,trigger.oldMap);
            UserTriggerHandler.removalofPOCApprover(trigger.new,trigger.oldMap);
            UserTriggerHandler.createUserHistory(trigger.new,trigger.oldMap);   //CS21-1189
            //UserTriggerHandler.assignPermissionSetgroup(trigger.new,trigger.oldMap); //SAL23-597
            //Disable feed email on user update
            UserTriggerHandler.disableFeedStandardEmail(trigger.newMap);

            //PRIT24 - 393 - sidhant.jain@rubrik.com
            UserTriggerHandler.sendInactiveFMMEmail(trigger.newMap, trigger.oldMap);
            
            //PRIT24 - 437 - Create Admin PR Request
            UserTriggerHandler.createAdminAccessReq(trigger.newMap, trigger.oldMap);
            UserTriggerHandler.updatePartnerRegRequest(trigger.newMap,trigger.oldMap);
        }
    }
}