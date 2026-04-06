/********************************************************************************************************
* Name              : AccountTriggerHelper_Test 
* Purpose           : AccountTriggerHelper_Test is Used for Testing AccountTriggerHelper Class
*********************************************************************************************************/
@isTest
public class AccountTriggerHelper_Test{
    @testSetup
    static void setupDataForAccountTriggerHelper(){
    List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        UserRole roleId = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        List<User> listUser = TestDataFactory.getUsers('testClassUser665544', new Set<Id>{listProfile[0].Id}, 1);
        listUser[0].UserRoleId = roleId.Id;
        insert listUser;
        System.runAs(listUser[0]){
            insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = listUser[0].Id,
                                                    Disable_Account_Validation_Rules__c = true,
                                                    Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                    Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                    Disable_Opportunity_Validation_Rules__c = True);
            List<Territory2> TerritoryList = new List<Territory2>();
            for(Territory2 terr : [select id,Adaptive_Territory_Id__c,ParentTerritory2.Adaptive_Territory_Id__c,ParentTerritory2Id,ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c,ParentTerritory2.ParentTerritory2.ParentTerritory2Id,ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory'and Adaptive_Territory_Id__c!='' and DeveloperName!='Unassigned'limit 2])
            {
                TerritoryList.add(terr);
            }
            
            insert new TriggerControl__c(name='Account',DisableTrigger__c=false);
            ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid(), Disable_Account_Triggers__c = false);
        }
    }
    
