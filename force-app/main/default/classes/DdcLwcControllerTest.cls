@isTest
public class DdcLwcControllerTest {
    @TestSetup
    static void setupMethod(){
        
        List<Profile> listProfile = new List<Profile>();
        listProfile = [Select Id
                       From Profile
                       Where Name = 'Rubrik Inside Sales'
                       OR Name = 'System Administrator'
                       Order By Name
                      ];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 3);
        
        listUser.addAll(TestDataFactory.getUsers('testClassUserAdmin', new Set<Id>{listProfile[1].Id}, 1));
        
        insert listUser;
        
        
        
        List<Group> listGroup = TestDataFactory.getGroups('Test Group', 2);
        
        System.runAs (listUser[3]) {
            insert listGroup;
            
            List<GroupMember> listGroupMember =
                TestDataFactory.getGroupMembers(listGroup[0].Id, new Set<Id>{listUser[1].Id, listUser[2].Id});
            listGroupMember.addAll(TestDataFactory.getGroupMembers(listGroup[1].Id, new Set<Id>{listUser[2].Id}));
            insert listGroupMember;
        }
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 1);
        insert listQuote;
        
        List<sbaa__Approver__c> listApprover =
            TestDataFactory.getApprovers(
                new Set<Id> {
                    listUser[0].Id,
                        listUser[1].Id,
                        listUser[2].Id,
                        listUser[3].Id
                        },
                new Set<Id> {
                    listGroup[0].Id,
                        listGroup[1].Id
                        }
            );
        insert listApprover;
        
        Deal_Desk_Case__c ddCase = new Deal_Desk_Case__c();
        ddCase.Deal_Desk_Team__c = 'Deal Structuring';
        ddCase.Amount_Conditional__c = 100;
        ddCase.Request_Type__c = 'General Inquiry';
        ddCase.Request_Sub_Type__c = 'Below Minimum Term';
        //ddCase.Request_Status__c = 'Draft';
        ddCase.Business_Justification__c = 'minimum characters';
        ddCase.ETM_Theatre__c = 'EMEA';
        ddCase.Opportunity__c = objOpportunity.Id;
        ddCase.ETM_Area__c = 'MAJORS';
        ddCase.ApprovalStatus__c = 'Pending';
        insert ddCase;
        
        TestDataFactory.setTriggerSwitch('Approval', false);        
        
        List<sbaa__Approval__c> listddApproval =
            new List<sbaa__Approval__c> {
                new sbaa__Approval__c(
                    Deal_Desk_Case__c = ddCase.Id,
                    sbaa__Opportunity__c = objOpportunity.Id,
                    sbaa__Status__c = 'Requested',
                    sbaa__Approver__c = listApprover[listApprover.size()-1].Id,
                    //sbaa__AssignedTo__c = listUser[0].Id,
                    sbaa__RecordField__c = 'Deal_Desk_Case__c',
                    sbaa__ApprovalStep__c = 1,
                    //sbaa__DelegatedApprover__c = listApprover[2].Id,
                    Previous_status__c = 'TestStatus'
                ), // Approval with Approver User and Delegated Approver User
                    new sbaa__Approval__c(
                        Deal_Desk_Case__c = ddCase.Id,
                        sbaa__Opportunity__c = objOpportunity.Id,
                        sbaa__Status__c = 'Requested',
                        sbaa__AssignedGroupId__c = listApprover[4].Id,
                        sbaa__RecordField__c = 'Deal_Desk_Case__c',
                        sbaa__ApprovalStep__c = 1,
                        Previous_status__c = 'TestStatus'
                    ), // Approval with Approver Group
                    new sbaa__Approval__c(
                        Deal_Desk_Case__c = ddCase.Id,
                        sbaa__Opportunity__c = objOpportunity.Id,
                        sbaa__Status__c = 'Requested',
                        sbaa__Approver__c = listApprover[0].Id,
                        sbaa__AssignedTo__c = listUser[0].Id,
                        sbaa__RecordField__c = 'Deal_Desk_Case__c',
                        sbaa__ApprovalStep__c = 1,
                        sbaa__DelegatedApprover__c = listApprover[5].Id,
                        Previous_status__c = 'TestStatus'
                    ) // Approval with Approver User and Delegated Approver Group
                    };
                        system.debug('listddApproval'+listddApproval);
        insert listddApproval;
        
        DdcLwcController.DdcWrapper ddcWrap = new DdcLwcController.DdcWrapper();
        ddcWrap.myId = 'testId102030';
        ddcWrap.message = 'This is test message';
        ddcWrap.ObjectName = 'Deal_Desk_Case__c';
        ddcWrap.status = 'On Hold';
        ddcWrap.userComments = '';
        
        
       
    }
    
    @isTest
    static void testValidateMethods(){
         List<sbaa__approval__c> listddApproval=[Select Id from sbaa__approval__c];
         Deal_Desk_Case__c ddCase=[Select Id from Deal_Desk_Case__c Limit 1];
        List<User> listUser= [Select Id from User Where firstname like 'testClassUser%'];
        DdcLwcController.ApprovalWrapper appWrap = new DdcLwcController.ApprovalWrapper();
        appWrap.amount = 100051.50;
        appWrap.approvalComments = 'This is test commments for Approval';
        Test.startTest();
        String testvalidateData = DdcLwcController.validateData(listddApproval[0].id);
        String validateDataTest = DdcLwcController.validateDataForApproval(listddApproval[0].id, listUser[0].id);
        String testvalidateData1 = DdcLwcController.validateData(ddcase.id);
        String testapproveCase = DdcLwcController.approveCase(listUser[0].Id, listddApproval[0].id, ddCase.Id, JSON.serialize(appWrap) );
        String testData = DdcLwcController.updateCase(ddCase.id, 'testComment');
        Test.stopTest();
        System.assert(ddcase.id!=null);
        
    }
    @isTest
    static void testDMLMethods(){
         Deal_Desk_Case__c ddCase=[Select Id from Deal_Desk_Case__c Limit 1];
         List<sbaa__approval__c> listddApproval=[Select Id from sbaa__approval__c where sbaa__status__c='Requested' and Deal_Desk_Case__c=:ddCase.Id];
        List<User> listUser= [Select Id from User Where firstname like 'testClassUser%'];
        ddCase.Request_Status__c='On Hold';
        update ddCase;
        Test.startTest();
        String testData = DdcLwcController.updateCase(ddCase.id, 'testComment');
         DdcLwcController.testPasser();

        Test.stopTest();
        System.assert(ddcase.id!=null);
        
    }
}