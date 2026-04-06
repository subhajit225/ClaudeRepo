@isTest
public with sharing class AARObjectTriggerTest {
    
    @TestSetUp
    static void initialDataSetup() {
        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
        upsert disableFuncCS;
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Contact objContact1 = new Contact();
        Account objAccount1 = new Account();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        objAccount1.Name = 'Test Account 01-06';
        objAccount1.RecordTypeId = recordTypeId;
        insert objAccount1;
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 31-05';
        insert objContact; 
        
        objContact1.LastName = 'Test Contact 01-06';
        objContact1.Account = objAccount1;
        insert objContact1; 
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        insert objOpportunity;
        
        SBQQ__Quote__c objQuote = new SBQQ__Quote__c();
        objQuote.SBQQ__Status__c = 'Draft';
        objQuote.SBQQ__Opportunity2__c = objOpportunity.Id;
        objQuote.Task_Products__c='RBK-DISK-RETENTION';
        insert objQuote;
    }

    @isTest
    static void testOpportunityClosedWon(){       
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];

        system.runas(listUser[0]){
            ShGl_DisableBusinessLogic__c BLSetting = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
            BLSetting.Disable_Opportunity_Validation_Rules__c = true;
            insert BLSetting;
            Opportunity opp = TestDataFactory.getOpportunity();
            opp.StageName = '1 Discovery';
            opp.name ='AAR Opp';
            
            insert opp;
            List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{opp.Id}, 1);
            insert listQuote;
            opp.Opportunity_Sub_Type__c='Regular';
            opp.RenewalOwner__c= listUser[0].id;
            opp.StageName = '7 Closed Lost';
            opp.Lost_To_Won_Against__c ='Actifio';
            opp.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
            opp.Valooto_Quote__c ='Test';
            Test.startTest();
            TriggerManager.resetTriggerCounter('Opportunity');
            update opp;
            System.assert(opp.Id != null);
            Test.stopTest();
        } 
    }
    @isTest
    static void testOpportunityUpdateStageChange(){
        ShGl_DisableBusinessLogic__c sdb1 = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        sdb1.Disable_Opportunity_Validation_Rules__c = true;
        insert sdb1;
        
        List<Profile> listProfile1 = [Select Id From Profile Where Name = 'System Administrator'];
        OppStageAndHours__c OppStageAndHoursCS = new OppStageAndHours__c(Name = '1 Discovery', HoursInStage__c = 'Hours_in_Discovery__c');
        insert OppStageAndHoursCS;
        List<User> listUser1 = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile1[0].Id}, 2);
        insert listUser1;
        listUser1[0].ManagerId = listUser1[1].Id;
        update listUser1[0];
        
        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.StageName = '2 Consensus';
        oppObject.ACV_Amount__c= 56000;
        insert oppObject;
        System.assert(oppObject.Id != null);
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{oppObject.Id}, 1);
        insert listQuote;
        oppObject.Opportunity_Sub_Type__c ='Regular';
        oppObject.Lost_To_Won_Against__c ='Cohesity';
        oppObject.Rubrik_Sales_Engineer__c = listUser1[0].id;
        oppObject.StageName = '7 Closed Lost';
        
        oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
        oppObject.Valooto_Quote__c ='Test';
        Test.startTest();
        TriggerManager.resetTriggerCounter('Opportunity');
        update oppObject;

        After_Action_Review__c aar = new After_Action_Review__c();
        aar.Opportunity__c = oppObject.Id;
        aar.AAR_Lost_to_Won_Against__c ='CommVault';
        aar.AAR_Loss_Reason__c = 'Too Expensive';
        
        Insert aar;

        oppObject.CloseDate = System.today()+15;
        oppObject.After_Action_Form_Submitted__c = true;
        TriggerManager.resetTriggerCounter('Opportunity');
        update oppObject;

        System.assert(oppObject.Id != null);
        Test.stopTest();
    }

    @isTest
    static void testAARLWCController(){
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        insert sdb;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        OppStageAndHours__c OppStageAndHoursCS = new OppStageAndHours__c(Name = '1 Discovery', HoursInStage__c = 'Hours_in_Discovery__c');
        insert OppStageAndHoursCS;
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];

        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.StageName = '2 Consensus';
        oppObject.Opportunity_Sub_Type__c ='Regular';
        oppObject.ACV_Amount__c= 56000;
        insert oppObject;

        oppObject.Lost_To_Won_Against__c ='Cohesity';
        oppObject.Rubrik_Sales_Engineer__c = listUser[0].id;
        oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
        oppObject.StageName = '7 Closed Lost';
        TriggerManager.resetTriggerCounter('Opportunity');
        

        After_Action_Review__c aar = new After_Action_Review__c();
        aar.Opportunity__c = oppObject.Id;
        aar.AAR_Lost_to_Won_Against__c ='CommVault';
        aar.AAR_Loss_Reason__c = 'Too Expensive';

        Test.startTest();
        update oppObject;
        delete sdb;
        Insert aar;

        Opportunity opp = AARLWCController.getOpportunity(oppObject.Id);
        System.assert(opp.Id != null);

        Id aarId = AARLWCController.getAARId(opp.Id);
        System.assertEquals(aar.Id, aarId);

        Id amerRecId = AARLWCController.getAARrecordTypeId('AMER');
        System.assert(amerRecId != null);

        Id nonAmerRecId = AARLWCController.getAARrecordTypeId('Non_AMER');
        System.assert(NonAmerRecId != null);
        Test.stopTest();

    }
     @isTest
    static void testAARLWCControllerCatch(){
        ShGl_DisableBusinessLogic__c sdb = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid());
        sdb.Disable_Opportunity_Validation_Rules__c = true;
        insert sdb;
        
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator'];
        OppStageAndHours__c OppStageAndHoursCS = new OppStageAndHours__c(Name = '1 Discovery', HoursInStage__c = 'Hours_in_Discovery__c');
        insert OppStageAndHoursCS;
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 2);
        insert listUser;
        listUser[0].ManagerId = listUser[1].Id;
        update listUser[0];

        Opportunity oppObject = TestDataFactory.getOpportunity();
        oppObject.StageName = '2 Consensus';
        oppObject.Opportunity_Sub_Type__c ='Regular';
        oppObject.ACV_Amount__c= 56000;
        insert oppObject;

        oppObject.Lost_To_Won_Against__c ='Cohesity';
        oppObject.Rubrik_Sales_Engineer__c = listUser[0].id;
        oppObject.Partner_Level_Of_Involvement__c ='1.Rubrik initiated, Partner was fulfillment only';
        oppObject.StageName = '7 Closed Lost';
        TriggerManager.resetTriggerCounter('Opportunity');
        

        After_Action_Review__c aar = new After_Action_Review__c();
        aar.Opportunity__c = oppObject.Id;
        aar.AAR_Lost_to_Won_Against__c ='CommVault';
        aar.AAR_Loss_Reason__c = 'Loss To Competitor';

        Test.startTest();
        update oppObject;
        delete sdb;
        Insert aar; 

        Opportunity opp = AARLWCController.getOpportunity(oppObject.Id);
        System.assert(opp.Id != null);

        Id aarId = AARLWCController.getAARId(opp.Id);
        System.assertEquals(aar.Id, aarId);

        Id amerRecId = AARLWCController.getAARrecordTypeId('AMER');
        System.assert(amerRecId != null);

        Id nonAmerRecId = AARLWCController.getAARrecordTypeId('Non_AMER');
        System.assert(NonAmerRecId != null);
        Test.stopTest();


    }
}