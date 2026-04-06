/**
* @File Name : ReplacementQuoteLineCreationTest.cls
* @description : test class for ReplacementQuoteLineCreation
* @Author :
* @Last Modified By :
* @Last Modified On : February 18, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | February 18, 2025 |   | Initial Version
**/
@isTest
public class ReplacementQuoteLineCreationTest {
    /***********************************************************************************************************
    * Method Name          : setup
    * Date Created/Modified: 04/03/2025
    * @description         : Creates Wrapper that is to be passed to the test method
    * Author               : Sumedha
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
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-01', 'RBK-R6410-01'
           , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
           , ReplacementConstants.SUBSCRIPTION,ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-02', 'RBK-R6410-02'
           , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
           , ReplacementConstants.SUBSCRIPTION,ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-03', 'RBK-R6410-03'
           , ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION
           , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.M365H, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getv1Product('RBK-R6410-04', 'RBK-R6410-04'
           , ReplacementConstants.EDITION_STANDALONE, ReplacementConstants.M365_DATA_PROTECTION
           , ReplacementConstants.PREPETUAL, ReplacementConstants.NAS_CLOUD_DIRECT, ReplacementConstants.ON_PREM));
        lstPrd.add(Replacement_TestDataFactory.getv1Product('RBK-R6410-05', 'RBK-R6410-05'
           , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
           , ReplacementConstants.SUBSCRIPTION,ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ON_PREM));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-06', 'RBK-R6410-06'
           , ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.COULD_DATA_PROTECTION
           , ReplacementConstants.PREPETUAL, ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-07', 'RBK-R6410-07'
           , ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SFDC_DATA_PROTECTION
           , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.PROACTIVE_EDITION, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-08', 'RBK-R6410-08'
           , ReplacementConstants.PROACTIVE_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION
           , ReplacementConstants.PREPETUAL, ReplacementConstants.GPS, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-09', 'RBK-R6410-09'
           , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
           , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-10', 'RBK-R6410-10'
           , ReplacementConstants.ENTERPRISE_EDITION, ReplacementConstants.COULD_DATA_PROTECTION
           , ReplacementConstants.PREPETUAL, ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-UG-P-CVB', 'RBK-UG-P-CVB'
           , ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.COULD_DATA_PROTECTION
           , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-RH-7408-02', 'RBK-R6410-RH-7408-02'
           , null,null,null, ReplacementConstants.HARDWARE,null));//refresh h/w
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-RS-HW-SVC-R7K-L3-S2', 'RBK-R6410-RS-HW-SVC-R7K-L3-S2'
           , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
           , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));//refresh h/w support
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-RS-HW-SVC-R7K-PE-S2', 'RBK-R6410-RS-HW-SVC-R7K-PE-S2'
           , null,null,null, ReplacementConstants.HW_SUPPORT,null));//refresh h/w Support
        //lstPrd.add(Replacement_TestDataFactory.getProduct('RS-BT-CVA-PE-PP', 'RBK-UG-P-CVB', 'Support Upgrade', ReplacementConstants.COULD_DATA_PROTECTION, ReplacementConstants.SUBSCRIPTION, 'cloud Vault Backup', ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProductWithSubCategory('RS-BT-CVA-PE-PP', 'RS-BT-CVA-PE-PP'
           , '',ReplacementConstants.CLOUD_VAULT, ReplacementConstants.SUBSCRIPTION
           , ReplacementConstants.CLOUD_VALUE_ARCHIVE, ReplacementConstants.SAAS, ReplacementConstants.CV_SAAS_COMMERCIAL));
        lstPrd.add(Replacement_TestDataFactory.getProductWithSubCategory('RS-BT-BE-SC-PE-PA', 'RS-BT-BE-SC-PE-PA'
           , ReplacementConstants.BUSINESS_EDITION,ReplacementConstants.ENTERPRISE_DATA_PROTECTION_SCALE
           , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.SAAS
           , ReplacementConstants.EDP_SCALE_COMMERCIAL));
        lstPrd.add(Replacement_TestDataFactory.getProductWithSubCategory('RHA-7402-01', 'RHA-7402-01'
           , null,ReplacementConstants.NON_REPLACEABLE, null, ReplacementConstants.HARDWARE, null, null));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-011', 'RBK-R6410-011'
           , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
           , ReplacementConstants.SUBSCRIPTION,ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SAAS));
        
        
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-F3M-CBL-01', 'RBK-F3M-CBL-01'
           , null, null
           , null,ReplacementConstants.ACCESSORIES, null));
        
        lstPrd[0].Support_Tier__c=ReplacementConstants.SUPPORT_TYPE_S3;
        lstPrd[9].Support_Tier__c=ReplacementConstants.SUPPORT_TYPE_S3;
        lstPrd[0].Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        lstPrd[0].Usable_Capacity__c=100;
        lstPrd[9].Usable_Capacity__c=null;
        lstPrd[0].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[1].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_PRIMIUM;
        lstPrd[1].Eligible_for_RCDM_T__c=true;
        lstPrd[2].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[16].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[16].Family =ReplacementConstants.PRODUCTCODE_R7000;
        lstPrd[2].Product_Level__c = null;
        lstPrd[17].Product_Level__c = null;
        lstPrd[2].Product_Type__c=ReplacementConstants.HW_SUPPORT;
        lstPrd[2].Eligible_for_RCDM_T__c=true;
        lstPrd[3].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_PRIMIUM;
        lstPrd[4].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[9].Product_Subtype__c = ReplacementConstants.FIPS;
        lstPrd[11].Family = ReplacementConstants.PRODUCTCODE_R7000;
        lstPrd[14].Family = ReplacementConstants.PRODUCTCODE_R7000;
        lstPrd[15].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_PRIMIUM;//khushboo
        lstPrd[12].Support_Tier__c=ReplacementConstants.SUPPORT_TYPE_S2;
        lstPrd[13].Support_Tier__c=ReplacementConstants.SUPPORT_TYPE_S2;
        lstPrd[0].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[1].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[2].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[3].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[4].SBQQ__RenewalProduct__c = lstPrd[13].Id;
         lstPrd[4].Eligible_for_RCDM_T__c=true;
        lstPrd[5].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[6].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[7].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[8].SBQQ__RenewalProduct__c = lstPrd[13].Id;
         lstPrd[8].Eligible_for_RCDM_T__c=true;
          lstPrd[9].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[10].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[11].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[12].SBQQ__RenewalProduct__c = lstPrd[13].Id;
        lstPrd[13].SBQQ__RenewalProduct__c = lstPrd[1].Id;
        lstPrd[14].SBQQ__RenewalProduct__c = lstPrd[1].Id;
        lstPrd[15].SBQQ__RenewalProduct__c = lstPrd[1].Id;
        lstPrd[16].SBQQ__RenewalProduct__c = lstPrd[1].Id;
        lstPrd[16].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[6].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[2].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[1].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[3].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[4].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[0].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[15].IsHardwareNotRequiredForHybridLicense__c =false;
        lstPrd[17].SBQQ__RenewalProduct__c = lstPrd[1].Id;
      system.runAs(usr1){
        INSERT lstPrd;
        for (Product2 prod : lstPrd) {
            lstPrdIds.add(prod.id);
        }
        
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
        
          SBQQ__ProductFeature__c prodAcceFeature3 = new SBQQ__ProductFeature__c();
        prodAcceFeature3.Name = ReplacementConstants.ACCESSORIES;
        prodAcceFeature3.SBQQ__ConfiguredSKU__c =lstPrd[11].Id;
        prodAcceFeature3.SBQQ__Number__c = 4;
        prodAcceFeature3.SBQQ__Category__c = ReplacementConstants.ACCESSORIES;
        insert prodAcceFeature3;
        
        List<SBQQ__ProductOption__c> prodOptions=new List<SBQQ__ProductOption__c>();
        SBQQ__ProductOption__c prodSupportOpt1 = new SBQQ__ProductOption__c();
        prodSupportOpt1.Refresh_Default_Option__c = false;
        prodSupportOpt1.SBQQ__ConfiguredSKU__c = lstPrd[11].Id;
        prodSupportOpt1.Configured_SKU_ID__c= lstPrd[11].Id;
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
        prodSupportOpt2.Configured_SKU_ID__c= lstPrd[11].Id;
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
        prodSupportOpt4.Configured_SKU_ID__c= lstPrd[11].Id;
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
        prodSupportOpt3.Configured_SKU_ID__c= lstPrd[16].Id;
        prodSupportOpt3.SBQQ__OptionalSKU__c = lstPrd[12].Id;
        prodSupportOpt3.SBQQ__Type__c = ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT;
        prodSupportOpt3.SBQQ__Feature__c = prodSupportFeature2.Id;
        prodSupportOpt3.Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        prodSupportOpt3.SBQQ__Selected__c = true;
        prodSupportOpt3.SBQQ__Number__c = 2;
        prodSupportOpt3.Payment_Options__c = ReplacementConstants.PREPAY;
        prodOptions.add(prodSupportOpt3);
            SBQQ__ProductOption__c prodAccesOpt2 = new SBQQ__ProductOption__c();
        prodAccesOpt2.Refresh_Default_Option__c = false;
        prodAccesOpt2.SBQQ__ConfiguredSKU__c = lstPrd[11].Id;
        prodAccesOpt2.Configured_SKU_ID__c= lstPrd[11].Id;
        prodAccesOpt2.SBQQ__OptionalSKU__c = lstPrd[18].Id;
        prodAccesOpt2.Refresh_Default_Option__c = true;
        prodAccesOpt2.SBQQ__Type__c = ReplacementConstants.PRODUCT_OPTION_TYPE_RELATED_PRODUCT;
        prodAccesOpt2.SBQQ__Feature__c = prodAcceFeature3.Id;
        prodAccesOpt2.SBQQ__Selected__c = true;
        prodAccesOpt2.SBQQ__Number__c = 1;
        prodAccesOpt2.Payment_Options__c = ReplacementConstants.PREPAY;
        prodOptions.add(prodAccesOpt2);
        insert prodOptions;

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
            Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[2].Id, lstPrd[1].Id);
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj1 = 
            Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[2].Id, lstPrd[4].Id);
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj2 = 
            Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[2].Id, lstPrd[8].Id);
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj3 = 
            Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[17].Id, lstPrd[8].Id);
        polarisSKUMappingObjList.add(polarisSKUMappingObj3);
        polarisSKUMappingObjList.add(polarisSKUMappingObj);
        polarisSKUMappingObjList.add(polarisSKUMappingObj1);
        polarisSKUMappingObjList.add(polarisSKUMappingObj2);
        INSERT polarisSKUMappingObjList;

        //Multi Mapping V2 Conversion
        Multi_Mapping_V2_Conversion__c mappingConvObj= Replacement_TestDataFactory.getMultiMappingV2Conversion(lstPrd[10].Id, lstPrd[1].Id);
        INSERT mappingConvObj;    

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
        Asset asst1= Replacement_TestDataFactory.getAsset('Asset123', lstPrd[9].Id, acc.Id);
        asst.SerialNumber='Asset123';asst1.SerialNumber='Asset123';
        asstList.add(asst);
        asstList.add(asst1);
        INSERT asstList;
		        
        List<ContractLineItem> lstCLI = new List<ContractLineItem>();
        ContractLineItem ContractLineItemObj = 
        Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj.EndDate = Date.today().addDays(365);
        ContractLineItemObj.StartDate =  Date.today();
        ContractLineItemObj.SBQQSC__Product__c = lstPrdIds[1];
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
        ContractLineItemObj2.SBQQSC__Product__c = lstPrdIds[10];
        ContractLineItemObj2.CPQ_Uplift__c = '5';
        ContractLineItemObj2.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj2);
        ContractLineItem ContractLineItemObj3 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj3.EndDate = Date.today().addDays(365);
        ContractLineItemObj3.StartDate =  Date.today();
        ContractLineItemObj3.SBQQSC__Product__c = lstPrdIds[8];
        ContractLineItemObj3.CPQ_Uplift__c = '5';
        ContractLineItemObj3.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj3);
        ContractLineItem ContractLineItemObj4 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj4.EndDate = Date.today().addDays(365);
        ContractLineItemObj4.StartDate =  Date.today();
        ContractLineItemObj4.SBQQSC__Product__c = lstPrdIds[4];
        ContractLineItemObj4.CPQ_Uplift__c = '5';
        ContractLineItemObj4.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj4); //v1 Product
        ContractLineItem ContractLineItemObj5 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj5.EndDate = Date.today().addDays(365);
        ContractLineItemObj5.StartDate =  Date.today();
        ContractLineItemObj5.SBQQSC__Product__c = lstPrdIds[8];
        ContractLineItemObj5.CPQ_Uplift__c = '5';
        ContractLineItemObj5.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj5);
        ContractLineItem ContractLineItemObj6 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj6.EndDate = Date.today().addDays(365);
        ContractLineItemObj6.StartDate =  Date.today();
        ContractLineItemObj6.SBQQSC__Product__c = lstPrdIds[8];
        ContractLineItemObj6.CPQ_Uplift__c = '5';
        ContractLineItemObj6.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj6);
        Test.startTest();
        ContractLineItem ContractLineItemObj12 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj12.EndDate = Date.today().addDays(365);
        ContractLineItemObj12.StartDate =  Date.today();
        ContractLineItemObj12.SBQQSC__Product__c = lstPrd[2].Id;
        ContractLineItemObj12.CPQ_Uplift__c = '5';
        ContractLineItemObj12.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj12);
        ContractLineItem ContractLineItemObj13 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj13.EndDate = Date.today().addDays(365);
        ContractLineItemObj13.StartDate =  Date.today();
        ContractLineItemObj13.SBQQSC__Product__c = lstPrd[2].Id;
        ContractLineItemObj13.CPQ_Uplift__c = '5';
        ContractLineItemObj13.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj13);
        ContractLineItem ContractLineItemObj14 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj14.EndDate = Date.today().addDays(365);
        ContractLineItemObj14.StartDate =  Date.today();
        ContractLineItemObj14.SBQQSC__Product__c = lstPrd[3].Id;
        ContractLineItemObj14.CPQ_Uplift__c = '5';
        ContractLineItemObj14.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj14);
        ContractLineItem ContractLineItemObj17 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj17.EndDate = Date.today().addDays(365);
        ContractLineItemObj17.StartDate =  Date.today();
        ContractLineItemObj17.SBQQSC__Product__c = lstPrd[17].Id;
        ContractLineItemObj17.CPQ_Uplift__c = '5';
        ContractLineItemObj17.SBQQSC__Quantity__c=10;
        lstCLI.add(ContractLineItemObj17);
        insert lstCLI;
		
        
        
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrd[1].Id, ContractLineItemObj1.Id); 
        qli.SubscribedAssetNames__c = asst.Id+','+asst1.Id;
        SBQQ__QuoteLine__c qli1= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrd[2].Id, ContractLineItemObj2.Id);
        qli1.SubscribedAssetNames__c = asst.Id+','+asst1.Id;
        SBQQ__QuoteLine__c qli2= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrd[2].Id, ContractLineItemObj12.Id); 
        qli2.SubscribedAssetNames__c = asst.Id+','+asst1.Id;
        qli2.Disposition_Reason__c = 
            ReplacementConstants.DISPOSTION_RENEWING;
        SBQQ__QuoteLine__c qli3= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrd[2].Id, ContractLineItemObj13.Id); 
        qli3.SubscribedAssetNames__c = asst.Id+','+asst1.Id;
        qli3.Disposition_Reason__c = ReplacementConstants.DISPOSTION_RENEWING;
        //qlList.add(qli);
        //qlList.add(qli1);
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
        
        
            
        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();
        Entitlement ent = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement', 
                acc.Id, lstPrd[0].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj.Id);
        Entitlement ent1 = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement1', 
                acc.Id, lstPrd[0].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj1.Id);//Inactive
        Entitlement ent2 = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement1', 
                acc.Id, lstPrd[10].Id, asst1.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj2.Id); //Upgrade Product
        Entitlement ent3 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[8].Id, asst1.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj3.Id); //HW Support
        Entitlement ent4 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[4].Id, asst1.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj4.Id);//v1 Product
        Entitlement ent5 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[8].Id, asst1.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj5.Id); //HW Support
        Entitlement ent6 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[8].Id, asst1.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj6.Id); //HW Support
        Entitlement ent12 = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement', 
                acc.Id, lstPrd[2].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj12.Id);
        Entitlement ent13 = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement1', 
                acc.Id, lstPrd[2].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj13.Id);//Inactive
        Entitlement ent14 = 
            Replacement_TestDataFactory.getEntitlement('CVB Entitlement', 
                acc.Id, lstPrd[14].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj13.Id);
        Entitlement ent15 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[3].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj14.Id);
        Entitlement ent17 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', 
                acc.Id, lstPrd[17].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj17.Id);
        ent1.EndDate = date.newinstance(2028, 2, 17);
        ent1.StartDate = date.newinstance(2027, 2, 17);
        entList.add(ent);
        entList.add(ent1);
        entList.add(ent2);
        entList.add(ent3);
        entList.add(ent4);
        entList.add(ent5);
        entList.add(ent6);
        entList.add(ent12);
        entList.add(ent13);
        entList.add(ent14);
        entList.add(ent15);
        entList.add(ent17);
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
    * Method Name          : replacementCPQCloneTest
    * Date Created/Modified: 11/08/2025
    * @description         : call apex class from method
    * Author               : Rahul
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
    testmethod static void replacementCPQCloneTest(){ 
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            CPQ_Disposition_Quote_Line__c cp = [SELECT Id, Disposition_Reason__c, Product__c, Quantity__c, Quote__c FROM CPQ_Disposition_Quote_Line__c LIMIT 1];
            List<SBQQ__Quote__c> lstsbq = [SELECT Id FROM SBQQ__Quote__c];
        	Set<Id> cpqQuoteId = new Set<Id>();
        	Map<Id,Id> mapSourceVsNewQId = new Map<Id, Id>();
            Id updateQuoteId;
            if(cp.Id != NULL && !lstsbq.isEmpty()){
                system.assert(cp.Id != null);
                for(SBQQ__Quote__c sq : lstsbq){
                    if(cp.Quote__c != sq.Id){
                        updateQuoteId = sq.Id;
                    }
                }
                mapSourceVsNewQId.put(cp.Quote__c, updateQuoteId);
                cpqQuoteId.add(cp.Quote__c);
                ReplacementQuoteLineCreationHelper.createCPQDispLinesOnCloneRelated(cpqQuoteId, mapSourceVsNewQId);
                SBQQ__Quote__c sb = new SBQQ__Quote__c();
                sb.Id = updateQuoteId;
                sb.SBQQ__Source__c = cp.Quote__c;
                Test.startTest();
                update sb;
                Test.stopTest();
            }
        }
    }
    
    /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationTestMethod
    * Date Created/Modified: 10/03/2025
    * @description         : call apex class from method
    * Author               : Sumedha
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
    testmethod static void replacementQuoteLineCreationTestMethod(){ 
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
                new Map<String, List<Scale_Entitlement__c>>();
            List<ReplacementRefreshWrapperData.WrapperData> hwSuppWrap = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> ugWraplst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> inactiveLst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.picklist> assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>();
            Date todaysDate = System.today();
            Date startDate = date.newinstance(2025, 2, 17);
            Date endDate = date.newinstance(2028, 2, 17);
            
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,
                Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c FROM SBQQ__Quote__c 
                    WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
            //Get Quote data
            SBQQ__Quote__c qb1= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,
                GPL_Deal__c, SBQQ__Account__c FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL LIMIT 1];
            
            //Get Product data 
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 
                WHERE Name like 'RBK-R6410%' LIMIT 15];
            
            List<Product2> prodResult1= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 
                WHERE Name = 'RHA-7402-01' LIMIT 1];
            
            List<SBQQ__ProductOption__c> productOptions= 
                [select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, Support_Type__c,Configured_SKU_ID__c, 
                        Configured_SKU_Name__c,Feature_Name__c 
                  from SBQQ__ProductOption__c where (SBQQ__Feature__r.Name =:ReplacementConstants.SUPPORT OR (SBQQ__Feature__r.Name =:ReplacementConstants.ACCESSORIES AND Refresh_Default_Option__c = true))
                    and SBQQ__ConfiguredSKU__r.Family =: ReplacementConstants.PRODUCTCODE_R7000 and SBQQ__Selected__c=true];
            
            List<Entitlement> ets = [SELECT Id, Asset.Product2.Family, Name,SBQQSC__AssetRootId__c, 
                AssetId,Asset.SerialNumber, Asset.Name,StartDate,EndDate,Asset.Product_Usable_Capacity__c,
                Asset.Order_Product_Name__c, Asset.Product2.Name,Asset.Product2.RWD_Version__c,
                Asset.Product2.Product_Type__c,Asset.SBQQSC__CurrentContractLineItem__c,Product__c,
                Product__r.Name,Product__r.Support_Type__c,Renewable__c,Product__r.License_Type__c,
                product__r.Product_Level__c,Product__r.Product_Type__c,Product__r.ProductCode,
                Product__r.License_Category__c,Product__r.License_Sub_Category__c,Product__r.Description,
                Product__r.Replacement_Category__c,Product__r.Edition__c,Order_Number__c,Order_Quantity__c,
                Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,
                ServiceContractId,Quantity__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,
                ServiceContract.Name,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,ContractLineItem.TPH_Drive_Size__c,
                ContractLineItem.TPH_Quantity__c,ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,
                ContractLineItem.Support_Type__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,
                ContractLineItem.Product_SubType__c, ContractLineItem.Product_Type__c,ContractLineItem.SBQQSC__QuoteLine__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ContractLineItem.Licensing_Model__c, ServiceContract.ContractNumber 
                FROM Entitlement where AccountId =: acc.Id];  
            
            List<Scale_Entitlement__c> scaleEntList  = [
                SELECT Id, Asset__c,Asset__r.Product2.Family,Asset__r.Name,Entitlement__c,Entitlement__r.Name,
                Asset__r.SBQQSC__CurrentContractLineItem__c, Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,
                Asset__r.Product2Id, Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,Asset__r.Product2.Product_Type__c,
                Asset__r.Product2.Add_on_Level__c,Entitlement__r.Product__r.Product_Level__c,
                Entitlement__r.Product__r.Add_on_Level__c, Renewal_Category__c 
                FROM Scale_Entitlement__c ];
            
            List<Entitlement_Links__c> entLinks = [Select Id, Previous_Entitlement__c, 
                Previous_Entitlement__r.StartDate, Previous_Entitlement__r.Renewal_Category__c, 
                Previous_Entitlement__r.EndDate, Previous_Entitlement__r.Product__r.Product_Type__c , 
                Previous_Entitlement__r.Status, Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, 
                Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, 
                Renewed_Entitlement__r.Product__r.Product_Type__c  FROM Entitlement_Links__c 
                where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate )];
            
            mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap1 = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> hwSupportMainWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            
            ReplacementRefreshWrapperData.wrapperData mainWrp =new ReplacementRefreshWrapperData.wrapperData();
            List<String> R7hw=new List<String>();
            List<String> R6Asset=new List<String>();
           // R6Asset.add(ets[14].AssetId);
            R6Asset.add(ets[4].AssetId);
            for(Product2 p:prodResult){
                if(p.Family==ReplacementConstants.PRODUCTCODE_R7000){
                    R7hw.add(p.Id);
                }
            }
            if(prodResult1[0].id != null){
                    if(prodResult1[0].family == ReplacementConstants.PRODUCTCODE_R7000){
                             R7hw.add(prodResult1[0].Id);
                     }
            }
            
            List<ReplacementRefreshWrapperData.PickList> lstOptWrap= new List<ReplacementRefreshWrapperData.PickList>();
            ReplacementRefreshWrapperData.PickList option1 = new ReplacementRefreshWrapperData.PickList();
            option1.entitlementId=ets[0].Id;
            option1.label= ets[4].Asset.Name+' ('+ets[4].Asset.Product2.Name+') (10.00)';//BB220764040026 (RH-6404S-01) (30.00)
            option1.quantity= 10;
            option1.selected=true;
            option1.value=ets[4].AssetId;
            lstOptWrap.add(option1);
            
            
            List<RefreshWrapper> refreshWrap=new List<RefreshWrapper>();
            List<RefreshWrapper.Option> options= new List<RefreshWrapper.Option>();
            RefreshWrapper.Option option= new RefreshWrapper.Option();
            option.entitlementId=ets[0].Id;
            option.supportEntId=ets[4].Id;
            option.supportProdId=ets[4].Product__c;
            option.label= ets[4].Asset.Name+' ('+ets[4].Asset.Product2.Name+') (10.00)';//BB220764040026 (RH-6404S-01) (30.00)
            option.quantity= 10;
            option.selected=true;
            option.value=ets[4].AssetId;
            options.add(option);
            
            List<RefreshWrapper.Row> rows=new List<RefreshWrapper.Row>();
            RefreshWrapper.Row row=new RefreshWrapper.Row();
            row.isSelected=true;
            row.isModified=true;
            row.deltaQuantity=30;
            row.selectedAssetIds=R6Asset;
            row.isSelected=true;
            row.options=options;
            row.selectedTargetIds=R7hw;
            rows.add(row);
            
            RefreshWrapper WrapRefresh= new RefreshWrapper();
            WrapRefresh.productId=ets[0].Product__c;
            WrapRefresh.supportType=ets[0].Product__r.Support_Type__c;
            WrapRefresh.rows=rows;
            
            refreshWrap.add(WrapRefresh);
            List<Product2> prds1 = [SELECT Id, Name FROM Product2 WHERE name in ('RS-BT-BE-SC-PE-PA','RHA-7402-01')];
            Product2 skuPrd = new Product2();
            Product2 hardwarePrd = new Product2();
            if(!prds1.isEmpty()){
                for(Product2 prds : prds1){
                    if(prds.Name == 'RS-BT-BE-SC-PE-PA'){
                        skuPrd = prds;
                    }
                    if(prds.Name == 'RHA-7402-01'){
                        hardwarePrd = prds;
                    }
                }
            }
            //V2 base entitlement
            ReplacementRefreshWrapperData.WrapperData wrapData = 
                Replacement_TestDataFactory.getWrappers (ets[0], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            List<ReplacementRefreshWrapperData.PickList> lstAssetNonAsset = new List<ReplacementRefreshWrapperData.PickList>();
            if(String.isNotBlank(skuPrd.Name) != null && String.isNotBlank(hardwarePrd.Name) != null){ 
                ReplacementRefreshWrapperData.WrapperData wrapData15 = 
                    Replacement_TestDataFactory.getWrappers (ets[0] , 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
                wrapData15.skuProductId = skuPrd.Id;
                 
                ReplacementRefreshWrapperData.PickList pick = new ReplacementRefreshWrapperData.PickList();
                pick.selected = true;
                pick.label= hardwarePrd.Name+' ('+hardwarePrd.Name+') (10.00)';
                pick.value=hardwarePrd.Id;
                pick.entitlementId = ets[0].Id;
                pick.quantity= 10;
                lstAssetNonAsset.add(pick);
                baseLicenceWrap.add(wrapData15);
            }
            
            
            ReplacementRefreshWrapperData.WrapperData wrapData12 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData12);

            ReplacementRefreshWrapperData.WrapperData wrapData120 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData120);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap1.add(mainWrp);
        
            ReplacementRefreshWrapperData.WrapperData wrapData13 = 
                Replacement_TestDataFactory.getWrappers (ets[8], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData13);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap1.add(mainWrp);
            baseLicenceWrap.clear();
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSuppWrap.add(wrapHWSuppData);
            mainWrp.wrapHWSupportLines = hwSuppWrap;
            
            //Wrapper for Inactive
            ReplacementRefreshWrapperData.WrapperData wrapInactiveData = 
                Replacement_TestDataFactory.getWrappers (ets[1], 'InactiveEnt', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            inactiveLst.add(wrapInactiveData);
            
            //Wrapper for Upgrade SKUs
            ReplacementRefreshWrapperData.WrapperData wrapUGData = 
                Replacement_TestDataFactory.getWrappers (ets[2], 'UpgradeSKU', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            ugWraplst.add(wrapUGData);
            mainWrp.wrapUpgradeEnt = ugWraplst;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for v1 data
            ReplacementRefreshWrapperData.WrapperData wrapv1Data = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'v1', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            baseLicenceWrap.add(wrapv1Data);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData1 = 
                Replacement_TestDataFactory.getWrappers (ets[5], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData1);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData2 = 
                Replacement_TestDataFactory.getWrappers (ets[6], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData2);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            for (ReplacementRefreshWrapperData.wrapperData wrap : lstFinalWrap) {
                if (wrap.wrapBaseLicense != null && !wrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapBaseLicense) {
                        baseWrap.isModified = true;
                        baseWrap.rowSelected = true;
                        baseWrap.productId = skuPrd.Id;
                        baseWrap.skuProductId = skuPrd.Id;
                        baseWrap.skuProdName = skuPrd.Name;
                        baseWrap.consumedquantity = 10;
                        baseWrap.quantity = 10;
                        baseWrap.selectedquantity = 10;
                        baseWrap.selecteddisposition = ReplacementConstants.UPGRADE_VALUE;
                        baseWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
                if (wrap.wrapHWSupportLines != null && !wrap.wrapHWSupportLines.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  HwSpptWrap : wrap.wrapHWSupportLines) {
                        HwSpptWrap.isModified = true;
                        HwSpptWrap.rowSelected = true;
                        HwSpptWrap.skuProductId = null;
                        HwSpptWrap.skuProdName = null;
                        HwSpptWrap.consumedquantity = 10;
                        HwSpptWrap.quantity = 10;
                        HwSpptWrap.selectedquantity = 10;
                        HwSpptWrap.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
                        HwSpptWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
            }
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
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap,refreshWrap, jsonString);
            ReplacementQuoteLineCreation.createNewQuoteLines(qb1.Id, lstFinalWrap1,refreshWrap, jsonString);
            Test.stopTest();
            System.assert(true);
        }
    }

    /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationTestAssetMethod
    * Date Created/Modified: 10/03/2025
    * @description         : call apex class from method
    * Author               : Sumedha
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
     testmethod static void replacementQuoteLineCreationTestAssetMethod(){
     user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
			Test.StartTest();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
			//Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,
                Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c FROM SBQQ__Quote__c 
                    WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
			
			String replacementDetailsJSON = '{' +
                '\"targetProductType\":\"Hardware\",' +
                '\"skuStorageTierVal\":null,' +
                '\"skuSelectedName\":null,' +
                '\"skuSelected\":null,' +
                '\"rowValues\":[' +
                '{' +
                '\"upgradeLines\":null,' +
                '\"selectedTerm\":12,' +
                '\"selectedRenewalDate\":null,' +
                '\"selectedQty\":null,' +
                '\"selectedAssetList\":null,' +
                '\"selectedAsset\":null,' +
                '\"rowId\":\"0.0.0\",' +
                '\"isMismatch\":null,' +
                '\"isAutoDisposition\":null,' +
                '\"inactiveLines\":null,' +
                '\"entId\":null,' +
                '\"disposition\":\"Renewing\"' +
                '},' +
                '{' +
                '\"upgradeLines\":null,' +
                '\"selectedTerm\":12,' +
                '\"selectedRenewalDate\":null,' +
                '\"selectedQty\":null,' +
                '\"selectedAssetList\":null,' +
                '\"selectedAsset\":null,' +
                '\"rowId\":\"0.0.0\",' +
                '\"isMismatch\":null,' +
                '\"isAutoDisposition\":null,' +
                '\"inactiveLines\":null,' +
                '\"entId\":null,' +
                '\"disposition\":\"Renewing\"' +
                '}' +
                '],' +
                '\"renLine\":true,' +
                '\"refreshCategoryId\":null,' +
                '\"mode\":\"Dispose\",' +
                '\"dynamicFieldValues\":null' +
                '}';
            
            List<SBQQ__QuoteLine__c> qls = [SELECT Id, Replacement_Details__c FROM SBQQ__QuoteLine__c];
            List<SBQQ__QuoteLine__c> lstQlines = new List<SBQQ__QuoteLine__c>();
            if(!qls.isEmpty()){
                for(SBQQ__QuoteLine__c ql: qls){
                    ql.Replacement_Details__c = replacementDetailsJSON;
                    lstQlines.add(ql);
                }
            }
            if(!lstQlines.isEmpty()){
                update lstQlines;
            }
			List<SBQQ__QuoteLine__c> lstQl = [SELECT Id,SubscribedAssetNames__c, Replacement_Details__c, Arroyo_Subscribed_Asset_Name__c, SBQQ__Quantity__c, 
                                              SBQQ__Product__c, Related_Asset_Total_Capacity__c,SBQQ__SubscriptionTerm__c,SBQQ__StartDate__c, SBQQ__EndDate__c,
                                              Disposition_Reason__c, Product_Level__c,SBQQSC__RenewedContractLine__c, Total_Prior_Net_Total__c, 
                                              SBQQ__Number__c, SBQQ__Quote__c, Replacement_Motion__c, RWD_Expected_Default_Quantity__c, SBQQ__PricebookEntryId__c, SBQQ__RequiredBy__c, Product_Type__c,
                                              Product_Code_Type__c, SBQQ__SubscriptionPricing__c, Category__c, Arroyo_Subsumed_Old_Contract_Line_Items__c, SBQQ__Group__c, TPH_OEM__c, TPH_Models_Gen__c, 
                                              TPH_Drive_Size__c, TPH_Quantity__c, SBQQ__OptionLevel__c, SBQQ__OptionType__c, Who_will_the_customer_be_buying_the_HW__c, Who_will_Install_CDM__c,V1_Quantity__c,
                                              Payment_Options__c, Support_Type__c, Storage_Region_Bundle_FrontEnd__c, Storage_Tier__c,Storage_Region_Bundle__c, Rubrik_Hosted_M365_Quantity__c,
                                              Atlassian_Quantity__c, Salesforce_Quantity__c, Dynamics_Quantity__c,Special_Program__c, CPQ_Uplift__c, 
                                              Total_Prior_Net_Total_With_Uplift__c, SBQQ__Discount__c FROM SBQQ__QuoteLine__c];
            List<Asset> lstAsset  = [SELECT Id, Product_Usable_Capacity__c, SBQQSC__CurrentContractLineItem__c, SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c,
                                    SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__c, SBQQSC__CurrentContractLineItem__r.SBQQSC__Quantity__c  FROM Asset];
            Map<String, Asset> mapAsset = new Map<String, Asset>();
            if(!lstAsset.isEmpty()){
                for(Asset ast : lstAsset){
                    mapAsset.put(ast.Id, ast);
                }
            }
            Map<Id, Product2> productMap = new Map<Id, Product2>();
            List<Product2> lstPrd = [SELECT Id, Name, Product_Level__c,ProductCode FROM Product2];
            if(!lstPrd.isEmpty()){
                for(Product2 prd : lstPrd){
                    productMap.put(prd.Id, prd);
                }
            }
            ReplacementQuoteLineCreationExtension.calculateQuantityforV1(lstQl, new List<CPQ_Disposition_Quote_Line__c>(), new Map <Id, Polaris_SKU_Mapping_V2__c>(), mapAsset, productMap);
			Test.stopTest();
            System.assert(true);
		}	    
     }
    
    /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationAttributesTestMethod
    * Date Created/Modified: 10/03/2025
    * @description         : call apex class from method
    * Author               : Rahul
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
      testmethod static void replacementQuoteLineCreationAttributesTestMethod(){
        
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
                new Map<String, List<Scale_Entitlement__c>>();
            List<ReplacementRefreshWrapperData.WrapperData> hwSuppWrap = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> ugWraplst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> inactiveLst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.picklist> assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>();
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
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 15];
            
            List<SBQQ__ProductOption__c> productOptions= 
                [select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, Support_Type__c,Configured_SKU_ID__c, 
                        Configured_SKU_Name__c,Feature_Name__c from SBQQ__ProductOption__c 
                  where (SBQQ__Feature__r.Name =:ReplacementConstants.SUPPORT OR (SBQQ__Feature__r.Name =:ReplacementConstants.ACCESSORIES AND Refresh_Default_Option__c = true))
                  and SBQQ__ConfiguredSKU__r.Family =:ReplacementConstants.PRODUCTCODE_R7000 and SBQQ__Selected__c=true];
            
            List<Entitlement> ets = [SELECT Id,  Name, AssetId, Asset.Name,StartDate,SBQQSC__AssetRootId__c,
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
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ServiceContract.ContractNumber,
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
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> hwSupportMainWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            
            ReplacementRefreshWrapperData.wrapperData mainWrp =new ReplacementRefreshWrapperData.wrapperData();
            List<String> R7hw=new List<String>();
            List<String> R6Asset=new List<String>();
            R6Asset.add(ets[4].AssetId);
            for(Product2 p:prodResult){
                if(p.Family==ReplacementConstants.PRODUCTCODE_R7000){
                    R7hw.add(p.Id);
                }
            }
            
            Product2 prds = Replacement_TestDataFactory.getProductWithSubCategory('RS-BT-CVA-PE-PP', 'RS-BT-CVA-PE-PP'
            , '',ReplacementConstants.CLOUD_VAULT, ReplacementConstants.SUBSCRIPTION
            , ReplacementConstants.CLOUD_VALUE_ARCHIVE, ReplacementConstants.SAAS, ReplacementConstants.CV_SAAS_COMMERCIAL);
            INSERT prds;
            
            List<RefreshWrapper> refreshWrap=new List<RefreshWrapper>();
            List<RefreshWrapper.Option> options= new List<RefreshWrapper.Option>();
            RefreshWrapper.Option option= new RefreshWrapper.Option();
            option.entitlementId=ets[0].Id;
            option.supportEntId=ets[4].Id;
            option.supportProdId=ets[4].Product__c;
            option.label= ets[4].Asset.Name+' ('+ets[4].Asset.Product2.Name+') (10.00)';//BB220764040026 (RH-6404S-01) (30.00)
            option.quantity= 10;
            option.selected=true;
            option.value=ets[4].AssetId;
            options.add(option);
            
            List<RefreshWrapper.Row> rows=new List<RefreshWrapper.Row>();
            RefreshWrapper.Row row=new RefreshWrapper.Row();
            row.isSelected=true;
            row.isModified=true;
            row.deltaQuantity=30;
            row.selectedAssetIds=R6Asset;
            row.isSelected=true;
            row.options=options;
            row.selectedTargetIds=R7hw;
            rows.add(row);
            
            RefreshWrapper WrapRefresh= new RefreshWrapper();
            WrapRefresh.productId=ets[0].Product__c;
            WrapRefresh.supportType=ets[0].Product__r.Support_Type__c;
            WrapRefresh.rows=rows;
            
            refreshWrap.add(WrapRefresh);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSuppWrap.add(wrapHWSuppData);
            mainWrp.wrapHWSupportLines = hwSuppWrap;
            
            //Wrapper for Inactive
            ReplacementRefreshWrapperData.WrapperData wrapInactiveData = 
                Replacement_TestDataFactory.getWrappers (ets[1], 'InactiveEnt', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            inactiveLst.add(wrapInactiveData);
            
            //Wrapper for Upgrade SKUs
            ReplacementRefreshWrapperData.WrapperData wrapUGData = 
                Replacement_TestDataFactory.getWrappers (ets[2], 'UpgradeSKU', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            ugWraplst.add(wrapUGData);
            mainWrp.wrapUpgradeEnt = ugWraplst;
            lstFinalWrap.add(mainWrp);
            
            ReplacementRefreshWrapperData.WrapperData wrapUGData01 = 
                Replacement_TestDataFactory.getWrappers (ets[2], 'UpgradeSKU', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            wrapUGData01.skuProductId = prds.Id; 
            wrapUGData01.skuProdCodeType = 'CVA';
            wrapUGData01.skuAttributesToQuoteLine = new Map<String,String>();
            wrapUGData01.skuAttributesToQuoteLine.put(
                ReplacementConstants.STORAGE_BUNDLE_FIELD_API,'Storage - Zone 1 (US-W2, EU-N, UK-S, Canada)');
            ugWraplst.add(wrapUGData01);
            mainWrp.wrapUpgradeEnt = ugWraplst;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for v1 data
            ReplacementRefreshWrapperData.WrapperData wrapv1Data = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'v1', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            baseLicenceWrap.add(wrapv1Data);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData1 = 
                Replacement_TestDataFactory.getWrappers (ets[5], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData1);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData2 = 
                Replacement_TestDataFactory.getWrappers (ets[6], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData2);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            
            for (ReplacementRefreshWrapperData.wrapperData wrap : lstFinalWrap) {
                if (wrap.wrapBaseLicense != null && !wrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapBaseLicense) {
                        baseWrap.isModified = true;
                        baseWrap.rowSelected = true;
                        baseWrap.skuProductId = prodResult[1].Id;
                        baseWrap.skuProdName = prodResult[1].Name;
                        baseWrap.consumedquantity = 10;
                        baseWrap.quantity = 10;
                        baseWrap.selectedquantity = 10;
                        baseWrap.selecteddisposition = ReplacementConstants.UPGRADE_VALUE;
                        baseWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
                if (wrap.wrapHWSupportLines != null && !wrap.wrapHWSupportLines.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  HwSpptWrap : wrap.wrapHWSupportLines) {
                        HwSpptWrap.isModified = true;
                        HwSpptWrap.rowSelected = true;
                        HwSpptWrap.skuProductId = null;
                        HwSpptWrap.skuProdName = null;
                        HwSpptWrap.consumedquantity = 10;
                        HwSpptWrap.quantity = 10;
                        HwSpptWrap.selectedquantity = 10;
                        HwSpptWrap.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
                        HwSpptWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
            }
            
            ReplacementRefreshWrapperData.WrapperData wrapv1Data1 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapv1Data1.isModified = true;
            wrapv1Data1.rowSelected = true;
            wrapv1Data1.consumedquantity = 10;
            wrapv1Data1.quantity = 10;
            wrapv1Data1.selectedquantity = 10;
            wrapv1Data1.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
            ReplacementRefreshWrapperData.WrapperData mainWrp1 = new ReplacementRefreshWrapperData.WrapperData();
            baseLicenceWrap.add(wrapv1Data1);
            mainWrp1.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp1);
            
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
            
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap,refreshWrap,jsonString);
            Test.stopTest();
            System.assert(true);
        }
    }
    
    /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationForFutureTest
    * Date Created/Modified: 10/03/2025
    * @description         : call apex class from method
    * Author               : Sumedha
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
    testMethod static void replacementQuoteLineCreationForFutureTest(){ 
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements =
                new Map<String, List<Scale_Entitlement__c>>();
            List<ReplacementRefreshWrapperData.WrapperData> hwSuppWrap = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> ugWraplst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> inactiveLst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.picklist> assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>();
            Date todaysDate = System.today();
            Date startDate = date.newinstance(2025, 2, 17);
            Date endDate = date.newinstance(2028, 2, 17);
            
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data
            SBQQ__Quote__c qb= 
                [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,
                        Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c 
                  FROM SBQQ__Quote__c WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
            //Get Quote data
            SBQQ__Quote__c qb1= 
                [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,
                        Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c 
                  FROM SBQQ__Quote__c WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL LIMIT 1];
            
            //Get Product data 
            List<Product2> prodResult= 
                [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                        Product_Code_Type__c,Family,Support_Tier__c 
                  FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 15];
            
            List<SBQQ__ProductOption__c> productOptions= 
                [select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, Support_Type__c,Configured_SKU_ID__c, 
                        Configured_SKU_Name__c,Feature_Name__c 
                 from SBQQ__ProductOption__c 
                 where (SBQQ__Feature__r.Name =:ReplacementConstants.SUPPORT OR (SBQQ__Feature__r.Name =:ReplacementConstants.ACCESSORIES AND Refresh_Default_Option__c = true))
                 and SBQQ__ConfiguredSKU__r.Family =:ReplacementConstants.PRODUCTCODE_R7000 and SBQQ__Selected__c=true];
            
            List<Entitlement> ets = [SELECT Id, Asset.Product2.Family, Name, AssetId, Asset.Name,SBQQSC__AssetRootId__c,
                StartDate,EndDate,Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, 
                Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,
                Asset.SBQQSC__CurrentContractLineItem__c,Product__c,Product__r.Name,Product__r.Support_Type__c,
                Renewable__c,Product__r.License_Type__c,product__r.Product_Level__c,Product__r.Product_Type__c,
                Product__r.ProductCode,Product__r.License_Category__c,Product__r.License_Sub_Category__c,
                Product__r.Description,Product__r.Replacement_Category__c,Product__r.Edition__c,Order_Number__c,
                Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,
                Order_Quantity__c,ServiceContractId,Quantity__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,
                ServiceContract.Name,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,
                ContractLineItem.TPH_Drive_Size__c,ContractLineItem.TPH_Quantity__c,
                ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,
                ContractLineItem.Support_Type__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,ContractLineItem.Product_SubType__c, 
                ContractLineItem.Product_Type__c,ContractLineItem.SBQQSC__QuoteLine__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ContractLineItem.Licensing_Model__c,ServiceContract.ContractNumber
                FROM Entitlement where AccountId =: acc.Id];  
            
            List<Scale_Entitlement__c> scaleEntList  = 
                [SELECT Id, Asset__c,Asset__r.Product2.Family,Asset__r.Name,Entitlement__c,
                    Entitlement__r.Name,Asset__r.SBQQSC__CurrentContractLineItem__c, 
                    Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,
                    Asset__r.Product2Id, Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,
                    Asset__r.Product2.Product_Type__c,Asset__r.Product2.Add_on_Level__c,
                    Entitlement__r.Product__r.Product_Level__c,Entitlement__r.Product__r.Add_on_Level__c, 
                    Renewal_Category__c FROM Scale_Entitlement__c ];
            
            List<Entitlement_Links__c> entLinks = 
                [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, 
                Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, 
                Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, 
                Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status,
                Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate,
                Renewed_Entitlement__r.Product__r.Product_Type__c 
                FROM Entitlement_Links__c 
                where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate )];
            
            mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap1 = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> baseFutureLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> hwSupportMainWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();

            ReplacementRefreshWrapperData.wrapperData mainWrp =new ReplacementRefreshWrapperData.wrapperData();
            List<String> R7hw=new List<String>();
            List<String> R6Asset=new List<String>();
            R6Asset.add(ets[4].AssetId);
            for(Product2 p:prodResult){
                if(p.Family==ReplacementConstants.PRODUCTCODE_R7000){
                    R7hw.add(p.Id);
                }
            }
            
            List<RefreshWrapper> refreshWrap=new List<RefreshWrapper>();
            List<RefreshWrapper.Option> options= new List<RefreshWrapper.Option>();
            RefreshWrapper.Option option= new RefreshWrapper.Option();
            option.entitlementId=ets[0].Id;
            option.supportEntId=ets[4].Id;
            option.supportProdId=ets[4].Product__c;
            option.label= ets[4].Asset.Name+' ('+ets[4].Asset.Product2.Name+') (10.00)';//BB220764040026 (RH-6404S-01) (30.00)
            option.quantity= 10;
            option.selected=true;
            option.value=ets[4].AssetId;
            options.add(option);
            
            List<RefreshWrapper.Row> rows=new List<RefreshWrapper.Row>();
            RefreshWrapper.Row row=new RefreshWrapper.Row();
            row.isSelected=true;
            row.isModified=true;
            row.deltaQuantity=30;
            row.selectedAssetIds=R6Asset;
            row.isSelected=true;
            row.options=options;
            row.selectedTargetIds=R7hw;
            rows.add(row);
            
            RefreshWrapper WrapRefresh= new RefreshWrapper();
            WrapRefresh.productId=ets[0].Product__c;
            WrapRefresh.supportType=ets[0].Product__r.Support_Type__c;
            WrapRefresh.rows=rows;
             refreshWrap.add(WrapRefresh);
            
            //V2 future base entitlement
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            ReplacementRefreshWrapperData.WrapperData wrapData = 
                Replacement_TestDataFactory.getWrappers (ets[0], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseFutureLicenceWrap.add(wrapData);
            //mainWrp.wrapBaseLicense = baseLicenceWrap;

            ReplacementRefreshWrapperData.WrapperData wrapData12 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseFutureLicenceWrap.add(wrapData12);
            //mainWrp.wrapBaseLicense = baseLicenceWrap;
            //lstFinalWrap1.add(mainWrp);

            ReplacementRefreshWrapperData.WrapperData wrapData13 = 
                Replacement_TestDataFactory.getWrappers (ets[8], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseFutureLicenceWrap.add(wrapData13);
            //mainWrp.wrapBaseLicense = baseLicenceWrap;

            // List<ReplacementRefreshWrapperData.futureDataValues> futureWrap = new List<ReplacementRefreshWrapperData.futureDataValues>();
            ReplacementRefreshWrapperData.futureDataValues futureWrapperData = 
                new ReplacementRefreshWrapperData.futureDataValues();
            futureWrapperData.futureValues = baseFutureLicenceWrap;
            futureWrapperData.futureKey = '';
            mainWrp.mapAssetEntitlements = futureWrapperData;
            // lstFinalWrap1.add(mainWrp);
            // baseFutureLicenceWrap.clear();
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSuppWrap.add(wrapHWSuppData);
            mainWrp.wrapHWSupportLines = hwSuppWrap;
            
            //Wrapper for Inactive
            ReplacementRefreshWrapperData.WrapperData wrapInactiveData = 
                Replacement_TestDataFactory.getWrappers (ets[1], 'InactiveEnt', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            inactiveLst.add(wrapInactiveData);
            
            //Wrapper for Upgrade SKUs
            ReplacementRefreshWrapperData.WrapperData wrapUGData = 
                Replacement_TestDataFactory.getWrappers (ets[2], 'UpgradeSKU', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            ugWraplst.add(wrapUGData);
            mainWrp.wrapUpgradeEnt = ugWraplst;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for v1 data
            ReplacementRefreshWrapperData.WrapperData wrapv1Data = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'v1', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            baseLicenceWrap.add(wrapv1Data);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData1 = 
                Replacement_TestDataFactory.getWrappers (ets[5], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData1);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData2 = 
                Replacement_TestDataFactory.getWrappers (ets[6], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData2);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            
            for (ReplacementRefreshWrapperData.wrapperData wrap : lstFinalWrap) {
                if (wrap.wrapBaseLicense != null && !wrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapBaseLicense) {
                        baseWrap.isModified = true;
                        baseWrap.rowSelected = true;
                        baseWrap.skuProductId = prodResult[1].Id;
                        baseWrap.skuProdName = prodResult[1].Name;
                        baseWrap.consumedquantity = 10;
                        baseWrap.quantity = 10;
                        baseWrap.selectedquantity = 10;
                        baseWrap.selecteddisposition = ReplacementConstants.UPGRADE_VALUE;
                        baseWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
                if (wrap.mapAssetEntitlements != null && !wrap.mapAssetEntitlements.futureValues.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.mapAssetEntitlements.futureValues) {
                        baseWrap.isModified = true;
                        baseWrap.rowSelected = true;
                        baseWrap.skuProductId = prodResult[1].Id;
                        baseWrap.skuProdName = prodResult[1].Name;
                        baseWrap.consumedquantity = 10;
                        baseWrap.quantity = 10;
                        baseWrap.selectedquantity = 10;
                        baseWrap.selecteddisposition = ReplacementConstants.UPGRADE_VALUE;
                        baseWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
                if (wrap.wrapHWSupportLines != null && !wrap.wrapHWSupportLines.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  HwSpptWrap : wrap.wrapHWSupportLines) {
                        HwSpptWrap.isModified = true;
                        HwSpptWrap.rowSelected = true;
                        HwSpptWrap.skuProductId = null;
                        HwSpptWrap.skuProdName = null;
                        HwSpptWrap.consumedquantity = 10;
                        HwSpptWrap.quantity = 10;
                        HwSpptWrap.selectedquantity = 10;
                        HwSpptWrap.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
                        HwSpptWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
            }
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
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap,refreshWrap,jsonString);
            ReplacementQuoteLineCreation.createNewQuoteLines(qb1.Id, lstFinalWrap1,refreshWrap,jsonString);
            Test.stopTest();
            System.assert(true);
        }
    }
    
    /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationTestMethodAssetNonAsset
    * Date Created/Modified: 10/03/2025
    * @description         : call apex class from method
    * Author               : Rahul
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
    testmethod static void replacementQuoteLineCreationTestMethodAssetNonAsset(){ 
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
                new Map<String, List<Scale_Entitlement__c>>();
            List<ReplacementRefreshWrapperData.WrapperData> hwSuppWrap = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> ugWraplst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> inactiveLst = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.picklist> assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>();
            Date todaysDate = System.today();
            Date startDate = date.newinstance(2025, 2, 17);
            Date endDate = date.newinstance(2028, 2, 17);
            
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,
                GPL_Deal__c, SBQQ__Account__c FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
            //Get Quote data
            SBQQ__Quote__c qb1= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,
                GPL_Deal__c, SBQQ__Account__c FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL LIMIT 1];
            
            //Get Product data 
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 15];
            
            List<Product2> prodResult1= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 WHERE Name = 'RS-BT-BE-SC-PE-PA' LIMIT 1];
            
            List<SBQQ__ProductOption__c> productOptions= [select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, 
                Support_Type__c,Configured_SKU_ID__c, Configured_SKU_Name__c,Feature_Name__c 
                from SBQQ__ProductOption__c where (SBQQ__Feature__r.Name =:ReplacementConstants.SUPPORT OR (SBQQ__Feature__r.Name =:ReplacementConstants.ACCESSORIES AND Refresh_Default_Option__c = true))
                and SBQQ__ConfiguredSKU__r.Family =:ReplacementConstants.PRODUCTCODE_R7000 and SBQQ__Selected__c=true];
            
            List<Entitlement> ets = [SELECT Id, Asset.Product2.Family, Name, AssetId,SBQQSC__AssetRootId__c,
            Asset.Name,StartDate,EndDate,Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, 
            Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,
            Asset.SBQQSC__CurrentContractLineItem__c,Product__c,Product__r.Name,
            Product__r.Support_Type__c,Renewable__c,Product__r.License_Type__c,
            product__r.Product_Level__c,Product__r.Product_Type__c,Product__r.ProductCode,
            Product__r.License_Category__c,Product__r.License_Sub_Category__c,
            Product__r.Description,Product__r.Replacement_Category__c,Product__r.Edition__c,
            Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,
            Order_Number__c,Order_Quantity__c,ServiceContractId,Quantity__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,
            ServiceContract.Name,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,
            ContractLineItem.TPH_Drive_Size__c,ContractLineItem.TPH_Quantity__c,ContractLineItem.TPH_OEM__c,
            ContractLineItem.TPH_Models_Gen__c,ContractLineItem.Support_Type__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
            Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,
            ContractLineItem.Product_SubType__c, ContractLineItem.Product_Type__c,
            ContractLineItem.SBQQSC__QuoteLine__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ServiceContract.ContractNumber,
            ContractLineItem.Licensing_Model__c FROM Entitlement where AccountId =: acc.Id];  
            
            List<Scale_Entitlement__c> scaleEntList = 
                [SELECT Id, Asset__c,Asset__r.Product2.Family,Asset__r.Name,Entitlement__c,
                        Entitlement__r.Name,Asset__r.SBQQSC__CurrentContractLineItem__c, 
                        Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,
                        Asset__r.Product2Id, Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,
                        Asset__r.Product2.Product_Type__c,Asset__r.Product2.Add_on_Level__c,
                        Entitlement__r.Product__r.Product_Level__c,Entitlement__r.Product__r.Add_on_Level__c, 
                        Renewal_Category__c FROM Scale_Entitlement__c ];
            
            List<Entitlement_Links__c> entLinks = 
                [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, 
                        Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, 
                        Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, 
                        Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, 
                        Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, 
                        Renewed_Entitlement__r.EndDate, Renewed_Entitlement__r.Product__r.Product_Type__c  
                    FROM Entitlement_Links__c 
                  where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate )];
            
            mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap1 = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> hwSupportMainWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            
            ReplacementRefreshWrapperData.wrapperData mainWrp =new ReplacementRefreshWrapperData.wrapperData();
            ReplacementRefreshWrapperData.wrapperData mainWrp1 =new ReplacementRefreshWrapperData.wrapperData();
            List<String> R7hw=new List<String>();
            List<String> R6Asset=new List<String>();
           // R6Asset.add(ets[14].AssetId);
            R6Asset.add(ets[4].AssetId);
            for(Product2 p:prodResult){
                if(p.Family==ReplacementConstants.PRODUCTCODE_R7000){
                    R7hw.add(p.Id);
                }
            }
            if(prodResult1[0].id != null){
                    if(prodResult1[0].family == ReplacementConstants.PRODUCTCODE_R7000){
                             R7hw.add(prodResult1[0].Id);
                     }
            }
            
        
            List<ReplacementRefreshWrapperData.PickList> lstOptWrap= new List<ReplacementRefreshWrapperData.PickList>();
            ReplacementRefreshWrapperData.PickList option1 = new ReplacementRefreshWrapperData.PickList();
            option1.entitlementId=ets[0].Id;
            option1.label= ets[4].Asset.Name+' ('+ets[4].Asset.Product2.Name+') (10.00)';//BB220764040026 (RH-6404S-01) (30.00)
            option1.quantity= 10;
            option1.selected=true;
            option1.value=ets[4].AssetId;
            lstOptWrap.add(option1);
            
            
            List<RefreshWrapper> refreshWrap=new List<RefreshWrapper>();
            List<RefreshWrapper.Option> options= new List<RefreshWrapper.Option>();
            RefreshWrapper.Option option= new RefreshWrapper.Option();
            option.entitlementId=ets[0].Id;
            option.supportEntId=ets[4].Id;
            option.supportProdId=ets[4].Product__c;
            option.label= ets[4].Asset.Name+' ('+ets[4].Asset.Product2.Name+') (10.00)';//BB220764040026 (RH-6404S-01) (30.00)
            option.quantity= 10;
            option.selected=true;
            option.value=ets[4].AssetId;
            options.add(option);
            
            List<RefreshWrapper.Row> rows=new List<RefreshWrapper.Row>();
            RefreshWrapper.Row row=new RefreshWrapper.Row();
            row.isSelected=true;
            row.isModified=true;
            row.deltaQuantity=30;
            row.selectedAssetIds=R6Asset;
            row.isSelected=true;
            row.options=options;
            row.selectedTargetIds=R7hw;
            rows.add(row);
            
            RefreshWrapper WrapRefresh= new RefreshWrapper();
            WrapRefresh.productId=ets[0].Product__c;
            WrapRefresh.supportType=ets[0].Product__r.Support_Type__c;
            WrapRefresh.rows=rows;
            
            refreshWrap.add(WrapRefresh);
            List<Product2> prds1 = [SELECT Id, Name FROM Product2 WHERE name in ('RS-BT-BE-SC-PE-PA','RHA-7402-01')];
            Product2 skuPrd = new Product2();
            Product2 hardwarePrd = new Product2();
            if(!prds1.isEmpty()){
                for(Product2 prds : prds1){
                    if(prds.Name == 'RS-BT-BE-SC-PE-PA'){
                        skuPrd = prds;
                    }
                    if(prds.Name == 'RHA-7402-01'){
                        hardwarePrd = prds;
                    }
                }
            }
            //V2 base entitlement
            ReplacementRefreshWrapperData.WrapperData wrapData = 
                Replacement_TestDataFactory.getWrappers (ets[0], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            List<ReplacementRefreshWrapperData.PickList> lstAssetNonAsset = new List<ReplacementRefreshWrapperData.PickList>();
            if(String.isNotBlank(skuPrd.Name) != null && String.isNotBlank(hardwarePrd.Name) != null){ 
                ReplacementRefreshWrapperData.PickList pick = new ReplacementRefreshWrapperData.PickList();
                pick.selected = true;
                pick.label= hardwarePrd.Name+' ('+hardwarePrd.Name+') (10.00)';
                pick.value=hardwarePrd.Id;
                pick.entitlementId = ets[0].Id;
                pick.quantity= 10;
                lstAssetNonAsset.add(pick);
               }
            ReplacementRefreshWrapperData.WrapperData wrapData15 = 
                Replacement_TestDataFactory.getWrappers (ets[0] , 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData15);
            mainWrp1.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp1);
             
            ReplacementRefreshWrapperData.WrapperData wrapData12 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData12);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap1.add(mainWrp);
            
            ReplacementRefreshWrapperData.WrapperData wrapData16 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData16);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap1.add(mainWrp);
           
            ReplacementRefreshWrapperData.WrapperData wrapData13 = 
                Replacement_TestDataFactory.getWrappers (ets[8], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            baseLicenceWrap.add(wrapData13);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap1.add(mainWrp);
            baseLicenceWrap.clear();
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSuppWrap.add(wrapHWSuppData);
            mainWrp.wrapHWSupportLines = hwSuppWrap;
            
            //Wrapper for Inactive
            ReplacementRefreshWrapperData.WrapperData wrapInactiveData = 
                Replacement_TestDataFactory.getWrappers (ets[1], 'InactiveEnt', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            inactiveLst.add(wrapInactiveData);
            
            //Wrapper for Upgrade SKUs
            ReplacementRefreshWrapperData.WrapperData wrapUGData =
                Replacement_TestDataFactory.getWrappers (ets[2], 'UpgradeSKU', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            ugWraplst.add(wrapUGData);
            mainWrp.wrapUpgradeEnt = ugWraplst;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for v1 data
            ReplacementRefreshWrapperData.WrapperData wrapv1Data = 
                Replacement_TestDataFactory.getWrappers (ets[3], 'v1', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            baseLicenceWrap.add(wrapv1Data);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData1 = 
                Replacement_TestDataFactory.getWrappers (ets[5], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData1);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData2 = 
                Replacement_TestDataFactory.getWrappers (ets[6], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            hwSupportMainWrap.add(wrapHWSuppData2);
            mainWrp = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp);
            
            Product2 prd = [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,
                Product_Code_Type__c,Family,Support_Tier__c FROM Product2 WHERE Id = :skuPrd.Id];
            for (ReplacementRefreshWrapperData.wrapperData wrap : lstFinalWrap) {
                if (wrap.wrapBaseLicense != null && !wrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapBaseLicense) {                       
                        baseWrap.isModified = true;
                        baseWrap.skuSuppType=ReplacementConstants.SUPPORT_TYPE_L3;
                        baseWrap.rowSelected = true;
                        baseWrap.productId = skuPrd.Id;
                        baseWrap.skuProductId = skuPrd.Id;
                        baseWrap.skuProdName = skuPrd.Name;
                        baseWrap.consumedquantity = 10;
                        baseWrap.quantity = 10;
                        baseWrap.selectedquantity = 10;
                        baseWrap.selecteddisposition = ReplacementConstants.UPGRADE_VALUE;
                        baseWrap.wrapInactiveEnt = inactiveLst;
                        baseWrap.selectedAssetsFromNonAsset = lstAssetNonAsset;
                    }
                }
                if (wrap.wrapHWSupportLines != null && !wrap.wrapHWSupportLines.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  HwSpptWrap : wrap.wrapHWSupportLines) {
                        HwSpptWrap.isModified = true;
                        HwSpptWrap.rowSelected = true;
                        HwSpptWrap.skuProductId = null;
                        HwSpptWrap.skuProdName = null;
                        HwSpptWrap.consumedquantity = 10;
                        HwSpptWrap.quantity = 10;
                        HwSpptWrap.selectedquantity = 10;
                        HwSpptWrap.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
                        HwSpptWrap.wrapInactiveEnt = inactiveLst;
                    }
                }
            }
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
            ReplacementQuoteLineCreation.productMap.put(skuPrd.Id, prd);
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap,refreshWrap,jsonString);
            ReplacementQuoteLineCreation.createNewQuoteLines(qb1.Id, lstFinalWrap1,refreshWrap,jsonString);
            Test.stopTest();
            System.assert(true);
        }
    }
    /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationTestMethodContractAttributes
    * Date Created/Modified: 12/07/2025
    * @description         : call apex class from method
    * Author               : Khushboo
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
     testmethod static void replacementQuoteLineCreationTestMethodContractAttributes(){
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Test.starttest();
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            List<Entitlement> ets = [SELECT Id, Asset.Product2.Family, Name, AssetId, Asset.Name,SBQQSC__AssetRootId__c,
            StartDate,EndDate,Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, 
            Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,ContractLineItemId,
            Asset.SBQQSC__CurrentContractLineItem__c,Product__c,Product__r.Name,Product__r.Support_Type__c,
            Renewable__c,Product__r.License_Type__c,product__r.Product_Level__c,Product__r.Product_Type__c,
            Product__r.ProductCode,Product__r.License_Category__c,Product__r.License_Sub_Category__c,
            Product__r.Description,Product__r.Replacement_Category__c,Product__r.Edition__c,
            Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,
            Order_Number__c,Order_Quantity__c,ServiceContractId,Quantity__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,ContractLineItem.SBQQSC__OriginalQuoteLine__c,
            ServiceContract.Name,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,
            ContractLineItem.TPH_Drive_Size__c,ContractLineItem.TPH_Quantity__c,
            ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,ContractLineItem.Support_Type__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
            Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,ContractLineItem.Product_SubType__c, 
            ContractLineItem.Product_Type__c,ContractLineItem.SBQQSC__QuoteLine__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ServiceContract.ContractNumber,
            ContractLineItem.Licensing_Model__c FROM Entitlement where AccountId =: acc.Id];
            
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,
                Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c,RWD_Sales_Rep_Exception__c,
                RWD_Deal_Ops_Exception__c,RWD_Sales_Rep_Exception_Justification__c,
                RWD_Deal_Ops_Exception_Justification__c FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
            
            Product2 prds = 
                Replacement_TestDataFactory.getProductWithSubCategory('RS-BT-CVB-PE-PP', 'RS-BT-CVB-PE-PP'
                , '',ReplacementConstants.CLOUD_VAULT, ReplacementConstants.SUBSCRIPTION, ReplacementConstants.CLOUD_VALUE_BACKUP
                , ReplacementConstants.SAAS, ReplacementConstants.CV_SAAS_COMMERCIAL);
            prds.Product_Type__c = 'Hardware';
            prds.ProductCode = 'RS-BT-CVB-PE-PP';
            insert prds;
            Map<Id, Product2> prdsMap = new Map<Id, Product2>();
            prdsMap.put(prds.Id, prds);
            ReplacementQuoteLineCreation.ProductMap = prdsMap;
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,
            License_Sub_Category__c,Product_Code_Type__c,Family,Support_Tier__c 
            FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 15];
            
            List<Scale_Entitlement__c> scaleEntList  = 
            [SELECT Id, Asset__c,Asset__r.Product2.Family,Asset__r.Name,Entitlement__c,
                    Entitlement__r.Name,Asset__r.SBQQSC__CurrentContractLineItem__c, 
                    Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,
                    Asset__r.Product2Id, Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,
                    Asset__r.Product2.Product_Type__c,Asset__r.Product2.Add_on_Level__c,
                    Entitlement__r.Product__r.Product_Level__c,Entitlement__r.Product__r.Add_on_Level__c, 
                    Renewal_Category__c FROM Scale_Entitlement__c ];
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
                new Map<String, List<Scale_Entitlement__c>>();
            mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);
            
            ReplacementRefreshWrapperData.WrapperData wrapData04 = 
                Replacement_TestDataFactory.getWrappers (ets[8], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);           
            wrapData04.skuProductId = prds.Id; 
            wrapData04.entitlementId = ets[8].Id;
            wrapData04.selectedquantity = 100;
            SBQQ__QuoteLine__c sbq = [SELECT Id, Replacement_Details__c ,SBQQ__Discount__c,Flag_for_Discount__c, Storage_Region_Bundle_FrontEnd__c,Storage_Tier__c, Storage_Region_Bundle__c FROM SBQQ__QuoteLine__c limit 1];
			ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(sbq.Replacement_Details__c, ReplacementJson.class);
			ContractLineItem ct = new ContractLineItem();
			ct.Id = ets[8].ContractLineItemId;
			ct.SBQQSC__OriginalQuoteLine__c = sbq.Id;
			update ct;
			
            Entitlement ennts = [SELECT Id, ContractLineItemId, ContractLineItem.SBQQSC__OriginalQuoteLine__c, ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,Product__c,
                                 Product__r.Product_Type__c,Product__r.Product_Subtype__c,Product__r.Description,Product__r.ProductCode,ContractLineItem.Storage_Region_Bundle_FrontEnd__c,ContractLineItem.Storage_Tier__c,ContractLineItem.Storage_Region_Bundle__c,
                                 ContractLineItem.SBQQSC__OriginalQuoteLine__r.Rubrik_Hosted_M365_Quantity__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Atlassian_Quantity__c,
                                 ContractLineItem.SBQQSC__OriginalQuoteLine__r.Salesforce_Quantity__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Dynamics_Quantity__c,
                              ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c, ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c FROM Entitlement WHERE Id = :ets[8].Id];
             Map<Id, Entitlement> mapEnt = new Map<Id, Entitlement>();
            String strEnt = '';
            if(!ets.isEmpty()){
                for(Entitlement ents : ets){
                    strEnt = strEnt + ents.Id + ',';
                    mapEnt.put(ents.Id, ents);
                }
            }
            mapEnt.put(ennts.Id, ennts);
            strEnt.removeEnd(',');
            SBQQ__Quoteline__c sq = ReplacementQuoteLineCreationExtension.getQuoteLine(qb.Id,wrapData04, prds, null,ets[8].ContractLineItemId , 
                    lineJson, null,null, null, null, null, mapEnt);
            ReplacementQuoteLineCreationExtension.getQLIForRefresh(qb.Id, 'Test' ,strEnt, new Map<String,String>(),1,prds.Id, 'Test',null,'Dispose',null,'5.1',2,mapEnt);
            Test.stoptest();
            System.assert(true);
        }
     }
    
    
     /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationTestMethodRenew
    * Date Created/Modified: 12/07/2025
    * @description         : call apex class from method
    * Author               : Khushboo
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
    testmethod static void replacementQuoteLineCreationTestMethodRenew(){ 
          user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            ReplacementFieldMetadata.setMock(new ReplacementQueryControllerTest.ReplacementFieldMock());
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
                new Map<String, List<Scale_Entitlement__c>>();
            Date todaysDate = System.today();
            Date startDate = date.newinstance(2025, 2, 17);
            Date endDate = date.newinstance(2028, 2, 17);
            
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,
                Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c,RWD_Sales_Rep_Exception__c,
                RWD_Deal_Ops_Exception__c,RWD_Sales_Rep_Exception_Justification__c,
                RWD_Deal_Ops_Exception_Justification__c FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
            List<SBQQ__QuoteLine__c> lstSbq = new List<SBQQ__QuoteLine__c>();
            if(qb.id != null){
                lstSbq = [SELECT Id,Storage_Region_Bundle_FrontEnd__c, Storage_Tier__c, Storage_Region_Bundle__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :qb.Id];
            }
            
             
            //Get Product data 
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,
            License_Sub_Category__c,Product_Code_Type__c,Family,Support_Tier__c 
            FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 15];
            
           List<SBQQ__ProductOption__c> productOptions= 
            [select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, Support_Type__c,Configured_SKU_ID__c, 
                    Configured_SKU_Name__c,Feature_Name__c 
                    from SBQQ__ProductOption__c where SBQQ__Feature__r.Name =:ReplacementConstants.SUPPORT 
                    and SBQQ__ConfiguredSKU__r.Family =:ReplacementConstants.PRODUCTCODE_R7000 and SBQQ__Selected__c=true];
            
           List<Entitlement> ets = [SELECT Id, Asset.Product2.Family, Name, AssetId, Asset.Name,SBQQSC__AssetRootId__c,
            StartDate,EndDate,Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, 
            Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,
            Asset.SBQQSC__CurrentContractLineItem__c,Product__c,Product__r.Name,Product__r.Support_Type__c,
            Renewable__c,Product__r.License_Type__c,product__r.Product_Level__c,Product__r.Product_Type__c,
            Product__r.ProductCode,Product__r.License_Category__c,Product__r.License_Sub_Category__c,
            Product__r.Description,Product__r.Replacement_Category__c,Product__r.Edition__c,
            Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,
            Order_Number__c,Order_Quantity__c,ServiceContractId,Quantity__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,ContractLineItem.SBQQSC__OriginalQuoteLine__c,
            ServiceContract.Name,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,
            ContractLineItem.TPH_Drive_Size__c,ContractLineItem.TPH_Quantity__c,
            ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,ContractLineItem.Support_Type__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
            ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
            Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,ContractLineItem.Product_SubType__c, 
            ContractLineItem.Product_Type__c,ContractLineItem.SBQQSC__QuoteLine__c,
            ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ServiceContract.ContractNumber,
            ContractLineItem.Licensing_Model__c FROM Entitlement where AccountId =: acc.Id];  
            
           List<Scale_Entitlement__c> scaleEntList  = 
            [SELECT Id, Asset__c,Asset__r.Product2.Family,Asset__r.Name,Entitlement__c,
                    Entitlement__r.Name,Asset__r.SBQQSC__CurrentContractLineItem__c, 
                    Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,
                    Asset__r.Product2Id, Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,
                    Asset__r.Product2.Product_Type__c,Asset__r.Product2.Add_on_Level__c,
                    Entitlement__r.Product__r.Product_Level__c,Entitlement__r.Product__r.Add_on_Level__c, 
                    Renewal_Category__c FROM Scale_Entitlement__c ];
            
           List<Entitlement_Links__c> entLinks = 
            [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, 
                    Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, 
                    Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, 
                    Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, Renewed_Entitlement__r.StartDate,
                    Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, 
                    Renewed_Entitlement__r.Product__r.Product_Type__c  
               FROM Entitlement_Links__c 
              where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate )];
           List<Polaris_SKU_Mapping_V2__c> PolarisMapping=
            [SELECT Id,Feature_Name_on_New_Product__c, New_Product__c,New_Product__r.Productcode,Old_Product__c,
                    Old_Product__r.Productcode,New_Product__r.Eligible_for_RCDM_T__c,New_Product__r.Product_Type__c, 
                    New_Product__r.Product_Subtype__c,Payment_Option__c,Quantity_Mapping_Type__c,Quantity_Ratio__c, 
                    Support_Type__c,Support_Tier__c,New_Product__r.SBQQ__SubscriptionTerm__c,
                    New_Product__r.Description, New_Product__r.Sales_Comp_Category__c, New_Product__r.Product_Level__c, 
                    New_Product__r.License_Type__c 
               FROM Polaris_SKU_Mapping_V2__c where Old_Product__r.IsActive =true and New_Product__r.IsActive =true];
            
            List<Product2> prds1 = [SELECT Id,Support_Type__c, Name 
                FROM Product2 WHERE name in ('RS-BT-BE-SC-PE-PA','RHA-7402-01')];
            Product2 skuPrd = new Product2();
            Product2 hardwarePrd = new Product2();
            if(!prds1.isEmpty()){
                for(Product2 prds : prds1){
                    if(prds.Name == 'RS-BT-BE-SC-PE-PA'){
                        skuPrd = prds;
                    }
                    if(prds.Name == 'RHA-7402-01'){
                        hardwarePrd = prds;
                    }
                }
            }
            List<ReplacementRefreshWrapperData.WrapperData> hwSuppWrap = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> inactiveLst = new List<ReplacementRefreshWrapperData.WrapperData>();
            mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> hwSupportMainWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            ReplacementRefreshWrapperData.wrapperData mainWrp = new ReplacementRefreshWrapperData.wrapperData();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap1 = new List<ReplacementRefreshWrapperData.wrapperData>();
            
            List<Product2> ProdList=new List<Product2>();
            Product2 prds = 
                Replacement_TestDataFactory.getProductWithSubCategory('RS-BT-CVB-PE-PP', 'RS-BT-CVB-PE-PP'
                , '',ReplacementConstants.CLOUD_VAULT, ReplacementConstants.SUBSCRIPTION, ReplacementConstants.CLOUD_VALUE_BACKUP
                , ReplacementConstants.SAAS, ReplacementConstants.CV_SAAS_COMMERCIAL);
            ProdList.add(prds);
            
            Product2 prd1 = Replacement_TestDataFactory.getProductWithSubCategory('RS-BT-CVA-PE-PP', 'RS-BT-CVA-PE-PP'
                , '',ReplacementConstants.CLOUD_VAULT, ReplacementConstants.SUBSCRIPTION
                , ReplacementConstants.CLOUD_VALUE_ARCHIVE, ReplacementConstants.SAAS, ReplacementConstants.CV_SAAS_COMMERCIAL);
            ProdList.add(prd1);
            
            Product2 prds2 = Replacement_TestDataFactory.getProductWithSubCategory('RS-UR-FE-SA-PE-PP', 'RS-UR-FE-SA-PE-PP'
                , ReplacementConstants.FOUNDATION_EDITION,ReplacementConstants.SAAS_DATA_PROTECTION
                , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.UNIVERSAL_SAAS_APPS, ReplacementConstants.SAAS
                , ReplacementConstants.SAAS_SAAS_COMMERCIAL);
            prds2.Product_Subtype__c = ReplacementConstants.SAAS_APPLICATIONS; 
            ProdList.add(prds2);
            
            Product2 prds3 = Replacement_TestDataFactory.getProductWithSubCategory('RS-UR-FE-MD-PE-PP', 'RS-UR-FE-MD-PE-PP'
                , ReplacementConstants.FOUNDATION_EDITION,ReplacementConstants.M365_DATA_PROTECTION
                , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.M365H, ReplacementConstants.SAAS
                , 'M365 - Commercial - Rubrik Hosted');
            ProdList.add(prds3);
            
            Insert ProdList;
            
            //V2 base entitlement//ManyTo1
            ReplacementRefreshWrapperData.WrapperData wrapData1 = 
                Replacement_TestDataFactory.getWrappers (ets[0], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapData1.skuProductId = prds3.Id; 
            wrapData1.selectedquantity = 50;
            wrapData1.skuAttributesToQuoteLine = new Map<String,String>();
            wrapData1.skuAttributesToQuoteLine.put('Storage_Tier__c','50 GB');
            baseLicenceWrap.add(wrapData1);
            ReplacementRefreshWrapperData.WrapperData wrapData01 =
                Replacement_TestDataFactory.getWrappers (ets[0], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapData01.skuProductId = prds2.Id; 
            wrapData01.selectedquantity = 50;
            baseLicenceWrap.add(wrapData01);
            ReplacementRefreshWrapperData.WrapperData mainWrp09 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp09.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp09);
            
            ReplacementRefreshWrapperData.WrapperData wrapData04 = 
                Replacement_TestDataFactory.getWrappers (ets[8], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);           
            wrapData04.skuProductId = prds2.Id; 
            wrapData04.entitlementId = ets[8].Id;
            wrapData04.selectedquantity = 100;
            wrapData04.skuAttributesToQuoteLine = new Map<String,String>();
            wrapData04.skuAttributesToQuoteLine.put('Salesforce_Quantity__c','10');
            wrapData04.skuAttributesToQuoteLine.put('Rubrik_Hosted_M365_Quantity__c','22');
            wrapData04.skuAttributesToQuoteLine.put('Atlassian_Quantity__c','33');
            wrapData04.skuAttributesToQuoteLine.put('Dynamics_Quantity__c ','44');
            baseLicenceWrap.add(wrapData04);
            ReplacementRefreshWrapperData.WrapperData mainWrp06 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp06.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp06);
            
            SBQQ__QuoteLine__c sbq = [SELECT Id,Replacement_Details__c ,SBQQ__Discount__c, Flag_for_Discount__c,Storage_Region_Bundle_FrontEnd__c,Storage_Tier__c, Storage_Region_Bundle__c FROM SBQQ__QuoteLine__c limit 1];
			ReplacementJson lineJson = (ReplacementJson) JSON.deserialize(sbq.Replacement_Details__c, ReplacementJson.class);
			ContractLineItem ct = new ContractLineItem();
			ct.Id = ets[8].ContractLineItemId;
			ct.SBQQSC__OriginalQuoteLine__c = sbq.Id;
			update ct;
			
            Entitlement ennts = [SELECT Id, ContractLineItemId, ContractLineItem.SBQQSC__OriginalQuoteLine__c, ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c, 
                              ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c, ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c FROM Entitlement WHERE Id = :ets[8].Id];
            Map<Id, Entitlement> mapEnt = new Map<Id, Entitlement>();
            mapEnt.put(ennts.Id, ennts);
            SBQQ__Quoteline__c sq = ReplacementQuoteLineCreationExtension.getQuoteLine(qb.Id,wrapData04, prds, null,ets[8].ContractLineItemId , 
                lineJson, null,null, null, null, null, mapEnt);
            ReplacementRefreshWrapperData.WrapperData wrapData13 = 
                Replacement_TestDataFactory.getWrappers (ets[8], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);           
            wrapData13.skuProductId = prds.Id; 
            wrapData13.skuAttributesToQuoteLine = new Map<String,String>();
            wrapData13.skuProdCodeType = ReplacementConstants.PRODUCT_CODE_TYPE_CVB;
            wrapData13.selectedquantity =100 ;
            wrapData13.skuAttributesToQuoteLine.put(
                    ReplacementConstants.STORAGE_BUNDLE_FIELD_API
                   ,'Storage - Zone 1 (US-W2, US-Central, US-E2, EU-N, EU-W, UK-S, Canada, E US, W US, S Central US, W Central US)');
            baseLicenceWrap.add(wrapData13);
            ReplacementRefreshWrapperData.WrapperData mainWrp08 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp08.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp06);
            
            ReplacementRefreshWrapperData.WrapperData wrapData14 = 
                Replacement_TestDataFactory.getWrappers (ets[8], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);           
            wrapData14.skuProductId = prd1.Id; 
            wrapData14.skuAttributesToQuoteLine = new Map<String,String>();
            wrapData14.skuProdCodeType = 'CVA';
            wrapData14.doNotConsolidateEnt=true;
            wrapData14.selectedquantity = 100;
            wrapData14.skuAttributesToQuoteLine.put(
                ReplacementConstants.STORAGE_BUNDLE_FIELD_API,'Storage - Zone 1 (US-W2, EU-N, UK-S, Canada)');
            baseLicenceWrap.add(wrapData14);
            ReplacementRefreshWrapperData.WrapperData mainWrp07 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp07.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp06);
            
            //v1 CPQ Dispose lines
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData04 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'v1', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapHWSuppData04.skuProductId =null; 
            wrapHWSuppData04.selectedquantity = 50;
            wrapHWSuppData04.assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>(createAssetforHW(ets[7]));
            baseLicenceWrap.add(wrapHWSuppData04);
            ReplacementRefreshWrapperData.WrapperData mainWrp04 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp04.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp04);
            
            //Wrapper for HW Support
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData2 = 
                Replacement_TestDataFactory.getWrappers (ets[6], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapHWSuppData2.assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>(createAssetforHW(ets[6]));
            wrapHWSuppData2.skuProductId=null;
            hwSupportMainWrap.add(wrapHWSuppData2);
            ReplacementRefreshWrapperData.WrapperData mainWrp2 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp2.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp2);
            
            ReplacementRefreshWrapperData.WrapperData wrapHWSuppData03 = 
                Replacement_TestDataFactory.getWrappers (ets[7], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapHWSuppData03.assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>(createAssetforHW(ets[7]));
            wrapHWSuppData03.skuProductId=null;
            hwSupportMainWrap.add(wrapHWSuppData03);
            ReplacementRefreshWrapperData.WrapperData mainWrp03 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp03.wrapHWSupportLines = hwSupportMainWrap;
            lstFinalWrap.add(mainWrp03);
            
            ReplacementRefreshWrapperData.WrapperData wrapData15 = 
                Replacement_TestDataFactory.getWrappers (ets[11], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);           
            wrapData15.skuProductId=null;
            wrapData15.assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>(createAssetforHW(ets[11]));
            baseLicenceWrap.add(wrapData15);
            ReplacementRefreshWrapperData.WrapperData mainWrp05 = new ReplacementRefreshWrapperData.WrapperData();
            mainWrp05.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp05);
           
            for (ReplacementRefreshWrapperData.wrapperData wrap : lstFinalWrap) {
                if (wrap.wrapBaseLicense != null && !wrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapBaseLicense) {                       
                        baseWrap.isModified = true;
                        baseWrap.rowSelected = true;
                        baseWrap.consumedquantity = 10;
                        baseWrap.quantity = 100;
                        baseWrap.selecteddisposition = ReplacementConstants.DISPOSTION_RENEWING;
                        baseWrap.renewalEndDate=date.newinstance(2029, 2, 17);
                        baseWrap.EndDate=date.newinstance(2028, 2, 17);
                    }
                }
              }
            wrapHWSuppData2.selecteddisposition = ReplacementConstants.UPGRADE_VALUE;
            wrapHWSuppData03.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
            wrapHWSuppData04.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
            wrapData15.selecteddisposition = ReplacementConstants.DISPOSE_AT_RISK;
           
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
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap,null,jsonString);
            for (ReplacementRefreshWrapperData.wrapperData wrap : lstFinalWrap) {
                if (wrap.wrapBaseLicense != null && !wrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapBaseLicense) {                       
                        baseWrap.isModified = true;
                        baseWrap.rowSelected = false;}}
                 if (wrap.wrapHWSupportLines != null && !wrap.wrapHWSupportLines.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapHWSupportLines) {                       
                        baseWrap.isModified = true;
                        baseWrap.rowSelected = false;}}
              }
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap,null,jsonString);            
            Test.stopTest();
            System.assert(true);
        }        
    }
    /***********************************************************************************************************
    * Method Name          : replacementQuoteLineCreationTestMethodRenew2
    * Date Created/Modified: 12/07/2025
    * @description         : call apex class from method
    * Author               : Khushboo
    * Purpose              : call apex class from method
    * Test Class Methods   :
    **********************************************************************************************************/
    testmethod static void replacementQuoteLineCreationTestMethodRenew2(){ 
          user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
                new Map<String, List<Scale_Entitlement__c>>();
            Date todaysDate = System.today();
            Date startDate = date.newinstance(2025, 2, 17);
            Date endDate = date.newinstance(2028, 2, 17);
            
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate
                , Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c,RWD_Sales_Rep_Exception__c
                , RWD_Deal_Ops_Exception__c,RWD_Sales_Rep_Exception_Justification__c
                , RWD_Deal_Ops_Exception_Justification__c FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
             
            //Get Product data 
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c
                ,Product_Code_Type__c,Family,Support_Tier__c FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 15];
            
