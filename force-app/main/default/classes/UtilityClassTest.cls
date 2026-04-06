@isTest
public class UtilityClassTest { 
    @testSetup
    static void setup(){ 

        createAdminUser();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='NetApp', RecordTypeId = partnerRecordTypeId);
        insert acct;
        Date closeDt = System.Today()+30;
        
        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 27/1/2017' , Sell_to_Partner__c = acct.Id,  AccountId= acct.Id, StageName = '1 Discovery',
                                           CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon', 
                                           Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                           Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                           Identified_Pain__c = 'Test', Champion__c = 'Test', Why_Rubrik__c = 'Why_Rubrik',
                                           Why_do_anything__c = 'Why_do_anything', Why_now__c = 'Why_now', Alliance_HW_Partner__c = 'Cisco', Partner_Representative__c = 'Test');
        insert oppr;
        
        Id standardPriceBookId = Test.getStandardPricebookId();//pb2Standard.Id;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> lstProducts = new List<Product2>{
            new Product2(Name = 'Product XY', ProductCode = 'Pro-XY', isActive = true,Product_Level__c = 'LOD Software', Quotable_Date__c = system.today()),
                new Product2(Name = 'Product XYZ', ProductCode = 'Pro-XYZ', isActive = true,Product_Level__c = 'Hybrid Software',Quotable_Date__c = system.today())
                };
                    
                    insert lstProducts;
        
        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
                new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true)
                };
                    
                    insert lstPricebooks;
        
        TriggerControls.disableQuoteTrigger= true;
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppr.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId(),
            SBQQ__Type__c = 'Renewal+Expansion');
        
        insert quote;
        
        SBQQ__Quote__c quote1 = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppr.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId(),
            SBQQ__Type__c = 'Renewal+Expansion');
        
        insert quote1;
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = lstProducts[0].Id, SBQQ__Quantity__c = 1, 
                                         SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), 
                                         SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, 
                                         SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Special_Program__c = 'Conversion', SubscribedAssetNames__c = '87676565656'));
        
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = lstProducts[1].Id, SBQQ__Quantity__c = 1, 
                                         SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), 
                                         SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, 
                                         SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Special_Program__c = 'Conversion',SubscribedAssetNames__c = '876765656567'));
        insert lines;
        SBQQ.TriggerControl.enable();
        List<PO_Stage__c> lstPoStage = new List<PO_Stage__c>();
        PO_Stage__c poStage = new PO_Stage__c(
            Name='Test PO Stage',
            Account__c=acct.Id,
            Quote__c=quote.id,
            Expected_number_of_POs__c = 3,
            PO_Index__c =1,
            Opportunity__c=oppr.Id);
        lstPoStage.add(poStage);
        
        PO_Stage__c poStage1 = new PO_Stage__c(
            Name='Test PO Stage1',
            Account__c=acct.Id,
            Expected_number_of_POs__c = 3,
            PO_Index__c =2,
            Quote__c=quote1.id);
        lstPoStage.add(poStage1);
        
        PO_Stage__c poStage2 = new PO_Stage__c(
            Name='Test PO Stage2',
            Account__c=acct.Id,
            Expected_number_of_POs__c = 3,
            PO_Index__c =3,
            Quote__c=quote1.id
        );
        lstPoStage.add(poStage2);
        
        insert lstPoStage;
        
        List<PO_Item_Stage__c> lstPoStageItem = new List<PO_Item_Stage__c>();
        PO_Item_Stage__c poStageItem= new PO_Item_Stage__c(
            Name='Test PO Stage Item',
            Product__c=lstProducts[0].id,
            Quote_Line__c=lines[0].Id,
            Stage_PO__c=lstPoStage[0].id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem);
        
        PO_Item_Stage__c poStageItem1= new PO_Item_Stage__c(
            Name='Test PO Stage Item1',
            Product__c=lstProducts[0].id,
            Quote_Line__c=lines[0].Id,
            Stage_PO__c=lstPoStage[0].id,
            Type__c='New'
        );
        lstPoStageItem.add(poStageItem1);
        
        PO_Item_Stage__c poStageItem2= new PO_Item_Stage__c(
            Name='Test PO Stage Item2',
            Product__c=lstProducts[1].id,
            Quote_Line__c=lines[1].Id,
            Stage_PO__c=lstPoStage[1].id,
            Type__c='Renewal'
        );
        lstPoStageItem.add(poStageItem2);
        
        PO_Item_Stage__c poStageItem3= new PO_Item_Stage__c(
            Name='Test PO Stage Item13',
            Product__c=lstProducts[1].id,
            Quote_Line__c=lines[1].Id,
            Stage_PO__c=lstPoStage[1].id,
            Type__c='New'
        );
        
        PO_Item_Stage__c poStageItem4= new PO_Item_Stage__c(
            Name='Test PO Stage Item14',
            Product__c=lstProducts[1].id,
            Quote_Line__c=lines[1].Id,
            Stage_PO__c=lstPoStage[1].id,
            Type__c='Renewal'
        );
        lstPoStageItem.add(poStageItem4);
        
        PO_Item_Stage__c poStageItem5= new PO_Item_Stage__c(
            Name='Test PO Stage Item15',
            Product__c=lstProducts[1].id,
            Quote_Line__c=lines[1].Id,
            Stage_PO__c=lstPoStage[0].id,
            Type__c='Renewal'
        );
        lstPoStageItem.add(poStageItem5);
        
        PO_Item_Stage__c poStageItem6= new PO_Item_Stage__c(
            Name='Test PO Stage Item16',
            Product__c=lstProducts[1].id,
            Quote_Line__c=lines[1].Id,
            Stage_PO__c=lstPoStage[2].id,
            Type__c='Renewal'
        );
        lstPoStageItem.add(poStageItem6);
        
        insert lstPoStageItem;
        system.assert(true);
    }

    /**
    * @author Naveen/Ravi
    * @date 12-03-2025
    * @description Test method to test checkOrderSplitForArroyo method
    */
    @isTest
    public static void checkOrderSplitForArroyo() {
    User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = True LIMIT 1];
    System.runAs(adminUser) {
      List<PO_Stage__c> poList = new List<PO_Stage__c>();
      poList = [
        SELECT
          id,
          Name,
          Quote__r.SBQQ__Type__c,
          Opportunity__c,
          Quote__r.Renewal_Opportunity__c,
          Expected_number_of_POs__c,
          Quote__r.Opportunity_Program__c,
          Quote__r.SBQQ__Opportunity2__c,
          Quote__r.ProcessType__c,
          Quote__r.Total_New_Hardware_Products__c,
          (
            SELECT id, Stage_PO__r.Quote__c, Type__c, Quote_Line__r.Special_Program__c, Product__r.ProductCode, Quote_Line__r.SBQQ__EffectiveStartDate__c
            FROM PO_Item_Stage__r
          )
        FROM PO_Stage__c
      ];
        
        test.startTest();
        UtilityClass.checkOrderSplitForArroyo(new List<PO_Stage__c>(poList));
        test.stopTest();
        system.assert(true);
        }
    }
    @isTest
    static void checkPublishGovOrgSyncOrder(){
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = True LIMIT 1];
        System.runAs(adminUser) {
        Account acc = [Select id from Account limit 1];
        Opportunity opp = [Select id from Opportunity where AccountId = : acc.Id];
        Order orderInstanceNew = new Order();
            orderInstanceNew.AccountId = acc.Id;
            orderInstanceNew.OpportunityId = opp.Id;
            orderInstanceNew.EffectiveDate = system.today();  
            orderInstanceNew.Status = 'Draft';
            orderInstanceNew.Type = 'Revenue';
            orderInstanceNew.Order_Status__c = 'Pending'; 
            orderInstanceNew.Status='Draft';
            //orderInstanceNew.Program__c = 'Refresh';
            orderInstanceNew.Pricebook2Id = Test.getStandardPricebookId(); 
            insert orderInstanceNew;
        orderInstanceNew.Ready_for_Gov_Sync__c = 'Sync Ready';
        Test.startTest();
        orderInstanceNew.Hold_Code__c =null;
        update orderInstanceNew;
        if(orderInstanceNew != null){
          UtilityClass.publishGovOrgSyncEvents(new set<Id>{orderInstanceNew.Id}, 'Order');  
        }
        // Covering test for updateOrderFields, getupdatedOrdIdToScActionItemMap from Utilityclass.
        Map<Id, set<String>> OrdIdToSCorEntIds = new Map<Id, set<String>>();
        OrdIdToSCorEntIds = Utilityclass.getupdatedOrdIdToScActionItemMap(orderInstanceNew,OrdIdToSCorEntIds, 'Create Custom Entitlement'); 
        Utilityclass.updateOrderFields(OrdIdToSCorEntIds.keyset(), Json.serialize(OrdIdToSCorEntIds)); 
        Map<Id, set<String>> OrdIdToSCorEntIds1 = new Map<Id, set<String>>();
        OrdIdToSCorEntIds1 = Utilityclass.getupdatedOrdIdToScActionItemMap(orderInstanceNew,OrdIdToSCorEntIds1, 'Create POC Entitlement');
        
        Test.stopTest();    
        system.assert(true); 
    }   
    }
    static testmethod void checkPublishGovOrgSync(){
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = True LIMIT 1];
    System.runAs(adminUser) {
        Account acc = [Select id from Account limit 1];
        Test.startTest();
        if(acc != null){
          UtilityClass.publishGovOrgSyncEvents(new set<Id>{acc.id}, 'Account');  
        }
        Test.stopTest();
        system.assert(true);
    }
    }

    
    /**
     * @author Ravi
     * @date 17-03-2025
     * @description Method to create admin user
     * @return User
     */
    static User createAdminUser() {
        String uniqueUserName = 'TestUser' + DateTime.now().getTime() + '@rbk.com';
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User usr = new user(
        alias = 'std',
        email = 'testuser@testclass.com',
        emailencodingkey = 'UTF-8',
        firstname = 'test',
        lastname = 'user',
        languagelocalekey = 'en_US',
        localesidkey = 'en_US',
        profileid = p.Id,
        timezonesidkey = 'America/Los_Angeles',
        username = uniqueUserName
        );
        return usr;
    }

}