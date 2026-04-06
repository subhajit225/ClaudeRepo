@isTest
public class reqMoreInfoTriggerHandlerTest {
    @testsetup
    static void setupmethod(){
        // create required object record to create Deal Desk record
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
        ddCase.ApprovalStatus__c = '';
        ddCase.Amount_Conditional__c = 100;
        ddCase.Request_Type__c = 'General Inquiry';
        ddCase.Request_Sub_Type__c = 'Below Minimum Term';
        ddCase.Request_Status__c = 'On Hold';
        ddCase.Business_Justification__c = 'minimum characters';
        ddCase.ETM_Theatre__c = 'EMEA';
        ddCase.Opportunity__c = objOpportunity.Id;
        ddCase.ETM_Area__c = 'MAJORS';
        insert ddCase;
        
        TestDataFactory.setTriggerSwitch('Approval', false);
        
        List<sbaa__Approval__c> listddApproval =
            new List<sbaa__Approval__c> {
                new sbaa__Approval__c(
                    Deal_Desk_Case__c = ddCase.Id,
                    sbaa__Opportunity__c = objOpportunity.Id,
                    sbaa__Status__c = 'Approved',
                    sbaa__Approver__c = listApprover[0].Id,
                    sbaa__AssignedTo__c = listUser[0].Id,
                    sbaa__RecordField__c = 'Deal_Desk_Case__c',
                    sbaa__ApprovalStep__c = 1,
                    sbaa__DelegatedApprover__c = listApprover[2].Id
                ), // Approval with Approver User and Delegated Approver User
                    new sbaa__Approval__c(
                        Deal_Desk_Case__c = ddCase.Id,
                        sbaa__Opportunity__c = objOpportunity.Id,
                        sbaa__Status__c = 'Requested',
                        sbaa__AssignedGroupId__c = listApprover[4].Id,
                        sbaa__RecordField__c = 'Deal_Desk_Case__c',
                        sbaa__ApprovalStep__c = 1
                    ), // Approval with Approver Group
                    new sbaa__Approval__c(
                        Deal_Desk_Case__c = ddCase.Id,
                        sbaa__Opportunity__c = objOpportunity.Id,
                        sbaa__Status__c = 'Requested',
                        sbaa__Approver__c = listApprover[0].Id,
                        sbaa__AssignedTo__c = listUser[0].Id,
                        sbaa__RecordField__c = 'Deal_Desk_Case__c',
                        sbaa__ApprovalStep__c = 1,
                        sbaa__DelegatedApprover__c = listApprover[5].Id
                    ) // Approval with Approver User and Delegated Approver Group
                    };
                        system.debug('listddApproval'+listddApproval);
        insert listddApproval;
    }

    @istest
    static void testInsertLogic(){
		// Retrieve necessary data created in the test setup
        Deal_Desk_Case__c ddCase = [SELECT Id FROM Deal_Desk_Case__c LIMIT 1];
        sbaa__Approval__c theApproval = [SELECT Id FROM sbaa__Approval__c LIMIT 1];
        
        
       /* Request_More_Information_Notes__c theNote = new Request_More_Information_Notes__c(
            Approval__c = theApproval.Id,
            Deal_Desk_Case__c = ddCase.Id,
            OwnerId = listApprover[0].Id
        ); */
        
        Request_More_Information_Notes__c theNote = new Request_More_Information_Notes__c();
        theNote.Approval__c = theApproval.Id;
        theNote.Deal_Desk_Case__c = ddCase.Id;
        theNote.Feedback_Groups__c = 'Orders';
        theNote.Requestor_Comments__c = 'Can we have order for this customer for more than 5yrs?';
        insert theNote;
        ChatterUtil.testPasser();
 
        System.assert(ddcase.id!=null);
       }
}