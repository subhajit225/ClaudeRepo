@isTest
private class SendSlackAlertsForMosaicOrdersTest {

    @TestSetUp
    static void initialDataSetup() {
        TriggerControl__c objTriggerControlCustSetting
            = new TriggerControl__c(
                Name = 'Order',
                DisableTrigger__c = false
            );
        insert objTriggerControlCustSetting;
        
        
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getuserid(),Disable_Opportunity_Triggers__c = false, Disable_SBQQ_Quote_Triggers__c = false);
        insert cdf;
        
        ShGl_DisableFunctionalityLogic__c obj = new ShGl_DisableFunctionalityLogic__c(Disable_Opportunity_Old_Trigger__c = True);
        insert obj;
        
        List<Product2> listProduct = TestDataFactory.getProducts('RBK-MOSAIC', 2);
        insert listProduct;
        
        List<Pricebook2> listPricebook = TestDataFactory.getPriceBook('TestPriceBook', 1);
        insert listPricebook;
        
        List<PricebookEntry> listPriceBookEntry = TestDataFactory.getPriceBookEntry(
            new List<Id> {listProduct[0].Id, listProduct[1].Id},
            new List<Id> {Test.getStandardPricebookId(), listPricebook[0].Id}
        );
        insert listPriceBookEntry;
        
        Opportunity objOpportunity = TestDataFactory.getOpportunity();
        objOpportunity.Mosaic_Customer_Environment__c = 'AWS';
        objOpportunity.Installation_Assigned_To__c = 'Partner Install';
        objOpportunity.Lost_To_Won_Against__c = 'Not Sure';
        objOpportunity.Partner_Level_Of_Involvement__c = '1.Rubrik initiated, Partner was fulfillment only';
        objOpportunity.Pricebook2Id = listPricebook[0].Id;
        insert objOpportunity;
        
        List<SBQQ__Quote__c> listQuote = TestDataFactory.getQuotes(new Set<Id>{objOpportunity.Id}, 1);
        listQuote[0].SBQQ__PriceBook__c = listPricebook[0].Id;
        insert listQuote;
        
        listQuote[0].SBQQ__Primary__c = TRUE;
        listQuote[0].Has_Mosaic_SKUs__c = TRUE;
        update listQuote;
        
        
        
    /*    List<SBQQ__QuoteLine__c> listQuoteLine = TestDataFactory.getQuoteLines(
            new Map<Id, List<Id>> {
                listQuote[0].Id => new List<Id> {listProduct[0].Id, listProduct[1].Id}
            }
        );
        listQuoteLine[0].SBQQ__PricebookEntryId__c = listPriceBookEntry[2].Id;
        listQuoteLine[0].SBQQ__ListPrice__c = 100;
        listQuoteLine[1].SBQQ__PricebookEntryId__c = listPriceBookEntry[3].Id;
        listQuoteLine[1].SBQQ__ListPrice__c = 100;
        insert listQuoteLine;
        
        for (SBQQ__Quote__c objQuote : listQuote) {
            objQuote.ApprovalStatus__c = 'Approved';
        }
        update listQuote; */
    }
    
    @isTest
    static void testSlackAlertForMosaicOrder() {
        
        List<Opportunity> listOpportunity = [Select Id, StageName, SBQQ__PrimaryQuote__c From Opportunity Limit 1];
        List<SBQQ__Quote__c> lst = [Select Id, SBQQ__Opportunity2__c, Mosaic_SKUs__c From SBQQ__Quote__c Limit 1];
        system.debug('**--O--'+listOpportunity);
        system.debug('**--Q--'+lst);
        Test.startTest();
        //listOpportunity[0].StageName = '6 PO With Channel';
        //listOpportunity[0].Deal_Registration_Type__c = 'Rubrik Initiated Deal';
        //update listOpportunity;
        
        listOpportunity[0].Include_Datos__c = False;
        update listOpportunity;
        listOpportunity = [Select Id, StageName, Include_Datos__c From Opportunity Limit 1];
        listOpportunity[0].Include_Datos__c = True;
        update listOpportunity;
        
        Order objOrder = new Order(Mosaic_SKUs__c = 'RBK-MOSAIC', OpportunityId = listOpportunity[0].Id, SBQQ__Quote__c = lst[0].Id, EffectiveDate = Date.Today());
        insert objOrder;
        Test.stopTest();
    }
    
    @isTest
    static void testSlackAlertForMosaicOrder1() {
        Profile pf = [SELECT Id FROM profile WHERE name='Sales Operations' limit 1]; 
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        usr.profileId = pf.id;
        insert usr;
    
        List<Profile> listProfile = [Select Id From Profile Where Name = 'System Administrator' Order By Name];
        
        List<User> listUser = TestDataFactory.getUsers('testClassUser', new Set<Id>{listProfile[0].Id}, 1);
        insert listUser;
        
        List<Opportunity> listOpportunity = [Select Id, StageName, AccountId, SBQQ__PrimaryQuote__c From Opportunity Limit 1];
        List<SBQQ__Quote__c> lst = [Select Id, SBQQ__Opportunity2__c, Mosaic_SKUs__c From SBQQ__Quote__c Limit 1];
        system.debug('**--O--'+listOpportunity);
        system.debug('**--Q--'+lst);
        Test.startTest();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account acct = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        acct.RecordTypeId = partnerRecordTypeId;
        update new Account(id = listOpportunity[0].AccountId, RecordTypeId = partnerRecordTypeId);
        //listOpportunity[0].StageName = '6 PO With Channel';
        //listOpportunity[0].Deal_Registration_Type__c = 'Rubrik Initiated Deal';
        //update listOpportunity;
        System.runAs(usr) {
            listOpportunity[0].Include_Datos__c = True;
            listOpportunity[0].OwnerId = listUser[0].Id;
            update listOpportunity;
        }
        
       // Order objOrder = new Order(Mosaic_SKUs__c = 'RBK-MOSAIC', OpportunityId = listOpportunity[0].Id, SBQQ__Quote__c = lst[0].Id, EffectiveDate = Date.Today());
       // insert objOrder;
        Test.stopTest();
    }
}