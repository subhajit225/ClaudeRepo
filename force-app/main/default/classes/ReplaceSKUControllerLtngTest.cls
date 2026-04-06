@isTest
/**Test class for  ReplaceSKUControllerLtng*/
public class ReplaceSKUControllerLtngTest {
    @TestSetUp 
        static void initialDataSetup() { 
        List<TriggerControl__c> lstTriggContrs = new List<TriggerControl__c>();
        TriggerControl__c setting1 = new TriggerControl__c();
        setting1.Name = 'Opportunity';
        setting1.DisableTrigger__c = TRUE;
        lstTriggContrs.add(setting1);
        TriggerControl__c setting2 = new TriggerControl__c();
        setting2.Name = 'Entitlement';
        setting2.DisableTrigger__c = TRUE;
        lstTriggContrs.add(setting2);
        insert lstTriggContrs; 
        
        ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
        disableFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        upsert disableFuncCS;
        
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
                                                                            Disable_SBQQ_Quote_Triggers__c = True,
                                                                            Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
                                                                            Disable_SBQQ_QuoteLine_Triggers__c = True,
                                                                            Disable_Opportunity_Validation_Rules__c = True,
                                                                            Disable_Opportunity_Triggers__c = True,
                                                                            Disable_Campaign_Member_Triggers__c = true,
                                                                           Disable_Campaign_Trigger__c = true,
                                                                           Disable_Campaign_Validation_Rules__c = true,
                                                                            Disable_Scale_Utility_Overage_Triggers__c  = true,
                                                                           Disable_Entitlement_Usage_Trigger__c=true,
                                                                            Disable_Entitlement_Trigger__c=true,
                                                                           Disable_ServiceContract_Trigger__c=true,
                                                                            Disable_Contract_Line_Item_Triggers__c  = true);
        insert cdf;
        
        Account accObj = TestDataFactory.getAccount();
        accObj.RSC_G_Eligible__c = true; //MS RSCG
        insert accObj;
        
        Opportunity oppr = TestDataFactory.getOpportunity(accObj);
        insert oppr;
        Opportunity renOppr = TestDataFactory.getOpportunity(accObj);
        insert renOppr;
        
        Id standardPriceBookId =  Test.getStandardPricebookId();
        
        PriceBook2 pb1  = new Pricebook2(Name = 'CPQ Pricebook', Description = 'Price Book 2009 Products 1', IsActive = true);
        insert pb1;
        
