/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   23-03-2021
* @Jira Ticket  :   CS21-288 - Update Case Notification Workflow Rule For ETM 2.0 Impacts
* @Description  :   Test class for AccountTerritoryUsersToCaseTeamHelper.cls
*/
@isTest(seeAllData = false)
public with sharing class AccountTerritoryUsersToCTMTest {

    @testSetup static void setup() {
        List<Territory2Model> lstOrgTerritories = [SELECT Id, Name FROM Territory2Model WHERE State = 'Active'];

        if(lstOrgTerritories.isEmpty()){
            List<Territory2Model> lstModel = ETM_TestDataFactory.createTerritoryModel('Test_FY',1);
            Insert lstModel;
            lstOrgTerritories.addAll(lstModel);
        }

        List<Territory2Type> lstType = [SELECT Id FROM Territory2Type LIMIT 1];

        List<Territory2> lstTerritories =  ETM_TestDataFactory.createTerritory('ETM_Territory', '12345', lstOrgTerritories[0].Id, lstType[0].Id, 1);
        insert lstTerritories;

        List<Profile> p = [SELECT Id FROM Profile WHERE Name IN ('Rubrik Customer Support User', 'Rubrik Customer Support Manager')];

        User newSEManager = new User();
        newSEManager.ProfileID = p[0].Id;
        newSEManager.EmailEncodingKey = 'ISO-8859-1';
        newSEManager.LanguageLocaleKey = 'en_US';
        newSEManager.TimeZoneSidKey = 'America/New_York';
        newSEManager.LocaleSidKey = 'en_US';
        newSEManager.Alias ='manager';
        newSEManager.FirstName = 'Test';
        newSEManager.LastName = 'Manager';
        newSEManager.Username = 'test.manager@testrubrik.com';
        newSEManager.Email = 'test.manager@testrubrik.com';
        newSEManager.IsActive = true;
        insert newSEManager;

        User newSEUser = new User();
        newSEUser.ProfileID = p[1].Id;
        newSEUser.EmailEncodingKey = 'ISO-8859-1';
        newSEUser.LanguageLocaleKey = 'en_US';
        newSEUser.TimeZoneSidKey = 'America/New_York';
        newSEUser.LocaleSidKey = 'en_US';
        newSEUser.Alias ='puser';
        newSEUser.FirstName = 'Test';
        newSEUser.LastName = 'User';
        newSEUser.Username = 'test.user@testrubrik.com';
        newSEUser.Email = 'test.user@testrubrik.com';
        newSEUser.IsActive = true;
        newSEUser.ManagerId = newSEManager.Id;
        insert newSEUser;

        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        User sysAdm = new User();
        sysAdm.ProfileID = sysAdminProfile.Id;
        sysAdm.EmailEncodingKey = 'ISO-8859-1';
        sysAdm.LanguageLocaleKey = 'en_US';
        sysAdm.TimeZoneSidKey = 'America/New_York';
        sysAdm.LocaleSidKey = 'en_US';
        sysAdm.Alias ='auser';
        sysAdm.FirstName = 'Test Admin';
        sysAdm.LastName = 'User';
        sysAdm.Username = 'admin.user@testrubrik.com';
        sysAdm.Email = 'admin.user@testrubrik.com';
        sysAdm.IsActive = true;
        insert sysAdm;

        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = lstTerritories[0].Id;
        uta.UserId = sysAdm.Id;
        uta.RoleInTerritory2 = 'Account Executive';
        insert uta;

        System.runAs(sysAdm) {
            insert new TriggerControl__c(Name='Case');

            Account acct = (Account)ShGl_TestFactory.createSObject(new Account(), null);
            acct.Rubrik_Sales_Engineer__c = newSEUser.Id;
            insert acct;

            Contact cont = new Contact(LastName='testCont');
            cont.Email='testcontact@test.com';
            cont.AccountId = acct.Id;
            insert cont;

            List<ObjectTerritory2Association> lstAssociation = ETM_TestDataFactory.createAssociationRecords(acct.Id, lstTerritories[0].Id, 'Territory2Manual', 1);
            insert lstAssociation;

            Case cs = new case();
            cs.Accountid = acct.Id;
            cs.contactid = cont.Id;
            cs.Subject ='JIRA12345';
            cs.JIRA_References_URL__c='SPARK-123456, SPARK-78910';
            cs.Jira_Reference_urls__c= 'SPARK-123456, SPARK-78910';
            cs.Origin = 'Alert';
            cs.close_survey_triggered__c = false;
            cs.Article_Created__c = false;
            cs.Resolution_Details__c  = 'test';
            cs.Next_Step__c = 'Test';
            cs.Current_Status__c  = 'testStatus';
            cs.Priority = 'P1';
            cs.Alert_Key__c = 'Alert case 1 key';
            insert cs;
        }
    }

    @isTest static void updateCtmOnAccTerrUserUpdateTest(){
        User u = [SELECT Id FROM User WHERE Username = 'admin.user@testrubrik.com'];

        UserTerritory2Association uta = [SELECT Id, RoleInTerritory2 FROM UserTerritory2Association WHERE UserId =: u.Id];

        uta.RoleInTerritory2 = 'SEM';
        update uta;
    }

    /*@isTest static void updateCtmOnAccTerrUserUpdateTest2(){
        User u = [SELECT Id FROM User WHERE Username = 'test.user@testrubrik.com'];

        UserTerritory2Association uta = [SELECT Id, RoleInTerritory2 FROM UserTerritory2Association WHERE UserId =: u.Id];

        uta.RoleInTerritory2 = 'SEM';
        update uta;

        uta.RoleInTerritory2 = 'Sales Engineer';
        update uta;
    }*/

    @isTest static void insertCtmOnNewAccTerrUserTest(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support User'];

        User seUser = new User();
        seUser.ProfileID = p.Id;
        seUser.EmailEncodingKey = 'ISO-8859-1';
        seUser.LanguageLocaleKey = 'en_US';
        seUser.TimeZoneSidKey = 'America/New_York';
        seUser.LocaleSidKey = 'en_US';
        seUser.Alias ='puser2';
        seUser.FirstName = 'Test';
        seUser.LastName = 'User2';
        seUser.Username = 'test.user2@testrubrik.com';
        seUser.Email = 'test.user2@testrubrik.com';
        seUser.IsActive = true;
        insert seUser;

        Territory2 t = [SELECT Id FROM Territory2 WHERE DeveloperName = 'ETM_Territory_0'];

        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = t.Id;
        uta.UserId = seUser.Id;
        uta.RoleInTerritory2 = 'Account Executive';
        insert uta;
    }

    @isTest static void deleteCtmOnAccTerrUserDeleteTest(){
        User u = [SELECT Id FROM User WHERE Username = 'admin.user@testrubrik.com'];

        UserTerritory2Association uta = [SELECT Id, RoleInTerritory2 FROM UserTerritory2Association WHERE UserId =: u.Id];
        delete uta;
    }

    @isTest static void deleteInsertCTMOnAccountChangeTest(){
        List<Territory2Model> lstOrgTerritories = [SELECT Id, Name FROM Territory2Model WHERE State = 'Active'];

        if(lstOrgTerritories.isEmpty()){
            List<Territory2Model> lstModel = ETM_TestDataFactory.createTerritoryModel('Test_FY',1);
            Insert lstModel;
            lstOrgTerritories.addAll(lstModel);
        }

        List<Territory2Type> lstType = [SELECT Id FROM Territory2Type LIMIT 1];

        List<Territory2> lstTerritories =  ETM_TestDataFactory.createTerritory('ETM_Territory2', '23456', lstOrgTerritories[0].Id, lstType[0].Id, 1);
        insert lstTerritories;

        List<Profile> p = [SELECT Id FROM Profile WHERE Name IN ('Rubrik Customer Support User', 'Rubrik Customer Support Manager')];

        User newSEManager = new User();
        newSEManager.ProfileID = p[0].Id;
        newSEManager.EmailEncodingKey = 'ISO-8859-1';
        newSEManager.LanguageLocaleKey = 'en_US';
        newSEManager.TimeZoneSidKey = 'America/New_York';
        newSEManager.LocaleSidKey = 'en_US';
        newSEManager.Alias ='manager2';
        newSEManager.FirstName = 'Test';
        newSEManager.LastName = 'Manager2';
        newSEManager.Username = 'test.manager2@testrubrik.com';
        newSEManager.Email = 'test.manager2@testrubrik.com';
        newSEManager.IsActive = true;
        insert newSEManager;

        User newSEUser = new User();
        newSEUser.ProfileID = p[1].Id;
        newSEUser.EmailEncodingKey = 'ISO-8859-1';
        newSEUser.LanguageLocaleKey = 'en_US';
        newSEUser.TimeZoneSidKey = 'America/New_York';
        newSEUser.LocaleSidKey = 'en_US';
        newSEUser.Alias ='puser2';
        newSEUser.FirstName = 'Test';
        newSEUser.LastName = 'User2';
        newSEUser.Username = 'test.user2@testrubrik.com';
        newSEUser.Email = 'test.user2@testrubrik.com';
        newSEUser.IsActive = true;
        newSEUser.ManagerId = newSEManager.Id;
        insert newSEUser;

        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = lstTerritories[0].Id;
        uta.UserId = newSEUser.Id;
        uta.RoleInTerritory2 = 'Account Executive';
        insert uta;

        User sysAdm = [SELECT Id FROM User WHERE Username = 'admin.user@testrubrik.com'];

        System.runAs(sysAdm) {
            Account acct = (Account)ShGl_TestFactory.createSObject(new Account(), null);
            insert acct;

            Contact cont = new Contact(LastName='testCont');
            cont.Email='testcontact2@test.com';
            cont.AccountId = acct.Id;
            insert cont;

            List<ObjectTerritory2Association> lstAssociation = ETM_TestDataFactory.createAssociationRecords(acct.Id, lstTerritories[0].Id, 'Territory2Manual', 1);
            insert lstAssociation;

            Case c = [SELECT Id, AccountId FROM Case];
            c.AccountId = acct.Id;
            update c;
        }
    }
}