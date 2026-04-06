/* Test Class for serviceContractList and serviceContractListBatch */
@IsTest
private class serviceContractListTest {

    /* testMethodserviceContract */
    @isTest
    public static void testMethodserviceContract(){
        List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        system.assert(usr1.Id != null);
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        System.runAs(usr1) {
        SBQQ.TriggerControl.disable();
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        insert setting1;
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Renewal Case';
        setting2.DisableTrigger__c = FALSE;
        insert setting2;
        TriggerControl__c setting3 = new TriggerControl__c();
        setting3.Name = 'Entitlement';
        setting3.DisableTrigger__c = TRUE;
        insert setting3;
            
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        insert accObj1;
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        oppr.Contract_Renewal_Term__c = 12;
        oppr.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        insert oppr;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'V68_2017_08_09_12_26_43', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RBK-GO-BE-R6408',
            ProductCode = 'RBK-GO-BE-R6408',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1
            //Product_Type__c = 'HW Support'
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true,
            SBQQ__SubscriptionTerm__c = 1,
            Product_Type__c = 'HW Support'
        );
        Product2 prod3 = new Product2(
            Name = 'RH-6408SE-02',
            ProductCode = 'RH-6408SE-02',
            Category__c = 'Hardware',
            Product_Subtype__c = 'GO',
            SBQQ__AssetConversion__c = 'None',
            SBQQSC__EntitlementConversion__c = 'One per unit',
            SBQQ__SubscriptionPricing__c = 'Fixed Price',
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__SubscriptionBase__c = 'List',
            SBQQ__SubscriptionType__c = 'Renewable',
            IsActive = true,
            Asset_Priority__c = 1,
            New_CPQ_Product__c = true,
            Product_Level__c = 'Hardware'
        );
        insert new List<Product2>{prod1, prod2, prod3};
            
            PricebookEntry pbStanEntry1 = new PricebookEntry(
                Pricebook2Id = standardPriceBookId,
                Product2Id = prod1.Id,
                UnitPrice = 100.00,
                IsActive = true
            );
        PricebookEntry pbStanEntry2 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntry3 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry1 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod1.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod2.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry3 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod3.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>
        {pbStanEntry1,pbStanEntry2,pbStanEntry3,pbEntry1,pbEntry2,pbEntry3};
        
        Map<String, Object>  quoteMap = new Map<String, Object> 
        {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
            
            Set<Id> quoteId = new Set<Id>();
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__Primary__c = true;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Status__c = 'Draft';
        qt1.SBQQ__Type__c = 'Renewal';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        insert qt1;
        
        qt1.MetricsLastCalcOn__c = System.today()+1;
        //qt1.LastModifiedDate = System.today()+2;
        update qt1;
        
        quoteId.add(qt1.Id);
        
        List<ServiceContract> lstServiceContract = new List<ServiceContract>();
        
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'EntitlementTriggerHelper Contract';
        serviceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        serviceContractObj.AccountId = accObj.Id;
        serviceContractObj.StartDate = Date.Today().addmonths(-30);
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.SBQQSC__RenewalOpportunity__c = oppr.Id;
        serviceContractObj.EndDate = System.today().addDays(360);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        lstServiceContract.add(serviceContractObj);
        
        ServiceContract renewServiceContractObj = new ServiceContract();
        renewServiceContractObj.Name = 'EntitlementTriggerHelper Contract';
        renewServiceContractObj.SBQQSC__Opportunity__c = oppr.Id;
        renewServiceContractObj.AccountId = accObj.Id;
        renewServiceContractObj.StartDate = System.today();
        renewServiceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        renewServiceContractObj.Term = 36;
        renewServiceContractObj.SBQQSC__Quote__c = qt1.Id;
        renewServiceContractObj.EndDate = System.today().addDays(360);
        lstServiceContract.add(renewServiceContractObj);
        insert lstServiceContract;
        
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbStanEntry1.Id;
        ContractLineItemObj.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj;
        
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj2.PricebookEntryId = pbStanEntry3.Id;
        ContractLineItemObj2.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.StartDate = Date.Today().addmonths(-29);
        ContractLineItemObj2.EndDate = Date.Today().addmonths(6);
        ContractLineItemObj2.SBQQSC__RenewalQuantity__c = 1;
        ContractLineItemObj2.SBQQSC__RootId__c = lstServiceContract[0].Id;
        
        insert ContractLineItemObj2;
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbEntry1.Id;
        ContractLineItemObj1.ServiceContractId = lstServiceContract[0].Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        
        /*Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = accObj.Id;
        ast.Name = 'AssetObj';
        ast.Rubrik_Suite__c = 'Foundation';
        ast.Payment_Options__c = 'Annual';
        ast.SerialNumber = '123\\s+';
        ast.Support_Type__c = 'L3';
        ast.Licensing_Model__c = 'Perpetual';
        ast.Product2Id = prod3.Id;
        insert ast;
        
        Entitlement entObj = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        entObj.AccountId = accObj.Id;
        entObj.StartDate = Date.today().addDays(-365);
        entObj.EndDate = Date.today().addDays(100);
        entObj.AssetId = ast.Id;
        entObj.Renewable__c = true;
        entObj.Type = 'Phone Support';
        entObj.Name = 'Entitlement';
        entObj.Product__c = prod3.Id;
        entObj.ContractLineItemId = ContractLineItemObj2.Id;
        entObj.Refreshed_Opportunity_Link__c = oppr.Id;
        entObj.ServiceContractId = lstServiceContract[0].Id;
        //insert entObj;
        */

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 10007, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Renewing', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), SubscribedAssetNames__c = 'BB192863040046', Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql2 = new SBQQ__QuoteLine__c(SBQQ__RequiredBy__c= ql1.Id,SubscribedAssetNames__c = 'AA165203480092, AA165203480094, AA164403480010, AA165203480109, AA164403480011', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480092 , AA164403480011',SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Refreshed',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql3 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 25, SBQQ__SubscriptionPricing__c = null, SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c = Date.today(), SBQQ__EndDate__c = Date.today().addDays(10),Prior_Net_Total__c = 21000);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', Special_Program__c = 'Conversion', Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'None', SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'BB192863040049', Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c  = 1);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010', PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 107, Arroyo_Subscribed_Asset_Name__c = 'AA165203480093', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SubscribedAssetNames__c = 'AA165203480092, AA165203480109, AA164403480010',PriorACVwithUplift__c = 10000, RTAwithoutUplift__c = 207, Arroyo_Subscribed_Asset_Name__c = 'AA165203480094 , AA164403480010', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, Sales_Comp_Category__c = 'HW SUPPORT', Disposition_Reason__c = 'Converted',SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 20, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), Prior_Net_Total__c = 21000, MSP_Segment_Product__c = true, SBQQ__Segmentindex__c = 1);
        
        lines.add(ql1);
        lines.add(ql2);
        lines.add(ql3);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        insert lines;
        
        List<ServiceContract> msContr = serviceContractList.fetchContracts(accObj.Id, oppr.Id);
        List<ContractLineItem> msContrLines = [SELECT ServiceContract.AccountID, ServiceContractId, EndDate, ServiceContract.SBQQSC__Quote__c, ServiceContract.SBQQSC__Quote__r.MSP_SKUs_Count__c, SBQQSC__RenewalQuantity__c, ServiceContract.GPL_Deal__c, ServiceContract.Name,
                                               ServiceContract.StartDate,ServiceContract.Status, ServiceContract.EndDate
                                               FROM ContractLineItem LIMIT 100];
        String JSONString = JSON.serialize(msContrLines);
        String qIdStr = serviceContractList.renewalContracts(JSONString, oppr.Id);
        //List<Entitlement> msEntitlements = [ Select Id, ContractLineItem.SBQQSC__RenewalQuantity__c, ServiceContractId, Asset.UsageEndDate, ContractLineItem.EndDate, ServiceContract.GPL_Deal__c, ContractLineItem.SBQQSC__SubscriptionType__c FROM Entitlement];
        
        Test.startTest();
/*      AutoQuoteCreationBatch1 obj = new AutoQuoteCreationBatch1(new Set<Id>{oppr.Id});
        Database.executeBatch(obj,1);*/
        Test.stopTest();

        Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = accObj.Id;
        ast.Name = 'AssetObj';
        ast.Rubrik_Suite__c = 'Foundation';
        ast.Payment_Options__c = 'Annual';
        ast.SerialNumber = '123\\s+';
        ast.Support_Type__c = 'L3';
        ast.Licensing_Model__c = 'Perpetual';
        ast.Product2Id = prod3.Id;
        ast.SBQQ__CombineKey__c = ql1.Id;
        insert ast;
        
        Entitlement entObj = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        entObj.AccountId = accObj.Id;
        entObj.StartDate = Date.today().addDays(-365);
        entObj.EndDate = Date.today().addDays(100);
        entObj.AssetId = ast.Id;
        entObj.Renewable__c = true;
        entObj.Type = 'Phone Support';
        entObj.Name = 'Entitlement';
        entObj.Product__c = prod3.Id;
        entObj.ContractLineItemId = ContractLineItemObj2.Id;
        entObj.Refreshed_Opportunity_Link__c = oppr.Id;
        entObj.ServiceContractId = lstServiceContract[0].Id;
        //insert entObj;

        Entitlement entObj2 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        entObj2.AccountId = accObj.Id;
        entObj2.StartDate = Date.today().addDays(-365);
        entObj2.EndDate = Date.today().addDays(100);
        //entObj2.AssetId = ast.Id;
        entObj2.Renewable__c = true;
        entObj2.Type = 'Phone Support';
        entObj2.Name = 'RBK-GO-EE-R6408';
        entObj2.Product__c = prod3.Id;
        entObj2.ContractLineItemId = ContractLineItemObj2.Id;
        entObj2.Refreshed_Opportunity_Link__c = oppr.Id;
        entObj2.ServiceContractId = lstServiceContract[0].Id;
        //insert entObj2;

        Entitlement entObj3 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        entObj3.AccountId = accObj.Id;
        entObj3.StartDate = Date.today().addDays(-365);
        entObj3.EndDate = Date.today().addDays(100);
        //entObj3.AssetId = ast.Id;
        entObj3.Renewable__c = true;
        entObj3.Type = 'Phone Support';
        entObj3.Name = 'RBK-GO-EE-R6408';
        entObj3.Product__c = prod3.Id;
        entObj3.ContractLineItemId = ContractLineItemObj.Id;
        entObj3.Refreshed_Opportunity_Link__c = oppr.Id;
        entObj3.ServiceContractId = lstServiceContract[0].Id;
        //insert entObj3;
        
        //Database.executeBatch(obj,1);
        String qIdStrg = serviceContractList.renewalContracts(JSONString, oppr.Id);
        //start
        CreateRenewalContext context = new CreateRenewalContext();
        context.masterContractId = lstServiceContract[0].Id;
        context.renewedContracts = new List<ServiceContract>();
        ServiceContract serviceContractToBeRenewed = new ServiceContract(ID = lstServiceContract[1].Id);
        context.renewedContracts.add(serviceContractToBeRenewed);
        context.returnOnlyQuoteId = false; 
        String jsonContext = JSON.serialize(context);
        serviceContractList scobj=new serviceContractList();
        scobj.load(null,jsonContext);
        Id qId = serviceContractList.fetchQuoteForSMSUI(oppr.Id, oppr.Opportunity_Sub_Type__c, oppr.Pricebook2Id, oppr.ContactId, oppr.OwnerId, oppr.AccountId);
        String quoteName = serviceContractList.getQuoteName(qId); //MS CPQ22-6072
        //Database.executeBatch(obj,1);
        System.assert(qIdStr != null);
        System.assert(qIdStrg != null);
        SBQQ.TriggerControl.enable();
        }
    }
    
    @isTest
    public static void testMethodserviceContract2(){
        List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        system.assert(usr1.Id != null);
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        System.runAs(usr1) {
        Account accObj = TestDataFactory.getAccount();
        insert accObj;
        Account accObj1 = TestDataFactory.getAccount();
        accObj1.Name = 'RUBRIK_ACC_NAME';
        insert accObj1;
        Account rbkAcc = new Account(Name='Rubrik');
        insert rbkAcc;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        oppr.SBQQ__QuotePricebookId__c = Test.getStandardPricebookId();
        insert oppr;
        
        test.startTest();
        
        Set<id> uids = new set<id>();
        id myid = userinfo.getUserID();
        uids.add(myid);
        serviceContractList.customShareOpp(uids,oppr.id);
        test.stopTest();
        }
    }
    @isTest
    public static void testMethodserviceContract3(){
    List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        system.assert(usr1.Id != null);
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true//FY25SR-2247
        );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        System.runAs(usr1) {
            test.startTest();
                serviceContractList.checkUserAccess();
                serviceContractList.getBusinessLogicSetting();
                    test.stopTest();
        }
    }
    
}