    static User createUser() { 
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'Rubrik Field Sales User']; //Rubrik Field Sales User
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        User sysAdmin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'sys1Admin@randomtestdomain.com',
            Alias = 'xmen',
            Email = System.now().millisecond() + 'random1.email@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        Database.insert(sysAdmin);
        return sysAdmin;
    }   
    
    static User createPortalUser(contact con) { 
        user sysAdmin = createUserAdmin();
        User communityUser = new user();
        system.runas(sysAdmin){
            Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'Rubrik Customer Community Super Login User'];
            communityUser = new User(Alias = 'systet11', Email='systest12AB@initial.com', ContactId = con.Id,
                                            EmailEncodingKey='UTF-8', LastName='systest1', LanguageLocaleKey='en_US',
                                            LocaleSidKey='en_US', ProfileId = profile1.Id, Phone = con.Phone,
                                            TimeZoneSidKey='America/Los_Angeles', UserName='systest112378114@test1885.com');
            Database.insert(communityUser);
        }
        return communityUser;
    }
    static User createUserAdmin() {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; //System Administrator
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        User sysAdmin = new User(
            EmailEncodingKey = 'UTF-8',
            Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
            UserRoleId = portalRole.Id,
            Username = System.now().millisecond() + 'sys1Admin123@randomtestdomain.com',
            ProfileId = profile1.Id,
            Alias = 'xmen',
            Firstname = 'test',Lastname = 'test',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_US',TimeZoneSidKey = 'America/Chicago');
        Database.insert(sysAdmin);
        return sysAdmin;
    }
    static testMethod void testPatchManagerAssignmentForInsert(){
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=true);
        insert new SetupCompanyMaster__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_CM__c = true);
        //insert new TriggerControl__c(name='Account',DisableTrigger__c=false);
        List<Account> actList = new List<Account>();
        
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',type='Customer');
        actList.add(act);
        insert actList;
        /* actList[0]. BillingPostalCode ='78923409' ;
update actList; */
        List<PatchManager__c> lstPatchs = new List<PatchManager__c>();
        for(integer i = 0; i<5; i++){
            PatchManager__c patch=new PatchManager__c();
            patch.City__c='California';
            if(i==1){
                patch.Zip_code__c='302022';
                patch.State__c='CA';
            }
            lstPatchs.add(patch);
        }
        insert lstPatchs;
        Map<String, List<PatchManager__c>> patchMap = new Map<String, List<PatchManager__c>>();
        patchMap.put('TestString',lstPatchs);
        Test.startTest();
        AccountTriggerHelper.patchManagerAssignment (actList, patchMap, true);
        shareOppFocusedPartnerAccController.testPasser();
        Test.stopTest();
        System.assertNotEquals(NULL, actList);
    }
    
    static testMethod void testAccountValidation(){
        List<SetupCompanyMaster__c> CMSetup = new List<SetupCompanyMaster__c>();
        CMSetup.add(new SetupCompanyMaster__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_CM__c = true));
        CMSetup.add(new SetupCompanyMaster__c(setupownerid = userinfo.getuserid(),Disable_grain_update_validation__c = false));
        insert new ShGl_DisableFunctionalityLogic__c(setupownerid = userinfo.getuserid(), Disable_Account_Old_Trigger__c = true);
        insert CMSetup;
        List<Territory2> TerritoryList = new List<Territory2>();
        for(Territory2 terr : [select id,Adaptive_Territory_Id__c,ParentTerritory2.Adaptive_Territory_Id__c,ParentTerritory2Id,ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c,ParentTerritory2.ParentTerritory2.ParentTerritory2Id,ParentTerritory2.ParentTerritory2.ParentTerritory2.Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory'and Adaptive_Territory_Id__c!='' and DeveloperName!='Unassigned'limit 2])
        {
            TerritoryList.add(terr);
        }
        insert new TriggerControl__c(name='Account',DisableTrigger__c=false);
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid(), Disable_Account_Triggers__c = false);
        List<Account> actList = new List<Account>();
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',type='Customer',Disable_Auto_OwnerAssignment__c=true,Adaptive_Territory_Id__c = TerritoryList[0].Adaptive_Territory_Id__c);
        actList.add(act);
        insert actList;
        List<ObjectTerritory2Association> OTAList = new List<ObjectTerritory2Association>();
        if(TerritoryList[0].Adaptive_Territory_Id__c!= null)
            OTAList.add(new ObjectTerritory2Association(ObjectId =actList[0].id , Territory2Id =TerritoryList[0].id, AssociationCause ='Territory2Manual'));
        insert OTAList ;
        actList[0].Cluster_ID__c ='ClusterId' ;
        actList[0].Disable_Auto_OwnerAssignment__c = false;
        actList[0].Pooled_SE_Override__c=true;
        actList[0].Adaptive_Territory_Id__c=TerritoryList.size()>1 ? TerritoryList[1].Adaptive_Territory_Id__c : '';
        actList[0].ETM_Area__c='STRATEGIC-CENTRAL;STRATEGIC-SOUTHEAST;STRATEGIC-WEST;STRATEGIC-NORTHEAST;ENT-HEALTHCARE;ENT-CORE-NORTHEAST;ENT-CORE-SOUTH;ENT-CORE-WESTCENTRAL'; //added by kajal
        actList[0].Scale_Eligible__c=false;
        actList[0].Insight_Matches__c = 'test';
        actList[0].Insight_Matches_Updated__c = System.now();
        update actList[0];
        actList[0].RASP__c=true;
        update actList[0];
        Test.startTest();
        AccountTriggerHelper.accountValidation (actList,false);
        Test.stopTest();
        System.assertNotEquals(NULL, actList);
    }
    static testMethod void testUpdateReleaseMethod(){
        user sysAdmin = createUserAdmin();
        user sysAdmin1 = createUserAdmin();
        List<Account> actList = new List<Account>();
        system.runas(sysAdmin){
            Account act = new Account(Name = 'TestAcct23',Website='www.test3.com',type='Customer');
            actList.add(act);
            insert actList;
            Contact objContact = new Contact();
            objContact.AccountId = actList[0].Id;
            objContact.LastName = 'Test Contact 31-05';
            insert objContact;
        }
        Contact con = [select id,phone, AccountId from contact where lastname='Test Contact 31-05' limit 1];
        user u = createPortalUser(con);
        Account acc = [select id, OwnerId from account where id =:con.AccountId limit 1];
        system.runas(sysAdmin){
            Test.startTest();
            territory2 terr = [select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory'and Adaptive_Territory_Id__c!='' and DeveloperName!='Unassigned' limit 1];
            UserTerritory2Association UTA2 = new UserTerritory2Association();
            UTA2.UserId = sysAdmin.Id; 
            UTA2.Territory2Id = terr.Id; 
            UTA2.RoleInTerritory2 = 'Account Executive';
            insert UTA2;
            
            acc.RASP__c=true;
            update acc;
            List<Account> accList = new List<Account>();
            accList.add(acc);
            set<Id> accIdsForTartUpdate = new set<Id>();
            accIdsForTartUpdate.add(acc.Id);
            set<Id> acctOwnerdIds = new set<Id>();
            acctOwnerdIds.add(acc.OwnerId);
            AccountTriggerHelper.populateEtmTartValues(accIdsForTartUpdate,acctOwnerdIds,accList);
            AccountTriggerHelper.updateAccountHistoryRelatedFields(accIdsForTartUpdate);
            
            Test.stopTest();
        }
        u.Releases__c = '5.0.0-DA1-583';
        update u;
        system.runas(sysAdmin){
            acc.RASP__c=false;
            update acc;
        }
        System.assertNotEquals(NULL, actList);
        
    }
    static testMethod void testPatchManagerAssignment(){
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=false);
        List<Account> actList = new List<Account>();
        
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',type='Customer');
        act.rerun_PatchManager__c =true;
        actList.add(act);
        insert actList;
        
        List<PatchManager__c> lstPatch = new List<PatchManager__c>();
        for(integer i = 0; i<5; i++){
            PatchManager__c patch=new PatchManager__c();
            patch.City__c='California';
            if(i==1){
                patch.Zip_code__c='302022';
                patch.State__c='CA';
            }
            lstPatch.add(patch);
        }
        insert lstPatch;
        
        Map<String, List<PatchManager__c>> patchMap = new Map<String, List<PatchManager__c>>();
        patchMap.put('TestString',lstPatch);
        
        Test.startTest();
        AccountTriggerHelper.patchManagerAssignment (actList, patchMap, true);
        Test.stopTest();
        System.assertNotEquals(NULL, actList);
    }
    
    static testMethod void testKeepOpportunityOwnerSame (){
        testDataFactoryClass.createCustomSettings();
        
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=false);
        List<Account> actList = new List<Account>();
        Map<Id, Account> actMap = new Map<Id, Account>();
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',/* OwnerId = userId, */type='Customer');
        act.rerun_PatchManager__c =true;
        actList.add(act);
        insert actList;
        List<opportunity> oppList =  testDataFactoryClass.createOpporunity(actList);
        for(Account acc:actList){
            actMap.put(acc.id,acc);
        }
        Test.startTest();
        AccountTriggerHelper.keepOpportunityOwnerSame(actMap,null);
        Test.stopTest();
        System.assertNotEquals(NULL, actMap);
    }
    
    static testMethod void testAccountTeamMember(){
        //UserRole vUserRole = new UserRole(DeveloperName = 'RubrikDeveloper2', Name = 'My RoleTest');
        //insert vUserRole;
        User u1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
            LastName = 'lasttest',
            Email = 'lafgrtesf'+'@rubrik.com',
            Username = 'lafgrtesf'+'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'lafgrtesf'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = vUserRole.Id,
            Start_Date__c=System.Today().adddays(-30)
            
        );
        insert u1;
        User u2 = new User(
            ProfileId = u1.ProfileId,
            LastName = 'last',
            Email = 'gjhhsjij'+'@rubrik.com',
            Username = 'gjhhsjij'+'@rubrik.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'gjhhsjij'.substring(0,5),
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            //UserRoleId = u1.UserRoleId ,
            Start_Date__c=System.Today().adddays(-30)
        );
        insert u2;
        List<Account> actList = new List<Account>();
        system.runas(u1){
            insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=true);
            Account act = new Account(Name = 'TestAcct1',Rubrik_Sales_Engineer__c = u2.Id);
            actList.add(act);
            insert actList;
            Test.startTest();
            //AccountTriggerHelper.createAccountTeamMember(actList);
            Test.stopTest();
            System.assertNotEquals(NULL, actList);
        }
    }
    
    // 4/10/2019 Part of next deployment cycle
    // added by Varsha for SF-2743 -startTest
    static testMethod void testOrderStatusToUpdate(){
        Set<Id> AccID = new Set<ID>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account testAccount = new Account(RecordTypeId = partnerRecordTypeId);
        testAccount.Name='Test Account1' ;
        insert testAccount;
        testAccount.Contract_Negotiation__c = true;
        testAccount.EULA_revision_Required__c = true;
        update testAccount;
        insert new TriggerControl__c(name='Opportunity',DisableTrigger__c=false);
        FlowControll.opportunityTriggerHandler = false;
        Opportunity oppr = TestDataFactory.getOpportunity(testAccount);
        oppr.partner_lookup__c=testAccount.Id;
        oppr.Installation_Assigned_To__c ='FE Install';
        insert oppr;
        FlowControll.opportunityTriggerHandler = true;
        Order ord = new Order();
        ord.Order_Status__c='Shipped';
        ord.EffectiveDate=date.ValueOf('1968-09-21');
        ord.Accountid= testAccount.id;
        ord.status='pending';
        ord.opportunityId = oppr.ID;
        ord.Hold_Code__c = 'Contract in negotiations';
        ord.Type = 'Revenue';
        insert ord;
        ord.Order_Status__c='On Hold';
        ord.Hold_Code__c = 'EULA Revision Required';
        update ord;
        AccID.add(testAccount.id);
        Map<Id, List<string>> mapAccountWithHoldChanged = new Map<Id, List<string>> ();
        mapAccountWithHoldChanged.put(testAccount.id, new List<string> ());
        if(testAccount.EULA_revision_Required__c == true){
            mapAccountWithHoldChanged.get(testAccount.Id).add('Eula Req True');
        }
        if(testAccount.Contract_Negotiation__c == true){
            mapAccountWithHoldChanged.get(testAccount.Id).add('contract Negotiation');
        } 
        Test.startTest();
        AccountTriggerHelper.updateOrderStatusAndHoldCode(AccID,mapAccountWithHoldChanged);
        Test.stopTest();
        System.assertNotEquals(NULL, AccID);
        
    }
    
    static testMethod void testsendEmailAlertforOrders()
    {
        Set<Id> AccID1 = new Set<ID>();
        Account testAccount = new Account();
        testAccount.Name='Test AccountEmail1' ;
        insert testAccount;
        Opportunity testOpportunity = TestDataFactory.getOpportunity(testAccount);
        
        Order ord = new Order();
        ord.Order_Status__c='pending';
        ord.EffectiveDate=date.ValueOf('1968-09-21');
        ord.Accountid= testAccount.id;
        ord.status='pending';
        ord.opportunityId = testOpportunity.ID;
        insert ord;
        ord.Order_Status__c='On Hold';
        ord.Hold_Code__c ='Contract in negotiations' ;
        update ord;
        AccID1.add(testAccount.id);
        Test.startTest();
        AccountTriggerHelper.sendEmailAlertforOrders(AccID1);
        Test.stopTest();
        System.assertNotEquals(NULL, AccID1);
        
    }
    
    public static testMethod void testUpdateReleases(){
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        
        Account testAccount = new Account();
        testAccount.Name='Test AccountEmail1';
        testAccount.RASP__c = false;
        insert testAccount;
        
        Test.startTest();
        testAccount.RASP__c = true;
        update testAccount;
        //AccountTriggerHelper.validateRASP(NewAccList,OldAccMAp);
        Test.stopTest();
        System.assertNotEquals(false, testAccount.RASP__c);
    }
    static testMethod void testupdateSmartHandentitlements()
    {    insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
     set<Id> testAccId = New set<Id>();
     Account acct = new Account(
         Name = 'Test Account',
         Phone = '123-456-7890',
         AccountNumber = 'Test',
         Deactivate_Smart_Hands__c =false,
         BillingStreet = '123 street',
         BillingCity = 'Santa Clara',
         BillingState = 'California',
         BillingPostalCode = '95050',
         BillingCountry = 'United States'
     );
     insert acct;
     
     Map<String, Object> cntMap = new Map<String, Object> {
         'AccountId' => acct.Id
             };
                 Contact con = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
     insert con;
     
     Map<String, Object> caseMap = new Map<String, Object> {
         'Subject' => 'RMA Test data',
             'ContactId' => con.Id,
             'Jira_Reference_urls__c' => 'test',
             'Priority' => 'P2',
             'AccountId' => acct.Id
             
             };
                 Case caseTest = (Case) ShGl_TestFactory.createSObject(new Case(), caseMap);
     insert caseTest;
     
     List<Product2> products = new List<Product2> {
         //apliance
         new Product2(Name = 'RBK-R348-01',
                      ProductCode = 'RBK-R348-01',
                      Category__c = 'Platform',
                      Family = 'R300',
                      Support_Type__c = 'PREM',
                      //Product_NIC_Type__c='SFP+',
                      Appliance_Model__c = 'R348',
                      Appliance_Model_HW__c = 'R348',
                      Create_Asset_Entitlement__c = true,
                      Asset_Priority__c = 0,
                      IsActive = true
                     )
             };
                 insert products;
     List<Asset> assets = new list<Asset> {
         new Asset(Name = 'SN1', SW_Version__c = '0.1', SerialNumber = 'SN1', Serial_Number__c = 'SN1', Product2Id = products[0].Id, Accountid = acct.Id),
             new Asset(Name = 'SN2', SW_Version__c = '0.2', SerialNumber = 'SN2', Serial_Number__c = 'SN2', Product2Id = products[0].Id, Accountid = acct.Id),
             new Asset(Name = 'SN3', SW_Version__c = '0.3', SerialNumber = 'SN3', Serial_Number__c = 'SN3', Product2Id = products[0].Id, Accountid = acct.Id),
             new Asset(Name = 'SN4', SW_Version__c = '0.4', SerialNumber = 'SN4', Serial_Number__c = 'SN4', Product2Id = products[0].Id, Accountid = acct.Id),
             new Asset(Name = 'SN5', SW_Version__c = '0.5', SerialNumber = 'SN5', Serial_Number__c = 'SN5', Product2Id = products[0].Id, Accountid = acct.Id),
             new Asset(Name = 'SN6', SW_Version__c = '0.6', SerialNumber = 'SN6', Serial_Number__c = 'SN6', Product2Id = products[0].Id, Accountid = acct.Id)
             };
                 insert assets;
     
     testAccId.add(acct.Id);
     RMA_Order__c rma = new RMA_Order__c(parent_case__c =caseTest.id,appliance__c =assets[0].serialNumber, Appliance_Quantity__c=1,
                                         Service_Type__c='Next Business Day: 8am', ShippingCountry__c ='United States', ShippingState__c='CA',
                                         Shipping_Street__c='test', Shipping_City__c='palo Alto', Shipping_Zip_Postal_Code__c='12098',
                                         Ship_To_Contact_Name__c='test contact', Ship_To_Email__c='test@test.com', Ship_To_Name__c=acct.id,Send_Smart_Hands_Service__c = true,Entitled_for_Smart_Hands_Service__c=true,Date_of_Smart_Hands_Arrival__c= system.Today() + 5,Time_of_Smart_Hands_Tech_Arrival__c= '15:00');
     Test.startTest();
     insert rma ;
     acct.Deactivate_Smart_Hands__c =true;
     Update acct;
     //AccountTriggerHelper.updateEntitledForSmartHands(testAccId);
     //rma.Entitled_for_Smart_Hands_Service__c=false;
     Test.stopTest();
     System.assertNotEquals(false, acct.Deactivate_Smart_Hands__c);
     
    }
    
    static testMethod void testupdateOpptyDDNotes (){
        //testDataFactoryClass.createCustomSettings();
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=false);
        List<Account> actList = new List<Account>();
        List<Id> actIdList = new List<Id>();
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',/* OwnerId = userId, */type='Customer');
        act.rerun_PatchManager__c =true;
        actList.add(act);
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account partAcc = new Account(RecordTypeId = partnerRecordTypeId);
        partAcc.Name='Test Account1';
        actList.add(partAcc);
        insert actList;
        List<opportunity> oppList =  testDataFactoryClass.createOpporunity(actList);
        List<SBQQ__Quote__c> quoteLst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = new SBQQ__Quote__c(SBQQ__Account__c = act.Id);
        SBQQ__Quote__c quoteRecError = new SBQQ__Quote__c(SBQQ__Account__c = act.Id);
        
        for (Opportunity oppObj : oppList) {
            oppObj.Opportunity_Type__c = 'New Customer';
            oppObj.Opportunity_Sub_Type__c = 'Regular';
            oppObj.Partner_Lookup__c = partAcc.Id;
            quoteRec.SBQQ__Opportunity2__c = oppObj.Id;
            quoteRecError.SBQQ__Opportunity2__c = oppObj.Id;
            
        }
        update oppList;
        quoteLst.add(quoteRec);
        quoteLst.add(quoteRecError);
        insert quoteLst;
        
        for(Account acc:actList){
            acc.Account_Deal_Desk_Notes__c = 'Test DDNotes';
            acc.ETM_Territory__c = 'TEST-TERRITORY-1';
            actIdList.add(acc.id);
        }
        
        Test.startTest();
        update actList;
        AccountTriggerHelper.updateQuotesDealNotesfuture(actIdList);
        Test.stopTest();
        List<opportunity> updOppList = [select Id, Account_Deal_Desk_Notes__c from Opportunity where Id in :oppList];
        System.assertEquals(actList[0].Account_Deal_Desk_Notes__c, updOppList[0].Account_Deal_Desk_Notes__c);
        List<SBQQ__Quote__c> quoteList = [select Id, Account_Deal_Desk_Notes__c from SBQQ__Quote__c where Id IN : quoteLst];
    } 
    
    static testMethod void testManageAccTeam(){
        User user1 = createUser();
        user User2 = createUserAdmin();
        user User3 = createUserAdmin();
        List<Account> actList = new List<Account>();
        System.RunAs(User3){
            insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
            insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=false);
            Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',/* OwnerId = userId, */type='Customer');
            act.rerun_PatchManager__c =true;
            actList.add(act);
            Account act1 = new Account(Name = 'TestAcct2',Website='www.test3.com',/* OwnerId = userId, */type='Customer');
            act1.rerun_PatchManager__c =true;
            actList.add(act1);
            insert actList;
            
            actList[0].Rubrik_Sales_Engineer__c = User1.Id;
            actList[0].Account_Alliance_BDM_Lookup__c = User2.Id;
            actList[1].Rubrik_Sales_Engineer__c = User2.Id;
            actList[1].Account_Alliance_BDM_Lookup__c = User1.Id;
            Test.startTest();
            update actList;
            actList[1].Rubrik_Sales_Engineer__c = null;
            actList[1].Account_Alliance_BDM_Lookup__c = null;
            update actList[1];
            Test.stopTest();
            System.assertEquals(1, [SELECT count() from AccountTeamMember where AccountId=:actList[0].Id and UserId = :User1.Id and TeamMemberRole IN('Sales Engineer','Alliance BDM')]);
            System.assertEquals(0, [SELECT count() from AccountTeamMember where AccountId=:actList[1].Id and UserId = :User2.Id and TeamMemberRole IN('Sales Engineer','Alliance BDM')]);
        }
    }
    
    static testMethod void testAfterUpdateChildAccCount(){
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        List<Account> actList = new List<Account>();
        //create single account
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        //create single account
        Account act2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act2.ParentId = act1.Id;
        Account act3 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act3.ParentId = act1.Id;
        //actList.add(act1);
        actList.add(act2);
        actList.add(act3);
        insert actList;
        //Account parentAcc1 = [select Number_of_Child_Accounts__c from Account where Id =: act1.Id];
        //System.assertEquals(2, parentAcc1.Number_of_Child_Accounts__c);
        Test.startTest();
        act3.ParentId = null;
        update act3;
        Test.stopTest();
        Account parentAcc2 = [select Number_of_Child_Accounts__c from Account where Id =: act1.Id];
        System.assertEquals(1, parentAcc2.Number_of_Child_Accounts__c);
    }
    
    static testMethod void testAfterDeleteChildAccCount(){
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new SOX_Objects_Delete_Access__c(setupownerid = userinfo.getOrganizationId(), Allow_Account_Delete__c = TRUE);
        List<Account> actList = new List<Account>();
        //create single account
        Account acct1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert acct1;
        //create single account
        Account acct2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct2.ParentId = acct1.Id;
        Account act3 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act3.ParentId = acct1.Id;
        //actList.add(acct1);
        actList.add(acct2);
        actList.add(act3);
        insert actList;
        
        //Account parentAcc1 = [select Number_of_Child_Accounts__c from Account where Id =: acct1.Id];
        //System.assertEquals(2, parentAcc1.Number_of_Child_Accounts__c);
        
        Test.startTest();
        delete act3;
        Test.stopTest();
        Account parentAcc2 = [select Number_of_Child_Accounts__c from Account where Id =: acct1.Id];
        System.assertEquals(1, parentAcc2.Number_of_Child_Accounts__c);
    }
    
    static testMethod void testAfterUnDeleteChildAccCount(){
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE);
        insert new SOX_Objects_Delete_Access__c(setupownerid = userinfo.getOrganizationId(), Allow_Account_Delete__c = TRUE);
        List<Account> actList = new List<Account>();
        //create single account
        Account act1 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act1;
        //create single account
        Account act2 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act2.ParentId = act1.Id;
        Account act3 = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act3.ParentId = act1.Id;
        //actList.add(act1);
        actList.add(act2);
        actList.add(act3);
        insert actList;
        
        delete act3;
        //Account parentAcc1 = [select Number_of_Child_Accounts__c from Account where Id =: act1.Id];
        //System.assertEquals(1, parentAcc1.Number_of_Child_Accounts__c);
        Test.startTest();
        undelete act3;
        Test.stopTest();
        Account parentAcc2 = [select Number_of_Child_Accounts__c from Account where Id =: act1.Id];
        System.assertEquals(2, parentAcc2.Number_of_Child_Accounts__c);
    }
    
    static testMethod void testPopulateEtmTartValues (){
        List<Territory2> TerritoryList = new List<Territory2>();
        TerritoryList.add([select id,Adaptive_Territory_Id__c,Internal_Territory_Name__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned'limit 1]);
        
        User user1 = createUser();
        user User2 = createUserAdmin();
        user User3 = createUserAdmin();
        UserTerritory2Association UTA = new UserTerritory2Association(Territory2Id = TerritoryList[0].Id,
                                                                      RoleInTerritory2 = 'Account Executive',
                                                                      UserId = user1.Id);
        insert UTA;
        
        List<Account> actList = new List<Account>();
        System.RunAs(User3){
            insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE, Allow_account_Transfer__c = TRUE);
            insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=false);
            Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',/* OwnerId = userId, */type='Customer');
            act.rerun_PatchManager__c =true;
            actList.add(act);
            insert actList;
            Account insAct1 = [Select Id, ETM_Territory__c from Account where Id =:actList[0].Id];
            System.assertEquals(null,insAct1.ETM_Territory__c);
            
            //Update the Owner
            actList[0].OwnerId = User1.Id;
            Test.startTest();
            update actList;
            Test.stopTest();
            Account updAct1 = [Select Id, ETM_Territory__c from Account where Id =:actList[0].Id];
            System.assertEquals(TerritoryList[0].Internal_Territory_Name__c,updAct1.ETM_Territory__c);
            //OpportunityUtil.testCoverage();
        }
    }
    static testMethod void testMethod_AccountOwnerUpdateWtOppty () { 
        
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = UserInfo.getOrganizationId(), Disable_Account_Old_Trigger__c = TRUE, Allow_account_Transfer__c = TRUE);
        insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getOrganizationId(),
                                                Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                Disable_SBQQ_Quote_Triggers__c = True,
                                                Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                Disable_Opportunity_Validation_Rules__c = True,
                                                Disable_Opportunity_Triggers__c = True);
        
        Profile pf = [SELECT Id FROM profile WHERE name='System Administrator' limit 1]; 
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        system.debug('usr :: '+usr);
        flowControll.UserTriggerHandler=false;
        insert usr;
        flowControll.UserTriggerHandler=true;
        Account pact = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert pact;
        
        //create single account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        system.debug('act :: '+act);
        insert act;
        Id partnerrecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
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
        System.RunAs(usr){ 
            Test.startTest();
            
            act.Disable_Auto_OwnerAssignment__c = true;
            act.recordtypeId = partnerrecTypeId;
            update act;
            List<Opportunity> opptyUpdedList = [SELECT Id, Name, OwnerId, Previous_Account_Owner__c 
                                                FROM Opportunity 
                                                WHERE AccountId = :act.Id];//removed Previous_Owner__c from SOQL as part of SAL26-873
            opptyUpdedList[0].Partner_Lookup__c = act.Id;
            update opptyUpdedList;
            System.debug('\n\n~~~~~User: ' + UserInfo.getName());
            PatchManager.ROUTE_ON_INSERT_ACCOUNT = true;
            act.OwnerId = usr.Id;
            act.Focused_Partner__c = true;
            act.Type = 'Customer';
            act.Contract_Negotiation__c = true;
            act.EULA_revision_Required__c = true;
            act.ParentId = pact.Id;
            act.Enforce_Admin_User__c = true;
            act.AWS_GCP_Cloud_Alliance_BDM__c = usr.Id; //Added as part of SAL26-105
            act.MSFT_OCI_Cloud_Alliance_BDM__c = usr.Id; //Added as part of SAL26-105
            //act.Account_Alliance_BDM_Lookup__c = usr.Id; //Commented as part of SAL26-101
            act.Account_Deal_Desk_Notes__c = 'ghjjs';
            act.Account_SAM__c = usr.Id;
            act.Disable_Auto_OwnerAssignment__c = false;
            update act;
            Set<Id> accIds = new Set<id>();
            accIds.add(act.Id);
            accIds.add(pact.Id);
            AccountTriggerHelper.sendEmailAlertforOrders(accIds);
            List<Account> accList =  new List<Account>();
            accList.add(act);
            Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(accList, PatchManager.ACCOUNT);
            AccountTriggerHelper.patchManagerAssignment(accList, patchMap, false);
            AccountTriggerHelper.notifyToParentAccountOwner(accList,accIds);
            act.OwnerId = userinfo.getUserId();
            update act;
            Test.stopTest();
            System.assertNotEquals(NULL, accList);
        }
        //System.assertEquals(act.Name, actUpd.Name);
        //System.assertEquals(usr.Id, actUpd.OwnerId);
        
    }
    
    static testMethod void testOrderStatusToUpdate2(){
        List<User> listUser = [select Id from user where Firstname like '%testClassUser665544%'];
        Set<Id> AccID = new Set<ID>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account testAccount = new Account(RecordTypeId = partnerRecordTypeId);
        testAccount.Name='Test Account1' ;
        Test.startTest();
        insert testAccount;
        testAccount.Contract_Negotiation__c = true;
        testAccount.EULA_revision_Required__c = false;
        testAccount.IsPartner = true;
        testAccount.Name='Test Account1 Update';
        testAccount.accountBuyingStage6sense__c ='Purchase';
        System.runAs(listUser[0]) {
          update testAccount;
        }
        insert new TriggerControl__c(name='Opportunity',DisableTrigger__c=false);
        FlowControll.opportunityTriggerHandler = false;
        Opportunity oppr = TestDataFactory.getOpportunity(testAccount);
        oppr.partner_lookup__c=testAccount.Id;
        oppr.Installation_Assigned_To__c ='FE Install';
        insert oppr;
        FlowControll.opportunityTriggerHandler = true;
        Order ord = new Order();
        ord.Order_Status__c='Shipped';
        ord.EffectiveDate=date.ValueOf('1968-09-21');
        ord.Accountid= testAccount.id;
        ord.status='pending';
        ord.opportunityId = oppr.ID;
        ord.Hold_Code__c = 'Contract in negotiations';
        ord.Type = 'Revenue';
        ord.Pricebook2Id = Test.getStandardPricebookId(); 
        insert ord;
        ord.Order_Status__c = 'On Hold';
        ord.Hold_Code__c = 'EULA Revision Required';
        update ord;
        Product2 sampleProduct = new Product2(Name = 'RBK-R348-01',ProductCode = 'RBK-R348-01',Category__c = 'Platform',Family = 'R300',Product_Subtype__c='GO CNV',Support_Type__c = 'PREM',Appliance_Model__c = 'R348',Appliance_Model_HW__c = 'R348',Create_Asset_Entitlement__c = true,Asset_Priority__c = 0,IsActive = true);
        insert sampleProduct;
        List<PricebookEntry>entries = new List<PricebookEntry>();
        entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id =sampleProduct.Id, IsActive = true, UnitPrice = 100 ));
        insert entries;
        OrderItem orderItemCons = new OrderItem();
        orderItemCons.OrderId = ord.Id;
        orderItemCons.Product2Id = sampleProduct.Id;
        orderItemCons.SerialNumber__c = '0909201';        
        orderItemCons.UnitPrice = entries[0].UnitPrice;
        //orderItemCons.SBQQ__QuoteLine__c = lines[0].Id;
        orderItemCons.SBQQ__SubscriptionTerm__c = 36;
        orderItemCons.Quantity = 20;
        orderItemCons.PricebookEntryId = entries[0].Id;
        insert orderItemCons;
        AccID.add(testAccount.id);
        Map<Id, List<string>> mapAccountWithHoldChanged2 = new Map<Id, List<string>> ();
        mapAccountWithHoldChanged2.put(testAccount.id, new List<string> ());
        if(testAccount.EULA_revision_Required__c == true){
            mapAccountWithHoldChanged2.get(testAccount.Id).add('Eula Req True');
        }
        if(testAccount.Contract_Negotiation__c == true){
            mapAccountWithHoldChanged2.get(testAccount.Id).add('contract Negotiation');
        } 
        testAccount.Contract_Negotiation__c = false;
        testAccount.EULA_revision_Required__c = true;
        update testAccount;
        testAccount.EULA_revision_Required__c = false;
        update testAccount;
        Test.stopTest();
        System.assertEquals(testAccount.EULA_revision_Required__c ,false);
    }
  /*  static testMethod void testpopulateSDPartner(){
        Map<Id,Account> actMap2=new Map<Id,Account>();
        Account act = new Account(Name = 'TestAcct1',Website='www.test3.com',type='Customer');
        act.MSP_Account_Lookup__c=null;          
        insert act;
        actMap2.put(act.Id,act);
        Map<Id,Account> actMap=new Map<Id,Account>();
        Account act2 = new Account(Name = 'TestAcct2',Website='www.test3.com',type='Customer');
        act2.MSP_Account_Lookup__c=act.Id;
        insert act2;
        actMap.put(act.Id,act2);
        insert new TriggerControl__c(name='Opportunity',DisableTrigger__c=false);
        FlowControll.opportunityTriggerHandler = false;
        Opportunity oppr = TestDataFactory.getOpportunity(act2);
        //oppr.partner_lookup__c=act2.Id;
        oppr.AccountId=act2.Id;
        oppr.StageName='Technical Validation';
        insert oppr;
        System.debug('Opp ==>'+oppr);
        Test.startTest();
        AccountTriggerHelper.populateSDPartner(actMap2,actMap);
        Test.stopTest();
        System.assertEquals(act.MSP_Account_Lookup__c, oppr.Partner_of_Record__c);
    } */
    @IsTest
    static void testshareOpportunities(){
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        disableBusinessLogicCS.Disable_Account_Validation_Rules__c = true;  
        INSERT disableBusinessLogicCS;    
        
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        
        Opportunity op1  = TestDataFactory.getOpportunity();
        op1.Deal_Registration_Type__c='Partner Sourced New Logo (PSNL)';
        Account ac = new Account(Id=op1.AccountId);
        ac.recordtypeid = partnerRecordTypeId;
        update ac;
        op1.Sourcing_Partner__c=ac.Id;
        Opportunity op2  = TestDataFactory.getOpportunity(ac);
        op2.Deal_Registration_Type__c='Rubrik Sourced';
        op2.Sourcing_Partner__c=ac.Id;
        op2.Teaming_Partner__c=ac.Id;
        Opportunity op3  = TestDataFactory.getOpportunity(ac);
        op3.Deal_Registration_Type__c='Partner Sourced Expand';
        op3.Sourcing_Partner__c=ac.Id;
        //op3.Partner_Lookup__c=ac.Id;
        List<Opportunity> oppList = new List<Opportunity>{op1,op2,op3};
            Test.startTest();
        insert oppList;
        ac.Focused_Partner__c =true;
        ac.National_Partner__c=true;
        update ac;
        Test.stopTest();
        System.assertEquals(op1.Deal_Registration_Type__c, 'Partner Sourced New Logo (PSNL)');
    }

    static testMethod void testUpdateCompanyNameOnUserFuture(){
        List<User> listUser = [select Id from user where Firstname like '%testClassUser665544%'];
        Profile portalProfile = [SELECT Id FROM Profile Where UserType = 'PowerPartner' Limit 1];
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        System.runAs(listUser[0]) {
            Account testAccount = new Account(RecordTypeId = partnerRecordTypeId);
            testAccount.Name='Test Account1' ;        
            insert testAccount;
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = testAccount.Id,
                Email = System.now().millisecond() + 'test@test.com'
            );
            Insert contact1;
            user portalUser = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = System.now().millisecond() + 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Insert portalUser;
            Test.startTest();
            testAccount.IsPartner = true;
            testAccount.Name='Test Account1 Update';
            update testAccount;
            Test.stopTest();
            System.assertEquals('Test Account1 Update',[select id, Name from account where id =:testAccount.Id limit 1].Name);
        }        
    }
    @IsTest
    static void testshareOppoFocusedPartnerAccController(){
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        disableBusinessLogicCS.Disable_Account_Validation_Rules__c = true;  
        INSERT disableBusinessLogicCS;   
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='AdminUser' + DateTime.now().getTime() + '@rubrik.com'
        );
        insert u;
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Id salesOppTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();      
        
        Opportunity op1  = TestDataFactory.getOpportunity();
        op1.Deal_Registration_Type__c='Partner Sourced New Logo (PSNL)';
        Account ac = new Account(Id=op1.AccountId);
        ac.recordtypeid = partnerRecordTypeId;
        ac.Focused_Partner__c =true;
        ac.type = 'Partner';
        update ac;
        op1.Sourcing_Partner__c=ac.Id;
        op1.Opportunity_Type__c = 'New Customer';
        op1.Opportunity_Sub_Type__c = 'Regular';
        op1.recordtypeId = salesOppTypeId;
        op1.Partner_Lookup__c=ac.Id;
        Opportunity op2  = TestDataFactory.getOpportunity(ac);
        op2.Deal_Registration_Type__c='Rubrik Sourced';
        op2.Opportunity_Type__c = 'New Customer';
        op2.Opportunity_Sub_Type__c = 'Regular';
        op2.Sourcing_Partner__c=ac.Id;
        op2.recordtypeId = salesOppTypeId;
        op2.Teaming_Partner__c=ac.Id;
        op2.Partner_Lookup__c=ac.Id;
        Opportunity op3  = TestDataFactory.getOpportunity(ac);
        op3.Opportunity_Type__c = 'New Customer';
        op3.Deal_Registration_Type__c='Partner Sourced Expand';
        op3.Sourcing_Partner__c=ac.Id;
        op3.recordtypeId = salesOppTypeId;
        op3.Opportunity_Sub_Type__c = 'Regular';
        op3.Partner_Lookup__c=ac.Id;
        //op3.Partner_Lookup__c=ac.Id;
        List<Opportunity> oppList = new List<Opportunity>{op1,op2,op3};
        insert oppList;
        System.RunAs(u){ 
            insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = u.id, Disable_Account_Old_Trigger__c = TRUE,Allow_account_Transfer__c = true);
            ShGl_DisableBusinessLogic__c BLSetting = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            BLSetting.Disable_Opportunity_Validation_Rules__c = false;
            insert BLSetting;
            Test.startTest();
			ac.OwnerId = usr.Id;
            update ac;
            Test.stopTest();
        }        
        System.assertEquals(op1.Deal_Registration_Type__c, 'Partner Sourced New Logo (PSNL)');
    }
    
    @IsTest
    static void testshareOppoFocusedPartnerAccController2(){
        ShGl_DisableBusinessLogic__c disableBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getUserId());
        disableBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        disableBusinessLogicCS.Disable_Account_Validation_Rules__c = true;  
        INSERT disableBusinessLogicCS;   
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com.sandbox',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName='AdminUser' + DateTime.now().getTime() + '@rubrik.com'
        );
        insert u;
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1];
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Id salesOppTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();      
        
        Opportunity op1  = TestDataFactory.getOpportunity();
        op1.Deal_Registration_Type__c='Partner Sourced New Logo (PSNL)';
        Account ac = new Account(Id=op1.AccountId);
        ac.recordtypeid = partnerRecordTypeId;
        ac.Focused_Partner__c =true;
        ac.type = 'Partner';
        update ac;
        op1.Sourcing_Partner__c=ac.Id;
        op1.Opportunity_Type__c = 'New Customer';
        op1.Opportunity_Sub_Type__c = 'Regular';
        op1.recordtypeId = salesOppTypeId;
        op1.Partner_Lookup__c=ac.Id;
        Opportunity op2  = TestDataFactory.getOpportunity(ac);
        op2.Deal_Registration_Type__c='Rubrik Sourced';
        op2.Opportunity_Type__c = 'New Customer';
        op2.Opportunity_Sub_Type__c = 'Regular';
        op2.Sourcing_Partner__c=ac.Id;
        op2.recordtypeId = salesOppTypeId;
        op2.Teaming_Partner__c=ac.Id;
        op2.Partner_Lookup__c=ac.Id;
        Opportunity op3  = TestDataFactory.getOpportunity(ac);
        op3.Opportunity_Type__c = 'New Customer';
        op3.Deal_Registration_Type__c='Partner Sourced Expand';
        op3.Sourcing_Partner__c=ac.Id;
        op3.recordtypeId = salesOppTypeId;
        op3.Opportunity_Sub_Type__c = 'Regular';
        op3.Partner_Lookup__c=ac.Id;
        //op3.Partner_Lookup__c=ac.Id;
        List<Opportunity> oppList = new List<Opportunity>{op1,op2,op3};
        insert oppList;
        System.RunAs(u){ 
            insert new ShGl_DisableFunctionalityLogic__c(SetupOwnerId = u.id, Disable_Account_Old_Trigger__c = TRUE,Allow_account_Transfer__c = true);
            Test.startTest();
			ac.OwnerId = usr.Id;
            update ac;
            Test.stopTest();
        }        
        System.assertEquals(op1.Deal_Registration_Type__c, 'Partner Sourced New Logo (PSNL)');
    }
}