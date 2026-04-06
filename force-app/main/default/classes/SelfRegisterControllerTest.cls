/*
 * Class Name :- SelfRegisterControllerTest
 * Visualforce Page :- SelfRegisterController
 * Author :- Shiva Sharma
 * Created Date :- 16-05-2018
 * Description : This Controller is being used in SelfRegisterController Test Class
 * Coverage :- 92%
 // ********************Change Logs ******************************************************************************************************************************************************
 * 
 * Modified By          Date        Description 
 * 
 * 
 // ********************Change Logs Ends**************************************************************************************************************************************************
*/
@isTest
public class SelfRegisterControllerTest {
    @testSetup static void setup() {
        testDataFactoryClass.createUser();
        testDataFactoryClass.createCustomSettings();
        testDataFactoryClass.createContactWithUser(2);
    }
    
    //No Domian
    @isTest static void testMethod1() {
        List<Account> act = testDataFactoryClass.createAccount(1,0);
        testDataFactoryClass.createOpporunity(act);
        SelfRegisterController src = new SelfRegisterController();
        src.usrInformation.firstName = 'testF';
        src.usrInformation.lastName = 'testl';
        src.usrInformation.email = 'test@test.com';
        src.usrInformation.title = 'testTitle';
        src.usrInformation.phone = 'testPhone';
        src.validateLoginInfo();
        
        SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );
        //System.assertEquals(1, [select count() from Customer_Registration_Request__c]);
    }
    
    //Account with Domain AND Customer Account
    @isTest static void testMethod2a() {
        List<Account> act = testDataFactoryClass.createAccount(1,0);
        testDataFactoryClass.createOpporunity(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        SelfRegisterController.activateUser(u.id);
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'test@test1.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );
                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    
    //Account with Domain AND Customer Account
    @isTest static void testMethod2() {
        List<Account> act = testDataFactoryClass.createAccount(1,0);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'test@test1.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    //Account with Domain AND Customer Account AND InactiveUser
    @isTest static void testMethod3() {
        List<Account> act = testDataFactoryClass.createAccount(1,0);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'testuser@testuser1.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    //Account with Domain AND Customer Account AND activeUser
    @isTest static void testMethod4() {
        List<Account> act = testDataFactoryClass.createAccount(1,0);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'testuser@testuser2.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    
    //Account with Domain AND partner Account
    @isTest static void testMethod5() {
        List<Account> act = testDataFactoryClass.createAccount(1,1);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'test@test2.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    
    //Account with Domain AND Prospect Account
    @isTest static void testMethod6() {
        List<Account> act = testDataFactoryClass.createAccount(1,1);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'test@test3.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    
    //Account with Domain AND Prospect Account
    @isTest static void testMethod6a() {
        List<Account> act = testDataFactoryClass.createAccount(1,1);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'test@test4.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    //Account with Domain AND partner Account AND InactiveUser
    @isTest static void testMethod7() {
        List<Account> act = testDataFactoryClass.createAccount(1,1);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'testuser@testuser1.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    //Account with Domain AND partner Account AND activeUser
    @isTest static void testMethod8() {
        List<Account> act = testDataFactoryClass.createAccount(1,1);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'testuser@testuser2.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    //Account with Domain AND prospect Account AND InactiveUser
    @isTest static void testMethod9() {
        List<Account> act = testDataFactoryClass.createAccount(1,2);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'testuser@testuser1.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    //Account with Domain AND Customer Account AND activeUser
    @isTest static void testMethod10() {
        List<Account> act = testDataFactoryClass.createAccount(1,2);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
                SelfRegisterController src = new SelfRegisterController();
                src.usrInformation.firstName = 'testF';
                src.usrInformation.lastName = 'testl';
                src.usrInformation.email = 'testuser@testuser2.com';
                src.usrInformation.title = 'testTitle';
                src.usrInformation.phone = 'testPhone';
                src.validateLoginInfo();
                SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );

                //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    //Account with Domain AND Customer Account AND activeUser
    @isTest static void testMethod11() {
        List<Account> act = testDataFactoryClass.createAccount(1,2);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        Id rcId = [Select id from recordType where Name='Partner/Distributor' AND SobjectType = 'Account'].id;
        List<Account> accounts =  [select id,RecordTypeId,Partner_Agreement_Status__c from account];
        for(Account a : accounts){
            a.RecordTypeId =rcId;
            a.Partner_Agreement_Status__c = 'Unsigned';
        }
        update accounts;
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
            SelfRegisterController src = new SelfRegisterController();
            src.usrInformation.firstName = 'testF';
            src.usrInformation.lastName = 'testl';
            src.usrInformation.email = 'testuser2134121@testuser2.com';
            src.usrInformation.title = 'testTitle';
            src.usrInformation.phone = 'testPhone';
            SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );
            
            //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    
    //Account with Domain AND Customer Account AND activeUser
    @isTest static void testMethod12() {
        List<Account> act = testDataFactoryClass.createAccount(1,2);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        Id rcId = [Select id from recordType where Name='Partner/Distributor' AND SobjectType = 'Account'].id;
        List<Account> accounts =  [select id,RecordTypeId,Partner_Agreement_Status__c from account];
        for(Account a : accounts){
            a.RecordTypeId =rcId;
            a.Partner_Agreement_Status__c = 'Signed - Active';
        }
        update accounts;
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        System.runAs(u){
            test.startTest();
            SelfRegisterController src = new SelfRegisterController();
            src.usrInformation.firstName = 'testF';
            src.usrInformation.lastName = 'testl';
            src.usrInformation.email = 'testuser2134121@testuser2.com';
            src.usrInformation.title = 'testTitle';
            src.usrInformation.phone = 'testPhone';
            SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );
            
            //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    
    //Account with Domain AND Customer Account AND activeUser
    @isTest static void testMethod13() {
        List<Account> act = testDataFactoryClass.createAccount(1,2);
        testDataFactoryClass.createOpporunitywithAccountEntitlement(act);
        Id rcId = [Select id from recordType where Name='Partner/Distributor' AND SobjectType = 'Account'].id;
        List<Account> accounts =  [select id,RecordTypeId,Partner_Agreement_Status__c from account];
        for(Account a : accounts){
            a.RecordTypeId =rcId;
            a.Partner_Agreement_Status__c = 'Signed - Inactive';
        }
        update accounts;
        
        Profile csop = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Support Manager'];
        User newSEManager = new User();
        newSEManager.ProfileID = csop.Id;
        newSEManager.EmailEncodingKey = 'ISO-8859-1';
        newSEManager.LanguageLocaleKey = 'en_US';
        newSEManager.TimeZoneSidKey = 'America/New_York';
        newSEManager.LocaleSidKey = 'en_US';
        newSEManager.Alias ='manager';
        newSEManager.FirstName = 'Test';
        newSEManager.LastName = 'Manager';
        newSEManager.Username = '32157#kiet.duong@rubrik.com';
        newSEManager.Email = 'kiet.duong@rubrik.com';
        newSEManager.IsActive = true;
        insert newSEManager;

        System.runAs(newSEManager){
            Account deniedAcc = new Account(Name = 'Denied Acc', GTC__c = 'Denied');
            INSERT deniedAcc;

            String timestamp = String.valueof(DateTime.now().getTime());
            List<WL_Domain__c> domainLst = new List<WL_Domain__c>{new WL_Domain__c(Name='unique.com',Account__c = deniedAcc.Id),
                                                                    new WL_Domain__c(Name='testDm.com',Account__c = accounts[1].Id),
                                                                    new WL_Domain__c(Name='testDm.com',Account__c = accounts[0].Id)};
            INSERT domainLst;
            SelfRegisterLightning.getAccountGTC('unique.com',timestamp);
            SelfRegisterLightning.getAccountGTC('testDm.com',timestamp);
            SelfRegisterLightning.getAccountGTC('sample.com',timestamp);
        }
        
        user u = [select id,email from user where Alias ='tUser' Limit  1];
        String externalId = '';
        System.runAs(u){
            test.startTest();
            SelfRegisterController src = new SelfRegisterController();
            src.usrInformation.firstName = 'testF';
            src.usrInformation.lastName = 'testl';
            src.usrInformation.email = 'testuser2134121@testuser2.com';
            src.usrInformation.title = 'testTitle';
            src.usrInformation.phone = 'testPhone';
            SelfRegisterLightning.validateLoginInfo(src.usrInformation.email,src.usrInformation.firstName ,src.usrInformation.lastName ,src.usrInformation.title ,src.usrInformation.phone );
            
            //stem.assertEquals(2, [select count() from Contact]);
            test.stopTest();
        }
    }
    
}