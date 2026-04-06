/**
 * @description test class for OppAnnualContractValueUtil
 */
@isTest
public class OppAnnualContractValueUtilTest {
    /**
     * @description test data setup
     */
	@TestSetUp
    static void initialDataSetup() {
        insert new Opportunity_Stage_Days__c(AllowAcvCalculation__c = true, AllowArrCalculation__c = true, DefaultAcvAmount__c =36);
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        
       
        
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        
        ShGl_DisableBusinessLogic__c settingDisable = new ShGl_DisableBusinessLogic__c();
        settingDisable.Trigger_Max_Loop_Count__c = 10;
        settingDisable.Disable_Opportunity_Validation_Rules__c = true;
        settingDisable.Disable_SBQQ_QuoteLine_Validation_Rules__c = true;
        insert settingDisable;
        
        upsert disableFuncCS;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        
        Account objAccount = new Account();
        Contact objContact = new Contact();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        objAccount.Name = 'Test Account 31-05';
        objAccount.RecordTypeId = recordTypeId;
        insert objAccount;

        objContact.Account = objAccount;
        objContact.LastName = 'Test Contact 31-05';
        insert objContact; 

        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.StageName = '1 Discovery';
        objOpportunity.closeDate = System.Today() + 30;
        objOpportunity.Name = 'Test Opp 31-05';
        objOpportunity.Opportunity_Sub_Type__c = 'Regular';
        objOpportunity.Initial_Contacts_Name__c = objContact.Id;
        objOpportunity.Distributor_Lookup__c = objAccount.Id;
        objOpportunity.Partner_Lookup__c = objAccount.Id;
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
        prdHW.Sales_Comp_Category__c = 'CONSUMPTION';
        prdHW.Product_Hierarchy_Group__c = 'Core';
        Product2 prod3 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        prod3.License_Type__c = 'Perpetual';
        prod3.Product_Subtype__c = 'E1000';
        prod3.Sales_Comp_Category__c = 'RUBRIK CLOUD DATA MGMT';
        prod3.Product_Hierarchy_Group__c = 'PLS-Cloud'; //SAL26-138: NAS to Cloud
        Product2 prod4 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prod4.productcode = 'Nassku';
        prod4.Product_Hierarchy_Group__c = 'PLS-Cloud'; //SAL26-138: NAS to Cloud
        prod4.Sales_Comp_Category__c = 'RUBRIK UCL';
        Product2 prod5 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prod5.productcode = 'TEST';
        prod5.Product_Hierarchy_Group__c = 'PLS-SaaS';
        prod5.Sales_Comp_Category__c = 'O365';
        prod5.Product_Level__c = 'OnPrem';
        prod5.Product_Subtype__c = 'FEDRAMP';
        Product2 prod6 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        prod6.productcode = 'TEST';
        prod6.Product_Hierarchy_Group__c = 'SaaS';
        prod6.Sales_Comp_Category__c = 'SW SUPPORT';
        prod6.Product_Level__c = 'OnPrem';
        prod6.Product_Subtype__c = 'FEDRAMP';
        Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT',productcode = 'OPTY-SPLIT');
        List<Product2> prdList = (List<Product2>) ShGl_TestFactory.createSObjectList(new Product2(), 4, prdMap);
        prdList.add(prdHW);
        prdList.add(prdSubs);
        prdList.add(prod3);
        prdList.add(prod4);
        prdList.add(prod5);
        prdList.add(prod6);
        prdList.add(optyspltchild);
        insert prdList;
        
        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = new PricebookEntry();
        pbeHW.Pricebook2Id = OpportunityUtil.defaultPriceBookId;
        pbeHW.Product2Id = prdHW.Id;
        pbeHW.UnitPrice = 1000;
        pbeHW.IsActive = true;
        pBList.add(pbeHW);
        
        PricebookEntry pbeSubs = new PricebookEntry();
        pbeSubs.Pricebook2Id = OpportunityUtil.defaultPriceBookId;
        pbeSubs.UnitPrice = 1000;
        pbeSubs.Product2Id = prdSubs.Id;
        pbeSubs.IsActive = true;
        pBList.add(pbeSubs);
        
        PricebookEntry pb3 = new PricebookEntry();
        pb3.Pricebook2Id = OpportunityUtil.defaultPriceBookId;
        pb3.Product2Id = prod3.Id;
        pb3.UnitPrice = 1000;
        pb3.IsActive = true;
        pBList.add(pb3);
        
        PricebookEntry pb4 = new PricebookEntry();
        pb4.Pricebook2Id = OpportunityUtil.defaultPriceBookId;
        pb4.Product2Id = prod4.Id;
        pb4.UnitPrice = 1000;
        pb4.IsActive = true;
        pBList.add(pb4);
        
        PricebookEntry pb5 = new PricebookEntry();
        pb5.Pricebook2Id = OpportunityUtil.defaultPriceBookId;
        pb5.Product2Id = prod5.Id;
        pb5.UnitPrice = 1000;
        pb5.IsActive = true;
        pBList.add(pb5);
        
        PricebookEntry pb6 = new PricebookEntry();
        pb6.Pricebook2Id = OpportunityUtil.defaultPriceBookId;
        pb6.Product2Id = optyspltchild.Id;
        pb6.UnitPrice = 1000;
        pb6.IsActive = true;
        pBList.add(pb6);
        
        insert pBList;
        
        List<PriceBook_Config_Ids__c> pbConfigList = new List<PriceBook_Config_Ids__c>();
		PriceBook_Config_Ids__c pbConfig1 = new PriceBook_Config_Ids__c();
        pbConfig1.name='OPTYSPLITPriceBookEntryId';
        pbConfig1.Config_Id__c = pb6.Id;
        pbConfigList.add(pbConfig1);
        PriceBook_Config_Ids__c pbConfig2 = new PriceBook_Config_Ids__c();
        pbConfig2.name='CPQPricebookID';
        pbConfig2.Config_Id__c = Test.getStandardPricebookId();
        pbConfigList.add(pbConfig2);
        insert pbConfigList;
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = objAccount.Id;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Opportunity2__c = objOpportunity.Id;
        qt.SBQQ__PrimaryContact__c = objContact.Id;
        qt.Task_Products__c='RBK-DISK-RETENTION';  
        qt.SBQQ__Type__c = 'Renewal';
        qt.Is_Ramp_Quote__c = 'Yes';
        insert qt; 
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c> ();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Subtype__c = 'FEDRAMP');  
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__SubscriptionTerm__c=15,SBQQ__Renewal__c=true,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prdSubs.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' );
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__SubscriptionTerm__c=15,SBQQ__Renewal__c=false,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prod3.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046' );
        SBQQ__QuoteLine__c qli4 = new SBQQ__QuoteLine__c(SBQQ__SubscriptionTerm__c=15,SBQQ__Renewal__c=false,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prod6.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQ__ProrateMultiplier__c=11 );
        SBQQ__QuoteLine__c qli5 = new SBQQ__QuoteLine__c(SBQQ__SubscriptionTerm__c=15,SBQQ__Renewal__c=false,SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prod6.Id, SBQQ__RequiredBy__c = qli1.id, SBQQ__Quantity__c = 10, SBQQ__Number__c = 2, SubscribedAssetNames__c = 'BB192863040046',SBQQ__ProrateMultiplier__c=10 );
        qliList.add( qli1 );
        qliList.add( qli2 );
        qliList.add( qli3 );
        qliList.add( qli4 );
        qliList.add( qli5 );
        insert qliList;
        
