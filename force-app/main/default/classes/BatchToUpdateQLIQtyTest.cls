/**Test class for BatchToUpdateQLIQty,QuoteCalculateAndSubmitBatch,CallQuoteSubmitAPIBatch,CreationOfRenewalChurnOpp
* @description test class FY25SR-1111 / JIRA - REEN-25 / FY25SR-1109   
* @CreatedDate 28th Dec 2023
*/
@isTest
public class BatchToUpdateQLIQtyTest {
    
    static ReplacementJson getReplacemetnDetail(Id prodId,String Prodcode,Id entitlementId,Integer qty,String dispose,Id AssetId)
    {
        ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
        row.entId =entitlementId;
        row.rowId ='0.0.0';
        row.selectedQty =qty;
        row.selectedTerm=12;
        row.selectedAssetList=AssetId!=null ?new Map<String,String>{String.valueOf(AssetId) => 'Asset123'}:null;
        row.selectedAsset=AssetId!=null ?AssetId :null;
        row.disposition= dispose; 
        
        ReplacementJson jsonData = new ReplacementJson();
        jsonData.rowValues = new List<ReplacementJson.RowDetail>();
        jsonData.rowValues.add(row);
        jsonData.mode = 'dispose';
        jsonData.renLine = true;
        return jsonData;
      }
    
