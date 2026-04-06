/**
 * @description Trigger handler for Approval object. 
 *              Handles insert, update, delete and email notification logic.
 */
public without sharing class ApprovalTriggerHandler extends TriggerHandler {
    
    /**
     * @description Default constructor.
     */
    public ApprovalTriggerHandler() {
        System.debug(LoggingLevel.FINE, 'ApprovalTriggerHandler constructor invoked');
    }
    
    /**
     * @description Executes before insert trigger logic on Approval.
     */
    public override void beforeInsert() {
        ApprovalTriggerHelper.assignDDCRecordType(Trigger.new);
        ApprovalTriggerHelper.duplicateCheck(Trigger.new);
        //Added by Sumedha for CPQ22-726
        ApprovalTriggerHelper.autoApprovalList(Trigger.new);
        //CPQ22-726 ends
         //FY26WL-230 smart approvals
         AutoApprovalTriggerUtility.autoApprove(Trigger.new);
        
    }
    
    /**
     * @description Executes after insert trigger logic on Approval.
     */
    public override void afterInsert() {
        System.debug(LoggingLevel.FINE, 'ApafterInsert constructor invoked');
        List<sbaa__Approval__c> approvalList = (List<sbaa__Approval__c>)Trigger.new;

        //FY26WL-961 start - send email for custom smart approvals (requested)
        for (sbaa__Approval__c approval : approvalList) {
            if (approval.SBAA__Status__c == Constants.STATUS_REQUESTED) {
                AutoApproveQueueable.smartApprovePendingEmail.add(approval.Id);
            }
        }
        AutoApproveQueueable.sendEmailForSmartApprovals(approvalList);
        //FY26WL-961 end
    }
    
    /**
     * @description Executes before update trigger logic on Approval.
     */
    public override void beforeUpdate() {
        List<sbaa__Approval__c> listOldApproval = new List<sbaa__Approval__c>();
        Map<Id, sbaa__Approval__c> mapNewApproval = new Map<Id, sbaa__Approval__c>();
        
        for (sbaa__Approval__c objApproval : (List<sbaa__Approval__c>)Trigger.old) {
            
            sbaa__Approval__c objNewApproval = (sbaa__Approval__c)Trigger.newMap.get(objApproval.Id);
            
            if (
                    objApproval.sbaa__AssignedTo__c != objNewApproval.sbaa__AssignedTo__c) {
                listOldApproval.add(objApproval);
                mapNewApproval.put(objApproval.Id, objNewApproval);
            }
            //CPQ-3440 Starts
            if(objApproval.sbaa__Status__c != objNewApproval.sbaa__Status__c && (objNewApproval.Feedback_Groups__c !=null || objNewApproval.Categories__c !=null)) {
                 if(objNewApproval.sbaa__Status__c=='Approved' || objNewApproval.sbaa__Status__c=='Rejected')
                 {
                   objNewApproval.Request_To_Information_Status__c = objNewApproval.sbaa__Status__c;
                 }
            } //CPQ-3440 Ends
         
        }
        
        if (!listOldApproval.isEmpty()) {
           ApprovalTriggerHelper.validateUser(listOldApproval, mapNewApproval);
        }
       ApprovalTriggerHelper.checkForDDCValidations((Map<Id, sbaa__Approval__c>)Trigger.OldMap,(List<sbaa__Approval__c>)Trigger.New);
     }
    
    /**
     * @description Executes after update trigger logic on Approval.
     */
    public override void afterUpdate() {
         for (sbaa__Approval__c objApproval : (List<sbaa__Approval__c>)Trigger.new) {
              sbaa__Approval__c objOldApproval = (sbaa__Approval__c)Trigger.oldMap.get(objApproval.Id);
             if( objOldApproval.Request_To_Information_Status__c != 'Waiting for Information' &&  
                 objApproval.Request_To_Information_Status__c == 'Waiting for Information') {
                 sendEmail(objApproval);
             }
            //FY26WL-961 - send email for custom smart approvals - queued to requested, or assignee is changed
            if ((objApproval.SBAA__Status__c != objOldApproval.SBAA__Status__c && objApproval.SBAA__Status__c == Constants.STATUS_REQUESTED)
            || (objApproval.sbaa__AssignedTo__c != objOldApproval.sbaa__AssignedTo__c)){
                AutoApproveQueueable.smartApprovePendingEmail.add(objApproval.Id);
             }
         }

        ApprovalTriggerHelper.syncDDCStatus((Map<Id,sbaa__Approval__c>)Trigger.oldMap,(List<sbaa__Approval__c>)Trigger.new);
        ApprovalTriggerHelper.sendConditionalApprovalEmail((List<sbaa__Approval__c>)Trigger.new,(Map<Id,sbaa__Approval__c>)Trigger.oldMap);
        //FY26WL-230 start
        AutoApprovalTriggerUtility.createSnapshots(Trigger.new, (Map<Id, sbaa__Approval__c>) Trigger.oldMap); //FY25SR-SmartApprovals
        //FY26WL-230 end

        //FY26WL-961 - send email for custom smart approvals - queued to requested
        AutoApproveQueueable.sendEmailForSmartApprovals(Trigger.new);

    }
    
    /**
     * @description Executes before delete trigger logic on Approval.
     */
    public override void beforeDelete() {
        ApprovalTriggerHelper.preventApprovalDeletion((List<sbaa__Approval__c>)Trigger.new,(Map<Id,sbaa__Approval__c>)Trigger.oldMap);
    }
    
    /**
     * @description Executes after delete trigger logic on Approval.
     */
    public override void afterDelete() {
        System.debug(LoggingLevel.FINE, 'afterDelete constructor invoked');
    }
    
    /**
     * @description Executes after undelete trigger logic on Approval.
     */
    public override void afterUndelete() {
        System.debug(LoggingLevel.FINE, 'afterUnDelete constructor invoked');
    }
    
    /**
     * @description Sends email notification for Approval record based on Feedback Group.
     * @param approvalObj Approval record for which email needs to be sent.
     */
    public static void sendEmail(sbaa__Approval__c approvalObj)
    {
        EmailTemplate et = [SELECT Id,Subject, Body FROM EmailTemplate WHERE Name ='RequestForInformation'];
        List<String> mailToAddresses = new List<String>();
        List<String> idList = new List<String>();
        Id quoteId;
        String quoteOwnerEmail;
        String[] toaddresses = new String[] {};
        sbaa__Approval__c approval = [Select Id, Request_To_Information_Status__c, Feedback_Groups__c, Request_To_Information_Comment__c, Feedback_Group_Comments__c, Categories__c, Quote__c,Feedback_User_Email__c FROM sbaa__Approval__c WHERE Id =: approvalObj.Id];
        
        
        SBQQ__Quote__c quote = [SELECT Id, Name, OwnerId, SBQQ__Opportunity2__r.Owner.Manager.Email, SBQQ__Opportunity2__r.Owner.Email, Owner.Email FROM SBQQ__Quote__c WHERE Id =: approval.Quote__c];
        //To do
        
        if(approval != null && approval.Feedback_Groups__c != null) {
            if(approval.Feedback_Groups__c == 'Deal Operations') {
                toaddresses.add(System.Label.DealDeskEmail); 
            } else if(approval.Feedback_Groups__c == 'Deal Structuring' || approval.Feedback_Groups__c == 'Revenue' || approval.Feedback_Groups__c == 'Legal') {
                toaddresses.add(System.Label.DealStructuringEmail);
            } else if(approval.Feedback_Groups__c == 'Deal Desk Leadership') {
                toaddresses.add(System.Label.DealDeskLeadershipEmail);
            } else if(approval.Feedback_Groups__c == 'Sales (to opportunity owner)' && quote.SBQQ__Opportunity2__c != null && quote.SBQQ__Opportunity2__r.Owner.Email != null) {
                toaddresses.add(quote.SBQQ__Opportunity2__r.Owner.Email);
            } else if(approval.Feedback_Groups__c == 'Sales Manager (to opportunity owner’s manager)' && quote.SBQQ__Opportunity2__c != null && quote.SBQQ__Opportunity2__r.Owner.Manager != null && quote.SBQQ__Opportunity2__r.Owner.Manager.Email != null) {
                toaddresses.add(quote.SBQQ__Opportunity2__r.Owner.Manager.Email);
            } else if(approval.Feedback_Groups__c == 'Orders') {
                toaddresses.add(System.Label.OrdersEmail);
            } else if(approval.Feedback_Groups__c == 'Other' && approval.Feedback_User_Email__c != null ) {
                toaddresses.add(approval.Feedback_User_Email__c);                
            }
        }
        if(approval != null && approval.Feedback_Groups__c != null) {
        
        mailToAddresses.addAll(toaddresses);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(mailToAddresses);
        mail.setWhatId(approval.Id);
        mail.setTargetObjectId(quote.OwnerId);
        mail.setSaveAsActivity(false);
        //mail.setWhatId(quote.Id);
        mail.setTemplateId(et.Id);
        mail.setHTMLBody(et.Body);
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        allmsg.add(mail);

        if (!Test.isRunningTest()){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
        
        if (results[0].isSuccess()) {
            System.debug(LoggingLevel.INFO, 'Email sent successfully.');
        } else {
            System.debug(LoggingLevel.ERROR, 'Email failed to send. Error: ' + results[0].getErrors()[0].getMessage());
        }
        }
        }
    } 
}