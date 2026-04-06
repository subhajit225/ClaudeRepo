@isTest
public class GTC_ScreenAccountsBatchTest {
    
    @testSetup
    static void createData(){
        try{
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Name = 'System Administrator', Disable_Opportunity_Validation_Rules__c = TRUE, Disable_SBQQ_Quote_Triggers__c = true, 
                                                                                     Disable_Account_Triggers__c = true,Disable_Entitlement_Trigger__c=true,Disable_Opportunity_Triggers__c=true,
                                                                                     Disable_ServiceContract_Trigger__c =true );
        insert disableLogic;
            FlowControll.accountTrigger = false;
        
         
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act = new Account(
            Name = 'Customer',
            recordtypeId = partner,
            Phone = '123-456-7890',
            AccountNumber = 'Test',
            BillingStreet = '123 street',
            BillingCity = 'Santa Clara',
            BillingState = 'California',
            BillingPostalCode = '95050',
            BillingCountry = 'United States',
            ShippingStreet = '123 street',
            ShippingCity = 'Santa Clara',
            ShippingState = 'California',
            ShippingPostalCode = '95050',
            ShippingCountry = 'United States'
        );
            
		insert act;
            
            
            Account sdpAccount = new Account(
                Name = 'SDP',
                recordtypeId = partner,
                Phone = '123-456-7890',
                AccountNumber = 'Test',
                BillingStreet = '123 street',
                BillingCity = 'Santa Clara',
                BillingState = 'California',
                BillingPostalCode = '95050',
                BillingCountry = 'United States',
                ShippingStreet = '123 street',
                ShippingCity = 'Santa Clara',
                ShippingState = 'California',
                ShippingPostalCode = '95050',
                ShippingCountry = 'United States'
            );
            
            insert sdpAccount;
        
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        prdHW.Product_Subtype__c = 'GO';
        prdHW.SBQQSC__EntitlementConversion__c = 'One per unit';
        insert prdHW;
        
       
            
          /*  PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
            insert pbeHW;*/
            
            List<PricebookEntry> entries = new List<PricebookEntry>();
            
            entries.add(new PricebookEntry(UseStandardPrice = false, Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prdHW.Id, IsActive = true, UnitPrice = 100));
            insert entries;
            TriggerControl__c objOrderTrigger = new TriggerControl__c(Name = 'Entitlement', Disable_Trigger__c = true, DisableTrigger__c = true, SendEmail__c = false);
            insert objOrderTrigger;
        
       Asset ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Name = 'EntitlementTriggerHelperAsset';
        ast.Rubrik_Suite__c = 'Foundation';
        ast.Payment_Options__c = 'Annual';
        ast.SerialNumber = '123\\s+';
        ast.Support_Type__c = 'L3';
        ast.Licensing_Model__c = 'Perpetual';
        ast.Product2Id = prdHW.Id;
        insert ast;
        
      Opportunity  opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Partner_Lookup__c = act.Id;
        opportunityObj.Distributor_Lookup__c = opportunityObj.AccountId;
        
        opportunityObj.Amount = 100;
        opportunityObj.OppSubscriptionTermMonths__c = 12;
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
      	opportunityObj.Deal_Structuring_Oppty_Notes__c = 'Test';
            
        insert opportunityObj;
        
       ServiceContract serviceContract = new ServiceContract();
        serviceContract.Name = 'EntitlementTriggerHelper Contract';
        serviceContract.SBQQSC__Opportunity__c = opportunityObj.Id;
        serviceContract.AccountId = act.Id;
        serviceContract.StartDate = System.today();
        serviceContract.PriceBook2Id = Test.getStandardPricebookId();
        serviceContract.Term = 36;
        insert serviceContract;
           
            /*contractLineItem contractLineItem=EntitlementTriggerHelperClass_Test.GetContractLineItem();
        insert contractLineItem;
        system.debug('#contractline');
       Entitlement  ent= EntitlementTriggerHelperClass_Test.GetEntitlement();
        ent.ContractLineItemId = contractLineItem.Id;
        ent.AccountId = act.Id;
            insert ent; */
            List<contractLineItem> cliList = new List<contractLineItem>();
            ContractLineItem ContractLineItemObj = (ContractLineItem) ShGl_TestFactory.createSObject(
                new ContractLineItem(),
                null
            );
            ContractLineItemObj.SBQQSC__Account__c =  act.Id;
            ContractLineItemObj.PricebookEntryId = entries[0].id;
            ContractLineItemObj.ServiceContractId = serviceContract.Id;
            ContractLineItemObj.Quantity = 10;
            ContractLineItemObj.UnitPrice = 100;
            ContractLineItemObj.StartDate = System.today();
            ContractLineItemObj.EndDate = System.today().addDays(120);
            cliList.add(ContractLineItemObj);
            insert cliList;
            
            Entitlement ent = new Entitlement(
                Name = 'Testing',
                AccountId = act.Id,
                ServiceContractId = serviceContract.id,
                ContractLineItemId = cliList[0].id,
                Product__c = prdHW.id,
                StartDate = Date.today().addDays(-30),
                MSP_End_User_Lookup__c = sdpAccount.id,
                AssetId = ast.Id,
                Entitlement_Subtype__c = 'Free Trial',
                EndDate = Date.today().addDays(30)
            );
        insert ent; 
            
    }catch(exception e){
        system.debug('err'+e.getMessage()+e.getStackTraceString()+e.getlineNumber());
    }
        
    }
        
    
    @isTest
    static void testBatchExecution() {
        // Prepare test data
        // Start batch job
        Test.startTest();
        GTC_ScreenAccountsBatch batchJob = new GTC_ScreenAccountsBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
    }
    @isTest
    static void testBatchExecution1() {
        Account acc = [Select id,Name,Account_Screening__c from Account Limit 1];
        
         Account_Screening__c acctscr = new Account_Screening__c();
        acctscr.Name = acc.Name;
        acctscr.Screening_Eligibility__c = false;
        acctscr.Screening_Action__c = 'Start';
        acctscr.Screening_Action_Status__c = 'Ready';
        acctscr.Account__c = acc.Id;
        acctscr.Unique_Parent_Id__c = acc.Id;
        insert acctscr;
        
        acc.Account_Screening__c = acctscr.id;
        update acc;
        
        Test.startTest();
        GTC_ScreenAccountsBatch batchJob = new GTC_ScreenAccountsBatch();
        Database.executeBatch(batchJob);
        Test.stopTest();
        
    }
  
}