        objOpportunity.SBQQ__PrimaryQuote__c = qt.Id;
        update objOpportunity;
        
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        oppLineList.add(new OpportunityLineItem(PBE_Product_Family__c = 'POLARIS',ACV_Amount__c=100,Renewal_Due_Date__c=System.Today()+300,SBQQ__QuoteLine__c=qliList[0].Id,pricebookentryid=pBList[0].Id,UnitPrice=1000, Quantity = 2,OpportunityID =  objOpportunity.Id));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,Renewal_Due_Date__c=System.Today(),SBQQ__QuoteLine__c=qliList[1].Id,pricebookentryid=pBList[1].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpportunity.Id));
        oppLineList.add(new OpportunityLineItem(ACV_Amount__c=100,SBQQ__QuoteLine__c=qliList[2].Id,pricebookentryid=pBList[2].Id,UnitPrice=1000,Quantity = 2,OpportunityID =  objOpportunity.Id));
    oppLineList.add(new OpportunityLineItem(product2Id = pBList[3].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[3].Id,TotalPrice=2000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[3].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[3].Id,TotalPrice=-1000,Quantity = 1,OpportunityID = objOpportunity.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[4].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[4].Id,TotalPrice=-1000,Quantity = 1,OpportunityID = objOpportunity.Id));
		oppLineList.add(new OpportunityLineItem(product2Id = pBList[5].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[5].Id,TotalPrice=-1000,Quantity = 1,OpportunityID = objOpportunity.Id,SBQQ__QuoteLine__c=qliList[4].Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[5].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[5].Id,TotalPrice=-1000,Quantity = 1,OpportunityID = objOpportunity.Id,SBQQ__QuoteLine__c=qliList[3].Id));

        insert oppLineList;

        List<OpportunityLineItem> oppLineitemList = new List<OpportunityLineItem>();
        oppLineitemList = [select Id,ACV_Amount__c from OpportunityLineItem limit 1];
        oppLineitemList[0].ACV_Amount__c = 200;
        update oppLineitemList;
        

        objOpportunity.SBQQ__PrimaryQuote__c = qt.Id;
        objOpportunity.SOW_Required__c = !objOpportunity.SOW_Required__c;
        update objOpportunity;

    }

    /**
     * @description test method
     */
    testMethod static void testMethod1(){
       User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        for(Opportunity opp : [select Id,stagename from Opportunity]){
            oppIdset.add(opp.Id);
        }
        test.startTest();
        System.runAs(user) {
        OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        }
        test.stopTest();
        System.assert(oppIdset != null);
    }
    /**
     * @description test method
     */
    testMethod static void salessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        Opportunity parentopp = new opportunity();
        List<PricebookEntry> pBList = [select Id, product2Id from PricebookEntry where product2.productcode='OPTY-SPLIT'];
        for(Opportunity opp : [select Id,stagename,Split_percentage__c,split__c from Opportunity]){
            parentopp = opp;
            parentopp.split__c = true;
            parentopp.Split_percentage__c = 50;            
            parentopp.Split_Amount__c = 100;
            parentopp.Co_Owner__c = userInfo.getUserId();
            parentopp.PLS_AE_ETM_Role_Name__c = 'SaaS AE';
            parentopp.pricebook2Id = Test.getStandardPricebookId();   
            oppIdset.add(opp.Id);
        }
        update parentopp;
        Opportunity childopp = new Opportunity();
        childopp.StageName = '1 Discovery';
        childopp.closeDate = System.Today() + 30;
        childopp.Name = 'Test Opp 31-05 -split';
        childopp.Opportunity_Sub_Type__c = 'Regular';
        childopp.PLS_AE_ETM_Role_Name__c = 'Cloud AE'; //SAL26-138: NAS to Cloud
        childopp.split__c = true;
        childopp.Split_Amount__c = 100;
        childopp.Split_percentage__c = 50;
        childopp.Opportunity_Split_Parent__c = parentopp.Id;
        childopp.pricebook2Id = Test.getStandardPricebookId();   
        insert childopp;
        oppIdset.add(childopp.Id);
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
       // oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id, pricebookEntryId=pBList[0].Id, Line_Type_Text__c = 'New',TotalPrice=-1000,Quantity = 1,OpportunityID = parentopp.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id, pricebookEntryId=pBList[0].Id, Line_Type_Text__c = 'New',TotalPrice=-1000,Quantity = 1,OpportunityID = childopp.Id));
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        //insert oppLineList;
        test.startTest();
        OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        //oppLineList[0].TotalPrice = -1000;
        //oppLineList[1].TotalPrice = 1000;
       // update oppLineList;
        flowControll.opportunityLineItemHandler = true;
        System.runAs(user) {
        OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        //OppAnnualContractValueUtil.setArroyofieldsforSplitProducts(oppLineList.get(0), parentopp);
        }
        test.stopTest();
        System.assert(childopp.Id != null);
    }
    /**
     * @description test method
     */
    testMethod static void salessplitwithoutproducts(){
        Set<ID> oppIdset = new Set<ID>();
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c=2000;
        parentopp1.Split_percentage__c = 50;     
        parentopp1.SOW_Required__c = true;
        parentopp1.PLS_AE_ETM_Role_Name__c = 'Cloud AE'; //SAL26-138: NAS to Cloud
        parentopp1.Co_Owner__c = userInfo.getUserId();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert parentopp1;
        oppIdset.add(parentopp1.Id);

        Opportunity childopp1 = new Opportunity();
        childopp1.StageName = '1 Discovery';
        childopp1.closeDate = System.Today() + 30;
        childopp1.Name = 'Test Opp 31-05 -split';
        childopp1.Opportunity_Type__c = 'New Customer';
        childopp1.Opportunity_Sub_Type__c = 'Regular';
        childopp1.split__c = true;
        childopp1.Split_percentage__c = 50;
        childopp1.Opportunity_Split_Parent__c = parentopp1.Id;
        childopp1.Amount = 1000;
        childopp1.Renewal_Subsumed_ACV__c = 200;
        childopp1.Subsumed_Renewal_TCV__c = 200;
        childopp1.ACV_Amount__c=1000;
		TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert childopp1;
        
        oppIdset.add(childopp1.Id);
		List<OpportunityLineItem> oppLinedeleteList = new List<OpportunityLineItem>();
        oppLinedeleteList = [select Id from OpportunityLineItem];
        delete oppLinedeleteList;
        List<PricebookEntry> pBList = [select Id,product2Id from PricebookEntry where product2.productcode='OPTY-SPLIT'];
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
		oppLineList.add(new OpportunityLineItem(SalesCompCategory__c='RUBRIK CLOUD DATA MGMT', product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=-1000,Quantity = 1,OpportunityID = parentopp1.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=-1000,Quantity = 1,OpportunityID = childopp1.Id));
        insert oppLineList;
        OppAnnualContractValueUtil.OppACVRecursion = false;
        test.startTest();
        System.runAs(user) {
        OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
            OppAnnualContractValueUtil.resetACVonOpp(parentopp1);
            OppAnnualContractValueUtil.setArroyofieldsforSplitProducts(oppLineList.get(1), parentopp1);
        }
        test.stopTest();
        System.assert(childopp1.Id != null);
    }
    /**
     * @description test method
     */
    testMethod static void oppwithoutproducts(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        Opportunity opp = new Opportunity();
        opp.StageName = '1 Discovery';
        opp.closeDate = System.Today() + 30;
        opp.Name = 'Test Opp 31-05';
        opp.Opportunity_Sub_Type__c = 'Regular';
        opp.Opportunity_Type__c = 'New Customer';
        opp.PLS_AE_ETM_Role_Name__c = 'SaaS AE';
        opp.Co_Owner__c = userInfo.getUserId();
        opp.Amount =1000;
        opp.Subsumed_Renewal_TCV__c = 2000;
        insert opp;
        oppIdset.add(opp.Id);
        test.startTest();
        System.runAs(user) {
        OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
            OppAnnualContractValueUtil.resetACVonOpp(opp);
        }
        test.stopTest();
        System.assert(opp.Id != null);
    }
    /**
     * @description test method
     */
    testMethod static void debookingOppwithoutprods(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Opportunity> lstOpp = [select Id from opportunity];
		Account acc = [select Id from Account limit 1];
        Map<String, Object> CCRMap = new Map<String, Object> {
            'Comment__c'=>'test',
                'Opportunity__c'=>lstOpp[0].id,
                'AssignmentStatus__c'=>'Unassigned',
                'User__c'=>'Pending',
                'Account_Name__c'=>acc.Id,
                'Effective_Date__c'=>System.today(),
                'Impacts_Commission__c'=>true,
                'Effective_End_Date__c'=>System.today(), 
                //'Booking__c'=> bkg.id,
                'Referral_Fee_Percent__c' => 20,
                'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
                };
        List<CCR__c> CCRList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),1, CCRMap); 
        insert CCRList;
        Opportunity opp = new Opportunity();
        opp.StageName = '1 Discovery';
        opp.closeDate = System.Today() + 30;
        opp.Name = 'Test Opp 31-05';
        opp.Opportunity_Type__c = 'Debooking';
        opp.Opportunity_Sub_Type__c = 'Full';
        opp.Amount = -1000;
        opp.ccr__c = CCRList[0].Id;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert opp;
        oppIdset.add(opp.Id);
        OppAnnualContractValueUtil.OppACVRecursion = false;
        test.startTest();
        System.runAs(user) {
        OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        }
        test.stopTest();
        System.assert(opp.Id != null);
    }
    /**
     * @description test method
     */
    testMethod static void debookingOppwithprods(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Opportunity> lstOpp = [select Id,(select Id,totalprice,ACV_Amount__c,New_Expansion_ACV__c from opportunitylineitems where productcode !='OPTY-SPLIT') from opportunity];
        List<opportunitylineitem> oliList = new List<opportunitylineitem>();
        for(Opportunity opp : lstOpp){
            for(opportunitylineitem oli : opp.opportunitylineitems){
                oliList.add(oli);
            }
        }
		Account acc = [select Id from Account];
        Map<String, Object> CCRMap = new Map<String, Object> {
            'Comment__c'=>'test',
                'Opportunity__c'=>lstOpp[0].id,
                'AssignmentStatus__c'=>'Unassigned',
                'User__c'=>'Pending',
                'Account_Name__c'=>acc.Id,
                'Effective_Date__c'=>System.today(),
                'Impacts_Commission__c'=>true,
                'Effective_End_Date__c'=>System.today(), 
                //'Booking__c'=> bkg.id,
                'Referral_Fee_Percent__c' => 20,
                'recordtypeId' => Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId()
                };
        List<CCR__c> CCRList = (List<CCR__c>) ShGl_TestFactory.createSObjectList(new CCR__c(),1, CCRMap); 
        insert CCRList;
        Opportunity opp = new Opportunity();
        opp.StageName = '1 Discovery';
        opp.closeDate = System.Today() + 30;
        opp.Name = 'Test Opp 31-05';
        opp.Opportunity_Type__c = 'Debooking';
        opp.Opportunity_Sub_Type__c = 'Full';
        opp.ACV_Amount__c = 100;
        opp.ARR_Amount__c = 100;
        opp.TotalHW_HwSupportAmount__c = 100;
        opp.Amount = -1000;
        opp.ccr__c = CCRList[0].Id;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        FlowControll.accountTrigger = false;
        flowControll.contactTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert opp;
        List<PricebookEntry> pBList = [select Id,product2Id from PricebookEntry where product2.productcode !='OPTY-SPLIT'];
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
		oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = opp.Id, Original_OpplineitemId__c=oliList[0].Id));
        insert oppLineList;
        OppAnnualContractValueUtil.OppACVRecursion = false;
        oppIdset.add(opp.Id);
        test.startTest();
        System.runAs(user) {
        OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        }
        test.stopTest();
        System.assert(opp.Id != null);
    }
    /*
     * @description test method
     */
    testMethod static void testMethodPLSACV(){
        List<PricebookEntry> pBList = new List<PricebookEntry> (); 
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        Id oppId;
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        for(Opportunity opp : [select Id,stagename from Opportunity]){
            opp.UCL_Scale_Percentage__c = 25;
            oppId = opp.Id;
            oppIdset.add(opp.Id);
            oppList.add(opp);
        }
        update oppList;
        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Amount = 2000;
        parentopp1.UCL_Scale_Percentage__c = 0;
        insert parentopp1;
        
        Product2 prod1 = new Product2(IsActive = true, name = 'saasprod',Product_Hierarchy_Group__c = 'PLS-SaaS',Sales_Comp_Category__c = 'O365');
        prdList.add(prod1);
        Product2 prod2 = new Product2(IsActive = true, name = 'nasprod',Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'NAS CLOUD');//SAL26-138: NAS to Cloud
        prdList.add(prod2);
        Product2 prod3 = new Product2(IsActive = true, name = 'DSPM',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'DSPM');
        prdList.add(prod3);
        Product2 prod4 = new Product2(IsActive = true, name = 'scale',Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'RCDM Scale');//SAL26-138: NAS to Cloud
        prdList.add(prod4);
        Product2 prod5 = new Product2(IsActive = true, name = 'RCVLRS',Sales_Comp_Category__c = 'RCV ZRS'); 
        prdList.add(prod5);
        Product2 prod6 = new Product2(IsActive = true, name = 'nasprod22',Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'CONSUMPTION EPE WITH DSPM'); //SAL26-138: NAS to Cloud
        prdList.add(prod6);
        insert prdList;

        PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod1.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe1);
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod3.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe3);
        PricebookEntry pe4 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod4.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe4);
        PricebookEntry pe5 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod5.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe5);
        PricebookEntry pe6 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod6.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe6);
        insert pBList;
        
		oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[3].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[3].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[4].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[4].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[5].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[5].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[5].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[5].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
            OppAnnualContractValueUtil.resetAllfieldsProduct(oppLineList[0]);
        }
        test.stopTest();
        System.assert(oppIdset != null);
    } 
    /**
     * @description test method
     */
    testMethod static void testMethodSaaSDSPM(){
        List<PricebookEntry> pBList = new List<PricebookEntry> (); 
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        Id oppId;
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Amount = 2000;
        insert parentopp1;
        oppId = parentopp1.Id;
        Product2 prod1 = new Product2(IsActive = true, name = 'saasprod',Product_Hierarchy_Group__c = 'PLS-SaaS',Sales_Comp_Category__c = 'O365');
        prdList.add(prod1);
        Product2 prod3 = new Product2(IsActive = true, name = 'DSPM',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'DSPM');
        prdList.add(prod3);

        insert prdList;

        PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod1.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe1);
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod3.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe3);

        insert pBList;
        
		oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));

        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        }
        test.stopTest();
        System.assert(oppIdset != null);
    } 
    /**
     * @description test method
     */
    testMethod static void testMethodNasDSPM(){
        List<PricebookEntry> pBList = new List<PricebookEntry> (); 
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        Id oppId;
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Amount = 2000;
        insert parentopp1;
        oppId = parentopp1.Id;
        
        Product2 prod2 = new Product2(IsActive = true, name = 'nasprod',Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'NAS CLOUD');//SAL26-138: NAS to Cloud
        prdList.add(prod2);
        Product2 prod3 = new Product2(IsActive = true, name = 'DSPM',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'DSPM');
        prdList.add(prod3);
        Product2 prod4 = new Product2(IsActive = true, name = 'RCVZRS',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'RCV ZRS');
        prdList.add(prod4);
        Product2 prod5 = new Product2(IsActive = true, name = 'SaaS',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'SAAS ADD-ON');
        prdList.add(prod5);
        insert prdList;

        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod3.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe3);
        PricebookEntry pe4 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod4.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe4);
        PricebookEntry pe5 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod5.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe5);
        insert pBList;
        
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
		oppLineList.add(new OpportunityLineItem(product2Id = pBList[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[3].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[3].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        }
        test.stopTest();
        System.assert(oppIdset != null);
    } 
    /**
     * @description test method
     */
    testMethod static void testMethodNasCloudDSPM(){
        List<PricebookEntry> pBList = new List<PricebookEntry> (); 
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        Id oppId;
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Amount = 2000;
        insert parentopp1;
        oppId = parentopp1.Id;
        
        Product2 prod2 = new Product2(IsActive = true, name = 'nasprod',Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'RUBRIK UCL'); //SAL26-138: NAS to Cloud
        prdList.add(prod2);
        Product2 prod3 = new Product2(IsActive = true, name = 'DSPM',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'DSPM');
        prdList.add(prod3);
        Product2 prod4 = new Product2(IsActive = true, name = 'RCVZRS',Product_Hierarchy_Group__c = 'Core',Sales_Comp_Category__c = 'RCV ZRS');
        prdList.add(prod4);
        insert prdList;

        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod3.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe3);
        PricebookEntry pe4 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod4.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe4);
        insert pBList;
        
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
		oppLineList.add(new OpportunityLineItem(product2Id = pBList[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = oppId));
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);
        }
        test.stopTest();
        System.assert(oppIdset != null);
    } 
    /**
     * @description test method
     */
    testMethod static void testMethodsalessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        
       	OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        

        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Split_percentage__c = 50;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c = 2000;
        parentopp1.OppSubscriptionTermMonths__c = 36;
        parentopp1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        parentopp1.Pricebook2Id = Test.getStandardPricebookId();
        parentopp1.Opportunity_Split_Parent__c = null;
        insert parentopp1;
        
        Opportunity childopp = new Opportunity();
        childopp.StageName = '1 Discovery';
        childopp.closeDate = System.Today() + 30;
        childopp.Name = 'Test Opp 31-05 -split';
        childopp.Opportunity_Type__c = 'New Customer';
        childopp.Opportunity_Sub_Type__c = 'Regular';
        childopp.split__c = true;
        childopp.Amount = 2000;
        childopp.ACV_Amount__c = 2000;
        childopp.OppSubscriptionTermMonths__c = 36;
        childopp.Split_percentage__c = 50;
        childopp.Opportunity_Split_Parent__c = parentopp1.Id;
        childopp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        childopp.Pricebook2Id = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        insert childopp;
        oppIdset.add(parentopp1.Id);
        oppIdset.add(childopp.Id);
        
        Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT');
        prdList.add(optyspltchild);
        Product2 prod2 = new Product2(IsActive = true, name = 'cloudsku',ProductCode ='cloudsku',Sales_Comp_Category__c = 'RUBRIK CLOUD DATA MGMT');
        prdList.add(prod2);
        insert prdList;
        
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = optyspltchild.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe3);
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        insert pBList;
        
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            FlowControll.opportunityTriggerHandler = false;
            OpportunitySplitLWCController.createOptySPlitLine = true;
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);

        }
        test.stopTest();
        System.assert(childopp.Id != null);
    } 
    /**
     * @description test method
     */
    testMethod static void testMethodpositiveparentsalessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        
       	OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        

        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Split_percentage__c = 50;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c = 2000;
        parentopp1.OppSubscriptionTermMonths__c = 36;
        parentopp1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        parentopp1.Pricebook2Id = Test.getStandardPricebookId();
        parentopp1.Opportunity_Split_Parent__c = null;
        insert parentopp1;

        oppIdset.add(parentopp1.Id);
        
        List<PricebookEntry> pbeoptyspltchildList = new List<PricebookEntry>();
        pbeoptyspltchildList = [select Id,product2Id from PricebookEntry where product2.ProductCode ='OPTY-SPLIT'];
        if(pbeoptyspltchildList.isEmpty()){
            Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT', ProductCode ='OPTY-SPLIT');
            insert optyspltchild;
            PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = optyspltchild.Id,UnitPrice = 1000,IsActive = true);
            insert pe1;
            pbeoptyspltchildList.add(pe1);
        }      
        Product2 prod2 = new Product2(IsActive = true, name = 'consumptionsku',ProductCode ='consumptionsku',Sales_Comp_Category__c = 'CONSUMPTION ACTUALS');
        prdList.add(prod2);
        insert prdList;
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        insert pBList;
        pbeoptyspltchildList.addAll(pBList);
        
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);

        }
        test.stopTest();
        System.assert(parentopp1.Id != null);
    }
     /**
     * @description test method
     */
    testMethod static void testMethodpositivechildsalessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        
       	OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        

        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Split_percentage__c = 50;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c = 2000;
        parentopp1.OppSubscriptionTermMonths__c = 36;
        parentopp1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        parentopp1.Pricebook2Id = Test.getStandardPricebookId();
        parentopp1.Opportunity_Split_Parent__c = null;
        insert parentopp1;
		
        Opportunity childopp = new Opportunity();
        childopp.StageName = '1 Discovery';
        childopp.closeDate = System.Today() + 30;
        childopp.Name = 'Test Opp 31-05 -split';
        childopp.Opportunity_Type__c = 'New Customer';
        childopp.Opportunity_Sub_Type__c = 'Regular';
        childopp.split__c = true;
        childopp.Amount = 2000;
        childopp.ACV_Amount__c = 2000;
        childopp.OppSubscriptionTermMonths__c = 36;
        childopp.Split_percentage__c = 50;
        childopp.Opportunity_Split_Parent__c = parentopp1.Id;
        childopp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        childopp.Pricebook2Id = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        insert childopp;
        
        oppIdset.add(parentopp1.Id);
        oppIdset.add(childopp.Id);
        
        
        List<PricebookEntry> pbeoptyspltchildList = new List<PricebookEntry>();
        pbeoptyspltchildList = [select Id,product2Id from PricebookEntry where product2.ProductCode ='OPTY-SPLIT'];
        if(pbeoptyspltchildList.isEmpty()){
            Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT', ProductCode ='OPTY-SPLIT');
            insert optyspltchild;
            PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = optyspltchild.Id,UnitPrice = 1000,IsActive = true);
            insert pe1;
            pbeoptyspltchildList.add(pe1);
        }      
        Product2 prod2 = new Product2(IsActive = true, name = 'cloudsku',ProductCode ='cloudsku',Sales_Comp_Category__c = 'RUBRIK CLOUD DATA MGMT');
        prdList.add(prod2);
        insert prdList;
        /*PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        insert pBList;*/
        pbeoptyspltchildList.addAll(pBList);
        
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp.Id));
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);

        }
        test.stopTest();
        System.assert(parentopp1.Id != null);
    }
     /**
     * @description test method
     */
    testMethod static void testMethodnegativeparentsalessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        
       	OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        

        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Split_percentage__c = 50;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c = 2000;
        parentopp1.OppSubscriptionTermMonths__c = 36;
        parentopp1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        parentopp1.Pricebook2Id = Test.getStandardPricebookId();
        parentopp1.Opportunity_Split_Parent__c = null;
        insert parentopp1;
		
        Opportunity childopp = new Opportunity();
        childopp.StageName = '1 Discovery';
        childopp.closeDate = System.Today() + 30;
        childopp.Name = 'Test Opp 31-05 -split';
        childopp.Opportunity_Type__c = 'New Customer';
        childopp.Opportunity_Sub_Type__c = 'Regular';
        childopp.split__c = true;
        childopp.Amount = 2000;
        childopp.ACV_Amount__c = 2000;
        childopp.OppSubscriptionTermMonths__c = 36;
        childopp.Split_percentage__c = 50;
        childopp.Opportunity_Split_Parent__c = parentopp1.Id;
        childopp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        childopp.Pricebook2Id = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        insert childopp;
        
        oppIdset.add(parentopp1.Id);
        oppIdset.add(childopp.Id);
        
        
        List<PricebookEntry> pbeoptyspltchildList = new List<PricebookEntry>();
        pbeoptyspltchildList = [select Id,product2Id from PricebookEntry where product2.ProductCode ='OPTY-SPLIT'];
        if(pbeoptyspltchildList.isEmpty()){
            Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT', ProductCode ='OPTY-SPLIT');
            insert optyspltchild;
            PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = optyspltchild.Id,UnitPrice = 1000,IsActive = true);
            insert pe1;
            pbeoptyspltchildList.add(pe1);
        }      
        Product2 prod2 = new Product2(IsActive = true, name = 'nasprod',ProductCode ='nasprod',Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'RUBRIK UCL'); //SAL26-138: NAS to Cloud
        prdList.add(prod2);
        insert prdList;
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        insert pBList;
        pbeoptyspltchildList.addAll(pBList);
        
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);

        }
        test.stopTest();
        System.assert(parentopp1.Id != null);
    }
    /**
     * @description test method
     */
    testMethod static void testMethodNoSplitProdparentsalessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        
       	OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        

        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Split_percentage__c = 50;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c = 2000;
        parentopp1.OppSubscriptionTermMonths__c = 36;
        parentopp1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        parentopp1.Pricebook2Id = Test.getStandardPricebookId();
        parentopp1.Opportunity_Split_Parent__c = null;
        insert parentopp1;
		
        Opportunity childopp = new Opportunity();
        childopp.StageName = '1 Discovery';
        childopp.closeDate = System.Today() + 30;
        childopp.Name = 'Test Opp 31-05 -split';
        childopp.Opportunity_Type__c = 'New Customer';
        childopp.Opportunity_Sub_Type__c = 'Regular';
        childopp.split__c = true;
        childopp.Amount = 2000;
        childopp.ACV_Amount__c = 2000;
        childopp.OppSubscriptionTermMonths__c = 36;
        childopp.Split_percentage__c = 50;
        childopp.Opportunity_Split_Parent__c = parentopp1.Id;
        childopp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        childopp.Pricebook2Id = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        insert childopp;
        
        oppIdset.add(parentopp1.Id);
        oppIdset.add(childopp.Id);
           
        Product2 prod2 = new Product2(IsActive = true, name = 'hardwareprod',ProductCode ='hardwareprod',Sales_Comp_Category__c = 'HARDWARE');
        prdList.add(prod2);
        insert prdList;
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        insert pBList;
        
        oppLineList.add(new OpportunityLineItem(product2Id = pBList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pBList[0].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));

        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = false;
            OpportunitySplitLWCController.createOptySPlitLine = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);

        }
        test.stopTest();
        System.assert(parentopp1.Id != null);
    }
     /**
     * @description test method
     */
     testMethod static void testMethodnegativechildsalessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        Set<ID> oppIdset = new Set<ID>();
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        
       	OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        

        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Split_percentage__c = 50;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c = 2000;
        parentopp1.OppSubscriptionTermMonths__c = 36;
        parentopp1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        parentopp1.Pricebook2Id = Test.getStandardPricebookId();
        parentopp1.Opportunity_Split_Parent__c = null;
        insert parentopp1;
		
        Opportunity childopp = new Opportunity();
        childopp.StageName = '1 Discovery';
        childopp.closeDate = System.Today() + 30;
        childopp.Name = 'Test Opp 31-05 -split';
        childopp.Opportunity_Type__c = 'New Customer';
        childopp.Opportunity_Sub_Type__c = 'Regular';
        childopp.split__c = true;
        childopp.Amount = 2000;
        childopp.ACV_Amount__c = 2000;
        childopp.OppSubscriptionTermMonths__c = 36;
        childopp.Split_percentage__c = 50;
        childopp.Opportunity_Split_Parent__c = parentopp1.Id;
        childopp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        childopp.Pricebook2Id = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        insert childopp;
        
        oppIdset.add(parentopp1.Id);
        oppIdset.add(childopp.Id);
        
        
        List<PricebookEntry> pbeoptyspltchildList = new List<PricebookEntry>();
        pbeoptyspltchildList = [select Id,product2Id from PricebookEntry where product2.ProductCode ='OPTY-SPLIT'];
        if(pbeoptyspltchildList.isEmpty()){
            Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT', ProductCode ='OPTY-SPLIT');
            insert optyspltchild;
            PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = optyspltchild.Id,UnitPrice = 1000,IsActive = true);
            insert pe1;
            pbeoptyspltchildList.add(pe1);
        }        
        Product2 prod2 = new Product2(IsActive = true, name = 'nasprod',ProductCode = 'nasprod', Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'RUBRIK UCL'); //SAL26-138: NAS to Cloud
        prdList.add(prod2);
        Product2 prod3 = new Product2(IsActive = true, name = 'nasprod33',ProductCode = 'nasprod33',Product_Hierarchy_Group__c = 'PLS-Cloud',Sales_Comp_Category__c = 'RUBRIK UCL'); //SAL26-138: NAS to Cloud
        prdList.add(prod3);
        insert prdList;
        PricebookEntry pe2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod2.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe2);
        PricebookEntry pe3 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = prod3.Id,UnitPrice = 1000,IsActive = true);
        pBList.add(pe3);
        insert pBList;
        pbeoptyspltchildList.addAll(pBList);
        
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[0].Id,TotalPrice=-2000,Quantity = 1,OpportunityID = childopp.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[0].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[0].Id,TotalPrice=-2000,Quantity = 1,OpportunityID = parentopp1.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[1].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[1].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        oppLineList.add(new OpportunityLineItem(product2Id = pbeoptyspltchildList[2].product2Id,Line_Type_Text__c = 'New',pricebookentryid=pbeoptyspltchildList[2].Id,TotalPrice=2000,Quantity = 1,OpportunityID = parentopp1.Id));
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        OppAnnualContractValueUtil.OppACVRecursion = true;
        insert oppLineList;
        
        test.startTest();
        System.runAs(user) {
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);

        }
        test.stopTest();
        System.assert(parentopp1.Id != null);
    }
     /**
     * @description test method
     */
     testMethod static void testMethodNoProductssalessplit(){
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        List<User> userLst = [SELECT Id FROM User WHERE isActive = true LIMIT 3];
        Set<ID> oppIdset = new Set<ID>();
        List<Product2> prdList = new List<Product2>(); 
        List<Opportunity> oppList = new List<Opportunity>(); 
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        List<PricebookEntry> pBList = new List<PricebookEntry>();
        
       	OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        

        Opportunity parentopp1 = new opportunity();
        parentopp1.StageName = '1 Discovery';
        parentopp1.closeDate = System.Today() + 30;
        parentopp1.Name = 'Test Opp 31-05';
        parentopp1.Opportunity_Type__c = 'New Customer';
        parentopp1.Opportunity_Sub_Type__c = 'Regular';
        parentopp1.split__c = true;
        parentopp1.Split_percentage__c = 50;
        parentopp1.Amount = 2000;
        parentopp1.ACV_Amount__c = 2000;
        parentopp1.OppSubscriptionTermMonths__c = 36;
        parentopp1.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        parentopp1.Pricebook2Id = Test.getStandardPricebookId();
        parentopp1.Opportunity_Split_Parent__c = null;
        parentopp1.SaaS_Co_Owner__c = userLst[0].Id;
        parentopp1.Co_Owner__c = userLst[1].Id;
        parentopp1.NCD_Co_Owner__c = userLst[2].Id;
        insert parentopp1;
		
        Opportunity childopp = new Opportunity();
        childopp.StageName = '1 Discovery';
        childopp.closeDate = System.Today() + 30;
        childopp.Name = 'Test Opp 31-05 -split';
        childopp.Opportunity_Type__c = 'New Customer';
        childopp.Opportunity_Sub_Type__c = 'Regular';
        childopp.split__c = true;
        childopp.Amount = 2000;
        childopp.ACV_Amount__c = 2000;
        childopp.OppSubscriptionTermMonths__c = 36;
        childopp.Split_percentage__c = 50;
        childopp.Opportunity_Split_Parent__c = parentopp1.Id;
        childopp.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        childopp.Pricebook2Id = Test.getStandardPricebookId();
        childopp.SaaS_Co_Owner__c = userLst[0].Id;
        childopp.Co_Owner__c = userLst[1].Id;
        childopp.NCD_Co_Owner__c = userLst[2].Id;
        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        insert childopp;
        
        oppIdset.add(parentopp1.Id);
        oppIdset.add(childopp.Id);

         Product2 optyspltchild = new Product2(IsActive = true, name = 'OPTY-SPLIT', ProductCode ='OPTY-SPLIT');
         insert optyspltchild;
         PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(),Product2Id = optyspltchild.Id,UnitPrice = 1000,IsActive = true);
         insert pe1;
         OpportunityLineItem splitOli = new OpportunityLineItem(product2Id = optyspltchild.Id,Line_Type_Text__c = 'New',pricebookentryid=pe1.Id,TotalPrice=2000,Quantity = 1,OpportunityID = childopp.Id);
         INSERT splitOli;
         
        test.startTest();
        System.runAs(user) {
			/*OpportunityLineItem splitOLI = [SELECT Id, Subsumed_Renewal_Amount__c, Subsumed_Renewal_TCV__c, New_Expansion_ACV__c, New_Expansion_TCV__c,
                                            ACV_Amount__c, TotalPrice, PLS_New_Expansion_ACV__c, SaaS_New_Expansion_ACV__c, NAS_New_Expansion_ACV__c, PLS_NCD_New_Expansion_ACV__c, Core_New_Expansion_ACV__c
                                            FROM OpportunityLineItem WHERE Product2.Id = :optyspltchild.Id];
            Opportunity oppChild = [SELECT Id, Opportunity_Type__c, SaaS_Co_Owner__c, Co_Owner__c, NCD_Co_Owner__c FROM Opportunity WHERE Id = :childopp.Id];*/
			OppAnnualContractValueUtil.setArroyofieldsforSplitProducts(splitOli, childopp);
            childopp.SaaS_Co_Owner__c = null;
            childopp.Co_Owner__c = null;
            childopp.NCD_Co_Owner__c = null;
            UPDATE childopp;
            OppAnnualContractValueUtil.setArroyofieldsforSplitProducts(splitOli, childopp);
            FlowControll.opportunityTriggerHandler = false;
            OppAnnualContractValueUtil.OppACVRecursion = false;
            OpportunitySplitLWCController.createOptySPlitLine = false;
        	OppAnnualContractValueUtil.calculateAcvAmount(oppIdset);

        }
        test.stopTest();
        System.assert(parentopp1.Id != null);
    }
    
    /**
     * @description test method for RCV sku acv calculation
     */
    @isTest static void accountUpdateRcvAcvTest(){
        Account objAccount = new Account();
        objAccount.Name = 'Test Account 01-01';
        objAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer/Prospect').getRecordTypeId();
        INSERT objAccount;
        
        User user = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true LIMIT 1];
        OpportunityUtil.defaultPriceBookId = Test.getStandardPricebookId();
        Opportunity opp = new opportunity();
        opp.AccountId = objAccount.Id;
        opp.StageName = '1 Discovery';
        opp.closeDate = System.Today() + 30;
        opp.Name = 'Test Opp 31-05';
        opp.Opportunity_Type__c = 'New Customer';
        opp.Opportunity_Sub_Type__c = 'Regular';
        opp.split__c = true;
        opp.Amount = 2000;
        opp.UCL_Scale_Percentage__c = 0;
		opp.Co_Owner__c = user.Id;
        opp.PLS_AE_ETM_Role_Name__c = 'Cloud AE';

        flowControll.opportunityLineItemHandler = false;
        FlowControll.opportunityTriggerHandler = false;
        INSERT opp;
      
        Product2 prod = new Product2(IsActive = true, name = 'RCVLRS',Sales_Comp_Category__c = 'RCV ZRS');
        INSERT prod;

        PricebookEntry pe1 = new PricebookEntry(Pricebook2Id = OpportunityUtil.defaultPriceBookId,Product2Id = prod.Id,UnitPrice = 1000,IsActive = true);
        INSERT pe1;
        
		INSERT new OpportunityLineItem(product2Id = pe1.product2Id,Line_Type_Text__c = 'New',pricebookentryid=pe1.Id,TotalPrice=2000,Quantity = 1,OpportunityID = opp.Id);
       
        Test.startTest();
        System.runAs(user) {
            objAccount.Customer_Type_Without_RCV__c = 'Cloud Customer w/o RCV';
            UPDATE objAccount;
            
            OppAnnualContractValueUtil.OppACVRecursion = false;
            OppAnnualContractValueUtil.calculateAcvAmount(new Set<Id>{opp.Id});
        }
        Test.stopTest();
        System.assert(true);
    }
}