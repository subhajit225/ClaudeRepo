public class ETMContactOwnerChangeBatch implements Database.Batchable<sObject>,Database.Stateful {
    public set<Id> failedAccIds = new set<Id>();
    public string CLASS_NAME = 'ETMContactOwnerChangeBatch';
    public string ERROR_FUNCTIONALITY = 'ETM';
    private Map<string,Custom_Error_Log__c> errorLogs = new Map<string,Custom_Error_Log__c>();
    private static final string Contact_UPDATE_ERROR = 'Contact Update Failed';
    private boolean enableLogging,disable_ContactOwnerUpdate,disable_OppOwnerUpdate ;
    private integer totalNumExec;
    private static Id accRecTypeIdCustomerProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId(); //SAL24-14
    public ETMContactOwnerChangeBatch(set<Id> failedAccIds,boolean enableLogging , boolean disable_ContactOwnerUpdate,boolean disable_OppOwnerUpdate,Integer totalNumExec){
         this.failedAccIds = failedAccIds;
         this.enableLogging = enableLogging;
         this.disable_OppOwnerUpdate=disable_OppOwnerUpdate;
         this.disable_ContactOwnerUpdate=disable_ContactOwnerUpdate;
         this.totalNumExec = totalNumExec;
         system.debug('ETM Contact failedAccIds'+failedAccIds);
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {
        string query;
        try{
            if(disable_ContactOwnerUpdate)
            query ='select id from contact limit 0';
            else
            //SAL24-14 
            //query = 'select Id,OwnerId,Account.OwnerId from Contact where accountid NOT IN : failedAccIds AND Sync_Owner_With_Territory__c=true';
            query = 'select Id,OwnerId,Account.OwnerId,Account.RecordTypeId,Account.Account_Status__c,Account.ETM_SDR__c,Account.ETM_Area__c,MQL__c from Contact where accountId NOT IN : failedAccIds AND Sync_Owner_With_Territory__c=true';
            system.debug('query '+query);
            return Database.getQueryLocator(query);
        }catch(exception e){
            insert LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY);
        }
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC,List<Contact> ContactList){
        try{
            List<Contact> updatedContactList = new List<Contact>();
            Map<Id, Contact> oldContactMap = new Map<Id, Contact>([SELECT Id,ownerId FROM Contact WHERE Id IN :ContactList]); //SAL24-14
            Integer i =0;
            system.debug('@@ ContactList '+ContactList);
            system.debug('@@ ContactList size '+ContactList.size());
            for(Contact con : ContactList) {
                //SAL24-14 Contact Routing
                con.OwnerId = con.Account.RecordTypeId != accRecTypeIdCustomerProspect ? /* If account is partner/distributor then account owner */
                                con.Account.OwnerId : 
                                (con.Account.Account_Status__c == 'Active Opportunity' || con.Account.Account_Status__c == 'Existing Customer') ? /* If account status 'Active Opportunity/Existing Customer' then account owner */
                                    con.Account.OwnerId :
                                    con.Account.ETM_Area__c != null && con.Account.ETM_Area__c.startsWith('MM-') ? /* If account status 'Lost Opportunity/Prospect' and ETM Area starts with MM- then account owner */
                                        con.Account.OwnerId :
                                        con.Account.ETM_SDR__c == null ? 
                                            con.Account.OwnerId : /* If account status 'Lost Opportunity/Prospect' and ETM Area not 'MM-' and SDR not exists in ETM territory then account owner */
                                            con.Account.ETM_SDR__c; /* If account status 'Lost Opportunity/Prospect' and ETM Area not 'MM-' and SDR exists in ETM territory then SDR */
                
                Contact oldContact = oldContactMap.get(con.Id);
                if(Test.isRunningTest() || con.ownerId != oldContact.ownerId){
                    updatedContactList.add(con);
                }
                //End
            }
            system.debug('@@updatedContactList '+updatedContactList);
            if(!updatedContactList.isEmpty()) {
                for (Database.SaveResult sr : database.update(updatedContactList, false)) {
                    if (!sr.isSuccess()) {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Contact update failed-->'+err.getMessage());
                            if(!errorLogs.isEmpty() && errorLogs.containskey(err.getMessage())){ 
                                if(errorLogs.get(err.getMessage()).FailedRecords__c.length() < 237)
                                    errorLogs.get(err.getMessage()).FailedRecords__c += ','+updatedContactList[i].Id;              
                            }
                            else{
                                  errorLogs.put(err.getMessage(),new Custom_Error_Log__c(Functionality__c = ERROR_FUNCTIONALITY, Exception_Message__c = (err.getMessage()+':'+err.getFields()),Class__c = CLASS_NAME,FailedRecords__c=updatedContactList[i].Id));
                            }
                        }
                    }
                    i++;
                }
            }
        }catch(exception e){
            if(errorLogs.isEmpty() || !errorLogs.containskey(e.getMessage())){
                                  errorLogs.put(e.getMessage(),LogError.CreateGenericErrorLog(CLASS_NAME,e,ERROR_FUNCTIONALITY));
                            }
        }
    }
    public void finish(Database.BatchableContext BC) {
        if(!errorLogs.values().isEmpty() && enableLogging){
        database.insert(errorLogs.values(),false);
        }
        //SAL24-735 
        Integer oppBatchSize = 50;
        List<Territory_Management_Setup__mdt> fielSalesMdtBatchSize = [select Field_Value__c,Field_Type__c,Operator__c from Territory_Management_Setup__mdt where DeveloperName='ETM_Opportunity_Batch_Size'];
        if(!fielSalesMdtBatchSize.isEmpty() && fielSalesMdtBatchSize[0].Field_Value__c!=null){
            oppBatchSize = Integer.valueOf(fielSalesMdtBatchSize[0].Field_Value__c);
        }
        // update opp owner 
        //if(!disable_OppOwnerUpdate){}
        Database.executeBatch(new ETMUpdateOppOwner(failedAccIds,enableLogging,totalNumExec,disable_OppOwnerUpdate),oppBatchSize); //SAL24-735
       
    
       
    }
}