/**
 * @description This service class handles the sending of email notifications for failed batch jobs.
 * It queries for the failed batch jobs and sends a detailed email to the configured recipients based on the batch class name.
 * @author ChangeMeIn@UserSettingsUnder.SFDoc
 * @group Batch Services
 * @last modified on 09-03-2025
 * @last modified by ChangeMeIn@UserSettingsUnder.SFDoc
 **/
public with sharing class BatchFailureEmailService{

    /**
     * @description Processes a list of BatchApexErrorEvent records to identify which batch job failed and sends an email notification.
     * The method determines the recipient email address based on the batch class name and the Salesforce environment (sandbox or production).
     * @param errorEventList A list of `BatchApexErrorEvent` objects representing the errors from the failed batch jobs.
     */
    public void getClassInfo(List<BatchApexErrorEvent> errorEventList){
        Set<Id> asyncApexJobIds = new Set<Id>();
        for (BatchApexErrorEvent evt : errorEventList){
            asyncApexJobIds.add(evt.AsyncApexJobId);
        }
        Organization orgInfo = [SELECT IsSandbox FROM Organization LIMIT 1];
        Environment_Variables__c envVar = Environment_Variables__c.getInstance();
        String marketingAppEmail = orgInfo.IsSandbox ? envVar.Generic_Sandbox_Email__c : envVar.Production_Marketing_Apps_Email__c;
        String sfdcSOXBatchEmail = orgInfo.IsSandbox ? envVar.Generic_Sandbox_Email__c : envVar.Production_SOX_Batch_Email__c;
        String partnerPortalEmail = 'partnerportalit@rubrik.com';
        Map<String, List<String>> emailBatchMap = new Map<String, List<String>>{ partnerPortalEmail => new List<String>{ 'PC_DealRegExpiryUpdateBatch', 'PC_ContractExpiryBatch' }, marketingAppEmail => new List<String>{ 'BatchCreatePSProject', 'PSTaskExpiryNotificationBatch', 'Batch_SyncQueuedTaskToNetsuite', 'Batch_UpdatePSTaskCompletion', 'PSTaskNetSuiteStatusUpdate', 'TestBatch' } };
        for (String email : emailBatchMap.keySet()) {
            
            List<String> batchClassNames = emailBatchMap.get(email);
            Map<Id, AsyncApexJob> jobMap = new Map<Id, AsyncApexJob>([SELECT Id, ApexClassID, ApexClass.Name FROM AsyncApexJob WHERE Id IN :asyncApexJobIds AND ApexClass.Name IN :batchClassNames]);

            if (!jobMap.isEmpty() && sfdcSOXBatchEmail != null) {
                if(email == partnerPortalEmail || (email != partnerPortalEmail && marketingAppEmail != null)){
                    sendEmail(errorEventList, email, jobMap, sfdcSOXBatchEmail);
                }
            }
        }
    }

    /**
     * @description Sends an email notification with details about the batch job failure.
     * The email includes the job ID, class name, error message, and stack trace.
     * @param errorEventList A list of `BatchApexErrorEvent` objects.
     * @param toAddress The primary recipient's email address.
     * @param jobMap A map of `AsyncApexJob` records, keyed by their Id, for the failed batch jobs.
     * @param ccAddress The email address to be included as a CC recipient.
     */
    public static void sendEmail(List<BatchApexErrorEvent> errorEventList, String toAddress, Map<Id, AsyncApexJob> jobMap, String ccAddress){
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        
        Date batchFailedDate = System.today();
        for (BatchApexErrorEvent batchApex : errorEventList){
            if (jobMap.containsKey(batchApex.AsyncApexJobId)){
                String emailSubject = 'Batch Failure | ' + jobMap.get(batchApex.AsyncApexJobId).ApexClass.Name + ' | ' + batchFailedDate;
                String emailHtmlBody = 'Hi <br><br>Please find below the details:<br><br>Job Id: ' + batchApex.AsyncApexJobId + '<br>Class Name: ' + jobMap.get(batchApex.AsyncApexJobId).ApexClass.Name + '<br>Error Message: ' + batchApex.Message + '<br>Stack Trace: ' + batchApex.StackTrace + '<br>Date: ' + batchFailedDate + '<br><br>Thanks,';
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toAddress.split(','));
                email.setCcAddresses(ccAddress.split(','));
                email.setSubject(emailSubject);
                email.setHtmlBody(emailHtmlBody);
                emailList.add(email);
            }
        }
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailList);
    }
}