/**  
*  @description : Expired Quote Notification Batch to send email notification to opportunity owner when primary quote is expired.
*  Class Name :- ExpiredQuoteNotificationBatch     
*  Created Date :- 15-09-2025
*  Created By :- Mustakim Shaikh
*
//********************Change Logs*****************************************************************************
* 
* Change Request            Modified By          Date           Description 
* CPQ22-5589            Mustakim Shaikh          15-09-2025     Created class
*  
//********************Change Logs Ends*************************************************************************
*/ 
public class ExpiredQuoteNotificationBatch implements Database.Batchable<SObject>, Database.Stateful {

    private EmailTemplate et=[Select Id from EmailTemplate where DeveloperName ='Expired_Quote_Notification' limit 1];
            

    /**
     * @description Starts the batch process by querying Opportunities with primary Quotes expiring today, 2 days ago, or 4 days ago, and in specific stages.
     * @param bc The batchable context.
     * @return A QueryLocator for Opportunities meeting the criteria.
     **/
    public Database.QueryLocator start(Database.BatchableContext bc) {

        //Changed addDays as per CPQ22-6118
        Set<Date> targetDates = new Set<Date>{
            System.today().addDays(-1),
            System.today().addDays(-3),
            System.today().addDays(-5)
        };
        
        Set<String> stages = new Set<String>{
            '3 Technical Validation',
            '4 Business Justification',
            '5 Negotiate & Close',
            '6 PO With Channel'
        };

        return Database.getQueryLocator([
            SELECT Id, Name, OwnerId, SBQQ__PrimaryQuote__c, SBQQ__PrimaryQuote__r.Name,
                   SBQQ__PrimaryQuote__r.Expiration_Date__c, SBQQ__PrimaryQuote__r.ApprovalStatus__c, Owner.Name, Owner.FirstName
            FROM Opportunity
            WHERE StageName IN :stages
              AND (CloseDate = THIS_MONTH OR CloseDate = LAST_MONTH) //Added for CPQ22-6118
              AND SBQQ__PrimaryQuote__c != null
              AND SBQQ__PrimaryQuote__r.Expiration_Date__c IN :targetDates
              AND SBQQ__PrimaryQuote__r.ApprovalStatus__c = 'Approved'
        ]);
    }

    /**
     * @description execute the batch process post querying Opportunities with primary Quotes expiring today, 2 days ago, or 4 days ago, and in specific stages.
     * @param bc The batchable context.
     * @param  oppsToNotify The list of Opportunities to process in this batch chunk.
     **/
    public void execute(Database.BatchableContext bc, List<Opportunity> oppsToNotify) {
        List<Batch_Error_Log__c> batchErrLogList = new List<Batch_Error_Log__c>();
        String recordIds = '';
        try{
            if (!oppsToNotify.isEmpty()) {
                List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
                
                for (Opportunity opp : oppsToNotify) {
                    String oppId = opp.Id;
                    recordIds += oppId.substring(0,15) + ',';
                    recordIds = recordIds.length() > 100 ? recordIds.substring(recordIds.length() - 100) : recordIds;
                    
                    Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
                    emailMsg.setTargetObjectId(opp.OwnerId);
                    emailMsg.setSaveAsActivity(false);
                    if(et != null){
                        emailMsg.setTemplateId(et.Id);
                    }
                    emailMsg.setWhatId(opp.Id);
                    emails.add(emailMsg);
                }
                if (!emails.isEmpty()) {
                    Messaging.sendEmail(emails);
                }
            }
        } catch(exception e){ batchErrLogList.add(new Batch_Error_Log__c(Class_Name__c='ExpiredQuoteNotificationBatch',Failure_Message__c=e.getMessage(),Object_ID__c = recordIds, Scenario__c='Expired Primary Quote Email Notification to Oppty Owner',Failure_Date__c = Date.today(), Failure_Job_ID__c = bc.getJobID()));
            insert batchErrLogList;}

    }

    /**
     * @description finish the batch process.
     * @param bc The batchable context.
     **/
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.debug, 'Finished ExpiredQuoteNotificationBatch');        
    }
}