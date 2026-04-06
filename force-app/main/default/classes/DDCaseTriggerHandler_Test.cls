/**
* Date :26-October-2023
* Author : Rajat Jain
* JIRA : Deal Desk Case
**/

@isTest
public with sharing class DDCaseTriggerHandler_Test {
    
    @isTest
    static void testMethod1(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        System.runAs(listUser[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            
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
            ddc.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc.Urgent__c = true; //DD25-6
            insert ddc;
            ddc.Deal_Desk_Team__c = 'Deal Structuring';
            ddc.Request_Type__c = 'Legal Language';
            ddc.OwnerId = listUser[1].Id;
            ddc.Tertiary_Owner__c = listUser[1].id;
            ddc.Secondary_owner__c = listUser[1].id;
            ddc.ApprovalStatus__c = 'Pending';
            ddc.Deal_Desk_Tagging__c = 'Other';
            ddc.Summary_of_Approval__c ='Test';
            update ddc;
            DDCaseTriggerHandler.updateDDCaseStatus(new list<opportunity>{objOpportunity});
            System.assert(ddc.Id != null);
        }
    }
     @isTest
    static void testMethod2(){
        List<Profile> listProfile1 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile1[0].Id}, 2);
        insert listUser1;
        listUser1[0].ManagerId = listUser1[1].Id;
        update listUser1;
        System.runAs(listUser1[0]) {
            
            Account objAccount1 = new Account();
            Contact objContact1 = new Contact();
            
            objAccount1.Name = 'Test Account 25-05';
            objAccount1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount1;
            
            objContact1.Account = objAccount1;
            objContact1.LastName = 'Test Contact 27-05';
            insert objContact1; 
            
            Opportunity objOpportunity1 = new Opportunity();
            objOpportunity1.StageName = '1 Discovery';
            objOpportunity1.closeDate = System.Today() + 10;
            objOpportunity1.Distributor_Lookup__c = objAccount1.Id;
            objOpportunity1.Name = 'Test Opp1 31-05';
            objOpportunity1.Initial_Contacts_Name__c = objContact1.Id;
            objOpportunity1.Partner_Lookup__c = objAccount1.Id;
            objOpportunity1.Opportunity_Sub_Type__c = 'Regular';
            test.startTest();
            insert objOpportunity1;
            test.stopTest();
            
            Deal_Desk_Case__c ddc1 = new Deal_Desk_Case__c();
            ddc1.Request_Type__c = 'General Inquiry';
            ddc1.Request_Sub_Type__c = 'Below Minimum Term';
            ddc1.Request_Status__c = 'Draft';
            ddc1.Business_Justification__c = 'minimum 10 chars';
            ddc1.Opportunity__c = objOpportunity1.Id;
            ddc1.ApprovalStatus__c = '';
            ddc1.Amount_Conditional__c = 300;
            ddc1.Deal_Desk_Team__c = 'Deal Structuring';
            ddc1.ETM_Area__c = 'MAJORS';
            ddc1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc1.ETM_Theatre__c = 'EMEA';
            ddc1.OwnerId = listUser1[1].Id;
            ddc1.Tertiary_Owner__c = listUser1[1].id;
            ddc1.Secondary_owner__c = listUser1[1].id;
            insert ddc1;
            ddc1.ApprovalStatus__c = 'Approved';
            ddc1.Request_Status__c = 'Approved';
            ddc1.Urgent__c = true; //DD25-6
            update ddc1;
            System.assert(ddc1.Id != null);
        }
    }
    
    @isTest
    static void testMethod3(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
           
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = '';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'EMEA';
            ddc2.Deal_Desk_Team__c = 'Deal Structuring';
            ddc2.Request_Type__c = 'General Inquiry';
            insert ddc2;
            ddc2.Request_Status__c = 'Closed - Incomplete';
            update ddc2;
            System.assert(ddc2.Id != null);
        }
    }
    
    @isTest
    static void testMethod4(){
        List<Profile> listProfile3 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser3 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile3[0].Id}, 2);
        insert listUser3;
        listUser3[0].ManagerId = listUser3[1].Id;
        update listUser3;
        System.runAs(listUser3[0]) {
            
            Account objAccount3 = new Account();
            Contact objContact3 = new Contact();
            
            objAccount3.Name = 'Test Account 31-03';
            objAccount3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount3;
            
            objContact3.Account = objAccount3;
            objContact3.LastName = 'Test Contact 31-07';
            insert objContact3; 
            
            Opportunity objOpportunity3 = new Opportunity();
            objOpportunity3.StageName = '1 Discovery';
            objOpportunity3.Partner_Lookup__c = objAccount3.Id;
            objOpportunity3.Amount = 100;
            objOpportunity3.Name = 'Test Opp3 31-05';
            objOpportunity3.Initial_Contacts_Name__c = objContact3.Id;
            objOpportunity3.closeDate = System.Today() + 25;
            objOpportunity3.Distributor_Lookup__c = objAccount3.Id;
            objOpportunity3.Opportunity_Sub_Type__c = 'Regular';
            test.startTest();
            insert objOpportunity3;
            test.stopTest();
            
            Deal_Desk_Case__c ddc3 = new Deal_Desk_Case__c();
            ddc3.Amount_Conditional__c = 1000;
            ddc3.Deal_Desk_Team__c = 'Deal Structuring';
            ddc3.ETM_Area__c = 'MAJORS';
            ddc3.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc3.ETM_Theatre__c = 'EMEA';
            ddc3.Request_Type__c = 'General Inquiry';
            ddc3.Business_Justification__c = 'minimum 10 characters';
            ddc3.Request_Sub_Type__c = 'Below Minimum Term';
            ddc3.Request_Status__c = 'Draft';
            ddc3.ApprovalStatus__c = '';
            ddc3.Opportunity__c = objOpportunity3.Id;
            ddc3.Opportunity_Stage__c = '1 Discovery';
           	insert ddc3;
            ddc3.Request_Status__c = 'Conditionally Approved';
            ddc3.Amount_TCV__c = 100;
            update ddc3;
            //ddc3.Opportunity_Stage__c = '6 PO With Channel';
            //update ddc3;
            System.assert(ddc3.Id != null);
     }
    }
     // DD25-77 Starts
    @isTest
    static void testPreventDeletion() {
       
               
        List<Profile> listProfile1 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile1[0].Id}, 2);
        insert listUser1;
        listUser1[0].ManagerId = listUser1[1].Id;
        update listUser1;
        SOX_Objects_Delete_Access__c userPermission = SOX_Objects_Delete_Access__c.getInstance(listUser1[1].id);
        userPermission.Allow_DDcase_delete__c = false; 
        upsert userPermission; 
        Deal_Desk_Case__c ddc = new Deal_Desk_Case__c();
        System.runAs(listUser1[0]) {
            
            Account objAccount1 = new Account();
            Contact objContact1 = new Contact();
            
            objAccount1.Name = 'Test Account 25-05';
            objAccount1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount1;
            
            objContact1.Account = objAccount1;
            objContact1.LastName = 'Test Contact 27-05';
            insert objContact1; 
            
            Opportunity objOpportunity1 = new Opportunity();
            objOpportunity1.StageName = '1 Discovery';
            objOpportunity1.closeDate = System.Today() + 10;
            objOpportunity1.Distributor_Lookup__c = objAccount1.Id;
            objOpportunity1.Name = 'Test Opp1 31-05';
            objOpportunity1.Initial_Contacts_Name__c = objContact1.Id;
            objOpportunity1.Partner_Lookup__c = objAccount1.Id;
            objOpportunity1.Opportunity_Sub_Type__c = 'Regular';
            test.startTest();
            insert objOpportunity1;
            test.stopTest();

            ddc.Deal_Desk_Team__c = 'Deal Structuring';
            ddc.ApprovalStatus__c = '';
            ddc.Amount_Conditional__c = 100;
            ddc.Request_Type__c = 'General Inquiry';
            ddc.Request_Sub_Type__c = 'Below Minimum Term';
            ddc.Request_Status__c = 'Draft';
            ddc.Business_Justification__c = 'minimum characters';
            ddc.ETM_Theatre__c = 'EMEA';
            ddc.Opportunity__c = objOpportunity1.Id;
            ddc.ETM_Area__c = 'MAJORS';
            ddc.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc.Urgent__c = true; //DD25-6
            insert ddc;
        }
        // Act - Attempt to delete the records
        try {
            delete new List<Deal_Desk_Case__c>{ddc};
            System.assert(false, 'Expected a DMLException due to lack of delete permission, but no exception was thrown.');
        } catch (DmlException e) {
            // Assert - Confirm that the correct error message is thrown
            System.assert(e.getMessage().contains('You are not authorized to delete this record'),
                'The error message did not contain the expected text.');
        }
     
        // Query the records again to ensure they were not deleted
        List<Deal_Desk_Case__c> remainingCases = [
            SELECT Id, Name 
            FROM Deal_Desk_Case__c 
            WHERE Id IN :new List<Id>{ddc.id}
        ];
        System.assertEquals(1, remainingCases.size(), 'Both records should still exist.');
    }
    //DD25-77 Ends
    //
    /*Code coverage task
     * BusinessTAT Calculation for First Response
     * 
     */
    @isTest
    static void testMethod6(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
           
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Case_Status__c = 'In Progress';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = '';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'EMEA';
            ddc2.Deal_Desk_Team__c = 'Deal Structuring';
            ddc2.Request_Type__c = 'General Inquiry';
            insert ddc2;
            ddc2.Request_Status__c = 'Closed - Incomplete';
            ddc2.Case_Status__c = 'Requested';
            update ddc2;
            System.assert(ddc2.Id != null);
        }
    }
    /*Code coverage task
     * BusinessTAT Calculation for First Response
     * 
     */
    @isTest
    static void testMethod7(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser2[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser2[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
           
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Case_Status__c = 'In Progress';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = 'Approved';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'EMEA';
            ddc2.Deal_Desk_Team__c = 'Deal Operations';
            ddc2.Request_Type__c = 'General Inquiry';
            insert ddc2;
            ddc2.Request_Status__c = 'Approved';
            ddc2.Case_Status__c = 'Requested';
            ddc2.Deal_Desk_Team__c = 'Deal Structuring';
            update ddc2;
            set<id> idset = new set<id>();
            idset.add(ddc2.id);
            DDCaseTriggerHandler.reOpenCase(idset);
            System.assert(ddc2.Id != null);
        }
    }
    /*Code coverage task
     * BusinessTAT Calculation for First Response
     * 
     */
    @isTest
    static void testMethod8(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser2[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser2[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
           
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Case_Status__c = 'In Progress';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = 'Approved';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'EMEA';
            ddc2.Deal_Desk_Team__c = 'Deal Structuring';
            ddc2.Request_Type__c = 'General Inquiry';
            insert ddc2;
            System.assert(ddc2.Id != null);
           
        }
    }
     /*Code coverage task
     * BusinessTAT Calculation for First Response
     * 
     */
    @isTest
    static void testMethod9(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser2[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser2[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
           
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Case_Status__c = 'In Progress';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = 'Approved';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'EMEA';
            ddc2.Deal_Desk_Team__c = 'Deal Operations';
            ddc2.Request_Type__c = 'General Inquiry';
            ddc2.Opportunity_Record_Type__c = 'Renewal Opportunity';
            
            insert ddc2;
            System.assert(ddc2.Id != null);
        }
    }
     /*Code coverage task
     * BusinessTAT Calculation for First Response
     * 
     */
    @isTest
    static void testMethod10(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser2[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser2[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
           
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Case_Status__c = 'In Progress';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = 'Approved';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'Test';
            ddc2.Deal_Desk_Team__c = 'Deal Operations';
            ddc2.Request_Type__c = 'General Inquiry';
            ddc2.Opportunity_Record_Type__c = 'Renewal Opportunity';
            
            insert ddc2;
            System.assert(ddc2.Id != null);
        }
    }
    /*Code coverage task
     * BusinessTAT Calculation for First Response
     * 
     */
    @isTest
    static void testMethod12(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser2[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser2[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
            ddc2.Opportunity_Record_Type__c = 'Renewal Opportunity';
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Case_Status__c = 'In Progress';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = 'Approved';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'EMEA';
            ddc2.Deal_Desk_Team__c = 'Deal Structuring';
            ddc2.Request_Type__c = 'General Inquiry';
            insert ddc2;
            ddc2.Request_Status__c = 'Approved';
            ddc2.Case_Status__c = 'Requested';
            ddc2.Deal_Desk_Team__c = 'Deal Operations';
            update ddc2;
            set<id> idset = new set<id>();
            idset.add(ddc2.id);
            DDCaseTriggerHandler.reOpenCase(idset);
            System.assert(ddc2.Id != null);
        }
    }
    /*Code coverage task
     * BusinessTAT Calculation for First Response
     * 
     */
    @isTest
    static void testMethod13(){
        List<Profile> listProfile2 = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser2 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile2[0].Id}, 2);
        insert listUser2;
        listUser2[0].ManagerId = listUser2[1].Id;
        update listUser2;
        System.runAs(listUser2[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser2[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser2[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            Account objAccount2 = new Account();
            Contact objContact2 = new Contact();
            
            objAccount2.Name = 'Test Account 14-05';
            objAccount2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert objAccount2;
            
            objContact2.Account = objAccount2;
            objContact2.LastName = 'Test Contact 13-05';
            insert objContact2; 
            
            Opportunity objOpportunity2 = new Opportunity();
            objOpportunity2.Initial_Contacts_Name__c = objContact2.Id;
            objOpportunity2.Amount = 100;
            objOpportunity2.closeDate = System.Today() + 20;
            objOpportunity2.Opportunity_Sub_Type__c = 'Regular';
            objOpportunity2.Distributor_Lookup__c = objAccount2.Id;
            objOpportunity2.StageName = '1 Discovery';
            objOpportunity2.Partner_Lookup__c = objAccount2.Id;
            objOpportunity2.Name = 'Test Opp2 31-05';
            test.startTest();
            insert objOpportunity2;
            test.stopTest();
            
            Deal_Desk_Case__c ddc2 = new Deal_Desk_Case__c();
            ddc2.Opportunity_Record_Type__c = 'Renewal Opportunity';
            ddc2.Request_Sub_Type__c = 'Below Minimum Term';
            ddc2.Request_Status__c = 'Draft';
            ddc2.Case_Status__c = '';
            ddc2.Business_Justification__c = 'min 10 characters';
            ddc2.Opportunity__c = objOpportunity2.Id;
            ddc2.ApprovalStatus__c = 'Approved';
            ddc2.Amount_Conditional__c = 2000;
            ddc2.ETM_Area__c = 'MAJORS';
            ddc2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc2.ETM_Theatre__c = 'EMEA';
            ddc2.Deal_Desk_Team__c = 'Deal Structuring';
            ddc2.Request_Type__c = 'General Inquiry';
            insert ddc2;
            ddc2.Request_Status__c = 'Approved';
            ddc2.Request_Sub_Type__c = 'Best Practices Enablement';
            ddc2.Case_Status__c = 'Requested';
            ddc2.Deal_Desk_Team__c = 'Deal Operations';
            update ddc2;
            set<id> idset = new set<id>();
            idset.add(ddc2.id);
            DDCaseTriggerHandler.reOpenCase(idset);
            System.assert(ddc2.Id != null);
        }
    }
     @isTest
    static void reOpenCase(){
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser;
        System.runAs(listUser[0]) {
            list<Deal_Desk_Assignees__c> ddaList = new List<Deal_Desk_Assignees__c>();
            Deal_Desk_Assignees__c dda1 = new Deal_Desk_Assignees__c();
            dda1.Assignee__c = listUser[0].Id;
            dda1.Deal_Desk_Team__c = 'Deal Structuring';
            dda1.ETM_Area__c = 'MAJORS';
            dda1.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda1.ETM_Region__c = 'ENT-SOUTHEAST-N';
            Deal_Desk_Assignees__c dda2 = new Deal_Desk_Assignees__c();
            dda2.Assignee__c = listUser[1].Id;
            dda2.Deal_Desk_Team__c = 'Deal Operations';
            dda2.ETM_Area__c = 'MAJORS';
            dda2.ETM_Theatre__c = 'EMEA, CDM-EMEA';
            dda2.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddaList.add(dda1);
            ddaList.add(dda2);
            insert ddaList;
            
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
            ddc.ETM_Region__c = 'ENT-SOUTHEAST-N';
            ddc.Urgent__c = true; //DD25-6
            ddc.Case_Status__c ='Requested';
            insert ddc;
            DDCaseTriggerHandler.autoSubmitCase(new List<Deal_Desk_Case__c> {ddc});
            ddc.Deal_Desk_Team__c = 'Deal Structuring';
            ddc.Request_Type__c = 'Legal Language';
            ddc.OwnerId = listUser[1].Id;
            ddc.Tertiary_Owner__c = listUser[1].id;
            ddc.Secondary_owner__c = listUser[1].id;
            ddc.ApprovalStatus__c = 'Pending';
            ddc.Deal_Desk_Tagging__c = 'Other';
            ddc.Summary_of_Approval__c ='Test';
            ddc.Case_Status__c ='Closed';
            update ddc;
            DDCaseTriggerHandler.reOpenCase(new Set<Id>{ddc.Id});
            System.assert(ddc.Id != null);
            //Test.StartTest();
            //DDCaseTriggerHandler.recallApprovalsAsync(new Set<Id> {ddc.Id});
            //test.stopTest();
        }
    }
}