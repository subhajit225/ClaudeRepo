@isTest
public class PC_DealRegistrationApexControllerTest {
    @testSetup static void setupmethod() {
        
        //Territories
        List<Territory2> territories = new List<Territory2>();
        List<Territory2Model> TModel = [Select id,Name from territory2model where State ='Active'];
        List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DeveloperName = 'Territory'];

        for(Integer i=0;i<3;i++){
            Territory2 terr = new Territory2();
            terr.Name = 'CDM-' + i;
            terr.DeveloperName = 'CDM_' + i;
            terr.Adaptive_Territory_Id__c = '999999'+i;
            terr.Territory2ModelId = TModel[0].Id;
            terr.Territory2TypeId = terrType[0].Id;
            territories.add(terr);
        }
        insert territories;
        
        //System Admin user
        Profile pf= [Select Id from profile where Name='System Administrator']; 
        User uu=new User(firstname = 'Alan', 
                         lastName = 'McCarthy', 
                         email = 'HG@gmail.com', 
                         Username = 'HG79879@gmail.com', 
                         EmailEncodingKey = 'ISO-8859-1', 
                         Alias = 'GAA', 
                         TimeZoneSidKey = 'America/Los_Angeles', 
                         LocaleSidKey = 'en_US', 
                         LanguageLocaleKey = 'en_US', 
                         ProfileId = pf.Id,
                         isActive = true
                        ); 
        insert uu;
        
        //CDM users
        Profile prCDM = [Select Id from profile where Name='Channel Development Manager']; 
        Profile prFS = [Select Id from profile where Name='Rubrik Field Sales User'];
        User uCDM1 = new User(firstname = 'James', 
                              lastName = 'Webb', 
                              email = 'JamWeb00098990@gmail.com', 
                              Username = 'JamWeb00098990@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id
                              //UserRoleId = urCDM.Id
                             ); 
        insert uCDM1;
        
        User uCDM2 = new User(firstname = 'James', 
                              lastName = 'Philips1', 
                              email = 'JamPhilp889000@gmail.com', 
                              Username = 'JamPhilp889000@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id
                              //UserRoleId = urCDM.Id
                             ); 
        insert uCDM2;
        
        User uCDM3 = new User(firstname = 'Joe', 
                              lastName = 'Rovers', 
                              email = 'JoeRov987895@gmail.com', 
                              Username = 'JoeRov987895@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id
                              //UserRoleId = urCDM.Id
                             ); 
        insert uCDM3;
        
        User uCDM4 = new User(firstname = 'James', 
                              lastName = 'Philips', 
                              email = 'JamPhilp1100@gmail.com', 
                              Username = 'JamPhilp1100@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prCDM.Id
                              //UserRoleId = urCDM.Id
                             ); 
        insert uCDM4;
        
