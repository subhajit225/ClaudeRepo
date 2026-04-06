/***********************************************************************************************************
 * Class Name           : SKUNewReplacementControllerTest
 * Date Created/Modified: 28/03/2024
 * Author               : Rahul/Shivani
 * @description         : Test Class for SKUNewReplacementController.                       
 * Dependant Components : SKUNewReplacementController
/**********************************************************************************************************/
@IsTest
public class SKUNewReplacementControllerTest { 
    /***********************************************************************************************************
     * Method Name          : setup
     * Date Created/Modified: 28/03/2024
     * Author               : Rahul/Shivani 
     * @description         : Test data setup method                
    /**********************************************************************************************************/
    @testSetup static void setup() {
        //Deactivate triggers
        // INSERT new ShGl_DisableBusinessLogic__c(setupownerid = userinfo.getUserId(), 
        //             Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        //             Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        //             Disable_Opportunity_Triggers__c=true, Disable_SBQQ_Quote_Validation_Rules__c= true);
        User usr1 = Replacement_TestDataFactory.getUser();
        usr1.RBAC_Department__c = 'Service Account';
        usr1.RBAC_Group__c = 'System - IT';
        insert usr1;
        INSERT new ShGl_DisableBusinessLogic__c(
            Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
            Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
            Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
            Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
            Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
            Disable_Opportunity_Validation_Rules__c=true,
        	setupownerid = usr1.Id);
                        
        Date startDate = date.today();
        Date endDate = date.today()+30;
        System.runAs(usr1){
        List<Replacement_Support__c> lstRep = new List<Replacement_Support__c>();
        
        Replacement_Support__c testReplacementPolicyGrid= 
            Replacement_TestDataFactory.getPolicyGridValues(
                ReplacementConstants.ENTERPRISE_DATA_PROTECTION, 
                ReplacementConstants.ENTERPRISE_DATA_PROTECTION, startDate, endDate);
        lstRep.add(testReplacementPolicyGrid);
        
        Replacement_Support__c testReplacementPolicyGrid1= 
            Replacement_TestDataFactory.getPolicyGridValues(
                ReplacementConstants.CLOUD_VAULT,
                ReplacementConstants.CLOUD_VAULT, startDate, endDate);
        lstRep.add(testReplacementPolicyGrid1);
        
        Replacement_Support__c testReplacementPolicyGrid2= 
            Replacement_TestDataFactory.getPolicyGridValues(
                ReplacementConstants.SAAS_DATA_PROTECTION, 
                ReplacementConstants.SAAS_DATA_PROTECTION, startDate, endDate);
        lstRep.add(testReplacementPolicyGrid2);
        
        Id recTypeId = Schema.getGlobalDescribe()
            .get(ReplacementConstants.REPLACEMENT_SUPPORT_OBJ)
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get(ReplacementConstants.UPGRADE_VALUE)
            .getRecordTypeId();
        Replacement_Support__c testDispositionRecord= 
            Replacement_TestDataFactory.getDispositionChange(
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.ENTERPRISE_EDITION,
                ReplacementConstants.UPGRADE_VALUE, startDate, endDate,recTypeId);
        lstRep.add(testDispositionRecord);
        
        Replacement_Support__c testDispDowngrade= 
            Replacement_TestDataFactory.getDispositionChange(
                ReplacementConstants.BUSINESS_EDITION,
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.DOWNGRADE_VALUE, startDate, endDate,NULL);
        lstRep.add(testDispDowngrade);
        
        Replacement_Support__c testDispNotAllowed= 
            Replacement_TestDataFactory.getDispositionChange(
                ReplacementConstants.BUSINESS_EDITION,
                ReplacementConstants.ENTERPRISE_EDITION,
                ReplacementConstants.NOTALLOWED_VALUE, startDate, endDate,NULL);
        lstRep.add(testDispNotAllowed);
        
        insert lstRep;
        //Account
        String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR)
            .getRecordTypeId();
        Account acc= Replacement_TestDataFactory.getAccount('Test Account', recordTypeId);
        INSERT acc;
        
        //Contact 
        Contact con= Replacement_TestDataFactory.getContact(acc);
        INSERT con;
        
       List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= TestDataFactory.getOpportunity(acc, con);
        Opportunity opp1= TestDataFactory.getOpportunity(acc, con);
        oppList.add(opp);
        oppList.add(opp1);
        INSERT oppList;
    
        
        List<Product2> lstPrd = new List<Product2>();
        List<Id> lstPrdIds = new List<Id>();
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-01', 'RBK-R6410-01', 
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.ENTERPRISE_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.SAAS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-02', 'RBK-R6410-02', 
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.ENTERPRISE_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-03', 'RBK-R6410-03', 
                ReplacementConstants.BUSINESS_EDITION, 
                ReplacementConstants.JIRA_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.M365H, 
                ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(
            Replacement_TestDataFactory.getv1Product(
                'RBK-R6410-04', 'RBK-R6410-04', 
                ReplacementConstants.EDITION_STANDALONE,
                ReplacementConstants.M365_DATA_PROTECTION, 
                ReplacementConstants.PREPETUAL, 
                ReplacementConstants.NAS_CLOUD_DIRECT, 
                ReplacementConstants.ON_PREM));
        lstPrd.add(
            Replacement_TestDataFactory.getv1Product(
                'RBK-R6410-05', 'RBK-R6410-05', 
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.ENTERPRISE_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.FOUNDATION_EDITION, 
                ReplacementConstants.ON_PREM));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-06', 'RBK-R6410-06', 
                ReplacementConstants.BUSINESS_EDITION, 
                ReplacementConstants.COULD_DATA_PROTECTION, 
                ReplacementConstants.PREPETUAL, 
                ReplacementConstants.EDITION_UPGRADE, 
                ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-07', 'RBK-R6410-07', 
                ReplacementConstants.EDITION_UPGRADE, 
                ReplacementConstants.SFDC_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.PROACTIVE_EDITION, 
                ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-08', 'RBK-R6410-07', 
                ReplacementConstants.PROACTIVE_EDITION, 
                ReplacementConstants.JIRA_DATA_PROTECTION, 
                ReplacementConstants.PREPETUAL, ReplacementConstants.GPS, 
                ReplacementConstants.SAAS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-09', 'RBK-R6410-07', 
                ReplacementConstants.SUPPORT, 
                ReplacementConstants.NON_REPLACEABLE, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.HW_SUPPORT, 
                ReplacementConstants.SAAS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-R6410-10', 'RBK-R6410-10', 
                ReplacementConstants.ENTERPRISE_EDITION, 
                ReplacementConstants.COULD_DATA_PROTECTION, 
                ReplacementConstants.PREPETUAL, 
                ReplacementConstants.HW_SUPPORT, 
                ReplacementConstants.SAAS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-UG-P-CVB', 'RBK-UG-P-CVB', 
                ReplacementConstants.EDITION_UPGRADE, 
                ReplacementConstants.COULD_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.EDITION_UPGRADE, 
                ReplacementConstants.SAAS));
        lstPrd.add(
            Replacement_TestDataFactory.getProduct(
                'RBK-UG-P-CVB', 'RBK-UG-P-CVB', 
                ReplacementConstants.EDITION_UPGRADE, 
                ReplacementConstants.COULD_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SAAS));
        lstPrd[0].Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        lstPrd[0].Product_Subtype__c = ReplacementConstants.PRODUCT_SUBTYPE_VIRTUAL;
        lstPrd[0].SBQQ__SubscriptionPricing__c = ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;
        lstPrd[4].Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        lstPrd[4].Product_Subtype__c = ReplacementConstants.PRODUCT_SUBTYPE_VIRTUAL;
        lstPrd[4].SBQQ__SubscriptionPricing__c = ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;
        lstPrd[1].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[2].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[3].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[4].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        INSERT lstPrd;
        for (Product2 prod : lstPrd) {
        lstPrdIds.add(prod.id);
        }

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
        
        ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opp.Id, customPB.Id);
        INSERT serviceContractObj;
        
        //Quote
        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = Replacement_TestDataFactory.getQuote(
            acc.Id, opp.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);
        SBQQ__Quote__c quoteRec1 = Replacement_TestDataFactory.getQuote(
            acc.Id, opp1.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL);
        qbList.add(quoteRec);
        qbList.add(quoteRec1);
        INSERT qbList;
    
        //Ceate Asset
        List<Asset> asstList = new  List<Asset>();
        Asset asst= Replacement_TestDataFactory.getAsset('Asset122', lstPrd[0].Id, acc.Id);
        Asset asst1= Replacement_TestDataFactory.getAsset('Asset123', lstPrd[9].Id, acc.Id);
        asstList.add(asst);
        asstList.add(asst1);
        INSERT asstList;

        List<ContractLineItem> lstCLI = new List<ContractLineItem>();
        ContractLineItem ContractLineItemObj = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj.EndDate = Date.today().addDays(365);
        ContractLineItemObj.StartDate =  Date.today();
        ContractLineItemObj.SBQQSC__Product__c = lstPrdIds[1];
        lstCLI.add(ContractLineItemObj);
        ContractLineItem ContractLineItemObj1 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj1.EndDate = date.newinstance(2028, 2, 17);
        ContractLineItemObj1.StartDate =  date.newinstance(2027, 2, 17);
        ContractLineItemObj1.SBQQSC__Product__c = lstPrdIds[1];
        lstCLI.add(ContractLineItemObj1);
        ContractLineItem ContractLineItemObj2 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj2.EndDate = Date.today().addDays(365);
        ContractLineItemObj2.StartDate =  Date.today();
        ContractLineItemObj2.SBQQSC__Product__c = lstPrdIds[10];
        lstCLI.add(ContractLineItemObj2);
       
        insert lstCLI;

        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[1], ContractLineItemObj1.Id); 
        SBQQ__QuoteLine__c qli1= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[2], ContractLineItemObj2.Id); 
        SBQQ__QuoteLine__c qli2= 
            Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrdIds[2], ContractLineItemObj2.Id); 
        qlList.add(qli);
        qlList.add(qli1);
        qlList.add(qli2);
        insert qlList;
        }
        
    }

    /***********************************************************************************************************
     * Method Name          : SKUGPSProductTypeMethod
     * Date Created/Modified: 28/03/2024
     * Author               : Rahul/Shivani 
     * @description         : This method prepares data for fetching SKU related products.              
    /**********************************************************************************************************/
    @isTest static void skuGPSProductTypeMethod() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
                
        Account acc= [SELECT Id FROM Account LIMIT 1];    
        Contact con= [SELECT Id, Email FROM Contact LIMIT 1];
        
        //Product data
        List<Product2> lstPrd = new List<Product2>();
        
        lstPrd.add(
            Replacement_TestDataFactory.getProductWithSubCategory(
                'RS-BT-EE-PE-PP', 'RS-BT-EE-PE-PP', //Fy25SR-2388
                ReplacementConstants.ENTERPRISE_EDITION, 
                ReplacementConstants.ENTERPRISE_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.GPS, 
                ReplacementConstants.SAAS,
                ReplacementConstants.HW_SUPPORT));
        lstPrd[0].Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        lstPrd[0].Product_Subtype__c = ReplacementConstants.PRODUCT_SUBTYPE_VIRTUAL;
        lstPrd[0].SBQQ__SubscriptionPricing__c = ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;    
        INSERT lstPrd;

        //Standard PriceBook
        Id standardPriceBookId= Test.getStandardPricebookId();
        
        //Custom PriceBook
        PriceBook2 customPB = Replacement_TestDataFactory.getPriceBook(); 
        INSERT customPB;
        
        //Create PriceBook Entries for Standard and Custom PriceBook
        List<PricebookEntry> lstEntry = new List<PricebookEntry>();
        //Standard PriceBookEntry
        lstEntry.add(
        Replacement_TestDataFactory.getPriceBookEntry(lstPrd[0].Id, standardPriceBookId));
        
        //Custom PriceBookEntry
        lstEntry.add(
        Replacement_TestDataFactory.getPriceBookEntry(lstPrd[0].Id, customPB.Id));
        INSERT lstEntry;
        
        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= Replacement_TestDataFactory.getOpportunity(acc, con, customPB.Id);
        Opportunity opp1= Replacement_TestDataFactory.getOpportunity(acc, con, customPB.Id);
        oppList.add(opp);
        oppList.add(opp1);
        INSERT oppList;
        
        //Quote
        Test.startTest();
        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = 
            Replacement_TestDataFactory.getQuote(acc.Id, opp.Id, customPB.Id, 
                ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);
        SBQQ__Quote__c quoteRec1 = 
            Replacement_TestDataFactory.getQuote(acc.Id, opp1.Id, customPB.Id, 
                ReplacementConstants.QUOTE_TYPE_RENEWAL);
        qbList.add(quoteRec);
        qbList.add(quoteRec1);
        INSERT qbList;
        
        quoteRec.ApprovalStatus__c = ReplacementConstants.STATUS_APPROVED;
        UPDATE quoteRec;
        
        opp.SBQQ__PrimaryQuote__c = quoteRec.Id;
        opp1.SBQQ__PrimaryQuote__c = quoteRec1.Id;
        UPDATE opp;
    
        //Ceate Asset
        Asset asst= Replacement_TestDataFactory.getAsset('EntitlementTriggerHelperAsset', lstPrd[0].Id, acc.Id);
        INSERT asst;
        
        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        INSERT ordr;
        
        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;
        
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(lstPrd[0].Id, ordr.Id, lstEntry[1].Id);
        INSERT oli1;
                    
         Entitlement ets;
            Entitlement ent = 
                Replacement_TestDataFactory.getEntitlement(
                    'Test Entitlement', acc.Id, lstPrd[0].Id, asst.Id, oli1.Id, null, null);
            INSERT ent;
            ets = ent;
        ReplacementRefreshWrapperData.WrapperData repWrapperdata= new ReplacementRefreshWrapperData.WrapperData();
        repWrapperdata.entitlementId = ets.Id != null ? ets.id : '';
        repWrapperdata.SrprodRepCategory = ReplacementConstants.ENTERPRISE_DATA_PROTECTION;
        repWrapperdata.oldProductEdition= ReplacementConstants.EDITION_STANDALONE;
        repWrapperdata.entitlementName= ets.Id != null ? ets.Name : '';     
        repWrapperdata.v1Product = false;
        repWrapperdata.productId = lstPrd[0].Id;
        repWrapperdata.srSuppType = 'Premium';//FY25SR-2388
        repWrapperdata.srPaymentType = 'Prepay';//FY25SR-2388
        List<SKUNewReplacementController.WrapperProuct> products = 
            SKUNewReplacementController.getSKUData(repWrapperdata, quoteRec, false);
        
        List<SKUNewReplacementController.WrapperProuct> products1 = 
            SKUNewReplacementController.getSKUData(repWrapperdata, quoteRec1, false);
        System.assertEquals(1, products.size());
        Test.stopTest();
        }
    }
    
    /***********************************************************************************************************
     * Class Extention Name : ReplacementFieldMock
     * Date Created/Modified: 24/04/2025
     * Author               : Rahul 
     * @description         : This method extends metadata for mock class.  
     * Story                : FY25SR-1084              
    /**********************************************************************************************************/

    class ReplacementFieldMock extends ReplacementFieldMetadata {
        override protected List<Replacement_Field_Mapping__mdt> getAllInternal() {
            List<Replacement_Field_Mapping__mdt> mockList = new List<Replacement_Field_Mapping__mdt>();

            Map<String, Object> data1 = new Map<String, Object>{
                'Product_Type_Sub_Type__c' => ReplacementConstants.CLOUD_VALUE_BACKUP,
                'SKU_Attribute_Fields__c' => 'Storage_Region_Bundle_FrontEnd__c'
            };
            Map<String, Object> data2 = new Map<String, Object>{
                'Product_Type_Sub_Type__c' => ReplacementConstants.CLOUD_VALUE_ARCHIVE,
                'SKU_Attribute_Fields__c' => 'Storage_Region_Bundle_FrontEnd__c,Approval_Flags__c'
            };
            Map<String, Object> data3 = new Map<String, Object>{
                'Product_Type_Sub_Type__c' => ReplacementConstants.M365H,
                'SKU_Attribute_Fields__c' => 'Storage_Tier__c'
            };
            Map<String, Object> data4 = new Map<String, Object>{
                'Product_Type_Sub_Type__c' => ReplacementConstants.SAAS_APPLICATIONS,
                'SKU_Attribute_Fields__c' => 'Salesforce_Quantity__c,Rubrik_Hosted_M365_Quantity__c,Atlassian_Quantity__c,Dynamics_Quantity__c'
            };
            Map<String, Object> data5 = new Map<String, Object>{
                'Product_Type_Sub_Type__c' => ReplacementConstants.SAAS_APPLICATIONS,
                'SKU_Attribute_Fields__c' => 'Prior_Net_Total__c'
            };
            Map<String, Object> data6 = new Map<String, Object>{
                'Product_Type_Sub_Type__c' => ReplacementConstants.SAAS_APPLICATIONS,
                'SKU_Attribute_Fields__c' => 'TPH_Models_Gen__c'
            };

            mockList.add(
                (Replacement_Field_Mapping__mdt) JSON.deserialize(
                    JSON.serialize(data1),
                    Replacement_Field_Mapping__mdt.class
                )
            );
            mockList.add(
                (Replacement_Field_Mapping__mdt) JSON.deserialize(
                    JSON.serialize(data2),
                    Replacement_Field_Mapping__mdt.class
                )
            );
            mockList.add(
                (Replacement_Field_Mapping__mdt) JSON.deserialize(
                    JSON.serialize(data3),
                    Replacement_Field_Mapping__mdt.class
                )
            );
            mockList.add(
                (Replacement_Field_Mapping__mdt) JSON.deserialize(
                    JSON.serialize(data4),
                    Replacement_Field_Mapping__mdt.class
                )
            );
            mockList.add(
                (Replacement_Field_Mapping__mdt) JSON.deserialize(
                    JSON.serialize(data5),
                    Replacement_Field_Mapping__mdt.class
                )
            );
            mockList.add(
                (Replacement_Field_Mapping__mdt) JSON.deserialize(
                    JSON.serialize(data6),
                    Replacement_Field_Mapping__mdt.class
                )
            );
            return mockList;
        }
    }
    
   
    /***********************************************************************************************************
     * Method Name : testCloudVaultSKU
     * Date Created/Modified: 24/04/2025
     * Author               : Rahul 
     * @description         : This method prepares data for sku attributes Storage Region Bundle
     * Story                : FY25SR-1084               
    /**********************************************************************************************************/

    static testMethod void testCloudVaultSKU() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
        ReplacementFieldMetadata.setMock(new ReplacementFieldMock());
        List<Replacement_Field_Mapping__mdt> results = ReplacementFieldMetadata.getAll();        
        
        Account acc= [SELECT Id FROM Account LIMIT 1];    
        Contact con= [SELECT Id, Email FROM Contact LIMIT 1];
        
        //Product data
        //List<Product2> lstPrd = new List<Product2>();
        
        Product2 prds = 
            Replacement_TestDataFactory.getProductWithSubCategory(
                'RA-BT-CVA-PE-PP', 'RA-BT-CVA-PE-PP', '',//FY25SR-2388
                ReplacementConstants.CLOUD_VAULT, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.CLOUD_VALUE_ARCHIVE, 
                ReplacementConstants.SAAS, 
                ReplacementConstants.CV_SAAS_COMMERCIAL);
        prds.Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        prds.Product_Subtype__c = ReplacementConstants.PRODUCT_SUBTYPE_VIRTUAL;
        prds.SBQQ__SubscriptionPricing__c = ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;
        INSERT prds;

        //Standard PriceBook
        Id standardPriceBookId= Test.getStandardPricebookId();
        
        //Custom PriceBook
        PriceBook2 customPB = Replacement_TestDataFactory.getPriceBook(); 
        INSERT customPB;
        
        //Create PriceBook Entries for Standard and Custom PriceBook
        List<PricebookEntry> lstEntry = new List<PricebookEntry>();
        //Standard PriceBookEntry
        lstEntry.add(
        Replacement_TestDataFactory.getPriceBookEntry(prds.Id, standardPriceBookId));
        
        //Custom PriceBookEntry
        lstEntry.add(
        Replacement_TestDataFactory.getPriceBookEntry(prds.Id, customPB.Id));
        INSERT lstEntry;
        
        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= Replacement_TestDataFactory.getOpportunity(acc, con, customPB.Id);
        Opportunity opp1= Replacement_TestDataFactory.getOpportunity(acc, con, customPB.Id);
        oppList.add(opp);
        oppList.add(opp1);
        INSERT oppList;
        
        //Quote
        Test.startTest();

        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = 
            Replacement_TestDataFactory.getQuote(
                acc.Id, opp.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);
        SBQQ__Quote__c quoteRec1 = 
            Replacement_TestDataFactory.getQuote(
                acc.Id, opp1.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL);
        qbList.add(quoteRec);
        qbList.add(quoteRec1);
        INSERT qbList;
        
        quoteRec.ApprovalStatus__c = ReplacementConstants.STATUS_APPROVED;
        UPDATE quoteRec;
        
        opp.SBQQ__PrimaryQuote__c = quoteRec.Id;
        opp1.SBQQ__PrimaryQuote__c = quoteRec1.Id;
        UPDATE opp;
        
        //Ceate Asset
        Asset asst= Replacement_TestDataFactory.getAsset('EntitlementTriggerHelperAsset', prds.Id, acc.Id);
        INSERT asst;
        
        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        INSERT ordr;
        
        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;
    
        SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,
                CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c, 
                SBQQ__Account__c, SBQQ__Type__c 
                FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c= :ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
        List<SBQQ__QuoteLine__c> qlList= 
                [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c 
                    FROM SBQQ__QuoteLine__c 
                    WHERE SBQQ__Quote__c=: qb.Id];
    
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(prds.Id, ordr.Id, lstEntry[1].Id);
        INSERT oli1;
        
            Entitlement ets;
            Entitlement ent = 
                Replacement_TestDataFactory.getEntitlement(
                    'Test Entitlement', acc.Id, prds.Id, asst.Id, oli1.Id, null, null);
            INSERT ent;
            ets = ent;
            ReplacementRefreshWrapperData.WrapperData repWrapperdata= new ReplacementRefreshWrapperData.WrapperData();
            repWrapperdata.entitlementId = ets.Id != null ? ets.id : '';
            repWrapperdata.SrprodRepCategory = ReplacementConstants.CLOUD_VAULT;
            repWrapperdata.entitlementName= ets.Id != null ? ets.Name : '';
            repWrapperdata.originalQuoteLineIdForEnt = qlList[0].Id;
        	repWrapperdata.v1Product = true;
        	repWrapperdata.productId = prds.Id;
            List<SKUNewReplacementController.WrapperProuct> products = 
                SKUNewReplacementController.getSKUData(repWrapperdata, quoteRec, false);
            List<SKUNewReplacementController.skuDrawerWrapperProduct> wrapPrd = 
                SKUNewReplacementController.getSchemaFieldsForQuoteLine(products[0]);
            System.assertEquals(1, products.size());
        Test.stopTest();
        }
    }
    
    /***********************************************************************************************************
     * Method Name : testUniversalSaaSSKU
     * Date Created/Modified: 24/04/2025
     * Author               : Rahul 
     * @description         : This method prepares data for sku attributes SaaS Applications   
     * Story                : FY25SR-1084          
    /**********************************************************************************************************/

    static testMethod void testUniversalSaaSSKU() {
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        
        System.runAs(usr1) {
        ReplacementFieldMetadata.setMock(new ReplacementFieldMock());
        
        ReplacementFieldMetadata instance = new ReplacementFieldMetadata();
        List<Replacement_Field_Mapping__mdt> result1 = instance.getAllInternal();
        
        List<Replacement_Field_Mapping__mdt> results = ReplacementFieldMetadata.getAll();        
        
        Account acc= [SELECT Id FROM Account LIMIT 1];    
        Contact con= [SELECT Id, Email FROM Contact LIMIT 1];
        
        //Product data
        //List<Product2> lstPrd = new List<Product2>();
        
        Product2 prds = 
            Replacement_TestDataFactory.getProductWithSubCategory(
                'RS-UR-FE-SA-PE-PP', 'RS-UR-FE-SA-PE-PP',
                ReplacementConstants.FOUNDATION_EDITION,
                ReplacementConstants.SAAS_DATA_PROTECTION, 
                ReplacementConstants.SUBSCRIPTION, 
                ReplacementConstants.UNIVERSAL_SAAS_APPS, 
                ReplacementConstants.SAAS, 
                ReplacementConstants.SAAS_SAAS_COMMERCIAL);
        prds.Product_Subtype__c = ReplacementConstants.SAAS_APPLICATIONS; 
        prds.Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        prds.SBQQ__SubscriptionPricing__c = ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;
        INSERT prds;

        //Standard PriceBook
        Id standardPriceBookId= Test.getStandardPricebookId();
        
        //Custom PriceBook
        PriceBook2 customPB = Replacement_TestDataFactory.getPriceBook(); 
        INSERT customPB;
        
        //Create PriceBook Entries for Standard and Custom PriceBook
        List<PricebookEntry> lstEntry = new List<PricebookEntry>();
        //Standard PriceBookEntry
        lstEntry.add(
        Replacement_TestDataFactory.getPriceBookEntry(prds.Id, standardPriceBookId));
        
        //Custom PriceBookEntry
        lstEntry.add(
        Replacement_TestDataFactory.getPriceBookEntry(prds.Id, customPB.Id));
        INSERT lstEntry;
        
        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= Replacement_TestDataFactory.getOpportunity(acc, con, customPB.Id);
        Opportunity opp1= Replacement_TestDataFactory.getOpportunity(acc, con, customPB.Id);
        oppList.add(opp);
        oppList.add(opp1);
        INSERT oppList;
        
        //Quote

        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = 
            Replacement_TestDataFactory.getQuote(
                acc.Id, opp.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);
        SBQQ__Quote__c quoteRec1 = 
            Replacement_TestDataFactory.getQuote(
                acc.Id, opp1.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL);
        qbList.add(quoteRec);
        qbList.add(quoteRec1);
        INSERT qbList;
        
        quoteRec.ApprovalStatus__c = ReplacementConstants.STATUS_APPROVED;
        UPDATE quoteRec;
        
        opp.SBQQ__PrimaryQuote__c = quoteRec.Id;
        opp1.SBQQ__PrimaryQuote__c = quoteRec1.Id;
        UPDATE opp;
        
        //Ceate Asset
        Asset asst= Replacement_TestDataFactory.getAsset('EntitlementTriggerHelperAsset', prds.Id, acc.Id);
        INSERT asst;
        
        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        INSERT ordr;
        
        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;
    	Test.startTest();

        SBQQ__Quote__c qb= 
            [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,
                    Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c 
               FROM SBQQ__Quote__c 
              WHERE SBQQ__Type__c= :ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
        List<SBQQ__QuoteLine__c> qlList= 
            [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c 
               FROM SBQQ__QuoteLine__c 
              WHERE SBQQ__Quote__c=: qb.Id];
    
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(prds.Id, ordr.Id, lstEntry[1].Id);
        INSERT oli1;
                   
            Entitlement ets;
            Entitlement ent = 
                Replacement_TestDataFactory.getEntitlement(
                    'Test Entitlement', acc.Id, prds.Id, asst.Id, oli1.Id, null, null);
            INSERT ent;
            ets = ent;
            ReplacementRefreshWrapperData.WrapperData repWrapperdata= new ReplacementRefreshWrapperData.WrapperData();
            repWrapperdata.entitlementId = ets.Id != null ? ets.id : '';
            repWrapperdata.SrprodRepCategory = ReplacementConstants.SAAS_DATA_PROTECTION;
            repWrapperdata.entitlementName= ets.Id != null ? ets.Name : '';
            repWrapperdata.originalQuoteLineIdForEnt = qlList[0].Id;
        	repWrapperdata.v1Product = false;
        	repWrapperdata.productId = prds.Id;
            List<SKUNewReplacementController.WrapperProuct> products = 
                SKUNewReplacementController.getSKUData(repWrapperdata, quoteRec, false);
            ReplacementRefreshWrapperData.WrapperData repWrapperdataTPH= 
                new ReplacementRefreshWrapperData.WrapperData();
            repWrapperdataTPH.entitlementId = ets.Id != null ? ets.id : '';
            repWrapperdataTPH.SrprodRepCategory = ReplacementConstants.SAAS_DATA_PROTECTION;
            repWrapperdataTPH.entitlementName= ets.Id != null ? ets.Name : '';
            repWrapperdataTPH.originalQuoteLineIdForEnt = qlList[0].Id;
            repWrapperdataTPH.tphTypeEntitlement = false;
        	repWrapperdataTPH.v1Product = false;
        	repWrapperdataTPH.productId = prds.Id;
            List<SKUNewReplacementController.WrapperProuct> productsTPHFalse = SKUNewReplacementController.getSKUData(
                repWrapperdataTPH, quoteRec, true);
            String strT = SKUNewReplacementController.calculateStepValue(3);
            
            List<SKUNewReplacementController.skuDrawerWrapperProduct> wrapPrd = 
                SKUNewReplacementController.getSchemaFieldsForQuoteLine(products[0]);
            List<ReplacementRefreshWrapperData.PickList> lstWrapPick = 
                SKUNewReplacementController.fetchNetworkTypeForAssetNonAsset();
            String str = SKUNewReplacementController.calculateStepValue(1);
            System.assertEquals(1, products.size());
    
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get('SBQQ__QuoteLine__c');
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        Schema.SObjectField field = MapofField.get('TPH_Models_Gen__c');
        Schema.DescribeFieldResult fr = field.getDescribe();
    
            List<skunewReplacementController.PickList> lstpick = 
                skunewReplacementController.getPickListEntries(fr,null,false,null);
            String valutBackUpNoFred = 
                skunewReplacementController.mapProductCodeType(
                    ReplacementConstants.CLOUD_VALUE_BACKUP,  ReplacementConstants.NOFEDRAMP,null,null);
            String valutArchiveFred = 
                skunewReplacementController.mapProductCodeType(
                    ReplacementConstants.CLOUD_VALUE_ARCHIVE,ReplacementConstants.FEDRAMP,null,null);
            String valutBackUpFred = 
                skunewReplacementController.mapProductCodeType(
                    ReplacementConstants.CLOUD_VALUE_BACKUP,  ReplacementConstants.FEDRAMP,null,null);
            String m365 = 
                skunewReplacementController.mapProductCodeType(
                    ReplacementConstants.M365H,ReplacementConstants.FEDRAMP,'Test Desc 50GB',null);
            String mdProd = 
                skunewReplacementController.mapProductCodeType(
                    ReplacementConstants.M365H,ReplacementConstants.FEDRAMP,'Test Desc 0GB','RBK-MD-4560');
            try{
                List<SKUNewReplacementController.SkuDrawerWrapperProduct> testCatchPart = 
                skunewReplacementController.getSchemaFieldsForQuoteLine(null);
            }catch(exception e){
                System.debug(LoggingLevel.DEBUG, 'Excepon caught');
            }
            try{
                List<SKUNewReplacementController.WrapperProuct> testCatchGetSKU = 
                skunewReplacementController.getSKUData(null, null, false);
            }catch(exception e){
                System.debug(LoggingLevel.DEBUG, 'Excepon caught');
            }
            try{
                ReplacementRefreshWrapperData.WrapperData entData = 
                new ReplacementRefreshWrapperData.WrapperData();
            List<SKUNewReplacementController.WrapperProuct> testCatchGetSKUC = 
                skunewReplacementController.getSKUData(entData, null, false);
            }catch(exception e){
                System.debug(LoggingLevel.DEBUG, 'Excepon caught');
            }
            
            SKUNewReplacementController.SkuDrawerWrapperProduct objSkuDrawerWrapperProduct = 
                new SKUNewReplacementController.SkuDrawerWrapperProduct();
            objSkuDrawerWrapperProduct.fieldValue = 'Test';
            objSkuDrawerWrapperProduct.currencyType = true;
            objSkuDrawerWrapperProduct.TextType = true;
            objSkuDrawerWrapperProduct.errorOccured = true;
            objSkuDrawerWrapperProduct.errorMessage = 'Test error message';
            
            SKUNewReplacementController.WrapperProuct objWrapperProuct = new SKUNewReplacementController.WrapperProuct();
            objWrapperProuct.childMappingSKUattributes = new Map<String, String>();
            objWrapperProuct.dispositionReason = ReplacementConstants.DISPOSITION;
            objWrapperProuct.errors = 'Test error';
            objWrapperProuct.pathFromSKU = 'Test pathFromSKU';
            objWrapperProuct.pathAssetSelected = new List<ReplacementRefreshWrapperData.PickList>();
            System.assertEquals(ReplacementConstants.DISPOSITION,objWrapperProuct.dispositionReason);
            System.assertEquals('Test error',objWrapperProuct.errors);
                
            SkunewReplacementController.Picklist pt = new SkunewReplacementController.Picklist();
            pt.valueProcessed = false;        
            Test.stopTest();
        }
    }
}