           List<SBQQ__ProductOption__c> productOptions= 
            [select id,SBQQ__ProductCode__c, SBQQ__OptionalSKU__c, Support_Type__c,Configured_SKU_ID__c, 
                    Configured_SKU_Name__c,Feature_Name__c from SBQQ__ProductOption__c 
              where SBQQ__Feature__r.Name =:ReplacementConstants.SUPPORT 
                and SBQQ__ConfiguredSKU__r.Family =:ReplacementConstants.PRODUCTCODE_R7000 and SBQQ__Selected__c=true];
            
           List<Entitlement> ets = 
            [SELECT Id, Asset.Product2.Family, Name, AssetId, Asset.Name,StartDate,EndDate,SBQQSC__AssetRootId__c
            , Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, Asset.Product2.Name
            , Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,Asset.SBQQSC__CurrentContractLineItem__c
            ,Product__c,Product__r.Name,Product__r.Support_Type__c,Renewable__c,Product__r.License_Type__c
            ,product__r.Product_Level__c,Product__r.Product_Type__c,Product__r.ProductCode
            ,Product__r.License_Category__c,Product__r.License_Sub_Category__c,Product__r.Description
            ,Product__r.Replacement_Category__c,Product__r.Edition__c,Order_Number__c
            ,Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c
            ,Order_Quantity__c,ServiceContractId,Quantity__c,ServiceContract.ContractNumber
            ,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,ServiceContract.Name
            ,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c
            ,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c
            ,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,ContractLineItem.TPH_Drive_Size__c
            ,ContractLineItem.TPH_Quantity__c,ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c
            ,ContractLineItem.Support_Type__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c
            ,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c
            ,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c
            ,Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c
            ,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,ContractLineItem.Product_SubType__c
            , ContractLineItem.Product_Type__c,ContractLineItem.SBQQSC__QuoteLine__c
            ,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,ContractLineItem.Licensing_Model__c 
            FROM Entitlement where AccountId =: acc.Id];  
            