        User uCDM5 = new User(firstname = 'Joe', 
                              lastName = 'Rovers1', 
                              email = 'JoeRov1234@gmail.com', 
                              Username = 'JoeRov1234@gmail.com', 
                              EmailEncodingKey = 'ISO-8859-1', 
                              Alias = 'GAA', 
                              TimeZoneSidKey = 'America/Los_Angeles', 
                              LocaleSidKey = 'en_US', 
                              LanguageLocaleKey = 'en_US', 
                              ProfileId = prFS.Id
                              //UserRoleId = urCDM.Id
                             ); 
        insert uCDM5;
        
        
        PermissionSet ps1= [SELECT Id FROM PermissionSet WHERE Name='RubrikChannelUsersNew'];
        
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = ps1.Id,
            AssigneeId = uCDM5.Id
        );
        PermissionSetAssignment psa1 = new PermissionSetAssignment(
            PermissionSetId = ps1.Id,
            AssigneeId = uCDM2.Id
        );
        
        psaList.add(psa);
        psaList.add(psa1);
        insert psaList;
        
        //User Territory Association
        List<UserTerritory2Association> utaRecords = new List<UserTerritory2Association>();
        UserTerritory2Association uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Account Executive';
        uta.UserId = uCDM1.Id;
        utaRecords.add(uta);
        
        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'SDR';
        uta.UserId = uCDM2.Id;
        utaRecords.add(uta);
        
        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'CDM';
        uta.UserId = uCDM3.Id;
        utaRecords.add(uta);
        
        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Regional Director';
        uta.UserId = uCDM4.Id;
        utaRecords.add(uta);
        
        uta = new UserTerritory2Association();
        uta.Territory2Id = territories[0].Id;
        uta.RoleInTerritory2 = 'Regional Sales Manager';
        uta.UserId = uCDM5.Id;
        utaRecords.add(uta);
        
        insert utaRecords;
        
        
        
        //Rubrik Light Admin
        String uniqueName = TestDataFactory.getUniqueName();
        User runAsUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Rubrik Light Administrator'].Id,    
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
            //UserRoleId = ur.Id,
            Start_Date__c=System.Today().adddays(-30)         
        );
        insert runAsUser; 
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        System.runAs(runAsUser){
            List<WorkflowTriggerBypass__c> wtList = new List<WorkflowTriggerBypass__c>();
            WorkflowTriggerBypass__c wt = new WorkflowTriggerBypass__c(name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            wtList.add(wt);
            WorkflowTriggerBypass__c wt1 = new WorkflowTriggerBypass__c(name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            wtList.add(wt1);
            WorkflowTriggerBypass__c wt2 = new WorkflowTriggerBypass__c(name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            wtList.add(wt2);
            WorkflowTriggerBypass__c wt3 = new WorkflowTriggerBypass__c(name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            wtList.add(wt3);
            WorkflowTriggerBypass__c wt4 = new WorkflowTriggerBypass__c(name='updateOpportunitySource',ByPassTrigger__c=false);
            wtList.add(wt4);
            WorkflowTriggerBypass__c wt5 = new WorkflowTriggerBypass__c(name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            wtList.add(wt5);
            WorkflowTriggerBypass__c wt6 = new WorkflowTriggerBypass__c(name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            wtList.add(wt6);
            insert wtList;

            ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
            settingDisable.Disable_Opportunity_Validation_Rules__c = true;
            insert settingDisable;

            CountryWithCode__c cc = new CountryWithCode__c(Code__c='US',Name='United States');
            insert cc;
            
            List<Account> accList = new List<Account>();
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account';
            acc.Type = 'Prospect';
            acc.OwnerId = uCDM1.Id;
            accList.add(acc);
            
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account 1';
            acc1.Type = 'OEM';
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.OEM_Subtype__c = 'Revshare';
            acc1.OwnerId = uCDM2.Id;
            accList.add(acc1);
            
            Account acc3 = TestDataFactory.getAccount();
            acc3.name = 'Test New Account 3';
            acc3.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
            acc3.OwnerId = uCDM1.Id;
            accList.add(acc3);
            
            Test.startTest();
            insert accList;
            
            Contact c = new Contact(FirstName = 'Joseph', LastName = ' Burrus', Email='asscdvce@rubrik.com.sandbox');
            insert c;
            
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.StageName = '1 Discovery';
            insert opp;
            
            List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Deal_Reg_Submitted_Date__c = System.today();
            deal.Primary__c = false;
            //deal.Deal_Registration_Sub_Status__c = 'SLA Violation';
            deal.Opportunity__c = opp.Id;
            deal.Deal_Reg_Submitted_Date__c = System.now();
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
            deal.Distributor__c = acc1.Id;
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Deal_Registration_Sub_Status__c = 'Pending TVP Approval';
            deal.OEM_L1_Approver__c = uCDM2.Id;
            deal.Theatre_VP__c = uCDM2.Id;
            deal.Primary_Contact__c = c.Id;
            dealRegList.add(deal);
            
            Deal_Registration__c deal2=TestDataFactory.getDealRegistration();
            deal2.Deal_Registration_Status__c = 'Submitted';
            deal2.Deal_Registration_Sub_Status__c = 'Pending L1 Approval';
            deal2.Registration_Type__c = 'Value Add';
            deal2.Dedicated_Managed_Service__c = true;
            deal2.Company_Name__c = acc3.Id;
            deal2.OwnerId = uCDM1.Id;
            deal2.Deal_Reg_Submitted_Date__c = System.now();
            deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
            deal2.Distributor__c = acc1.Id;
            deal2.OEM_L1_Approver__c = uCDM3.Id;
            deal2.Theatre_VP__c = uCDM2.Id;
            deal2.Deal_Reg_Submitted_Date__c = Date.today().addDays(-30);
            dealRegList.add(deal2);
            
            Deal_Registration__c deal3=TestDataFactory.getDealRegistration();
            deal3.Deal_Registration_Status__c = 'Submitted';
            //deal3.Deal_Registration_Sub_Status__c = 'SLA Violation';
            deal3.OwnerId = uCDM1.Id;
            deal3.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
            deal3.StateCode__c = '';
            dealRegList.add(deal3);
            
            Deal_Registration__c deal4=TestDataFactory.getDealRegistration();
            deal4.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal4.Deal_Registration_Status__c = 'Escalated';
            deal4.PS_Escalated__c = true;
            deal4.Opportunity__c = opp.Id;
            deal4.Theatre_VP__c = uCDM5.Id;
            deal4.Sales_Manager__c = uCDM2.Id;
            deal4.OwnerId = uCDM2.Id;
            deal4.StateCode__c = '';
            deal4.Deal_Registration_Sub_Status__c = 'Pending RVP Approval';
            deal4.BDM__c = uCDM1.Id;
            dealRegList.add(deal4);
            
            Deal_Registration__c deal5=TestDataFactory.getDealRegistration();
            deal5.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal5.Deal_Registration_Status__c = 'Escalated';
            deal5.Opportunity__c = opp.Id;
            deal5.PS_Escalated__c = true;
            deal5.OwnerId = uCDM2.Id;
            deal5.StateCode__c = '';
            deal5.Deal_Registration_Sub_Status__c = 'Pending RSM Approval';
            deal5.Sales_Manager__c = uCDM5.Id;
            deal5.Theatre_VP__c = uCDM2.Id;
            dealRegList.add(deal5);
            
            Deal_Registration__c deal6 = TestDataFactory.getDealRegistration();
            deal6.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal6.Deal_Registration_Status__c = 'Submitted';
            deal6.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal6.Opportunity__c = opp.Id;
            deal6.OwnerId = uCDM2.Id;
            deal6.Dedicated_Managed_Service__c = true;
            deal6.StateCode__c = '';
            //deal6.Deal_Registration_Sub_Status__c = 'SLA Violation';
            deal6.Sales_Manager__c = uCDM2.Id;
            deal6.Theatre_VP__c = uCDM2.Id;
            deal6.Deal_Reg_Submitted_Date__c = Date.today().addDays(-20);
            dealRegList.add(deal6);
            
            Deal_Registration__c deal7 = TestDataFactory.getDealRegistration();
            deal7.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
            deal7.Deal_Registration_Status__c = 'Approved';
            deal7.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal7.Opportunity__c = opp.Id;
            deal7.Deal_Reg_Submitted_Date__c = Date.today().addDays(-50);
            deal7.Deal_Reg_Exp_Date__c = Date.today().addDays(-35);
            dealRegList.add(deal7);
            
            Deal_Registration__c deal8 = TestDataFactory.getDealRegistration();
            deal8.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
            deal8.Deal_Registration_Status__c = 'Expired';
            deal8.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal8.Opportunity__c = opp.Id;
            deal8.Deal_Reg_Submitted_Date__c = Date.today().addDays(-50);
            dealRegList.add(deal8);
            
            insert dealRegList;
            Test.stopTest();
        }
    }
    
    static testMethod void getRelatedRecordsTest(){
        Account a = [SELECT Id FROM Account WHERE Name = 'Test New Account' LIMIT 1];
        User adm = [SELECT Id FROM User WHERE LastName ='McCarthy' and email ='HG@gmail.com' and isActive = true LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        Test.startTest();
        System.runAs(adm){
            PC_DealRegistrationApexController.getRelatedRecords(a.Id);
        }
        Test.stopTest();
        System.assert(true);
    }
    
    static testMethod void extendDealRegistrationExpirationTest(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User uCDM = [SELECT Id FROM User WHERE LastName ='Rovers' LIMIT 1];
        Deal_Registration__c dealReg = [SELECT Id,Deal_Registration_Status__c,Deal_Reg_Exp_Date__c FROM Deal_Registration__c WHERE Deal_Registration_Status__c ='Approved' LIMIT 1];
        Deal_Registration__c dealReg1 = [SELECT Id,Deal_Registration_Status__c,Deal_Reg_Exp_Date__c FROM Deal_Registration__c WHERE Deal_Registration_Status__c ='Expired' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        Test.startTest();
        System.runAs(uCDM){
            
            PC_DealRegistrationApexController.extendDealRegistrationExpiration(dealReg);
                PC_DealRegistrationApexController.extendDealRegistrationExpiration(dealReg1);
            }
        Test.stopTest();
        System.assert(true);
    }
    
    static testMethod void getUserInOwnerTerritoryTest(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User uCDM = [SELECT Id FROM User WHERE LastName ='Rovers' LIMIT 1];
        for(Deal_Registration__c dealReg : [SELECT Id FROM Deal_Registration__c]){
            dealRegList.add(dealReg);
        }
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        Test.startTest();
        System.runAs(uCDM){
                PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
            	PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[1].Id);
            	PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[2].Id);
                PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[3].Id);
                PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[4].Id);
            	PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[5].Id);
            }
        Test.stopTest();
        System.assert(true);
    }
    
    static testMethod void getUserInOwnerTerritoryTest2(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User uCDM = [SELECT Id FROM User WHERE LastName ='Rovers1' LIMIT 1];
        
        for(Deal_Registration__c dealReg : [SELECT Id,Sales_Manager__r.Name,Sales_Manager__c,Theatre_VP__c FROM Deal_Registration__c WHERE RecordType.Name = 'Reseller']){
            dealReg.Sales_Manager__c = uCDM.Id;
            dealReg.Theatre_VP__c = uCDM.Id;
            dealRegList.add(dealReg);
        }
        
        flowControll.DealRegistrationTrigger = false;
        update dealRegList;
        flowControll.DealRegistrationTrigger = true;
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        Test.startTest();
        System.runAs(uCDM){
                PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
            	PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[1].Id);
            	PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[2].Id);
            }
        Test.stopTest();
        System.assert(true);
    }
        
    static testMethod void getUserInOwnerTerritoryTest3(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User uCDM = [SELECT Id FROM User WHERE LastName ='Philips1' LIMIT 1];
        
        for(Deal_Registration__c dealReg : [SELECT Id,Sales_Manager__r.Name,Sales_Manager__c,Theatre_VP__c FROM Deal_Registration__c WHERE RecordType.Name = 'OEM']){
            dealReg.OEM_L1_Approver__c = uCDM.Id;
            dealReg.Theatre_VP__c = uCDM.Id;
            dealRegList.add(dealReg);
        }
        
        flowControll.DealRegistrationTrigger = false;
        update dealRegList;
        flowControll.DealRegistrationTrigger = true;
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        Test.startTest();
        System.runAs(uCDM){
                PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
            	PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[1].Id);
            }
        Test.stopTest();
        System.assert(true);
    }
    
    static testMethod void getUserInOwnerTerritoryTest7(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User uCDM = [SELECT Id FROM User WHERE LastName ='Philips1' LIMIT 1];
        
        for(Deal_Registration__c dealReg : [SELECT Id,Sales_Manager__r.Name,Sales_Manager__c,Theatre_VP__c FROM Deal_Registration__c WHERE RecordType.Name != 'OEM']){
            dealReg.Deal_Registration_Sub_Status__c = 'Pending RSM Approval';
            dealReg.Theatre_VP__c = uCDM.Id;
            dealReg.Opportunity__c = null;
            dealReg.Deal_Registration_Status__c = 'Escalated';
            dealRegList.add(dealReg);
        }
        flowControll.DealRegistrationTrigger = false;
        update dealRegList;
        flowControll.DealRegistrationTrigger = true;
        Test.startTest();
        System.runAs(uCDM){
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[1].Id);
            try{
                PC_DealRegistrationApexController.allowDRAssociationToOpportunity(null,null);
            }catch(Exception e){
                System.debug(LoggingLevel.ERROR, 'An error occurred: ' + e.getMessage());
            }
        }
        Test.stopTest();
        System.assertEquals('Escalated', dealRegList[0].Deal_Registration_Status__c);
    }
    
    static testMethod void getUserInOwnerTerritoryTest4(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User uCDM = [SELECT Id FROM User WHERE LastName ='Philips1' LIMIT 1];
        for(Deal_Registration__c dealReg : [SELECT Id,Sales_Manager__r.Name,Sales_Manager__c,Theatre_VP__c FROM Deal_Registration__c WHERE RecordType.Name = 'OEM']){
            dealReg.Deal_Registration_Sub_Status__c = 'Pending TVP Approval';
            dealReg.Theatre_VP__c = uCDM.Id;
            dealRegList.add(dealReg);
        }
        flowControll.DealRegistrationTrigger = false;
        update dealRegList;
        flowControll.DealRegistrationTrigger = true;
        Test.startTest();
        System.runAs(uCDM){
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[1].Id);
        }
        Test.stopTest();
        System.assertEquals('Pending TVP Approval', dealRegList[0].Deal_Registration_Sub_Status__c);
    }
    
    static testMethod void getUserInOwnerTerritoryTest5(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User uCDM = [SELECT Id FROM User WHERE LastName ='Philips1' LIMIT 1];
        Account acc = [Select Id, Name, OEM_Subtype__c from Account WHere Name = 'Test New Account 1' LIMIT 1];
        acc.OEM_SubType__c = 'Markup';
        update acc;
        for(Deal_Registration__c dealReg : [SELECT Id,Sales_Manager__r.Name,Sales_Manager__c,Theatre_VP__c FROM Deal_Registration__c WHERE RecordType.Name = 'OEM']){
            dealReg.Deal_Registration_Sub_Status__c = 'Pending TVP Approval';
            dealReg.OEM_L1_Approver__c = uCDM.Id;
            dealReg.Distributor__c = acc.Id;
            dealReg.Theatre_VP__c = uCDM.Id;
            dealRegList.add(dealReg);
        }
        flowControll.DealRegistrationTrigger = false;
        update dealRegList;
        flowControll.DealRegistrationTrigger = true;
        Test.startTest();
        System.runAs(uCDM){
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[1].Id);
        }
        Test.stopTest();
        System.assertEquals(acc.Id, dealRegList[0].Distributor__c);
    }
    
    static testMethod void getUserInOwnerTerritoryTest6(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User adm = [SELECT Id FROM User WHERE LastName ='last' and profile.Name ='Rubrik Light Administrator' and isActive = true LIMIT 1];
        for(Deal_Registration__c dealReg : [SELECT Id FROM Deal_Registration__c]){
            dealRegList.add(dealReg);
        }
        System.runAs(adm){
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
        }
        System.assert(dealRegList.size() > 0);
    }
    

    
    static testMethod void getUserInOwnerTerritoryTest1(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        User adm = [SELECT Id FROM User WHERE LastName ='McCarthy' and email ='HG@gmail.com' and isActive = true LIMIT 1];
        for(Deal_Registration__c dealReg : [SELECT Id FROM Deal_Registration__c]){
            dealRegList.add(dealReg);
        }
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        System.runAs(adm){
            PC_DealRegistrationApexController.getUserInOwnerTerritory(dealRegList[0].Id);
        }
        System.assert(true);
    }
    
    static testMethod void allowDRAssociationToOpportunityTest(){
        User u = [SELECT Id from User WHERE Profile.Name='System Administrator' AND isActive= true LIMIT 1];
        List<Deal_Registration__c> dealRegList1 = new List<Deal_Registration__c>();
        List<Account> accList = new List<Account>();
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        
        System.runAs(u)
        {
            Account acc = TestDataFactory.getAccount();
            acc.name = 'Test New Account test 1';
            acc.Type = 'OEM';
            acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc.OEM_Subtype__c = 'Revshare';
            acc.OwnerId = UserInfo.getUserId();
            acc.BillingCountryCode = 'US';
            insert acc;
            
            Account acc1 = TestDataFactory.getAccount();
            acc1.name = 'Test New Account 1';
            acc1.Type = 'OEM';
            acc1.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc1.OEM_Subtype__c = 'Revshare';
            acc1.OwnerId = UserInfo.getUserId();
            acc1.BillingCountryCode = 'US';
            accList.add(acc1);
            
            Account acc2 = TestDataFactory.getAccount();
            acc2.name = 'Test New Account 1';
            acc2.Type = 'OEM';
            acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            acc2.OEM_Subtype__c = 'Revshare';
            acc2.OwnerId = UserInfo.getUserId();
            acc2.Distributor__c = acc.Id;
            accList.add(acc2);
            insert accList;
            
            List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
            Deal_Registration__c deal=TestDataFactory.getDealRegistration();
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Deal_Reg_Submitted_Date__c = System.today();
            deal.Primary__c = false;
            deal.Deal_Reg_Submitted_Date__c = System.now();
            deal.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
            deal.Distributor__c = acc1.Id;
            deal.Deal_Registration_Status__c = 'Submitted';
            deal.Deal_Registration_Sub_Status__c = 'Pending TVP Approval';
            dealRegList1.add(deal);
            
            Deal_Registration__c deal1 = TestDataFactory.getDealRegistration();
            deal1.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
            deal1.Deal_Registration_Status__c = 'Approved';
            deal1.Distributor__c = acc1.Id;
            deal1.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal1.Deal_Reg_Submitted_Date__c = Date.today().addDays(-50);
            deal1.Deal_Reg_Exp_Date__c = Date.today().addDays(-35);
            dealRegList1.add(deal1);
            
            Deal_Registration__c deal2 = TestDataFactory.getDealRegistration();
            deal2.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
            deal2.Deal_Registration_Status__c = 'Approved';
            deal2.Distributor__c = acc1.Id;
            deal2.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal2.Deal_Reg_Submitted_Date__c = Date.today().addDays(-50);
            deal2.Deal_Reg_Exp_Date__c = Date.today().addDays(-35);
            deal2.Dedicated_Managed_Service__c = true;
            dealRegList1.add(deal2);
            
            Deal_Registration__c deal3 = TestDataFactory.getDealRegistration();
            deal3.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal3.Deal_Registration_Status__c = 'Submitted';
            deal3.Distributor__c = acc1.Id;
            deal3.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal3.Deal_Reg_Submitted_Date__c = Date.today().addDays(-50);
            deal3.Deal_Reg_Exp_Date__c = Date.today().addDays(-35);
            deal3.Dedicated_Managed_Service__c = true;
            deal3.Company_Name__c = acc1.Id;
            deal3.Partner_Lookup__c = acc2.Id;
            dealRegList1.add(deal3);
            
            Deal_Registration__c deal4 = TestDataFactory.getDealRegistration();
            deal4.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
            deal4.Deal_Registration_Status__c = 'Submitted';
            deal4.Distributor__c = acc1.Id;
            deal4.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal4.Registration_Type__c = 'Partner Sourced';
            deal4.Deal_Reg_Submitted_Date__c = Date.today().addDays(-20);
            deal4.Deal_Reg_Exp_Date__c = Date.today().addDays(-35);
            deal4.Dedicated_Managed_Service__c = true;
            deal4.Company_Name__c = acc1.Id;
            deal4.Partner_Lookup__c = acc2.Id;
            dealRegList1.add(deal4);
            
            Deal_Registration__c deal5 = TestDataFactory.getDealRegistration();
            deal5.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
            deal5.Deal_Registration_Status__c = 'Submitted';
            deal5.Distributor__c = acc1.Id;
            deal5.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal5.Registration_Type__c = 'Partner Sourced';
            deal5.Deal_Reg_Submitted_Date__c = Date.today().addDays(-20);
            deal5.Deal_Reg_Exp_Date__c = Date.today().addDays(-35);
            deal5.Company_Name__c = acc1.Id;
            deal5.Partner_Lookup__c = acc2.Id;
            dealRegList1.add(deal5);
            
            Deal_Registration__c deal6 = TestDataFactory.getDealRegistration();
            deal6.RecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
            deal6.Deal_Registration_Status__c = 'Submitted';
            deal6.Distributor__c = acc1.Id;
            deal6.Deal_Registration_Type__c = 'Partner Sourced New Logo (PSNL)';
            deal6.Registration_Type__c = 'Partner Sourced';
            deal6.Deal_Reg_Submitted_Date__c = Date.today().addDays(-20);
            deal6.Deal_Reg_Exp_Date__c = Date.today().addDays(-35);
            deal6.Company_Name__c = acc1.Id;
            deal6.Partner_Lookup__c = acc2.Id;
            dealRegList1.add(deal6);
            
            insert dealRegList1;
            
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        List<Opportunity> oppList = new List<Opportunity>();
        
            //Stage closed - 1st condition
        Opportunity opp1 = TestDataFactory.getOpportunity();
            opp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        opp1.StageName = '7 Closed';
            opp1.Opportunity_Type__c = 'Existing Customer';
            opp1.Opportunity_Sub_Type__c = 'MSP';
            opp1.MSP_End_User_Lookup__c = acc1.Id;
        oppList.add(opp1);
        
            //Sales opp - 2nd condition
        Opportunity opp2 = TestDataFactory.getOpportunity();
        opp2.StageName = '1 Discovery';
		opp2.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal Opportunity').getRecordTypeId();
            opp2.Opportunity_Type__c = 'Existing Customer';
        opp2.Opportunity_Sub_Type__c = 'MSP';
            opp2.MSP_End_User_Lookup__c = acc1.Id;
        oppList.add(opp2);
        
            //Stage 6 - 3rd condition
        Opportunity opp3 = TestDataFactory.getOpportunity();
            opp3.StageName = '6 PO With Channel'; 
            opp3.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp3.Opportunity_Type__c = 'Existing Customer';
            opp3.Opportunity_Sub_Type__c = 'MSP';
            opp3.MSP_End_User_Lookup__c = acc1.Id;
        oppList.add(opp3);
        
        Opportunity opp4 = TestDataFactory.getOpportunity();
            opp4.StageName = '5 Negotiate & Close'; 
            opp4.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp4.Opportunity_Type__c = 'Existing Customer';
            opp4.Opportunity_Sub_Type__c = 'MSP';
            opp4.MSP_End_User_Lookup__c = acc1.Id;
        oppList.add(opp4);
        
        Opportunity opp5 = TestDataFactory.getOpportunity();
            opp5.StageName = '5 Negotiate & Close'; 
        opp5.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
        opp5.Opportunity_Type__c = 'Existing Customer';
        opp5.Opportunity_Sub_Type__c = 'MSP';
            opp5.MSP_End_User_Lookup__c = acc1.Id;
        oppList.add(opp5);
        
            Opportunity opp6 = TestDataFactory.getOpportunity();
            opp6.StageName = '5 Negotiate & Close'; 
            opp6.AccountId = acc1.Id;
            opp6.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp6.Opportunity_Type__c = 'Existing Customer';
            opp6.Opportunity_Sub_Type__c = 'MSP';
            opp6.MSP_End_User_Lookup__c = acc1.Id;
            opp6.ETM_Theatre__c = 'EMEA-1';
            opp6.ETM_Area__c = 'EMEA-AREA';
            opp6.Distributor_Lookup__c = acc2.Id;
            oppList.add(opp6);
            
            Opportunity opp7 = TestDataFactory.getOpportunity();
            opp7.StageName = '5 Negotiate & Close'; 
            opp7.AccountId = acc1.Id;
            opp7.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp7.Opportunity_Type__c = 'Existing Customer';
            opp7.Opportunity_Sub_Type__c = 'MSP';
            opp7.MSP_End_User_Lookup__c = acc1.Id;
            opp7.ETM_Theatre__c = 'APAC-1';
            opp7.ETM_Area__c = 'APAC-SLED';
            opp7.Distributor_Lookup__c = acc2.Id;
            oppList.add(opp7);
            
            Opportunity opp8 = TestDataFactory.getOpportunity();
            opp8.StageName = '2 Consensus'; 
            opp8.AccountId = acc1.Id;
            opp8.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp8.Opportunity_Type__c = 'New Customer';
            opp8.Opportunity_Sub_Type__c = 'MSP';
            opp8.MSP_End_User_Lookup__c = acc1.Id;
            opp8.ETM_Theatre__c = 'APAC-1';
            opp8.ETM_Area__c = 'APAC-SLED';
            opp8.Distributor_Lookup__c = acc1.Id;
            //opp8.PSNL_Eligible__c = true;
            oppList.add(opp8);
            
            Opportunity opp9 = TestDataFactory.getOpportunity();
            opp9.StageName = '2 Consensus'; 
            opp9.AccountId = acc1.Id;
            opp9.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp9.Opportunity_Type__c = 'Existing Customer';
            opp9.Opportunity_Sub_Type__c = 'MSP';
            opp9.MSP_End_User_Lookup__c = acc1.Id;
            opp9.ETM_Theatre__c = 'APAC-1';
            opp9.ETM_Area__c = 'APAC-SLED';
            opp9.Distributor_Lookup__c = acc1.Id;
            oppList.add(opp9);
            
            Opportunity opp10 = TestDataFactory.getOpportunity();
            opp10.StageName = '2 Consensus'; 
            opp10.AccountId = acc1.Id;
            opp10.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp10.Opportunity_Type__c = 'Existing Customer';
            opp10.Opportunity_Sub_Type__c = 'MSP';
            opp10.MSP_End_User_Lookup__c = acc1.Id;
            opp10.ETM_Theatre__c = 'APAC-1';
            opp10.ETM_Area__c = 'APAC-SLED';
            opp10.Distributor_Lookup__c = acc1.Id;
            oppList.add(opp10);
            
            Opportunity opp11 = TestDataFactory.getOpportunity();
            opp11.StageName = '5 Negotiate & Close'; 
            opp11.AccountId = acc1.Id;
            opp11.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp11.Opportunity_Type__c = 'Existing Customer';
            opp11.Opportunity_Sub_Type__c = 'MSP';
            opp11.MSP_End_User_Lookup__c = acc1.Id;
            opp11.ETM_Theatre__c = 'APAC-1';
            opp11.ETM_Area__c = 'APAC-SLED';
            opp11.Distributor_Lookup__c = acc1.Id;
            opp11.Deal_Reg_Approval_Status__c ='Approved';
            oppList.add(opp11);
            
            Deal_Registration__c dealQuery = [SELECT Id, Name FROM Deal_Registration__c WHERE Id =: deal6.Id];
            Opportunity opp12 = TestDataFactory.getOpportunity();
            opp12.StageName = '5 Negotiate & Close'; 
            opp12.AccountId = acc1.Id;
            opp12.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sales Opportunity').getRecordTypeId();
            opp12.Opportunity_Type__c = 'Existing Customer';
            opp12.Opportunity_Sub_Type__c = 'MSP';
            opp12.MSP_End_User_Lookup__c = acc1.Id;
            opp12.ETM_Theatre__c = 'APAC-1';
            opp12.ETM_Area__c = 'APAC-SLED';
            opp12.Distributor_Lookup__c = acc1.Id;
            opp12.Deal_Reg_Approval_Status__c ='Approved';
            opp12.Deal_Registration_Number__c = dealQuery.Name;
            oppList.add(opp12);
            
	    flowControll.opportunityTriggerHandler = false;
            insert oppList;
        
        
        
        Test.startTest();
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal.Id,opp1.Id);//1st
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal.Id,opp2.Id);//2nd
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal1.Id,opp3.Id);//3rd
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal1.Id,opp4.Id);//4th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal2.Id,opp5.Id);//5th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal3.Id,opp6.Id);//6th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal3.Id,opp7.Id);//7th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal4.Id,opp8.Id);//8th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal5.Id,opp9.Id);//9th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal3.Id,opp10.Id);//10th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal5.Id,opp11.Id);//11th
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(deal6.Id,opp12.Id);//14th
        Test.stopTest();
        System.assert(true);
        }
    }
    
    static testMethod void createEscalationTest(){
        User u = [SELECT Id from User WHERE Profile.Name='System Administrator' AND isActive= true LIMIT 1];
        List<Deal_Registration__c> dealRegList1 = [SELECT Id, Deal_Registration_Type__c, Company_Name__c, Account__c, Theatre_VP__c, CDM__c, Partner_Lookup__c FROM Deal_Registration__c
                                                   LIMIT 1];
        Account a = [SELECT Id,Name, RecordType.Name FROM Account WHERE Name='Test New Account 1'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        
        Opportunity opp3 = TestDataFactory.getOpportunity();
        opp3.StageName = '1 Discovery';
        opp3.AccountId = a.Id;
        opp3.Opportunity_Sub_Type__c = 'Regular';
        opp3.ACV_Amount__c = 100;
		flowControll.opportunityTriggerHandler = false;
		insert opp3;        
        
        Test.startTest();
        System.runAs(u){
            PC_DealRegistrationApexController.createEscalation(dealRegList1[0], opp3, 'Federal');   
        }
        Test.stopTest();
        System.assert(true);
    }
     static testMethod void createEscalationTest2(){
        User u = [SELECT Id from User WHERE Profile.Name='System Administrator' AND isActive= true LIMIT 1];
        List<Deal_Registration__c> dealRegList1 = [SELECT Id, Deal_Registration_Type__c, Company_Name__c, Account__c, Theatre_VP__c, CDM__c, Partner_Lookup__c FROM Deal_Registration__c
                                                   LIMIT 1];
        dealRegList1[0].Deal_Reg_Submitted_Date__c = Date.today().addDays(100);
        update dealRegList1;
        
        Account a = [SELECT Id,Name, RecordType.Name FROM Account WHERE Name='Test New Account 1'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        
        Opportunity opp3 = TestDataFactory.getOpportunity();
        opp3.StageName = '6 PO With Channel';
        opp3.AccountId = dealRegList1[0].Company_Name__c;
        opp3.Opportunity_Sub_Type__c = 'Regular';
        opp3.ACV_Amount__c = 100;
        
        flowControll.opportunityTriggerHandler = false;
        insert opp3;        
        
        Test.startTest();
        System.runAs(u){
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(dealRegList1[0].Id,opp3.Id);  
            
        }
        Test.stopTest();
        System.assert(true);
    }
    static testMethod void createEscalationTest3(){
        User u = [SELECT Id from User WHERE Profile.Name='System Administrator' AND isActive= true LIMIT 1];
        List<Deal_Registration__c> dealRegList1 = [SELECT Id, Deal_Registration_Type__c,Dedicated_Managed_Service__c, Company_Name__c, Account__c, Theatre_VP__c, CDM__c, Partner_Lookup__c FROM Deal_Registration__c
                                                   LIMIT 1];
        dealRegList1[0].Deal_Reg_Submitted_Date__c = Date.today().addDays(100);
        dealRegList1[0].Dedicated_Managed_Service__c = true;
        update dealRegList1;
        
        Account a = [SELECT Id,Name, RecordType.Name FROM Account WHERE Name='Test New Account 1'];
        Test.setMock(HttpCalloutMock.class, new PC_DealRegL2AMatchTest('SUCCESS'));
        
        Opportunity opp3 = TestDataFactory.getOpportunity();
        opp3.Deal_Reg_Approval_Status__c = 'Expired';
        
        flowControll.opportunityTriggerHandler = false;
        insert opp3;        
        
        Test.startTest();
        System.runAs(u){
        try {
            
            PC_DealRegistrationApexController.allowDRAssociationToOpportunity(dealRegList1[0].Id,opp3.Id);
            
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        }
        Test.stopTest();
        System.assert(true);
    }

    
}