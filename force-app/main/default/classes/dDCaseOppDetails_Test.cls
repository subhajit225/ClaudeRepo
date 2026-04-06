/**
* Date :26-October-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
**/

@isTest
public class dDCaseOppDetails_Test {
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
            SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = objOpportunity.Id , SBQQ__Primary__c = true);
            insert q;
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
            ddc.Primary_Quote__c = q.Id;
            ddc.ETM_Area__c = 'MAJORS';
            insert ddc;
            dDCaseOppDetails.saveElapsedTime(ddc.id, '01:00:00');
            dDCaseOppDetails.getOppDetails(objOpportunity.Id);
            dDCaseOppDetails.getQuesMetadata();
            dDCaseOppDetails.getDDCPermission(ddc.id);
            dDCaseDetails.getddCaseDetails(ddc.id);
            dDCaseDetails.updateCase(ddc.id);
            system.assert(ddc.Id != null);
        }
    }
}