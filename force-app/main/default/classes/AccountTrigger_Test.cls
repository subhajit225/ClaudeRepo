@isTest
public class AccountTrigger_Test {
    
    @testSetup
    static void setupData(){
        Okta_Attributes__c customSet = new Okta_Attributes__c();
        customSet.Access_Token__c='test123';
        customSet.Customer_User_AppId__c='0oa74j6tt8UcKoESq1d7';
        customSet.Group_Id__c='00g6tq1v7rafytctf1d7';
        customSet.Partner_User_AppId__c='0oa79x7bg7u6C9upE1d7';
        customSet.Name = 'Okta Attributes';
        customSet.Okta_Base_URL__c = 'https://onepassport-dev.rubrik.com.sandbox';
        customSet.Disable_User_Sync__c = false;
        INSERT customSet;
    }

    //Test Account Creation
    static testMethod void testMethodAccountCreation () {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='AdminUser' + DateTime.now().getTime() + '@rubrik.com'
        );
        insert u;
        System.runAs(u){
            insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);

            //create single account
            Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
            insert act;
            
            List<Account> actList = [SELECT Id FROM Account];
            System.assertEquals(1, actList.size());

            //create a list of accounts - size 10
            List<Account> newActList = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 10, null);
            /*for (Account ant : newActList) {
                system.debug('ant :: '+ant);
            }*/
            insert newActList;
            
            List<Account> actList1 = [SELECT Id FROM Account];
            System.assertEquals(11, actList1.size());
            
            //create single account with dynamic values
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Arpit Account',
                'Type' => 'Customer',    
                'BillingStreet' => '444 Saratoga Ave',
                'BillingCity' => 'Santa Clara',
                'BillingState' => 'California',
                'BillingCountry' => 'United States',
                'BillingPostalCode' => '95050'
            };
            Account act2 = (Account) ShGl_TestFactory.createSObject(new Account(), m);
            insert act2;
            
            Account act2Q = [SELECT Id, Name, Type FROM Account WHERE Id = :act2.Id];
            System.assertEquals('Test Arpit Account', act2Q.Name);
            System.assertEquals('Customer', act2Q.Type);
        }
        
    }

    //Test Account Owner Update
    static testMethod void testMethodAccountOwnerUpdate () {
        
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE,Allow_account_Transfer__c = true);
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1]; 
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;

        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='AdminUser' + DateTime.now().getTime() + '@rubrik.com'
        );
        insert u;
        
        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        List<Account> actList = [SELECT Id FROM Account];
        System.assertEquals(1, actList.size());
        
        Test.startTest();
        System.RunAs(u){ 
            act.OwnerId = usr.Id;
            update act;
        }
        Test.stopTest();

        Account actUpd = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :act.Id];
        System.assertEquals(act.Name, actUpd.Name);
        System.assertEquals(usr.Id, actUpd.OwnerId);
        
    }

    //Test Account Owner Update - with Opportunities
    static testMethod void testMethodAccountOwnerUpdateWtOppty () {

        ShGl_TestFactoryHelper.insertTriggerControls();
            
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE,Allow_account_Transfer__c = true);

        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='AdminUser' + DateTime.now().getTime() + '@rubrik.com'
        );
        insert u;

        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        insert cnt;

        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'Initial_Contacts_Name__c' => cnt.Id,
            'StageName' => '1 Discovery',    
            'ForecastCategoryName' => 'Best Case',   
            'RecordTypeId' => Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId()
        };
        List<Opportunity> opptyList = (List<Opportunity>) ShGl_TestFactory.createSObjectList(new Opportunity(), 4, oppMap);
        insert opptyList;
        System.RunAs(u){ 
            Test.startTest();
            act.OwnerId = usr.Id;
            update act;
        }
        Test.stopTest();

        Account actUpd = [SELECT Id, Name, OwnerId FROM Account WHERE Id = :act.Id];
        List<Opportunity> opptyUpdedList = [SELECT Id, Name, OwnerId, Previous_Account_Owner__c 
                                FROM Opportunity 
                                WHERE AccountId = :act.Id];//removed Previous_Owner__c from SOQL as part of SAL26-873
        System.assertEquals(act.Name, actUpd.Name);
        //System.assertEquals(usr.Id, actUpd.OwnerId);
        
    }

}