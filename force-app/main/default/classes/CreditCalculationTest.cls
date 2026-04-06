/***********************************************************************************************************
* Class Name           : CreditCalculationTest
* Date Created/Modified: 06/22/2025
* Author               : Ankita
* @description         : Test Class for CreditCalculation
* Test Class           :                     
/**********************************************************************************************************/
@isTest 
public class CreditCalculationTest{
/***********************************************************************************************************
  * Method Name          : setup
  * Date Created/Modified: 04/2225
  * @description         : Test data setup
  * Author               : Ankita
  * Purpose              : Creates mandatory data
  * Test Class Methods   :setup
  /**********************************************************************************************************/
  @testSetup static void setup() {
    User usr1 = Replacement_TestDataFactory.getUser();
    insert usr1;
    //Deactivate triggers
    INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
    Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
    Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
    Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
    Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
    Disable_SBQQ_Quote_Validation_Rules__c= true,Disable_Entitlement_Validation_Rules__c=true,
    Disable_Opportunity_Validation_Rules__c=true);

    System.runAs(usr1) {
                          
      //Account
      String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName()
        .get(ReplacementConstants.PARTNER_DISTRIBUTOR).getRecordTypeId();
      Account acc= Replacement_TestDataFactory.getAccount('Test Account', recordTypeId);
      INSERT acc;
            
      //Contact 
      Contact con= Replacement_TestDataFactory.getContact(acc);
      INSERT con;
              
      //Product data
      List<Product2> lstPrd = new List<Product2>();
      lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-01', 'RBK-R6410-01',
        ReplacementConstants.EDITION_STANDALONE, ReplacementConstants.COULD_DATA_PROTECTION, ReplacementConstants.PREPETUAL
        , ReplacementConstants.HW_SUPPORT, ReplacementConstants.SAAS));
      lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-02', 'RBK-R6410-02'
        , ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.ENTERPRISE_DATA_PROTECTION
        , ReplacementConstants.SUBSCRIPTION, ReplacementConstants.FOUNDATION_EDITION, ReplacementConstants.SUBSCRIPTIONS));
      lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-03', 'RBK-R6410-03'
      , ReplacementConstants.BUSINESS_EDITION, ReplacementConstants.JIRA_DATA_PROTECTION, ReplacementConstants.SUBSCRIPTION
      , ReplacementConstants.M365H, ReplacementConstants.SUBSCRIPTIONS));
      lstPrd[0].Product_Level__c='';
      INSERT lstPrd;
      //Polaris SKU Mapping
       List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingObjList = new List<Polaris_SKU_Mapping_V2__c>();
       Polaris_SKU_Mapping_V2__c polarisSKUMappingObj = Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[0].Id, lstPrd[1].Id);
       polarisSKUMappingObjList.add(polarisSKUMappingObj);
       insert polarisSKUMappingObjList;
      
      //Standard PriceBook
      Id standardPriceBookId= Test.getStandardPricebookId();
            
      //Custom PriceBook
      PriceBook2 customPB = Replacement_TestDataFactory.getPriceBook(); 
      INSERT customPB;
            
      //Create PriceBook Entries for Standard and Custom PriceBook
      List<PricebookEntry> lstEntry = new List<PricebookEntry>();
      //Standard PriceBookEntry
      lstEntry.add(Replacement_TestDataFactory.getPriceBookEntry(lstPrd[0].Id, standardPriceBookId));
      lstEntry.add(Replacement_TestDataFactory.getPriceBookEntry(lstPrd[1].Id, standardPriceBookId));
      lstEntry.add(Replacement_TestDataFactory.getPriceBookEntry(lstPrd[2].Id, standardPriceBookId));
            
      //Custom PriceBookEntry
      lstEntry.add(Replacement_TestDataFactory.getPriceBookEntry(lstPrd[0].Id, customPB.Id)); 
      lstEntry.add(Replacement_TestDataFactory.getPriceBookEntry(lstPrd[1].Id, customPB.Id)); 
      lstEntry.add(Replacement_TestDataFactory.getPriceBookEntry(lstPrd[2].Id, customPB.Id));                    
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
              
      //QuoteLinegroup
      SBQQ__QuoteLineGroup__c quoteLineGrp= Replacement_TestDataFactory.getQuoteLineGroup(quoteRec.Id);
      INSERT quoteLineGrp;
        
      //Ceate Asset
      List<Asset> asstList = new List<Asset>();
      asstList.add(Replacement_TestDataFactory.getAsset('EntitlementTriggerHelperAsset', lstPrd[0].Id, acc.Id));
      asstList.add(Replacement_TestDataFactory.getAsset('EntitlementTriggerHelperAsset', lstPrd[1].Id, acc.Id));
      asstList.add(Replacement_TestDataFactory.getAsset('EntitlementTriggerHelperAsset', lstPrd[2].Id, acc.Id));      
      INSERT asstList;

      test.startTest();
      //Create Order
      Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
      INSERT ordr;
      
      ordr.Pricebook2Id = customPB.Id;
      UPDATE ordr;
      
      //OrderItem
      List<OrderItem> oliList= new List<OrderItem>();
      oliList.add(Replacement_TestDataFactory.getOrderItem(lstPrd[0].Id, ordr.Id, lstEntry[3].Id));
      oliList[0].EndDate= oliList[0].Support_End_Date__c;
      oliList[0].ServiceDate = System.today() + 1;
      oliList.add(Replacement_TestDataFactory.getOrderItem(lstPrd[1].Id, ordr.Id, lstEntry[4].Id));
      oliList[1].EndDate= oliList[1].Support_End_Date__c;
      oliList[1].ServiceDate = System.today() + 1;
      oliList.add(Replacement_TestDataFactory.getOrderItem(lstPrd[2].Id, ordr.Id, lstEntry[5].Id));
      oliList[2].EndDate= oliList[2].Support_End_Date__c;
      oliList[2].ServiceDate = System.today() + 1;

      INSERT oliList;
      
      //ServiceContract
      ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opp.Id, customPB.Id);
      INSERT serviceContractObj;
      
      //ContractLineItem
      List<ContractLineItem> contractLineItemObj = new List<ContractLineItem> ();
      contractLineItemObj.add(Replacement_TestDataFactory.getContractLineItem(
                              acc.Id, asstList[0].Id, lstEntry[3].Id, serviceContractObj.Id));
      contractLineItemObj.add(Replacement_TestDataFactory.getContractLineItem(
                              acc.Id, asstList[1].Id, lstEntry[4].Id, serviceContractObj.Id));
      contractLineItemObj.add(Replacement_TestDataFactory.getContractLineItem(
                              acc.Id, asstList[2].Id, lstEntry[5].Id, serviceContractObj.Id));
      INSERT contractLineItemObj;
      //Entitlement 
      List<Entitlement> entList= new List<Entitlement>();
      Entitlement ent = Replacement_TestDataFactory.getEntitlement(
          'Test Entitlement', acc.Id, lstPrd[0].Id, asstList[0].Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj[0].Id);
      Entitlement ent1 = Replacement_TestDataFactory.getEntitlement(
          'Test Entitlement1', acc.Id, lstPrd[1].Id, null, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj[1].Id);
      Entitlement ent2 = Replacement_TestDataFactory.getEntitlement(
          'Test Entitlement2', acc.Id, lstPrd[2].Id, null, oliList[2].Id, serviceContractObj.Id, ContractLineItemObj[1].Id);
      entList.add(ent);
      entList.add(ent1);
      entList.add(ent2);
      INSERT entList;
          
      //Scale Entitlement
      List<Scale_Entitlement__c> scaleEnt= new List<Scale_Entitlement__c>();
      scaleEnt.add(Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asstList[0].Id));
      scaleEnt.add(Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asstList[1].Id));
      scaleEnt.add(Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asstList[2].Id));
      INSERT scaleEnt;
      
      //QuoteLine
      List<SBQQ__QuoteLine__c> qli1= new List<SBQQ__QuoteLine__c>();
      qli1.add(Replacement_TestDataFactory.getQuoteLine(
        asstList[0].Id, asstList[0], quoteRec.Id, lstPrd[1].Id, ContractLineItemObj[0].Id));
      qli1.add(Replacement_TestDataFactory.getQuoteLine(
        asstList[1].Id, asstList[1], quoteRec.Id, lstPrd[1].Id, ContractLineItemObj[1].Id));
      qli1.add(Replacement_TestDataFactory.getQuoteLine(
        asstList[2].Id, asstList[2], quoteRec.Id, lstPrd[1].Id, ContractLineItemObj[2].Id)); 
      INSERT qli1;
      
      //Order Item Extension
      List<Order_Item_Extension__c> orderItemExtensionList = new List<Order_Item_Extension__c>();
      Order_Item_Extension__c lstOIEToInsert = new Order_Item_Extension__c(
        OI_ExternalID__c = oliList[0].Id, Order_Line_ID__c = oliList[0].Id, Paid_Quantity__c = 3, 
        Credit_Calculation_Status__c = ReplacementConstants.TO_PROCESS, Per_DayQuantity_amount__c = 1.5);
      Order_Item_Extension__c lstOIEToInsert1 = new Order_Item_Extension__c(
        OI_ExternalID__c = oliList[1].Id, Order_Line_ID__c = oliList[1].Id, Paid_Quantity__c = 3, 
        Credit_Calculation_Status__c = ReplacementConstants.TO_PROCESS, Per_DayQuantity_amount__c = 1.5);
      Order_Item_Extension__c lstOIEToInsert2 = new Order_Item_Extension__c(
        OI_ExternalID__c = oliList[2].Id, Order_Line_ID__c = oliList[2].Id, Paid_Quantity__c = 3, 
        Credit_Calculation_Status__c = ReplacementConstants.TO_PROCESS, Per_DayQuantity_amount__c = 1.5);
      orderItemExtensionList.add(lstOIEToInsert);
      orderItemExtensionList.add(lstOIEToInsert1);
      orderItemExtensionList.add(lstOIEToInsert2);  
      INSERT orderItemExtensionList;

      orderItemExtensionList[0].Credit_Calculation_Status__c = ReplacementConstants.COMPLETED;
      orderItemExtensionList[1].Credit_Calculation_Status__c = ReplacementConstants.COMPLETED;
      orderItemExtensionList[2].Credit_Calculation_Status__c = ReplacementConstants.COMPLETED;
      UPDATE orderItemExtensionList;
      test.stopTest();
    }
  }
  /***********************************************************************************************************
  * Method Name          : creditCalculationTestMethod
  * Date Created/Modified:04/22/2025
  * @description         : Test Method for CreditCalculation   
  * Author               : Ankita,
  * Purpose              : Test Method for CreditCalculation                   
  /**********************************************************************************************************/
  public testMethod static void creditCalculationTestMethod() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr1) {
      SBQQ__QuoteLine__c qli = 
             [SELECT Id,SBQQ__Product__c 
                FROM SBQQ__QuoteLine__c 
                WHERE SBQQ__Quote__r.SBQQ__Type__c= :ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
      List<Entitlement> entList = [SELECT Id FROM Entitlement];
      List<Asset> asst = [SELECT Id, Name FROM Asset];
      List<QuoteLineRecordResponse> qliRespLst = new List<QuoteLineRecordResponse>();
      QuoteLineRecordResponse qlresp3 = new QuoteLineRecordResponse ();
      qlresp3.prodCode='RS-TB-EE-RSV-PE';
      qlresp3.newQty=1.00;
      qlresp3.pLvl=ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
      qlresp3.ptyp=ReplacementConstants.ENTERPRISE_EDITION;
      qlresp3.rqBy= qli.Id;
      qlresp3.sP = 'Conversion';
      qlresp3.pTyp ='M365 ZRS';
      qlresp3.asCap= 1.00;
      qlresp3.aoLvl= null;
      qlresp3.pFam= ReplacementConstants.RUBRIK_LICENSE;
      qlresp3.pSt= ReplacementConstants.SCALE_MSP;
      qlresp3.eQty= 1.00;
      qlresp3.qtyC= false;
      qlresp3.apCt= 3;
      qlresp3.nCt= 1;
      qlresp3.pNam='RS-TB-EE-RSV-PE';
      qlresp3.uCap=90;
      qlresp3.ext=false;
      qlresp3.nbr=4;
      qlresp3.prd= qli.SBQQ__Product__c;
      qlresp3.lTyp=ReplacementConstants.QUOTE_TYPE_NEW;
      qlresp3.tCap=1;
      qlresp3.oTCap=null;
      qlresp3.dSize='1';
      qlresp3.tQty='2';
      qlresp3.rcId= qli.Id;
      qlresp3.replacementDetails= createReplacementDetails(
          asst[0], new List<Entitlement>{entList[0], entList[1]}, qlresp3, false, ReplacementConstants.MANY_TO_1);
      qlresp3.listTotal = 100.00;
      qlresp3.creditSD= System.today();
      qliRespLst.add(qlresp3);
      
      Test.startTest();
        CreditCalculation.QuoteLineDataResponse quoteLinesToReturn= CreditCalculation.creditCalculationPost(qliRespLst);
        System.assert(quoteLinesToReturn.quotelines.size()>0, 'Total Credits Calculated');
      Test.stopTest();
    }
  }
  /***********************************************************************************************************
  * Method Name          : fullCreditCalculationTestMethod
  * Date Created/Modified:04/22/2025
  * @description         : Test Method for CreditCalculation   
  * Author               : Ankita,
  * Purpose              : Test Method for CreditCalculation                   
  /**********************************************************************************************************/
  public testMethod static void fullCreditCalculationTestMethod(){
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr1) {
      SBQQ__QuoteLine__c qli = [SELECT Id,SBQQ__Product__c 
          FROM SBQQ__QuoteLine__c 
        WHERE SBQQ__Quote__r.SBQQ__Type__c=:ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION LIMIT 1];
      List<Entitlement> entList = [SELECT Id FROM Entitlement];
      List<Asset> asst = [SELECT Id, Name FROM Asset];
      List<QuoteLineRecordResponse> qliRespLst = new List<QuoteLineRecordResponse>();
      QuoteLineRecordResponse qlresp3 = new QuoteLineRecordResponse ();
      qlresp3.prodCode='RS-TB-EE-RSV-PE';
      qlresp3.newQty=1.00;
      qlresp3.pLvl=ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
      qlresp3.ptyp=ReplacementConstants.ENTERPRISE_EDITION;
      qlresp3.rqBy= qli.Id;
      qlresp3.sP = 'Conversion';
      qlresp3.pTyp ='M365 ZRS';
      qlresp3.asCap= 1.00;
      qlresp3.aoLvl= null;
      qlresp3.pFam= ReplacementConstants.RUBRIK_LICENSE;
      qlresp3.pSt= ReplacementConstants.SCALE_MSP;
      qlresp3.eQty= 1.00;
      qlresp3.qtyC= false;
      qlresp3.apCt= 3;
      qlresp3.nCt= 1;
      qlresp3.pNam='RS-TB-EE-RSV-PE';
      qlresp3.uCap=90;
      qlresp3.ext=false;
      qlresp3.nbr=4;
      qlresp3.prd= qli.SBQQ__Product__c;
      qlresp3.lTyp=ReplacementConstants.QUOTE_TYPE_NEW;
      qlresp3.tCap=1;
      qlresp3.oTCap=null;
      qlresp3.dSize='1';
      qlresp3.tQty='2';
      qlresp3.rcId= qli.Id;
      qlresp3.replacementDetails= createReplacementDetails(
          asst[0], new List<Entitlement>{entList[0]}, qlresp3, true, ReplacementConstants.ONE_TO_ONE);
      qlresp3.listTotal = 100.00;
      qlresp3.creditSD= System.today();
      qliRespLst.add(qlresp3);
      
      Test.startTest();
        CreditCalculation.QuoteLineDataResponse quoteLinesToReturn= CreditCalculation.creditCalculationPost(qliRespLst);
        System.assert(quoteLinesToReturn.quotelines.size()>0, 'Total Credits Calculated');
      Test.stopTest();
    }
  }

  /***********************************************************************************************************
  * Method Name          : creditCalculationOneToManyTestMethod
  * Date Created/Modified: 04/22/2025
  * @description         : Test Method for CreditCalculation   
  * Author               : Ankita,
  * Purpose              : Test Method for CreditCalculation                   
  /**********************************************************************************************************/
  public testMethod static void creditCalculationOneToManyTestMethod() {
    user usr1 = [SELECT Id FROM User WHERE email = 'testuser@testclass.com' LIMIT 1];
    System.runAs(usr1) {
      List<SBQQ__QuoteLine__c> qli = 
             [SELECT Id,SBQQ__Product__c 
                FROM SBQQ__QuoteLine__c 
               WHERE SBQQ__Quote__r.SBQQ__Type__c= :ReplacementConstants.QUOTE_TYPE_RENEWAL_EXPANSION];
      List<Entitlement> entList = [SELECT Id FROM Entitlement];
      List<Asset> asst = [SELECT Id, Name FROM Asset];
      List<QuoteLineRecordResponse> qliRespLst = new List<QuoteLineRecordResponse>();
      QuoteLineRecordResponse qlresp3 = new QuoteLineRecordResponse ();
      qlresp3.prodCode='RS-TB-EE-RSV-PE';
      qlresp3.newQty=1.00;
      qlresp3.pLvl=ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
      qlresp3.ptyp=ReplacementConstants.ENTERPRISE_EDITION;
      qlresp3.rqBy= qli[0].Id;
      qlresp3.sP = 'Conversion';
      qlresp3.pTyp ='M365 ZRS';
      qlresp3.asCap= 1.00;
      qlresp3.aoLvl= null;
      qlresp3.pFam= ReplacementConstants.RUBRIK_LICENSE;
      qlresp3.pSt= ReplacementConstants.SCALE_MSP;
      qlresp3.eQty= 1.00;
      qlresp3.qtyC= false;
      qlresp3.apCt= 3;
      qlresp3.nCt= 1;
      qlresp3.pNam='RS-TB-EE-RSV-PE';
      qlresp3.uCap=90;
      qlresp3.ext=false;
      qlresp3.nbr=4;
      qlresp3.prd= qli[0].SBQQ__Product__c;
      qlresp3.lTyp=ReplacementConstants.QUOTE_TYPE_NEW;
      qlresp3.tCap=1;
      qlresp3.oTCap=null;
      qlresp3.dSize='1';
      qlresp3.tQty='2';
      qlresp3.rcId= qli[0].Id;
      qlresp3.replacementDetails= createReplacementDetails(
        asst[0], new List<Entitlement>{entList[0]}, qlresp3, false, ReplacementConstants.ONE_TO_MANY);
      qlresp3.listTotal = 100.00;
      qlresp3.creditSD= System.today();

      QuoteLineRecordResponse qlresp1 = new QuoteLineRecordResponse ();
      qlresp1.prodCode='RS-TB-EE-RSV-PP';
      qlresp1.newQty=1.00;
      qlresp1.pLvl=ReplacementConstants.PRODUCT_LEVEL_HYBRID_SOFTWARE;
      qlresp1.ptyp=ReplacementConstants.ENTERPRISE_EDITION;
      qlresp1.rqBy= qli[1].Id;
      qlresp1.asCap= 1.00;
      qlresp1.aoLvl= null;
      qlresp1.pFam= ReplacementConstants.RUBRIK_LICENSE;
      qlresp1.pSt= ReplacementConstants.SCALE_MSP;
      qlresp1.eQty= 1.00;
      qlresp1.qtyC= false;
      qlresp1.apCt= 3;
      qlresp1.nCt= 1;
      qlresp1.pNam='RS-TB-EE-RSV-PP';
      qlresp1.uCap=90;
      qlresp1.ext=false;
      qlresp1.nbr=4;
      qlresp1.prd= qli[1].SBQQ__Product__c;
      qlresp1.lTyp=ReplacementConstants.QUOTE_TYPE_NEW;
      qlresp1.tCap=1;
      qlresp1.oTCap=null;
      qlresp1.dSize='1';
      qlresp1.tQty='2';
      qlresp1.rcId= qli[0].Id;
      qlresp1.replacementDetails= createReplacementDetails(
        asst[0], new List<Entitlement>{entList[0]}, qlresp1, false, ReplacementConstants.ONE_TO_MANY);
        qlresp1.listTotal = 100.00;
        qlresp1.creditSD= System.today();
      qliRespLst.add(qlresp1);
      qliRespLst.add(qlresp3);
      
      Test.startTest();
        CreditCalculation.QuoteLineDataResponse quoteLinesToReturn= CreditCalculation.creditCalculationPost(qliRespLst);
        System.assert(quoteLinesToReturn.quotelines.size()>0, 'Total Credits Calculated');
      Test.stopTest();
    }
  }
  /***********************************************************************************************************
  * Method Name          : createReplacementDetails
  * Date Created/Modified: 04/22/2025
  * @description         : create data for Replacement Detail field
  * Author               : Ankita
  * Purpose              : Tcreate data for Replacement Detail field   
  * @param              assetRecord
  * @param              entRecord
  * @param              quoteline
  * @param              isMismatch
  * @param              mode
  * @return             ReplacementJSON
  /**********************************************************************************************************/
  public static String createReplacementDetails(Asset assetRecord, List<Entitlement> entRecord, 
      QuoteLineRecordResponse quoteline, Boolean isMismatch, String mode) {
    ReplacementJson lineJson = new ReplacementJson();
    // lineJson.skuSuppType = 'Premium';
    lineJson.skuSelectedName = 'RS-BT-EE-SC-PE-PP';
    lineJson.skuSelected = quoteline.prodCode ;
    lineJson.mode = mode;
    List<ReplacementJson.RowDetail> rowDetails = new List<ReplacementJson.RowDetail>();
    for(Entitlement ent : entRecord) {
      ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
      row.upgradeLines = null;
      row.selectedTerm = 12;
      row.selectedQty = Integer.valueOf(quoteline.newQty);
      Map<String,String> selectedAssets = new Map<String,String> {assetRecord.Id => assetRecord.Name};
      row.selectedAssetList = selectedAssets;
      row.selectedAsset = ''+assetRecord.Id ;
      row.entId = ent.Id;
      row.rowId= '3.1.0';
      row.disposition= ReplacementConstants.CONVERTED;
      row.isMismatch = isMismatch;
      rowDetails.add(row);
    }

    ReplacementJson.RelatedChildEntRowDetail inactivateRows 
        = createInternalRow(String.valueOf(entRecord[0].Id), Integer.valueOf(quoteline.newQty),rowDetails[0].rowId);
        rowDetails[0].inactiveLines = new list<ReplacementJson.RelatedChildEntRowDetail>{inactivateRows};
        Id ugEntId = entRecord.size() > 1 ? entRecord[1].Id : entRecord[0].Id;
    ReplacementJson.RelatedChildEntRowDetail upgradeLines 
        = createInternalRow(String.valueOf(ugEntId), Integer.valueOf(quoteline.newQty),rowDetails[0].rowId);
        rowDetails[0].upgradeLines = new list<ReplacementJson.RelatedChildEntRowDetail>{upgradeLines};
    lineJson.rowValues =  rowDetails;
    String jsonRow = JSON.serialize(lineJson);
    return jsonRow;
  }

   /***********************************************************************************************************
  * Method Name          : createInternalRow
  * Date Created/Modified: 06/18/2025
  * @description         : create data row for UG and Inactive SKUS
  * Author               : Ankita
  * Purpose              : create data for Replacement Detail field   
  * @param              entId
  * @param              quantity
  * @param              rowId
  * @return             ReplacementJson.RelatedChildEntRowDetail
  /**********************************************************************************************************/
  private static ReplacementJson.RelatedChildEntRowDetail createInternalRow(String entId, Integer quantity, String rowId) {
    ReplacementJson.RelatedChildEntRowDetail result = new ReplacementJson.RelatedChildEntRowDetail();
    result.childEntId =  entId;
    result.childQnty = quantity;
    result.childrowId = rowId;
    return result;
  }
}