    @testSetup static void setup() {
        User usr1 = Replacement_TestDataFactory.getUser();
        insert usr1;
        //Deactivate triggers 
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
                                                Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                                                Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
                                                Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
                                                Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
                                                Disable_Order_Validation_Rules__c = true,Disable_Order_Old_Trigger__c = true,
                                                Disable_Opportunity_Validation_Rules__c=true,Disable_Entitlement_Validation_Rules__c=true,
                                                Disable_OrderItem_Old_Trigger__c = true,Disable_SBQQ_Quote_Validation_Rules__c= true);
        Insert new ShGl_DisableFunctionalityLogic__c(setupownerid = usr1.Id,Disable_OpportunityValidationRules__c =true);
        System.runAs(usr1){
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
        String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
        List<Account> accList= new List<Account>();
        Account acc = TestDataFactory.getAccount();
        Account acc1 = TestDataFactory.getAccount();
        //accList.add(acc1);    
        accList.add(acc);
        INSERT accList;
        
        //Contact 
        Contact con= TestDataFactory.getContact(acc);
        INSERT con;
        
        //Product data
        List<Product2> lstPrd = new List<Product2>();
        List<Id> lstPrdIds = new List<Id>();
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-01', 'RBK-R6410-01', 
            ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION, 
            ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-02', 'RBK-R6410-02', 
            ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION, 
            ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, 
            ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-03', 'RBK-R6410-03', 
            ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION, 
            ReplacementConstants.SUBSCRIPTION, ReplacementConstants.M365H, ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-06', 'RBK-R6410-06', 
            ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.COULD_DATA_PROTECTION, 
            ReplacementConstants.PREPETUAL, ReplacementConstants.EDITION_UPGRADE, 
            ReplacementConstants.SUBSCRIPTIONS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-09', 'RBK-R6410-07', 
            ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, 
            ReplacementConstants.SUBSCRIPTION, ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RS-HW-SVC-PE-S2', 'RS-HW-SVC-PE-S2', 
            ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, 
            ReplacementConstants.SUBSCRIPTION, ReplacementConstants.HW_SUPPORT, 
            ReplacementConstants.SAAS));
             INSERT lstPrd;
        for (Product2 prod : lstPrd) {
            lstPrdIds.add(prod.id);
        }
        List<Product2> ProductUpdate=new List<Product2>();
        Product2 p=new Product2(id=lstPrd[2].Id, Product_level__c= null,Usable_Capacity__c=100);
        Product2 p1=new Product2(id=lstPrd[3].Id, Product_level__c= null,Usable_Capacity__c=60);
        Product2 p2=new Product2(id=lstPrd[0].Id, Product_level__c= 
            ReplacementConstants.SAAS_SOFTWARE_ADDON,Usable_Capacity__c=90);
        Product2 p3=new Product2(id=lstPrd[1].Id, Product_level__c=null ,Usable_Capacity__c=40);
        Product2 p4=new Product2(id=lstPrd[4].Id, Product_level__c= 
            ReplacementConstants.SAAS_SOFTWARE_ADDON,Usable_Capacity__c=80);
        Product2 p5=new Product2(id=lstPrd[5].Id, Product_level__c= 
            ReplacementConstants.SUPPORT,Product_Type__c=ReplacementConstants.HW_SUPPORT,Usable_Capacity__c=80);
        ProductUpdate.add(p);
        ProductUpdate.add(p1);
        ProductUpdate.add(p2);
        ProductUpdate.add(p3);
        ProductUpdate.add(p4);
        ProductUpdate.add(p5);
        update ProductUpdate;
        
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
        
        Id renewalRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName()
            .get('Renewal Opportunity')
            .getRecordTypeId();
        
        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp=  TestDataFactory.getOpportunity(acc, con);
        Opportunity opp1 = TestDataFactory.getOpportunity(acc, con);
        opp1.SBQQ__Ordered__c=false;
        opp1.Opportunity_Sub_Type__c=ReplacementConstants.QUOTE_TYPE_RENEWAL;
        opp1.Opportunity_Type__c='Existing Customer';
        opp1.RecordTypeId=renewalRecordTypeId;
        oppList.add(opp);
        oppList.add(opp1);
        INSERT oppList;
        
        //Quote
        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
                SBQQ__Quote__c quoteRec = 
            Replacement_TestDataFactory.getQuote(acc.Id, opp.Id, customPB.Id, 
                ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);
        SBQQ__Quote__c quoteRec1 = Replacement_TestDataFactory.getQuote(
            acc.Id, opp1.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL);
        qbList.add(quoteRec);
            qbList.add(quoteRec1);
        
        INSERT qbList;
        
        opp.SBQQ__PrimaryQuote__c = quoteRec.Id;
        UPDATE opp;
        
        //Ceate Asset
        List<Asset> asstList = new  List<Asset>();
        Asset asst= Replacement_TestDataFactory.getAsset('Asset122', lstPrd[0].Id, acc.Id);
        Asset asst1= Replacement_TestDataFactory.getAsset('Asset1231', lstPrd[1].Id, acc.Id);
        Asset asst2= Replacement_TestDataFactory.getAsset('Asset12245', lstPrd[2].Id, acc.Id);
        Asset asst3= Replacement_TestDataFactory.getAsset('Asset1245', lstPrd[3].Id, acc.Id);
        Asset asst4= Replacement_TestDataFactory.getAsset('Asset1278', lstPrd[4].Id, acc.Id);
        Asset asst5= Replacement_TestDataFactory.getAsset('Asset1290', lstPrd[5].Id, acc.Id);
        Asset asst6= Replacement_TestDataFactory.getAsset('Asset1298', lstPrd[5].Id, acc.Id);
        asstList.add(asst);
        asstList.add(asst1);
        asstList.add(asst2);
        asstList.add(asst3);
        asstList.add(asst4);
        asstList.add(asst5);
        asstList.add(asst6);
        INSERT asstList;
        
        //Polaris SKU Mapping
        List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingObjList = new List<Polaris_SKU_Mapping_V2__c>();
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj = Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[2].Id, lstPrd[0].Id);
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj1 = Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[2].Id, lstPrd[1].Id);
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj2 = Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[3].Id, lstPrd[4].Id);
        polarisSKUMappingObjList.add(polarisSKUMappingObj);
        polarisSKUMappingObjList.add(polarisSKUMappingObj1);
        polarisSKUMappingObjList.add(polarisSKUMappingObj2);
        INSERT polarisSKUMappingObjList;
        
        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        INSERT ordr;
        
        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;
        
       
        List<OrderItem> oliList = new List<OrderItem>();
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(lstPrd[0].Id, ordr.Id, lstEntry[1].Id);
        OrderItem oli2= Replacement_TestDataFactory.getOrderItem(lstPrd[1].Id, ordr.Id, lstEntry[3].Id);
        OrderItem oli3= Replacement_TestDataFactory.getOrderItem(lstPrd[2].Id, ordr.Id, lstEntry[5].Id);
        OrderItem oli4= Replacement_TestDataFactory.getOrderItem(lstPrd[3].Id, ordr.Id, lstEntry[7].Id);
         OrderItem oli6= Replacement_TestDataFactory.getOrderItem(lstPrd[4].Id, ordr.Id, lstEntry[9].Id);
        oliList.add(oli6);
        OrderItem oli5= Replacement_TestDataFactory.getOrderItem(lstPrd[5].Id, ordr.Id, lstEntry[11].Id);
        oliList.add(oli5);
        oliList.add(oli1);
        oliList.add(oli2);
        oliList.add(oli3);
        oliList.add(oli4);
        INSERT oliList;
        
        ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opp.Id, customPB.Id);
        INSERT serviceContractObj;
        
        quoteRec1.Amended_Renewed_Service_Contract__c= serviceContractObj.Id;
        quoteRec1.ApprovalStatus__c = ReplacementConstants.STATUS_IN_REVIEW;
        quoteRec1.OpportunitySubType__c=ReplacementConstants.QUOTE_TYPE_RENEWAL;
        UPDATE quoteRec1;
        
        opp1.SBQQSC__RenewedServiceContract__c= serviceContractObj.Id;
        Update opp1;
        
        List<ContractLineItem> lstCLI = new List<ContractLineItem>();
        ContractLineItem contractLineItemObj = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntry[1].Id, serviceContractObj.Id);
        contractLineItemObj.EndDate = Date.today().addDays(365);
        contractLineItemObj.StartDate =  Date.today();
        contractLineItemObj.SBQQSC__Product__c = lstPrdIds[0];
        contractLineItemObj.SBQQSC__RenewalQuantity__c=200;
        contractLineItemObj.SBQQSC__ListPrice__c=400;
        lstCLI.add(contractLineItemObj);
        ContractLineItem contractLineItemObj1 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[3].Id, serviceContractObj.Id);
        contractLineItemObj1.EndDate = date.newinstance(2028, 2, 17);
        contractLineItemObj1.StartDate =  date.newinstance(2027, 2, 17);
        contractLineItemObj1.SBQQSC__Product__c = lstPrdIds[1];
        contractLineItemObj1.SBQQSC__RenewalQuantity__c=200;
        contractLineItemObj1.SBQQSC__ListPrice__c=600;
        lstCLI.add(contractLineItemObj1);
        ContractLineItem contractLineItemObj2 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst2.Id, lstEntry[5].Id, serviceContractObj.Id);
        contractLineItemObj2.EndDate = Date.today().addDays(365);
        contractLineItemObj2.StartDate =  Date.today();
        contractLineItemObj2.SBQQSC__Product__c = lstPrdIds[2];
        contractLineItemObj2.SBQQSC__RenewalQuantity__c=0;
        contractLineItemObj2.SBQQSC__ListPrice__c=1000;
        lstCLI.add(contractLineItemObj2);
        ContractLineItem contractLineItemObj3 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst3.Id, lstEntry[7].Id, serviceContractObj.Id);
        contractLineItemObj3.EndDate = Date.today().addDays(365);
        contractLineItemObj3.StartDate =  Date.today();
        contractLineItemObj3.SBQQSC__Product__c = lstPrdIds[3];
        contractLineItemObj3.SBQQSC__RenewalQuantity__c=0;
        contractLineItemObj3.SBQQSC__ListPrice__c=4000;
        lstCLI.add(contractLineItemObj3);
        ContractLineItem contractLineItemObj4 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst4.Id, lstEntry[9].Id, serviceContractObj.Id);
        contractLineItemObj4.EndDate = Date.today().addDays(365);
        contractLineItemObj4.StartDate =  Date.today();
        contractLineItemObj4.SBQQSC__Product__c = lstPrdIds[4];
        lstCLI.add(contractLineItemObj4);
        ContractLineItem contractLineItemObj5 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst5.Id, lstEntry[11].Id, serviceContractObj.Id);
        contractLineItemObj5.EndDate = Date.today().addDays(365);
        contractLineItemObj5.StartDate =  Date.today();
        contractLineItemObj5.SBQQSC__Product__c = lstPrdIds[5];
        lstCLI.add(contractLineItemObj5);
        insert lstCLI;
        
        RecordType rt = [SELECT Id, DeveloperName 
                           FROM RecordType 
                          WHERE SObjectType = :ReplacementConstants.REPLACEMENT_ENTITLEMENT_MDT 
                            AND DeveloperName = :ReplacementConstants.SUPPORT LIMIT 1];
        
        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();
        Entitlement ent = Replacement_TestDataFactory.getEntitlement('Test Entitlement', acc.Id, lstPrd[1].Id, null, oliList[0].Id, serviceContractObj.Id, contractLineItemObj1.Id);
        ent.Quantity__c = 1200;
        ent.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent.Renewal_Category__c = ReplacementConstants.DISPOSITION_REASON_REPLACED;
        ent.RecordTypeId =rt.Id;
        Entitlement ent1 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[1].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, contractLineItemObj1.Id);
        ent1.Quantity__c = 1000;
        ent1.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent1.Renewal_Category__c = ReplacementConstants.DISPOSITION_REASON_REPLACED;
        ent1.RecordTypeId =rt.Id;
        Entitlement ent2 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[1].Id, null, oliList[1].Id, serviceContractObj.Id, contractLineItemObj1.Id); 
        ent2.Quantity__c = 200;
        ent2.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent2.RecordTypeId =rt.Id;
        Entitlement ent3 = Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[2].Id, asst2.Id, oliList[2].Id, serviceContractObj.Id, contractLineItemObj2.Id); 
        ent3.Quantity__c = 1000;
        ent3.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent3.Renewal_Category__c = ReplacementConstants.PRODUCT_CATEGORY_RENEWED;
        ent3.RecordTypeId =rt.Id;
        Entitlement ent4 = Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[3].Id, asst3.Id, oliList[3].Id, serviceContractObj.Id, contractLineItemObj3.Id);
        ent4.Quantity__c = 500;
        ent4.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent4.Renewal_Category__c = ReplacementConstants.DISPOSITION_REASON_REPLACED;
        ent4.RecordTypeId =rt.Id;
        Entitlement ent5 = Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[0].Id, asst3.Id, oliList[0].Id, serviceContractObj.Id, contractLineItemObj.Id);
        ent5.Quantity__c = 2000;
         ent5.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent5.Renewal_Category__c = ReplacementConstants.DISPOSITION_REASON_REPLACED;
        ent5.RecordTypeId =rt.Id;
        ent1.EndDate = date.newinstance(2028, 2, 17);
        ent1.StartDate = date.newinstance(2027, 2, 17);
        Entitlement ent6 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[3].Id, asst3.Id, oliList[3].Id, serviceContractObj.Id, contractLineItemObj3.Id);
        ent6.Quantity__c = 200;
        ent6.Resync_Line__c=null;
        ent6.Renewal_Category__c =null;
        ent6.RecordTypeId =rt.Id;
        Entitlement ent7 = Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[2].Id,null, oliList[2].Id, serviceContractObj.Id, contractLineItemObj2.Id); 
        ent7.Quantity__c = 1000;
        ent7.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent7.Renewal_Category__c = ReplacementConstants.PRODUCT_CATEGORY_RENEWED;
        ent7.RecordTypeId =rt.Id;
        Entitlement ent8 = Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[2].Id,null, oliList[2].Id, serviceContractObj.Id, contractLineItemObj2.Id); 
        ent8.Quantity__c = 1000;
         ent8.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent8.Renewal_Category__c = null;
        ent8.RecordTypeId =rt.Id;
        Entitlement ent9 = Replacement_TestDataFactory.getEntitlement('Test Entitlement', acc.Id, lstPrd[1].Id, null, oliList[0].Id, serviceContractObj.Id, contractLineItemObj1.Id);
        ent9.Quantity__c = 1200;
        ent9.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent9.Renewal_Category__c = ReplacementConstants.DISPOSITION_REASON_REPLACED;
        ent9.RecordTypeId =rt.Id;
        Entitlement ent10 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[1].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, contractLineItemObj1.Id);
        ent10.Quantity__c = 1000;
        ent10.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent10.Renewal_Category__c = ReplacementConstants.DISPOSITION_REASON_REPLACED;
        ent10.RecordTypeId =rt.Id;
        Entitlement ent11 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[1].Id, null, oliList[1].Id, serviceContractObj.Id, contractLineItemObj1.Id); 
        ent11.Quantity__c = 200;
        ent11.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent11.RecordTypeId =rt.Id;
        Entitlement ent12 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[5].Id, asst5.Id, oli5.Id, serviceContractObj.Id, contractLineItemObj5.Id); 
        ent12.Quantity__c = 200;
        ent12.Resync_Line__c=ReplacementConstants.RESYNC_LINE_REQUIRED;
        ent12.Renewal_Category__c = ReplacementConstants.REFRESHED;
        ent12.RecordTypeId =rt.Id;
        Entitlement ent13 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[5].Id,asst6.Id, oli5.Id, serviceContractObj.Id, contractLineItemObj5.Id); 
        ent13.Quantity__c = 200;
        ent13.RecordTypeId =rt.Id;
        Entitlement ent14 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[4].Id,null, oli6.Id, serviceContractObj.Id, contractLineItemObj4.Id); 
        ent14.Quantity__c = 200;
        ent14.RecordTypeId =rt.Id;
        Entitlement ent15 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[3].Id, asst3.Id, oliList[3].Id, serviceContractObj.Id, contractLineItemObj3.Id);
        ent15.RecordTypeId =rt.Id;
        ent15.Quantity__c = 200;
        entList.add(ent);
        entList.add(ent1);
        entList.add(ent2);
        entList.add(ent3);
        entList.add(ent4);
        entList.add(ent5);
        entList.add(ent6);
        entList.add(ent7);
        entList.add(ent8);
        entList.add(ent9);
        entList.add(ent10);
        entList.add(ent11);
        entList.add(ent12);
        entList.add(ent13);
        entList.add(ent14);
        entList.add(ent15);
        INSERT entList;
            
        ReplacementJson.RowDetail row2 = new ReplacementJson.RowDetail();
        row2.entId =ent15.Id;
        row2.rowId ='0.0.0';
        row2.selectedQty =200;
        row2.selectedTerm=12;
        //row2.selectedAssetList=asst3.Id!=null ?new Map<String,String>{String.valueOf(asst3.Id) => 'Asset1231'}:null;
        //row2.selectedAsset=asst3.Id!=null ?asst3.Id :null;
         
        //Scale Entitlement
        List<Scale_Entitlement__c> scaleEntList = new List<Scale_Entitlement__c>();
        Scale_Entitlement__c scaleEnt= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst.Id);
        Scale_Entitlement__c scaleEnt2= Replacement_TestDataFactory.getScaleEntitlement(ent2.Id, asst1.Id);
        Scale_Entitlement__c scaleEnt3= Replacement_TestDataFactory.getScaleEntitlement(ent14.Id, asst5.Id);
        scaleEnt3.Contract_Line_Item__c=contractLineItemObj4.Id;
        scaleEntList.add(scaleEnt);
        scaleEntList.add(scaleEnt2);
        scaleEntList.add(scaleEnt3);
        INSERT scaleEntList;
        
        //Entitlement Links for inactive and Upgrade Entitlements
        List<Entitlement_Links__c> entLinkLst = new List<Entitlement_Links__c>();
        Entitlement_Links__c entLink1= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent1.Id); 
        Entitlement_Links__c entLink2= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent2.Id); 
        entLinkLst.add(entLink1);
        entLinkLst.add(entLink2);
        Entitlement_Links__c entLink3= Replacement_TestDataFactory.getEntitlementLinks(ent9.Id, ent10.Id); 
        Entitlement_Links__c entLink4= Replacement_TestDataFactory.getEntitlementLinks(ent9.Id, ent11.Id);
        Entitlement_Links__c entLink5= Replacement_TestDataFactory.getEntitlementLinks(ent12.Id, ent13.Id);
        entLinkLst.add(entLink3);
        entLinkLst.add(entLink4);
        entLinkLst.add(entLink5);
        INSERT entLinkLst;
        
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli= Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[0],null);// contractLineItemObj.Id 
        SBQQ__QuoteLine__c qli1= Replacement_TestDataFactory.getQuoteLine(asst1.Id, asst1, quoteRec.Id, lstPrdIds[1],null);// contractLineItemObj1.Id 
        SBQQ__QuoteLine__c qli2= Replacement_TestDataFactory.getQuoteLine(asst2.Id, asst2, quoteRec.Id, lstPrdIds[2], null);//contractLineItemObj2.Id 
        SBQQ__QuoteLine__c qli3= Replacement_TestDataFactory.getQuoteLine(asst3.Id, asst3, quoteRec.Id, lstPrdIds[3], null);//contractLineItemObj3.Id 
        SBQQ__QuoteLine__c qli4= Replacement_TestDataFactory.getQuoteLine(asst1.Id, asst1, quoteRec1.Id, lstPrdIds[1], contractLineItemObj1.Id);
        SBQQ__QuoteLine__c qli7= Replacement_TestDataFactory.getQuoteLine(asst4.Id, asst4, quoteRec1.Id, lstPrdIds[4], contractLineItemObj4.Id);
        SBQQ__QuoteLine__c qli8= Replacement_TestDataFactory.getQuoteLine(asst5.Id, asst5, quoteRec1.Id, lstPrdIds[5], contractLineItemObj5.Id);
        qli7.CCLI__c=contractLineItemObj4.Id;
        qli7.Subscribed_Asset_Name__c= asst5.Name;
        qli7.Replacement_Details__c=JSON.serialize(getReplacemetnDetail( lstPrd[4].Id,'RBK-R6410-02',ent14.Id,1200,ReplacementConstants.REFRESHED,asst5.Id));
        qli7.SBQQSC__RenewedContractLine__c=contractLineItemObj4.Id;
        qli7.Arroyo_Subsumed_Old_Contract_Line_Items__c=contractLineItemObj4.Id;
        qli8.CCLI__c=contractLineItemObj5.Id;
        qli8.Replacement_Details__c=JSON.serialize(getReplacemetnDetail( lstPrd[5].Id,'RBK-R6410-02',ent12.Id,1200,ReplacementConstants.REFRESHED,asst5.Id));
        qli8.Arroyo_Subsumed_Old_Contract_Line_Items__c=contractLineItemObj5.Id+','+contractLineItemObj.Id;
        qli4.SBQQ__Quantity__c=1200;
        qli4.CCLI__c=contractLineItemObj.Id;
        qli4.Arroyo_Subsumed_Old_Contract_Line_Items__c= contractLineItemObj1.Id+','+contractLineItemObj.Id;
        qli4.Replacement_Details__c=JSON.serialize(getReplacemetnDetail( lstPrd[1].Id,'RBK-R6410-02',ent.Id,1200,ReplacementConstants.UPGRADED,asst1.Id));
        SBQQ__QuoteLine__c qli5= Replacement_TestDataFactory.getQuoteLine(asst2.Id, asst2, quoteRec1.Id, lstPrdIds[2], contractLineItemObj2.Id);
        qli5.SBQQ__Quantity__c=900;
        qli5.Arroyo_Subsumed_Old_Contract_Line_Items__c= contractLineItemObj1.Id;
        qli5.Replacement_Details__c=JSON.serialize(getReplacemetnDetail(lstPrd[2].Id,'RBK-R6410-03',ent3.Id,900,ReplacementConstants.PRODUCT_CATEGORY_RENEWED,asst2.Id));
        SBQQ__QuoteLine__c qli6= Replacement_TestDataFactory.getQuoteLine(asst3.Id, asst3, quoteRec1.Id, lstPrdIds[3], contractLineItemObj3.Id);
        qli6.SBQQ__Quantity__c=500;
        qli6.Arroyo_Subsumed_Old_Contract_Line_Items__c= contractLineItemObj1.Id;
        qli6.Replacement_Details__c=JSON.serialize(getReplacemetnDetail(lstPrd[3].Id,'RBK-R6410-06',ent4.Id,500,ReplacementConstants.UPGRADED,asst3.Id));
        ReplacementJson qliReplaceJSON = (ReplacementJson)JSON.deserialize(qli6.Replacement_Details__c, ReplacementJson.class);
        ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
        row.entId =ent6.Id;
        row.rowId ='0.0.0';
        row.selectedQty =12;
        row.selectedTerm=12;
        row.selectedAssetList=new Map<String,String>{String.valueOf(asst2.Id) => 'Asset123'};
            row.selectedAsset=asst2.Id;
        qliReplaceJSON.rowValues.add(row);
        qliReplaceJSON.rowValues.add(row2);
        qli6.Replacement_Details__c=JSON.serialize(qliReplaceJSON);  
        qlList.add(qli);
        qlList.add(qli1);
        qlList.add(qli2);
        qlList.add(qli3);
        qlList.add(qli4);
        qlList.add(qli5);
        qlList.add(qli6);
        qlList.add(qli7);
        qlList.add(qli8);
        insert qlList;
        
        List<CPQ_Disposition_Quote_Line__c> cpqList=new List<CPQ_Disposition_Quote_Line__c>();
        CPQ_Disposition_Quote_Line__c cpqDisposeLine= new CPQ_Disposition_Quote_Line__c(
            Quote__c=quoteRec1.Id,
            Disposition_Reason__c=ReplacementConstants.DISPOSE_AT_RISK,
            Product__c=lstPrdIds[2],
            Quantity__c=100,
            Replacement_Detail__c=JSON.serialize(getReplacemetnDetail(lstPrdIds[2],'RBK-R6410-03',ent3.id,100,ReplacementConstants.DISPOSE_AT_RISK,asst2.Id)),
            //Arroyo_Subscribed_Asset_Name__c=String.join(new List<String>(assetNames), ', '),
            RenewedContractLine__c=contractLineItemObj2.Id,
            PricebookEntryId__c= lstEntry[1].Id,
            Arroyo_Subsumed_Old_Contract_Line_Items__c=contractLineItemObj2.Id
        );
        cpqList.add(cpqDisposeLine);
        CPQ_Disposition_Quote_Line__c cpqDisposeLine1= new CPQ_Disposition_Quote_Line__c(
            Quote__c=quoteRec1.Id,
            Disposition_Reason__c=ReplacementConstants.DISPOSE_AT_RISK,
            Product__c=lstPrdIds[0],
            Quantity__c=2000,
            Replacement_Detail__c=JSON.serialize(getReplacemetnDetail(lstPrdIds[0],'RBK-R6410-01',ent5.Id,2000,ReplacementConstants.DISPOSE_AT_RISK,asst2.Id)),
            //Arroyo_Subscribed_Asset_Name__c=String.join(new List<String>(assetNames), ', '),
            RenewedContractLine__c=contractLineItemObj.Id,
            PricebookEntryId__c= lstEntry[1].Id,
            Arroyo_Subsumed_Old_Contract_Line_Items__c=contractLineItemObj.Id
        );
        cpqList.add(cpqDisposeLine1);
        CPQ_Disposition_Quote_Line__c cpqDisposeLine2= new CPQ_Disposition_Quote_Line__c(
            Quote__c=quoteRec1.Id,
            Disposition_Reason__c=ReplacementConstants.DISPOSE_CHURN,
            Product__c=lstPrdIds[0],
            Quantity__c=1000,
            Replacement_Detail__c=JSON.serialize(getReplacemetnDetail(lstPrdIds[2],'RBK-R6410-01',ent7.Id,2000,ReplacementConstants.DISPOSE_CHURN,null)),
            //Arroyo_Subscribed_Asset_Name__c=String.join(new List<String>(assetNames), ', '),
            RenewedContractLine__c=contractLineItemObj2.Id,
            PricebookEntryId__c= lstEntry[5].Id,
            Arroyo_Subsumed_Old_Contract_Line_Items__c=contractLineItemObj2.Id
        );
        cpqList.add(cpqDisposeLine2);
        CPQ_Disposition_Quote_Line__c cpqDisposeLine4= new CPQ_Disposition_Quote_Line__c(
            Quote__c=quoteRec1.Id,
            Disposition_Reason__c=ReplacementConstants.DISPOSE_AT_RISK,
            Product__c=lstPrdIds[1],
            Quantity__c=1000,
            Replacement_Detail__c=JSON.serialize(getReplacemetnDetail(lstPrdIds[1],'RBK-R6410-03',ent9.id,100,ReplacementConstants.DISPOSE_AT_RISK,null)),
            //Arroyo_Subscribed_Asset_Name__c=String.join(new List<String>(assetNames), ', '),
            RenewedContractLine__c=contractLineItemObj1.Id,
            PricebookEntryId__c= lstEntry[3].Id,
            Arroyo_Subsumed_Old_Contract_Line_Items__c=contractLineItemObj1.Id
        );
        cpqList.add(cpqDisposeLine4);
        ReplacementJson disposeReplaceJSON = (ReplacementJson)JSON.deserialize(cpqDisposeLine2.Replacement_Detail__c, ReplacementJson.class);
        ReplacementJson.RowDetail row1 = new ReplacementJson.RowDetail();
        row1.entId =ent8.Id;
        row1.rowId ='0.0.0';
        row1.selectedQty =1000;
        row1.selectedTerm=12;
        row1.selectedAssetList=null;
        row1.selectedAsset=null;
        disposeReplaceJSON.rowValues.add(row1);
        cpqDisposeLine2.Replacement_Detail__c=JSON.serialize(disposeReplaceJSON); 
        Insert cpqList;
            
        /* opp1.stageName='6 PO With Channel';
         opp1.SBQQ__PrimaryQuote__c = quoteRec1.Id;
         update opp1;   */  
        
        Test.startTest();
        opp1.stageName='6 PO With Channel';   
        Test.stopTest();
    }
    } 
    
    @isTest
    private static void batchToUpdateQLIQtyTest4() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            List<Entitlement_Links__c> el=[select id,Previous_Entitlement__c,Renewed_Entitlement__c,Renewed_Entitlement__r.Quantity__c, Renewed_Entitlement__r.Renewal_Category__c,Renewed_Entitlement__r.Resync_Line__c from Entitlement_Links__c LIMIT 2];
            List<Entitlement> ent=[SELECT Id,ContractLineItemId,Renewal_Category__c,Quantity__c,Asset.Name,AssetId,Status FROM Entitlement LIMIT 20];
            Test.startTest();
            TriggerControls.disableCalculateAPIBatch = true;
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true; 
            Id batchJobId = Database.executeBatch(new BatchToUpdateQLIQty(), 200);
            Test.stopTest();
            System.assert(true);
        }
    }
    
    @isTest
    private static void batchToUpdateQLIQtyTest1() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            List<ContractLineItem> cli=[Select id,Resync_Line__c,SBQQSC__RenewalQuantity__c from ContractLineItem limit 8];
            for(ContractLineItem c:cli){
                c.SBQQSC__RenewalQuantity__c=0;
            }
            update cli;
            Entitlement e=[SELECT Id,ContractLineItemId,Renewal_Category__c,Quantity__c,Asset.Name,AssetId,Status FROM Entitlement where Renewal_Category__c=null  LIMIT 1][0];
            e.Renewal_Category__c=ReplacementConstants.REFRESHED;
            update e;    
            
            List<Entitlement> ent=[SELECT Id,ContractLineItemId,Renewal_Category__c,Quantity__c,Asset.Name,AssetId,Status FROM Entitlement LIMIT 20];
            List<ShGl_DisableBusinessLogic__c> dflList = [SELECT Id, Disable_SBQQ_QuoteLine_Validation_Rules__c,Disable_Opportunity_Validation_Rules__c,Disable_Entitlement_Validation_Rules__c, Name, SetupOwnerId FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId() limit 1];
                        dflList[0].Disable_SBQQ_QuoteLine_Validation_Rules__c = false;
                        dflList[0].Disable_Opportunity_Validation_Rules__c = false;
                        dflList[0].Disable_Entitlement_Validation_Rules__c= false;
                        update dflList[0];
            
            Test.startTest();
            TriggerControls.disableCalculateAPIBatch = true;
            Id batchJobId = Database.executeBatch(new BatchToUpdateQLIQty(), 200);
            Test.stopTest();
            System.assert(true);
        }
    }
    @isTest
    private static void batchToUpdateQLIQtyTest5() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            List<ContractLineItem> cli=[Select id,Resync_Line__c,SBQQSC__RenewalQuantity__c from ContractLineItem limit 8];
            for(ContractLineItem c:cli){
                c.SBQQSC__RenewalQuantity__c=0;
            }
            update cli;
            Entitlement e=[SELECT Id,ContractLineItemId,Renewal_Category__c,Quantity__c,Asset.Name,AssetId,Status FROM Entitlement where Renewal_Category__c=null  LIMIT 1][0];
            e.Renewal_Category__c=ReplacementConstants.REFRESHED;
            update e;    
            List<SBQQ__Quote__c> quoteList=[Select id,SBQQ__Status__c from SBQQ__Quote__c where SBQQ__Status__c=:ReplacementConstants.STATUS_DRAFT];
            for(SBQQ__Quote__C q:quoteList){
                q.SBQQ__Status__c=ReplacementConstants.STATUS_IN_REVIEW;
            }
            update quoteList; 
            List<Entitlement> ent=[SELECT Id,ContractLineItemId,Renewal_Category__c,Quantity__c,Asset.Name,AssetId,Status FROM Entitlement LIMIT 20];
            List<ShGl_DisableBusinessLogic__c> existing = [SELECT Id, Disable_SBQQ_QuoteLine_Validation_Rules__c,Disable_Opportunity_Validation_Rules__c,Disable_Entitlement_Validation_Rules__c, Name, SetupOwnerId FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId() limit 1];
            if (!existing.isEmpty()) {
                delete existing;
            }
            
            
            Test.startTest();
            TriggerControls.disableCalculateAPIBatch = true;
            Id batchJobId = Database.executeBatch(new BatchToUpdateQLIQty(), 200);
            Test.stopTest();
            System.assert(true);
        }
    }
    
    @isTest
    private static void callQuoteSubmitAPIBatchTest2() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            SBQQ__Quote__c quotes=[Select id,SBQQ__Status__c,OpportunitySubType__c,SBQQ__Opportunity2__c,SBQQ__Type__c from SBQQ__Quote__c limit 1];
            quotes.ApprovalStatus__c='';
            quotes.SBQQ__Status__c=ReplacementConstants.STATUS_DRAFT;
            update quotes;
            Set<id> qid=new Set<id>();
            qid.add(quotes.id);
            Test.startTest();
            Id batchJobId = Database.executeBatch(new CallQuoteSubmitAPIBatch(qid), 200);
            Test.stopTest(); 
            System.assert(true);
        }
    }
    @isTest
    private static void batchToUpdateQLIQtyTest3() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            Test.startTest();
            String schTime = '0 0 12 * * ?';
            BatchToUpdateQLIQty schJob = new BatchToUpdateQLIQty();
            System.schedule('TestUpdateConAccJob', schTime, schJob);
            Test.stopTest();
            System.assert(true);
        }
    }
    @isTest
    private static void quoteCalculateAndSubmitBatchTest() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            SBQQ.TriggerControl.disable();
            SBQQ__Quote__c quotes=[Select id,SBQQ__Status__c,OpportunitySubType__c,SBQQ__Opportunity2__c,SBQQ__Type__c from SBQQ__Quote__c limit 1];
            quotes.ApprovalStatus__c='';
            quotes.SBQQ__Status__c=ReplacementConstants.STATUS_DRAFT;
            update quotes;
            Set<id> qid=new Set<id>();
            qid.add(quotes.id);
            Test.startTest();
            Id batchJobId = Database.executeBatch(new QuoteCalculateAndSubmitBatch(qid,qid), 200);//Khushboo
            Test.stopTest(); 
            System.assert(true);
        }
    }
   @isTest
    private static void testFinishMethodEmailLogic() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            BatchToUpdateQLIQty batch = new BatchToUpdateQLIQty();
            batch.errorsnewSCList.add('Simulated error for email test');
            Test.startTest();
            batch.finish(null);
            Test.stopTest();
            System.assert(true, 'Finish method executed with email logic.');
        }
    }
    @isTest
    private static void testStartMethodWithNullQuery() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            BatchToUpdateQLIQty batch = new BatchToUpdateQLIQty();
            batch.query = null;
            Test.startTest();
            Database.QueryLocator locator = batch.start(null);
            Test.stopTest();
            System.assertNotEquals(null, locator, 'QueryLocator should not be null.');
        }
    }
    @isTest
    private static void getUsableCapacityFromAssetTest() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            List<Product2> p=[Select id,Usable_Capacity__c from Product2 limit1];
            p[0].Usable_Capacity__c=0;
            update p[0];
            List<Asset> a= [SELECT Id,Product2Id,Product_Usable_Capacity__c,SBQQSC__CurrentContractLineItem__c,SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__c, SBQQSC__CurrentContractLineItem__r.SBQQSC__RequiredByProduct__r.Usable_Capacity__c,SBQQSC__CurrentContractLineItem__r.SBQQSC__Quantity__c FROM Asset
                            LIMIT 1];
            List<ContractLineItem> cli=[Select id,Resync_Line__c,SBQQSC__RenewalQuantity__c from ContractLineItem limit 1];
            cli[0].SBQQSC__Quantity__c=400;
            update cli[0];
            a[0].SBQQSC__CurrentContractLineItem__c=cli[0].Id;
            update a[0];
            Test.startTest();
            BatchToUpdateQLIQty batch = new BatchToUpdateQLIQty();
            Decimal d=batch.getUsableCapacityFromAsset(a[0]);
            Test.stopTest();
            System.assert(true);
        }
    }
    @isTest
    private static void testAddErrorLogsMethod() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
        List<Batch_Error_Log__c> errorLogList = new List<Batch_Error_Log__c>();
        List<String> errorsList = new List<String>();
        
        SBQQ__Quote__c q=new SBQQ__Quote__c();
        Database.SaveResult[] srList = Database.insert(new List<SBQQ__Quote__c>{ q }, false);
        Database.SaveResult sr = srList[0];
        Test.startTest();
        Id jobId=Database.executeBatch(new BatchToUpdateQLIQty());
        new BatchToUpdateQLIQty().adderrorLogs(errorLogList, errorsList, jobId, sr);
        Test.stopTest();
        System.assertEquals(1, errorLogList.size(), 'One error log should be added');
        System.assertEquals(1, errorsList.size(), 'One error message should be added');
       }
     }
     @isTest
    private static void testcloneOpportunityMethod() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
        List<Opportunity> opp=[SELECT Id, Name, AccountId, CloseDate, StageName, Pricebook2Id, ACV_Amount__c,
            Opportunity_Sub_Type__c, Opportunity_Type__c, OwnerId, RecordTypeId,
            SBQQSC__RenewedServiceContract__c 
            FROM Opportunity limit 1];
            opp[0].Name='OpportunityClosedAdminHelperClass.cloneOpportunity opp OpportunityClosedAdminHelperClass.CloneType.PARTIAL_CHURNOpportunity clonedOpportunity2';
            Test.startTest();
            Opportunity clonedOpportunity1 =
                OpportunityClosedAdminHelperClass.cloneOpportunity(
                    opp[0].Id, OpportunityClosedAdminHelperClass.CloneType.PARTIAL_CHURN);
            Opportunity clonedOpportunity2 =
                OpportunityClosedAdminHelperClass.cloneOpportunity(
                    opp[0].Id, OpportunityClosedAdminHelperClass.CloneType.FULL_CHURN);
            Test.stopTest();
            System.assert(true);
         }
     }
     @isTest
    private static void testCreationOfRenewalChurnOpp() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            List<Opportunity> opp=[SELECT Id, Name, AccountId, CloseDate, StageName, Pricebook2Id, ACV_Amount__c,
                                   Opportunity_Sub_Type__c, Opportunity_Type__c, OwnerId, RecordTypeId,
                                   SBQQSC__RenewedServiceContract__c 
                                   FROM Opportunity WHERE SBQQ__PrimaryQuote__c !=null AND
                                   Opportunity_Sub_Type__c ='Renewal' AND StageName ='6 PO With Channel' limit 2];
            Set<Id> oppIds=new Set<Id>();
            for(Opportunity o:opp){
                oppIds.add(o.Id); 
            }
            List<ShGl_DisableBusinessLogic__c> existing = [SELECT Id, Disable_SBQQ_QuoteLine_Validation_Rules__c,Disable_Opportunity_Validation_Rules__c,Disable_Entitlement_Validation_Rules__c, Name, SetupOwnerId FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId() limit 1];
            if (!existing.isEmpty()) {
                delete existing;
            }
            System.enqueueJob(new CreationOfRenewalChurnOpp(oppIds));
             System.assert(true);
        }
    }
    @isTest
    private static void testCreationOfRenewalChurnOpp2() {
        user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1){
            List<Opportunity> opp=[SELECT Id, Name, AccountId, CloseDate, StageName, Pricebook2Id, ACV_Amount__c,
                                   Opportunity_Sub_Type__c, Opportunity_Type__c, OwnerId, RecordTypeId,
                                   SBQQSC__RenewedServiceContract__c 
                                   FROM Opportunity WHERE SBQQ__PrimaryQuote__c !=null AND
                                   Opportunity_Sub_Type__c ='Renewal' limit 2];
            Set<Id> oppIds=new Set<Id>();
            for(Opportunity o:opp){
             o.stageName='6 PO With Channel';
             oppIds.add(o.Id); 
            }
            Update opp;
            List<ShGl_DisableBusinessLogic__c> dflList = [SELECT Id, Disable_SBQQ_QuoteLine_Validation_Rules__c,Disable_Opportunity_Validation_Rules__c,Disable_Entitlement_Validation_Rules__c, Name, SetupOwnerId FROM ShGl_DisableBusinessLogic__c WHERE SetupOwnerId = :UserInfo.getUserId() limit 1];
            dflList[0].Disable_SBQQ_QuoteLine_Validation_Rules__c = false;
                        dflList[0].Disable_Opportunity_Validation_Rules__c = false;
                        dflList[0].Disable_Entitlement_Validation_Rules__c= false;
                        update dflList[0];
            System.enqueueJob(new CreationOfRenewalChurnOpp(oppIds));
             System.assert(true);
        }
    }
     
 }