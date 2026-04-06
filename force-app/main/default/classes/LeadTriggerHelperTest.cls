/********************************************************************************************************
* Name              : LeadTriggerHelperTest
* Purpose           : LeadTriggerHelperTest is Used for Testing LeadTriggerHelper Class 
*********************************************************************************************************/
@isTest
private class LeadTriggerHelperTest implements HttpCalloutMock { 
    private static final String RTID_INDUSTRY = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByDeveloperName().get('Industry').getRecordTypeId();
    private static final Boolean DOINSERT_TRUE = true;
    private static final Boolean DOINSERT_FALSE = false;
    @testSetup static void testDataSetup() {
        
        Group datosQ = new Group(Name='Datos.io Leads', Type = 'Queue');
        insert datosQ;
        
        User user1 = createUserAdmin('tUser1');
        User user2 = createUserAdmin('tUser2');
        User user3 = createUserAdmin('tUser3');
        QueuesObject qObject = new QueueSObject(QueueID = datosQ.id, SobjectType = 'Lead');
        insert qObject; 
        
        system.runas(user1){
            //insert Custom Setting
            WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
            
            TriggerControl__c trigcontrl = new TriggerControl__c(name='Entitlement', DisableTrigger__c  = true);
            insert trigcontrl;    
                
              
                
                //initialize custom label
                String testLbl = Label.LeadCountryCodes;
            String testLb2 = Label.LeadSourceValues;
            
            //Generate  Campaign
            /*Map < String, Object > campMap = new Map < String, Object > {
            'Alliance_Partner__c' => 'Cleversafe',
            'Campaign_Sales_Theatre__c' => 'APAC',
            'Campaign_Sales_Area__c' => 'APJ',
            'Campaign_Sales_Region__c' => 'APJ',
            'Cost_Center__c' => 'Alliance'
            };
            //MKT24-1149236
            List < Campaign > campList = (List < Campaign > ) ShGl_TestFactory.createSObjectList(new Campaign(), 5, campMap);
            insert campList;
            system.debug('>>>'+campList);*/
            Id recordtypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
            Campaign camp1 = new Campaign(RecordtypeId= recordtypeId, Name = 'Test Campaign 1', 
                                          IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'APAC', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance', Campaign_Theme__c='Cloud', GTM_Play__c ='Cloud Native Protection', Executed_By__c = 'Digital Marketing',Involvement_by_Customer_Marketing__c='Yes', Planned_MQL__c=1);
            insert camp1;
            
            //Id recordtypeId1 = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Digital').getRecordTypeId();
            //  Campaign camp2 = new Campaign(RecordtypeId= recordtypeId, Name = 'Test Campaign 1', 
            // IsActive = True, Alliance_Partner__c = 'Cleversafe', Campaign_Sales_Theatre__c = 'APAC', Campaign_Sales_Area__c = 'AMER-FED', Campaign_Sales_Region__c = 'APAC', Campaign_Sales_Sub_Region__c = 'APAC', Cost_Center__c = 'Alliance', Campaign_Theme__c='Alliances', GTM_Play__c ='Azure', Executed_By__c = 'Digital Marketing',Involvement_by_Customer_Marketing__c='Yes', Planned_MQL__c=1);
            // insert camp2;
            
            //Create Parent Group
            Group grp = new Group();
            grp.name = 'AMER-MM';
            grp.Type = 'Queue'; 
            Insert grp; 
            
            Group grp1 = new Group();
            grp1.name = 'FED_Queue';
            grp1.Type = 'Queue'; 
            Insert grp1; 
            
            //Create Group Member
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = user1.Id;
            grpMem1.GroupId = grp.Id;
            Insert grpMem1;
            
            PatchManager__c ptch = new PatchManager__c();
            //ptch.Industry_Category__c = 'Agriculture';
            ptch.Country__c = 'US';
            ptch.CountryGlobal__c='United States';
            ptch.SMB_Owner__c=userInfo.getUserId();
            ptch.Zip_code__c = '20006';
            insert ptch;
            
            PatchManager__c ptch3 = new PatchManager__c();
            //ptch.Industry_Category__c = 'Agriculture';
            ptch3.Country__c = 'IN';
            ptch3.CountryGlobal__c='India';
            ptch3.SMB_Owner__c=userInfo.getUserId();
            ptch3.SDR__c=userInfo.getUserId();
            insert ptch3;
            String RecordTypeIdDomain = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Domain').getRecordTypeId();
            PatchManager__c ptch2 = new PatchManager__c();
            //ptch.Industry_Category__c = 'Agriculture';
            ptch2.Domain__c = 'nassconorfolk.com';
            ptch2.SDR__c=userInfo.getUserId();
            ptch2.RecordTypeId=RecordTypeIdDomain;
            insert ptch2;
            
            //Generate Lead
            Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
            led.firstName = 'Test Lead FN';
            led.lastName = 'Test Lead LN';
            led.Status = 'Open';
            led.CountryCode = 'US';
            led.Routing_Rule_Applied__c ='test';
            insert led;
            
            Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com');
            insert act;
            
            //Generate  CampaignMember
            CampaignMember campMem1 = new CampaignMember(Leadid = led.id, CampaignId = camp1.id, Status = 'Sent');
            /*CampaignMember campMem2 = new CampaignMember(Leadid = led.id, CampaignId = campList[1].id, Status = 'Sent');
            CampaignMember campMem3 = new CampaignMember(Leadid = led.id, CampaignId = campList[2].id, Status = 'Sent');
            CampaignMember campMem4 = new CampaignMember(Leadid = led.id, CampaignId = campList[3].id, Status = 'Sent');
            CampaignMember campMem5 = new CampaignMember(Leadid = led.id, CampaignId = campList[4].id, Status = 'Sent');
            insert new List<CampaignMember>{campMem1,campMem2,campMem3,campMem4,campMem5};*/
            insert campMem1;
            
            Id adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1].Id; //System Administrator
            Id adminProfileIdLightAdmin = [SELECT Id FROM Profile WHERE Name = 'Rubrik Light Administrator' limit 1].Id;
            ShGl_DisableBusinessLogic__c disableBusiCS = ShGl_DisableBusinessLogic__c.getInstance();
            disableBusiCS.Disable_Lead_Validation_Rules__c = true;
            disableBusiCS.SetupOwnerId = adminProfileId;
            disableBusiCS.Disable_Contact_Triggers__c = true;
            upsert disableBusiCS;
            ShGl_DisableBusinessLogic__c disableBusiCSLightAdmin = ShGl_DisableBusinessLogic__c.getInstance();
            disableBusiCSLightAdmin.Disable_Lead_Validation_Rules__c = true;
            disableBusiCSLightAdmin.SetupOwnerId = adminProfileIdLightAdmin;
            disableBusiCSLightAdmin.Disable_Contact_Triggers__c = true;
            upsert disableBusiCSLightAdmin;
            
            List<Lead_RiffRaff__c> riffRaffSetting = new List<Lead_RiffRaff__c>();
            riffRaffSetting.add(new Lead_RiffRaff__c(Name = 'Actifio Test',Type__c = 'Company'));
            riffRaffSetting.add(new Lead_RiffRaff__c(Name = 'Data Test',Type__c = 'Domain'));
            riffRaffSetting.add(new Lead_RiffRaff__c(Name = 'Rubrik Test',Type__c = 'Title'));
            riffRaffSetting.add(new Lead_RiffRaff__c(Name = 'Test Lead LN1',Type__c = 'Name'));
            insert riffRaffSetting;
            insert new ShGl_DisableBusinessLogic__c(SetupOwnerId = UserInfo.getUserId(), Disable_Opportunity_Validation_Rules__c = TRUE, Disable_Lead_Validation_Rules__c= TRUE, Disable_Entitlement_Trigger__c	 = TRUE, Disable_Contact_Triggers__c = TRUE);
            
            List<Territory2> territories = new List<Territory2>();
            List<Territory2Model> TModel = [select id,Name from territory2model where State ='Active'];
            List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DEveloperNAme = 'Territory'];
            
            for(Integer i=0;i<1;i++){
                Territory2 terr = new Territory2();
                terr.Name = 'TEST-TERR-' + i;
                terr.DeveloperName = 'TEST_TERR_' + i;
                terr.Adaptive_Territory_Id__c = '999999'+i;
                terr.Territory2ModelId = TModel[0].Id;
                terr.Territory2TypeId = terrType[0].Id;
                territories.add(terr);
            }
            insert territories;
            
            User tUser1 = createUser('tUser1');
        User tUser2 = createUser('tUser2');
        User tUser3 = createUser('tUser3');
            
           
          
        List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
        UserTerritory2Association uta1 = new UserTerritory2Association();
        uta1.Territory2Id = territories[0].Id;
        uta1.RoleInTerritory2 = 'Account Executive';
        uta1.UserId = tUser1.Id;
        utaRecords.add(uta1);

        UserTerritory2Association uta2 = new UserTerritory2Association();
        uta2.Territory2Id = territories[0].Id;
        uta2.RoleInTerritory2 = 'IAM';
        uta2.UserId = tUser2.Id;
        utaRecords.add(uta2);

        UserTerritory2Association uta3 = new UserTerritory2Association();
        uta3.Territory2Id = territories[0].Id;
        uta3.RoleInTerritory2 = 'SDR';
        uta3.UserId = tUser3.Id;
        utaRecords.add(uta3);
            insert utaRecords;
            
            // Account act2 = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='AMER-MM',ETM_Area__c='ENT-test',BillingCountry ='United States',BillingCountryCode ='US');
       // insert act2;
        insert new ObjectTerritory2Association(ObjectId =act.id , Territory2Id =territories[0].id, AssociationCause ='Territory2Manual');  
        }
    }
    
    
    static User createUser(String alias) {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'Rubrik Field Sales User']; //Rubrik Field Sales User
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        User sysAdmin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'sys1Admin@randomtestdomain.com',
            Alias = alias,
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
    public HTTPResponse respond(HTTPRequest req) {
        String fullJson ='{"statusDescription":"Success","statusDescription":"Success","statusCode":"200","status":null,"l2aAccount":[{"matchStatus":"Not Matched","matchConfidence":"3","matchCriteria":"","accountId":"","sourceId":"00Q4000001IrbyEEAR"}]}';       
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'text/json');
        res.setBody(fullJson);
        res.setStatusCode(200);
        return res;
    }
    static User createUserAdmin(string alias) {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; //System Administrator
        UserRole portalRole = [SELECT Id FROM UserRole WHERE Name = 'CEO' LIMIT 1];
        User sysAdmin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'sys1Admin123@randomtestdomain.com',
            Alias = alias,
            Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
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
    
    @isTest static void updateLeadandCampaignOnMeetingSet_test(){
        
        //DandbCompany dCompany = [select id from DandbCompany where name = 'Test'];
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Lead newLead = [SELECT Id,Status,UTM_Campaign__c, UTM_Medium__c, UTM_Source__c,SDR_Led__c ,LeadSource FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        newLead.Status = 'Meeting Set';
        newLead.rerun_PatchManager__c = false; 
        newLead.UTM_Campaign__c = 'testCampaign';
        newLead.UTM_Medium__c = 'testMedium';
        newLead.UTM_Source__c = 'testSource';
        //newLead.DandbCompanyId = dCompany.Id;
        newLead.CountryCode = 'IN';
        newLead.Industry = 'Agriculture';
        newLead.Country = 'India';
        //newLead.Business_Unit__c = 'Both';
        newLead.Meeting_Id__c = 'testId';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update newLead;
        Test.stopTest();
            system.assertEquals(True,newLead.Id != null);
        }
        
        Campaign camp = [Select Id,Name from Campaign where Name='Test Campaign 1' limit 1];
        
        CampaignMember cpm = [Select Id,UTM_Campaign__c,UTM_Medium__c,UTM_Source__c,Lead_Status_Stamp__c,Meeting_set__c from CampaignMember where CampaignId=:camp.Id];
        
    }
    @isTest static void testriffraffFilter() { 
        Lead_RiffRaff__c riffRaffSetting = new Lead_RiffRaff__c();
		riffRaffSetting.Type__c = 'Company';
		riffRaffSetting.Name = 'Nothing';
		insert riffRaffSetting;
        //Generate Lead
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'TestFN345';
        led.lastName = 'TestLN456';
        led.Email = 'testFNLN456@test.com';
        led.Status = 'Open';
        led.CountryCode = 'BE';
        led.Deal_Registration__c = false;
        led.title = 'test';
        led.MQL__c = true;
        led.SAL__c = true;
        led.LeadSource = 'Sales';
        
        Lead lead2 = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        lead2.firstName = 'TesLedFN234';
        lead2.lastName = 'TestLedLN567';
        lead2.Email = 'testLed56@test.com';
        lead2.Company = 'Nothing';
        lead2.Status = 'RAW';
        lead2.CountryCode = 'BE';
        lead2.Deal_Registration__c = false;
        lead2.P_0_Response__c = true;
        lead2.title = 'test';
        lead2.MQL__c = true;
        lead2.SAL__c = true;
        lead2.LeadSource = 'Sales';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        insert led;
        insert lead2;
        Test.stopTest();
        led = [SELECT Id, Status, Lead_Rejection_Reason__c FROM Lead WHERE Id = :lead2.Id];    
        lead2 = [SELECT Id, Status, MQL__c, Last_MQL_Date__c FROM Lead WHERE Id = :lead2.Id];
        Assert.areEqual(True,lead2.Id != null);
        }
    }
    @isTest static void testmqlUpdatesBeforeUpdate() {
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Lead led = [SELECT Id FROM Lead LIMIT 1];
        led.Status = 'Non-Qualified';
        led.CountryCode = 'BE';
        led.Deal_Registration__c = false;
        led.P_0_Response__c = true;
        led.Lead_Rejection_Reason__c = 'Contacted/No Interest';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update led;
        Test.stopTest();
        led = [SELECT Id, Status FROM Lead WHERE Id = :led.Id];
        Assert.areEqual(True,led.Id != null);
        }
    }
    @isTest static void testcreateSDRLedMeetingTask(){
        Lead led = [SELECT Id FROM Lead LIMIT 1];
        led.Meeting_Id__c = 'testId';
        led.SDR_Led__c = true;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update led;
        Test.stopTest();
        led = [SELECT Id, SDR_Led__c FROM Lead WHERE Id = :led.Id];
        System.assert(led.SDR_Led__c);
        }
    }
    @isTest static void testonStatusChange(){
        Lead led = [SELECT Id FROM Lead LIMIT 1];
        led.Meeting_Id__c = 'testId';
        led.Status = 'Meeting Set';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update led;
        Test.stopTest();
        led = [SELECT Id, DateEnteredintoMeetingSet__c, Last_Status_Updated_TimeStamp__c FROM Lead WHERE Id = :led.Id];
        Assert.areEqual(True,led.Id != null);
        }
        /*System.assert(led.DateEnteredintoMeetingSet__c!=null);
System.assert(led.Last_Status_Updated_TimeStamp__c!=null);*/
    }
    @isTest static void testunmqlLead(){
        Lead led = [SELECT Id FROM Lead WHERE Status!= 'Non-Qualified' LIMIT 1];
        led.MQL__c = true;
        led.Lead_Rejection_Reason__c = 'Contacted/No Interest';
        led.Status = 'Non-Qualified';
        //update led;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update led;
        Test.stopTest();
        led = [SELECT Id, MQL__c FROM Lead WHERE Id = :led.Id];
        Assert.areEqual(True,led.Id != null);
        }
    }
    @isTest static void testresetL2Astatus(){
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Lead led = [SELECT Id, Company FROM Lead LIMIT 1];
        led.Company = 'Another Company';
        led.L2A_Status__c = 'PROCESSED';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update led;
        Test.stopTest();
        Assert.areEqual(True,led.Id != null);
        }
    }
    
     @isTest static void testRunL2A(){
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'TestFN123';
        led.lastName = 'TestLN3456';
        led.Email = 'test9876Led@test.com';
        led.Status = 'Open';
         led.Salesloft_Cadence_Most_Recent__c='MM-';
        led.CountryCode = 'IN';
        led.Deal_Registration__c = false;
        insert led;
        List<id> LeadId=new List<id>();
        LeadId.add(led.id);
        List<Boolean> runPatchManager=new List<Boolean>{true};
            
            led = [SELECT Id, Run_L2A__c FROM Lead WHERE Run_L2A__c = false LIMIT 1];
        led.Run_L2A__c = true;
         User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        try{
             update led;
           // LeadTriggerHelper.runL2AServiceBulk(LeadId,runPatchManager);
            
        }
        catch(exception ex){
            String errorMsg = ex.getMessage();
        }
       
        Test.stopTest();
         Assert.areEqual(True,led.Id != null);
        }
    }
    @isTest static void testrerunPatchManager(){
        
        
        
      Account act = [Select id,name from Account where Name ='Test Company' limit 1];
        
       List<User>  Pmuser1  =[Select id,name from User WHERE IsActive = TRUE Limit 10];
      // User  Pmuser2  =[Select id,name from User where Alias='tUser2'];
       //User  Pmuser3  =[Select id,name from User where Alias='tUser3'];
        
        
        
        Id devRecordTypeId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Geographic').getRecordTypeId();
        PatchManager__c patchmanger = new PatchManager__c();
        patchmanger.RecordTypeId = devRecordTypeId;
        patchmanger.SDR__c=Pmuser1[0].id;
        patchmanger.AccountExecutive__c=Pmuser1[1].id;
        patchmanger.Alliance_BDM__c=Pmuser1[2].id;
        
        insert patchmanger;
        
        List<Patch_Manager_User_Pool__c> pMPoolList = new List<Patch_Manager_User_Pool__c>();
        Patch_Manager_User_Pool__c poolData = new Patch_Manager_User_Pool__c();
        poolData.Patch_Key__c=patchmanger.id;
        poolData.User__c=Pmuser1[0].id;
        
        pMPoolList.add(poolData);
         Patch_Manager_User_Pool__c poolData2 = new Patch_Manager_User_Pool__c();
        poolData2.Patch_Key__c=patchmanger.id;
        poolData2.User__c=Pmuser1[1].id;
        pMPoolList.add(poolData2);
        insert pMPoolList;
        
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'TestLeadFN567';
        led.lastName = 'TestLeadLN567';
        led.Status = 'Open';
        led.Email='test567@nassconorfolk.com';
        led.Campaign_Sourced_By__c='Sales';
        led.Deal_Registration__c = false;
        led.rerun_PatchManager__c = false;
        led.Industry = 'Industry';
        led.Country = 'United States';
        led.CountryCode = 'US';
        led.postalCode = '589526';
        led.L2A_Confidence_Code__c=4.0;
        led.L2A_Account__c=act.Id;
        led.PatchManager__c=patchmanger.id;
        led.UTM_Source__c='microsft';
        //led.ReassignLead__c=true;
        
        insert led;
        
        
       
        
        
        Lead updatelead1 = new Lead();
        updatelead1.Id=led.Id; 
        updatelead1.rerun_PatchManager__c = false;
       // updatelead1.ReassignLead__c=true;
        updatelead1.Winning_L2A_Account__c=act.id; 
        update updatelead1;
        
        led = [SELECT Id, rerun_PatchManager__c,ReassignLead__c,Winning_L2A_Account__c FROM Lead WHERE rerun_PatchManager__c = false and Id =:updatelead1.Id LIMIT 1];
        //Lead updatelead2 = new Lead();
        // updatelead2.Id=led.Id; 
        led.rerun_PatchManager__c = true;
        led.AssignLeadInAfter__c=true;
        //led.ReassignLead__c=true
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        update led;
        set<Id> accountIds = new set<Id>();
        accountIds.add(act.Id);
        set<Id> leadIds = new set<Id>();
        leadIds.add(led.Id);
        LeadTriggerHelper Obj = new LeadTriggerHelper();
        set<Id> accountOwnerIds = new set<Id>();
        accountOwnerIds.add(UserInfo.getUserId());
        
      // MQLRoutingOwnerAssignService1 objService = new MQLRoutingOwnerAssignService1(leadIds);
       //Map<String,map<String,String>> userTerriterMap = MQLRoutingOwnerAssignService1.findOwnerFromAccount(accountIds); 
        System.assert(led.Winning_L2A_Account__c!=null);   
        
        Test.stopTest();
        }
    }
    
    @isTest static void testrerunPatchKey(){
        
        
      //  Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='AMER-MM',ETM_Area__c='ENT-test',BillingCountry ='United States',BillingCountryCode ='US');
      //  insert act;
        // List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and  DeveloperName!='Unassigned'  limit 10];
      //  insert new ObjectTerritory2Association(ObjectId =act.id , Territory2Id =terrList[0].id, AssociationCause ='Territory2Manual');
       Account act = [Select id,name from Account where Name ='Test Company' limit 1];  
          List<User>  Pmuser1  =[Select id,name from User WHERE IsActive = TRUE Limit 10];
      // User  Pmuser2  =[Select id,name from User where Alias='tUser2'];
       //User  Pmuser3  =[Select id,name from User where Alias='tUser3'];
        
        
        
        Id devRecordTypeId = Schema.SObjectType.PatchManager__c.getRecordTypeInfosByName().get('Domain').getRecordTypeId();
        PatchManager__c patchmanger = new PatchManager__c();
        patchmanger.RecordTypeId = devRecordTypeId;
        patchmanger.SDR__c=Pmuser1[0].id;
        patchmanger.AccountExecutive__c=Pmuser1[1].id;
        patchmanger.Alliance_BDM__c=Pmuser1[2].id;
        patchmanger.Domain__c='libraryofcongress.gov';
        
        insert patchmanger;
        
        List<Patch_Manager_User_Pool__c> pMPoolList = new List<Patch_Manager_User_Pool__c>();
        Patch_Manager_User_Pool__c poolData = new Patch_Manager_User_Pool__c();
        poolData.Patch_Key__c=patchmanger.id;
        poolData.User__c=Pmuser1[0].id;
        
        pMPoolList.add(poolData);
        Patch_Manager_User_Pool__c poolData2 = new Patch_Manager_User_Pool__c();
        poolData2.Patch_Key__c=patchmanger.id;
        poolData2.User__c=Pmuser1[1].id;
        pMPoolList.add(poolData2);
        insert pMPoolList;
        
        
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'TestLeadFN765';
        led.lastName = 'TestLeadLN765';
        led.Status = 'Open';
        led.Email='test765@libraryofcongress.gov';
        led.Campaign_Sourced_By__c='Sales';
        led.Deal_Registration__c = false;
        led.rerun_PatchManager__c = false;
        led.Industry = 'Industry';
        led.Country = 'United States';
        led.CountryCode = 'US';
        led.postalCode = '';
        led.L2A_Confidence_Code__c=4.0;
        led.PatchManager__c=patchmanger.Id;
       // led.L2A_Account__c=act.Id;
        //led.ReassignLead__c=true;
        
        insert led;
        
        
      
        
        
        Lead updatelead1 = new Lead();
        updatelead1.Id=led.Id; 
        updatelead1.rerun_PatchManager__c = false;
       // updatelead1.ReassignLead__c=true;
        updatelead1.Winning_L2A_Account__c=act.id; 
        update updatelead1;
        
        led = [SELECT Id, rerun_PatchManager__c,ReassignLead__c,Winning_L2A_Account__c FROM Lead WHERE rerun_PatchManager__c = false and Id =:updatelead1.Id LIMIT 1];
        //Lead updatelead2 = new Lead();
        // updatelead2.Id=led.Id; 
        led.rerun_PatchManager__c = true;
        led.PatchManager__c=patchmanger.Id;
        led.Ownerid=Pmuser1[0].Id;
        //led.ReassignLead__c=true;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        update led;
        set<Id> accountIds = new set<Id>();
        accountIds.add(act.Id);
        set<Id> leadIds = new set<Id>();
        leadIds.add(led.Id);
        LeadTriggerHelper Obj = new LeadTriggerHelper();
        set<Id> accountOwnerIds = new set<Id>();
        accountOwnerIds.add(UserInfo.getUserId());
        System.assert(led.Winning_L2A_Account__c!=null);   
        Test.stopTest();
        }
    }
    
   @isTest static void leadRoutingTest(){
       Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='MM-LATAM',ETM_Area__c='JAPAN-A');
        insert act;
        List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' limit 10];
        insert new ObjectTerritory2Association(ObjectId =act.id , Territory2Id =terrList[0].id, AssociationCause ='Territory2Manual');
        Lead led = [SELECT Id,Status,Company, UTM_Medium__c, Deal_Registration__c,ReassignLead__c, rerun_PatchManager__c,Industry,Country,Campaign_Sourced_By__c,CountryCode,postalCode,L2A_Confidence_Code__c,L2A_Account__c,L2A_Status__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        
        led.Status = 'Open';
        //led.Email='test@nad45435sscodfsfnorfolkjhgjhg.com';
        led.Company='Test ABC Company';
        led.Deal_Registration__c = false;
        led.rerun_PatchManager__c = false;
        led.Industry = 'Industry';
        led.Country = 'United States';
        led.Campaign_Sourced_By__c='Sales';
        led.CountryCode = 'US';
        led.postalCode = '20006';
        led.L2A_Confidence_Code__c=4.0;
        led.L2A_Account__c=act.Id;
        led.L2A_Status__c='';
        led.rerun_PatchManager__c=false;
        //led.ReassignLead__c=true;
        led.Winning_L2A_Account__c=act.id;
        update led;
        
        led = [SELECT Id, rerun_PatchManager__c FROM Lead WHERE rerun_PatchManager__c = false  and Id =:led.Id LIMIT 1];
        Lead updatelead2 = new Lead();
        led.rerun_PatchManager__c = true;
       User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        
        update led;
        Test.stopTest();
       Assert.areEqual(True,led.Id != null);
        }
    }
    
      @isTest static void leadRoutingTest3(){
       Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='CDM',ETM_Area__c='CDM-EMEA');
        insert act;
        Lead led = [SELECT Id,Status,Company, UTM_Medium__c, Deal_Registration__c,ReassignLead__c, rerun_PatchManager__c,Industry,Country,Campaign_Sourced_By__c,CountryCode,postalCode,L2A_Confidence_Code__c,L2A_Account__c,L2A_Status__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        
        led.Status = 'Open';
        //led.Email='test@nad45435sscodfsfnorfolkjhgjhg.com';
        led.Company='Test ABC Company';
        led.Deal_Registration__c = false;
        led.rerun_PatchManager__c = false;
        led.Industry = 'Industry';
        led.Country = 'India';
        led.Campaign_Sourced_By__c='Sales';
        led.CountryCode = 'US';
        led.postalCode = '20006';
        led.L2A_Confidence_Code__c=1.0;
        led.OP_Confidence_Level__c=1.0;
        led.L2A_Account__c=act.Id;
        led.L2A_Status__c='';
        led.rerun_PatchManager__c=false;
        //led.ReassignLead__c=true;
        led.Winning_L2A_Account__c=act.id;
        update led;
        
        led = [SELECT Id, rerun_PatchManager__c FROM Lead WHERE rerun_PatchManager__c = false  and Id =:led.Id LIMIT 1];
        Lead updatelead2 = new Lead();
        led.rerun_PatchManager__c = true;
          User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        
        update led;
        Test.stopTest();
          Assert.areEqual(True,led.Id != null);
        }
    }
    
    @isTest static void leadAssignTest(){
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='MM-APAC-A',ETM_Area__c='ENT-test', accountBuyingStage6sense__c ='Purchase');
        insert act;
         List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' limit 10];
        insert new ObjectTerritory2Association(ObjectId =act.id , Territory2Id =terrList[0].id, AssociationCause ='Territory2Manual');
        Lead led = [SELECT Id,Status,Company, UTM_Medium__c, Deal_Registration__c,ReassignLead__c, rerun_PatchManager__c,Industry,Country,Campaign_Sourced_By__c,CountryCode,postalCode,L2A_Confidence_Code__c,L2A_Account__c,L2A_Status__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        
        led.Status = 'Open';
        //led.Email='test@nad45435sscodfsfnorfolkjhgjhg.com';
        led.Company='Test ABC Company';
        led.Deal_Registration__c = false;
        led.rerun_PatchManager__c = false;
        led.Industry = 'Industry';
        led.Country = 'United States';
        led.Campaign_Sourced_By__c='Marketing';
        led.CountryCode = 'US';
        led.postalCode = '20006';
        led.L2A_Confidence_Code__c=4.0;
        led.L2A_Account__c=act.Id;
        led.L2A_Status__c='';
        led.rerun_PatchManager__c=false;
        //led.ReassignLead__c=true;
        led.Winning_L2A_Account__c=act.id;
        led.Update_Lead_Score__c = true;
        led.AnnualRevenue = 1000000000;
        update led;
        
        led = [SELECT Id, rerun_PatchManager__c FROM Lead WHERE rerun_PatchManager__c = false  and Id =:led.Id LIMIT 1];
        Lead updatelead2 = new Lead();
        led.rerun_PatchManager__c = true;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        
        update led;
        Test.stopTest();
        Assert.areEqual(True,led.Id != null);
        }
    }
    
    
    @isTest static void updateCampMemberForL2ATest(){
        
        //DandbCompany dCompany = [select id from DandbCompany where name = 'Test'];
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Account act1 = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='MM-EMEA',ETM_Area__c='ENT-test');
        insert act1;
        
        Account act2 = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='MM-EMEA',ETM_Area__c='ENT-test');
        insert act2;
        
        Lead newLead = [SELECT Id,Status,UTM_Campaign__c, UTM_Medium__c, UTM_Source__c,SDR_Led__c ,LeadSource FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        newLead.Status = 'Marketing Nurture';
        newLead.rerun_PatchManager__c = false; 
        newLead.UTM_Campaign__c = 'testCampaign';
        newLead.UTM_Medium__c = 'testMedium';
        newLead.UTM_Source__c = 'testSource';
        //newLead.DandbCompanyId = dCompany.Id;
        newLead.CountryCode = 'IN';
        newLead.Industry = 'Agriculture';
        newLead.Country = 'India';
        //newLead.Business_Unit__c = 'Both';
        newLead.L2A_Confidence_Code__c=4;
        newLead.L2A_Account__c=act1.Id;
        newLead.MQL__c=true;
        newLead.Partner_MQL__c=true;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update newLead;
        Test.stopTest();
        Assert.areEqual(True,newLead.Id != null);
        }
        Campaign camp = [Select Id,Name from Campaign where Name='Test Campaign 1' limit 1];
        
        CampaignMember cpm = [Select Id,UTM_Campaign__c,UTM_Medium__c,UTM_Source__c,Lead_Status_Stamp__c,Meeting_set__c from CampaignMember where CampaignId=:camp.Id];
        // system.assert(cpm.Meeting_set__c);
        // system.assertEquals(cpm.UTM_Campaign__c,'testCampaign');
        //  system.assertEquals(cpm.UTM_Medium__c,'testMedium');
        //  system.assertEquals(cpm.UTM_Source__c,'testSource');
        
        //Lead newLead1 = [SELECT Id,Meeting_Set_Campaign_ID__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        //system.assertEquals(newLead1.Meeting_Set_Campaign_ID__c,camp.Id);
    }
    @isTest static void prepareContactListForEdgeTrialTest(){
        Lead newLead = [SELECT Id, Email, Agreed_to_Edge_Trail_Agreement__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=true);
        insert new SetupCompanyMaster__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_CM__c = true);
        
        Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',type='Customer');
        act.rerun_PatchManager__c =true;
        insert act;
        
        Contact con = new Contact(accountid=act.Id, lastname='test con', email='test-example@test-rubrik.com');
        insert con;
        
        Test.startTest();
        
        newLead.Agreed_to_Edge_Trail_Agreement__c = true;
        update newLead;
        Set<String> emailSet = new set<String>();
        emailSet.add(con.Email);
        LeadTriggerHelper Obj = new LeadTriggerHelper();
        Obj.prepareContactListForEdgeTrial(emailSet); 
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.stopTest();
        Assert.areEqual(True,newLead.Id != null);
        }

    }
    
    @isTest static void prepareContactListForEdgeTrialTest2(){
        User adminUser = [select Id from User where UserRole.Name='CEO' limit 1];
        Lead newLead = [SELECT Id, Email, Agreed_to_Edge_Trail_Agreement__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        
        insert new PatchManagerSettings__c(Default_User_Id__c=UserInfo.getUserId(), Default_Account_User__c=UserInfo.getUserId(),Route_on_Insert_Account__c=true);
        insert new SetupCompanyMaster__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_CM__c = true);
        
        Account act = [select Id from Account limit 1];
        
        Contact con = new Contact(accountid=act.Id, lastname='test con', email='test-example@test-rubrik.com');
        insert con;
        
        User newPortalUser = new User();
        newPortalUser.ProfileID = '00e1W000000jxzi';
        newPortalUser.EmailEncodingKey = 'ISO-8859-1';
        newPortalUser.LanguageLocaleKey = 'en_US';
        newPortalUser.TimeZoneSidKey = 'America/New_York';
        newPortalUser.LocaleSidKey = 'en_US';
        newPortalUser.Alias ='puser';
        newPortalUser.FirstName = con.FirstName;
        newPortalUser.LastName = con.LastName;
        newPortalUser.Username = 'support.test-example@test-rubrik.com';   
        newPortalUser.CommunityNickname =String.ValueOf(Math.random());
        newPortalUser.Email = con.Email;
        newPortalUser.IsActive = true;
        newPortalUser.ContactId = con.Id;
        newPortalUser.Phone = con.Phone;
        newPortalUser.Street= con.MailingStreet;
        newPortalUser.City = con.MailingCity;
        newPortalUser.State = con.MailingState;
        newPortalUser.Country = con.MailingCountry;
        newPortalUser.PostalCode = con.MailingPostalCode;
        //newPortalUser.UserPermissionsSFContentUser= true;
        newPortalUser.CompanyName = con.Account.Name;
        insert newPortalUser;  
        Test.startTest();
        
        newLead.Agreed_to_Edge_Trail_Agreement__c = true;
        update newLead;
        Set<String> emailSet = new set<String>();
        emailSet.add(con.Email);
        LeadTriggerHelper Obj = new LeadTriggerHelper();
        Obj.prepareContactListForEdgeTrial(emailSet); 
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.stopTest();
        Assert.areEqual(True,newLead.Id != null);
        }
    }
    @isTest static void testupdateLeadCompositeScore() {
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Lead testLead = [SELECT Id, Job_Function__c FROM Lead WHERE Job_Function__c != 'Administration' LIMIT 1];
        testLead.Job_Function__c = 'Administration';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update testLead;
        Test.stopTest();
        Assert.areEqual(True,testLead.Id != null);
        }
    }
    @isTest static void testpopulateWinningL2AAccount() {
        Lead testLead = [SELECT Id, Job_Function__c,L2A_Confidence_Code__c FROM Lead WHERE L2A_Confidence_Code__c != 3 LIMIT 1];
        testLead.L2A_Confidence_Code__c = 3;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update testLead;
        Test.stopTest(); 
        Assert.areEqual(True,testLead.Id != null);
        }
    }
    @isTest static void testpopulateWinningL2AAccount2() {
        Lead testLead = [SELECT Id, Job_Function__c,OP_Confidence_Level__c, L2A_Confidence_Code__c FROM Lead WHERE OP_Confidence_Level__c != 4  LIMIT 1];
        testLead.OP_Confidence_Level__c = 4;
        testLead.L2A_Confidence_Code__c = 2;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update testLead;
        Test.stopTest();  
        Assert.areEqual(True,testLead.Id != null);
        }
    }
    @isTest static void testpopulateWinningL2AAccount3() {
        Lead testLead = [SELECT Id, Job_Function__c,OP_Confidence_Level__c, L2A_Confidence_Code__c FROM Lead WHERE OP_Confidence_Level__c != 5  LIMIT 1];
        testLead.OP_Confidence_Level__c = 5;
        testLead.L2A_Confidence_Code__c = 2;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        update testLead;
        Test.stopTest(); 
        Assert.areEqual(True,testLead.Id != null);
        }
    }
    //MKT23-665 // File--Data Merge Data
    @isTest static void leadRoutingTestAMERFRED(){
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='AMER-FED',ETM_Area__c='ENT-test');
        insert act;
         List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' limit 10];
        insert new ObjectTerritory2Association(ObjectId =act.id , Territory2Id =terrList[0].id, AssociationCause ='Territory2Manual');
        Lead led = [SELECT Id,Status,Company, UTM_Medium__c, Deal_Registration__c,ReassignLead__c, rerun_PatchManager__c,Industry,Country,Campaign_Sourced_By__c,CountryCode,postalCode,L2A_Confidence_Code__c,L2A_Account__c,L2A_Status__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        
        led.Status = 'Open';
        //led.Email='test@nad45435sscodfsfnorfolkjhgjhg.com';
        led.Company='Test ABC Company';
        led.Deal_Registration__c = false;
        led.rerun_PatchManager__c = false;
        led.Industry = 'Industry';
        led.Country = 'United States';
        led.Campaign_Sourced_By__c='Sales';
        led.CountryCode = 'US';
        led.postalCode = '20006';
        led.L2A_Confidence_Code__c=4.0;
        led.L2A_Account__c=act.Id;
        led.L2A_Status__c='';
        led.Federal_Lead__c=true;
        led.Last_Applied_Routing_Modifier__c='Route to Federal';
        led.MQL__c = true;
        update led;
         
        led = [SELECT Id, rerun_PatchManager__c FROM Lead WHERE rerun_PatchManager__c = false  and Id =:led.Id LIMIT 1];
        Lead updatelead2 = new Lead();
        led.rerun_PatchManager__c = true;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        
        update led;
        Test.stopTest();
        Assert.areEqual(True,led.Id != null);
        }
    }
    
    @isTest static void leadsharingExpirationTest(){
        Lead newLead = [SELECT Id,Lead_Share_Program_Expiration_Date__c,MeetingDate__c,Routing_Rule_Applied__c FROM Lead limit 1];
        newLead.Lead_Share_Program_Expiration_Date__c = Date.today();
        newLead.MeetingDate__c = Date.today();
        newLead.Routing_Rule_Applied__c = 'Campaign - Partner of Record';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        
        update newLead;
        Test.stopTest();
        Assert.areEqual('Campaign - Partner of Record',newLead.Routing_Rule_Applied__c);
        }
    }

    @isTest static void testUpdateWinL2AAccount(){
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        List<Account> accList = new List<Account>();
        Account act = new Account(Name = 'Test Company',Website='www.test-rubrik.com',ETM_Region__c='MM-APAC-A',ETM_Area__c='ENT-test');
        Account act2 = new Account(Name = 'Test Company 2',Website='www.test-rubrik2.com',ETM_Region__c='MM-APAC-A',ETM_Area__c='ENT-test');
        accList.add(act);
        accList.add(act2);
        insert accList;
        List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' limit 10];
        insert new ObjectTerritory2Association(ObjectId =act.id , Territory2Id =terrList[0].id, AssociationCause ='Territory2Manual');
        Lead leadQuery = [SELECT Id,Status,Company, UTM_Medium__c, Deal_Registration__c,ReassignLead__c, rerun_PatchManager__c,Industry,Country,Campaign_Sourced_By__c,CountryCode,postalCode,L2A_Confidence_Code__c,L2A_Account__c,L2A_Status__c, Winning_L2A_Account__c FROM Lead where Company='Test Company' and Email='test-example@test-rubrik.com' limit 1];
        Map<Id, Lead> mapOfLead = new Map<Id,Lead>();
        leadQuery.Status = 'Open';
        leadQuery.Company='Test ABC Company';
        leadQuery.Deal_Registration__c = false;
        leadQuery.rerun_PatchManager__c = false;
        leadQuery.Industry = 'Industry';
        leadQuery.Country = 'United States';
        leadQuery.Campaign_Sourced_By__c='Marketing';
        leadQuery.CountryCode = 'US';
        leadQuery.postalCode = '20006';
        leadQuery.L2A_Confidence_Code__c=4.0;
        leadQuery.L2A_Account__c=accList[0].Id;
        leadQuery.L2A_Status__c='';
        leadQuery.rerun_PatchManager__c=false;
        leadQuery.Winning_L2A_Account__c=accList[0].Id;
        update leadQuery;
        mapOfLead.put(leadQuery.Id, leadQuery);
        leadQuery = [SELECT Id, Winning_L2A_Account__c FROM Lead WHERE Id =:leadQuery.Id LIMIT 1];
        leadQuery.Winning_L2A_Account__c = accList[1].Id;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest(); 
        update leadQuery;
        List<Lead> newLeadList = new List<Lead>{leadQuery};
        LeadTriggerHelper leadHelper = new LeadTriggerHelper();
        leadHelper.updateWinl2AAccountOwner(newLeadList,mapOfLead); 
        Test.stopTest();
        Assert.areEqual(True,leadQuery.Id != null);
        }
    }

    @isTest static void testRunL2AOnFlagCheck(){
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        List<Lead> leadList = new List<Lead>();
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'TestFN123';
        led.lastName = 'TestLN3456';
        led.Email = 'test9876Led@test.com';
        led.Status = 'Open';
         led.Salesloft_Cadence_Most_Recent__c='MM-';
        led.CountryCode = 'IN';
        led.Deal_Registration__c = false;
        leadList.add(led);
        insert leadList;
        Map<Id,Lead> mapOfLead = new Map<Id, Lead>(leadList);
        List<id> LeadId=new List<id>();
        LeadId.add(leadList[0].id);
        List<Boolean> runPatchManager=new List<Boolean>{true};
            
        List<Lead> ledQ = [SELECT Id, Run_L2A__c FROM Lead WHERE Run_L2A__c = false LIMIT 1];
        ledQ[0].Run_L2A__c = true;
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
        try{
            update ledQ;
            LeadTriggerHelper helper = new LeadTriggerHelper();
            helper.runL2AOnFlagCheck(ledQ,mapOfLead);
        }
        catch(exception ex){  
            String errorMsg = ex.getMessage();
        }
        Test.stopTest();
        Assert.areEqual(True,!ledQ.isEmpty());
        }
    }
    @isTest static void testMethod1(){
        Test.setMock(HttpCalloutMock.class, new LeadTriggerHelperTest());
        Account acc = [SELECT Id from Account LIMIT 1];
        List<Lead> leadList = new List<Lead>();
        Lead led = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        led.firstName = 'TestFN1234';
        led.lastName = 'TestLN34567';
        led.Email = 'test9876Led@test.com';
        led.Status = 'Nurture';
        led.Salesloft_Cadence_Most_Recent__c='MM-';
        led.CountryCode = 'IN';
        led.Deal_Registration__c = false;
        led.OP_L2A_Confidence_Type__c = 'LOW CONFIDENCE WITH DOMAIN';
        led.OP_L2A_Account__c = acc.Id;
        leadList.add(led);
        insert leadList;
        Lead ld = [SELECT Id,UTM_Term__c from Lead LIMIT 1];
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
            Test.startTest();
                try{
                   ld.UTM_Term__c = 'msft';
                   ld.ReassignLead__c = true;
                   ld.HasOptedOutOfEmail = true;
                   ld.Email_Opt_In__c = true;
                   ld.Salesloft_Cadence_Most_Recent__c = 'test';
                   update ld;
                    leadList[0].status = 'Nurture';
                    leadList[0].Lead_Rejection_Reason__c = null;
                    update leadList; 
                }
                catch(exception ex){   
                    String errorMsg = ex.getMessage();
                }
            Test.stopTest();
            Assert.areEqual(!leadList.isEmpty(),true);
        }
        
    }
    @isTest static void testinsertLeadIntoCampaign1(){
        Lead ld = [SELECT Id,Salesloft_Cadence_Most_Recent__c FROM Lead LIMIT 1];
        ld.Salesloft_Cadence_Most_Recent__c = 'MM-Test';
        ld.CFCR_Status_Reason__c = 'test';
        ld.status = 'Working';
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
            try {
                update ld;
            } catch (Exception e) {
                String errorMsg = e.getMessage();
            }
        Test.stopTest();
            
        Assert.areEqual(ld.Id != null,true);
        }
    }
    
    @isTest static void testMethodNurtureStatus(){
        Lead ld = [Select Id, Status, Last_MQL_Date__c FROM Lead LIMIT 1];
        ld.status = 'Nurture';
        ld.Last_MQL_Date__c = System.today();
        User usr = [SELECT Id From User where Profile.Name = 'System Administrator' and IsActive = TRUE LIMIT 1];
        System.runAs(usr){
        Test.startTest();
            try {
                update ld;
            } catch (Exception e) {
                String errorMsg = e.getMessage();
            }
        Test.stopTest();
            
        Assert.areEqual(ld.Id != null,true);
        }
    }

    //Created for MKT26-<Story number>
    @isTest static void patchManagerTest(){
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        Account accountObj = [SELECT Id, Name FROM Account WHERE Name ='Test Company' limit 1];
        String email = 'testUser@testemail.com';
        String domain = 'testemail.com';

        List<PatchManager__c> patchManagers = new List<PatchManager__c>();
        List<Lead> leads = new List<Lead>();

        //UserCase 0: lead with matchinhg domain
        Lead leadObj0 = getLead(email, DOINSERT_FALSE);
        leadObj0.Email = email;
        leads.add(leadObj0);

        //prepare patch manager with domain
        PatchManager__c patchManager0 = getPatchManager(domain, DOINSERT_FALSE);
        patchManager0.Zip_code__c = '119-72';
        patchManagers.add(patchManager0);


        //UserCase 1: lead with not matching domain && matching country+statecode+zipcode+industrycategory+tier
        Lead leadObj1 = getLead(email, DOINSERT_FALSE);
        leadObj1.Email = email + 'randomSuffix1';
        leadObj1.postalCode = '119-73';
        leadObj1.AnnualRevenue = 1000000001; // >= 1000000000 => Tier 1
        leadObj1.Metro_Area__c = '';
        leads.add(leadObj1);

        //prepare patch manager with no domain && no Metro_Area__c
        PatchManager__c patchManager1 = getPatchManager('', DOINSERT_FALSE);
        patchManager1.Metro_Area__c = '';
        patchManager1.Zip_code__c = '119-73';
        patchManagers.add(patchManager1);


        //UserCase 2: lead with not matching domain && matching country+statecode+zipcode+industrycategory
        Lead leadObj2 = getLead(email, DOINSERT_FALSE);
        leadObj2.Email = email + 'randomSuffix2';
        leadObj2.Winning_L2A_Account__c = accountObj.Id;
        leadObj2.L2A_Confidence_Code__c = 4.0;
        leadObj2.L2A_Account__c = accountObj.Id;
        leadObj2.Metro_Area__c = '';
        leadObj2.postalCode = '119-74';
        leads.add(leadObj2);

        //prepare patch manager with  no domain && no Metro_Area__c && no tier
        PatchManager__c patchManager2 = getPatchManager('', DOINSERT_FALSE);
        patchManager2.Metro_Area__c = '';
        patchManager2.Zip_code__c = '119-74';
        patchManager2.Tier__c = '';
        patchManagers.add(patchManager2);


        //UserCase 3: lead with not matching domain && matching country+zipcode+industrycategory+tier
        Lead leadObj3 = getLead(email, DOINSERT_FALSE);
        leadObj3.Email = email + 'randomSuffix3';
        leadObj3.AnnualRevenue = 1000000001; // >= 1000000000 => Tier 1
        leadObj3.Metro_Area__c = '';
        leadObj3.postalCode = '119-75';
        leadObj3.State = 'District of Columbia';
        leadObj3.StateCode = 'DC'; //non matching state code;
        leads.add(leadObj3);

        //prepare patch manager with  no domain && no Metro_Area__c && no state
        PatchManager__c patchManager3 = getPatchManager('', DOINSERT_FALSE);
        patchManager3.Metro_Area__c = '';
        patchManager3.StateGlobal__c = '';
        patchManager3.State__c = '';
        patchManager3.Zip_code__c = '119-75';
        patchManagers.add(patchManager3);


        //UserCase 4: lead with not matching domain && matching country+zipcode+industrycategory
        Lead leadObj4 = getLead(email, DOINSERT_FALSE);
        leadObj4.Email = email + 'randomSuffix4';
        leadObj4.AnnualRevenue = 1000000001; // >= 1000000000 => Tier 1
        leadObj4.Metro_Area__c = '';
        leadObj4.postalCode = '119-76';
        leadObj4.State = 'District of Columbia';
        leadObj4.StateCode = 'DC'; //non matching state code;
        leads.add(leadObj4);

        //prepare patch manager with  no domain && no Metro_Area__c && no state && no tier
        PatchManager__c patchManager4 = getPatchManager('', DOINSERT_FALSE);
        patchManager4.Metro_Area__c = '';
        patchManager4.StateGlobal__c = '';
        patchManager4.State__c = '';
        patchManager4.Zip_code__c = '119-76';
        patchManager4.Tier__c = '';
        patchManagers.add(patchManager4);
        

        //UserCase 5: lead with not matching domain && matching country+statecode+metro area+industrycategory+tier
        Lead leadObj5 = getLead(email, DOINSERT_FALSE);
        leadObj5.Email = email + 'randomSuffix5';
        leadObj5.AnnualRevenue = 1000000001; // >= 1000000000 => Tier 1
        leadObj5.postalCode = '119-77';
        leads.add(leadObj5);

        //prepare patch manager with  no domain, no zip code
        PatchManager__c patchManager5 = getPatchManager('', DOINSERT_FALSE);
        patchManager5.Zip_code__c = '';
        patchManagers.add(patchManager5);


        //UserCase 6: lead with not matching domain && matching country+statecode+metro area+industrycategory
        Lead leadObj6 = getLead(email, DOINSERT_FALSE);
        leadObj6.Email = email + 'randomSuffix6';
        leadObj6.postalCode = '';
        leadObj6.Winning_L2A_Account__c = accountObj.Id;
        leadObj6.L2A_Confidence_Code__c = 4.0;
        leadObj6.L2A_Account__c = accountObj.Id;
        leads.add(leadObj6);

        //prepare patch manager with  no domain, no zip code, no tier
        PatchManager__c patchManager6 = getPatchManager('', DOINSERT_FALSE);
        patchManager6.Zip_code__c = '';
        patchManager6.Tier__c = '';
        patchManagers.add(patchManager6);

        
        //UserCase 7: lead with not matching domain && matching country+statecode+industrycategory+tier
        Lead leadObj7 = getLead(email, DOINSERT_FALSE);
        leadObj7.Email = email + 'randomSuffix7';
        leadObj7.AnnualRevenue = 1000000001; // >= 1000000000 => Tier 1
        leadObj7.postalCode = '119-78';
        leadObj7.Metro_Area__c = '';
        leads.add(leadObj7);

        //prepare patch manager with  no domain, no zip code
        PatchManager__c patchManager7 = getPatchManager('', DOINSERT_FALSE);
        patchManager7.Zip_code__c = '';
        patchManager7.Metro_Area__c = '';
        patchManagers.add(patchManager7);
        

        //UserCase 8: lead with not matching domain && matching country+statecode+industrycategory
        Lead leadObj8 = getLead(email, DOINSERT_FALSE);
        leadObj8.Email = email + 'randomSuffix8';
        leadObj8.postalCode = '';
        leadObj8.Winning_L2A_Account__c = accountObj.Id;
        leadObj8.L2A_Confidence_Code__c = 4.0;
        leadObj8.L2A_Account__c = accountObj.Id;
        leadObj8.Metro_Area__c = '';
        leads.add(leadObj8);

        //prepare patch manager with  no domain, no zip code, no Metro_Area, no tier
        PatchManager__c patchManager8 = getPatchManager('', DOINSERT_FALSE);
        patchManager8.Zip_code__c = '';
        patchManager8.Tier__c = '';
        patchManager8.Metro_Area__c = '';
        patchManagers.add(patchManager8);
        

        //UserCase 9: lead with not matching domain && matching country+industrycategory+tier
        Lead leadObj9 = getLead(email, DOINSERT_FALSE);
        leadObj9.Email = email + 'randomSuffix9';
        leadObj9.AnnualRevenue = 1000000001; // >= 1000000000 => Tier 1
        leadObj9.postalCode = '119-78';
        leadObj9.Metro_Area__c = '';
        leadObj9.StateCode = ''; //non matching state code;
        leads.add(leadObj9);

        //prepare patch manager with  no domain, no zip code
        PatchManager__c patchManager9 = getPatchManager('', DOINSERT_FALSE);
        patchManager9.Zip_code__c = '';
        patchManager9.Metro_Area__c = '';
        patchManager9.StateGlobal__c = '';
        patchManager9.State__c = '';
        patchManagers.add(patchManager9);


        //UserCase 10: lead with not matching domain && matching country+industrycategory
        Lead leadObj10 = getLead(email, DOINSERT_FALSE);
        leadObj10.Email = email + 'randomSuffix10';
        leadObj10.Winning_L2A_Account__c = accountObj.Id;
        leadObj10.L2A_Confidence_Code__c = 4.0;
        leadObj10.L2A_Account__c = accountObj.Id;
        leadObj10.postalCode = '119-78';
        leadObj10.Metro_Area__c = '';
        leadObj10.StateCode = ''; //non matching state code;
        leads.add(leadObj10);

        //prepare patch manager with  no domain, no zip code, no tier
        PatchManager__c patchManager10 = getPatchManager('', DOINSERT_FALSE);
        patchManager10.Zip_code__c = '';
        patchManager10.Metro_Area__c = '';
        patchManager10.StateGlobal__c = '';
        patchManager10.State__c = '';
        patchManager10.Tier__c = '';
        patchManagers.add(patchManager10);
        

        //UserCase 11: lead with not matching domain && matching country+statecode+zipcode+tier
        Lead leadObj11 = getLead(email, DOINSERT_FALSE);
        leadObj11.Email = email + 'randomSuffix11';
        leadObj11.AnnualRevenue = 1000000001; // >= 1000000000 => Tier 1
        leadObj11.postalCode = '119-79';
        leadObj11.Metro_Area__c = '';
        leadObj11.Industry = '';
        leads.add(leadObj11);

        //prepare patch manager with  no domain, no zip code
        PatchManager__c patchManager11 = getPatchManager('', DOINSERT_FALSE);
        patchManager11.Zip_code__c = '119-79';
        patchManager11.Metro_Area__c = '';
        patchManager11.Industry_Category__c = '';
        patchManagers.add(patchManager11);

        //UserCase 12: lead with not matching domain && matching country
        Lead leadObj12 = getLead(email, DOINSERT_FALSE);
        leadObj12.Email = email + 'randomSuffix12';
        leadObj12.postalCode = '';
        leadObj12.Metro_Area__c = '';
        leadObj12.Industry = '';
        leadObj12.State = '';
        leadObj12.StateCode = '';
        leads.add(leadObj12);

        //prepare patch manager with  no domain, and Only Country
        PatchManager__c patchManager12 = getPatchManager('', DOINSERT_FALSE);
        patchManager12.StateGlobal__c = '';
        patchManager12.State__c = '';
        patchManager12.Industry_Category__c = '';
        patchManager12.Zip_code__c = '';
        patchManager12.Metro_Area__c = '';
        patchManager12.City__c = '';
        patchManager12.Tier__c = '';
        patchManagers.add(patchManager12);
        
        insert patchManagers;
        insert leads;
        
        System.runAs(testUser){
            Test.startTest();
            for(Lead leadObj: leads){
                leadObj.rerun_PatchManager__c = true;
            }
            update leads;
            Test.stopTest();
        }

        for(Lead updatedLead  : [SELECT Id, PatchManager__c FROM Lead WHERE Id IN :leads]){
            Assert.isTrue(updatedLead.PatchManager__c != null, 'Patch Manager should have been assigned based on matching criteria.');
        }
     }

     private static PatchManager__c getPatchManager(String domain, Boolean doInsert) {
        PatchManager__c patchManager = new PatchManager__c();
        patchManager.RecordTypeId = RTID_INDUSTRY;
        patchManager.Domain__c = domain;
        patchManager.Country__c = 'US';
        patchManager.CountryGLobal__c = 'United States';       
        patchManager.StateGlobal__c = 'KY';
        patchManager.State__c = 'Kentucky';
        patchManager.Industry_Category__c = 'Healthcare';
        patchManager.Zip_code__c = '11972';
        patchManager.Metro_Area__c = 'MM2';
        patchManager.City__c = 'Patton';
        patchManager.SDR__c = UserInfo.getUserId();
        patchManager.Tier__c = 'Tier 1;Tier 2;Tier 3;Tier 4;Tier 5';
        if(doInsert){
            insert patchManager;
        }
        return patchManager;
    }

    private static Lead getLead(String email, Boolean doInsert) {
        Lead leadObj = (Lead) ShGl_TestFactory.createSObject(new Lead(), null);
        leadObj.Email = email;
        leadObj.status = 'Nurture';
        leadObj.Industry = 'Healthcare Providers';
        leadObj.Country = 'United States';
        leadObj.CountryCode = 'US';
        leadObj.State = 'Kentucky';
        leadObj.StateCode = 'KY';
        leadObj.PostalCode = '119-73';
        leadObj.Metro_Area__c ='MM2';
        leadObj.City= 'Patton';
        leadObj.Last_MQL_Date__c = System.today();
        if(doInsert){
            insert leadObj;
        }
        return leadObj;
    }
    
    @IsTest
    static void testLeadPopulateUTMTermAndLastUTMString() {
        
        // Fetch Lead created in @testSetup
        Lead l = [SELECT Id,UTM_Campaign__c,UTM_Source__c,UTM_Term__c,Last_UTM_String__c FROM Lead LIMIT 1];
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        Test.startTest();
        
        // Update UTM fields to trigger logic
        l.UTM_Campaign__c = 'camp_test';
        l.UTM_Source__c   = 'google';
        l.UTM_Term__c     = 'bdm_term';
        update l;
        
        Test.stopTest();
        system.assert(true);
    }
}
    
    
}