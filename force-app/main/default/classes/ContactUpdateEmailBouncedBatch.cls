/**
 * @description Class to update the EmailBouncedFlag to FALSE on contacts - 
 * SAL25-355
*/
public with sharing class ContactUpdateEmailBouncedBatch  implements Database.Batchable<SObject>, Database.Stateful, Schedulable{
    String queryStr;
    public List<Custom_Error_Log__c> customErrorList = new List<Custom_Error_Log__c>();
    /**
     * @description constructor
    */
    public ContactUpdateEmailBouncedBatch(String queryStr){
        this.queryStr = queryStr;
    }
    /**
     * @description start method
    */
    public Database.queryLocator start(Database.BatchableContext batchContext){
        String queryStrStart = 'SELECT Id,EmailBouncedReason,EmailBouncedDate from Contact where IsEmailBounced = TRUE';
        queryStr = queryStr != null ? queryStr : queryStrStart;
        return Database.getQueryLocator(queryStr); 
    }
    /**
     * @description batch execute method
    */
    public void execute(Database.BatchableContext batchContext, List<Contact> contactList){
        List<Contact> updateContactList = new List<Contact>();
        for(Contact con :contactList){
            con.EmailBouncedReason = null;
            con.EmailBouncedDate = null;
            updateContactList.add(con);
        }
        if(!updateContactList.isEmpty()){
            flowControll.contactTrigger = false;
            List<Database.SaveResult> srList = Database.update(updateContactList, false);
            List<Custom_Error_Log__c> errorLogList = LogError.createDMLErrorLogWithRetrunType((List<SObject>)updateContactList, srList, 'ContactUpdateEmailBouncedBatch','Update Contact Emailbounced Flag');
            customErrorList.addAll(errorLogList); // SAL25-717
            flowControll.contactTrigger = true;
        }
    }
    /**
     * @description batch finish method
    */
    public void finish(Database.BatchableContext batchContext){
        /* Start SAL25-717 */
        if(!customErrorList.isEmpty()){
            string emailDetail = EmailHelper.prepareEmailBodyForCustomErrorLog(customErrorList);
            EmailHelper.sendBatchErrorsEmail(new List<String>{System.Label.SalesApps_Support_Email},
                                            'ContactUpdateEmailBouncedBatch - ' + Date.today().format(),
                                            emailDetail); 
        }
         /* End SAL25-717 */
    }
    /**
     * @description schedule execute method
    */
    public void execute(SchedulableContext sc){
		Database.executeBatch(new ContactUpdateEmailBouncedBatch(null), 200);
    }
}