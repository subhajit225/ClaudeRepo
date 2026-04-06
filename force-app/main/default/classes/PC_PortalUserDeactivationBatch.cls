/**
* @description :PC_PortalUserDeactivationBatch - Batch class for user deactivation
* @Test Class PC_PortalUserDeactivationBatchTest
*/
public class PC_PortalUserDeactivationBatch implements Database.Batchable<sObject> { 
     /**
    * @description : Start Method 
    * @param BatchableContext
    * @return Database.getQueryLocator
    */
    public Database.QueryLocator start(Database.BatchableContext BC)
    {Integer days = Integer.valueOf(System.Label.Partner_Portal_Inactivity_Days);
     DateTime inactivityDate = System.now().addDays(-days);
     return Database.getQueryLocator([SELECT Id FROM User WHERE IsActive = TRUE AND UserType = 'PowerPartner' AND (LastLoginDate < :inactivityDate OR LastLoginDate = NULL)]);  
    }
     /**
     * @description : Execute Method
     * @param BatchableContext , List of users
     * @return void
     */
    public void execute (Database.BatchableContext BC, List<User> scope)
    {List<User> userDMLList =new List<User>();
     for(User userObj:scope)
     {
         userObj.isActive=false;
         userDMLList.add(userObj);
     }
     System.enqueueJob(new UserDeactivationQueueable(userDMLList));
    } 
     /**
     * @description: Finish Method
     * @param BatchableContext
     * @return void
     */
    public void finish(Database.BatchableContext BC)
    {    
    }
 /***********************************************************************************************************
 * Method Name           : UserDeactivationQueueable
 * @description          : Queuable method for DML of user records , used for compatibility with user trigger
 ***********************************************************************************************************/
    public class UserDeactivationQueueable implements Queueable {
        private List<User> usersToProcess;  
        /**
 		* @description : Accepts incoming users list and saves the user data in a local list to be used later.
 		* @param List of users 
		* @return void
 		*/
        public UserDeactivationQueueable(List<User> users) {
            this.usersToProcess = users;
        }
        /**
 		* @description : QueueableContext execute method for asynchronous processing
 		* @param context 
		* @return void
 		*/  
        public void execute(QueueableContext context) {
            try {
                Database.update(usersToProcess, false);
            } catch(Exception exp) {
                System.debug(System.LoggingLevel.DEBUG, 'Exception occured ' + exp.getMessage() + ' at line ' + exp.getLineNumber());
                Custom_Error_Log__c errorLogRec = new Custom_Error_Log__c();
                errorLogRec.Class__c = 'PC_PortalUserDeactivationBatch';
                errorLogRec.Exception_Message__c = exp.getMessage();
                errorLogRec.Functionality__c = 'Updated users to inactive';
                insert errorLogRec;
            }
        }
    }   
}