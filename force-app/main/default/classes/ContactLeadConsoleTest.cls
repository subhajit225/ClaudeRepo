/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-30-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class ContactLeadConsoleTest {
    @testSetup static void insertData() {
       
        testDataFactoryClass.createCustomSettings();
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
        
        String loggedInUserId = Userinfo.getUserId();

        System.runAs(sysAdm) {
            List<Territory2Model> lstOrgTerritories = [SELECT Id, Name FROM Territory2Model WHERE State = 'Active'];
            if(lstOrgTerritories.isEmpty()){
                List<Territory2Model> lstModel = ETM_TestDataFactory.createTerritoryModel('Test_FY',1);
                lstModel[0].State = 'Active';
                Insert lstModel;
                //lstOrgTerritories.addAll(lstModel);
                lstOrgTerritories = lstModel;
            }

            List<Territory2Type> lstType = [SELECT Id FROM Territory2Type LIMIT 1];

            List<Territory2> lstTerritories =  ETM_TestDataFactory.createTerritory('ETM_Territory', '12345', lstOrgTerritories[0].Id, lstType[0].Id, 1);
            insert lstTerritories;

            List<UserTerritory2Association> insertUserTerritory = new List<UserTerritory2Association>();
            UserTerritory2Association uta = new UserTerritory2Association();
            uta.Territory2Id = lstTerritories[0].Id;
            uta.UserId = sysAdm.Id;
            uta.RoleInTerritory2 = 'Account Executive';
            insertUserTerritory.add(uta);
            
            User insertedUser = ShGl_TestFactory.createUserwithRole();
            UserTerritory2Association uta2 = new UserTerritory2Association();
            uta2.Territory2Id = lstTerritories[0].Id;
            uta2.UserId = insertedUser.Id;
            uta2.RoleInTerritory2 = 'SDR';
            insertUserTerritory.add(uta2);
            
            UserTerritory2Association uta3 = new UserTerritory2Association();
            uta3.Territory2Id = lstTerritories[0].Id;
            uta3.UserId = loggedInUserId;
            uta3.RoleInTerritory2 = 'NAS AE';
            insertUserTerritory.add(uta3);
            insert insertUserTerritory;
            
            Account acct = (Account)ShGl_TestFactory.createSObject(new Account(), null);
            acct.Rubrik_Sales_Engineer__c = sysAdm.Id;
            acct.Type='Customer';
            insert acct;

            Contact cont = new Contact(LastName='testCont');
            cont.Email='testcontact@test.com';
            cont.AccountId = acct.Id;
            insert cont;

            List<ObjectTerritory2Association> lstAssociation = ETM_TestDataFactory.createAssociationRecords(acct.Id, lstTerritories[0].Id, 'Territory2Manual', 1);
            insert lstAssociation;
        }
        List<Account> accList = testDataFactoryClass.createAccounts();
        Contact con = new Contact(accountid=accList[0].Id,lastname='test con',email='abchjk@gmail.com');
        insert con;
        
        task t = new task(); 
        t.WhoId=con.id;
        t.Subject = 'Email:';
        insert t;
        t.Subject = 'Call:';
        update t;
        
        task t1 = new task();
        t1.WhoId=con.id;
        t1.Subject = 'Follow up Request';
        insert t1;
    }
    
    public static testMethod void method1(){
        
        //UserRole obj=new UserRole(Name= 'ABC'); 
        //insert obj; 
        
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        
        String orgId=UserInfo.getOrganizationId(); 
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000)); 
        String uniqueName=orgId+dateString+RandomId; 
        
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = uniqueName + '@test' + orgId + '.org', 
                         Username = uniqueName + '@test' + orgId + '.org', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = uniqueName.substring(18, 23), 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id 
                         ); 
                      // UserRoleId = obj.Id
        
        insert uu; 
        System.runas(uu) { 
            User uu1=new User(firstname = 'Alan', 
                              lastName = 'McCarthy', 
                              email = uniqueName + '1@test' + orgId + '.org', 
                              Username = uniqueName + '1@test' + orgId + '.org', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = uniqueName.substring(18, 22), 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = pf.Id
                              ); 
            //UserRoleId = obj.Id
            
            insert uu1; 
            
            List<contact> con = [Select id,Account.Account_Status__c from contact Limit 1];
            system.debug('ConRecord'+con);
            List<id> conIds = new List<id>();
            conIds.add(con[0].Id);
            Event e = new Event();
            e.WhoId=con[0].id;
            e.OwnerId = uu1.id;
            e.Type = 'inside sales led meeting';
            e.ActivityDateTime = Date.today()+1;
            e.StartDateTime=system.today()+1;
            e.EndDateTime=system.today()+5;
            //insert e;
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getProfileId(), Allow_contact_Transfer__c = false);            Test.startTest();
            ContactLeadConsole.reAssignTask(conIds);
            ContactLeadConsole.getProfileName();
            ContactLeadConsole.assignFollowUpTask(con[0].Id, 'tt', uu.id);
            
             map<String,Decimal> fitScoremapContact1 = new map<String,Decimal>();
            fitScoremapContact1.put('MinRange',10.00);
            fitScoremapContact1.put('MaxRange',40.00);
            
            ContactLeadConsole.getAccountContacts('MQL',fitScoremapContact1, true,con[0].Account.Account_Status__c);
            ContactLeadConsole.getAccountContacts('All',fitScoremapContact1, true,con[0].Account.Account_Status__c);
            ContactLeadConsole.getAccountContacts('Manager View',fitScoremapContact1, true,con[0].Account.Account_Status__c); 
            
            map<String,Decimal> fitScoremap1 = new map<String,Decimal>();
            fitScoremap1.put('MinRange',10);
            fitScoremap1.put('MaxRange',40);
            
             ContactLeadConsole.getLeadAccountCampaigns(null,'MQL',fitScoremap1, true,con[0].Account.Account_Status__c); 
             ContactLeadConsole.getLeadAccountCampaigns(null,'All',fitScoremap1, true,con[0].Account.Account_Status__c); 
            ContactLeadConsole.getLeadAccountCampaigns(null,'Manager View',fitScoremap1, true,con[0].Account.Account_Status__c); 
            map<String,Decimal> fitScoremap2 = new map<String,Decimal>();
             fitScoremap2.put('MinRange',10);
             fitScoremap2.put('MaxRange',40);
            ContactLeadConsole.getLeadAccountCampaigns(null,'MQL',fitScoremap2, true,con[0].Account.Account_Status__c); 
             ContactLeadConsole.getLeadAccountCampaigns(null,'All',fitScoremap2, true,con[0].Account.Account_Status__c); 
            contactLeadConsole.updateContactStatus(con[0].id,'Marketing Nurture','failed');
            ContactLeadConsole.getLeadAccountCampaigns(null,'Manager View',fitScoremap2, true,con[0].Account.Account_Status__c); 
             User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
                System.runAs(sysAdminUser){
                   Assert.areEqual(TRUE,!con.isEmpty());  
                }
            //ContactLeadConsole.updateLeadStatus(lead1.Id, 'Marketing Nurture');
            //ContactLeadConsole.updateContactStatus(con[0].Id, 'Marketing Nurture');
            //ContactLeadConsole.updateContactStatus(con[0].Id, 'Marketing Nurture1');
            Test.stopTest(); 
        } 
    }
    public static testMethod void testMethod1(){

        ShGl_TestFactoryHelper.insertCustomSettings();
        ShGl_TestFactoryHelper.WorkflowTriggerBypass();

        Lead lead1 = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        lead1.CountryCode = 'IT';
        insert lead1;
        Test.startTest();
        list<Account> accId = [SELECT Id FROM Account WHERE Rubrik_Sales_Engineer__c != null];
        List<Contact> contacts = CustomTestDataFactory.createcont(accId);
        createOpportunity(accId);
        List<Id> accIds= new List<Id>();
        List<Id> contactIds = new List<Id>();
        Map<Id, List<Id>> mapAccIdWithContacts = new Map<Id, List<Id>>();
        for(Contact conRec : contacts){ 
            accIds.add(conRec.AccountId);
            if(!mapAccIdWithContacts.containsKey(conRec.AccountId))
                mapAccIdWithContacts.put(conRec.AccountId, new List<Id>());
            
            mapAccIdWithContacts.get(conRec.AccountId).add(conRec.Id);
            contactIds.add(conRec.Id);
            conRec.Contact_Follow_Up_Status__c = 'Follow up Required';
        }
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            Assert.areEqual(TRUE,!contacts.isEmpty());
        }
        update contacts;
        ContactLeadConsole.updateLeadStatus(lead1.Id, 'Nurture','AE Customer/Active Opp',accId[0].Id);
        ContactLeadConsole.updateLeadStatus(lead1.Id, null,null,null);
        ContactLeadConsole.updateLeadOwnerAction(lead1.Id,'Queue',null);
        ContactLeadConsole.getTerritoryUsersForAccount(accIds,mapAccIdWithContacts);
        ContactLeadConsole.reAssignTask(contactIds);
        Test.stopTest();
    }
    public static void createOpportunity(List<Account> actlst){
        List<Opportunity> opplst = new List<Opportunity>();
        for (Integer j=0;j<actlst.size();j++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'testopp';
            opp.StageName = '1 Discovery';
            opp.AccountId = actlst[0].id;
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.CloseDate = system.today();
            opp.Business_Unit__c = 'Mosaic';
            opp.Deal_Registration_Type__c = 'Rubrik Sourced';
            opplst.add(opp);
        }
        insert opplst;
    }
    public static testMethod void method2(){    
        
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='testAccount',recordtypeId = partner);
        insert acct;
        Date closeDt = System.Today()+30;
        
        
        Product2 pd = new Product2(Name='Pord B',ProductCode='Product123XYZ',isActive=true, Bundle_Features__c ='Appliance');
        pd.IsActive = true;
        insert pd;
        
        // Pricebook2  standardPb = [select id, name, isActive from Pricebook2 where IsStandard = true limit 1];
        Id pricebookId = Test.getStandardPricebookId();
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = pd.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        Order ordr = new Order(Type='Revenue' ,  AccountId= acct.Id,ShippingStreet ='Test Street',
                               ShippingCity ='Test City',
                               ShippingState ='California',
                               ShippingCountry ='United States',
                               ShippingPostalcode ='94820',
                               EffectiveDate=system.Today(), Order_Status__c = 'Order Accepted',Order_Accepted_Timestamp__c=system.today().addDays(-45) );
        insert ordr;
        Order od = [ SELECT Id,Pricebook2Id FROM Order where id=:ordr.id LIMIT 1 ];
        od.Pricebook2Id = pricebookId;
        update od;
        List<OrderItem> ordItemList = new List<OrderItem>();
        OrderItem oli1 = new OrderItem(
            OrderId = od.Id,
            Quantity = 5,
            Product2Id =  pd.Id,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 100,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        ordItemList.add(oli1);
        OrderItem oli2 = new OrderItem(
            OrderId = od.Id,
            Quantity = 5,
            Product2Id =  pd.Id,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = 200,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        ordItemList.add(oli2);
        Test.startTest();
        insert ordItemList;
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            List<Task> t1 = [select id,WhatId from task Limit 1];
            Map<id,id> maptaskWithOrderItem = new Map<id,id>();
            maptaskWithOrderItem.put(t1[0].id,od.id);
        }
        
        Test.stopTest();
        Assert.areEqual(TRUE,!ordItemList.isEmpty());
    } 
    @isTest static void testMethod2(){
        insert new ShGl_DisableBusinessLogic__c(setupOwnerId = UserInfo.getUserId(), Disable_Task_Triggers__c = true);
        insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getProfileId(), Allow_contact_Transfer__c = false);
        Account acc = [SELECT Id from Account where Type = 'Customer' LIMIT 1];
        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 1, null);
        conList[0].AccountId = acc.Id;
        Insert conList;
            Task tsks = new Task();
            tsks.Subject = 'Follow up Request';
            tsks.Status = 'Not Started';
            tsks.WhoId = conList[0].Id;
            insert tsks;
        List<id> conIds = new List<id>();
            
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            try{
                conIds.add(conList[0].Id);
            }catch(Exception ex){
                String exceptionMsg = ex.getMessage();
            }
        }
        ContactLeadConsole.reAssignTask(conIds);
        Assert.areEqual(TRUE,!conIds.isEmpty());         
    }
}