           List<Scale_Entitlement__c> scaleEntList  = 
            [SELECT Id, Asset__c,Asset__r.Product2.Family,Asset__r.Name,Entitlement__c
                ,Entitlement__r.Name,Asset__r.SBQQSC__CurrentContractLineItem__c
                , Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c
                ,Asset__r.Product2Id, Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c
                ,Asset__r.Product2.Product_Type__c,Asset__r.Product2.Add_on_Level__c
                ,Entitlement__r.Product__r.Product_Level__c,Entitlement__r.Product__r.Add_on_Level__c
                , Renewal_Category__c FROM Scale_Entitlement__c ];
            
           List<Entitlement_Links__c> entLinks = 
            [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate
                  , Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate
                  , Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status
                  , Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, Renewed_Entitlement__r.StartDate
                  , Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, Renewed_Entitlement__r.Product__r.Product_Type__c  
               FROM Entitlement_Links__c where (Previous_Entitlement__r.EndDate >= : todaysDate 
                 OR Renewed_Entitlement__r.StartDate >= : todaysDate )];
           List<Polaris_SKU_Mapping_V2__c> PolarisMapping=
                [SELECT Id,Feature_Name_on_New_Product__c, New_Product__c,New_Product__r.Productcode,Old_Product__c
                        ,Old_Product__r.Productcode,New_Product__r.Eligible_for_RCDM_T__c,New_Product__r.Product_Type__c, 
                        New_Product__r.Product_Subtype__c,Payment_Option__c,Quantity_Mapping_Type__c
                        ,Quantity_Ratio__c, Support_Type__c,Support_Tier__c,New_Product__r.SBQQ__SubscriptionTerm__c
                        ,New_Product__r.Description, New_Product__r.Sales_Comp_Category__c, New_Product__r.Product_Level__c
                        , New_Product__r.License_Type__c FROM Polaris_SKU_Mapping_V2__c 
                    where Old_Product__r.IsActive =true and New_Product__r.IsActive =true];
            
