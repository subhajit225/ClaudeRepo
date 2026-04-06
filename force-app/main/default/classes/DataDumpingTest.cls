/***********************************************************************************************************
* Class Name           : DataDumpingTest
* @description         : This class is called from DataDumping class to test its method
/**********************************************************************************************************/
@isTest
public class DataDumpingTest {
    /***********************************************************************************************************
    * Method Name          : testDataDumpingMethod2
    * @description         : test Method 1
    /**********************************************************************************************************/
    @isTest 
    static void testDataDumpingMethod2(){  

        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName,
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account'
        );
        insert u;

        System.runAs(u) {

        ShGl_DisableBusinessLogic__c settingDisable2 = new ShGl_DisableBusinessLogic__c();
        settingDisable2.Name = 'System Administrator';
        settingDisable2.Disable_ServiceContract_Trigger__c = true;
        settingDisable2.Disable_Account_Triggers__c = true;
        settingDisable2.Disable_Entitlement_Validation_Rules__c = true;
        settingDisable2.Disable_Opportunity_Triggers__c=true;
        settingDisable2.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable2.Disable_SBQQ_QuoteLine_Triggers__c = true;
        settingDisable2.SetupOwnerId = u.Id;
        insert settingDisable2;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        SBQQ.TriggerControl.disable();
        
        TriggerControl__c TC = new TriggerControl__c();
        TC.Name = 'Entitlement';
        TC.DisableTrigger__c = true;
        TC.DisableTrigger__c = true;
        TC.Last_Batch_Run_Date__c = Date.newInstance(2021,04,30);
        TC.SendEmail__c = false;
        insert TC;
        
        Tier_Quantity_Range_lookup_Table__c tb = new Tier_Quantity_Range_lookup_Table__c();
        tb.Quantity_Lower_Bound__c = 1;
        tb.Quantity_Upper_Bound__c = 1000;
        tb.Location__c = 'US';
        tb.Discount_RSM__c = 30;
        tb.Approval_Category__c = 'Zone1';
        insert tb;
        
        List<Product_Constrain_Config__c> pccList = new List<Product_Constrain_Config__c>();
        Product_Constrain_Config__c pccInstance = new Product_Constrain_Config__c();
        
        pccInstance.Name = 'R6412 Cons';
        pccInstance.Dependent_Product__c = 'RBK-R6412S-CONS-DR';
        pccInstance.Constraining_Product__c = 'RBK-R6412S-CONS';
        pccInstance.Is_Active__c = TRUE;
        pccInstance.Dependent_Product_Quantity__c = null;
        pccInstance.Could_be_Repurchased__c = True;
        pccInstance.Self_Constrain_Only__c = false;
        pccInstance.Cross_Product_Constrain_Only__c = false;
        pccList.add(pccInstance);
        insert pccList;
        DataDumping.CustomMap cMap = new DataDumping.CustomMap();
        
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        Assert.areEqual(2, accountList.size());
        
        cMap.Acc = act;
        cMap.PCC = pccList;
        String myJSON = JSON.serialize(cMap);
        
        RestRequest request = new RestRequest();
        request.requestUri ='https://cs79.salesforce.com/services/apexrest/DataDumping';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(myJSON);
        
        RestContext.request = request;
        
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = act.Id;
        opp.CloseDate = Date.newInstance(2021,04,30);
        opp.Partner_Lookup__c = vAccount2.id;
        opp.Distributor_Lookup__c = vAccount.id;
        opp.Deal_Structuring_Oppty_Notes__c = 'Test';
        insert opp;
        Product2 trnSKU = new Product2(Name='PS-WRAPPER', IsActive=true, ProductCode = 'PS-WRAPPER', Quotable_Date__c = Date.newInstance(2004, 11, 11) ); 
        insert trnSKU; 
        Product2 trnSKU2 = new Product2(Name='RBK-SVC-TRN-VIRTUAL', IsActive=true, ProductCode = 'RBK-SVC-TRN-VIRTUAL', Quotable_Date__c = Date.newInstance(2004, 11, 11) ); 
        insert trnSKU2; 
        
        Product2 prod = new Product2(Name='PS-WRAPPER',ProductCode = 'PS-WRAPPER' ,IsActive=true, Quotable_Date__c = Date.newInstance(2004, 11, 11),
                                     IsHardwareNotRequiredForHybridLicense__c = false,SBQQSC__EntitlementConversion__c='One per unit',
                                     Product_Payment_Option__c=ReplacementConstants.PAYMENT_OPTION_ANNUAL
                                          );       
        Product2 hybLicenseprod = new Product2(Name='RS-BT-EE-PE-PP',ProductCode = 'RS-BT-EE-PE-PP', IsActive=true, Product_Level__c = 'Hybrid Software', 
                                               Product_Type__c='Enterprise Edition',Product_Subtype__c='Saas Cloud', X0__c=true,
                                               Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1');       
        Product2 hwprod = new Product2(Name='RH-6304S-01',ProductCode = 'RH-6304S-01', IsActive=true, Product_Level__c = 'Hardware', Product_Type__c='Hardware', 
                                       Usable_Capacity__c = 12.00,Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, X0__c = true,SBQQSC__EntitlementConversion__c='One per quote line');  
        Product2 supportProd = new Product2(Name='RS-HW-SVC-PE-S2',ProductCode = 'RS-HW-SVC-PE-S2', IsActive=true, Product_Level__c = 'Support', Product_Type__c='HW Support', 
                                            Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, X0__c = true); 
        Product2 supportProdNRD = new Product2(Name='RS-HW-SVC-PE-S2',ProductCode = 'RS-HW-SVC-PE-S2', IsActive=true, Product_Level__c = 'Support', Product_Type__c='HW Support', Family = 'Non-Returnable Disk Service' ,
                                            Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, X0__c = true); 
                                                    
        Product2 addOnprod = new Product2(Name='RS-BT-NDA-PE-PP',ProductCode ='RS-BT-NDA-PE-PP' , IsActive=true,  Product_Level__c = 'SaaS Software Addon', 
                                          Product_Type__c='NAS', Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, X0__c = true, Family = 'POLARIS', Add_on_Level__c = 'RCDM Add-On');
        Product2 scaleProd = new Product2(Name='RS-TB-EE-RSVX-PE',ProductCode ='RS-TB-EE-RSVX-PE' , IsActive=true,  Product_Level__c = 'Hybrid Software', Product_Type__c='Enterprise Edition',
                                          Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = false, X0__c =false); 
        Product2 scaleProd2 = new Product2(Name='RS-TB-EE-RSV-PE',ProductCode ='RS-TB-EE-RSV-PE' , IsActive=true,  Product_Level__c = 'Hybrid Software', Product_Type__c='Enterprise Edition',
                                          Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = false, X0__c =false); 
        Product2 addOnprod2 = new Product2(Name='RS-BT-NDA-PE-PP',ProductCode ='RS-BT-NDA-PE-PP' , IsActive=true,  Product_Level__c = 'SaaS Software Addon', 
                                           Product_Type__c='NAS', Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, 
                                           X0__c = true,Family = 'POLARIS', Add_on_Level__c = 'RCDM Add-On',Product_Payment_Option__c=ReplacementConstants.PAYMENT_OPTION_ANNUAL);
        List<Product2> prodList = new List<Product2>();
        prodList.add(hybLicenseprod);
        prodList.add(hwprod);
        prodList.add(supportProd);
        prodList.add(addOnprod);
        prodList.add(prod);
        prodList.add(scaleProd);
        prodList.add(addOnprod2);
        prodList.add(scaleProd2);
        prodList.add(supportProdNRD);
        insert prodList;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = prod.Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        pbeList.add(pricebookObj);
        PricebookEntry hybLicenseprodpbe = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        hybLicenseprodpbe.Product2Id = hybLicenseprod.Id;
        hybLicenseprodpbe.UnitPrice = 100;
        hybLicenseprodpbe.Pricebook2Id = Test.getStandardPricebookId();
        hybLicenseprodpbe.IsActive = true;
        pbeList.add(hybLicenseprodpbe);
        PricebookEntry hwprodpbe = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        hwprodpbe.Product2Id = hwprod.Id;
        hwprodpbe.UnitPrice = 100;
        hwprodpbe.Pricebook2Id = Test.getStandardPricebookId();
        hwprodpbe.IsActive = true;
        pbeList.add(hwprodpbe);
        PricebookEntry addOnprodpbe = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        addOnprodpbe.Product2Id = addOnprod.Id;
        addOnprodpbe.UnitPrice = 100;
        addOnprodpbe.Pricebook2Id = Test.getStandardPricebookId();
        addOnprodpbe.IsActive = true;
        pbeList.add(addOnprodpbe);
        PricebookEntry suppprodpbe = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        suppprodpbe.Product2Id = scaleProd.Id;
        suppprodpbe.UnitPrice = 100;
        suppprodpbe.Pricebook2Id = Test.getStandardPricebookId();
        suppprodpbe.IsActive = true;
        pbeList.add(suppprodpbe);
        PricebookEntry addOnprodpbe2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        addOnprodpbe2.Product2Id = addOnprod2.Id;
        addOnprodpbe2.UnitPrice = 100;
        addOnprodpbe2.Pricebook2Id = Test.getStandardPricebookId();
        addOnprodpbe2.IsActive = true;
        pbeList.add(addOnprodpbe2);
        PricebookEntry scaleprodpbe2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        scaleprodpbe2.Product2Id = scaleProd2.Id;
        scaleprodpbe2.UnitPrice = 100;
        scaleprodpbe2.Pricebook2Id = Test.getStandardPricebookId();
        scaleprodpbe2.IsActive = true;
        pbeList.add(scaleprodpbe2);
        PricebookEntry suppNRD = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        suppNRD.Product2Id = supportProdNRD.Id;
        suppNRD.UnitPrice = 100;
        suppNRD.Pricebook2Id = Test.getStandardPricebookId();
        suppNRD.IsActive = true;
        pbeList.add(suppNRD);
        
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 10000, Product2Id = trnSKU.Id, IsActive = true);
        insert standardPrice1;
        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 10000, Product2Id = trnSKU2.Id, IsActive = true);
        insert standardPrice2;
        
