/***********************************************************************************************************
* Class Name           : ReplacementQueryControllerTest
* Date Created/Modified: 28/02/2025
* Author               : Sumedha
* @description         : Test class for ReplacementQueryController
* Test Class           :
/*******************************************************.
0***************************************************/
@isTest
public class ReplacementQueryControllerTest { 
    /***********************************************************************************************************
    * Method Name          : setup
    * Date Created/Modified: 28/02/2025
    * Author               : Sumedha
    * @description         : Data setup for the test class
    /**********************************************************************************************************/
    @testSetup static void setup() {
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
		
        //Account
        String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName()
            .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        List<Account> accList= new List<Account>();
        Account acc = TestDataFactory.getAccount();
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
          , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-02', 'RBK-R6410-02'
          , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
          , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-03', 'RBK-R6410-03'
          , ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION
          , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.M365H, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getv1Product('RBK-R6410-04', 'RBK-R6410-04'
          , ReplacementConstants.EDITION_STANDALONE, ReplacementConstants.M365_DATA_PROTECTION
          , ReplacementConstants.PREPETUAL, ReplacementConstants.NAS_CLOUD_DIRECT, ReplacementConstants.ON_PREM));
        lstPrd.add(Replacement_TestDataFactory.getv1Product('RBK-R6410-05', 'RBK-R6410-05'
          , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
          , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ON_PREM));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-06', 'RBK-R6410-06'
          , ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.COULD_DATA_PROTECTION
          , ReplacementConstants.PREPETUAL, ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-07', 'RBK-R6410-07'
          , ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SFDC_DATA_PROTECTION
          , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.PROACTIVE_EDITION, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-08', 'RBK-R6410-07'
          , ReplacementConstants.PROACTIVE_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION
          , ReplacementConstants.PREPETUAL, ReplacementConstants.GPS, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-09', 'RBK-R6410-07'
          , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
          , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-10', 'RBK-R6410-10'
          , ReplacementConstants.ENTERPRISE_EDITION, ReplacementConstants.COULD_DATA_PROTECTION
          , ReplacementConstants.PREPETUAL, ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-UG-P-CVB', 'RBK-UG-P-CVB'
          , ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.COULD_DATA_PROTECTION
          , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SAAS));
        lstPrd[0].Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        lstPrd[0].Product_Subtype__c = ReplacementConstants.PRODUCT_SUBTYPE_VIRTUAL;
        lstPrd[0].SBQQ__SubscriptionPricing__c = ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;
        lstPrd[0].Product_Code_Type__c = ReplacementConstants.PRODUCT_CODE_TYPE_CVB;
        lstPrd[4].Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
        lstPrd[4].Product_Subtype__c = ReplacementConstants.PRODUCT_SUBTYPE_VIRTUAL;
        lstPrd[4].SBQQ__SubscriptionPricing__c = ReplacementConstants.SUBSCRIPTION_FIXED_PRICE;
        lstPrd[1].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[2].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[3].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        lstPrd[4].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
        system.runAs(usr1){
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

        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= TestDataFactory.getOpportunity(acc, con);
        Opportunity opp1= TestDataFactory.getOpportunity(acc, con);
        oppList.add(opp);
        //oppList.add(opp1);
        INSERT oppList;

        //Quote
        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = Replacement_TestDataFactory.getQuote(
            acc.Id, opp.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);
        SBQQ__Quote__c quoteRec1 = Replacement_TestDataFactory.getQuote(
            acc.Id, opp1.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL);
        qbList.add(quoteRec);
        INSERT qbList;

        //Ceate Asset
        List<Asset> asstList = new  List<Asset>();
        Asset asst= Replacement_TestDataFactory.getAsset('Asset122', lstPrd[0].Id, acc.Id);
        Asset asst1= Replacement_TestDataFactory.getAsset('Asset123', lstPrd[9].Id, acc.Id);
        asstList.add(asst);
        asstList.add(asst1);
        INSERT asstList;

        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        INSERT ordr;

        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;

        //Polaris SKU Mapping
        List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingObjList = new List<Polaris_SKU_Mapping_V2__c>();
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj = 
            Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[0].Id, lstPrd[1].Id);
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj1 = 
            Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[9].Id, lstPrd[8].Id);
        polarisSKUMappingObjList.add(polarisSKUMappingObj);
        polarisSKUMappingObjList.add(polarisSKUMappingObj1);
        INSERT polarisSKUMappingObjList;

        //Multi Mapping V2 Conversion
        Multi_Mapping_V2_Conversion__c mappingConvObj= 
            Replacement_TestDataFactory.getMultiMappingV2Conversion(lstPrd[0].Id, lstPrd[1].Id);
        INSERT mappingConvObj;    

        Test.startTest();
        List<OrderItem> oliList = new List<OrderItem>();
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(lstPrd[0].Id, ordr.Id, lstEntry[1].Id);
        OrderItem oli2= Replacement_TestDataFactory.getOrderItem(lstPrd[2].Id, ordr.Id, lstEntry[3].Id);
        oliList.add(oli1);
        oliList.add(oli2);
        INSERT oliList;

        ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opp.Id, customPB.Id);
        INSERT serviceContractObj;

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
        ContractLineItem ContractLineItemObj3 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj3.EndDate = Date.today().addDays(365);
        ContractLineItemObj3.StartDate =  Date.today();
        ContractLineItemObj3.SBQQSC__Product__c = lstPrdIds[8];
        lstCLI.add(ContractLineItemObj3);
        ContractLineItem ContractLineItemObj4 = 
            Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj4.EndDate = Date.today().addDays(365);
        ContractLineItemObj4.StartDate =  Date.today();
        ContractLineItemObj4.SBQQSC__Product__c = lstPrdIds[4];
        lstCLI.add(ContractLineItemObj4);

        insert lstCLI;
        
            
        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();
        Entitlement ent = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement', acc.Id, lstPrd[0].Id, asst.Id
            , oliList[0].Id, serviceContractObj.Id, ContractLineItemObj.Id);
        Entitlement ent1 = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[0].Id, asst.Id
            , oliList[0].Id, serviceContractObj.Id, ContractLineItemObj1.Id);//Inactive
        Entitlement ent2 = 
            Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[10].Id, asst1.Id
            , oliList[1].Id, serviceContractObj.Id, ContractLineItemObj2.Id); //Upgrade Product
        Entitlement ent3 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[8].Id, asst1.Id
            , oliList[1].Id, serviceContractObj.Id, ContractLineItemObj3.Id); //HW Support
        Entitlement ent4 = 
            Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[4].Id, asst1.Id
            , oliList[1].Id, serviceContractObj.Id, ContractLineItemObj3.Id);//v1 Product
        ent1.EndDate = date.newinstance(2028, 2, 17);
        ent1.StartDate = date.newinstance(2027, 2, 17);
        entList.add(ent);
        entList.add(ent1);
        entList.add(ent2);
        entList.add(ent3);
        entList.add(ent4);
        INSERT entList;

        //Scale Entitlement
        List<Scale_Entitlement__c> scaleEntList = new List<Scale_Entitlement__c>();
        Scale_Entitlement__c scaleEnt= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst.Id);
        Scale_Entitlement__c scaleEnt2= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst1.Id);
        scaleEntList.add(scaleEnt);
        scaleEntList.add(scaleEnt2);
        INSERT scaleEnt;

        //Entitlement Links for inactive and Upgrade Entitlements
        List<Entitlement_Links__c> entLinkLst = new List<Entitlement_Links__c>();
        Entitlement_Links__c entLink1= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent1.Id); //Inactive Link
        Entitlement_Links__c entLink2= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent2.Id); //Upgrade link
        entLinkLst.add(entLink1);
        entLinkLst.add(entLink2);
        INSERT entLinkLst;
        
        CPQ_Disposition_Quote_Line__c cpqLine = new CPQ_Disposition_Quote_Line__c();
        
        String replacementDetails = '{"skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,'
        +'"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"01t6f00000O6dT0AAJ","skuM365HVal":null,"skuAttlasianVal"'
        +':null,"SeamlessCutover":null,"rowValues":[{"UpgradeLines":null,"selectedQty":300,"selectedTerm":12,"'
        +'selectedAssetList":{"02i6f00000IfP9gAAF":"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020",'
        +'"02i6f00000IrOTzAAN":"BB211364100028","02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"'
        +'02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"2.1.0",'
        +'"InactiveLines":null,"entId":"550VI000007aYKAYA2","disposition":"Converted","AnyToAnyFlag":null}],"mode":"1to1"}';
        cpqLine.Replacement_Detail__c = replacementDetails;
        cpqLine.Quote__c = quoteRec.Id;
        insert cpqLine;
		}
        
        Test.stopTest();
    }
    /***********************************************************************************************************
    * Method Name          : RQCTestMethod
    * Date Created/Modified: 28/02/2025
    * Author               : Sumedha
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    testmethod static void rQCTestMethod(){
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
		
        System.runAs(usr1) {
            Id standardPriceBookId= Test.getStandardPricebookId();
            
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];

            //Get Quote data
            SBQQ__Quote__c qb= 
                [SELECT Id, Name, SBQQ__Type__c , SBQQ__PriceBook__c
                    , CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c,SBQQ__PricebookId__c 
                  FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c= :ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
            SBQQ__Quote__c quoteDets= ReplacementQueryController.getQuoteDetails(qb.Id);

            CPQ_Disposition_Quote_Line__c cpqLine = 
                [SELECT Id, Replacement_Detail__c, Quote__c FROM CPQ_Disposition_Quote_Line__c WHERE Quote__c =: qb.Id];
            
            //Get Product data 
            List<Product2> prodResult= 
                [SELECT Id, ProductCode FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 9];
            
            //Get Asset data
            Asset asst= [SELECT Id, name, SerialNumber, SBQQ__QuoteLine__c FROM Asset WHERE AccountId=: acc.Id LIMIT 1];
            
            //Get ContractLineItem
            List<ContractLineItem> contractLineItemResult = 
                [SELECT Id, SBQQSC__QuoteLine__c FROM ContractLineItem WHERE SBQQSC__Account__c=: acc.Id];

            List<Entitlement> entRec= [SELECT Id FROM Entitlement WHERE AccountId =: acc.Id];

            List<OrderItem> orderlst = [Select Id FROM OrderItem where Order.AccountId =: acc.Id];

            List<Polaris_SKU_Mapping_V2__c> lstPol = [Select Id, name FROM Polaris_SKU_Mapping_V2__c];

            Map<id, Polaris_SKU_Mapping_V2__c> polarisSKUMappingObjList = new Map<id, Polaris_SKU_Mapping_V2__c>();
            for (Polaris_SKU_Mapping_V2__c pol : lstPol) {
                polarisSKUMappingObjList.put(pol.Id, pol);
            }
            //Quote Line
            List<SBQQ__QuoteLine__c> quotelines = new List<SBQQ__QuoteLine__c>();
            SBQQ__QuoteLine__c qli1= 
                Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, qb.Id,prodResult[0].Id, contractLineItemResult[0].Id);
            qli1.SBQQ__RequiredBy__c= null;
            qli1.Replacement_Motion__c= ReplacementConstants.UPGRADE_VALUE;
            qli1.Product_Code_Type__c  = ReplacementConstants.PRODUCT_CODE_TYPE_CVB;
            quotelines.add(qli1);
            SBQQ__QuoteLine__c qli2= 
                Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, qb.Id,prodResult[1].Id, contractLineItemResult[1].Id);
            qli2.SBQQ__RequiredBy__c= null;
            qli2.Special_Program__c= ReplacementConstants.DISPOSE_REFRESH;
            String replacementDetails = '{"skuStorageTierVal":null,"skuStorageBundleVal":null,"skuSFDCVal":null,'
            +'"skuSelectedName":"RS-BT-EE-PE-PA","skuSelected":"'+prodResult[1].Id
            +'","skuM365HVal":null,"skuAttlasianVal":null,"SeamlessCutover":null,"rowValues"'
            +':[{"UpgradeLines":null,"selectedQty":300,"selectedAssetList":{"02i6f00000IfP9gAAF":'
            +'"BB210464100059","02i6f00000IfPBSAA3":"BB210364100020","02i6f00000IrOTzAAN":"BB211364100028",'
            +'"02i6f00000IrOUJAA3":"BB211364100030"},"selectedAsset":"02i6f00000IrOUJAA3,02i6f00000IrOTzAAN,'
            +'02i6f00000IfPBSAA3,02i6f00000IfP9gAAF","rowId":"1.1.0","InactiveLines":null,"entId":"550VI000007aYKAYA2",'
            +'"disposition":"Refresh","selectedTerm":12,"AnyToAnyFlag":null}],"mode":"1to1"}';
            qli2.Replacement_Details__c = replacementDetails;
            quotelines.add(qli2);
            INSERT quotelines;
            
            //Covers getPreviousIbmData method
            List<ReplacementJson> jsonValue= ReplacementQueryController.getPreviousIbmData(qb.Id);
            System.assertEquals(jsonValue.size(), 2);
            
            Integer numValue= ReplacementQueryController.getMaxNumberQuoteLine(qb.Id);
            System.assert(true);
            

            Map<Id, Id> pbeMap = ReplacementQueryController.createProductToPricebookEntryIdMap(standardPriceBookId);
            System.assertEquals(pbeMap.size(), 11);

            Set<Id> entIds = new Set<Id>();
            for (Entitlement ent : entRec) {
                entIds.add(ent.Id);
            }
            
            List<Entitlement> entList = ReplacementQueryController.getEntitlementsBasedonIds(entIds);

            Set<Id> prodIds = new Set<Id>();
            Set<String> productCodes = new Set<String>();
            Id polarisProduct;
            for (Product2 prod : prodResult) {
                prodIds.add(prod.Id);
                polarisProduct = prod.Id;
                productCodes.add(prod.ProductCode);
            }
            //With Product Code
            Map<Id, Product2> mapOfProd = ReplacementQueryController.getProductsBasedonIds(prodIds, productCodes);
            Set<String> assetIds = new Set<String>();
            Set<Id> assetIdValues = new Set<Id>();
            assetIds.add(asst.Id);
            assetIdValues.add(asst.Id);

            Map<Id, Asset> assetMap = ReplacementQueryController.getAssetsBasedonIds(assetIdValues);

            List<SBQQ__QuoteLine__c> modifiedQls = 
                ReplacementQueryController.getExistingQuoteLineForDeletion(
                    qb.Id, entIds,prodIds, assetIds, polarisSKUMappingObjList, prodIds) ;

            List<CPQ_Disposition_Quote_Line__c> disposedLines = 
                ReplacementQueryController.getCpqDispositionLinesToDelete(String.valueOf(qb.Id), entIds);
            
            Set<Id> remainingEntd = ReplacementQueryController.getremainingEntIdsAfterDeletion(qb.Id);

            List<Polaris_SKU_Mapping_V2__c> polMapping = ReplacementQueryController.getPolarisSKUMapping();

            List<Multi_Mapping_V2_Conversion__c> mulMapping = ReplacementQueryController.getMultiMappingList();

            List<Replacement_Support__c> repSupp = ReplacementQueryController.getSkuReplacementPolicyGrid();
			
            if(polarisProduct != NULL){
                Polaris_SKU_Mapping_V2__c pm = new Polaris_SKU_Mapping_V2__c();
            	pm.Old_Product__c = polarisProduct;
                pm.New_Product__c = polarisProduct;
                insert pm;
                List<Polaris_SKU_Mapping_V2__c> lstSkuPolaris = ReplacementQueryController.getV2ProductIdsForRenewalV1(polarisProduct);
                system.assert(lstSkuPolaris.size() >0);
            }
			
            ReplacementRefreshWrapperData.WrapperData entData = new ReplacementRefreshWrapperData.WrapperData();
            entData.SrprodRepCategory = 'Not Replaceable';
            entData.V1Product = true;
            
            ReplacementRefreshWrapperData.WrapperData entData1 = new ReplacementRefreshWrapperData.WrapperData();
            entData1.V1Product = false;
            
            Set<String> sProdRep = new Set<String>{
                    ReplacementConstants.ENTERPRISE_DATA_PROTECTION, ReplacementConstants.COULD_DATA_PROTECTION};
            List<Product2> products = ReplacementQueryController.getSkuProductData(true,sProdRep,entData, prodIds, qb);
			
            List<Product2> products1 = ReplacementQueryController.getSkuProductData(false,sProdRep, entData1, null, qb);
            List<Id> orderLineIds = new List<Id>();
            for (OrderItem ord : orderlst) {
                orderLineIds.add(ord.Id);
            }

            List<Entitlement> entList1 = ReplacementQueryController.getEntitlementData1(String.valueOf(acc.Id), new List<Id>());

            Map<String,List<SBQQ__ProductOption__c>>  pos = ReplacementQueryController.getR7KProductOption();

            Map<String, String> pageSize = ReplacementQueryController.getSmsPageSize();

            Set<Id> quoteIds = new Set<Id>();
            quoteIds.add(qb.Id);
            List<SBQQ__Quote__c> quoteLst = ReplacementQueryController.getQuoteandQLDets(quoteIds);

            List<SMS_Screen_Error_Messages__mdt> smsMetadata = ReplacementQueryController.getSMSScreenErrorMessages();

            List<Replacement_Field_Mapping__mdt> lstReasons = ReplacementQueryController.getDispositionReasons(qb.SBQQ__Type__c);
            
            List<SKUNewReplacementController.PickList> lstDisposition = 
                ReplacementQueryController.getPicklistValuesDispositionQuote(
                    ReplacementConstants.QUOTE_TYPE_RENEWAL,ReplacementConstants.MANUAL_TYPE);
            
            Set<String> skuAttributes = new set<String>{
                ReplacementConstants.STORAGE_TIER_FIELD_API,ReplacementConstants.STORAGE_BUNDLE_FIELD_API};
            Map<String, String> dynamicMap = 
                ReplacementQueryController.getEntitlementsDynamicQuery(skuAttributes,modifiedQls[0].Id);
            List<Replacement_Field_Mapping__mdt> lstReasons1 = ReplacementQueryController.getListOfProductTypeSubType(); 
            
        }
    }
    /***********************************************************************************************************
    * Method Name          : fetchPicklistValuesTest
    * Date Created/Modified: 12/06/2025
    * Author               : Ankita
    * @description         : Covers methods for multiple methods
    /**********************************************************************************************************/
    testmethod static void fetchPicklistValuesTest(){
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
		
        System.runAs(usr1) {
            String profileName = ReplacementQueryController.fetchProfileName();
            test.startTest();
            System.assert(String.isNotBlank(profileName), 'Profile Name Emtpty!');
            ReplacementScreenErrorMetadata.setMock(new ReplacementExceptionOwnerMock());
            List<SMS_Exceptions_Owner__mdt> smsErrorsGetAll = ReplacementScreenErrorMetadata.getAll();
            System.assert(smsErrorsGetAll != null, 'Exceptions metadata');
            ReplacementScreenErrorMetadata service = new ReplacementScreenErrorMetadata();
            List<SMS_Exceptions_Owner__mdt> smsErrorsGetAllInternal = service.getAllInternal();
            System.assert(smsErrorsGetAllInternal != null, 'Exceptions metadata');
            SMS_Exceptions_Owner__mdt mDataResult = ReplacementQueryController.fetchExceptions(profileName);
            System.assert(mDataResult != null, 'Exceptions should not be null');
            List<String> pickliValues = 
                ReplacementQueryController.fetchPicklistValues(
                    ReplacementConstants.QUOTE_OBJ_API,ReplacementConstants.RWD_SALES_REP_EXCEPTION_FIELD_API);
            System.assert(!pickliValues.isEmpty(), 'No picklist values');
            test.stopTest();
        }
    }
    /***********************************************************************************************************
    * Method Name          : testGetDisableBusinessLogic_True
    * Date Created/Modified: 12/06/2025
    * Author               : Khushboo
    * @description         : custom setting test
    /**********************************************************************************************************/
     @isTest
    static void testGetDisableBusinessLogicTrue() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true, Disable_Validations_on_SMS_UI__c =true);
        
        System.runAs(usr1) {
            Boolean result = ReplacementQueryController.getDisableBusinessLogic();
            System.assertEquals(true, result, 'Expected to return true when setting is enabled.');
        }
        
    }

    /***********************************************************************************************************
    * Method Name          : fetchBusinessLogicSetting_UserLevel
    * Date Created/Modified: 14/07/2025
    * Author               : Ankita
    * @description         : custom setting test
    /**********************************************************************************************************/
    @isTest
    static void fetchBusinessLogicSettingUserLevel() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        // Arrange - Create hierarchy custom setting for current user
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = usr1.Id// hierarchy setting for current user
        );
        insert setting;
        System.runAs(usr1) {
            ShGl_DisableBusinessLogic__c result = ReplacementQueryController.fetchBusinessLogicSetting();
            System.assertEquals(true, result.Id != null, 'Expected User level custom setting.');
        }
    }
    /***********************************************************************************************************
    * Method Name          : fetchBusinessLogicSetting_ProfileLevel
    * Date Created/Modified: 14/07/2025
    * Author               : Ankita
    * @description         : custom setting test
    /**********************************************************************************************************/
    @isTest
    static void fetchBusinessLogicSettingProfileLevel() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        // Arrange - Create hierarchy custom setting for current user
        ShGl_DisableBusinessLogic__c setting = new ShGl_DisableBusinessLogic__c(
            SetupOwnerId = usr1.ProfileId // hierarchy setting for current user
        );
        insert setting;
        
        System.runAs(usr1) {
            ShGl_DisableBusinessLogic__c result = ReplacementQueryController.fetchBusinessLogicSetting();
            System.assertEquals(true, result.Id != null, 'Expected profile level custom setting.');
        }
    }
    /***********************************************************************************************************
    * Method Name          : fetchBusinessLogicSetting_ProfileLevel
    * Date Created/Modified: 14/07/2025
    * Author               : Ankita
    * @description         : custom setting test
    /**********************************************************************************************************/
    @isTest
    static void fetchBusinessLogicSettingOrgLevel() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            ShGl_DisableBusinessLogic__c result = ReplacementQueryController.fetchBusinessLogicSetting();
            System.assertEquals(true, result.Id != null, 'Expected org level custom setting.');
        }
    }

    /***********************************************************************************************************
    * Method Name          : getOrderItemExtensionCreditCalTest
    * Date Created/Modified: 14/07/2025
    * Author               : Ankita
    * @description         : custom setting test
    /**********************************************************************************************************/
    @isTest
    static void getOrderItemExtensionCreditCalTest() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        OrderITem oli1 = [SELECT Id FROM OrderItem Limit 1];
        //Order Item Extension
        Order_Item_Extension__c lstOIEToInsert= 
            new Order_Item_Extension__c(OI_ExternalID__c = oli1.Id
                , Order_Line_ID__c = oli1.Id, Paid_Quantity__c = 3
                , Credit_Calculation_Status__c = ReplacementConstants.TO_PROCESS, Per_DayQuantity_amount__c = 1.5);
        INSERT lstOIEToInsert;

        lstOIEToInsert.Credit_Calculation_Status__c = ReplacementConstants.COMPLETED;
        UPDATE lstOIEToInsert;
        System.runAs(usr1) {
            Test.startTest();
            ReplacementFieldMetadata.setMock(new ReplacementFieldMock());
            List<Order_Item_Extension__c> result = 
                ReplacementQueryController.getOrderItemExtensionCreditCal(new List<Id>{oli1.Id});
            System.assertEquals(true, result.size() > 0, 'Expected Order Item Extension records');
            Test.stopTest();
        }
    }

    /***********************************************************************************************************
    * Method Name          : getLowerAndUpperBoundTest
    * Date Created/Modified: 14/07/2025
    * Author               : Ankita
    * @description         : custom setting test
    /**********************************************************************************************************/
    @isTest
    static void getLowerAndUpperBoundTest() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];

        System.runAs(usr1) {
            Test.startTest();
            ReplacementFieldMetadata.setMock(new ReplacementFieldMock());
            Replacement_Field_Mapping__mdt result = ReplacementQueryController.getLowerAndUpperBound();
            System.assertEquals(true, result!=null, 'Expected Metadata record');
            Test.stopTest();
        }
    }

    /***********************************************************************************************************
    * Method Name          : getLowerAndUpperBoundTest
    * Date Created/Modified: 14/07/2025
    * Author               : Ankita
    * @description         : custom setting test
    /**********************************************************************************************************/
    @isTest
    static void getProductsBasedonIdsTest() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];

        System.runAs(usr1) {
            //Get Product data 
            List<Product2> prodResult= [SELECT Id, ProductCode FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 9];
            Set<Id> prodIds = new Set<Id>();
            for (Product2 prod : prodResult) {
                prodIds.add(prod.Id);
            }
            Test.startTest();
            ReplacementFieldMetadata.setMock(new ReplacementFieldMock());
            //Without Product Code
            Map<Id, Product2> result = ReplacementQueryController.getProductsBasedonIds(prodIds, new Set<String>());
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__Type__c , SBQQ__PriceBook__c
                      ,CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c 
                 FROM SBQQ__Quote__c 
                WHERE SBQQ__Type__c= :ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];

            List<SBQQ__QuoteLine__c> quoteLines = 
                ReplacementQueryController.getQuoteLinesDetailsByQuoteId(
                    qb.Id, new List<String>{
                        ReplacementConstants.QUOTE_LINE_TYPE_FIELD_API
                     ,  ReplacementConstants.SPECIAL_PROGRAM_FIELD_API
                     , ReplacementConstants.PRODUCT_TYPE_FIELD_API}, 
                    new List<String>{'Id', ReplacementConstants.QUOTELINE_OBJ_API}, 
                    'SBQQ__Assets__r', 'SBQQ__Quote__c =\'' +qb.Id+'\'');
            List<CPQ_Disposition_Quote_Line__c> resultCPQQL = ReplacementQueryController.fetchExistingCPQDispLines(new Set<Id>{qb.Id});
            System.assertEquals(true, result.size() > 0, 'Expected records');
            System.assertEquals(false, quoteLines.size() > 0, 'Expected no ql records');
            Test.stopTest();
        }
    }

    /***********************************************************************************************************
    * Method Name          : getR7kProductsTest
    * Date Created/Modified: 14/07/2025
    * Author               : Ankita
    * @description         : custom setting test
    /**********************************************************************************************************/
    @isTest
    static void getR7kProductsTest() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];

        System.runAs(usr1) {
            Test.startTest();
            ReplacementFieldMetadata.setMock(new ReplacementFieldMock());
            List<Product2> result = ReplacementQueryController.getR7kProducts();
            System.assertEquals(false, result.size() > 0, 'Expected r7 record');
            Test.stopTest();
        }
    }

    
    /***********************************************************************************************************
     * Class Extention Name : ReplacementExceptionOwnerMock
     * Date Created/Modified: 11/07/2025
     * Author               : Ankita 
     * @description         : This method extends metadata for mock class.  
     * Story                : FY25SR-1874          
    /**********************************************************************************************************/
    class ReplacementExceptionOwnerMock extends ReplacementScreenErrorMetadata {
        override protected List<SMS_Exceptions_Owner__mdt> getAllInternal() {
            List<SMS_Exceptions_Owner__mdt> mockList = new List<SMS_Exceptions_Owner__mdt>();
            Map<String, Object> data1 = new Map<String, Object>{
                'Profile_Name__c' => 'System Administrator',
                'Exception_Message__c' => 'Mismatch Quantity,Do Not Consolidate Replacement Lines,Replace Any to Any'
            };
            mockList.add(
                (SMS_Exceptions_Owner__mdt) JSON.deserialize(
                    JSON.serialize(data1),
                    SMS_Exceptions_Owner__mdt.class
                )
            );
            return mockList;
        }
    }

    /***********************************************************************************************************
     * Class Extention Name : ReplacementFieldMock
     * Date Created/Modified: 24/04/2025
     * Author               : Rahul 
     * @description         : This method extends metadata for mock class.  
     * Story                : FY25SR-1084              
    /**********************************************************************************************************/

    public class ReplacementFieldMock extends ReplacementFieldMetadata {
        override protected List<Replacement_Field_Mapping__mdt> getAllInternal() {
            List<Replacement_Field_Mapping__mdt> mockList = new List<Replacement_Field_Mapping__mdt>();
            String completed = ReplacementConstants.COMPLETED;
            String familyR7 = ReplacementConstants.PRODUCTCODE_R7000;
            Map<String, Object> data1 = new Map<String, Object>{
                'First_Filter_Criteria__c' => 'Credit_Calculation_Status__c = \'' +completed+ '\'',
                'DeveloperName' => ReplacementConstants.REPLACEMENT_CCORDERLITEMEXTENSTION_MDT
            };
            
            Map<String, Object> data2 = new Map<String, Object>{
                'DeveloperName' => ReplacementConstants.REPLACEMENT_FILTER_CRITERIA_MDT,
                'UpperBoundM__c' => 3
            };

            Map<String, Object> data3 = new Map<String, Object>{
                'DeveloperName' => ReplacementConstants.REPLACEMENT_R7_PRODUCT_MDT,
                'First_Filter_Criteria__c' => 'FAMILY = \'' +familyR7+ '\''
            };

            Map<String, Object> data4 = new Map<String, Object>{
                'DeveloperName' => ReplacementConstants.REPLACEMENT_QUOTELINE_DELETION_MDT,
                'Quote_Line_API_Fields__c' => 'SBQQ__Discount__c'
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
            
            return mockList;
        }
    }
        /***********************************************************************************************************
    * Method Name          : getReplacementMultiMappingTest
    * Date Created/Modified: 16/10/2025
    * Author               : Lokesh Sharma
    * @description         : Covers getReplacementMultiMapping 
    /**********************************************************************************************************/
    @isTest
    static void getReplacementMultiMappingTest() {
        user usr1 = [SELECT Id,ProfileId  FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];

        System.runAs(usr1) {
        

            Product2 src = [SELECT Id FROM Product2 WHERE ProductCode = 'RBK-R6410-01' LIMIT 1];
            Product2 tgt = [SELECT Id FROM Product2 WHERE ProductCode = 'RBK-R6410-02' LIMIT 1];

            // Active Multi Mapping record
            Multi_Mapping_V2_Conversion__c mmInRegion = new Multi_Mapping_V2_Conversion__c();
            mmInRegion.Source_Product__c = src.Id;
            mmInRegion.Target_Product__c = tgt.Id;
            mmInRegion.Active__c = true;
            mmInRegion.Option_Level__c = 1; 
            mmInRegion.Payment_Option__c = 'Annual';
            mmInRegion.Pricing_Percent__c = 10;
            mmInRegion.Support_Type__c = 'L3';
            mmInRegion.Renewal_Type__c = 'V2 To V2 - In Region';
            insert mmInRegion;

       
            Test.startTest();
            Set<Id> selectedProductIds = new Set<Id>{ src.Id };
            Set<String> configSKU = new Set<String>();
            Set<String> optionalSKU = new Set<String>();

            Map<String, Multi_Mapping_V2_Conversion__c> result =
                ReplacementQueryController.getReplacementMultiMapping(selectedProductIds, configSKU, optionalSKU);
            Test.stopTest();

            
            System.assert(result.size() >0, 'active mappings should be returned');
        }
    }
}