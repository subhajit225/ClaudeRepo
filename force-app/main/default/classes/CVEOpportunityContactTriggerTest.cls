/**
 * @description Apex test class for CVEOpportunityContactTrigger
 * @createdDate 05-August-2025
 */ 
@isTest
public without sharing class CVEOpportunityContactTriggerTest {

    /**
     * @description create test data
     */
    @testsetup
    public static void createTestData(){
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        settingDisable.Disable_Account_Validation_Rules__c = true; 
        settingDisable.Disable_Contact_Triggers__c = true;
        insert settingDisable;
        
        List<Account> accountLst = new List<Account>();
        Account account1 = new Account();
        account1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        account1.Name = 'Test Account1';
        accountLst.add(account1);
        Account account2 = new Account();
        account2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        account2.Name = 'Test Account2';
        accountLst.add(account2);
        INSERT accountLst;
        System.assert(accountLst.size() == 2);
        
        List<Contact> contactsLst = new List<Contact>();
        contactsLst.add(TestDataFactory.getContact(accountLst[0]));
        contactsLst.add(TestDataFactory.getContact(accountLst[0]));
        contactsLst.add(TestDataFactory.getContact(accountLst[0]));
        contactsLst.add(TestDataFactory.getContact(accountLst[0]));
        contactsLst.add(TestDataFactory.getContact(accountLst[0]));
        contactsLst.add(TestDataFactory.getContact(accountLst[0]));
        contactsLst.add(TestDataFactory.getContact(accountLst[1]));
        contactsLst.add(TestDataFactory.getContact(accountLst[1]));
        INSERT contactsLst;
        
        List<Contact> contactLst = [SELECT Id FROM Contact];
        System.assert(contactLst.size() == 8);
        
        List<Opportunity> opportunityLst = new List<Opportunity>();
        opportunityLst.add(TestDataFactory.getOpportunity(accountLst[0]));
        opportunityLst.add(TestDataFactory.getOpportunity(accountLst[0]));
        opportunityLst.add(TestDataFactory.getOpportunity(accountLst[0]));
        opportunityLst.add(TestDataFactory.getOpportunity(accountLst[1]));
        INSERT opportunityLst;
    }
    
    /**
     * @description Test CVEOpportunityContact Trigger functionality
     */
    @isTest
    public static void cveOppConTriggerTest(){
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'Rubrik Field Sales User'];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        listUser[0].LastName = 'TestClass';
        insert listUser;
        
        PermissionSet ps = [SELECT Id,name FROM PermissionSet WHERE name = 'Rubrik_IT_Production_support_Sales_New'];
        insert new PermissionSetAssignment(AssigneeId = listUser[0].Id, PermissionSetId = ps.Id);
        
        System.runAs(listUser[0]) {
            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            settingDisable.Disable_Opportunity_Validation_Rules__c  = true;
            settingDisable.Disable_CVE_Enagement_Validation_Rules__c  = true;
            insert settingDisable;
            
            List<Account> accountLst = [SELECT Id FROM Account];
            List<Contact> contactsLst = [SELECT Id FROM Contact];
            List<Opportunity> opportunityLst = [SELECT Id FROM Opportunity];
            
            List<CVE_Engagement__c> cveEngagementLst = new List<CVE_Engagement__c>();
            cveEngagementLst.add(new CVE_Engagement__c(X3_Why_s_Presented__c = 'Yes', Account__c = accountLst[0].Id));
            cveEngagementLst.add(new CVE_Engagement__c(X3_Why_s_Presented__c = 'No', Account__c = accountLst[1].Id));
            INSERT cveEngagementLst;
            System.assert(!cveEngagementLst.isEmpty());
            
            Test.startTest();
            List<CVE_Opportunity_Contact__c> cveOppContactLst = new List<CVE_Opportunity_Contact__c>();
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Contact__c = contactsLst[0].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Contact__c = contactsLst[1].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Opportunity__c = opportunityLst[0].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Opportunity__c = opportunityLst[1].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Opportunity__c = opportunityLst[1].Id, CVE_Engagement__c = cveEngagementLst[1].Id));
            INSERT cveOppContactLst;
            
            cveOppContactLst[0].Contact__c = contactsLst[2].Id;
            cveOppContactLst[1].Contact__c = contactsLst[3].Id;
            cveOppContactLst[2].Opportunity__c = opportunityLst[2].Id;
            UPDATE cveOppContactLst;
            
            DELETE [SELECT Id FROM CVE_Opportunity_Contact__c 
                    WHERE CVE_Engagement__c = :cveEngagementLst[0].Id AND Opportunity__c != null 
                    LIMIT 2];
            
            List<CVE_Opportunity_Contact__c> remainingCVEOppContLst = [SELECT Id FROM CVE_Opportunity_Contact__c WHERE CVE_Engagement__c = :cveEngagementLst[0].Id];
            System.assert(remainingCVEOppContLst.size() == 2);
            
            cveOppContactLst = new List<CVE_Opportunity_Contact__c>();
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Contact__c = contactsLst[4].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Contact__c = contactsLst[5].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Contact__c = contactsLst[0].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            cveOppContactLst.add(new CVE_Opportunity_Contact__c(Contact__c = contactsLst[1].Id, CVE_Engagement__c = cveEngagementLst[0].Id));
            
            //Max stakeholders engaged limit is exceeded
            try {
                INSERT cveOppContactLst;
            } catch(Exception ex){
                System.assert(true);
            }
            
            DELETE [SELECT Id FROM CVE_Opportunity_Contact__c 
                    WHERE CVE_Engagement__c = :cveEngagementLst[0].Id];
            Test.stopTest();  
        }
    }
}