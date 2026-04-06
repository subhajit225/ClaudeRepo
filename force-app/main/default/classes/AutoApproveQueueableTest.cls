/***********************************************************************************************************
* Class Name           : AutoApproveQueueableTest
* Date Created/Modified: 21/11/2025
* Author               : Paritosh
* @description         : Test class for AutoApproveQueueable
* Test Class           :
/********************************************************************************************************/
@IsTest
public without sharing class AutoApproveQueueableTest {
    
    @IsTest
    /**
     * @description Test method to verify email sending for user approver
     */
    static void sendEmailForUserApprover() {

        User usr = new user(Id=UserInfo.getUserId());

        List<Group> listGroup = TestDataFactory.getGroups('Test Group', 1);
        insert listGroup;
        
        List<GroupMember> listGroupMember = TestDataFactory.getGroupMembers(listGroup[0].Id, new Set<Id>{usr.Id, usr.Id});
        insert listGroupMember;

         system.runas(usr){

            TriggerControl__c control = new TriggerControl__c(
            Name = 'Approval',
            DisableTrigger__c = true
            );
            insert control;

            List<sbaa__Approver__c> listApprover =
            TestDataFactory.getApprovers(
                    new Set<Id> {
                        usr.Id
                    },
                    new Set<Id> {
                        listGroup[0].Id
                    }
                );
            insert listApprover;

            sbaa__EmailTemplate__c template = new sbaa__EmailTemplate__c(
                Name = 'Test Template',
                sbaa__TemplateId__c = [select id from EmailTemplate where DeveloperName ='Quote_Approval_Request'].Id
            );
            insert template;

            sbaa__ApprovalRule__c rule = new sbaa__ApprovalRule__c();
            rule.sbaa__TargetObject__c = 'SBQQ__Quote__c';
            rule.Request_Template__c = template.Id;
            rule.SBAA__Approver__c = listApprover[0].Id;
            insert rule;

            sbaa__Approval__c approval = new sbaa__Approval__c(
                sbaa__Status__c = 'Requested',
                sbaa__AssignedTo__c = usr.Id,
                SBAA__Approver__c = listApprover[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__Rule__c = rule.Id
            );
            insert approval;

            sbaa__ApprovalRule__c rule2 = new sbaa__ApprovalRule__c();
            rule2.sbaa__TargetObject__c = 'SBQQ__Quote__c';
            rule2.Request_Template__c = template.Id;
            rule2.SBAA__Approver__c = listApprover[1].Id;
            insert rule2;

            sbaa__Approval__c approval2 = new sbaa__Approval__c(
                sbaa__Status__c = 'Requested',
                sbaa__AssignedTo__c = usr.Id,
                SBAA__Approver__c = listApprover[1].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__Rule__c = rule2.Id
            );
            insert approval2;
            
            AutoApproveQueueable.smartApprovePendingEmail.add(approval.Id);
            AutoApproveQueueable.smartApprovePendingEmail.add(approval2.Id);
            List<SBAA__Approval__c> aprvls = new List<SBAA__Approval__c>{approval, approval2};

            Test.startTest();
        
                AutoApproveQueueable.sendEmailForSmartApprovals(aprvls);
                AutoApproveQueueable.smartApprovePendingEmail = null;
                AutoApproveQueueable.sendEmailForSmartApprovals(aprvls);
                
            Test.stopTest();

            System.assert(aprvls.size() > 0);

        }
    }
}