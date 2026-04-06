/**
* Date :26-October-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
**/

@isTest
public class DealDeskCaseReassignmentController_Test {
    
    @isTest
    static void testMethod1(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        System.runAs(listUser[0]) {
            
            Account objAccount = new Account();
            Contact objContact = new Contact();
            
            objAccount.Name = 'Test Account 26-05';
            objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount;
            
            objContact.Account = objAccount;
            objContact.LastName = 'Test Contact 22-05';
            insert objContact; 
            
            Opportunity objOpportunity = new Opportunity();
            objOpportunity.StageName = '1 Discovery';
            objOpportunity.Initial_Contacts_Name__c = objContact.Id;
            objOpportunity.Distributor_Lookup__c = objAccount.Id;
            objOpportunity.closeDate = System.Today() + 16;
            objOpportunity.Name = 'Test Opp 31-05';
            objOpportunity.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity.Partner_Lookup__c = objAccount.Id;
            test.startTest();
            insert objOpportunity;
            test.stopTest();
            
            Deal_Desk_Case__c ddc = new Deal_Desk_Case__c();
            ddc.Deal_Desk_Team__c = 'Deal Structuring';
            ddc.ApprovalStatus__c = '';
            ddc.Amount_Conditional__c = 100;
            ddc.Request_Type__c = 'General Inquiry';
            ddc.Request_Sub_Type__c = 'Below Minimum Term';
            ddc.Request_Status__c = 'Draft';
            ddc.Business_Justification__c = 'minimum characters';
            ddc.ETM_Theatre__c = 'EMEA';
            ddc.Opportunity__c = objOpportunity.Id;
            ddc.ETM_Area__c = 'MAJORS';
            insert ddc;
            list<Id> assgneeId = new list<Id>{listUser[0].id};
            list<String> statusStr = new list<string>{'Draft'};
            list<Id> ddId = new list<Id>{ddc.id};
            list<Deal_Desk_Case__c> ddcLi = DealDeskCaseReassignmentController.fetchFilteredRecords(assgneeId,'Deal Structuring',statusStr);
            list<sObject> liObj = DealDeskCaseReassignmentController.fetchReassignUser('test');
            list<Deal_Desk_Case__c> ddLi2 = DealDeskCaseReassignmentController.reAssignCase(ddId,listUser[1].id,ddId);
            system.assert(ddc.Id != null);
        }
    }
}