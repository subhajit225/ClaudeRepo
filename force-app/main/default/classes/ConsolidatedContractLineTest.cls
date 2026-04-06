/***********************************************************************************************************
* Class Name           : ConsolidatedContractLineTest
* Date Created/Modified: 28/02/2025
* Author               : Sumedha
* @description         : Test class for ReplacementQueryController
* Test Class           :
/**********************************************************************************************************/
@isTest
public class ConsolidatedContractLineTest { 
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
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = usr1.Id, 
                        Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                        Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
                        Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
                        Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
                        Disable_SBQQ_Quote_Validation_Rules__c= true, Disable_Order_Triggers__c= true);
        
        //Account
        String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
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
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-01', 'RBK-R6410-01', 'Foundation Edition', 'Enterprise Data Protection', 'Subscription', 'Foundation Edition', 'SaaS'));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-02', 'RBK-R6410-02', 'Foundation Edition', 'Enterprise Data Protection', 'Subscription', 'Foundation Edition', 'Subscriptions'));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-01', 'RBK-R6410-01', 'Foundation Edition', 'Enterprise Data Protection', 'Subscription', 'Foundation Edition', 'SaaS'));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-02', 'RBK-R6410-02', 'Foundation Edition', 'Enterprise Data Protection', 'Subscription', 'Foundation Edition', 'Subscriptions'));
        lstPrd[0].Product_Level__c = 'Hybrid Software';
        lstPrd[1].Product_Level__c = 'Hybrid Software';
        INSERT lstPrd;
        for (Product2 prod : lstPrd) {
        lstPrdIds.add(prod.id);
        }

        List<Id> lstPB = new List<Id>();
        List<Id> lstPBCust = new List<Id>(); 
        //Create PriceBook Entries for Standard and Custom PriceBook
        List<PricebookEntry> lstEntryStd = new List<PricebookEntry>();
        List<PricebookEntry> lstEntryCust = new List<PricebookEntry>();
        //Standard PriceBook
        Id standardPriceBookId= Test.getStandardPricebookId();
        lstPB.add(standardPriceBookId);
        //Standard PriceBookEntry
        lstEntryStd = TestDataFactory.getPriceBookEntry (lstPrdIds, lstPB);
        INSERT lstEntryStd;
        
        //Custom PriceBook
        PriceBook2 customPB = Replacement_TestDataFactory.getPriceBook(); 
        INSERT customPB;
        lstPBCust.add(customPB.Id);

        lstEntryCust = TestDataFactory.getPriceBookEntry (lstPrdIds, lstPBCust);
        INSERT lstEntryCust;

        
        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= TestDataFactory.getOpportunity(acc, con);
        Opportunity opp1= TestDataFactory.getOpportunity(acc, con);
        oppList.add(opp);
        oppList.add(opp1);
        INSERT oppList;
        
        //Quote
        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec1 = Replacement_TestDataFactory.getQuote(acc.Id, opp1.Id, customPB.Id, 'Renewal');
        qbList.add(quoteRec1);
        INSERT qbList;

        //Ceate Asset
        List<Asset> asstList = new  List<Asset>();
        Asset asst= Replacement_TestDataFactory.getAsset('Asset122', lstPrd[0].Id, acc.Id);
        asstList.add(asst);
        INSERT asstList;

        //Polaris SKU Mapping
        List<Polaris_SKU_Mapping_V2__c> polarisSKUMappingObjList = new List<Polaris_SKU_Mapping_V2__c>();
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj = Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[2].Id, lstPrd[0].Id);
        Polaris_SKU_Mapping_V2__c polarisSKUMappingObj1 = Replacement_TestDataFactory.getPolarisSKUMapping(lstPrd[3].Id, lstPrd[1].Id);
        polarisSKUMappingObjList.add(polarisSKUMappingObj);
        polarisSKUMappingObjList.add(polarisSKUMappingObj1);
        INSERT polarisSKUMappingObjList;

        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        Test.startTest();
        INSERT ordr;
        
        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;

        List<OrderItem> oliList = new List<OrderItem>();
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(lstPrd[2].Id, ordr.Id, lstEntryCust[2].Id);
        OrderItem oli2= Replacement_TestDataFactory.getOrderItem(lstPrd[3].Id, ordr.Id, lstEntryCust[3].Id);
        oliList.add(oli1);
        oliList.add(oli2);
        INSERT oliList;

        ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opp.Id, customPB.Id);
        INSERT serviceContractObj;

        
        List<ContractLineItem> lstCLI = new List<ContractLineItem>();
        ContractLineItem ContractLineItemObj = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntryCust[2].Id, serviceContractObj.Id);
        ContractLineItemObj.EndDate = Date.today().addDays(365);
        ContractLineItemObj.StartDate =  Date.today();
        ContractLineItemObj.SBQQSC__Product__c = lstPrdIds[2];
        lstCLI.add(ContractLineItemObj);
        ContractLineItem ContractLineItemObj1 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntryCust[2].Id, serviceContractObj.Id);
        ContractLineItemObj1.EndDate = date.newinstance(2028, 2, 17);
        ContractLineItemObj1.StartDate =  date.newinstance(2027, 2, 17);
        ContractLineItemObj1.SBQQSC__Product__c = lstPrdIds[2];
        lstCLI.add(ContractLineItemObj1);
        ContractLineItem ContractLineItemObj2 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntryCust[3].Id, serviceContractObj.Id);
        ContractLineItemObj2.EndDate = Date.today().addDays(365);
        ContractLineItemObj2.StartDate =  Date.today();
        ContractLineItemObj2.SBQQSC__Product__c = lstPrdIds[3];
        lstCLI.add(ContractLineItemObj2);
        ContractLineItem ContractLineItemObj3 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstEntryCust[3].Id, serviceContractObj.Id);
        ContractLineItemObj3.EndDate = Date.today().addDays(365);
        ContractLineItemObj3.StartDate =  Date.today();
        ContractLineItemObj3.SBQQSC__Product__c = lstPrdIds[3];
        insert lstCLI;

        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();
        Entitlement ent = Replacement_TestDataFactory.getEntitlement('Test Entitlement', acc.Id, lstPrd[2].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj.Id);
        Entitlement ent1 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[2].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj1.Id);//Inactive
        Entitlement ent2 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[3].Id, asst.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj2.Id); //Upgrade Product
        Entitlement ent3 = Replacement_TestDataFactory.getEntitlement('Test HWSuppEntitlement', acc.Id, lstPrd[3].Id, asst.Id, oliList[1].Id, serviceContractObj.Id, ContractLineItemObj3.Id); //HW Support
        ent1.EndDate = date.newinstance(2028, 2, 17);
        ent1.StartDate = date.newinstance(2027, 2, 17);
        entList.add(ent);
        entList.add(ent1);
        entList.add(ent2);
        entList.add(ent3);
        INSERT entList;
        
        //Scale Entitlement
        List<Scale_Entitlement__c> scaleEntList = new List<Scale_Entitlement__c>();
        Scale_Entitlement__c scaleEnt= Replacement_TestDataFactory.getScaleEntitlement(ent.Id, asst.Id);
        scaleEntList.add(scaleEnt);
        INSERT scaleEnt;

        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli= Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrdIds[1], ContractLineItemObj1.Id); 
        SBQQ__QuoteLine__c qli1= Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrdIds[2], ContractLineItemObj2.Id); 
        //SBQQ__QuoteLine__c qli2= Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec1.Id, lstPrdIds[2], ContractLineItemObj2.Id); 
        qlList.add(qli);
        qlList.add(qli1);
        //qlList.add(qli2);
        insert qlList;
        Test.stopTest();

    }
    testmethod static void ccliTestMethod (){
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            //Get Account data
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c FROM SBQQ__Quote__c  LIMIT 1];

            //Get Quote Lines
            List<SBQQ__QuoteLine__c> qlList= [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: qb.Id];
            System.assert(qlList.size()>0, 'Expansion Group lines created'); 
            //Get Contract Lines
            List<ContractLineItem> clis = [SELECT Id, Total_Price_Without_Promo__c, CPQ_Uplift__c FROM ContractLineItem];

            List<Consolidated_Contract_Lines__c> ccliRecs = new List<Consolidated_Contract_Lines__c>();
            Consolidated_Contract_Lines__c cli1 = new Consolidated_Contract_Lines__c();
            cli1.Contract_Line_Item__c = clis[0].Id;
            cli1.Quote_Line__c = qlList[0].Id;
            ccliRecs.add(cli1);

            Consolidated_Contract_Lines__c cli2 = new Consolidated_Contract_Lines__c();
            cli2.Contract_Line_Item__c = clis[1].Id;
            cli2.Quote_Line__c = qlList[1].Id;
            ccliRecs.add(cli2);

            insert ccliRecs;
        }

    }
}