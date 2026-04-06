/** Created By : Grazitti
* Purpose : to update contact legacy records
Last Modified : Grazitti Akash - CS-67 Jira Ticket

**/
global class BatchUpdateUsers  implements Database.Batchable<sObject>,Schedulable{
    global String theQuery = '';
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchUpdateUsers (''),20);
    }
    
    /*global BatchUpdateUsers(){
        if(!test.isRunningTest())
            theQuery = 'SELECT id,Usertype,profile.name, Name,contactId,contact.Customer_Super_User__c,contact.customer_user__c,contact.partner_user__c FROM User WHERE (Profile.UserLicense.Name=\'Partner Community\' OR Profile.UserLicense.Name=\'Customer Community\' OR Profile.UserLicense.Name=\'Customer Community Login\') and ISActive = true';
        else
            theQuery = 'SELECT id,Usertype,profile.name, Name,contactId,contact.Customer_Super_User__c,contact.customer_user__c,contact.partner_user__c FROM User WHERE (Profile.UserLicense.Name=\'Partner Community\' OR Profile.UserLicense.Name=\'Customer Community\' OR Profile.UserLicense.Name=\'Customer Community Login\') and ISActive = true limit 1';
    }*/
    
    global BatchUpdateUsers(String queryForThisBatch){
        if(queryForThisBatch!=null && queryForThisBatch!='')
            theQuery = queryForThisBatch;
        else
            theQuery = 'SELECT id,Usertype,TimeZoneSidKey,profile.name, Name,contactId,contact.user_profile__c,contact.Time_Zone__c FROM User WHERE (Profile.UserLicense.Name=\'Partner Community\' OR Profile.UserLicense.Name=\'Customer Community\' OR Profile.UserLicense.Name=\'Customer Community Login\') and ISActive = true and contactId!=null and contact.user_profile__c = null';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(theQuery);
    }
    
    global void execute(Database.BatchableContext BC,List<User> scopeList) {
        List<Contact> lstUpdate = new List<Contact>();
        for (User each: scopeList){
            if(each.profile.name != each.contact.user_profile__c){
                Contact con = new contact(Id=each.contactId);
                con.user_profile__c = each.profile.name;
                con.Time_Zone__c = each.TimeZoneSidKey;
                lstUpdate.add(con);
            }
            
        }
        UserTriggerHandler.userContactRecurrsion = true;
        if(lstUpdate !=null && !lstUpdate.isEmpty()){
            update lstUpdate;    
        }
    }
    global void finish(Database.BatchableContext BC){
        
    }    
}