        Product2 prod1 = new Product2(
            Name = 'RS-BT-FE-SC-PE-PA',
            ProductCode = 'RS-BT-FE-SC-PE-PA',
            isActive = true
        );
        Product2 prod2 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-R304',
            isActive = true
        );
        Product2 prod3 = new Product2(
            Name = 'RBK-R Premium Support 1-Yr Prepaid, r304',
            ProductCode = 'RBK-SVC-PREM-APPLIANCE',
            isActive = true
        );
        Product2 prod4 = new Product2(
            Name = 'RBK-R6408S-HW-01',
            ProductCode = 'RBK-R6408S-HW-01',
            isActive = true
        );
        Product2 prodRCDM = new Product2(
            Name = 'RS-BT-RCDM-T',
            ProductCode = 'RS-BT-RCDM-T',
            isActive = true
        );
        Product2 prod5 = new Product2(
            Name = 'RS-UR-MH5G-PE-PP',
            ProductCode = 'RS-UR-MH5G-PE-PP',
            isActive = true
        );
        insert new List<Product2>{prod1, prod2, prod3, prod4, prodRCDM,prod5};
            
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
            
            PricebookEntry pbStanEntry4 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbStanEntryRCDM = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prodRCDM.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
         PricebookEntry pbStanEntry5 = new PricebookEntry(
            Pricebook2Id = standardPriceBookId,
            Product2Id = prod5.Id,
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
            
        PricebookEntry pbEntry4 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod4.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        
        
        PricebookEntry pbEntryRCDM = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prodRCDM.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        PricebookEntry pbEntry5 = new PricebookEntry(
            Pricebook2Id = pb1.id,
            Product2Id = prod5.Id,
            UnitPrice = 1000.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbStanEntry1, pbStanEntry2, pbStanEntry3,pbStanEntry4, pbStanEntryRCDM,pbStanEntry5, pbEntry1, pbEntry2, pbEntry3, pbEntry4, pbEntryRCDM,pbEntry5};
        
        List<Asset> lstAsset = new List<Asset>();
        Asset newAsset = new Asset(Name = 'AA165203480078', SerialNumber = 'AA165203480078', 
                                   Product2Id = prod4.Id, AccountId = accObj.Id,
                                   SBQQ__CombineKey__c = '8026f000000F4SyAAK', Licensing_Model__c = 'Perpetual'
                                   );
        Asset newAsset2 = new Asset(Name = 'AA165203480028', SerialNumber = 'AA165203480028', 
                                   Product2Id = prod4.Id, AccountId = accObj.Id,
                                   SBQQ__CombineKey__c = '8026f000000F4SyAAK', Licensing_Model__c = 'Perpetual'
                                   );

        Asset newAsset3 = new Asset(Name = 'AA165203480030', SerialNumber = 'AA165203480030', 
                                   Product2Id = prod2.Id, AccountId = accObj.Id,
                                   SBQQ__CombineKey__c = '8026f000000F4SyAAK', Licensing_Model__c = 'Perpetual'
                                   );
        lstAsset.add(newAsset);
        lstAsset.add(newAsset2);
        lstAsset.add(newAsset3);
        insert lstAsset;    
        
        //create Service Contract
        ServiceContract serviceContractObj = new ServiceContract(Name = 'sample SC', SBQQSC__Opportunity__c = oppr.Id,AccountId = accObj.Id,StartDate = System.today(),
                                                                PriceBook2Id = pb1.Id,Term = 36, EndDate = System.today() + 365,SBQQSC__RenewalOpportunity__c = renOppr.id,
                                                                SBQQSC__RenewalQuoted__c = true);
        insert serviceContractObj;

        List<ContractLineItem> lstCLIs = new List<ContractLineItem>();
        
        //Contract Line Items
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj.PricebookEntryId = pbEntry2.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj.SBQQSC__Product__c = prod2.Id;
        ContractLineItemObj.Licensing_Model__c = 'Subscription';
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate = System.today().addMonths(36);
        lstCLIs.add(ContractLineItemObj);

        //Contract Line Items
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = accObj.Id;
        ContractLineItemObj1.PricebookEntryId = pbEntry1.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.SBQQSC__SubscriptionPricing__c='Fixed Price';
        ContractLineItemObj1.SBQQSC__Product__c = prod1.Id;
        ContractLineItemObj1.Licensing_Model__c = 'Subscription';
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.EndDate = System.today().addMonths(36);
        lstCLIs.add(ContractLineItemObj1);
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        SBQQ.TriggerControl.disable();
        insert lstCLIs;
        SBQQ.TriggerControl.enable();
                

        List<Entitlement> lstEnts = new List<Entitlement>();

        Entitlement enttitlementNewObj = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj.AccountId = accObj.Id;
        enttitlementNewObj.StartDate = Date.today().addDays(-365);
        enttitlementNewObj.EndDate = Date.today().addDays(+200);
        enttitlementNewObj.ContractLineItemId = ContractLineItemObj.Id;
        enttitlementNewObj.Type = 'Phone Support';
        enttitlementNewObj.Name = 'EntitlementTriggerHelper';
        enttitlementNewObj.Product__c = prod1.Id; 
        enttitlementNewObj.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj.ServiceContractId = serviceContractObj.Id;
        enttitlementNewObj.AssetId = newAsset.Id;
        lstEnts.add(enttitlementNewObj);
            
        Entitlement enttitlementNewObj1 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj1.AccountId = accObj.Id;
        enttitlementNewObj1.StartDate = Date.today().addDays(-365);
        enttitlementNewObj1.EndDate = Date.today().addDays(+200);
        enttitlementNewObj1.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj1.Type = 'Phone Support';
        enttitlementNewObj1.Name = 'EntitlementTriggerHelper1';
        enttitlementNewObj1.Product__c = prod1.Id; 
        enttitlementNewObj1.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj1.ServiceContractId = serviceContractObj.Id;
        enttitlementNewObj1.AssetId = newAsset2.Id;
        lstEnts.add(enttitlementNewObj1);

        
        Entitlement enttitlementNewObj3 = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        enttitlementNewObj3.AccountId = accObj.Id;
        enttitlementNewObj3.StartDate = Date.today().addDays(-365);
        enttitlementNewObj3.EndDate = Date.today().addDays(+200);
        enttitlementNewObj3.ContractLineItemId = ContractLineItemObj1.Id;
        enttitlementNewObj3.Type = 'Phone Support';
        enttitlementNewObj3.Name = 'EntitlementTriggerHelper1';
        enttitlementNewObj3.Product__c = prod2.Id; 
        enttitlementNewObj3.Refreshed_Opportunity_Link__c = oppr.Id;
        enttitlementNewObj3.ServiceContractId = serviceContractObj.Id;
        enttitlementNewObj3.AssetId = newAsset3.Id;
        lstEnts.add(enttitlementNewObj3);
            
        insert lstEnts; 
        
        List<SBQQ__ProductOption__c> poList = new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c prodOption = new SBQQ__ProductOption__c(Refresh_Default_Option__c = true, SBQQ__ConfiguredSKU__c = prod1.Id, SBQQ__Number__c = 1,
                                                                      SBQQ__OptionalSKU__c = prodRCDM.Id);
        poList.add(prodOption);
        SBQQ__ProductOption__c prodOption2 = new SBQQ__ProductOption__c(Refresh_Default_Option__c = true, SBQQ__ConfiguredSKU__c = prod4.Id, SBQQ__Number__c = 1,
                                                                      SBQQ__OptionalSKU__c = prodRCDM.Id);
        poList.add(prodOption2);
        insert poList;
            
            
        Map<String, Object>  quoteMap = new Map<String, Object> {'SBQQ__Account__c' => accObj.Id,'SBQQ__Opportunity2__c' => oppr.Id};
        SBQQ__Quote__c qt1 = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), quoteMap);
        qt1.SBQQ__Opportunity2__c = oppr.Id;
        qt1.SBQQ__PriceBook__c = pb1.Id;
        qt1.SBQQ__Type__c = 'Renewal+Expansion';
        qt1.SBQQ__StartDate__c = Date.today();
        qt1.Manual_Billing__c = false;
        qt1.Consolidate_Lines__c = false;
        qt1.SBQQ__Account__c = accObj.Id;
        qt1.RWD_Deal_Ops_Exception__c = '$0 RSC-G Replacement';
        qt1.RWD_Deal_Ops_Exception_Justification__c = '$0 RSC-G Replacement RWD_Deal_Ops_Exception_Justification__c';
        insert qt1;
        
        List<SBQQ__QuoteLineGroup__c> lstGroups = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c  renewGrp = new SBQQ__QuoteLineGroup__c  (Name = 'Renewal Quote', SBQQ__Quote__c = qt1.Id);
        SBQQ__QuoteLineGroup__c  expGrp = new SBQQ__QuoteLineGroup__c  (Name = 'Expansion Quote', SBQQ__Quote__c = qt1.Id);
        lstGroups.add(renewGrp);
        lstGroups.add(expGrp);
        insert lstGroups;
        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c ql1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, Prior_Net_Total__c = 10, SBQQ__Product__c = prod1.Id, SBQQ__Quantity__c = 20,required_by_ext_Id__c = 'DGHT56748',
                                                        TPH_Drive_Size__c  = '24-BETB:15',TPH_Quantity__c = '4',TPH_OEM__c ='HPE',TPH_Models_Gen__c = 'DL360G10',Temp_TPH_Count__c = 5,
                                                        SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = 1, SBQQ__ListPrice__c = 200,Special_Program__c='Replaced',
                                                        SBQQ__NetPrice__c = 200, SBQQ__StartDate__c =  Date.today(), SBQQ__EndDate__c = Date.today().addDays(10), 
                                                        SubscribedAssetNames__c = 'AA165203480078',Disposition_Reason__c = 'None', SBQQ__Group__c = renewGrp.Id,Related_Asset_Total_Capacity__c = 10,
                                                        Product_Subtype__c = 'GO' , SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id, SBQQ__SubscribedAssetIds__c = newAsset.Id, AssociatedAccount__c= accObj.Id);
        SBQQ__QuoteLine__c ql4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod2.Id,required_by_ext_Id__c = 'DGJY56748', MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20,
                                                        TPH_Drive_Size__c  = '24-BETB:15',TPH_Quantity__c = '4',TPH_OEM__c ='HPE',TPH_Models_Gen__c = 'DL360G10',Temp_TPH_Count__c = 5,
                                                        SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null,Related_Asset_Total_Capacity__c = 10,
                                                        SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, 
                                                        //SubscribedAssetNames__c = 'AA165203480078',
                                                        SubscribedAssetNames__c = 'AA165203480030',
                                                        Disposition_Reason__c = 'None', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
                                                        SBQQ__Group__c = renewGrp.Id, Product_Type__c = 'Hybrid M365', AssociatedAccount__c= accObj.Id);
        SBQQ__QuoteLine__c ql5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prod3.Id,required_by_ext_Id__c = 'RBK-R Premium Support 1-Yr Prepaid, r304', MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20, 
                                                        TPH_Drive_Size__c  = '24-BETB:15',TPH_Quantity__c = '4',TPH_OEM__c ='HPE',TPH_Models_Gen__c = 'DL360G10',Temp_TPH_Count__c = 5,
                                                        SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null,Related_Asset_Total_Capacity__c = 10,
                                                        SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'AA165203480078',
                                                        Disposition_Reason__c = 'Renew Later', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id, 
                                                        SBQQ__Group__c = renewGrp.Id, SBQQ__SubscribedAssetIds__c = newAsset.Id, Product_Type__c = 'HW Support', AssociatedAccount__c= accObj.Id);
       SBQQ__QuoteLine__c ql6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt1.Id, SBQQ__Product__c = prodRCDM.Id,required_by_ext_Id__c = 'BFHT56748', MSP_Segment_Product__c = true, SBQQ__Quantity__c = 20,
                                                       TPH_Drive_Size__c  = '24-BETB:15',TPH_Quantity__c = '4',TPH_OEM__c ='HPE',TPH_Models_Gen__c = 'DL360G10',Temp_TPH_Count__c = 5,
                                                        SBQQ__Segmentindex__c  =1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = null,Related_Asset_Total_Capacity__c = 10,
                                                        SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, SubscribedAssetNames__c = 'AA165203480078',
                                                        Disposition_Reason__c = 'None', 
                                                        SBQQ__Group__c = renewGrp.Id, SBQQ__SubscribedAssetIds__c = newAsset.Id, AssociatedAccount__c= accObj.Id);
            
      
        lines.add(ql1);
        lines.add(ql4);
        lines.add(ql5);
        lines.add(ql6);
        insert lines;
        
        List<SBQQ__QuoteLine__c> updateLines = new List<SBQQ__QuoteLine__c>();
        ql4.SBQQ__RequiredBy__c = ql1.Id;
        ql5.SBQQ__RequiredBy__c = ql1.Id;
        ql6.SBQQ__RequiredBy__c = ql1.Id;
                   
        updateLines.add(ql4);
        updateLines.add(ql5);
        updateLines.add(ql6);
        update updateLines;
        
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(qt1.Id, yesterday);
        
        List<SAAS_To_SAAS__c> lstMapping = new List<SAAS_To_SAAS__c>();
        SAAS_To_SAAS__c saasRec1 = new SAAS_To_SAAS__c(From__c = prod2.Id, To__c = prod3.Id,Section_Category__c='SaaS replacement',Uplift_Percent__c =25,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec2 = new SAAS_To_SAAS__c(From__c = prod2.Id, To__c = prod1.Id,Section_Category__c='Go to Scale replacement',Uplift_Percent__c =25,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec3 = new SAAS_To_SAAS__c(From__c = prod3.Id, To__c = prod2.Id,Section_Category__c='Go to Scale replacement',Uplift_Percent__c =25,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec4 = new SAAS_To_SAAS__c(From__c = prod1.Id, To__c = prod3.Id,Section_Category__c='SaaS replacement',Uplift_Percent__c =25,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec5 = new SAAS_To_SAAS__c(From__c = prod3.Id, To__c = prod1.Id,Section_Category__c='Go to Scale replacement',Uplift_Percent__c =25,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec6 = new SAAS_To_SAAS__c(From__c = prod4.Id, To__c = prod1.Id,Section_Category__c='SaaS replacement',Uplift_Percent__c =25,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec7 = new SAAS_To_SAAS__c(From__c = prod4.Id, To__c = prod1.Id,Section_Category__c='');

        
        SAAS_To_SAAS__c saasRec8 = new SAAS_To_SAAS__c(From__c = prod2.Id, To__c = prod3.Id,Section_Category__c='RSC to RSC-G', Name = 'RBK-SVC-PREM-R304 => RBK-SVC-PREM-APPLIANCE',Active__c = true, RenLater__c = true, No_Merge__c= true, Uplift_Percent__c =25,	Starting_Point__c='Quote Creation Date', IAR__c=false,	Additional_Days__c=30,	Is_EDNE__c = true,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec9 = new SAAS_To_SAAS__c(From__c = prod2.Id, To__c = prod1.Id,Section_Category__c='SAAS-SAAS-G', Name = 'RBK-SVC-PREM-R304 => RS-BT-FE-SC-PE-PA', Active__c = true, RenLater__c = true, No_Merge__c= true, Uplift_Percent__c =25,	Starting_Point__c='Quote Creation Date', IAR__c= false,	Additional_Days__c=30,	Is_EDNE__c = true,Storage_Tier__c ='20 GB');
        SAAS_To_SAAS__c saasRec10 = new SAAS_To_SAAS__c(From__c = prod4.Id, To__c = prod1.Id,Section_Category__c='LOD-RSC-G', Name = 'RBK-R6408S-HW-01 => RS-BT-FE-SC-PE-PA', Active__c = true, RenLater__c = true, No_Merge__c= false, Uplift_Percent__c =25,	Starting_Point__c='Quote Creation Date', IAR__c= true,	Additional_Days__c=30,	Is_EDNE__c = true,Storage_Tier__c ='20 GB');

        lstMapping.add(saasRec1);
        lstMapping.add(saasRec2);
        lstMapping.add(saasRec3);
        lstMapping.add(saasRec4);
        lstMapping.add(saasRec5);
        lstMapping.add(saasRec6);
        lstMapping.add(saasRec7); 
        
        lstMapping.add(saasRec8);
        lstMapping.add(saasRec9);
        lstMapping.add(saasRec10);   
        insert lstMapping;
            
    }

    /**TestMethods for fetching records to display */
    public static testMethod void testFetchSaasRecords() {
        SBQQ__Quote__c quoteRec = [Select Id, SBQQ__PriceBook__c from SBQQ__Quote__c where SBQQ__LineItemCount__c > 3 LIMIT 1];
        PriceBook2 pb1 = [Select Id from PriceBook2 LIMIT 1];
        
        quoteRec.SBQQ__PriceBook__c = pb1.Id;
        quoteRec.SBQQ__SubscriptionTerm__c = 36;
        update quoteRec;
        
        String quoteId = quoteRec.Id;
        String quoteId2 = quoteRec.Id;
        List<SBQQ__Quote__c> quoteRecList = new List<SBQQ__Quote__c>();
        quoteRecList.add(quoteRec);
        Assert.areEqual(1, quoteRecList.size());
       // List<SBQQ__QuoteLine__c> qlList = ReplaceSKUControllerLtng.getQuoteLinesAvailableForUpdate(quoteId);
       List<SBQQ__QuoteLine__c> qlList = [select id , SBQQ__SubscribedAssetIds__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =:quoteId ];
        Map<String, String> selectedRecords = new Map<String, String>();
        if (qlList != null && !qlList.isEmpty()) {
            for (SBQQ__QuoteLine__c qlRec : qlList) {
                if (qlRec.SBQQ__SubscribedAssetIds__c == null) {
                    selectedRecords.put(qlRec.Id,'RS-BT-FE-SC-PE-PA'); // 'RS-UR-MH5G-PE-PP');
                }else if (qlRec.SBQQ__SubscribedAssetIds__c != null ) {
                   // selectedRecords.put(qlRec.Id, 'RBK-SVC-PREM-APPLIANCE');
                   selectedRecords.put('AA165203480078', 'RS-BT-FE-SC-PE-PA');
                }
            }
        }
        
        ReplaceSKUControllerLtng cntrlr = new ReplaceSKUControllerLtng();
        try {
            ReplaceSKUControllerLtng.getQuoteFieldValuesFromApex('invalidId');
        } catch(AuraHandledException ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage());
        }


        ReplaceSKUControllerLtng.getQuoteFieldValuesFromApex(quoteId);
        ReplaceSKUControllerLtng.fetchSaasRecords(quoteId);  
        ReplaceSKUControllerLtng.fetchGoRecords(quoteId, 'Go to Scale replacement');  
        ReplaceSKUControllerLtng.fetchLoDRecords(quoteId,''); 
        ReplaceSKUControllerLtng.fetchGoRecords(quoteId, 'RSC to RSC-G'); 
        ReplaceSKUControllerLtng.fetchGoRecords(quoteId, 'SAAS-SAAS-G'); 
        ReplaceSKUControllerLtng.fetchLoDRecords(quoteId,'LOD-RSC-G');
        ReplaceSKUControllerLtng.replaceSKUs(quoteId, 
                                            ReplaceSKUControllerLtng.fetchSaasRecords(quoteId), 
                                            ReplaceSKUControllerLtng.fetchGoRecords(quoteId, 'Go to Scale replacement'),
                                            ReplaceSKUControllerLtng.fetchLoDRecords(quoteId,''), 
                                            ReplaceSKUControllerLtng.fetchGoRecords(quoteId, 'RSC to RSC-G'), 
                                            ReplaceSKUControllerLtng.fetchGoRecords(quoteId, 'SAAS-SAAS-G'), 
                                            ReplaceSKUControllerLtng.fetchLoDRecords(quoteId,'LOD-RSC-G'), 
                                            selectedRecords);
        
        

         Date startDate = Date.newInstance(2024, 1, 5);
        Date endDate = Date.newInstance(2024, 3, 1);
        ReplaceSKUControllerLtng.getProrateMultiplier(startDate, endDate);
        ReplaceSKUControllerLtng.getMapOfToSKUsVsSaasRec(selectedRecords);  
        
    }

    @isTest
    static void testGetUnitPrice() {
        Id standardPbId =  Test.getStandardPricebookId();
        Product2 testProduct = new Product2(Name = 'RS-BT-FE-MDG-PE-PA',ProductCode = 'RS-BT-FE-MDG-PE-PA', IsActive = true, Dynamic_Pricing_Enabled__c = true);
        insert testProduct;

        PricebookEntry pbStanEntry1 = new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = testProduct.Id, UnitPrice = 100.00, IsActive = true);
        
        Dynamic_Pricing_Lookup__c dynamicPricing1 = new Dynamic_Pricing_Lookup__c(Product__c = testProduct.Id, Storage_Tier__c = '20 GB', Unit_Price__c = 10);
        Dynamic_Pricing_Lookup__c dynamicPricing2 = new Dynamic_Pricing_Lookup__c(Product__c = testProduct.Id, Storage_Tier__c = '50 GB', Unit_Price__c = 20);
        insert new List<Dynamic_Pricing_Lookup__c>{dynamicPricing1, dynamicPricing2};
        
        Test.startTest();
        Decimal unitPrice1 = ReplaceSKUControllerLtng.getUnitPrice(testProduct.Id, '20 GB');
        System.assertEquals(10, unitPrice1);
        
        Decimal unitPrice2 = ReplaceSKUControllerLtng.getUnitPrice(testProduct.Id, '50 GB');
        System.assertEquals(20, unitPrice2);

        Decimal unitPrice3 = ReplaceSKUControllerLtng.getUnitPrice(testProduct.Id, 'InvalidTier');
        System.assertEquals(null, unitPrice3);

        Decimal unitPrice4 = ReplaceSKUControllerLtng.getUnitPrice(null, '20 GB');
        System.assertEquals(null, unitPrice4);
        
        Decimal unitPrice5 = ReplaceSKUControllerLtng.getUnitPrice(testProduct.Id, null);
        Test.stopTest();
        System.assertEquals(null, unitPrice5);
    }
    
    @isTest
  static void testGetters() {
    Test.startTest();
    
    ReplaceSKUControllerLtng.SaasWrapper saasWrapper = new ReplaceSKUControllerLtng.SaasWrapper();
    ReplaceSKUControllerLtng.EntitlementWrapper entitlementWrapper = new ReplaceSKUControllerLtng.EntitlementWrapper();
    ReplaceSKUControllerLtng.AssetWrapper assetWrapper = new ReplaceSKUControllerLtng.AssetWrapper();
    ReplaceSKUControllerLtng.QuoteLineWrapper quoteLineWrapper = new ReplaceSKUControllerLtng.QuoteLineWrapper();
    
    quoteLineWrapper.assetNamesForTPH = 'Sample Asset Names';
    quoteLineWrapper.uplift = 10.5;
    quoteLineWrapper.astqli = 'Sample ASTQLI';
    assetWrapper.qlId = '234574889645678';
    
    entitlementWrapper.uplift = 10.5;
    entitlementWrapper.originalQuoteName = 'Sample Quote';
    
    saasWrapper.originalQuoteName = 'Sample Quote';

    System.assertEquals(10.5, entitlementWrapper.uplift);    
    Test.stopTest();
  }
      
      
}