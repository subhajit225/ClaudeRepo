//Test Class for  UpdateCSATOnQuoteOppBatch
@isTest
public class UpdateCSATOnQuoteOppBatchTest {
    public static Account act;
    public static Entitlement ent;
    public static Product2 prdHW;
    public static PricebookEntry pbeHW;
    public static Asset ast;
    public static ContractLineItem contractLineItem;
    public static ServiceContract serviceContract;
    public static Opportunity opportunityObj;
    
        static {
        ShGl_TestFactoryHelper.insertTriggerControls();

        
        act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        prdHW.ProductCode = 'RBK-SVC-test-product';
        insert prdHW;
        
        pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;

        ast = (Asset) ShGl_TestFactory.createSObject(new Asset(), null);
        ast.AccountId = act.Id;
        ast.Name = 'EntitlementTriggerHelperAsset';
        ast.Product2Id = prdHW.Id;
        insert ast;

        opportunityObj = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opportunityObj.AccountId = act.Id;
        opportunityObj.Name = 'EntitlementTriggerHelper Opportunity';
        opportunityObj.CloseDate = System.today().addMonths(12);
        opportunityObj.StageName = 'Prospecting';
        opportunityObj.Pricebook2Id = Test.getStandardPricebookId();
        insert opportunityObj;

        serviceContract = new ServiceContract();
        serviceContract.Name = 'EntitlementTriggerHelper Contract';
        serviceContract.SBQQSC__Opportunity__c = opportunityObj.Id;
        serviceContract.SBQQSC__RenewalOpportunity__c = opportunityObj.Id;    
        serviceContract.AccountId = act.Id;
        serviceContract.StartDate = System.today();
        serviceContract.PriceBook2Id = Test.getStandardPricebookId();
        serviceContract.Term = 36;
        serviceContract.SBQQSC__RenewalForecast__c = true;
        serviceContract.Is_Renewed__c = true;
        serviceContract.CSAT_Quoted__c = true;    
        insert serviceContract;
        
        contractLineItem = (ContractLineItem) ShGl_TestFactory.createSObject(new ContractLineItem(), null);
        contractLineItem.SBQQSC__Account__c = act.Id;
        contractLineItem.AssetId = ast.Id;
        contractLineItem.PricebookEntryId = pbeHW.Id;
        contractLineItem.ServiceContractId = serviceContract.Id;
        contractLineItem.New_Extended_End_Date__c = system.today();    
        insert contractLineItem;

        ent = (Entitlement) ShGl_TestFactory.createSObject(new Entitlement(), null);
        ent.AccountId = act.Id;
        ent.StartDate = Date.today().addDays(-365);
        ent.EndDate = Date.today().addDays(365);
        ent.AssetId = ast.Id;
        ent.ContractLineItemId = contractLineItem.Id;
        ent.Renewable__c = true;
        ent.Type = 'Phone Support';
        ent.Name = 'EntitlementTriggerHelper';
        ent.Product__c = prdHW.Id;
        ent.Refreshed_Opportunity_Link__c = opportunityObj.Id;
        ent.ServiceContractId = serviceContract.Id;
        insert ent;
    }
    
 @isTest
    private static void testBatch() {
        Set<Id> contractlineIdSet = new Set<Id>();
        
        for(contractlineitem cli : [select Id,ServiceContractID from ContractLineItem]){
            contractlineIdSet.add(cli.Id);
        }
        
        Test.startTest();
        UpdateCSATOnQuoteOppBatch b = new UpdateCSATOnQuoteOppBatch(contractlineIdSet);
        Database.executeBatch(b, 10);
        Test.stopTest();

    }
}