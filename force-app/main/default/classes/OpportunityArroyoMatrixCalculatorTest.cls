@isTest
public class OpportunityArroyoMatrixCalculatorTest {
    
    testMethod static void testMethod_1(){

       ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
		disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;

		ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        disabled.Disable_Opportunity_Triggers__c = false;
        disabled.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        disabled.TriggerMaxLoopCount__c = 10;
        upsert disabled;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        
        Account objAccount = new Account();
        Contact objContact = new Contact();
        
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;
        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 31-05';
        insert objContact; 
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
        objOpportunity.Pricebook2Id = pricebookId;
        insert objOpportunity;
        
        
        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
                    
       Map<String, Object> prdMap1 = new Map<String, Object> {
      'Name' => 'Subscription', 
      'IsActive' => true, 
      'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
      'SBQQ__SubscriptionTerm__c' => 12, 
      'SBQQ__SubscriptionType__c' => 'Renewable'
      };
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        prdHW.License_Type__c = 'Perpetual';
        prdHW.Product_Subtype__c = 'E1000';
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 2, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = new PricebookEntry();
        pbeHW.Pricebook2Id = pricebookId;
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.UnitPrice = 1000;
        pbeHW.IsActive = true;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = new PricebookEntry();
        pbeSubs.Pricebook2Id = pricebookId;
        pbeSubs.UnitPrice = 1000;
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.IsActive = true;
        pBList.add(pbeSubs);
        insert pBList;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = objAccount.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Opportunity2__c = objOpportunity.Id;
        qt.SBQQ__PrimaryContact__c = objContact.Id;
        qt.Task_Products__c='RBK-DISK-RETENTION';  
        qt.SBQQ__Type__c = 'Renewal';
        insert qt; 
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046' );  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' ); 
        qliList.add( qli1 );
        qliList.add( qli2 );
        insert qliList;
        
        objOpportunity.SBQQ__PrimaryQuote__c = qt.Id;
        update objOpportunity;
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        oppLineList.add(new OpportunityLineItem(PBE_Product_Family__c = 'POLARIS',ACV_Amount__c=100,Renewal_Due_Date__c=System.Today()+300,SBQQ__QuoteLine__c=qliList[0].Id,pricebookentryid=pBList[0].Id,UnitPrice=1000, Quantity = 2,OpportunityID =  objOpportunity.Id));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[1].Id,pricebookentryid=pBList[1].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpportunity.Id));
        insert oppLineList;
		test.startTest();
        Set<Id> qtIdSet = new Set<Id>();
        qtIdSet.add(qt.Id);
        OpportunityArroyoMatrixCalculator.copyMatrixValuesToOpportunity(qtIdSet);
        Test.stopTest();
    }
}