/*
 * Description: This is Test Class of InvalidateQuoteBatch
 *
 * Author:      Mustakim Shaikh
 * Date:        May 28, 2024
 */
 
 @isTest
public class InvalidateQuoteBatchTest {

    @testSetup
    static void testData() {
        ShGl_DisableBusinessLogic__c cdf = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Validation_Rules__c = True,
        Disable_SBQQ_Quote_Triggers__c = True,
        Disable_SBQQ_QuoteLine_Validation_Rules__c = True,
        Disable_SBQQ_QuoteLine_Triggers__c = True,
        Disable_Opportunity_Validation_Rules__c = True,
        Disable_Opportunity_Triggers__c = True);
        insert cdf;
        
        TriggerControl__c TC = new TriggerControl__c();
        TC.Name = 'Entitlement';
        TC.DisableTrigger__c = true;
        TC.DisableTrigger__c = true;
        TC.Last_Batch_Run_Date__c = Date.newInstance(2021,04,30);
        TC.SendEmail__c = false;
        insert TC;
        
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
        
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = act.Id;
        opp.CloseDate = Date.newInstance(2021,04,30);
        opp.Partner_Lookup__c = vAccount2.id;
        opp.Distributor_Lookup__c = vAccount.id;
        insert opp;
        
        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Subscription', 
                'IsActive' => true, 
                'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                'SBQQ__SubscriptionTerm__c' => 12, 
                'SBQQ__SubscriptionType__c' => 'Renewable'
                };
        Product2 prdSubs = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        insert prdSubs;
           
        Product2 prdHW = new Product2(Name='Pord-GO-B',ProductCode='Product123XYZ',isActive=true,Eligible_For_Trade_Up__c=true, Product_Type__c = 'Hardware', Product_Level__c = 'Hardware', Eligible_HW_for_Expansion__c = 'R6416S,R6416SE', Usable_Capacity__c = 12,Appliance_Model_HW__c='R6416S',Trade_Up_HW_Value__c=10 );
        prdHW.IsActive = true;
        insert prdHW;
     
        Product2 prdLic = new Product2(Name='Pord-GO-B',ProductCode='Product123XZ',isActive=true, Product_Level__c = 'Hybrid Software', Category__c = 'Bundle', Trade_Up_Multiplier__c = 1.00,Eligible_For_Trade_Up__c=true,Tradeup_Pattern__c = 'License');
        prdLic.IsActive = true;
        insert prdLic;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();

        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        PricebookEntry pbeLic = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeLic.Product2Id = prdLic.Id;
        PricebookEntry pbeSubs = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeSubs.Product2Id = prdSubs.Id;
        pBList.add(pbeSubs);
        pBList.add(pbeHW);
        pBList.add(pbeLic);

        insert pBList;
        
        Asset asst = new Asset(
        Name= 'Test1234567Asset', SerialNumber= 'Test1234567Asset',Serial_Number__c= 'Test1234567Asset',Product2ID=prdHW.Id,
        Accountid =act.Id, Rubrik_Suite__c = 'Business'
        );
        Asset asst2 = new Asset(
        Name= 'XYX', SerialNumber= 'XYX',Serial_Number__c= 'XYX',Product2ID=prdHW.Id,
        Accountid =act.Id, Rubrik_Suite__c = 'Business'
        );
        insert new List<Asset>{asst,asst2};
        


        List<ServiceContract> contractList = new List<ServiceContract>();
        ServiceContract serviceContractObj = new ServiceContract();
        serviceContractObj.Name = 'PolarisContractRenewalQuotesUpdateTests';
        serviceContractObj.SBQQSC__Opportunity__c = opp.Id;
        serviceContractObj.StartDate = System.today();
        serviceContractObj.PriceBook2Id = Test.getStandardPricebookId();
        serviceContractObj.Term = 36;
        serviceContractObj.EndDate = System.today().addDays(365);
        serviceContractObj.SBQQSC__RenewalForecast__c = false;
        serviceContractObj.SBQQSC__RenewalTerm__c = 12;
        
        contractList.add(serviceContractObj);
        insert contractList;
                
        List<contractLineItem> cliList = new List<contractLineItem>(); 
        ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj.SBQQSC__Account__c = vAccount2.Id;
        ContractLineItemObj.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj.Quantity = 10;
        ContractLineItemObj.UnitPrice = 100;
        ContractLineItemObj.StartDate = System.today();
        ContractLineItemObj.EndDate = System.today().addDays(120);
        cliList.add(ContractLineItemObj);
        
         ContractLineItem ContractLineItemObj1 = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        ContractLineItemObj1.SBQQSC__Account__c = vAccount2.Id;
        ContractLineItemObj1.PricebookEntryId = pbeHW.Id;
        ContractLineItemObj1.ServiceContractId = serviceContractObj.Id;
        ContractLineItemObj1.Quantity = 10;
        ContractLineItemObj1.UnitPrice = 100;
        ContractLineItemObj1.StartDate = System.today();
        ContractLineItemObj1.EndDate = System.today().addDays(120);
        cliList.add(ContractLineItemObj1);
        
        insert cliList;
        
        Entitlement ent = new Entitlement(Name='Testing', 
                                          AccountId=act.Id,
                                          AssetId = asst.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj.id,
                                          Product__c =prdHW.id,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365));
        insert ent;
       
            Entitlement ent1 = new Entitlement(Name='Testing', 
                                          AccountId=act.Id,
                                          AssetId = asst2.Id,
                                          ServiceContractId = serviceContractObj.id,
                                          ContractLineItemId = ContractLineItemObj1.id,
                                          Product__c =prdHW.id,
                                          StartDate = Date.today(),
                                          EndDate = Date.today().addDays(365));
        insert ent1;

        List<SBQQ__Quote__c>lstQuote = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        qt.SBQQ__Account__c = act.Id;
        qt.SBQQ__Opportunity2__c = opp.Id;
        qt.SBQQ__SubscriptionTerm__c = 12;
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Type__c = 'Quote';
        qt.RecordTypeId=Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Draft Quote').getRecordTypeId();
    qt.Amended_Renewed_Service_Contract__c = serviceContractObj.Id;
        lstQuote.add(qt);
        
        insert qt;

        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',Expected_Trade_Up_Discount__c=10, SBQQ__Product__c = prdLic.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12,Trade_Up_Serial_Number__c='XYX' );  
        insert qli2;
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id,Category__c = 'Bundle',SBQQ__RequiredBy__c=qli2.Id,Expected_Trade_Up_Discount__c=10, SBQQ__Product__c = prdHW.Id, SBQQ__Quantity__c = 1, SBQQ__Number__c = 1, SubscribedAssetNames__c = 'BB192863040046', Product_Level__c = 'Hardware' , Product_Type__c = 'Hardware',Trade_Up_Multiplier__c =1,SBQQ__SubscriptionTerm__c=12 );  
        insert qli1;
     
        list<SBQQ__QuoteLine__c> qlList = new list<SBQQ__QuoteLine__c>();
        qlList.add(qli2);
        qlList.add(qli1);

        Map<Id,Decimal> maptredeup = new Map<Id,Decimal>();
        QuoteTriggerHandler.isRecursiveLinkOppEnt = false;
        system.debug('check after this'+ QuoteTriggerHandler.isRecursiveLinkOppEnt);
        qt.SBQQ__Primary__c = true;
        qt.SBQQ__Status__c = 'In Review'; //MS flag check add/removing
        qt.Trade_Up_Serial_Numbers__c = asst.SerialNumber;
        qt.Trade_Up_Amounts__c = 57500;
        update qt;

        qli1.Trade_Up_Serial_Number__c = asst.SerialNumber;
        qli1.Trade_Up_Discount__c = 57500;
        TriggerControls.disableQuoteLineTrigger = true;
        LockQuoteValidationByPass.byPassValidation = true;
        Update qli1;
        
        SBQQ.TriggerControl.disable();
        qt.SBQQ__Status__c = 'In Review';
        qt.Trade_Up_Serial_Numbers__c = asst.SerialNumber;
        qt.Trade_Up_Amounts__c = 57500;
        update qt;
    }

    
    testMethod static void testMethodInvalidateQt() {
        Map<String, Date> disqAstSNvsExpDtMap = new Map<String, Date>();
        Set<Id> accIdsSet = new Set<Id>();

        List<SBQQ__Quote__c> qtList = [ SELECT
                                            Id,
                                            Name
                                        FROM SBQQ__Quote__c
                                            WHERE Trade_Up_Amounts__c > 0
                                        ];

        System.debug('MS Quote List:'+JSON.serializePretty(qtList));

        List<Asset> astList = [ SELECT
                                        Id,
                                        Name,
                                        SerialNumber,
                                        Expiration_Date__c,
                                        AccountId
                                        FROM Asset
                                        ];

        for (Asset ast : astList) {
            disqAstSNvsExpDtMap.put(ast.Name, ast.Expiration_Date__c);
            accIdsSet.add(ast.AccountId);
        }

        Test.startTest();
            InvalidateQuoteBatch invlQtBatch = new InvalidateQuoteBatch(disqAstSNvsExpDtMap, accIdsSet);
            Database.executeBatch(invlQtBatch);
            System.debug('MS InvalidateQuoteBatch () , Executed from Test Class');
        	InvalidateQuoteBatch.createErrorLog('MS Test invalidateQuoteBatch - Error while invalidating Quote', 'MS MSg', null);
        Test.stopTest();
    }
}