        insert pbeList;
        ShGl_DisableBusinessLogic__c isDisabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled.Disable_Contract_Line_Item_Triggers__c = true;
        isDisabled.Disable_ServiceContract_Trigger__c = true;
        List<ServiceContract> contractList = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
        serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
        //serviceContractObj.SBQQSC__Quote__c = quoteRec1.Id;
        //serviceContractObj.SBQQSC__RenewalOpportunity__c = lstOpportunity[1].Id;
        serviceContractObj.AccountId = act.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.EndDate = System.today().addDays(365);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        contractList.add(serviceContractObj);
        insert contractList;
        
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.SerialNumber = '123456';
        asset.AccountId = act.id;
        asset.Product2Id = prod.Id;
        insert asset;
        
        List<contractLineItem> cliList = new List<contractLineItem>(); 
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = act.Id;
        ContractLineItemObj.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate = System.today().addDays(120);
        cliList.add(ContractLineItemObj);
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = act.Id;
        ContractLineItemObj1.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.EndDate = System.today().addDays(120);
        cliList.add(ContractLineItemObj1);
            
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = act.Id;
        ContractLineItemObj2.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj2.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.StartDate = System.today();
        ContractLineItemObj2.EndDate = System.today().addDays(120);
        ContractLineItemObj2.LinkedAssets__c= '123456';
        ContractLineItemObj2.SBQQSC__Discount__c = 50;
        cliList.add(ContractLineItemObj2);    

        ContractLineItem ContractLineItemObj3 = ContractLineItemObj.clone();
        cliList.add(ContractLineItemObj3);

        ContractLineItem ContractLineItemObj4 = ContractLineItemObj.clone();
        cliList.add(ContractLineItemObj4);
           
        insert cliList;
        
