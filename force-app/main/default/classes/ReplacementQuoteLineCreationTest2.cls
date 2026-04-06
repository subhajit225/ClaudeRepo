/**
* @File Name : ReplacementQuoteLineCreationTest2.cls
* @description : test class for ReplacementQuoteLineCreation
* @Author :Khushboo
* @Jira: FY25SR-2247
* @Last Modified On : 26/09/2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | 26/09/2025 |   | Initial Version
**/
@isTest
public class ReplacementQuoteLineCreationTest2 {
    /***********************************************************************************************************
    * Method Name          : setup
    * Date Created/Modified: 26/09/2025
    * @description         : Creates Wrapper that is to be passed to the test method
    * Author               : Khushboo
    * Purpose              : Creates Wrapper that is to be passed to the test method
    * Test Class Methods   :
    **********************************************************************************************************/
    @testSetup static void setup() {
        List<ShGl_DisableBusinessLogic__c> disableBusinessLogic = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = UserInfo.getOrganizationId(), 
            Disable_SBQQ_Quote_Triggers__c = false
        );
        insert setting;

        ShGl_DisableBusinessLogic__c currentUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = UserInfo.getUserId(), 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true
        );
        disableBusinessLogic.add(currentUserDB);
        // INSERT new ShGl_DisableBusinessLogic__c();

        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        //Deactivate triggers
        ShGl_DisableBusinessLogic__c runAsUserDB = new ShGl_DisableBusinessLogic__c(
            setupownerid = usr1.Id, 
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,Disable_Flows__c=true
            );
        disableBusinessLogic.add(runAsUserDB);
        insert disableBusinessLogic;
        TriggerControl.stopOrderItemTrigger = true;
        TriggerControl.stopOrderTrigger = true;
        // TriggerControls.disableCalculateAPIBatch = true;
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true; 
        TriggerControl.stopEntitlementTrigger = true;
        //SBQQ.TriggerControl.disable();
        flowControll.opportunityTriggerHandler = false;
        flowControll.opportunityLineItemHandler = false;
        //Account
        String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        List<Account> accList= new List<Account>();
        Account acc = TestDataFactory.getAccount();
        acc.Eligible_for_RCDM_T__c=true;
        acc.RCDMT_EOL_Date__c=date.newinstance(2028, 2, 17);
        accList.add(acc);
        INSERT accList;

        //Contact 
        Contact con= TestDataFactory.getContact(acc);
        INSERT con;

        //Product data
        List<Product2> lstPrd = new List<Product2>();
        List<Id> lstPrdIds = new List<Id>();
        lstPrd.add(Replacement_TestDataFactory.getProductWithSubCategory('RS-BT-BE-SC-L3-PA', 'RS-BT-BE-SC-L3-PA'
           , ReplacementConstants.BUSINESS_EDITION,ReplacementConstants.ENTERPRISE_DATA_PROTECTION_SCALE
           , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.SAAS
           , ReplacementConstants.EDP_SCALE_COMMERCIAL));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-RS-HW-SVC-PE-S2', 'RBK-R6410-RS-HW-SV-PE-S2'
           , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
           , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
         lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-RS-HW-SVC-PE-S2', 'RBK-R6410-RS-HW-SV-PE-S2'
           , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
           , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RS-R6410-RS-HW-SVC-PE-S2', 'RS-R6410-RS-HW-SVCK-PE-S2'
           , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
           , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RS-R6410-RS-HW-SVC-L3-S2', 'RS-R6410-RS-HW-SVCK-L3-S2'
                                                          , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
                                                          , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        
        lstPrd[0].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[0].SBQQ__RenewalProduct__c = lstPrd[1].Id;
        lstPrd[0].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[1].Product_Level__c=null;
        lstPrd[1].SBQQ__RenewalProduct__c=lstPrd[0].Id;
        lstPrd[2].Product_Level__c=null;
        lstPrd[1].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_PRIMIUM;
        lstPrd[2].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_PRIMIUM;
        lstPrd[3].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_PRIMIUM;
        lstPrd[4].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        INSERT lstPrd;
        for (Product2 prod : lstPrd) {
            lstPrdIds.add(prod.id);
        }
        /*
        SBQQ__ProductFeature__c prodSupportFeature1 = new SBQQ__ProductFeature__c();
        prodSupportFeature1.Name = ReplacementConstants.SUPPORT;
        prodSupportFeature1.SBQQ__ConfiguredSKU__c =lstPrd[11].Id;
        prodSupportFeature1.SBQQ__Number__c = 3;
        prodSupportFeature1.SBQQ__Category__c = ReplacementConstants.SUPPORT;
        insert prodSupportFeature1;
        
        SBQQ__ProductFeature__c prodSupportFeature2 = new SBQQ__ProductFeature__c();
        prodSupportFeature2.Name = ReplacementConstants.SUPPORT;
        prodSupportFeature2.SBQQ__ConfiguredSKU__c =lstPrd[16].Id;
        prodSupportFeature2.SBQQ__Number__c = 3;
        prodSupportFeature2.SBQQ__Category__c = ReplacementConstants.SUPPORT;
        insert prodSupportFeature2;
        
        List<SBQQ__ProductOption__c> prodOptions=new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c prodSupportOpt1 = new SBQQ__ProductOption__c();
        prodSupportOpt1.Refresh_Default_Option__c = false;
        prodSupportOpt1.SBQQ__ConfiguredSKU__c = lstPrd[11].Id;
        prodSupportOpt1.SBQQ__OptionalSKU__c = lstPrd[12].Id;
        prodSupportOpt1.SBQQ__Type__c = ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT;
        prodSupportOpt1.SBQQ__Feature__c = prodSupportFeature1.Id;
        prodSupportOpt1.Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        prodSupportOpt1.SBQQ__Selected__c = true;
        prodSupportOpt1.SBQQ__Number__c = 1;
        prodSupportOpt1.Payment_Options__c = ReplacementConstants.PREPAY;
        prodOptions.add(prodSupportOpt1);
        
        //List<SBQQ__ProductOption__c> prodOptions1=new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c prodSupportOpt2 = new SBQQ__ProductOption__c();
        prodSupportOpt2.Refresh_Default_Option__c = false;
        prodSupportOpt2.SBQQ__ConfiguredSKU__c = lstPrd[11].Id;
        prodSupportOpt2.SBQQ__OptionalSKU__c = lstPrd[12].Id;
        prodSupportOpt2.SBQQ__Type__c = ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT;
        prodSupportOpt2.SBQQ__Feature__c = prodSupportFeature1.Id;
        prodSupportOpt2.Support_Type__c = ReplacementConstants.SUPPORT_TYPE_S2;
        prodSupportOpt2.SBQQ__Selected__c = true;
        prodSupportOpt2.SBQQ__Number__c = 1;
        prodSupportOpt2.Payment_Options__c = ReplacementConstants.PREPAY;
        prodOptions.add(prodSupportOpt2);
        
       // List<SBQQ__ProductOption__c> prodOptions=new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c prodSupportOpt4 = new SBQQ__ProductOption__c();
        prodSupportOpt4.Refresh_Default_Option__c = false;
        prodSupportOpt4.SBQQ__ConfiguredSKU__c = lstPrd[11].Id;
        prodSupportOpt4.SBQQ__OptionalSKU__c = lstPrd[12].Id;
        prodSupportOpt4.SBQQ__Type__c = ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT;
        prodSupportOpt4.SBQQ__Feature__c = prodSupportFeature1.Id;
        prodSupportOpt4.Support_Type__c = ReplacementConstants.SUPPORT_TYPE_S2;
        prodSupportOpt4.SBQQ__Selected__c = true;
        prodSupportOpt4.SBQQ__Number__c = 1;
        prodSupportOpt4.Payment_Options__c = ReplacementConstants.PREPAY;
        prodOptions.add(prodSupportOpt4);
        
        SBQQ__ProductOption__c prodSupportOpt3 = new SBQQ__ProductOption__c();
        prodSupportOpt3.Refresh_Default_Option__c = false;
        prodSupportOpt3.SBQQ__ConfiguredSKU__c = lstPrd[16].Id;
        prodSupportOpt3.SBQQ__OptionalSKU__c = lstPrd[12].Id;
        prodSupportOpt3.SBQQ__Type__c = ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT;
        prodSupportOpt3.SBQQ__Feature__c = prodSupportFeature2.Id;
        prodSupportOpt3.Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        prodSupportOpt3.SBQQ__Selected__c = true;
        prodSupportOpt3.SBQQ__Number__c = 2;
        prodSupportOpt3.Payment_Options__c = ReplacementConstants.PREPAY;
        prodOptions.add(prodSupportOpt3);
        
        insert prodOptions;
         */
      system.runAs(usr1){
        List<Id> lstPB = new List<Id>();
        //Standard PriceBook
        Id standardPriceBookId= Test.getStandardPricebookId();
        lstPB.add(standardPriceBookId);

        //Custom PriceBook
        PriceBook2 customPB = Replacement_TestDataFactory.getPriceBook(); 
        INSERT customPB;
        lstPB.add(customPB.Id);

        //Create PriceBook Entries for Standard and Custom PriceBook
        List<PricebookEntry> lstEntry = new List<PricebookEntry>();
        //Standard PriceBookEntry
        lstEntry = TestDataFactory.getPriceBookEntry (lstPrdIds, lstPB);
        INSERT lstEntry;

        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= TestDataFactory.getOpportunity(acc, con);
        Opportunity opp1= TestDataFactory.getOpportunity(acc, con);
        oppList.add(opp);
        //oppList.add(opp1);
        INSERT oppList;

        //Quote
        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = Replacement_TestDataFactory.getQuote(acc.Id, opp.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);      
        SBQQ__Quote__c quoteRec1 = Replacement_TestDataFactory.getQuote(acc.Id, opp1.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL);
        quoteRec1.SBQQ__Primary__c = false;
        quoteRec1.RCDMT_EOL_Date__c=date.newinstance(2028, 2, 17);
        quoteRec.SBQQ__Primary__c = false;
        quoteRec.RCDMT_EOL_Date__c=date.newinstance(2028, 2, 17);
        qbList.add(quoteRec);
        qbList.add(quoteRec1);
        INSERT qbList;
		
        quoteRec.SBQQ__Source__c = quoteRec1.Id;
        update quoteRec;
        
        CPQ_Disposition_Quote_Line__c cpq = new CPQ_Disposition_Quote_Line__c();
        cpq.Quote__c = quoteRec.Id;
        cpq.Disposition_Reason__c = 'Renew Later';
        cpq.Product__c = lstPrd[0].Id;
        cpq.Quantity__c = 20;
        insert cpq;
        

        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        INSERT ordr;

        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;

        //Polaris SKU Mapping
        List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingObjList = new List<Polaris_SKU_Mapping_V2__c>();
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj = 
            Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[2].Id, lstPrd[3].Id);
        polarisSKUMappingObjList.add(polarisSKUMappingObj);
        INSERT polarisSKUMappingObjList;

        List<OrderItem> oliList = new List<OrderItem>();
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(lstPrd[0].Id, ordr.Id, lstEntry[1].Id);
        OrderItem oli2= Replacement_TestDataFactory.getOrderItem(lstPrd[2].Id, ordr.Id, lstEntry[3].Id);
        oliList.add(oli1);
        oliList.add(oli2);
        INSERT oliList;

        ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opp.Id, customPB.Id);
        INSERT serviceContractObj;
		
        //Ceate Asset
        List<Asset> asstList = new List<Asset>();
        Asset asst= Replacement_TestDataFactory.getAsset('Asset123', lstPrd[0].Id, acc.Id);
        Asset asst1= Replacement_TestDataFactory.getAsset('Asset123', lstPrd[1].Id, acc.Id);
        asst.SerialNumber='Asset123';asst1.SerialNumber='Asset123';
        asstList.add(asst);
        asstList.add(asst1);
        INSERT asstList;
		        
        List<ContractLineItem> lstCLI = new List<ContractLineItem>();
        ContractLineItem ContractLineItemObj = 
        Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj.EndDate = Date.today().addDays(365);
        ContractLineItemObj.StartDate =  Date.today();
        ContractLineItemObj.SBQQSC__Product__c = lstPrdIds[0];
        ContractLineItemObj.CPQ_Uplift__c = '5';
        ContractLineItemObj.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj);
        ContractLineItem ContractLineItemObj1 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj1.EndDate = date.newinstance(2028, 2, 17);
        ContractLineItemObj1.StartDate =  date.newinstance(2027, 2, 17);
        ContractLineItemObj1.SBQQSC__Product__c = lstPrdIds[1];
        ContractLineItemObj1.CPQ_Uplift__c = '5';
        ContractLineItemObj1.SBQQSC__Quantity__c=20;
        lstCLI.add(ContractLineItemObj1);
        ContractLineItem ContractLineItemObj2 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj2.EndDate = Date.today().addDays(365);
        ContractLineItemObj2.StartDate =  Date.today();
        ContractLineItemObj2.SBQQSC__Product__c = lstPrdIds[2];
        ContractLineItemObj2.CPQ_Uplift__c = '5';
        ContractLineItemObj2.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj2);
         insert lstCLI;
		
        
        
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
         SBQQ__QuoteLine__c qli= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrd[1].Id, ContractLineItemObj1.Id); 
        qli.SubscribedAssetNames__c = asst.Id+','+asst1.Id;
        SBQQ__QuoteLine__c qli2= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrd[1].Id, ContractLineItemObj1.Id); 
        qli2.SubscribedAssetNames__c = asst.Id+','+asst1.Id;
        qli2.Disposition_Reason__c = 
            ReplacementConstants.DISPOSTION_RENEWING;
        SBQQ__QuoteLine__c qli3= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrd[2].Id, ContractLineItemObj2.Id); 
        qli3.SubscribedAssetNames__c = asst.Id+','+asst1.Id;
        qli3.Disposition_Reason__c = ReplacementConstants.DISPOSTION_RENEWING;
        qlList.add(qli2);
        qlList.add(qli3);
        insert qlList;
        
        List<ContractLineItem> lstContract = [SELECT Id, SBQQSC__OriginalQuoteLine__c FROM ContractLineItem];
        List<ContractLineItem> contractUpdate = new List<ContractLineItem>();
        if(!lstContract.isEmpty()){
            for(ContractLineItem ct: lstContract){
                ct.SBQQSC__OriginalQuoteLine__c = qli.Id;
                contractUpdate.add(ct);
            }
        }
        if(!contractUpdate.isEmpty()){
            update contractUpdate;
        }
        asst1.SBQQSC__CurrentContractLineItem__c=ContractLineItemObj1.Id;Update asst1;
        
        
        Test.startTest();   
        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();
        Entitlement ent = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement', 
                acc.Id, lstPrd[0].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj.Id);
        Entitlement ent1 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[1].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj1.Id);
            Entitlement ent2 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[2].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj2.Id);
        ent1.EndDate = date.newinstance(2028, 2, 17);
        ent1.StartDate = date.newinstance(2027, 2, 17);
        entList.add(ent);
        entList.add(ent1);
        entList.add(ent2);
        INSERT entList;

        //Scale Entitlement
        List<Scale_Entitlement__c> scaleEntList = new List<Scale_Entitlement__c>();
        Scale_Entitlement__c scaleEnt= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst.Id);
        Scale_Entitlement__c scaleEnt2= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst1.Id);
        scaleEntList.add(scaleEnt);
        scaleEntList.add(scaleEnt2);
        INSERT scaleEntList;

        //Entitlement Links for inactive and Upgrade Entitlements
        List<Entitlement_Links__c> entLinkLst = new List<Entitlement_Links__c>();
        Entitlement_Links__c entLink1= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent1.Id); //Inactive Link
        Entitlement_Links__c entLink2= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent2.Id); //Upgrade link
        entLinkLst.add(entLink1);
        entLinkLst.add(entLink2);
        INSERT entLinkLst;
        }
        Test.stopTest();
    }
     /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationAttributesNewTestMethod
    * Date Created/Modified: 26/09/2025
    * @description         : call apex class from method
    * Author               : Khushboo
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
     testmethod static void replacementQuoteLineCreationAttributesNewTestMethod(){
        
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
                new Map<String, List<Scale_Entitlement__c>>();
            Date todaysDate = System.today();
            Date startDate = date.newinstance(2025, 2, 17);
            Date endDate = date.newinstance(2028, 2, 17);
            
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data at once
            List<SBQQ__Quote__c> quotelist = 
                [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,
                    GPL_Deal__c, SBQQ__Account__c FROM SBQQ__Quote__c 
                    WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION 
                    OR SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL];
            SBQQ__Quote__c qb= quotelist[0];
            //Get Quote data
            SBQQ__Quote__c qb1= quotelist[1];
            
            //Get Product data 
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 LIMIT 15];
            
            /*List<SBQQ__ProductOption__c> productOptions= 
                [select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, Support_Type__c,Configured_SKU_ID__c, 
                        Configured_SKU_Name__c,Feature_Name__c from SBQQ__ProductOption__c 
                  where SBQQ__Feature__r.Name =:ReplacementConstants.SUPPORT 
                  and SBQQ__ConfiguredSKU__r.Family =:ReplacementConstants.PRODUCTCODE_R7000 and SBQQ__Selected__c=true];*/
            
            List<Entitlement> ets = [SELECT Id,  Name, AssetId, Asset.Name,StartDate,
                EndDate,Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, Asset.Product2.Family
                ,Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,
                Asset.SBQQSC__CurrentContractLineItem__c,Product__c,Product__r.Name,Product__r.Support_Type__c,
                Renewable__c,Product__r.License_Type__c,product__r.Product_Level__c,Product__r.Product_Type__c,
                Product__r.ProductCode,Product__r.License_Category__c,Product__r.License_Sub_Category__c,
                Product__r.Description,Product__r.Replacement_Category__c,Product__r.Edition__c,
                Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,
                Order_Number__c,Order_Quantity__c,ServiceContractId,Quantity__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,ServiceContract.Name,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,ContractLineItem.TPH_Drive_Size__c,
                ContractLineItem.TPH_Quantity__c,ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,
                ContractLineItem.Support_Type__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,ContractLineItem.Product_SubType__c, 
                ContractLineItem.Product_Type__c,ContractLineItem.SBQQSC__QuoteLine__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ServiceContract.ContractNumber,ContractLineItem.Total_Price_Without_Promo__c,SBQQSC__AssetRootId__c,
                ContractLineItem.Licensing_Model__c,Renewal_Category__c FROM Entitlement where AccountId =: acc.Id];  
            
            List<Scale_Entitlement__c> scaleEntList  = 
                [SELECT Id, Asset__c,Asset__r.Name,Entitlement__c,Entitlement__r.Name,
                Asset__r.SBQQSC__CurrentContractLineItem__c, Asset__r.Product2.Family, 
                Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,Asset__r.Product2Id, 
                Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,Asset__r.Product2.Product_Type__c,
                Asset__r.Product2.Add_on_Level__c,Entitlement__r.Product__r.Product_Level__c,
                Entitlement__r.Product__r.Add_on_Level__c, Renewal_Category__c FROM Scale_Entitlement__c ];
            
            List<Entitlement_Links__c> entLinks = 
                [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, 
                    Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, 
                    Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, 
                    Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, 
                    Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, 
                    Renewed_Entitlement__r.Product__r.Product_Type__c, Renewal_Category__c  
                FROM Entitlement_Links__c 
                where (Previous_Entitlement__r.EndDate >= : todaysDate 
                    OR Renewed_Entitlement__r.StartDate >= : todaysDate )];
            List<Polaris_SKU_Mapping_V2__c> PolarisMapping=
                [SELECT Id,Feature_Name_on_New_Product__c, New_Product__c,New_Product__r.Productcode,
                    Old_Product__c,Old_Product__r.Productcode,New_Product__r.Eligible_for_RCDM_T__c,
                    New_Product__r.Product_Type__c, New_Product__r.Product_Subtype__c,Payment_Option__c,
                    Quantity_Mapping_Type__c,Quantity_Ratio__c, Support_Type__c,Support_Tier__c,
                    New_Product__r.SBQQ__SubscriptionTerm__c,New_Product__r.Description, 
                    New_Product__r.Sales_Comp_Category__c, New_Product__r.Product_Level__c, 
                    New_Product__r.License_Type__c 
                FROM Polaris_SKU_Mapping_V2__c where Old_Product__r.IsActive =true and New_Product__r.IsActive =true];
            
            mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap1 = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> hwSupportMainWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            
            List<Product2> prodResult21= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 
                WHERE Name = 'RS-BT-BE-SC-L3-PA' LIMIT 1];
            
            ReplacementRefreshWrapperData.WrapperData wrapv1Data21 = 
            Replacement_TestDataFactory.getWrappers (ets[1], 'v1', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapv1Data21.isModified = true;
            wrapv1Data21.rowSelected = true;
            wrapv1Data21.skuProductId = prodResult21[0].Id;
            wrapv1Data21.quantity = 10;
            wrapv1Data21.selectedquantity = 10;
            wrapv1Data21.selecteddisposition = ReplacementConstants.UPGRADE_VALUE;
            ReplacementRefreshWrapperData.WrapperData mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            baseLicenceWrap.add(wrapv1Data21);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap1.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData21 = 
                Replacement_TestDataFactory.getWrappers (ets[2], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapHWSuppData21.renewalEndDate=date.newinstance(2029, 2, 17);
            hwSupportMainWrap.add(wrapHWSuppData21);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap1.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData22 = 
                Replacement_TestDataFactory.getWrappers (ets[2], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapHWSuppData22.isModified = true;
            wrapHWSuppData22.rowSelected = true;
            wrapHWSuppData22.skuProductId = null;
            wrapHWSuppData22.assetsAvailable = new List<ReplacementRefreshWrapperData.pickList>();
            wrapHWSuppData22.selectedquantity = 40 ;
            wrapHWSuppData22.customIndex = '2.0.0';
            wrapHWSuppData22.selecteddisposition = ReplacementConstants.DISPOSTION_RENEWING;
            hwSupportMainWrap.add(wrapHWSuppData22);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap1.add(mainWrp);
            
            
            List<ReplacementRefreshWrapperData.pickList> optionsEx = new List<ReplacementRefreshWrapperData.pickList>();
            ReplacementRefreshWrapperData.pickList optionEx1 = new ReplacementRefreshWrapperData.pickList(); 
            optionEx1.value = 'Mismatch Quantity';
            optionEx1.selected = true;
            optionsEx.add(optionEx1);

            ReplacementRefreshWrapperData.pickList optionEx2 = new ReplacementRefreshWrapperData.pickList(); 
            optionEx2.value = 'Individual Lines Only';
            optionEx2.selected = true;
            optionsEx.add(optionEx2);
            Map<String, String> quoteDetail = new MAp<String, String>();
            quoteDetail.put(ReplacementConstants.ATTRIBUTE_ISDEALOPS,''+true);
            quoteDetail.put(ReplacementConstants.ATTRIBUTE_EXCEPTIONCOMMENTS, 'test exceptionComments');
            quoteDetail.put(ReplacementConstants.ATTRIBUTE_EXCEPTIONMESSAGES, JSON.serialize(optionsEx));

            String jsonString = JSON.serialize(quoteDetail);
            Test.startTest();
            
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap1,null,jsonString);
            Test.stopTest();
            System.assert(true);
        }
    }
    /***********************************************************************************************************
    * Method Name          : autoAddNewLinesForReplacementTest
    * Date Created/Modified: 16/10/2025
    * @description         : Covers ReplacementQuoteLineCreationExtension.autoAddNewLinesForReplacement (In-Region defaults)
    * Notes                : Does not touch Quote formula fields. Sets Account.RBRK_NotSummaryVarCustomRuleId__c = 'DO' so Quote formula reflects it.
    **********************************************************************************************************/
    testmethod static void autoAddNewLinesForReplacementTest() {
        // Arrange
        User runUser = [SELECT Id FROM User WHERE Email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(runUser){
            SBQQ__Quote__c quoteRec = [
                SELECT Id, SBQQ__Account__c,RBRK_NotSummaryVarCustomRuleId__c, RWD_Deal_Ops_Exception__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Type__c IN (:ReplacementConstants.QUOTE_TYPE_RENEWAL, :ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION)
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            // Ensure Account drives the Quote formula for SummaryVariable
            Account acc = [SELECT Id, RBRK_NotSummaryVarCustomRuleId__c FROM Account WHERE Id = :quoteRec.SBQQ__Account__c LIMIT 1];
            acc.RBRK_NotSummaryVarCustomRuleId__c = 'DO';
            update acc;

            // Clear Deal Ops exception so auto-add isn't blocked
            quoteRec.RWD_Deal_Ops_Exception__c = null;
            update quoteRec;
			Map<String, Id> productIdMap = new Map<String, Id>();
            For(Product2 prod:[SELECT Name, ProductCode,Id FROM Product2 WHERE ProductCode IN ('RS-GB-MS-PE-PA','RS-UR-CCR-MS-PE-PA')]){
                  productIdMap.put(prod.ProductCode,Prod.Id);
                }
            
            // Parent Quote Line to act as replacement source
            SBQQ__QuoteLine__c parentQL = new SBQQ__QuoteLine__c(
                                                    SBQQ__Quote__c = quoteRec.Id, 
                                                    SBQQ__Product__c = productIdMap.get('RS-UR-CCR-MS-PE-PA'), 
                                                    SBQQ__Quantity__c = 50, 
                                                    SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__DefaultSubscriptionTerm__c = 1);
            
           
            // Multi Mapping so method can find a mapping by repKey
            Multi_Mapping_V2_Conversion__c mm = new Multi_Mapping_V2_Conversion__c(
                Name = 'RS-UR-CCR-MS-PE-PA-RS-GB-MS-PE-PA',
                Source_Product__c = productIdMap.get('RS-UR-CCR-MS-PE-PA'),
                Target_Product__c = productIdMap.get('RS-GB-MS-PE-PA'),
                Quantity_Multiplier__c = 5,
				Renewal_Type__c = 'V2 To V2 - In Region',
                active__c = true
            );
            insert mm;

            // Provide a Product Option mapping for SBQQ__ProductOption__c resolution
            SBQQ__ProductFeature__c feat = new SBQQ__ProductFeature__c(
                Name = 'Support',
                SBQQ__ConfiguredSKU__c = parentQL.SBQQ__Product__c,
                SBQQ__Category__c = 'Support',
                SBQQ__Number__c = 1
            );
            insert feat;
            SBQQ__ProductOption__c opt = new SBQQ__ProductOption__c(
                SBQQ__ConfiguredSKU__c = parentQL.SBQQ__Product__c,
                SBQQ__OptionalSKU__c =  productIdMap.get('RS-GB-MS-PE-PA'),
                SBQQ__Feature__c = feat.Id,
                SBQQ__Type__c = ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT,
                SBQQ__Selected__c = true,
                SBQQ__Number__c = 1
            );
            insert opt;

            // Inputs
            Map<String, SBQQ__QuoteLine__c> entitlementParentQL = new Map<String, SBQQ__QuoteLine__c>{
                'Ent1' => parentQL
            };
            Set<Id> selectedSkus = new Set<Id>{ parentQL.SBQQ__Product__c };
            
            Test.startTest();
            // Act
            Map<String, SBQQ__QuoteLine__c> result = ReplacementQuoteLineCreationExtension.autoAddNewLinesForReplacement(
                quoteRec.Id,
                entitlementParentQL,
                selectedSkus
            );
            Test.stopTest();

            // Assert
            
            System.assert(result.size()> 0, 'child line expected');
        }
    }
    
}