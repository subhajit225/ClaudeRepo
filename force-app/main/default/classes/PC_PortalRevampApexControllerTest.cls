@isTest(SeeAllData=false) 
public with sharing class PC_PortalRevampApexControllerTest {
    @IsTest(SeeAllData=true) static void testMethod7(){
        Contact con;
        UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
        User portalAccountOwner1 = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'testpuser2@test.com',
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        
        System.runAs(portalAccountOwner1){
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Reseller';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            insert acc;
    
            con = TestDataFactory.getContact();
            con.AccountId = acc.Id;
            insert con;
        }

        String uniqueName = TestDataFactory.getUniqueName();
        User runAsUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Partner Community User'].Id,
            LastName = 'last',
            Email = uniqueName +'@rubrik.com',
            Username = uniqueName +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = uniqueName.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = vUserRole.Id,
            ContactId = con.Id,
            Start_Date__c=System.Today().adddays(-30)         
        );
        //insert runAsUser; 

        System.runAs(runAsUser){
            //PC_PortalNavigationApexController.getAudiencesRecord(runAsUser.Id);

            List<Partner_Page_Configuration__c> configList = new List<Partner_Page_Configuration__c>();
            Partner_Page_Configuration__c config1 = new Partner_Page_Configuration__c();
            config1.Name = 'test config1';
            config1.Menu_Label__c = 'Home';
            config1.Menu_Group__c = '';
            config1.Order__c = 1;
            config1.Image_Type__c = 'Menu';
            configList.add(config1);

            Partner_Page_Configuration__c config2 = new Partner_Page_Configuration__c();
            config2.Name = 'test config2';
            config2.Menu_Label__c = 'Sell';
            config2.Menu_Group__c = 'Sell';
            config2.Order__c = 1;
            config2.Image_Type__c = 'Menu Item';
            configList.add(config2);

            insert configList;

            PC_PortalNavigationApexController.getMenuConfigs(runAsUser.Id);
        }
    }

    /*@IsTest static void testMethod8(){
        Account acc = TestDataFactory.getAccount();
        acc.name = 'Test New Account';
        acc.Type = 'Reseller';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        insert acc;

        Account acc1 = TestDataFactory.getAccount();
        acc1.name = 'Test New Account Pros';
        acc1.Type = 'Prospect';
        insert acc1;

        Contact con1 = TestDataFactory.getContact();
        con1.AccountId = acc1.Id;
        insert con1;

        Contact con = TestDataFactory.getContact();
        con.AccountId = acc.Id;
        insert con;

        Opportunity opp = TestDataFactory.getOpportunity(acc1,con1);
        opp.Partner_Lookup__c = acc.Id;
        opp.CloseDate = System.today();
        insert opp;

        String uniqueName = TestDataFactory.getUniqueName();
        User runAsUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Partner Community User'].Id,
            LastName = 'last',
            Email = uniqueName +'@rubrik.com',
            Username = uniqueName +'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = uniqueName.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = vUserRole.Id,
            ContactId = con.Id,
            Start_Date__c=System.Today().adddays(-30)         
        );
        insert runAsUser; 

        System.runAs(runAsUser){
            PC_PartnerOppPipelineApexController.getPartnerOppPipeline(runAsUser.Id, null, null, 'test', null);
        }
    }*/
}