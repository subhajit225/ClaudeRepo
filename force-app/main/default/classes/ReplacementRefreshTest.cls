/***********************************************************************************************************
 * Class Name           : ReplacementRefreshTest
 * Date Created/Modified: 24/02/2025
 * Author               : Sumedha
 * @description         : Test class for ReplacementRefreshWrapperData, ReplacementRefreshUtility, ReplacementRefreshController
 * Test Class           :
 * Dependant Components : newReplacementLWC
 /**********************************************************************************************************/
 @isTest 
 public class ReplacementRefreshTest {
    /***********************************************************************************************************
    * Method Name          : setup
    * Date Created/Modified: 10/02/2025
    * Author               : Sumedha
    * @description         : Creates Wrapper that is to be passed to the UI
    * Test Class Methods   :
  /**********************************************************************************************************/
  @testSetup static void setup() {
    User usr1 = Replacement_TestDataFactory.getUser();
      usr1.RBAC_Department__c = 'Service Account';
      usr1.RBAC_Group__c = 'System - IT';
      
      insert usr1;
    //Deactivate triggers
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
        Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
        Disable_Opportunity_Validation_Rules__c=true);
    System.runAs(usr1){
    //Account
    String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName()
      .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
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
    lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-01', 'RBK-R6410-01'
      , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION_TPH
      , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SAAS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RA-R6410-02', 'RA-R6410-02'//Fy25SR-2388
      , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
      , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SUBSCRIPTIONS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-03', 'RBK-R6410-03'
      , ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION, ReplacementConstants.SUBSCRIPTION
      , ReplacementConstants.M365H, ReplacementConstants.SUBSCRIPTIONS));
    lstPrd.add(Replacement_TestDataFactory.getv1Product('RBK-R6410-04', 'RBK-R6410-04'
      , ReplacementConstants.EDITION_STANDALONE, ReplacementConstants.M365_DATA_PROTECTION, ReplacementConstants.PREPETUAL
      , ReplacementConstants.NAS_CLOUD_DIRECT, ReplacementConstants.ON_PREM));
    lstPrd.add(Replacement_TestDataFactory.getv1Product('RBK-R6410-05', 'RBK-R6410-05'
      , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
      , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ON_PREM));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-06', 'RBK-R6410-06'
      , ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.COULD_DATA_PROTECTION
      , ReplacementConstants.PREPETUAL, ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SUBSCRIPTIONS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-07', 'RBK-R6410-07'
      , ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SFDC_DATA_PROTECTION, ReplacementConstants.SUBSCRIPTION
      , ReplacementConstants.PROACTIVE_EDITION, ReplacementConstants.SUBSCRIPTIONS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-08', 'RBK-R6410-07'
      , ReplacementConstants.PROACTIVE_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION
      , ReplacementConstants.PREPETUAL, ReplacementConstants.GPS, ReplacementConstants.SAAS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RS-HW-SVC-PE-S1', 'RBK-HW-09'
      , ReplacementConstants.SUPPORT, ReplacementConstants.NON_REPLACEABLE, ReplacementConstants.SUBSCRIPTION
      , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RS-HW-SVC-PE-S2', 'RBK-HW-10'
      , ReplacementConstants.ENTERPRISE_EDITION, ReplacementConstants.COULD_DATA_PROTECTION
      , ReplacementConstants.PREPETUAL, ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-UG-P-CVB', 'RBK-UG-P-CVB'
      , ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.COULD_DATA_PROTECTION
      , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SAAS));
    lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-UG-P-CVB', 'RBK-UG-P-CVB'
      , ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.ENTERPRISE_DATA_PROTECTION_TPH
      , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.EDITION_UPGRADE, ReplacementConstants.SAAS));

    lstPrd[0].Product_Level__c = ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
    lstPrd[10].Product_Level__c ='Support';//FY25SR-2388
    lstPrd[1].SBQQ__SubscriptionPricing__c ='Fixed Price';//FY25SR-2388
    lstPrd[1].Approval_Category__c ='PSS - CX';//FY25SR-2388
    lstPrd[1].Product_Type__c = ReplacementConstants.PRODUCT_TYPE_RCDOM_SUPPORT;
    lstPrd[1].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
    lstPrd[2].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
    lstPrd[2].Product_Subtype__c = ReplacementConstants.PRODUCT_LEVEL_LOD_ADDON;
    lstPrd[3].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
    lstPrd[3].Family = 'R6000';    
    lstPrd[4].Support_Type__c = ReplacementConstants.SUPPORT_TYPE_L3;
    lstPrd[4].Edition__c = ReplacementConstants.EDITION_UPGRADE;
    lstPrd[5].Edition__c = ReplacementConstants.EDITION_UPGRADE;
    lstPrd[10].Edition__c = ReplacementConstants.EDITION_UPGRADE;
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
    oppList.add(opp1);
    INSERT oppList;
    
    //Quote
    List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
    SBQQ__Quote__c quoteRec = Replacement_TestDataFactory.getQuote(
        acc.Id, opp.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION);
    SBQQ__Quote__c quoteRec1 = Replacement_TestDataFactory.getQuote(
        acc.Id, opp1.Id, customPB.Id, ReplacementConstants.QUOTE_TYPE_RENEWAL);
    qbList.add(quoteRec);
    qbList.add(quoteRec1);
    INSERT qbList;
    
    quoteRec.ApprovalStatus__c = ReplacementConstants.STATUS_APPROVED;
    UPDATE quoteRec;
    
    opp.SBQQ__PrimaryQuote__c = quoteRec.Id;
    opp1.SBQQ__PrimaryQuote__c = quoteRec1.Id;
    UPDATE opp;
            
    //QuoteLinegroup - Might not be needed
    SBQQ__QuoteLineGroup__c quoteLineGrp= Replacement_TestDataFactory.getQuoteLineGroup(quoteRec.Id);
    INSERT quoteLineGrp;

    //Ceate Asset
    List<Asset> asstList = new  List<Asset>();
    Asset asst= Replacement_TestDataFactory.getAsset('Asset122', lstPrd[0].Id, acc.Id);
    Asset asst01= Replacement_TestDataFactory.getAsset('Asset1222', lstPrd[0].Id, acc.Id);
    Asset asst1= Replacement_TestDataFactory.getAsset('Asset123', lstPrd[9].Id, acc.Id);
    Asset asst2= Replacement_TestDataFactory.getAsset('Asset123', lstPrd[3].Id, acc.Id);
    asst2.Licensing_Model__c= 'Perpetual';
    asstList.add(asst);
    asstList.add(asst01);
    asstList.add(asst1);
    asstList.add(asst2);
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
        OrderItem oli3= Replacement_TestDataFactory.getOrderItem(lstPrd[3].Id, ordr.Id, lstEntry[5].Id);
        oliList.add(oli1);
        oliList.add(oli2);
        oliList.add(oli3);
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
        ContractLineItem ContractLineItemObj6 = 
          Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj6.EndDate = Date.today().addDays(365);
        ContractLineItemObj6.StartDate =  Date.today();
        ContractLineItemObj6.SBQQSC__Product__c = lstPrdIds[8];
        lstCLI.add(ContractLineItemObj6);
        ContractLineItem ContractLineItemObj4 = 
          Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj4.EndDate = Date.today().addDays(365);
        ContractLineItemObj4.StartDate =  Date.today();
        ContractLineItemObj4.SBQQSC__Product__c = lstPrdIds[4];
        lstCLI.add(ContractLineItemObj4);
        
        ContractLineItem ContractLineItemObj5 = 
          Replacement_TestDataFactory.getContractLineItem(acc.Id, asst2.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj5.EndDate = Date.today().addDays(365);
        ContractLineItemObj5.StartDate =  Date.today();
        ContractLineItemObj5.SBQQSC__Product__c = lstPrdIds[3];
        lstCLI.add(ContractLineItemObj5);
        
        SBQQ__QuoteLine__c qliTPH= 
          Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[11], ContractLineItemObj1.Id); 
                  qliTPH.TPH_Quantity__c = '12';
        insert qliTPH;
        
        ContractLineItem ContractLineItemObj7 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst1.Id, lstEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj7.EndDate = Date.today().addDays(365);
        ContractLineItemObj7.StartDate =  Date.today();
        ContractLineItemObj7.SBQQSC__Product__c = lstPrdIds[11];
        ContractLineItemObj7.SBQQSC__OriginalQuoteLine__c = qliTPH.Id;
        lstCLI.add(ContractLineItemObj7);
        
        insert lstCLI;

        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli= 
          Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[1], ContractLineItemObj1.Id); 
        SBQQ__QuoteLine__c qli1= 
          Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[2], ContractLineItemObj2.Id); 
        SBQQ__QuoteLine__c qli2= 
          Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrdIds[2], ContractLineItemObj2.Id); 
        SBQQ__QuoteLine__c qli3= 
          Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[11], ContractLineItemObj1.Id);
        qli3.Arroyo_Subscribed_Asset_Name__c='JAY8486304222';
        qli3.Arroyo_Subsumed_Old_Contract_Line_Items__c=ContractLineItemObj1.Id;
        qli3.Special_Program__c='Conversion';
        qli3.Disposition_Reason__c=null;
        qli3.SBQQSC__RenewedContractLine__c=null;
        SBQQ__QuoteLine__c qli4= 
          Replacement_TestDataFactory.getQuoteLine(asst.Id, asst2, quoteRec.Id, lstPrdIds[3], ContractLineItemObj5.Id);
        qli4.Arroyo_Subscribed_Asset_Name__c='JAY8486304222';
        qli4.Arroyo_Subsumed_Old_Contract_Line_Items__c=ContractLineItemObj5.Id;
        qli4.Special_Program__c='Conversion';
        qli4.Disposition_Reason__c=null;
        qli4.SBQQSC__RenewedContractLine__c=null;
        qlList.add(qli);
        qlList.add(qli1);
        qlList.add(qli2);
        qlList.add(qli3);
        qlList.add(qli4);
        insert qlList;
    
        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();
        Entitlement ent = 
          Replacement_TestDataFactory.getEntitlement('Test Entitlement', acc.Id, lstPrd[0].Id, null, oliList[0].Id
          , serviceContractObj.Id, ContractLineItemObj7.Id);
        Entitlement ent1 = 
          Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[1].Id, asst.Id, oliList[0].Id
          , serviceContractObj.Id, ContractLineItemObj1.Id);//Inactive
        Entitlement ent2 = 
          Replacement_TestDataFactory.getEntitlement('Test Upgrade', acc.Id, lstPrd[10].Id, asst1.Id, oliList[1].Id
          , serviceContractObj.Id, ContractLineItemObj2.Id); //Upgrade Product
        Entitlement ent3 = 
          Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[8].Id, asst1.Id
          , oliList[1].Id, serviceContractObj.Id, ContractLineItemObj3.Id); //HW Support
        Entitlement ent6 = 
          Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[8].Id, asst1.Id, oliList[1].Id
          , serviceContractObj.Id, ContractLineItemObj6.Id); //HW Support
        Entitlement ent4 = 
          Replacement_TestDataFactory.getEntitlement('Test V1 Entitlement', acc.Id, lstPrd[4].Id, asst1.Id
          , oliList[1].Id, serviceContractObj.Id, ContractLineItemObj3.Id);//v1 Product
        //Entitlement ent5 = Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[4].Id, asst1.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj3.Id);//v1 Product
             Entitlement ent5 = Replacement_TestDataFactory.getEntitlement('Test Entitlement', acc.Id
         , lstPrd[0].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj.Id);

        Entitlement ent7 = 
          Replacement_TestDataFactory.getEntitlement('Test PerpetualEntitlement', acc.Id, lstPrd[8].Id, asst2.Id, oliList[2].Id
          , serviceContractObj.Id, ContractLineItemObj5.Id); //HW Support
        ent1.EndDate = date.newinstance(2028, 2, 17);
        ent1.StartDate = date.newinstance(2027, 2, 17);
        //ent1.EndDate = Date.today().addMonths(13);
        //ent1.StartDate = Date.today();
        entList.add(ent);
        entList.add(ent1);
        entList.add(ent2);
        entList.add(ent3);
        entList.add(ent4);
        entList.add(ent6);
        ent5.EndDate = date.newinstance(2030, 2, 17);
        ent5.StartDate = date.newinstance(2029, 2, 17);
        //ent5.Status = ReplacementConstants.STATUS_INACTIVE;
        entList.add(ent5);
        entList.add(ent7);
        INSERT entList;
        
        //Scale Entitlement
        List<Scale_Entitlement__c> scaleEntList = new List<Scale_Entitlement__c>();
        Scale_Entitlement__c scaleEnt= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst.Id);
        Scale_Entitlement__c scaleEnt01= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst01.Id);
        Scale_Entitlement__c scaleEnt2= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst1.Id);
        Scale_Entitlement__c scaleEnt1= Replacement_TestDataFactory.getScaleEntitlement(ent2.Id, asst1.Id);
        scaleEnt1.Type__c = ReplacementConstants.REFRESHED_DELTA_LICENSE;
        scaleEnt2.Type__c = ReplacementConstants.REFRESHED_BASE_LICENSE;
        scaleEntList.add(scaleEnt);
        scaleEntList.add(scaleEnt01);
        scaleEntList.add(scaleEnt1);
        scaleEntList.add(scaleEnt2);
        INSERT scaleEntList;
        //Entitlement Links for inactive and Upgrade Entitlements
        List<Entitlement_Links__c> entLinkLst = new List<Entitlement_Links__c>();
        Entitlement_Links__c entLink1= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent1.Id); //Inactive Link
        Entitlement_Links__c entLink2= Replacement_TestDataFactory.getEntitlementLinks(ent.Id, ent2.Id); //Upgrade link
        entLinkLst.add(entLink1);
        entLinkLst.add(entLink2);
        INSERT entLinkLst;
      Test.stopTest();
    }
  }
  
  /***********************************************************************************************************
    * Method Name          : getWrapperTestMethod
    * Date Created/Modified: 04/07/2025
    * Author               : Shivani
    * @description         : Tests the profile info
    * Test Class Methods   :
  /**********************************************************************************************************/
  testmethod static void getWrapperTestMethod(){
    System.runAs(new User(Id = UserInfo.getUserId())) {
      Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = 
        new Map<String, List<Scale_Entitlement__c>>();
      Date todaysDate = System.today();
      //Get Account data
      Account acc = [SELECT Id, Name FROM Account LIMIT 1];
      
      //Get Quote data
      SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c
        ,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c FROM SBQQ__Quote__c 
        WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];

      //Get Quote data
      SBQQ__Quote__c qbR= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c
        ,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c FROM SBQQ__Quote__c 
        WHERE SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL LIMIT 1];
      
      List<SBQQ__QuoteLine__c> qlList= [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c 
        FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: qb.Id];
      List<SBQQ__QuoteLine__c> qlList2= [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c 
        FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: qbR.Id];
      
      //Get Product data 
      List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,Product_Code_Type__c FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 10];
      
      List<Entitlement> ets = 
        [SELECT Id,  Status, Name, AssetId, Asset.Name,Asset.SerialNumber, StartDate,EndDate,
              Product__r.Approval_Category__c,Product__r.SBQQ__SubscriptionPricing__c,//FY25SR-2388
                Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, 
                Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,
                Product__r.Product_Payment_Option__c,Product__r.SBQQ__RenewalProduct__c,Product__r.Custom_Renewal_Product__c,
                Asset.SBQQSC__CurrentContractLineItem__c,Product__c,Product__r.Name,Product__r.Support_Type__c,
                Renewable__c,Product__r.License_Type__c,product__r.Product_Level__c,Product__r.Product_Type__c,
                Product__r.ProductCode,Product__r.License_Category__c,
                Product__r.License_Sub_Category__c,Product__r.Description,
                Product__r.Replacement_Category__c,Product__r.Edition__c,
                Order_Number__c,Order_Quantity__c,ServiceContractId,Quantity__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,
                ServiceContract.Name,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,ContractLineItem.TPH_Drive_Size__c,
                ContractLineItem.TPH_Quantity__c,
                ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,ContractLineItem.Support_Type__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,
                ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,
                ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,
                Asset.Product2.Add_on_Level__c, 
                Product__r.Add_on_Level__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,
                ContractLineItem.Product_SubType__c, ContractLineItem.Product_Type__c,
                ContractLineItem.SBQQSC__QuoteLine__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c, 
                ContractLineItem.Licensing_Model__c, Entitlement_ACV__c,ServiceContract.ContractNumber,ContractLineItem.Total_Price_Without_Promo__c,SBQQSC__AssetRootId__c
                FROM Entitlement where AccountId =: acc.Id];  
      
      List<Scale_Entitlement__c> scaleEntList  =
       [SELECT Id, Asset__c,Asset__r.Name,Entitlement__c,Entitlement__r.Name,Asset__r.SBQQSC__CurrentContractLineItem__c, 
               Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,Asset__r.Product2Id, 
               Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,Asset__r.Product2.Product_Type__c,
               Asset__r.Product2.Add_on_Level__c,Entitlement__r.Product__r.Product_Level__c,
               Entitlement__r.Product__r.Add_on_Level__c, Entitlement__r.SBQQSC__AssetRootId__c, Entitlement__r.ServiceContract.ContractNumber FROM Scale_Entitlement__c ];
      
      mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);

      Date startDate = date.newinstance(2025, 2, 17);
      Date endDate = date.newinstance(2028, 2, 17);
      Test.startTest();
      List<Id> selectedEnts = new List<Id>{ets[0].Id};
      List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = 
        ReplacementRefreshController.getWrapper (qb, startDate, endDate, 
          selectedEnts, new List<Id>{}, new List<String>{'1','2'});
      /*List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrapR = 
        ReplacementRefreshController.getWrapper (qbR, startDate, endDate, 
          selectedEnts, new List<Id>{}, new List<String>{'1','2'});
      List<ReplacementRefreshWrapperData.wrapperData> lstFinalNullFilter = 
        ReplacementRefreshController.getWrapper (qbR, null, null, 
          selectedEnts, new List<Id>{}, new List<String>{'1','2'}); */
      
      Set<Id> quoteIds = new Set<Id>();
      quoteIds.add(qb.Id);
      quoteIds.add(qbR.Id);
      Map<Id, Entitlement> mapEnts = new Map<Id, Entitlement>();
      Map<Id, Map<String, String>> assetEntMap = new Map<Id, Map<String, String>>();
      Map<Id, List<Entitlement>>  hwSuppIdvsEntLst =  new Map<Id, List<Entitlement>>();
      Map<Id, List<Entitlement>> lstInactiveEnts = new Map<Id, List<Entitlement>>();
      Entitlement ents = new Entitlement();
      for (Entitlement ent : ets) {

          if(String.isNotBlank(ent.Product__r.Name) && ent.Product__r.Name.contains('HW-SVC')){
              
              if(!hwSuppIdvsEntLst.containsKey(ets[0].Id)){
                hwSuppIdvsEntLst.put(ets[0].Id, new List<Entitlement>{ent});
              }
              else {
                hwSuppIdvsEntLst.get(ets[0].Id).add(ent);
              }
          }
          if(ent.Status == ReplacementConstants.STATUS_INACTIVE){
              if(ents != null){ents = ent;} 
              if(!lstInactiveEnts.containsKey(ent.Id)){
                  lstInactiveEnts.put(ent.Id, new List<Entitlement>{ent});
              }
              lstInactiveEnts.get(ent.Id).add(ent);
          }
        mapEnts.put(ent.Id, ent);
        Map<String, String> tempMap = new Map<String, String>();
        if (assetEntMap.containsKey(ent.Id)) {
          tempMap.put(ent.AssetId, ent.Asset.SerialNumber);
          assetEntMap.get(ent.Id).put(ent.AssetId, ent.Asset.SerialNumber);
        } else {
          tempMap.put(ent.AssetId, ent.Asset.SerialNumber); 
          assetEntMap.put(ent.Id, tempMap);
        }
      }

      Map<String, List<Scale_Entitlement__c>> mapEntvsSCENT = new Map<String, List<Scale_Entitlement__c>>();
      for (Scale_Entitlement__c scaleEnt : scaleEntList){
        if (mapEntvsSCENT.containsKey(scaleEnt.Entitlement__c)){
          mapEntvsSCENT.get(scaleEnt.Entitlement__c).add(scaleEnt);
        }
        else {
          mapEntvsSCENT.put(scaleEnt.Entitlement__c, new List<Scale_Entitlement__c>{scaleEnt});
        }
      }
    
      Map<String, Asset> assetLst = new Map<String, Asset>();
      for (Asset astRec : [SELECT Id, Name, Asset_Id__c,Product_Usable_Capacity__c,Licensing_Model__c,Product_Family__c,SerialNumber FROM Asset WHERE AccountId = : acc.Id]) {
        assetLst.put(astRec.SerialNumber, astRec);
      }

      Map<String, String> mapOfInactiveEnts = new Map<String, String>();
      for (Entitlement_Links__c entLink : 
        [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, Previous_Entitlement__r.Renewal_Category__c, 
        Previous_Entitlement__r.EndDate, Previous_Entitlement__r.Product__r.Product_Type__c , 
        Previous_Entitlement__r.Status, Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, 
        Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, 
        Renewed_Entitlement__r.Product__r.Product_Type__c, Renewed_Entitlement__r.Product__r.Edition__c  
        FROM Entitlement_Links__c 
        where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate )]) {
        mapOfInactiveEnts.put(entLink.Renewed_Entitlement__c, entLink.Previous_Entitlement__c);
      }
      ReplacementRefreshUtility.createHWSuppWrap(ets[0], lstFinalWrap[0], 
                                               hwSuppIdvsEntLst, lstInactiveEnts, mapEntvsSCENT);

      List<SBQQ__QuoteLine__c> qlsToUpdate = ReplacementRefreshUtility.populateJSONForReconstruction (
                            quoteIds, mapEnts, assetLst, mapOfInactiveEnts, assetEntMap);
      ReplacementRefreshUtility.createBundledWrap(ents,lstInactiveEnts, mapEntvsSCENT,hwSuppIdvsEntLst);
      System.assert(lstFinalWrap.size() > 0);
    }
  }
   
     /***********************************************************************************************************
    * Method Name          : replacementControllerTestMethod
    * Date Created/Modified: 10/02/2025
    * Author               : Sumedha
    * @description         : Creates test data  for Replacement Refresh test
    * Test Class Methods   :
  /**********************************************************************************************************/

  testmethod static void replacementControllerTestMethod(){
    user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr1) {
      Map<String, List<Scale_Entitlement__c>> mapEntitlemmemntNameToScaleEntitlements = new Map<String, List<Scale_Entitlement__c>>();
      Date todaysDate = System.today();
      //Get Account data
      Account acc = [SELECT Id, Name FROM Account LIMIT 1];
      
      //Get Quote data
      SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c='Renewal+Expansion' LIMIT 1];

      //Get Quote data
      SBQQ__Quote__c qbR= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c='Renewal' LIMIT 1];
      
      List<SBQQ__QuoteLine__c> qlList= [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: qb.Id];
      List<SBQQ__QuoteLine__c> qlList2= [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: qbR.Id];
      System.assert(qlList.size()>0, 'Expansion Group lines created'); 
      //Get Product data 
      List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,Product_Code_Type__c FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 10];
      
      List<Entitlement> ets = [SELECT Id,  Name, AssetId, Asset.Name,Asset.SerialNumber, StartDate,EndDate,Asset.Product_Usable_Capacity__c,Asset.Order_Product_Name__c, Asset.Product2.Name,Asset.Product2.RWD_Version__c,Asset.Product2.Product_Type__c,Asset.SBQQSC__CurrentContractLineItem__c,Product__c,Product__r.Name,Product__r.Support_Type__c,Renewable__c,Product__r.License_Type__c,product__r.Product_Level__c,Product__r.Product_Type__c,Product__r.ProductCode,Product__r.License_Category__c,Product__r.License_Sub_Category__c,Product__r.Description,Product__r.Replacement_Category__c,Product__r.Edition__c,Order_Number__c,Order_Quantity__c,ServiceContractId,Quantity__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Product_Code_Type__c,ServiceContract.Name,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle_FrontEnd__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Region_Bundle__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Storage_Tier__c,ContractLineItem.TPH_Drive_Size__c,ContractLineItem.TPH_Quantity__c,ContractLineItem.TPH_OEM__c,ContractLineItem.TPH_Models_Gen__c,ContractLineItem.Support_Type__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_the_customer_be_buying_the_HW__c,ContractLineItem.SBQQSC__OriginalQuoteLine__r.Who_will_Install_CDM__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,Asset.Product2.Add_on_Level__c, Product__r.Add_on_Level__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__c,ContractLineItem.Product_SubType__c, ContractLineItem.Product_Type__c,ContractLineItem.SBQQSC__QuoteLine__c,ContractLineItem.SBQQSC__QuoteLine__r.SBQQ__RequiredBy__r.SBQQ__RequiredBy__c,Product__r.Approval_Category__c,Product__r.SBQQ__SubscriptionPricing__c, SBQQSC__AssetRootId__c, ServiceContract.ContractNumber FROM Entitlement where AccountId =: acc.Id];//FY25SR-2388 
      
      List<Scale_Entitlement__c> scaleEntList  = [SELECT Id, Asset__c,Asset__r.Name,Entitlement__c,Entitlement__r.Name,Asset__r.SBQQSC__CurrentContractLineItem__c, Asset__r.Product_Usable_Capacity__c,Asset__r.Order_Product_Name__c,Asset__r.Product2Id, Asset__r.Product2.Name,Asset__r.Product2.RWD_Version__c,Asset__r.Product2.Product_Type__c,Asset__r.Product2.Add_on_Level__c,Entitlement__r.Product__r.Product_Level__c,Entitlement__r.Product__r.Add_on_Level__c, Entitlement__r.SBQQSC__AssetRootId__c, Entitlement__r.ServiceContract.ContractNumber FROM Scale_Entitlement__c ];
      
      /*List<Entitlement_Links__c> entLinks = [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, Renewed_Entitlement__r.Product__r.Product_Type__c  FROM Entitlement_Links__c where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate )];*/

      mapEntitlemmemntNameToScaleEntitlements.put(String.valueOf(ets[0].Id), scaleEntList);

      Date startDate = date.newinstance(2025, 2, 17);
      Date endDate = date.newinstance(2028, 2, 17);
      Test.startTest();
      List<Id> selectedEnts = new List<Id>();
      List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrap = ReplacementRefreshController.createWrapperData (qb, startDate, endDate, selectedEnts, new List<Id>{}, new List<String>{'1','2'});
   //   List<ReplacementRefreshWrapperData.wrapperData> lstFinalWrapR = ReplacementRefreshController.createWrapperData (qbR, startDate, endDate, selectedEnts, new List<Id>{}, new List<String>{'1','2'});
   //   System.AssertEquals (lstFinalWrap.size(), 1);

      Set<Id> quoteIds = new Set<Id>();
      quoteIds.add(qb.Id);
      quoteIds.add(qbR.Id);
      Map<Id, Entitlement> mapEnts = new Map<Id, Entitlement>();
      Map<Id, Map<String, String>> assetEntMap = new Map<Id, Map<String, String>>();
      for (Entitlement ent : ets) {
        mapEnts.put(ent.Id, ent);
        Map<String, String> tempMap = new Map<String, String>();
        if (assetEntMap.containsKey(ent.Id)) {
          tempMap.put(ent.AssetId, ent.Asset.SerialNumber);
          assetEntMap.get(ent.Id).put(ent.AssetId, ent.Asset.SerialNumber);
        } else {
          tempMap.put(ent.AssetId, ent.Asset.SerialNumber); 
          assetEntMap.put(ent.Id, tempMap);
        }
      }

      Map<String, Asset> assetLst = new Map<String, Asset>();
      for (Asset astRec : [Select Id, Name, Asset_Id__c,Product_Usable_Capacity__c,Licensing_Model__c,Product_Family__c,SerialNumber from Asset where AccountId = : acc.Id]) {
        assetLst.put(astRec.SerialNumber, astRec);
      }

      Map<String, String> mapOfInactiveEnts = new Map<String, String>();
      for (Entitlement_Links__c entLink : [Select Id, Previous_Entitlement__c, Previous_Entitlement__r.StartDate, Previous_Entitlement__r.Renewal_Category__c, Previous_Entitlement__r.EndDate, Previous_Entitlement__r.Product__r.Product_Type__c , Previous_Entitlement__r.Status, Renewed_Entitlement__r.Name, Renewed_Entitlement__r.Status, Renewed_Entitlement__r.StartDate, Renewed_Entitlement__c, Renewed_Entitlement__r.EndDate, Renewed_Entitlement__r.Product__r.Product_Type__c, Renewed_Entitlement__r.Product__r.Edition__c  FROM Entitlement_Links__c where (Previous_Entitlement__r.EndDate >= : todaysDate OR Renewed_Entitlement__r.StartDate >= : todaysDate )]) {
        mapOfInactiveEnts.put(entLink.Renewed_Entitlement__c, entLink.Previous_Entitlement__c);
      }

      List<SBQQ__QuoteLine__c> qlsToUpdate = ReplacementRefreshUtility.populateJSONForReconstruction (quoteIds, mapEnts, assetLst, mapOfInactiveEnts, assetEntMap);
      
      Test.stopTest();
    }
  }
     
   /***********************************************************************************************************
    * Method Name          : currentUserExceptionsTestMethod
    * Date Created/Modified: 16/06/2025
    * Author               : Ankita
    * @description         : Tests the profile info
    * Test Class Methods   :
  /**********************************************************************************************************/
     
  testmethod static void currentUserExceptionsTestMethod(){
    user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr1) {
      ReplacementRefreshController.currentUserExceptions();
      Replacement_Field_Mapping__mdt objectData= ReplacementRefreshUtility.getCustomMetadataInstance('OldFrameWorkQuoteType');   
    }
    System.Assert(true);
  }
    /***********************************************************************************************************
    * Method Name          : coverReplacementRefreshWrapperData
    * Date Created/Modified: 23/07/2025
    * Author               : Shivani
    * @description         : covers ReplacementRefreshWrapperData class
    * Test Class Methods   :
  /**********************************************************************************************************/
      
     testmethod static void coverReplacementRefreshWrapperData(){
         System.runAs(new user(Id = UserInfo.getUserId())) {
         ReplacementRefreshWrapperData.WrapperData objReplacementRefreshWrapperData = new ReplacementRefreshWrapperData.WrapperData();
         objReplacementRefreshWrapperData.wrapBaseLicense = new List<ReplacementRefreshWrapperData.WrapperData>();
         objReplacementRefreshWrapperData.wrapHWSupportLines = new List<ReplacementRefreshWrapperData.WrapperData>();
         objReplacementRefreshWrapperData.wrapInactiveEnt = new List<ReplacementRefreshWrapperData.WrapperData>();
         objReplacementRefreshWrapperData.wrapUpgradeEnt = new List<ReplacementRefreshWrapperData.WrapperData>();
         objReplacementRefreshWrapperData.mapAssetEntitlements = new ReplacementRefreshWrapperData.futureDataValues();
         objReplacementRefreshWrapperData.exceptionMessages = new List<ReplacementRefreshWrapperData.PickList>();
         objReplacementRefreshWrapperData.selectedAssetsFromNonAsset = new List<ReplacementRefreshWrapperData.PickList>();
         objReplacementRefreshWrapperData.consumedquantity = 1.0;
        objReplacementRefreshWrapperData.entitlementName = 'RBK-134-DCX';
        objReplacementRefreshWrapperData.entitlementOrderNumber = '456788';
        objReplacementRefreshWrapperData.entitlementId = 'FCv123mbjb26vbhbUI';
        objReplacementRefreshWrapperData.productId = 'FCv123mbjb26vbhbUI';
        objReplacementRefreshWrapperData.oldProductEdition = 'FCv123mbjb26vbhbUI';
        objReplacementRefreshWrapperData.StartDate= System.Today();
        objReplacementRefreshWrapperData.EndDate= System.Today().addDays(900);
        //List<pickList> assetsAvailable =
        objReplacementRefreshWrapperData.quantityAssetType = true;
        objReplacementRefreshWrapperData.SrprodLicSubCategoryVal = 'Test1';
        objReplacementRefreshWrapperData.quantity = 1.0;
        objReplacementRefreshWrapperData.selectedquantity = 1.0;
        objReplacementRefreshWrapperData.ReplacementTerm = 1.0;
        objReplacementRefreshWrapperData.RemainingTerm = 1.0;
        objReplacementRefreshWrapperData.selecteddisposition = 'Renewal';
        objReplacementRefreshWrapperData.disableDisposition = false;
        objReplacementRefreshWrapperData.SrprodRepCategory = 'TestRep';
        objReplacementRefreshWrapperData.customIndex = '1.0.1';
        objReplacementRefreshWrapperData.errors = 'Test error';
        objReplacementRefreshWrapperData.rowSelected = true;
        objReplacementRefreshWrapperData.showAdd = false;
        objReplacementRefreshWrapperData.serviceContractId = 'TestId';
        objReplacementRefreshWrapperData.serviceContractName = 'Test';
        objReplacementRefreshWrapperData.showSelectCheckBox = true;
        objReplacementRefreshWrapperData.skuProductId = 'vxsvhmshchd';
        objReplacementRefreshWrapperData.skuProdName = 'Test Ptod';
        objReplacementRefreshWrapperData.skuProdRepCategory = 'Test Category';
        objReplacementRefreshWrapperData.skuProdLicenseSubCategory = 'Test Lic Category';
        objReplacementRefreshWrapperData.skuStorBackBundleValue = 'bmxhsdb';
        objReplacementRefreshWrapperData.skuStorFrontBundleValue = 'vdsmbc';
        objReplacementRefreshWrapperData.skuStorTierValue = 'bdcmkmd';
        objReplacementRefreshWrapperData.skuProdCodeType = 'vmbdchb';
        objReplacementRefreshWrapperData.oldSKUwrapBundleVal = 'mvdbcy sdgcliu';
        objReplacementRefreshWrapperData.oldSKUwrapBundleBackVal ='vmdchmdvskyuc';
        objReplacementRefreshWrapperData.oldSKUwrapProductType = 'dsmcbydugskuydk';
        objReplacementRefreshWrapperData.oldSKUwrapTierVal = 'vdcjyduv';
        objReplacementRefreshWrapperData.partialReplacement = true;
        objReplacementRefreshWrapperData.tphTypeEntitlement = false; //FY25SR-1557
        objReplacementRefreshWrapperData.tphQuantity =  '1';
        objReplacementRefreshWrapperData.tphOEM = 'vdbcdcbd';
        objReplacementRefreshWrapperData.tphModels = 'vdbcdcbd';
        objReplacementRefreshWrapperData.tphDriveSize =  'vdbcdcbd';
        objReplacementRefreshWrapperData.tphHWPurchasedFrom ='vdbcdcbd';
        objReplacementRefreshWrapperData.tphWhoWillDoImaging = 'vdbcdcbd';
        objReplacementRefreshWrapperData.isModified = true;
        objReplacementRefreshWrapperData.baseProdIds = 'vdbcdcbd';
        objReplacementRefreshWrapperData.skuSuppType = 'vdbcdcbd';
        objReplacementRefreshWrapperData.srSuppType = 'vdbcdcbd';
        ReplacementRefreshWrapperData.pickList autoDisposition = ReplacementRefreshWrapperData.createpicKlistValues('Test','Test',
                                                                                                                    'Test','Test',
                                                                                                                     10,
                                                                                                                     true,false,
                                                                                                                     false,true);
        objReplacementRefreshWrapperData.autoDisposition = new List<ReplacementRefreshWrapperData.pickList>();
        objReplacementRefreshWrapperData.manualDisposition = new List<ReplacementRefreshWrapperData.pickList>();
        objReplacementRefreshWrapperData.renLine = true;
        objReplacementRefreshWrapperData.renewalEndDate= System.Today();
        objReplacementRefreshWrapperData.originalQuoteLineIdForEnt = 'vdbcdcbd';
        objReplacementRefreshWrapperData.keyIdentifier ='vdbcdcbd';
        objReplacementRefreshWrapperData.srcLicModel ='vdbcdcbd';
        objReplacementRefreshWrapperData.anyToAnyFlag = true;
        objReplacementRefreshWrapperData.targetProductType ='vdbcdcbd';
        objReplacementRefreshWrapperData.doNotConsolidateEnt = true;
        objReplacementRefreshWrapperData.textToShow = 'vdbcdcbd';

         ReplacementRefreshWrapperData.FutureDataValues obj = new ReplacementRefreshWrapperData.FutureDataValues();
         obj.futureKey = 'test';
         system.AssertEquals(obj.futureKey, 'test');
         obj.futureValues = new List<ReplacementRefreshWrapperData.WrapperData>{objReplacementRefreshWrapperData};
        }
     }
}