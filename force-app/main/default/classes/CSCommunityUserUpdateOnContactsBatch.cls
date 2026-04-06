/**
* @description Batch Job to update Community User on Contacts.
*  - JIRA - CS21-788
*
* @CreatedDate 12th Jan 2022
* @Created By Veera Gandi
* 
* @Test Class CSCommunityUserUpdateOnContactsBatchTest
*/
public class CSCommunityUserUpdateOnContactsBatch implements Database.Batchable<sObject>{
    public String query;
    
    /**
     * @description Constructor to get batch job query to be executed in start method.
     * @param query - eg: SELECT Id, ContactId FROM User WHERE ContactId != null
     */
    public CSCommunityUserUpdateOnContactsBatch(string query){       
        this.query = query;
    }
    
    /**
     * @description start method runs at the beginning of a batch Apex job which collects the records or objects to pass to the execute method. 
     * @param batchableContext - Database.BatchableContext
     * @return Database.QueryLocator - List of Users
     */
    public Database.QueryLocator start(Database.BatchableContext batchableContext){
        return Database.getQueryLocator(query);
    }
    
    /**
    * @description execute method is called for each batch of records that you pass to it
    * @param  batchableContext - Database.BatchableContext
    * @param  users - List of Users
    */
    public void execute(Database.BatchableContext batchableContext, List<User> users){
        Map<Id, Contact> contactUpdateMap = new Map<Id, Contact>();
        
        Set<Id> contIdSet = new Set<Id>();
        for (User eachUser : users) {
            if (eachUser.ContactId != null) {
                contIdSet.add(eachUser.ContactId);
            }
        } 

        Map<Id, Contact> contMap = new Map<Id, Contact>();
        if(!contIdSet.isEmpty()){
            contMap = new Map<Id, Contact>([SELECT Id, CommunityUser__c FROM Contact WHERE Id IN: contIdSet AND CommunityUser__c = null]);
        }

        for (User eachUser : users) {
            if (eachUser.ContactId != null
                && contMap.containsKey(eachUser.ContactId)) {
                    Contact newContact = new Contact();
                    newContact.Id = eachUser.ContactId;
                    newContact.CommunityUser__c = eachUser.Id;
                    contactUpdateMap.put(eachUser.ContactId, newContact);
            }
        } 

        
        //update contacts
        if (!contactUpdateMap.isEmpty()) {
            List<Database.SaveResult> saveResults = Database.Update(contactUpdateMap.values(), false);
            
            for (Database.SaveResult result : saveResults) {
                if (!result.isSuccess()) {
                    System.debug(LoggingLevel.WARN,'Error Occured ::' + JSON.serialize(result.getErrors()));
                }
            }
        }
    }
    
    /**
     * @description finish is to execute post-processing operations
     * @param  batchableContext - Database.BatchableContext
     */
    public void finish(Database.BatchableContext batchableContext){
        System.debug(LoggingLevel.DEBUG, 'Contacts are updated successfully.');
    }
}