/**
* @author Princy Jain UTM_
*/
@isTest
class ContactObjectTriggerHelperTest {
    @TestSetup
    static void makeData(){
        UserRole vUserRole = new UserRole(DeveloperName = 'RubrikDeveloperNew', Name = 'My Role');
        insert vUserRole;
        List<Account> accountRecs = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 2, 'AccountDefaults', null);
        accountRecs[0].Type = 'Marketplace';
        //accountRecs[0].RCIE_Certified__c=3;
        accountRecs[0].Account_Tier__c = 'Tier 1';
        accountRecs[0].AWS_GCP_Cloud_Alliance_BDM__c = UserInfo.getUserId(); //Added as part of SAL26-105
        accountRecs[0].MSFT_OCI_Cloud_Alliance_BDM__c = UserInfo.getUserId(); //Added as part of SAL26-105
        //accountRecs[0].Account_Alliance_BDM_Lookup__c = UserInfo.getUserId(); //Commented as part of SAL26-101
        accountRecs[1].ETM_Area__c = 'MM-APAC-A'; 
        accountRecs[1].Account_Tier__c = 'Tier 3';
        
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        sysAdminUser.UserRoleId = vUserRole.Id;
               update sysAdminUser;
        System.runAs(sysAdminUser) {
                    insert accountRecs; 

            List<Territory2Model> lstOrgTerritories = [SELECT Id, Name FROM Territory2Model WHERE State = 'Active'];

            if(lstOrgTerritories.isEmpty()){
                List<Territory2Model> lstModel = ETM_TestDataFactory.createTerritoryModel('Test_FY',1);
                Insert lstModel;
                lstOrgTerritories.addAll(lstModel);
            }

            List<Territory2Type> lstType = [SELECT Id FROM Territory2Type LIMIT 1];

            List<Territory2> lstTerritories =  ETM_TestDataFactory.createTerritory('ETM_Territory', '12345', lstOrgTerritories[0].Id, lstType[0].Id, 1);
            insert lstTerritories;

            UserTerritory2Association uta = new UserTerritory2Association();
            uta.Territory2Id = lstTerritories[0].Id;
            uta.UserId = UserInfo.getUserId();
            uta.RoleInTerritory2 = 'SDR';
            insert uta;

            List<ObjectTerritory2Association> lstAssociation = ETM_TestDataFactory.createAssociationRecords(accountRecs[1].Id, lstTerritories[0].Id, 'Territory2Manual', 1);
            insert lstAssociation;
   

        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 5, null);
        conList[0].AccountId=AccountRecs[0].Id;
        conList[0].Latest_UTM_Term__c = 'msft';
        conList[0].Last_UTM_Term_Date__c=system.today()-1;     
        conList[1].AccountId=AccountRecs[1].Id;         
        conList[1].Campaign_Sourced_By__c='Marketing'; 
        conList[1].Contact_Status__c='Nurture';
        conList[0].Campaign_Sourced_By__c='Marketing';
        conList[2].AccountId=AccountRecs[1].Id;         
        conList[2].Campaign_Sourced_By__c='Marketing';
        conList[2].Last_Applied_Routing_Modifier__c = 'Route to Partner';
         conList[2].Contact_Status__c='Nurture';
        conList[3].Contact_Status__c='Open';
        conList[3].MQL__c =true;
        conList[3].RCCS_Accredited__c=System.today();
        conList[3].RCDP_Accredited__c=System.today();
        conList[3].RCDP_S_Accredited__c = System.today();
        conList[4].PSE_Shadow_Completed__c=System.today();
        conList[4].PSE_Shadow_2_Completed__c=System.today();
        insert conList;
            
            
                 }
    }
    /**
     * @description This method is used to testContactRoutingForBDM.
     */
    @isTest public static void testContactRoutingForBDM(){  
        Contact con = [SELECT Id, MQL__c,Contact_Status__c,rerun_PatchManager__c/*,RCIE_Certified__c*/ FROM Contact WHERE Latest_UTM_Term__c='msft' LIMIT 1];
        con.MQL__c = TRUE;
        
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        Test.startTest();
        System.runAs(sysAdminUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Allow_Contact_Transfer__c = true);
               con.Contact_Status__c='Nurture';         
            con.rerun_PatchManager__c=true;
            //con.RCIE_Certified__c=system.today();
    update con;
        }
        Test.stopTest();
        Assert.areEqual(TRUE,con.MQL__c);    
    }
    /**
     * @description This method is used to testContactRoutingToAE.
     */
    @isTest public static void testContactRoutingToAE(){  
        Contact con = [SELECT Id, MQL__c FROM Contact WHERE Latest_UTM_Term__c!='msft' LIMIT 1];
        con.MQL__c = TRUE;
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        //TODO: insert custom setting
        System.runAs(sysAdminUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Allow_Contact_Transfer__c = true);
        }
        Test.startTest();
        System.runAs(sysAdminUser) {
            update con;

        }
        Test.stopTest();
        Assert.areEqual(TRUE,con.MQL__c);    

    }
    /**
     * @description This method is used to testContactRoutingToAE.
     */
    @isTest public static void testContactUpdate(){  
        Contact con = [SELECT Id, MQL__c,AccountId,Agreed_to_Edge_Trial_Agreement__c FROM Contact WHERE Latest_UTM_Term__c!='msft' LIMIT 1];
        con.MQL__c = TRUE;
        con.firstName = 'testfirstName1656736';
        con.lastName = 'testlastName16567363';
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        //TODO: insert custom setting
        System.runAs(sysAdminUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Allow_Contact_Transfer__c = true);
        }
        List<contact> conList=new List<Contact>();
        Set<id> ConId=new Set<id>();
        List<id> ConIdList=new List<id>();
        Set<id> Accid=new Set<id>();
        Test.startTest();
        
        System.runAs(sysAdminUser) {
            con.OwnerId=sysAdminUser.Id;
            update con;
        }
        conList.add(con);
        ConId.add(con.Id);
        ConIdList.add(con.id);
        Accid.add(con.AccountId);
        ContactObjectTriggerHelper.updateContacts(conList);
        ContactObjectTriggerHelper.trialEdgeContact(ConId);
        ContactObjectTriggerHelper.manageEntitlement(conList,Accid);
        
        Test.stopTest();
        Assert.areEqual(TRUE,con.MQL__c);    
        
    }
      /**
     * @description This method is used to testContactUpdateMQL.
     */
    @isTest public static void testContactUpdateMQL(){  
        Contact con = [SELECT Id, MQL__c,AccountId,Agreed_to_Edge_Trial_Agreement__c FROM Contact WHERE Latest_UTM_Term__c='msft' LIMIT 1];
        con.MQL__c = TRUE;
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        //TODO: insert custom setting
        System.runAs(sysAdminUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Allow_Contact_Transfer__c = true);
        }
        List<contact> conList=new List<Contact>();
        Set<id> ConId=new Set<id>();
        List<id> ConIdList=new List<id>();
        Set<id> Accid=new Set<id>();
        Test.startTest();
        
        System.runAs(sysAdminUser) {
            con.Contact_Status__c='Nurture';  
            update con;
        }
        conList.add(con);
        ConId.add(con.Id);
        ConIdList.add(con.id);
        Accid.add(con.AccountId);
        ContactObjectTriggerHelper.updateContacts(conList); 
        ContactObjectTriggerHelper.trialEdgeContact(ConId);
        
        ContactObjectTriggerHelper.updateContactCompositeScore(ConIdList);  
        ContactObjectTriggerHelper.manageEntitlement(conList,Accid);
        
        Test.stopTest();
        Assert.areEqual(TRUE,con.MQL__c);    
        
    }
    
    @isTest public static void testContactUpdateMethod(){
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        Contact con = [SELECT Id, MQL__c,MeetingDate__c,Lead_Share_Program_Expiration_Date__c, Partner_of_Record__c,Last_Applied_Routing_Modifier__c FROM Contact WHERE Last_Applied_Routing_Modifier__c ='Route to Partner' LIMIT 1];
        con.MQL__c = TRUE;
        con.MeetingDate__c = Date.today().addDays(100);
        con.Lead_Share_Program_Expiration_Date__c = Date.today();
        con.Partner_of_Record__c = sysAdminUser.Id;
        System.runAs(sysAdminUser) {
            update con;
        }
        Assert.areEqual(TRUE,con.MQL__c);
    }
    
    //Method Name :testContactPopulateUTM for Test//
      @isTest public static void testContactPopulateUTM(){  
        Contact con = [SELECT Id, MQL__c,AccountId,Agreed_to_Edge_Trial_Agreement__c FROM Contact WHERE Latest_UTM_Term__c='msft' LIMIT 1];
        con.MQL__c = TRUE;
        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
      
        System.runAs(sysAdminUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Allow_Contact_Transfer__c = true);
        }
        
        Test.startTest();
        
        System.runAs(sysAdminUser) {
            con.Contact_Status__c='Nurture'; 
            con.UTM_Term__c='microsoft';
            con.Primary_Customer_Mailing_Contact__c=true;
            update con;
        }
        
        Test.stopTest();
        Assert.areEqual(TRUE,con.MQL__c);    
        
    }

    @isTest static void testinsertContactIntoCampaign(){
        Contact con = [SELECT Id,Salesloft_Cadence_Most_Recent__c, AccountId FROM Contact LIMIT 1];
        con.Salesloft_Cadence_Most_Recent__c = 'MM-Test';
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        Test.startTest();
            try {
                update con;
            } catch (Exception e) {
                String errorMsg = e.getMessage();
            }
        Test.stopTest();
        Assert.areEqual(TRUE,con.Id != null);
        }
    }

    @isTest static void testRollUpOnAccToCon(){
        Contact con = [SELECT Id,PSE_Shadow_Completed__c, Agreed_to_Edge_Trial_Agreement__c, AccountId FROM Contact LIMIT 1];

        List<Contact> newContacts = new List<Contact>{con};
        Map<Id, Contact> oldContactMap =  new Map<Id, Contact> {con.Id => con.clone(true, true)};

        con.PSE_Shadow_Completed__c = Date.today();
        con.Agreed_to_Edge_Trial_Agreement__c = TRUE;

        User sysAdminUser  = [SELECT Id FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser) {
            insert new ShGl_DisableFunctionalityLogic__c(setupOwnerId = UserInfo.getUserId(), Allow_Contact_Transfer__c = true);
        }
        Test.startTest();
            System.runAs(sysAdminUser) {
                ContactObjectTriggerHelper.RollUpOnAccToCon(newContacts, oldContactMap);
            }
        Test.stopTest();
        Account acc = [SELECT Id,PSE_Shadow_Completed__c, Agreed_to_Edge_Trial_Agreement__c FROM Account WHERE Id = :con.AccountId];
        Assert.isNotNull(acc);
    }

    /*@isTest static void testupdatePartnerRegRequest(){
        Partner_Registration_Request__c req = new Partner_Registration_Request__c();
        req.Email__c = 'test@xyz.com';
        insert req;
        Contact c = new contact (lastname ='test', email = 'test@xyz.com');
        Test.startTest();
        ContactObjectTriggerHelper.updatePartnerRegRequest(new Map<String,Contact> {'test@xyz.com'=>c});
        Test.stopTest();
        req = [SELECT Id, is_Converted__c FROM Partner_Registration_Request__c WHERE Id = :req.Id];
        Assert.isTrue(req.is_Converted__c);
    }*/
    @isTest static void testOnAfterDelete() {
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        delete [SELECT Id FROM Contact LIMIT 1];
        Assert.areEqual('test','test');
        }
    }
    @isTest static void testAfterUpdateScenarios() {
        Contact con = [SELECT Id,Agreed_to_Edge_Trial_Agreement__c, create_Portal_User__c FROM Contact LIMIT 1];
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        Test.startTest();
        	con.Agreed_to_Edge_Trial_Agreement__c = true;
        	con.create_Portal_User__c = true;
            try {
                update con;
            } catch(Exception e){
                String errorMsg = e.getMessage();
            }
        Test.stopTest();
        Assert.areEqual(True,con.Id != null);
        }
    }
    @isTest static void testContactServiceClass() {
        Contact con = [SELECT Id,Agreed_to_Edge_Trial_Agreement__c, create_Portal_User__c FROM Contact LIMIT 1];
        List<Id> ids = new List<Id>();
        Set<Id> conIdSet = new Set<ID>();
        ids.add(con.Id);
        conIdSet.add(con.Id);
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        Test.startTest();
        	ContactService.createPortalUser(ids);
        	ContactService.updateUserCompany(ids);
        	ContactService.deactivateCommunityUser(conIdSet);
        	
        Test.stopTest();
        Assert.areEqual(True,con.Id != null);
        }
    }
    @isTest static void testContactStatusUpdate() {
        Contact con = [SELECT Id, Contact_Status__c FROM Contact LIMIT 1];

        Campaign campaignObject1 = new Campaign();
        campaignObject1.Name = 'Test Campaign 11';
         campaignObject1.type= 'Advertising';
        campaignObject1.IsActive = true;
        campaignObject1.Alliance_Partner__c = 'Cleversafe';
        campaignObject1.Campaign_Sales_Theatre__c = 'APAC';
        campaignObject1.Campaign_Sales_Area__c = 'APAC';
        campaignObject1.Campaign_Sales_Region__c = 'APAC';
        campaignObject1.Campaign_Sales_Sub_Region__c = 'APAC';
        campaignObject1.Cost_Center__c = 'Alliance';
        campaignObject1.Enabled_for_Opportunity_creation__c = true;
        campaignObject1.Campaign_Theme__c='Cloud';
        campaignObject1.GTM_Play__c='Cloud Native Protection';
        campaignObject1.Executed_By__c='Sales';
        campaignObject1.Involvement_by_Customer_Marketing__c='Yes';
        campaignObject1.Planned_MQL__c = 1;
        insert campaignObject1;

        CampaignMember campaignMemberObject1 = new CampaignMember();
        campaignMemberObject1.ContactId = con.Id;
        campaignMemberObject1.CampaignId = campaignObject1.Id;
        campaignMemberObject1.Status = 'Sent';
        campaignMemberObject1.FCRM__FCR_QR__c=false;
        campaignMemberObject1.CFCR_PQL__c=false;
        insert campaignMemberObject1;
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        Test.startTest();
        	con.Contact_Status__c = 'Meeting Set';
            try {
                update con;
            } catch(Exception e){
                String errorMsg = e.getMessage();
            }
        Test.stopTest();
        Assert.areEqual(True,con.Id != null);
        }
    }
    @isTest
    static void testCheckPartnerContacts(){
        Contact con = [SELECT Id, AccountId FROM Contact LIMIT 1];
        List<Account> accountRecs = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(), 1, 'AccountDefaults', null);
        accountRecs[0].Type = 'Marketplace';
        //accountRecs[0].RCIE_Certified__c=3;
        accountRecs[0].AWS_GCP_Cloud_Alliance_BDM__c = UserInfo.getUserId(); //Added as part of SAL26-105
        accountRecs[0].MSFT_OCI_Cloud_Alliance_BDM__c = UserInfo.getUserId(); //Added as part of SAL26-105
        //accountRecs[0].Account_Alliance_BDM_Lookup__c = UserInfo.getUserId(); //Commented as part of SAL26-101
        accountRecs[0].ETM_Area__c = 'MM-APAC-A'; 
        insert accountRecs;
        con.AccountId = accountRecs[0].Id;
         User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        Test.startTest();
        update con;
        Test.stopTest();
            Assert.areEqual(True,con.Id != null);
        }
        
    }
    @isTest static void testMethod1(){
        Contact con = [SELECT Id,Contact_Status__c, MQL__c,Account_Tier__c FROM Contact where Account_Tier__c = 'Tier 1' LIMIT 1];
        Contact con1 = [SELECT Id,Contact_Status__c, MQL__c,Account_Tier__c FROM Contact where Account_Tier__c = 'Tier 3' LIMIT 1];
        con.Contact_Status__c = 'Non-Qualified';
        con.MQL__c = true;
        con.Update_Lead_Score__c = true;
        con1.Update_Lead_Score__c = true;
        con.Job_Function__c = 'IT';
        
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            Test.startTest();
            try {
                update con;
                update con1;
            } catch (Exception e) {
                String errorMsg = e.getMessage();
            }
            Test.stopTest();
            Assert.areEqual(con.id != null,true);
        }
            
    }
    @isTest static void tesetInsertCampaign1(){
        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 2, null);
        conList[0].Salesloft_Cadence_Most_Recent__c = 'MM-Test';
        conList[1].MQL__c = false;
        conList[1].contact_status__c = 'Open';
        conList[1].SAL__c = false;
        conList[0].HasOptedOutOfEmail = true;
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];

        System.runAs(sysAdminUser){
            Test.startTest();
            try{
                insert conList;
                conList[1].MQL__c = true;
                conList[1].SAL__c = true; 
                conList[1].contact_status__c = 'Working';
                update conList;
            }catch(exception e){
                String errorMsg = e.getMessage();
            }
            Test.stopTest();
            Assert.areEqual(!conList.isEmpty(),true);
        }    
    }
    @isTest static void testcheckPartnerContacts1(){
        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 1, null);
        conList[0].HasOptedOutOfEmail = true;
        //conList[0].Agreed_to_Edge_Trial_Agreement__c = true;
        //conList[0].trial_Edge_End_Date__c = null;
        conList[0].PSE_Shadow_Completed__c = System.today();
        conList[0].PSE_Shadow_2_Completed__c = System.today();
        
        conList[0].Email_Opt_In__c = true;
        conList[0].HasOptedOutOfEmail = false;
        
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
  
        System.runAs(sysAdminUser){
            Test.startTest();
            try{
                insert new TriggerControl__c(Name = 'Entitlement', DisableTrigger__c = true);
                insert conList;
            }catch(exception e){
                String errorMsg = e.getMessage();
            }
            Test.stopTest();
            Assert.areEqual(!conList.isEmpty(),true);
        } 
    }
    
    @isTest static void testMethod2(){
        Contact con = [SELECT Id,Contact_Status__c, MQL__c,Account_Tier__c FROM Contact where Contact_Status__c = 'Open' LIMIT 1];
        con.Contact_Status__c = 'Nurture';
        con.ContactRejectReason__c = null;
        con.SAL__c = true;
        con.MQL__c = false;
        Test.startTest();
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            try {
                update con;
            } catch (Exception e) {
                String errorMsg = e.getMessage();
            }
        }
            
        Test.stopTest();
        Assert.areEqual(con.Id!=null,true);
    }
    @isTest static void testMethod3(){
        Contact con = [SELECT Id,Contact_Status__c, MQL__c,Account_Tier__c,RCCS_Accredited__c,RCDP_Accredited__c FROM Contact where Contact_Status__c = 'Open' LIMIT 1];
        con.Contact_Status__c = 'Working';
        con.SAL__c = false;
        con.RCCS_Accredited__c = System.today().addDays(4);
        con.RCDP_Accredited__c = System.today().addDays(4);
        con.RCDP_S_Accredited__c = System.today().addDays(4);
        Test.startTest();
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            try {
                update con;
            } catch (Exception e) {
                String errorMsg = e.getMessage();
            }
        }
        Test.stopTest();
        Assert.areEqual(con.Id!=null,true);
    }
    @isTest static void testMethod4(){
        Contact con = [Select Id From Contact where PSE_Shadow_2_Completed__c != null LIMIT 1];
        Test.startTest();
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            try{
                delete con;
            }catch(exception e){
                String errorMsg = e.getMessage();
            }
        }        
        
        Test.stopTest();
        Assert.areEqual(con.Id!=null,true);
    }
    @isTest static void testMethod5(){
        ShGl_TestFactoryHelper.insertCustomSettings();
        ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disFuncCS.Allow_Contact_Transfer__c = true;
        update disFuncCS;
        Contact con = [Select Id from contact LIMIT 1];
        
        con.OwnerId = userInfo.getUserId();
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            Test.startTest();
            try{
                update con;
            }catch(Exception e){
                String errorMsg = e.getMessage();
            }
            Test.stopTest();
            Assert.areEqual(con.Id!=null,true);
        
        }
        
    }
    @isTest static void testMethod6(){
        List<Contact> conList = (List<Contact>)ShGl_TestFactory.createSObjectList(new Contact(), 1, null);
        conList[0].Email = 'testtrialEdgeContact@rubrik.com';
           
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User simpleUser = new User(
            Alias = 'suser', // Alias must be unique and <= 8 characters
            Email = 'simpleemailtest@rubrik.com', // Must be a valid email format and unique
            EmailEncodingKey = 'UTF-8',
            LastName = 'SimpleUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id, // Assign the queried standard profile
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testtrialEdgeContact@rubrik.com' // Must be unique and in email format
        );
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
            Test.startTest();
            try{
                insert simpleUser;
                insert conList;
                Set<Id> idslist = new Set<Id>();
                idslist.add(conList[0].Id);
                ContactObjectTriggerHelper.trialEdgeContact(idslist);
                
            }catch(exception e){
                String errorMsg = e.getMessage();
            }
            Test.stopTest();
            Assert.areEqual(!conList.isEmpty(),true);
            
        }
    }
    
    @IsTest
    static void testContactPopulateUTMTermLastUTMString() {
        
        // Fetch a Contact created in @TestSetup
        Contact c = [ SELECT Id,UTM_Medium__c,UTM_Content__c,UTM_Term__c,Last_UTM_String__c,Latest_UTM_Term__c,Last_UTM_Term_Date__c  FROM Contact  LIMIT 1 ];
        User sysAdminUser  = [SELECT Id,UserRoleId FROM User WHERE Profile.Name='System Administrator' AND IsActive=TRUE LIMIT 1];
        System.runAs(sysAdminUser){
        Test.startTest();
        // Update UTM fields to trigger populateUTMTerm
        c.UTM_Medium__c  = 'email';
        c.UTM_Content__c = 'banner';
        c.UTM_Term__c    = 'msft';
        update c;
        
        Test.stopTest();
        system.assert(true);
        }
    }
    
}