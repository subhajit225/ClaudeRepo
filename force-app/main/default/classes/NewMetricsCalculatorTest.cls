/***********************************************************************************************************
* Class Name           : NewMetricsCalculatorTest
* Date Created/Modified: 15/05/2025
* Author               : Sumedha
* @description         : Test class for NewMetricsCalculator, MetricsCalculatorUtil, MetricsCalculatorQueueable
/**********************************************************************************************************/
@isTest
public class NewMetricsCalculatorTest {
    /***********************************************************************************************************
    * Method Name          : setup
    * @description         : Test Data Setup method
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
                                                Disable_SBQQ_Quote_Validation_Rules__c= true, Disable_Entitlement_Validation_Rules__c = true);
        INSERT new ShGl_DisableBusinessLogic__c(setupownerid = UserInfo.getUserId(), 
                                                Disable_Account_Triggers__c = TRUE,Disable_Asset_Triggers__c=TRUE,
                                                Disable_SBQQ_QuoteLine_Triggers__c=true,Disable_SBQQ_Quote_Triggers__c=true,
                                                Disable_Opportunity_Triggers__c=true,Disable_ServiceContract_Trigger__c=true,
                                                Disable_Contract_Line_Item_Triggers__c=true, Disable_SBQQ_QuoteLine_Validation_Rules__c= true,
                                                Disable_SBQQ_Quote_Validation_Rules__c= true, Disable_Entitlement_Validation_Rules__c = true);

        //Account
        String recordTypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
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
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-01', 'RBK-R6410-01', 'Foundation Edition', 'Enterprise Data Protection', 'Subscription', 'Foundation Edition', 'SaaS'));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-02', 'RBK-R6410-02', 'Foundation Edition', 'Enterprise Data Protection', 'Subscription', 'Foundation Edition', 'Subscriptions'));
        lstPrd.add(Replacement_TestDataFactory.getProduct('RBK-R6410-03', 'RBK-R6410-03', 'Business Edition', 'JIRA Data Protection', 'Subscription', 'M365H', 'Subscriptions'));
        lstPrd[0].SBQQ__SubscriptionTerm__c = 1;
        lstPrd[1].SBQQ__SubscriptionTerm__c = 1;
        lstPrd[2].SBQQ__SubscriptionTerm__c = 1;
        INSERT lstPrd;
        for (Product2 prod : lstPrd) {
        lstPrdIds.add(prod.id);
        }

        List<Id> lstPB = new List<Id>();
        //Standard PriceBook
        Id standardPriceBookId= Test.getStandardPricebookId();
        lstPB.add(standardPriceBookId);
        
        //Custom PriceBook
        List<Id> customlstPB = new List<Id>();
        PriceBook2 customPB = Replacement_TestDataFactory.getPriceBook(); 
        INSERT customPB;
        customlstPB.add(customPB.Id);

        //Create PriceBook Entries for Standard and Custom PriceBook
        List<PricebookEntry> lstEntry = new List<PricebookEntry>();
        //Standard PriceBookEntry
        lstEntry = TestDataFactory.getPriceBookEntry (lstPrdIds, lstPB);
        INSERT lstEntry;

        //Create PriceBook Entries for Standard and Custom PriceBook
        List<PricebookEntry> lstCustEntry = new List<PricebookEntry>();
        //Standard PriceBookEntry
        lstCustEntry = TestDataFactory.getPriceBookEntry (lstPrdIds, customlstPB);
        INSERT lstCustEntry;

        //Opportunity
        List<Opportunity> oppList= new List<Opportunity>();
        Opportunity opp= TestDataFactory.getOpportunity(acc, con);
        oppList.add(opp);
        Test.startTest();
        INSERT oppList;
        
        //Quote
        List<SBQQ__Quote__c> qbList= new List<SBQQ__Quote__c>();
        SBQQ__Quote__c quoteRec = Replacement_TestDataFactory.getQuote(acc.Id, opp.Id, customPB.Id, 'Renewal+Expansion');
        qbList.add(quoteRec);
        SBQQ.TriggerControl.disable();
        TriggerControls.disableQuoteTrigger = true;
        TriggerControls.disableQuoteLineTrigger = true;
        INSERT qbList;

        //Ceate Asset
        List<Asset> asstList = new  List<Asset>();
        Asset asst= Replacement_TestDataFactory.getAsset('Asset122', lstPrd[0].Id, acc.Id);
        asstList.add(asst);
        INSERT asstList;

        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c qli= Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[1], null); 
        SBQQ__QuoteLine__c qli1= Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[2], null); 
        SBQQ__QuoteLine__c qli3= Replacement_TestDataFactory.getQuoteLine(asst.Id, asst, quoteRec.Id, lstPrdIds[2], null); 
        qli.SBQQ__SubscriptionTerm__c = 12;
        qli.SBQQ__Quantity__c = 1;
        qli1.SBQQ__SubscriptionTerm__c = 12;
        qli1.SBQQ__Quantity__c = 1;
        qli3.SBQQ__SubscriptionTerm__c = 12;
        qli3.SBQQ__Quantity__c = 1;
        qlList.add(qli);
        qlList.add(qli1);
        qlList.add(qli3);
        insert qlList;

        //Create Order
        Order ordr= Replacement_TestDataFactory.getOrder(acc.Id, opp.Id, standardPriceBookId);
        INSERT ordr;
        
        ordr.Pricebook2Id = customPB.Id;
        UPDATE ordr;

        List<OrderItem> oliList = new List<OrderItem>();
        OrderItem oli1= Replacement_TestDataFactory.getOrderItem(lstPrd[0].Id, ordr.Id, lstCustEntry[0].Id);
        OrderItem oli2= Replacement_TestDataFactory.getOrderItem(lstPrd[1].Id, ordr.Id, lstCustEntry[1].Id);
        oliList.add(oli1);
        oliList.add(oli2);
        INSERT oliList;

        ServiceContract serviceContractObj = Replacement_TestDataFactory.getServiceContract(acc.Id, opp.Id, customPB.Id);
        INSERT serviceContractObj;
        
        List<ContractLineItem> lstCLI = new List<ContractLineItem>();
        ContractLineItem ContractLineItemObj = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstCustEntry[0].Id, serviceContractObj.Id);
        ContractLineItemObj.EndDate = Date.today().addDays(365);
        ContractLineItemObj.StartDate =  Date.today();
        ContractLineItemObj.SBQQSC__Product__c = lstPrdIds[0];
        ContractLineItemObj.SBQQSC__Quantity__c = 1;
        lstCLI.add(ContractLineItemObj);
        ContractLineItem ContractLineItemObj1 = Replacement_TestDataFactory.getContractLineItem(acc.Id, asst.Id, lstCustEntry[1].Id, serviceContractObj.Id);
        ContractLineItemObj1.EndDate = date.newinstance(2028, 2, 17);
        ContractLineItemObj1.StartDate =  date.newinstance(2027, 2, 17);
        ContractLineItemObj1.SBQQSC__Product__c = lstPrdIds[1];
        ContractLineItemObj.SBQQSC__Quantity__c = 1;
        lstCLI.add(ContractLineItemObj1);
        insert lstCLI;

        //Entitlement 
        List<Entitlement> entList= new List<Entitlement>();
        Entitlement ent = Replacement_TestDataFactory.getEntitlement('Test Entitlement', acc.Id, lstPrd[0].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj.Id);
        Entitlement ent1 = Replacement_TestDataFactory.getEntitlement('Test Entitlement1', acc.Id, lstPrd[0].Id, asst.Id, oliList[0].Id, serviceContractObj.Id, ContractLineItemObj1.Id);//Inactive
        ent1.EndDate = date.newinstance(2028, 2, 17);
        ent1.StartDate = date.newinstance(2027, 2, 17);
        entList.add(ent);
        entList.add(ent1);
        INSERT entList;
        
        ReplacementJson jsonData = new ReplacementJson ();
        jsonData.rowValues = new List<ReplacementJson.RowDetail>();
        jsonData.mode = 'dispose';
        ReplacementJson.RowDetail row = new ReplacementJson.RowDetail();
        row.entId = ent1.Id;
        jsonData.rowValues.add(row);
        qli.Replacement_Details__c = JSON.serialize(jsonData);
        qli.SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id;
        qli.Disposition_Reason__c = 'Renewing';
        qli.RTAWithoutUplift__c = 1000;
        qli.RenGrowth__c = 100;
        qli1.Replacement_Details__c = JSON.serialize(jsonData);
        qli1.SBQQSC__RenewedContractLine__c = ContractLineItemObj1.Id;
        qli3.Replacement_Details__c = '';
        qli3.SBQQSC__RenewedContractLine__c = null;
        update qlList;
        
        Test.stopTest();
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
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            //Get Product data 
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,Product_Code_Type__c FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 10];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c='Renewal+Expansion' LIMIT 1];
            List<SBQQ__QuoteLine__c> qlList= [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: qb.Id];
            qb.RWD_Sales_Rep_Exception__c = '25% Premium RSC-G Replacement';
            System.assert(qlList.size()>0, 'Expansion Group lines created'); 

            Set<Id> quoteIds = new Set<Id>();
            quoteIds.add(qb.Id);

            Test.startTest();
            qb.SBQQ__Primary__c = true;
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            update qb;

            NewMetricsCalculator.calculateMetrics(quoteIds);
            MetricsCalculatorQueueable queueableClass = new MetricsCalculatorQueueable(quoteIds);
            System.enqueueJob(queueableClass);
            Test.stopTest();

        }
    }

    /***********************************************************************************************************
    * Method Name          : replacementControllerTestMethod2
    * @description         : SAL26-1343
    /**********************************************************************************************************/
    testmethod static void replacementControllerTestMethod2(){
        user usr1 = [SELECT Id FROM User WHERE email  = 'testuser@testclass.com' LIMIT 1];
        System.runAs(usr1) {
            Account acc = [SELECT Id, Name FROM Account LIMIT 1];
            //Get Product data 
            List<Product2> prodResult= [SELECT Id , Name, Replacement_Category__c,License_Sub_Category__c,Product_Code_Type__c FROM Product2 WHERE Name like 'RBK-R6410%' LIMIT 10];
            
            //Get Quote data
            SBQQ__Quote__c qb= [SELECT Id, Name, SBQQ__PriceBook__c,CreatedDate,Is_Scale_Utility_Quote__c,GPL_Deal__c, SBQQ__Account__c, SBQQ__Type__c FROM SBQQ__Quote__c WHERE SBQQ__Type__c='Renewal+Expansion' LIMIT 1];
            List<SBQQ__QuoteLine__c> qlList= [SELECT Id, SBQQ__Group__c, SBQQ__Group__r.name, SBQQ__Quantity__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=: qb.Id];
            qb.RWD_Sales_Rep_Exception__c = '25% Premium RSC-G Replacement';
            System.assert(qlList.size()>0, 'Expansion Group lines created'); 
            for(SBQQ__QuoteLine__c qlRec : qlList){
                qlRec.Special_Program__c = 'Conversion';                
            }
            update qlList;
            Set<Id> quoteIds = new Set<Id>();
            quoteIds.add(qb.Id);

            Test.startTest();
            qb.SBQQ__Primary__c = true;
            SBQQ.TriggerControl.disable();
            TriggerControls.disableQuoteTrigger = true;
            TriggerControls.disableQuoteLineTrigger = true;
            update qb;

            NewMetricsCalculator.calculateMetrics(quoteIds);
            MetricsCalculatorQueueable queueableClass = new MetricsCalculatorQueueable(quoteIds);
            System.enqueueJob(queueableClass);
            Test.stopTest();

        }
    }

}