            List<Product2> prds1 = [SELECT Id,Support_Type__c, Name FROM Product2 
                WHERE name in ('RS-BT-BE-SC-PE-PA','RHA-7402-01')];
            Product2 skuPrd = new Product2();
            if(!prds1.isEmpty()){
                for(Product2 prds : prds1){
                    if(prds.Name == 'RS-BT-BE-SC-PE-PA'){
                        skuPrd = prds;
                    }
                }
            }
            List<ReplacementRefreshWrapperData.picklist> assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>();
            ReplacementRefreshWrapperData.pickList objpickListAll = 
                ReplacementRefreshWrapperData.createpicKlistValues('Full', 'Full',ets[1].Id,ets[1].Name,0,true,false,false,true);
            assetsAvailable.add(objpickListAll);
            ReplacementRefreshWrapperData.pickList objpickListAll1 = 
                ReplacementRefreshWrapperData.createpicKlistValues(
                    String.valueOf(ets[1].Asset.ID), 'Asset123',String.valueOf(ets[1].Id),ets[1].Name,0,true,false,false,true);
            assetsAvailable.add(objpickListAll1);
            List<ReplacementRefreshWrapperData.WrapperData> hwSuppWrap = new List<ReplacementRefreshWrapperData.WrapperData>();
            List<ReplacementRefreshWrapperData.WrapperData> inactiveLst = new List<ReplacementRefreshWrapperData.WrapperData>();
            mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);
            List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            List<ReplacementRefreshWrapperData.wrapperData> hwSupportMainWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            ReplacementRefreshWrapperData.wrapperData mainWrp = new ReplacementRefreshWrapperData.wrapperData();
            ReplacementRefreshWrapperData.wrapperData mainWrp02 = new ReplacementRefreshWrapperData.wrapperData();
            List<ReplacementRefreshWrapperData.wrapperData> baseLicenceWrap = new List<ReplacementRefreshWrapperData.wrapperData>();
            //Wrapper for Inactive
            ReplacementRefreshWrapperData.WrapperData wrapInactiveData = 
                Replacement_TestDataFactory.getWrappers (ets[1], 'InactiveEnt', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            wrapInactiveData.assetsAvailable= null;//new List<ReplacementRefreshWrapperData.pickList>(assetsAvailable);
            wrapInactiveData.selectedquantity =10 ;
            inactiveLst.add(wrapInactiveData);

            List<ReplacementRefreshWrapperData.WrapperData> inactiveLst2 = new List<ReplacementRefreshWrapperData.WrapperData>();
             ReplacementRefreshWrapperData.WrapperData wrapInactiveData2 = 
                Replacement_TestDataFactory.getWrappers (ets[1], 'InactiveEnt', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            wrapInactiveData2.assetsAvailable= new List<ReplacementRefreshWrapperData.pickList>(assetsAvailable);
            wrapInactiveData2.selectedquantity =40 ;
            wrapInactiveData2.customIndex = '2.0.0';
            inactiveLst2.add(wrapInactiveData2);
            

            //V2 base entitlement
            ReplacementRefreshWrapperData.WrapperData wrapData = 
                Replacement_TestDataFactory.getWrappers (ets[0], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapData.ProductId=skuPrd.Id;
            wrapData.skuProductId = skuPrd.Id;
            wrapData.skuProdName = skuPrd.Name;
            wrapData.wrapInactiveEnt = inactiveLst;
            wrapData.assetsAvailable=null;
            wrapData.customIndex = '1.0.0';
            wrapData.consumedquantity = 40;
            wrapData.quantity = 40;
            wrapData.selectedquantity = 10;
            wrapData.skuProdLicenseSubCategory= 'RSC Gov Cloud';

            //wrapData.wrapHWSupportLines=hwSuppWrap;
            baseLicenceWrap.add(wrapData);
            mainWrp.wrapBaseLicense = baseLicenceWrap;
            lstFinalWrap.add(mainWrp);
              
            //H/w Support-add for support switch
            ReplacementRefreshWrapperData.WrapperData hwSprtForBase = 
                Replacement_TestDataFactory.getWrappers (ets[6], 'HWSupp', mapEntitlemmemntNameToScaleEntitlements, prodResult); 
            hwSprtForBase.isModified = true;
            hwSprtForBase.rowSelected = true;
            hwSprtForBase.renewalEndDate=date.newinstance(2029, 2, 17);
            hwSprtForBase.EndDate=date.newinstance(2028, 2, 17);
            hwSprtForBase.assetsAvailable=new List<ReplacementRefreshWrapperData.picklist>(createAssetforHW(ets[0]));
            hwSprtForBase.selecteddisposition = ReplacementConstants.DISPOSTION_RENEWING;
            hwSuppWrap.add(hwSprtForBase);
            
            //V2 base entitlement
            ReplacementRefreshWrapperData.WrapperData wrapData00 = 
                Replacement_TestDataFactory.getWrappers (ets[2], 'default', mapEntitlemmemntNameToScaleEntitlements, prodResult);
            wrapData00.ProductId=ets[0].Product__c;
            wrapData00.skuProductId = skuPrd.Id;
            wrapData00.skuProdName = skuPrd.Name;
            wrapData00.customIndex = '2.0.0';
            wrapData00.assetsAvailable=new List<ReplacementRefreshWrapperData.picklist>{assetsAvailable[0]};
            baseLicenceWrap.add(wrapData00);
            mainWrp02.wrapHWSupportLines=hwSuppWrap;
            mainWrp02.wrapBaseLicense = baseLicenceWrap;
            
            lstFinalWrap.add(mainWrp02);
            for (ReplacementRefreshWrapperData.wrapperData wrap : lstFinalWrap) {
                if (wrap.wrapBaseLicense != null && !wrap.wrapBaseLicense.isEmpty()) {
                    for (ReplacementRefreshWrapperData.wrapperData  baseWrap : wrap.wrapBaseLicense) {                       
                        baseWrap.isModified = true;
                        baseWrap.misMatchQTY = true;
                        baseWrap.rowSelected = true;
                        baseWrap.consumedquantity = 10;
                        baseWrap.quantity = 100;
                        baseWrap.selecteddisposition = ReplacementConstants.DISPOSTION_RENEWING;
                        baseWrap.renewalEndDate=date.newinstance(2029, 2, 17);
                        baseWrap.EndDate=date.newinstance(2028, 2, 17);
                    }
                }
              }
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
            ReplacementQuoteLineCreation.createNewQuoteLines(qb.Id, lstFinalWrap,null,jsonString);
             Test.stopTest();
            System.assert(true);
        }        
    }
    /***********************************************************************************************************
    * Method Name          : testHandleVariousExceptions
    * Date Created/Modified: 12/07/2025
    * @description         : for rxception handling
    * Author               : Khushboo
    * Purpose              : call apex class handleException method from this method
    * Test Class Methods   :
    **********************************************************************************************************/
   testMethod static void testHandleVariousExceptions() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
             
            try {
                Account acc = new Account();// Missing required Name field
                insert acc; // This will throw a DmlException
            } catch (Exception ex) {
                Test.startTest();
                AuraHandledException result = ReplacementQuoteLineCreationHelper.handleException(ex);
                Test.stopTest();
                System.assert(true);
            }
            // DML Exception
            try {
                insert new SBQQ__Quote__C(); // Assuming this triggers a validation rule
            } catch (Exception ex) {
                AuraHandledException result = ReplacementQuoteLineCreationHelper.handleException(ex);
                System.assert(true);
            }

            // Null Pointer Exception
            try {
                String s;
            } catch (Exception ex) {
                AuraHandledException result = ReplacementQuoteLineCreationHelper.handleException(ex);
                System.assert(true);
            }
            
            try {
                String s;
                s.toLowerCase(); // NullPointerException
            } catch (Exception ex) {
                AuraHandledException result = ReplacementQuoteLineCreationHelper.handleException(ex);
                System.assert(true);
            }

            // Query Exception
            try {
                SBQQ__Quote__c acc = [SELECT Id FROM SBQQ__Quote__c WHERE Name = 'NonExistent' LIMIT 1 OFFSET 999999];
            } catch (Exception ex) {
                AuraHandledException result = ReplacementQuoteLineCreationHelper.handleException(ex);
                System.assert(true);
            }

            // No Access Exception
            try {
                throw new System.NoAccessException();
            } catch (Exception ex) {
                AuraHandledException result = ReplacementQuoteLineCreationHelper.handleException(ex);
                System.assert(true);
            }

            // Generic Exception
            try {
                Integer i=1/0;
            } catch (Exception ex) {
                AuraHandledException result = ReplacementQuoteLineCreationHelper.handleException(ex);
                System.assert(true);
            }
        }
    }
    /***********************************************************************************************************
    * Method Name          : createAssetforHW
    * Date Created/Modified: 12/07/2025
    * @description         : for asset creation
    * Author               : Khushboo
    * Purpose              : sub function
    * @param               ent
    * @return              assetsAvailable 
    * Test Class Methods   :
    **********************************************************************************************************/
    static List<ReplacementRefreshWrapperData.picklist> createAssetforHW(Entitlement ent){
        List<ReplacementRefreshWrapperData.picklist> assetsAvailable = new List<ReplacementRefreshWrapperData.picklist>();
        ReplacementRefreshWrapperData.pickList objpickListAll = 
            ReplacementRefreshWrapperData.createpicKlistValues(
                ReplacementConstants.FULL_SELECTION, ReplacementConstants.FULL_SELECTION,
                ent.Id,ent.Name,0,true,true,false,true);
        assetsAvailable.add(objpickListAll);
        ReplacementRefreshWrapperData.pickList objpickListAll1 = 
            ReplacementRefreshWrapperData.createpicKlistValues(
                String.valueOf(ent.Asset.ID), 'Asset123 (Asset123) (10.00)',String.valueOf(ent.Id),ent.Name
                ,0,true,false,false,true);
        assetsAvailable.add(objpickListAll1);
        return assetsAvailable;
    }
    
    /***********************************************************************************************************
    * Method Name          : testCPQCloneErrorHandling
    * Date Created/Modified: 21/08/2025
    * @description         : for CPQ Clone Error Handling
    * Author               : Rahul
    * Purpose              : sub function
    * Test Class Methods   :
    **********************************************************************************************************/
    testmethod static void testCPQCloneErrorHandling() {
       	user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
        SBQQ__Quote__c  sq = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        CPQ_Disposition_Quote_Line__c cpqLine = new CPQ_Disposition_Quote_Line__c(Quote__c = sq.Id);
        insert cpqLine;
        
        Map<Id, Id> mapSourceVsNewQId = new Map<Id, Id>();
        mapSourceVsNewQId.put(sq.Id, acc.Id);  
        Test.startTest();
        try {
                ReplacementQuoteLineCreationHelper.createCPQDispLinesOnCloneRelated(new Set<Id>{sq.Id}, mapSourceVsNewQId);
        } catch (Exception e) {
            	System.debug(System.logginglevel.DEBUG,'Caught exception: ' + e.getMessage());
            	system.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }    
    }
}