public with sharing class AssetExpirationBatch implements Database.Batchable<sObject>, Schedulable {

    public AssetExpirationBatch() {

    }

    private Id poc_id;

    public AssetExpirationBatch(ApexPages.StandardController std_controller) {
        poc_id = std_controller.getId();
    }

    public PageReference send_email_page_action() {
        PageReference pr;
        Boolean check_send = !Test.isRunningTest();
        List<POC__c> poc = [
            SELECT Id, Order__c, Contact__c, Contact__r.Email, Last_Expiration_Notification_Sent__c FROM POC__c
            WHERE Id = :poc_id
                AND Send_Asset_Expiration_Email__c = :check_send
                AND POC_Type__c != 'Conditional PO'
        ];
        if (poc.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'POC Request is not in appropriate stage'));
        }
        else {
            send_emails(poc);
            pr = new PageReference('/' + poc[0].Id);
            String uiThemeDisplayed = UserInfo.getUiThemeDisplayed();
            if(uiThemeDisplayed != 'Theme3'){  // Lightning Theme Value          
                   aura.redirect(pr);
            }else{
                pr.setRedirect(true);
            }
        }
        return pr;
    }

    public void execute(SchedulableContext context) {
        List<POC__c> check_poc = [SELECT Id FROM POC__c WHERE Send_Asset_Expiration_Email__c = true AND POC_Type__c != 'Conditional PO' LIMIT 1];
        if (check_poc.size() > 0) {
            Database.executeBatch(new AssetExpirationBatch(), 1);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Boolean check_send = !Test.isRunningTest();
        return Database.getQueryLocator([
            SELECT Id, Order__c, Contact__c, Contact__r.Email, Last_Expiration_Notification_Sent__c FROM POC__c
            WHERE Send_Asset_Expiration_Email__c = :check_send
        ]);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        send_emails(scope);
    }

    public void finish(Database.BatchableContext BC) {

    }

    private static Map<Id,String> internal_email_recipients(Id order_id) {
        Set<Id> collect_user_ids = new Set<Id>();
        Set<String> collect_user_emails = new Set<String>();
        Set<Id> collect_poc_ids = new Set<Id>();
        Order target_order = [SELECT Rubrik_Sales_Engineer__c, POC_Request__c FROM Order WHERE Id = :order_id];
        if (target_order.Rubrik_Sales_Engineer__c != null) {
            //collect_user_ids.add(target_order.Rubrik_Sales_Engineer__c);
            collect_user_emails.add(target_order.Rubrik_Sales_Engineer__c);
        }
        if (target_order.POC_Request__c != null) {
            collect_poc_ids.add(target_order.POC_Request__c);
        }

        List<OpportunityTeamMember> lstOTM = [
            SELECT Id, UserId, OpportunityId, User.Email
            FROM OpportunityTeamMember
            WHERE OpportunityId IN (SELECT OpportunityId FROM Order WHERE Id = :order_id)
                AND (TeamMemberRole = 'Sales Engineer' OR TeamMemberRole = 'Sales Engineer Manager')
        ];
        for(OpportunityTeamMember otm : lstOTM) {
            collect_user_emails.add(otm.User.Email);
        }

        for (POC__c poc : [
            SELECT (Select StepStatus, ActorId From ProcessSteps Where StepStatus = 'Approved'),
                (Select SubmittedById From ProcessInstances)
            FROM POC__c WHERE Order__c = :order_id OR Id IN :collect_poc_ids
        ]) {
            for (ProcessInstance pi : poc.ProcessInstances) {
                collect_user_ids.add(pi.SubmittedById);
            }
            for (ProcessInstanceHistory pih : poc.ProcessSteps) {
                collect_user_ids.add(pih.ActorId);
            }
        }
        Map<Id,String> result = new Map<Id,String>();
        if (!collect_user_ids.isEmpty() || !collect_user_emails.isEmpty()) {
            Map<Id,String> pre_result = new Map<Id,String>();
            for (User usr : [SELECT Id, Email FROM User WHERE Id IN :collect_user_ids OR Email IN :collect_user_emails]) {
                pre_result.put(usr.Id, usr.Email);
            }
            for (Id usr_id : collect_user_ids) {
                result.put(usr_id, pre_result.get(usr_id));
            }
        }
        return result;
    }

    private static User getApprovalSubmiter(Id orderId) {
        List<ProcessInstance> inst = [SELECT TargetObjectId, SubmittedBy.Id,SubmittedBy.Name FROM ProcessInstance WHERE TargetObjectId = :orderId LIMIT 1];
        return (!inst.isEmpty()) ? (User)inst[0].SubmittedBy : null;
    }

    public static void send_emails(List<sObject> scope) {
        String HOLDER_TEMPLATE = 'POC_Asset_expiration_emails';
        String ENGINEER_TEMPLATE = 'POC_Asset_expiration_emails2';
        Set<String> template_name_set = new Set<String> { HOLDER_TEMPLATE, ENGINEER_TEMPLATE };
        Map<String,Id> template_map = new Map<String,Id>();
        for (EmailTemplate et : [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :template_name_set]) {
            template_map.put(et.DeveloperName, et.Id);
        }
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        List<POC__c> update_poc = new List<POC__c>();
        for (sObject obj : scope) {
            POC__c poc_obj = (POC__c)obj;

            if (template_map.get(ENGINEER_TEMPLATE) != null) {
                Map<Id,String> recipients = internal_email_recipients(poc_obj.Order__c);
                User submittedBy = getApprovalSubmiter(poc_obj.Id);

                if (recipients.size() > 0) {

                    List<Id> recipients_plain = new List<Id>(recipients.keySet());
                    Id submittedById = (submittedBy == null) ? recipients_plain[0] : submittedBy.Id;

                    Messaging.SingleEmailMessage engineer_message = Messaging.renderStoredEmailTemplate(
                        template_map.get(ENGINEER_TEMPLATE),
                        submittedById,//recipients_plain[0],
                        poc_obj.Order__c
                    );
                    String body = engineer_message.getHtmlBody();
                    body = body.replace('UserSubmitterName', submittedBy.Name);
                    engineer_message.setHtmlBody(body);

                    engineer_message.saveAsActivity = false;
                    engineer_message.setToAddresses(recipients.values());
                    engineer_message.setTargetObjectId(submittedById);
                    //donotreply@rubrik.com
                    engineer_message.setOrgWideEmailAddressId('0D21W000000PD33');
                    messages.add(engineer_message);
                }
            }
            poc_obj.Last_Expiration_Notification_Sent__c = Date.today();
            update_poc.add(poc_obj);
        }
        update update_poc;
        if (messages.size() > 0 && !Test.isRunningTest()) {
            Messaging.sendEmail(messages);
        }
    }

}