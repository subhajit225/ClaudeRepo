@isTest
public class ApprovalRequestWidgetControllerTest {
    
    @TestSetUp
    static void initialDataSetup() {
        // Create the TriggerControl__c record
        TriggerControl__c triggerControl = new TriggerControl__c(
            Name = 'Approval',
            DisableTrigger__c = false
        );
        insert triggerControl;
        
        // Create profiles, users, groups, and other necessary data for testing
        List<Profile> listProfile = [Select Id
                                     From Profile
                                     Where Name = 'Rubrik Inside Sales'
                                     OR Name = 'System Administrator'
                                     Order By Name];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 3);
        listUser.addAll(TestDataFactory.getUsers('testClassUserAdmin', new Set<Id>{listProfile[1].Id}, 1));
        insert listUser;
        
        List<Group> listGroup = TestDataFactory.getGroups('Test Group', 2);
        
        System.runAs(listUser[3]){
            insert listGroup;
            
            List<GroupMember> listGroupMember = TestDataFactory.getGroupMembers(listGroup[0].Id, new Set<Id>{listUser[1].Id, listUser[2].Id});
            listGroupMember.addAll(TestDataFactory.getGroupMembers(listGroup[1].Id, new Set<Id>{listUser[2].Id}));
            insert listGroupMember;
        }
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        insert objOpportunity;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 1);
        insert listQuote;
        
        List<sbaa__Approver__c> listApprover = TestDataFactory.getApprovers(
            new Set<Id> {
                listUser[0].Id,
                    listUser[1].Id
                    },
            new Set<Id> {
                listGroup[0].Id,
                    listGroup[1].Id
                    }
        );
        insert listApprover;
        
        List<sbaa__Approval__c> listApproval = new List<sbaa__Approval__c> {
            new sbaa__Approval__c(
                Quote__c = listQuote[0].Id,
                sbaa__Opportunity__c = objOpportunity.Id,
                sbaa__Status__c = 'Requested',
                sbaa__Approver__c = listApprover[0].Id,
                sbaa__AssignedTo__c = listUser[0].Id,
                sbaa__RecordField__c = 'Quote__c',
                sbaa__ApprovalStep__c = 1,
                sbaa__DelegatedApprover__c = listApprover[2].Id
            )
                };
                    insert listApproval;
    }
    
    @isTest
    static void testGetApprovalRequestsForTestUsers() {
        // Query existing users or create new users for testing
        List<User> testUsers = [SELECT Id FROM User WHERE FirstName LIKE 'testClassUser%' LIMIT 2];
        
        // Run the method
        Test.startTest();
        List<sbaa__Approval__c> result1 = ApprovalRequestWidgetController.getApprovalRequests(testUsers[0].Id);
        List<sbaa__Approval__c> result2 = ApprovalRequestWidgetController.getApprovalRequests(testUsers[1].Id);
        Test.stopTest();
        
    }
}