/**
* @File Name : AutoApproveQueueable.cls
* @description : This class will send approval rules for approval via SBAA package
* @Author : Ankita Varma
* @Last Modified By : Ankita Varma
* @Last Modified On : November 6, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | November 6, 2025 |   | Initial Version
**/
public without sharing class AutoApproveQueueable{
    public static Set<Id> smartApprovePendingEmail = new Set<Id>();

    /**
     * @description : Method to send approval email
     * @param approvalList  : Set of approval Ids
     */
    public static void sendEmailForSmartApprovals(List<sbaa__Approval__c> approvalList) {
        try {
            Set<Id> approvalIds = new Set<Id>();
            for (sbaa__Approval__c approval : approvalList) {
                //FY26WL-961 include approvals queued to requested
                if (approval.SBAA__Status__c == Constants.STATUS_REQUESTED && (smartApprovePendingEmail.contains(approval.Id))) {
                    approvalIds.add(approval.Id);
                }
            }
            //FY26WL-961 clear smartApprovePendingEmail
            smartApprovePendingEmail.clear();

            if (approvalIds.isEmpty()) {
                return;
            }
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            //get approval data
            //FY26WL-961 added clause to check template
            List<SBAA__Approval__c> aprvList = [SELECT Id, Quote__c, sbaa__Rule__r.Request_Template__r.sbaa__TemplateId__c, 
            SBAA__Approver__c, SBAA__Approver__r.sbaa__User__c, SBAA__Approver__r.sbaa__GroupId__c,
            sbaa__AssignedTo__c, sbaa__AssignedTo__r.Email FROM SBAA__Approval__c WHERE Id IN : approvalIds AND sbaa__Rule__r.Request_Template__c != null];

            Map<Id, Id> aprvIdGrpIdMap = new Map<Id, Id>();
            for(SBAA__Approval__c aprv: aprvList) {
                //if approver is group
                if(aprv.SBAA__Approver__r.sbaa__User__c == null && !String.isBlank(aprv.SBAA__Approver__r.sbaa__GroupId__c)){
                    if(aprv.SBAA__Approver__c != null && aprv.SBAA__Approver__r.sbaa__GroupId__c != null) {
                        aprvIdGrpIdMap.put(aprv.Id, aprv.SBAA__Approver__r.sbaa__GroupId__c);
                    }                
                }else{
                    //if approver is user
                    if(aprv.sbaa__AssignedTo__c != null) {
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                       
                        email.setTargetObjectId(aprv.sbaa__AssignedTo__c);
                        email.setToAddresses(new List<String>{aprv.sbaa__AssignedTo__r.Email});
                        email.setReplyTo(System.Label.Approval_Long_Email);
                        email.setWhatId(aprv.Id);
                        email.setSaveAsActivity(false); 
                        email.setTemplateId(aprv.sbaa__Rule__r.Request_Template__r.sbaa__TemplateId__c);
                        emailsToSend.add(email);
                    }
                }
            } 
            List<GroupMember> grpMbrList = new List<GroupMember>();
            if(aprvIdGrpIdMap != null && !aprvIdGrpIdMap.isEmpty()) {
                grpMbrList = [SELECT Id, UserOrGroupId, UserOrGroup.Email, GroupId  
                    FROM GroupMember WHERE GroupId IN:aprvIdGrpIdMap.values()];
            }
            //for group aprover get the members
            Map<Id, List<User>> grpIdUserEmailListMap = new Map<Id, List<User>>();
            
            for(GroupMember gm : grpMbrList){
                if(String.valueOf(gm.UserOrGroupId).startsWith('005')) {// Ensure it is a User 
                    if(grpIdUserEmailListMap.containsKey(gm.GroupId)){
                        grpIdUserEmailListMap.get(gm.GroupId).add(new User(Id=gm.UserOrGroupId, Email=gm.UserOrGroup.Email));
                    }else{
                        grpIdUserEmailListMap.put(gm.GroupId, new List<User>{new User(Id=gm.UserOrGroupId, Email=gm.UserOrGroup.Email)});
                    }
                }
            }
            for(SBAA__Approval__c aprv: aprvList){
                if(grpIdUserEmailListMap.containsKey(aprv.SBAA__Approver__r.sbaa__GroupId__c)){
                    for (User usr :  grpIdUserEmailListMap.get(aprv.SBAA__Approver__r.sbaa__GroupId__c)){
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email.setToAddresses(new List<String>{usr.Email});
                        email.setReplyTo(System.Label.Approval_Long_Email);
                        email.setWhatId(aprv.Id);
                        email.setTargetObjectId(usr.Id);
                        email.setSaveAsActivity(false); 
                        email.setTemplateId(aprv.sbaa__Rule__r.Request_Template__r.sbaa__TemplateId__c);
                        emailsToSend.add(email);
                    }
                }
            }

            //send out emails
            
            if (!emailsToSend.isEmpty() && !Test.isRunningTest()) {
                Messaging.sendEmail(emailsToSend, false);
            }
        }catch (Exception e){
             insert new Custom_Error_Log__c(
                Class__c = 'AutoApproveQueueable',
                Functionality__c = 'sendEmail',
                Exception_Message__c= e.getMessage(),
                ErrorTrace__c=  e.getStackTraceString()
            );
        }
    }
}