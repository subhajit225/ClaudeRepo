/**
* @Description        : This is the Batch class which update Opportunity where multiple Primary Quote is associated
* @Author             : Shivani
* Ver       Date            Author                 Modification
* 1.0      06-20-2022       Shivani               Intial Draft
**/ 
public class UpdatePrimaryQuotesBatch implements Database.Batchable<sObject>, Database.Stateful{
    public Set <Id> opportunityId = new Set<Id>(); 
    public Set <Id> processedOppId = new Set<Id>(); 
    public String queryStr = '';
    public List<String> errorsnewOppList = new List<String>();
     /**
    * Method : UpdatePrimaryQuotesBatch
    * Parameters : Accept Opportunity Id to update primary Quotes on it
    * Description :  This method is added to pass specific Opportunity Id
    */
    
    public UpdatePrimaryQuotesBatch(Set <Id> opportunityId) {
        this.opportunityId = opportunityId;
    }
     /**
    * Method : UpdatePrimaryQuotesBatch constructure
    * Parameters : Accept QueryString based on which Opportunities and PrimaryQuote will be updated. 
    * Description :  Added inorder to execute batch from console and pass dynamic query
    */
    public UpdatePrimaryQuotesBatch(String queryStr) {
        this.queryStr = queryStr;
    }
    /**
    * Method : updateQuotesOnOpportunity
    * Parameters : 
    * Description : Default Constructor
    */
    public UpdatePrimaryQuotesBatch() {
    }

    /**
    * Method : updateQuotesOnOpportunity
    * Parameters : opportunityRecords- This parameter holds all Opportunities where multiple Primary Quote
    * Description :  This method is to set only 1 Quote as primary and unche
    */
    public database.QueryLocator start(Database.BatchableContext bc){
        system.debug('in start'+opportunityId);
        List<String> stagesToExclude = new List<String>();
        stagesToExclude.addAll(System.Label.Opportunity_Stages.split(','));
        if(opportunityId.isEmpty()) {
            Map<Id,AggregateResult> oppIdQuoteMap = new Map<id,AggregateResult>([SELECT SBQQ__Opportunity2__c Id, 
                                                                                        count(id) 
                                                                                     FROM SBQQ__Quote__c 
                                                                                     WHERE SBQQ__Primary__c = true 
                                                                                     AND SBQQ__Opportunity2__c  != null 
                                                                                     AND SBQQ__Opportunity2__r.SBQQ__Ordered__c = false
                                                                                     GROUP BY SBQQ__Opportunity2__c having count(id) > 1]);
            opportunityId = oppIdQuoteMap.keyset();
        }
        
       
        String query = queryStr != '' ? queryStr : 'SELECT Id, ' +
                                                    'StageName, '+
                                                    'SBQQ__Ordered__c, '+
                                                    'SBQQ__PrimaryQuote__c, '+
                                                    'Opportunity_Sub_Type__c, ' +
                                                    'Number_of_valid_Primary_Quotes__c, '+ // CPQ22-3860
                                                    '(SELECT Id, '+
                                                    'SBQQ__Primary__c, '+
                                                    'SBQQ__NetAmount__c '+
                                                    'FROM sbqq__Quotes2__r  '+
                                                    'WHERE SBQQ__Primary__c = True '+
                                                    'ORDER BY Createddate desc) ' +
                                                    'FROM Opportunity WHERE SBQQ__Ordered__c = false ' +
                                                    'AND StageName NOT IN '+stagesToExclude +
                                                    'AND Id IN :opportunityId ';
        return Database.getQueryLocator(query);
    } 
    
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunityRecords) {
        try{
           // Integer i=1/0;
        processedOppId = UpdatePrimaryQuotesBatchUtility.updateQuotesOnOpportunity(opportunityRecords);
            System.debug('ERRR '+UpdatePrimaryQuotesBatchUtility.errr);
            if(UpdatePrimaryQuotesBatchUtility.errr!=null && UpdatePrimaryQuotesBatchUtility.errr.size()>1)
            {
                errorsnewOppList.addAll(UpdatePrimaryQuotesBatchUtility.errr);
            }
        }
        Catch(exception ex){
            system.debug('@@ Error Details '+ex.getMessage());
            errorsnewOppList.add('</b> ::' + JSON.serialize(ex.getMessage()));
            Batch_Error_Log__c bel = new Batch_Error_Log__c();bel.Failure_Job_ID__c = bc.getJobID();bel.Failure_Message__c = ex.getMessage();
            try{insert bel;}
            catch(Exception e){
             system.debug('@@ Error Details '+e.getMessage());   
            }
          }
    }    
    
    public void finish(Database.BatchableContext bc){
        String emailBody = System.Label.UpdatePrimaryQuoteEmailBody ;
        if(processedOppId.size() > 0) {
            for (Id recordId : processedOppId ) {
                String recordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
                emailBody += '<a href="' + recordUrl + '">' + recordId + '</a><br/>';
            }
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('UpdatePrimaryQuoteBatch Process Completed');
            email.setHtmlBody(emailBody);
            email.setToAddresses(new List<String>{ System.Label.UpdatePrimaryQuoteRecipient });
            Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            if (sendResults[0].isSuccess()) {
                System.debug('Email sent successfully');
            } else {
                System.debug('Email sending failed: ' + sendResults[0].getErrors()[0].getMessage());
            }
        }
        System.debug('errorsnewOppList> '+errorsnewOppList);
        Messaging.SingleEmailMessage emailmessage = new Messaging.SingleEmailMessage();
         String strEmails = System.Label.ServiceContractRenewalForecastBatch_Emails;
        String strCPQAdmin = System.Label.CPQAdminEmailId;
        String[] toAddresses = !String.isBlank(strEmails) ? strEmails.split(',') : new List<String>{strCPQAdmin};
          //String[] toAddresses = new List<String>{'cpq_it_admin@rubrik.com','salesapps@rubrik.com'};//for testing
             System.debug('toAddresses> '+toAddresses);
            emailmessage.setToAddresses(toAddresses);
            emailmessage.setSubject('Update Primary Quotes Batch Errors - ' + Date.today().format());
            String Message = 'Below is a list of the Opportunity/Quote that failed to update <br/><br/>';
            if(!errorsnewOppList.isEmpty()) {
                Message += '<b>Opportunity Updated YESTERDAY:</b> <br/>';
                for(String eachError : errorsnewOppList) {
                    Message += eachError + '<br/>';
                }
                Message += '<br/>';
            }
            Message += '<br/>Thank you';
            System.debug('Message> '+Message);
            emailmessage.setHtmlBody(Message);
            if (!test.isRunningTest() && (!errorsnewOppList.isEmpty() )) {
                //Send email
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailmessage });
                System.debug('Email is sent Successfully.');
            }
    }    
}