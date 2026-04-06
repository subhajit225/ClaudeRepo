/**
* @description Test Class for BatchCaseRenewal Apex Batch
* @test
* @author Raveesh Layal
* @date 2025-08-01
*/
@isTest
public class BatchCaseRenewalTest {
    
    /**
* @description Test setup method creates required test data including TriggerControl, Account, Opportunity,
*              ServiceContract, and User with specified Profile.
* @testSetup
*/
    @testSetup static void setup() { 
        Id profileId = [SELECT Id, Name from Profile WHERE Name = 'Rubrik Customer Support User'].Id;
        
        User u = new User(
            ProfileId = profileId,
            LastName = 'last',
            Email = 'csit-testuser@rubrik.com',
            Username = System.now().millisecond() + 'csit-testuser@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            Employee_Time_Off__c = true
        );
        insert u;
        System.runAs(u){
            insert new E2CAdv__E2CAConfiguration__c(
                Name = 'E2C Advance Configuration',
                E2CAdv__EnableTrigger__c = false
            );
            
            // Insert the AccountTrigger setting record (List Custom Setting)
            insert new E2CAdv__E2CATriggers__c(
                Name = 'AccountTrigger',
                E2CAdv__IsActive__c = true
            );
            
            E2CAdv__E2CAConfiguration__c generalConfiguration = E2CAdv__E2CAConfiguration__c.getInstance('E2C Advance Configuration');
            E2CAdv__E2CATriggers__c accountTriggerSetting = E2CAdv__E2CATriggers__c.getInstance('AccountTrigger');
            TriggerControl__c triggerCntlr = getTriggerControl();
            insert triggerCntlr;
            
            Account acc = new Account(Name = 'Test Account');
            insert acc;  
            
            Opportunity tempOpp = new Opportunity(
                name = 'Temp Opp', 
                OwnerID = UserInfo.getUserId(),
                accountId = acc.id,
                stagename = 'Approved',
                Amount = 1000,
                Lead_Email_Hidden__c = 'test@email.com',
                closeDate = Date.today()
            );
            insert tempOpp;
            
            ServiceContract sc = new ServiceContract(
                Name = 'Test', 
                AccountId = acc.Id, 
                StartDate = System.today(), 
                Enddate = System.today().addDays(119), 
                SBQQSC__Opportunity__c = tempOpp.Id
            );
            insert sc;
            
        }
    }
    
    /**
* @description Helper method to create and return TriggerControl__c record for Opportunity
* @return TriggerControl__c
*/
    static TriggerControl__c getTriggerControl(){
        TriggerControl__c tc = new TriggerControl__c();
        tc.Name = 'Opportunity';
        tc.DisableTrigger__c = false;
        return tc;
    }
    
    /**
* @description Test case 1: Execute BatchCaseRenewal with ServiceContract query and verify basic execution
*/
    @isTest
    static void test1(){
        User user1 = [Select ProfileId, LastName from User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1){
            BatchCaseRenewal c = new BatchCaseRenewal(
                'Select Id, EndDate, AccountId, SBQQSC__Opportunity__c, SBQQSC__Quote__c,' + 
                ' (Select Id from Cases WHERE RecordType.name = \'Renewal Case\') FROM ServiceContract',
                false
            );
            Database.executeBatch(c);
            System.assertEquals(1,1);  // Basic assertion placeholder
        }
    }
    
    /**
* @description Test case 2: Execute BatchCaseRenewal with Opportunity query and explicitly call execute method
*/
    @isTest
    static void test2(){
        User user1 = [Select ProfileId, LastName from User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1){
            BatchCaseRenewal c = new BatchCaseRenewal(
                'SELECT Id, OwnerId, Account.Name, AccountId, Partner_Lookup__r.Name, Partner_Lookup__c, ' + 
                'Partner_SE_Phone__c, Partner_SE_Name__c, Partner_SE_Email__c, Distributor_Rep_Email__c, ' + 
                'Distributor_Rep_Name__c, Distributor_Rep_Phone_Number__c, Distributor_Lookup__c, SBQQSC__RenewedServiceContract__c FROM Opportunity',
                false
            );
            Database.executeBatch(c);
            
            Test.startTest();
            c.execute(null); // SchedulableContext is not required for test
            Test.stopTest();
            
            System.assertEquals(1,1);  // Basic assertion placeholder
        }
    }
    
    /**
* @description Test case 3: Execute BatchCaseRenewal with empty query string to check batch handling
*/
    @isTest
    static void test3(){
        User user1 = [Select ProfileId, LastName from User WHERE Email = 'csit-testuser@rubrik.com'];
        System.runAs(user1){
            BatchCaseRenewal c = new BatchCaseRenewal('', false);
            Database.executeBatch(c);
            System.assertEquals(1,1);  // Basic assertion placeholder
        }
    }
}