        List<Entitlement> ent=new List<Entitlement>();
        Entitlement ent1 = new Entitlement(Name='Testing', 
                                          AccountId=act.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj.id,
                                          Product__c =prod.id,
                                          Quantity__c=10,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365),
                                         AssetId=asset.id,
                                         Entitlement_ACV__c = 100,
                                         EntitlementExitDate__c = Date.today().addDays(180));
        ent.add(ent1);
            Entitlement ent2 = new Entitlement(Name='Testing1', 
                                          AccountId=act.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj.id,
                                          Product__c =hwprod.id,
                                          Quantity__c=10,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365),
                                         AssetId=asset.id,
                                         Entitlement_ACV__c = 100,
                                         Entitlement_RAMP_EXIT_ACV__c = 100,
                                         EntitlementExitDate__c = Date.today().addDays(180));
        ent.add(ent2);
             Entitlement ent3 = new Entitlement(Name='Testing1', 
                                          AccountId=act.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj2.id,
                                          Product__c =hwprod.id,
                                          Quantity__c=1,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365),
                                         Entitlement_ACV__c = 100,
                                         Entitlement_RAMP_EXIT_ACV__c = 100,
                                         EntitlementExitDate__c = Date.today().addDays(180)
                                          );
        ent.add(ent3);
        insert ent;

        Scale_Entitlement__c Sent = new Scale_Entitlement__c(Type__c= 'Non-Scale',Contract_Line_Item__c=ContractLineItemObj.id,Entitlement__c=ent[0].id,Asset__c=asset.id);
        insert Sent;
        Scale_Entitlement__c Sent1 = new Scale_Entitlement__c(Type__c= 'Non-Scale',Contract_Line_Item__c=ContractLineItemObj.id,Entitlement__c=ent[0].id,Asset__c=asset.id);
        insert Sent1;        
        Scale_Entitlement__c Sent2 = new Scale_Entitlement__c(Type__c= 'Non-Scale',Contract_Line_Item__c=ContractLineItemObj.id,Entitlement__c=ent[0].id,Asset__c=asset.id);
        insert Sent2; 
        List<SBQQ__Quote__c>lstQuote = new List<SBQQ__Quote__c>();
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__SubscriptionTerm__c = 12;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Type__c = 'Renewal';
        qt.RWD_Deal_Ops_Exception__c = 'Quoting Exception - HW without SW;New LOD Licenses exception;Hardfloor Discount Exception - RCV';
        qt.RWD_Deal_Ops_Exception_Justification__c = 'test';
        qt.RecordTypeId=Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        qt.Metering__c = 'FETB';
        qt.CSAT_Reason__c = 'Missized';
        qt.Is_RSCG_Excp__c = true;//SF-72381
        qt.QuoteApprovalCategory__c = ReplacementConstants.PREPAY;
        lstQuote.add(qt);
        
        SBQQ__Quote__c quote2 = qt.clone();
        quote2.SBQQ__Primary__c = false;
        lstQuote.add(quote2);
                
        insert lstQuote;
        
        List<SBQQ__QuoteLineGroup__c> qlGroups = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c despGp = new SBQQ__QuoteLineGroup__c(Name = 'Expansion Quote',SBQQ__Quote__c = qt.Id );
        SBQQ__QuoteLineGroup__c renGp = new SBQQ__QuoteLineGroup__c(Name = 'Renewal Quote',SBQQ__Quote__c = qt.Id );
        qlGroups.add(despGp); 
        qlGroups.add(renGp); 
        insert qlGroups;

        Decimal num = 1;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        QuoteLineRecordResponse replQlr = new QuoteLineRecordResponse();
        replQlr.prodCode = 'RS-BT-EE-SC-PE-PP';
        replQlr.newQty = 1;
        String replacementDetailStr = CreditCalculationTest.createReplacementDetails(
                                        asset, ent, 
                                        replQlr, false, 
                                        ReplacementConstants.ONE_TO_ONE);
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = prod.Id, SBQQ__Quantity__c = 1,SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
            SBQQ__Group__c = renGp.Id,Approval_Category__c = 'Zone1');  
        qliList.add(qli1);

        SBQQ__QuoteLine__c hybLicenseqli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
                                                                  SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
                                                                  SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
                                                                  SBQQ__Discount__c = 100, SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli);

        SBQQ__QuoteLine__c hybLicenseqli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
                                                                  SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
                                                                  SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1',SBQQ__Quantity__c = 1,
                                                                  SBQQ__Discount__c = 99.99, CPQ_Prior_Discount__c = 10, SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id,Product_Level__c = 'Hybrid Software',  Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli2);

        SBQQ__QuoteLine__c hybLicenseqli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
                                                                  SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
                                                                  SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
                                                                  Promo_Disc__c = 100.000, SBQQSC__RenewedContractLine__c = ContractLineItemObj2.Id,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10);  
        qliList.add(hybLicenseqli3);

        SBQQ__QuoteLine__c hybLicenseqli4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
                                                                  SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
                                                                  SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
                                                                  Promo_Disc__c = 50, Total_Discount__c = 100, SBQQSC__RenewedContractLine__c = ContractLineItemObj3.Id,Product_Level__c = 'Hybrid Software',  Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli4);

        SBQQ__QuoteLine__c hybLicenseqli5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
                                                                  SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
                                                                  SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
                                                                  SBQQSC__RenewedContractLine__c = ContractLineItemObj4.Id,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli5);

        SBQQ__QuoteLine__c hybLicenseqli6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
                                                                  SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
                                                                  SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
                                                                  SBQQ__Discount__c = 100, CPQ_Prior_Discount__c = 100,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli6);

        SBQQ__QuoteLine__c addOnqli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id,SBQQ__Group__c = renGp.Id, SBQQ__Quantity__c = 1,
                                                              SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,Approval_Category__c = 'Zone1', Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', RWD_Expected_Default_Quantity__c = 10, Related_Asset_Total_Capacity__c = 12, Temp_Appliance_Count__c = 10);  
        qliList.add(addOnqli2);

        SBQQ__QuoteLine__c replacedSKU1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111',Replace_By__c = '',
                                                                 SubscribedAssetNames__c = 'BB192863040047, BB192863040048',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047, BB192863040048', Disposition_Reason__c = 'Replaced', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
                                                                 SBQQ__Discount__c = 100, Product_Level__c = 'Hybrid Software', Special_Program__c = 'Replaced' ,Temp_Node_Count__c = 12);  
        qliList.add(replacedSKU1);

        SBQQ__QuoteLine__c replacedSKU3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '121',Replace_By__c = 'RS-BT-NDA-PE-PP', SBQQ__Quantity__c = 1,
                                                                 Arroyo_Subscribed_Asset_Name__c = null, Disposition_Reason__c = 'Replaced', SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id,Approval_Category__c = 'Zone1', Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(replacedSKU3);

        SBQQ__QuoteLine__c replacedSKU2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '222', SBQQ__Quantity__c = 1,
                                                                 SubscribedAssetNames__c = 'BB192863040047',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047', Disposition_Reason__c = 'None', Special_Program__c = 'Replaced',Approval_Category__c = 'Zone1', Product_Level__c = 'Hybrid Software', Temp_Node_Count__c = 12, Replace_By__c = 'RS-BT-NDA-PE-PP');  
        qliList.add(replacedSKU2);

        SBQQ__QuoteLine__c replacedSKUNew = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222', SBQQ__Quantity__c = 1,
                                                                   SubscribedAssetNames__c = 'BB192863040048',Arroyo_Subscribed_Asset_Name__c = 'BB192863040048', Disposition_Reason__c = 'None', Special_Program__c = 'Replaced',Approval_Category__c = 'Zone1', Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', Related_Asset_Total_Capacity__c = 12, RWD_Expected_Default_Quantity__c = 10,  Temp_Appliance_Count__c = 10, Replace_By__c = 'RS-BT-NDA-PE-PP');  
        qliList.add(replacedSKUNew);

        SBQQ__QuoteLine__c replacedSKUNew1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222', SBQQ__Quantity__c = 1,
                                                                    Disposition_Reason__c = 'None', Special_Program__c = 'Refresh',Approval_Category__c = 'Zone1', SubscribedAssetNames__c = 'BB192863040047', Arroyo_Subscribed_Asset_Name__c = 'BB192863040047',Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', RWD_Expected_Default_Quantity__c = 10, Related_Asset_Total_Capacity__c = 12, Temp_Node_Count__c = 12, Temp_Appliance_Count__c = 10, Replacement_Motion__c = 'Upgrade');  
        qliList.add(replacedSKUNew1);

        SBQQ__QuoteLine__c convertedSKUNew1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222',SBQQ__Quantity__c = 1,
                                                                     Disposition_Reason__c = 'None', Special_Program__c = 'Conversion',SubscribedAssetNames__c = 'BB192863040047',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047',Approval_Category__c = 'Zone1',Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On',  Product_Type__c = 'RADAR',RWD_Expected_Default_Quantity__c = 1, Related_Asset_Total_Capacity__c = 12, Temp_Appliance_Count__c = 10, Replacement_Motion__c = 'Upgrade',
                                                                     Replacement_Details__c = replacementDetailStr
                                                                     );  
        qliList.add(convertedSKUNew1);

        SBQQ__QuoteLine__c SwapServiceql = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222', SBQQ__Quantity__c = 1,
                                                                     Disposition_Reason__c = 'None', Special_Program__c = 'Refresh',SubscribedAssetNames__c = 'BB192863040047',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047',Approval_Category__c = 'Zone1', Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', RWD_Expected_Default_Quantity__c = 10, Related_Asset_Total_Capacity__c = 1 ,Temp_Appliance_Count__c = 10
                                                                     );  
        SBQQ__QuoteLine__c scaleqli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = scaleProd.Id,SBQQ__Group__c = renGp.Id, SBQQ__Quantity__c = 1,
                                                             Arroyo_Subscribed_Asset_Name__c = 'BB192863040046',Approval_Category__c = 'Zone1', Product_Level__c = 'Hybrid Software', Usable_Capacity__c = 12.00, Total_Usable_Capacity__c = 12.00, Temp_Node_Count__c = 12, Temp_Appliance_Count__c = 10);  
        qliList.add(SwapServiceql);
        qliList.add(scaleqli);
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert qliList;
        List<SBQQ__QuoteLine__c> updateList = new List<SBQQ__QuoteLine__c>();
        convertedSKUNew1.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        replacedSKUNew1.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        replacedSKUNew.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        addOnqli2.SBQQ__RequiredBy__c = hybLicenseqli.Id;

        updateList.add(convertedSKUNew1);
        updateList.add(replacedSKUNew1);
        updateList.add(replacedSKUNew);
        updateList.add(addOnqli2);

        //create level 2 quotelines
        List<SBQQ__QuoteLine__c> qlLevel2 = new List<SBQQ__QuoteLine__c>();

        SBQQ__QuoteLine__c hwqli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hwprod.Id, SBQQ__Quantity__c = 1, SBQQ__Group__c = renGp.Id, SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,Approval_Category__c = 'Zone1', Product_Level__c = 'Hardware', Usable_Capacity__c = 12.00, SBQQ__Existing__c = true, Total_Usable_Capacity__c = 12.00, Product_Type__c = 'Hardware', Temp_Appliance_Count__c = 10);
        SBQQ__QuoteLine__c hwqli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hwprod.Id, SBQQ__Quantity__c = 1, SBQQ__Group__c = renGp.Id, SubscribedAssetNames__c = 'BB1928630400461',Arroyo_Subscribed_Asset_Name__c = null,Approval_Category__c = 'Zone1', Product_Level__c = 'Hardware', Usable_Capacity__c = 12.00, SBQQ__Existing__c = true, Total_Usable_Capacity__c = 12.00, Product_Type__c = 'Hardware', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);
        SBQQ__QuoteLine__c scaleProdChild = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = scaleProd2.Id, SBQQ__Quantity__c = 1, SBQQ__Group__c = renGp.Id, SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,Approval_Category__c = 'Zone1', Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10);
        SBQQ__QuoteLine__c suppQLI = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = supportProd.Id,SBQQ__Group__c = renGp.Id, SBQQ__Quantity__c = 1,
                                                             Arroyo_Subscribed_Asset_Name__c = 'BB192863040046',Approval_Category__c = 'Zone1', Product_Level__c = 'Support', Usable_Capacity__c = 12.00, Total_Usable_Capacity__c = 12.00, Temp_Node_Count__c = 12, Temp_Appliance_Count__c = 10); 
        SBQQ__QuoteLine__c supportProdNRDQLI = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = supportProdNRD.Id,SBQQ__Group__c = renGp.Id, SBQQ__Quantity__c = 1,
                                                             Arroyo_Subscribed_Asset_Name__c = 'BB192863040046',Approval_Category__c = 'Zone1', Product_Level__c = 'Support'); 
        
        qlLevel2.add(hwqli);
        qlLevel2.add(hwqli1);
        qlLevel2.add(scaleProdChild);
        qlLevel2.add(suppQLI);
        qlLevel2.add(supportProdNRDQLI);
        insert qlLevel2;

        
        hwqli.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        hwqli.SBQQ__Existing__c = true;
        hwqli1.SBQQ__RequiredBy__c = scaleqli.Id;
        scaleProdChild.SBQQ__RequiredBy__c = scaleqli.Id;
        suppQLI.SBQQ__RequiredBy__c = hwqli.Id;
        supportProdNRDQLI.SBQQ__RequiredBy__c = hwqli1.Id;
        updateList.add(hwqli);
        updateList.add(hwqli1);
        updateList.add(scaleProdChild);
        updateList.add(suppQLI);
            updateList.add(supportProdNRDQLI);
        update updateList;

        //create level 3 quotelines
        List<SBQQ__QuoteLine__c> qlLevel3 = new List<SBQQ__QuoteLine__c>();

        SBQQ__QuoteLine__c addOnqli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod.Id,SBQQ__Group__c = renGp.Id, SBQQ__RequiredBy__c = hwqli.Id,SBQQ__Quantity__c = 1, 
                                                             Arroyo_Subscribed_Asset_Name__c = null,SubscribedAssetNames__c = 'BB192863040046',Approval_Category__c = 'Zone1');  
        qlLevel3.add(addOnqli);
        insert qlLevel3;
        
        QuoteTriggerHandler.isRecursiveLinkOppEnt = false;
        
        //query quotelines
        List<SBQQ__QuoteLine__c> qlQueried = [SELECT SBQQ__ProductCode__c, SBQQ__Quantity__c, Product_Level__c, Product_Type__c, SBQQ__RequiredBy__c, 
        Related_Asset_Total_Capacity__c, Add_on_Level__c, SBQQ__ProductFamily__c, Product_Subtype__c, RWD_Expected_Default_Quantity__c, 
        RWD_Polaris_SKUs_Quantity_Changed__c, Temp_Appliance_Count__c, Temp_Node_Count__c, SBQQ__ProductName__c, Usable_Capacity__c, SBQQ__Existing__c, 
        SBQQ__Number__c, SBQQ__Product__c, Quote_Line_Type__c, Total_Usable_Capacity__c, Old_Total_Usable_Capacity__c, No_of_TBs_Cloud__c, 
        SBQQ__ProductOption__r.No_of_TBs_Environment__c, TPH_Drive_Size__c, TPH_Quantity__c, SBQQ__SegmentLabel__c, SBQQ__Quote__r.RWD_Total_Capacity__c, SBQQ__Quote__r.RWD_TB_Per_Appliance_Ratio__c, 
        Id, Special_Program__c, SBQQ__Optional__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Support_Tier__c, 
        SBQQ__RequiredBy__r.SBQQ__Product__r.HW_Support_Tier__c, SBQQ__Product__r.Support_Tier__c, SBQQ__Product__r.HW_Support_Tier__c, Replacement_Details__c, 
        SBQQ__ListTotal__c, SBQQ__Quote__r.Credit_Calculation_Start_Date__c, Replacement_Motion__c, SBQQSC__RenewedContractLine__c, (SELECT SBQQ__Number__c FROM SBQQ__Quote_Lines__r) FROM SBQQ__QuoteLine__c];

        //create QuoteLineRecordResponse
        List<QuoteLineRecordResponse> qliRespLst = new List<QuoteLineRecordResponse>();
        List<QuoteLineRecordResponse> qliRespLst1 = new List<QuoteLineRecordResponse>();

        List<Map<String, Object>> parentChildMapList = new List<Map<String, Object>>();

        for (SBQQ__QuoteLine__c ql : qlQueried){
            QuoteLineRecordResponse qlRecord = new QuoteLineRecordResponse ();
            qlRecord.prodCode = ql.SBQQ__ProductCode__c;
            qlRecord.newQty = ql.SBQQ__Quantity__c;
            qlRecord.pLvl = ql.Product_Level__c;
            qlRecord.ptyp = ql.Product_Type__c;
            qlRecord.rqBy = ql.SBQQ__RequiredBy__c;
            qlRecord.asCap = ql.Related_Asset_Total_Capacity__c;
            qlRecord.aoLvl = ql.Add_on_Level__c;
            qlRecord.pFam = ql.SBQQ__ProductFamily__c;
            qlRecord.pSt = ql.Product_Subtype__c;
            qlRecord.eQty = ql.RWD_Expected_Default_Quantity__c;
            qlRecord.qtyC = ql.RWD_Polaris_SKUs_Quantity_Changed__c;
            qlRecord.apCt = ql.Temp_Appliance_Count__c;
            qlRecord.nCt = ql.Temp_Node_Count__c;
            qlRecord.pNam = ql.SBQQ__ProductName__c;
            qlRecord.uCap = ql.Usable_Capacity__c;
            qlRecord.ext = ql.SBQQ__Existing__c;
            qlRecord.nbr = ql.SBQQ__Number__c;
            qlRecord.prd = ql.SBQQ__Product__c;
            qlRecord.lTyp = ql.Quote_Line_Type__c;
            qlRecord.tCap = ql.Total_Usable_Capacity__c;
            qlRecord.oTCap = ql.Old_Total_Usable_Capacity__c;
            qlRecord.tbCld = ql.No_of_TBs_Cloud__c;
            qlRecord.tbEnv = ql.SBQQ__ProductOption__r.No_of_TBs_Environment__c;
            qlRecord.dSize = ql.TPH_Drive_Size__c;
            qlRecord.tQty = ql.TPH_Quantity__c;
            qlRecord.sLbl = ql.SBQQ__SegmentLabel__c;
            qlRecord.totCap = ql.SBQQ__Quote__r.RWD_Total_Capacity__c;
            qlRecord.tbAp = ql.SBQQ__Quote__r.RWD_TB_Per_Appliance_Ratio__c;
            qlRecord.rcId = ql.Id;
            qlRecord.sP = ql.Special_Program__c;
            qlRecord.optional = ql.SBQQ__Optional__c;
            if (ql.SBQQ__RequiredBy__c != null) {
                qlRecord.reqSupTier = ql.SBQQ__RequiredBy__r.SBQQ__Product__r.Support_Tier__c;
                qlRecord.reqHWSupTier = ql.SBQQ__RequiredBy__r.SBQQ__Product__r.HW_Support_Tier__c;
            }
            qlRecord.supTier = ql.SBQQ__Product__r.Support_Tier__c;
            qlRecord.hWSupTier = ql.SBQQ__Product__r.HW_Support_Tier__c;
            qlRecord.replacementDetails = ql.Replacement_Details__c;
            qlRecord.listTotal = ql.SBQQ__ListTotal__c;
            qlRecord.creditSD = ql.SBQQ__Quote__r.Credit_Calculation_Start_Date__c;
            qlRecord.replacementMotion = ql.Replacement_Motion__c;
            qliRespLst.add(qlRecord);
            if (ql.SBQQ__Quote_Lines__r.size() > 0){
                Map<String, Object> parentChildMap = new Map<String, Object>();
                parentChildMap.put('parent', ql.SBQQ__Number__c);
                
                List<Decimal> childNums = new List<Decimal>();
                for (SBQQ__QuoteLine__c childQL : ql.SBQQ__Quote_Lines__r){
                    childNums.add(childQL.SBQQ__Number__c);
                }
                parentChildMap.put('children', childNums);

                parentChildMapList.add(parentChildMap);
            }
        }

        String newLines1 = JSON.serialize(parentChildMapList);
        
        String lineIds = JSON.serialize(qliRespLst);
        
        String lineIds1 = JSON.serialize(qliRespLst1);
        List<ContractLineItem> cliUpdate = new List<ContractLineItem>();
        
        ContractLineItemObj.SBQQSC__QuoteLine__c=hybLicenseqli2.id;
        ContractLineItemObj1.SBQQSC__QuoteLine__c=hybLicenseqli.id;
        ContractLineItemObj2.SBQQSC__QuoteLine__c=hybLicenseqli4.Id;
        ContractLineItemObj3.SBQQSC__QuoteLine__c=hybLicenseqli3.Id;
        ContractLineItemObj4.SBQQSC__QuoteLine__c=hybLicenseqli6.Id;

        cliUpdate.add(ContractLineItemObj);
        cliUpdate.add(ContractLineItemObj1);
        cliUpdate.add(ContractLineItemObj2);
        cliUpdate.add(ContractLineItemObj3);
        cliUpdate.add(ContractLineItemObj4);

        update cliUpdate;
            
        test.startTest();
        String accId = act.Id;
        String qId = qt.Id;
        String quoteAppCategory = 'Test';
        DataDumping.CustomMap cMapNew = DataDumping.DataDumpingPost(accId, qId, true, false, 100, false, true, 1, newLines1, 'Quote', false, lineIds,quoteAppCategory, 'Yes', 'Save');
        DataDumping.AddDataMigration(quote2.Id, false, 1, false);
        DataDumping.AddDataMigration(qt.Id, false, 1, true);

        }
    }
    /***********************************************************************************************************
    * Method Name          : testDataDumpingMethod3
    * @description         : test Method 2
    /**********************************************************************************************************/
    @isTest 
    static void testDataDumpingMethod3(){  
        String uniqueUserName = 'AdminUser' + DateTime.now().getTime() + '@rubrik.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(
            Alias = 'adminU', Email='AdminUser@rubrik.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles',
            UserName=uniqueUserName,
            RBAC_Group__c = 'System - IT',
            RBAC_Department__c = 'Service Account'
        );
        insert u;
        System.runAs(u) {

        ShGl_DisableBusinessLogic__c settingDisable2 = new ShGl_DisableBusinessLogic__c();
        settingDisable2.Name = 'System Administrator';
        settingDisable2.Disable_ServiceContract_Trigger__c = true;
        settingDisable2.Disable_Account_Triggers__c = true;
        settingDisable2.Disable_Entitlement_Validation_Rules__c = true;
        settingDisable2.Disable_Opportunity_Triggers__c=true;
        settingDisable2.Disable_SBQQ_Quote_Triggers__c = true;
        settingDisable2.Disable_SBQQ_QuoteLine_Triggers__c = true;
        settingDisable2.SetupOwnerId = u.Id;
        insert settingDisable2;
        
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;

        SBQQ.TriggerControl.disable();
        
        TriggerControl__c TC = new TriggerControl__c();
        TC.Name = 'Entitlement';
        TC.DisableTrigger__c = true;
        TC.DisableTrigger__c = true;
        TC.Last_Batch_Run_Date__c = Date.newInstance(2021,04,30);
        TC.SendEmail__c = false;
        insert TC;
        
        Tier_Quantity_Range_lookup_Table__c tb = new Tier_Quantity_Range_lookup_Table__c();
        tb.Quantity_Lower_Bound__c = 1;
        tb.Quantity_Upper_Bound__c = 1000;
        tb.Location__c = 'US';
        tb.Discount_RSM__c = 30;
        tb.Approval_Category__c = 'Zone1';
        insert tb;
        
        List<Product_Constrain_Config__c> pccList = new List<Product_Constrain_Config__c>();
        Product_Constrain_Config__c pccInstance = new Product_Constrain_Config__c();
        pccInstance.Name = 'R6412 Cons';
        pccInstance.Dependent_Product__c = 'RBK-R6412S-CONS-DR';
        pccInstance.Constraining_Product__c = 'RBK-R6412S-CONS';
        pccInstance.Is_Active__c = TRUE;
        pccInstance.Dependent_Product_Quantity__c = null;
        pccInstance.Could_be_Repurchased__c = True;
        pccInstance.Self_Constrain_Only__c = false;
        pccInstance.Cross_Product_Constrain_Only__c = false;
        pccList.add(pccInstance);
        insert pccList;
        DataDumping.CustomMap cMap = new DataDumping.CustomMap();
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();

        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        
        Assert.areEqual(2, accountList.size());

        cMap.Acc = act;
        cMap.PCC = pccList;
        String myJSON = JSON.serialize(cMap);
        
        RestRequest request = new RestRequest();
        request.requestUri ='https://cs79.salesforce.com/services/apexrest/DataDumping';
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueof(myJSON);
        RestContext.request = request;
        
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = act.Id;
        opp.CloseDate = Date.newInstance(2021,04,30);
        opp.Partner_Lookup__c = vAccount2.id;
        opp.Distributor_Lookup__c = vAccount.id;
        opp.Deal_Structuring_Oppty_Notes__c = 'Test';
        insert opp;


        Product2 trnSKU = new Product2(Name='PS-WRAPPER', IsActive=true, ProductCode = 'PS-WRAPPER', Quotable_Date__c = Date.newInstance(2004, 11, 11) ); 
        insert trnSKU; 
        Product2 trnSKU2 = new Product2(Name='RBK-SVC-TRN-VIRTUAL', IsActive=true, ProductCode = 'RBK-SVC-TRN-VIRTUAL', Quotable_Date__c = Date.newInstance(2004, 11, 11) ); 
        insert trnSKU2; 
        
        Product2 prod = new Product2(Name='PS-WRAPPER',ProductCode = 'PS-WRAPPER' ,IsActive=true, Quotable_Date__c = Date.newInstance(2004, 11, 11),
               IsHardwareNotRequiredForHybridLicense__c = false,SBQQSC__EntitlementConversion__c='One per unit', Product_Payment_Option__c=ReplacementConstants.PAYMENT_OPTION_ANNUAL
            );       
        Product2 hybLicenseprod = new Product2(Name='RS-BT-EE-PE-PP',ProductCode = 'RS-BT-EE-PE-PP', IsActive=true, Product_Level__c = 'Hybrid Software', 
                                               Product_Type__c='Enterprise Edition',Product_Subtype__c='Saas Cloud', X0__c=true,
                                               Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = false,Approval_Category__c = 'Zone1');       
        Product2 hwprod = new Product2(Name='RH-6304S-01',ProductCode = 'RH-6304S-01', IsActive=true, Product_Level__c = 'Hardware', Product_Type__c='Hardware', 
                                       Usable_Capacity__c = 12.00,Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, X0__c = true,SBQQSC__EntitlementConversion__c='One per quote line');  
        Product2 supportProd = new Product2(Name='RS-HW-SVC-PE-S2',ProductCode = 'RS-HW-SVC-PE-S2', IsActive=true, Product_Level__c = 'Support', Product_Type__c='HW Support', 
                                            Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, X0__c = true);            
        Product2 addOnprod2 = new Product2(Name='RS-BT-NDA-PE-PP',ProductCode ='RS-BT-NDA-PE-PP' , IsActive=true,  Product_Level__c = 'SaaS Software Addon', 
                                           Product_Type__c='NAS', Quotable_Date__c = Date.newInstance(2004, 11, 11), IsHardwareNotRequiredForHybridLicense__c = true, 
                                           X0__c = true,Family = 'POLARIS', Add_on_Level__c = 'RCDM Add-On',Product_Payment_Option__c=ReplacementConstants.PAYMENT_OPTION_ANNUAL);
        List<Product2> prodList = new List<Product2>();
        prodList.add(hybLicenseprod);
        prodList.add(hwprod);
        prodList.add(supportProd);
        prodList.add(prod);
        prodList.add(addOnprod2);
        insert prodList;
        
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        PricebookEntry pricebookObj = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pricebookObj.Product2Id = prod.Id;
        pricebookObj.UnitPrice = 100;
        pricebookObj.Pricebook2Id = Test.getStandardPricebookId();
        pricebookObj.IsActive = true;
        pbeList.add(pricebookObj);
        PricebookEntry hybLicenseprodpbe = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        hybLicenseprodpbe.Product2Id = hybLicenseprod.Id;
        hybLicenseprodpbe.UnitPrice = 100;
        hybLicenseprodpbe.Pricebook2Id = Test.getStandardPricebookId();
        hybLicenseprodpbe.IsActive = true;
        pbeList.add(hybLicenseprodpbe);
        PricebookEntry hwprodpbe = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        hwprodpbe.Product2Id = hwprod.Id;
        hwprodpbe.UnitPrice = 100;
        hwprodpbe.Pricebook2Id = Test.getStandardPricebookId();
        hwprodpbe.IsActive = true;
        pbeList.add(hwprodpbe);
        PricebookEntry addOnprodpbe2 = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        addOnprodpbe2.Product2Id = addOnprod2.Id;
        addOnprodpbe2.UnitPrice = 100;
        addOnprodpbe2.Pricebook2Id = Test.getStandardPricebookId();
        addOnprodpbe2.IsActive = true;
        pbeList.add(addOnprodpbe2);
        PricebookEntry standardPrice1 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 10000, Product2Id = trnSKU.Id, IsActive = true);
        insert standardPrice1;
        PricebookEntry standardPrice2 = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 10000, Product2Id = trnSKU2.Id, IsActive = true);
        insert standardPrice2;
        
        insert pbeList;
        ShGl_DisableBusinessLogic__c isDisabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled.Disable_Contract_Line_Item_Triggers__c = true;
        isDisabled.Disable_ServiceContract_Trigger__c = true;
        List<ServiceContract> contractList = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
        serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
        //serviceContractObj.SBQQSC__Quote__c = quoteRec1.Id;
        //serviceContractObj.SBQQSC__RenewalOpportunity__c = lstOpportunity[1].Id;
        serviceContractObj.AccountId = act.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.EndDate = System.today().addDays(365);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        contractList.add(serviceContractObj);
        insert contractList;
        
        Asset asset = new Asset();
        asset.Name = '123456';
        asset.Serial_Number__c = '123456';
        asset.SerialNumber = '123456';
        asset.AccountId = act.id;
        asset.Product2Id = prod.Id;
        insert asset;
        
        List<contractLineItem> cliList = new List<contractLineItem>(); 
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = act.Id;
        ContractLineItemObj.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate = System.today().addDays(120);
        cliList.add(ContractLineItemObj);
        
        ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = act.Id;
        ContractLineItemObj1.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.EndDate = System.today().addDays(120);
        cliList.add(ContractLineItemObj1);
            
        ContractLineItem ContractLineItemObj2 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj2.SBQQSC__Account__c = act.Id;
        ContractLineItemObj2.PricebookEntryId = pricebookObj.Id;
        ContractLineItemObj2.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj2.Quantity = 10;
        ContractLineItemObj2.UnitPrice = 100;
        ContractLineItemObj2.StartDate = System.today();
        ContractLineItemObj2.EndDate = System.today().addDays(120);
        ContractLineItemObj2.LinkedAssets__c= '123456';
        ContractLineItemObj2.SBQQSC__Discount__c = 50;
        cliList.add(ContractLineItemObj2);    

        ContractLineItem ContractLineItemObj3 = ContractLineItemObj.clone();
        cliList.add(ContractLineItemObj3);

        ContractLineItem ContractLineItemObj4 = ContractLineItemObj.clone();
        cliList.add(ContractLineItemObj4);
           
        insert cliList;
        //FY26WL-499
        Account_Discount_History__c adh = new Account_Discount_History__c();
        adh.Account__c = act.Id;
        adh.Product__c = prod.Id;
        insert adh;
        //FY26WL-499  
        
        List<Entitlement> ent=new List<Entitlement>();
        Entitlement ent1 = new Entitlement(Name='Testing', 
                                          AccountId=act.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj.id,
                                          Product__c =prod.id,
                                          Quantity__c=1,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365),
                                         AssetId=asset.id);
        ent.add(ent1);
            Entitlement ent2 = new Entitlement(Name='Testing1', 
                                          AccountId=act.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj.id,
                                          Product__c =hwprod.id,
                                          Quantity__c=1,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365),
                                         AssetId=asset.id);
        ent.add(ent2);
             Entitlement ent3 = new Entitlement(Name='Testing1', 
                                          AccountId=act.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj2.id,
                                          Product__c =hwprod.id,
                                          Quantity__c=1,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365)
                                          );
        ent.add(ent3);
        insert ent;

        Scale_Entitlement__c Sent = new Scale_Entitlement__c(Type__c= 'Non-Scale',Contract_Line_Item__c=ContractLineItemObj.id,Entitlement__c=ent[0].id,Asset__c=asset.id);
        insert Sent;
        Scale_Entitlement__c Sent1 = new Scale_Entitlement__c(Type__c= 'Non-Scale',Contract_Line_Item__c=ContractLineItemObj.id,Entitlement__c=ent[0].id,Asset__c=asset.id);
        insert Sent1;        
        Scale_Entitlement__c Sent2 = new Scale_Entitlement__c(Type__c= 'Non-Scale',Contract_Line_Item__c=ContractLineItemObj.id,Entitlement__c=ent[0].id,Asset__c=asset.id);
        insert Sent2; 
        List<SBQQ__Quote__c>lstQuote = new List<SBQQ__Quote__c>();
        
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__SubscriptionTerm__c = 12;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Type__c = 'Renewal';
        qt.RWD_Deal_Ops_Exception__c = 'Quoting Exception - HW without SW;New LOD Licenses exception;Hardfloor Discount Exception - RCV';
        qt.RWD_Deal_Ops_Exception_Justification__c = 'test';
        qt.RecordTypeId=Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
        qt.Metering__c = 'FETB';
        qt.CSAT_Reason__c = 'Missized';
        qt.Is_RSCG_Excp__c = true;//SF-72381
        qt.QuoteApprovalCategory__c = ReplacementConstants.PREPAY;
        lstQuote.add(qt);
        
        SBQQ__Quote__c quote2 = qt.clone();
        quote2.SBQQ__Primary__c = false;
        lstQuote.add(quote2);
                
        insert lstQuote;
         List<SBQQ__QuoteLineGroup__c> qlGroups = new List<SBQQ__QuoteLineGroup__c>();
        SBQQ__QuoteLineGroup__c despGp = new SBQQ__QuoteLineGroup__c(Name = 'Expansion Quote',SBQQ__Quote__c = qt.Id );
        SBQQ__QuoteLineGroup__c renGp = new SBQQ__QuoteLineGroup__c(Name = 'Renewal Quote',SBQQ__Quote__c = qt.Id );
        qlGroups.add(despGp); 
        qlGroups.add(renGp); 
        insert qlGroups;

        Decimal num = 1;
        
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = prod.Id, SBQQ__Quantity__c = 1,SBQQSC__RenewedContractLine__c = ContractLineItemObj.id, SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
            SBQQ__Group__c = renGp.Id,Approval_Category__c = 'Zone1');  
        qliList.add(qli1);

        SBQQ__QuoteLine__c hybLicenseqli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
        SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
        SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
        SBQQ__Discount__c = 100, SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli);

        SBQQ__QuoteLine__c hybLicenseqli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
        SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
        SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1',SBQQ__Quantity__c = 1,
        SBQQ__Discount__c = 99.99, CPQ_Prior_Discount__c = 10, SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id,Product_Level__c = 'Hybrid Software',  Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli2);

        SBQQ__QuoteLine__c hybLicenseqli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
        SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
        SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
        Promo_Disc__c = 100.000, SBQQSC__RenewedContractLine__c = ContractLineItemObj2.Id,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10);  
        qliList.add(hybLicenseqli3);

        SBQQ__QuoteLine__c hybLicenseqli4 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
        SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
        SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
        Promo_Disc__c = 50, Total_Discount__c = 100, SBQQSC__RenewedContractLine__c = ContractLineItemObj3.Id,Product_Level__c = 'Hybrid Software',  Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli4);

        SBQQ__QuoteLine__c hybLicenseqli5 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
        SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
        SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
        SBQQSC__RenewedContractLine__c = ContractLineItemObj4.Id,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli5);

        SBQQ__QuoteLine__c hybLicenseqli6 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id,SBQQ__Group__c = renGp.Id,
        SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,
        SBQQ__SubscriptionTerm__c = 1.00, SBQQ__DefaultSubscriptionTerm__c = 1.00,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
        SBQQ__Discount__c = 100, CPQ_Prior_Discount__c = 100,Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(hybLicenseqli6);

        SBQQ__QuoteLine__c addOnqli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id,SBQQ__Group__c = renGp.Id, SBQQ__Quantity__c = 1,
        SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,Approval_Category__c = 'Zone1', Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', RWD_Expected_Default_Quantity__c = 10, Related_Asset_Total_Capacity__c = 12, Temp_Appliance_Count__c = 10);  
        qliList.add(addOnqli2);

        SBQQ__QuoteLine__c replacedSKU1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111',Replace_By__c = '',
        SubscribedAssetNames__c = 'BB192863040047, BB192863040048',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047, BB192863040048', Disposition_Reason__c = 'Replaced', SBQQSC__RenewedContractLine__c = ContractLineItemObj.Id,Approval_Category__c = 'Zone1', SBQQ__Quantity__c = 1,
        SBQQ__Discount__c = 100, Product_Level__c = 'Hybrid Software', Special_Program__c = 'Replaced' ,Temp_Node_Count__c = 12);  
        qliList.add(replacedSKU1);

        SBQQ__QuoteLine__c replacedSKU3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '121',Replace_By__c = 'RS-BT-NDA-PE-PP', SBQQ__Quantity__c = 1,
        Arroyo_Subscribed_Asset_Name__c = null, Disposition_Reason__c = 'Replaced', SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id,Approval_Category__c = 'Zone1', Product_Level__c = 'Hybrid Software', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);  
        qliList.add(replacedSKU3);

        SBQQ__QuoteLine__c replacedSKU2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hybLicenseprod.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '222', SBQQ__Quantity__c = 1,
        SubscribedAssetNames__c = 'BB192863040047',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047', Disposition_Reason__c = 'None', Special_Program__c = 'Replaced',Approval_Category__c = 'Zone1', Product_Level__c = 'Hybrid Software', Temp_Node_Count__c = 12, Replace_By__c = 'RS-BT-NDA-PE-PP');  
        qliList.add(replacedSKU2);

        SBQQ__QuoteLine__c replacedSKUNew = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222', SBQQ__Quantity__c = 1,
        SubscribedAssetNames__c = 'BB192863040048',Arroyo_Subscribed_Asset_Name__c = 'BB192863040048', Disposition_Reason__c = 'None', Special_Program__c = 'Replaced',Approval_Category__c = 'Zone1', Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', Related_Asset_Total_Capacity__c = 12, RWD_Expected_Default_Quantity__c = 10,  Temp_Appliance_Count__c = 10, Replace_By__c = 'RS-BT-NDA-PE-PP');  
        qliList.add(replacedSKUNew);

        SBQQ__QuoteLine__c replacedSKUNew1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222', SBQQ__Quantity__c = 1,
        Disposition_Reason__c = 'None', Special_Program__c = 'Refresh',Approval_Category__c = 'Zone1', SubscribedAssetNames__c = 'BB192863040047', Arroyo_Subscribed_Asset_Name__c = 'BB192863040047',Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', RWD_Expected_Default_Quantity__c = 10, Related_Asset_Total_Capacity__c = 12, Temp_Node_Count__c = 12, Temp_Appliance_Count__c = 10, Replacement_Motion__c = 'Upgrade');  
        qliList.add(replacedSKUNew1);

        SBQQ__QuoteLine__c convertedSKUNew1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222',SBQQ__Quantity__c = 1,
        Disposition_Reason__c = 'None', Special_Program__c = 'Conversion',SubscribedAssetNames__c = 'BB192863040047',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047',Approval_Category__c = 'Zone1',Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On',  Product_Type__c = 'RADAR',RWD_Expected_Default_Quantity__c = 1, Related_Asset_Total_Capacity__c = 12, Temp_Appliance_Count__c = 10, Replacement_Motion__c = 'Upgrade');  
        qliList.add(convertedSKUNew1);

        SBQQ__QuoteLine__c SwapServiceql = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = addOnprod2.Id, Arroyo_Subsumed_Old_Contract_Line_Items__c = '111,222', SBQQ__Quantity__c = 1,
        Disposition_Reason__c = 'None', Special_Program__c = 'Refresh',SubscribedAssetNames__c = 'BB192863040047',Arroyo_Subscribed_Asset_Name__c = 'BB192863040047',Approval_Category__c = 'Zone1', Product_Level__c = 'SaaS Software Addon', Add_on_Level__c = 'RCDM Add-On', Product_Type__c = 'RADAR', RWD_Expected_Default_Quantity__c = 10, Related_Asset_Total_Capacity__c = 1 ,Temp_Appliance_Count__c = 10
        );    
        qliList.add(SwapServiceql);
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        insert qliList;
        List<SBQQ__QuoteLine__c> updateList = new List<SBQQ__QuoteLine__c>();
        convertedSKUNew1.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        replacedSKUNew1.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        replacedSKUNew.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        addOnqli2.SBQQ__RequiredBy__c = hybLicenseqli.Id;

        updateList.add(convertedSKUNew1);
        updateList.add(replacedSKUNew1);
        updateList.add(replacedSKUNew);
        updateList.add(addOnqli2);

        //create level 2 quotelines
        List<SBQQ__QuoteLine__c> qlLevel2 = new List<SBQQ__QuoteLine__c>();

        SBQQ__QuoteLine__c hwqli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hwprod.Id, SBQQ__Quantity__c = 1, SBQQ__Group__c = renGp.Id, SubscribedAssetNames__c = 'BB192863040046',Arroyo_Subscribed_Asset_Name__c = null,Approval_Category__c = 'Zone1', Product_Level__c = 'Hardware', Usable_Capacity__c = 12.00, SBQQ__Existing__c = true, Total_Usable_Capacity__c = 12.00, Product_Type__c = 'Hardware', Temp_Appliance_Count__c = 10);
        
        SBQQ__QuoteLine__c hwqli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Number__c = num++,  SBQQ__Product__c = hwprod.Id, SBQQ__Quantity__c = 1, SBQQ__Group__c = renGp.Id, SubscribedAssetNames__c = 'BB1928630400461',Arroyo_Subscribed_Asset_Name__c = null,Approval_Category__c = 'Zone1', Product_Level__c = 'Hardware', Usable_Capacity__c = 12.00, SBQQ__Existing__c = true, Total_Usable_Capacity__c = 12.00, Product_Type__c = 'Hardware', Temp_Appliance_Count__c = 10, Temp_Node_Count__c = 12);

        qlLevel2.add(hwqli);
        qlLevel2.add(hwqli1);
        insert qlLevel2;

        hwqli.SBQQ__RequiredBy__c = hybLicenseqli.Id;
        hwqli.SBQQ__Existing__c = true;
        updateList.add(hwqli);
        updateList.add(hwqli1);
        update updateList;
        
        QuoteTriggerHandler.isRecursiveLinkOppEnt = false;
        
        //query quotelines
        List<SBQQ__QuoteLine__c> qlQueried = [SELECT SBQQ__ProductCode__c, SBQQ__Quantity__c, Product_Level__c, Product_Type__c, SBQQ__RequiredBy__c, 
        Related_Asset_Total_Capacity__c, Add_on_Level__c, SBQQ__ProductFamily__c, Product_Subtype__c, RWD_Expected_Default_Quantity__c, 
        RWD_Polaris_SKUs_Quantity_Changed__c, Temp_Appliance_Count__c, Temp_Node_Count__c, SBQQ__ProductName__c, Usable_Capacity__c, SBQQ__Existing__c, 
        SBQQ__Number__c, SBQQ__Product__c, Quote_Line_Type__c, Total_Usable_Capacity__c, Old_Total_Usable_Capacity__c, No_of_TBs_Cloud__c, 
        SBQQ__ProductOption__r.No_of_TBs_Environment__c, TPH_Drive_Size__c, TPH_Quantity__c, SBQQ__SegmentLabel__c, SBQQ__Quote__r.RWD_Total_Capacity__c, SBQQ__Quote__r.RWD_TB_Per_Appliance_Ratio__c, 
        Id, Special_Program__c, SBQQ__Optional__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Support_Tier__c, 
        SBQQ__RequiredBy__r.SBQQ__Product__r.HW_Support_Tier__c, SBQQ__Product__r.Support_Tier__c, SBQQ__Product__r.HW_Support_Tier__c, Replacement_Details__c, 
        SBQQ__ListTotal__c, SBQQ__Quote__r.Credit_Calculation_Start_Date__c, Replacement_Motion__c, SBQQSC__RenewedContractLine__c, SBQQ__StartDate__c, Arroyo_Subscribed_Asset_Name__c, (SELECT SBQQ__Number__c FROM SBQQ__Quote_Lines__r) FROM SBQQ__QuoteLine__c];

        //create QuoteLineRecordResponse
        List<QuoteLineRecordResponse> qliRespLst = new List<QuoteLineRecordResponse>();
        List<QuoteLineRecordResponse> qliRespLst1 = new List<QuoteLineRecordResponse>();

        List<Map<String, Object>> parentChildMapList = new List<Map<String, Object>>();

        for (SBQQ__QuoteLine__c ql : qlQueried){
            QuoteLineRecordResponse qlRecord = new QuoteLineRecordResponse ();
            qlRecord.prodCode = ql.SBQQ__ProductCode__c;
            qlRecord.newQty = ql.SBQQ__Quantity__c;
            qlRecord.pLvl = ql.Product_Level__c;
            qlRecord.ptyp = ql.Product_Type__c;
            qlRecord.rqBy = ql.SBQQ__RequiredBy__c;
            qlRecord.asCap = ql.Related_Asset_Total_Capacity__c;
            qlRecord.aoLvl = ql.Add_on_Level__c;
            qlRecord.pFam = ql.SBQQ__ProductFamily__c;
            qlRecord.pSt = ql.Product_Subtype__c;
            qlRecord.eQty = ql.RWD_Expected_Default_Quantity__c;
            qlRecord.qtyC = ql.RWD_Polaris_SKUs_Quantity_Changed__c;
            qlRecord.apCt = ql.Temp_Appliance_Count__c;
            qlRecord.nCt = ql.Temp_Node_Count__c;
            qlRecord.pNam = ql.SBQQ__ProductName__c;
            qlRecord.uCap = ql.Usable_Capacity__c;
            qlRecord.ext = ql.SBQQ__Existing__c;
            qlRecord.nbr = ql.SBQQ__Number__c;
            qlRecord.prd = ql.SBQQ__Product__c;
            qlRecord.lTyp = ql.Quote_Line_Type__c;
            qlRecord.tCap = ql.Total_Usable_Capacity__c;
            qlRecord.oTCap = ql.Old_Total_Usable_Capacity__c;
            qlRecord.tbCld = ql.No_of_TBs_Cloud__c;
            qlRecord.tbEnv = ql.SBQQ__ProductOption__r.No_of_TBs_Environment__c;
            qlRecord.dSize = ql.TPH_Drive_Size__c;
            qlRecord.tQty = ql.TPH_Quantity__c;
            qlRecord.sLbl = ql.SBQQ__SegmentLabel__c;
            qlRecord.totCap = ql.SBQQ__Quote__r.RWD_Total_Capacity__c;
            qlRecord.tbAp = ql.SBQQ__Quote__r.RWD_TB_Per_Appliance_Ratio__c;
            qlRecord.rcId = ql.Id;
            qlRecord.sP = ql.Special_Program__c;
            qlRecord.optional = ql.SBQQ__Optional__c;
            if (ql.SBQQ__RequiredBy__c != null) {
                qlRecord.reqSupTier = ql.SBQQ__RequiredBy__r.SBQQ__Product__r.Support_Tier__c;
                qlRecord.reqHWSupTier = ql.SBQQ__RequiredBy__r.SBQQ__Product__r.HW_Support_Tier__c;
            }
            qlRecord.supTier = ql.SBQQ__Product__r.Support_Tier__c;
            qlRecord.hWSupTier = ql.SBQQ__Product__r.HW_Support_Tier__c;
            qlRecord.replacementDetails = ql.Replacement_Details__c;
            qlRecord.listTotal = ql.SBQQ__ListTotal__c;
            qlRecord.creditSD = ql.SBQQ__Quote__r.Credit_Calculation_Start_Date__c;
            qlRecord.replacementMotion = ql.Replacement_Motion__c;
            qlRecord.startDate = ql.SBQQ__StartDate__c;
            qlRecord.convSubsAst = ql.Arroyo_Subscribed_Asset_Name__c;
            qliRespLst.add(qlRecord);
            if (ql.SBQQ__Quote_Lines__r.size() > 0){
                Map<String, Object> parentChildMap = new Map<String, Object>();
                parentChildMap.put('parent', ql.SBQQ__Number__c);
                
                List<Decimal> childNums = new List<Decimal>();
                for (SBQQ__QuoteLine__c childQL : ql.SBQQ__Quote_Lines__r){
                    childNums.add(childQL.SBQQ__Number__c);
                }
                parentChildMap.put('children', childNums);

                parentChildMapList.add(parentChildMap);
            }
        }

        String newLines1 = JSON.serialize(parentChildMapList);
        
        String lineIds = JSON.serialize(qliRespLst);
        
        String lineIds1 = JSON.serialize(qliRespLst1);
        List<ContractLineItem> cliUpdate = new List<ContractLineItem>();
        
        ContractLineItemObj.SBQQSC__QuoteLine__c=hybLicenseqli2.id;
        ContractLineItemObj1.SBQQSC__QuoteLine__c=hybLicenseqli.id;
        ContractLineItemObj2.SBQQSC__QuoteLine__c=hybLicenseqli4.Id;
        ContractLineItemObj3.SBQQSC__QuoteLine__c=hybLicenseqli3.Id;
        ContractLineItemObj4.SBQQSC__QuoteLine__c=hybLicenseqli6.Id;

        cliUpdate.add(ContractLineItemObj);
        cliUpdate.add(ContractLineItemObj1);
        cliUpdate.add(ContractLineItemObj2);
        cliUpdate.add(ContractLineItemObj3);
        cliUpdate.add(ContractLineItemObj4);

        update cliUpdate;
            
        test.startTest();
        String accId = act.Id;
        String qId = qt.Id;
        String quoteAppCategory = 'Test';
        DataDumping.CustomMap cMapNew = DataDumping.DataDumpingPost(accId, qId, true, false, 100, false, true, 1, newLines1, 'Quote', false, lineIds,quoteAppCategory, 'Yes', 'Save');
        DataDumping.AddDataMigration(quote2.Id, false, 1, false);
        DataDumping.AddDataMigration(qt.Id, false, 1, true);

        }
    }
}