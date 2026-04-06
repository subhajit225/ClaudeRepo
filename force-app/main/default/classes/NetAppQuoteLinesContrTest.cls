@isTest
public class NetAppQuoteLinesContrTest {

    public static testMethod void testInit(){
        
        ShGl_DisableBusinessLogic__c disableLogic = new ShGl_DisableBusinessLogic__c(Disable_SBQQ_Quote_Triggers__c = true, Disable_Order_Old_Trigger__c = true, Disable_Account_Triggers__c = true);
        disableLogic.Name = 'System Administrator';   
        disableLogic.Disable_Opportunity_Validation_Rules__c = TRUE; 

        insert disableLogic;

        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account acct = new Account(Name='NetApp', RecordTypeId = partnerRecordTypeId);
        insert acct;
        Date closeDt = System.Today()+30;

        opportunity oppr = new opportunity(Name='testing DIEtestsalesforce 27/1/2017' , Sell_to_Partner__c = acct.Id,  AccountId= acct.Id, StageName = '1 Discovery',
                                            CloseDate = closeDt, Lead_Email_Hidden__c='', Partner_Lookup__c =acct.id, Alliance_Partner_Name__c='Amazon', 
                                            Alliance_Source_Type__c='Alliance Initiated Deal', Alliance_Source_Type_HW__c = 'Rubrik Initiated Alliance Deal',
                                            Economic_Buyer__c = 'Test', Metric__c = 'Test', Decision_Process__c = 'Test', Decision_Criteria__c = 'Test',
                                            Identified_Pain__c = 'Test', Champion__c = 'Test', Why_Rubrik__c = 'Why_Rubrik',
                                            Why_do_anything__c = 'Why_do_anything', Why_now__c = 'Why_now', //Alliance_HW_Partner__c = 'Cisco', 
                                            Partner_Representative__c = 'Test');
SBQQ.TriggerControl.disable();
        insert oppr;

        Id standardPriceBookId = Test.getStandardPricebookId();//pb2Standard.Id;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<Product2> lstProducts = new List<Product2>{
            new Product2(Name = 'Product XY', ProductCode = 'Pro-XY', isActive = true),
            new Product2(Name = 'RBK-R304-01', ProductCode = 'RBK-R304-01', isActive = true),
            new Product2(Name = 'Premium Support 1-Yr Prepaid, r304', ProductCode = 'RBK-SVC-PREM-R304', isActive = true)
        };

        insert lstProducts;

        List<PricebookEntry> lstPricebooks = new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[0].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[1].Id, UnitPrice = 100.00, IsActive = true),
            new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = lstProducts[2].Id, UnitPrice = 100.00, IsActive = true)
        };
        
        insert lstPricebooks;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c = oppr.Id,
            SBQQ__StartDate__c = System.today(),
            SBQQ__SubscriptionTerm__c = 12,
            SBQQ__Primary__c = true,
            SBQQ__PriceBook__c = Test.getStandardPricebookId());
        insert quote;
        test.startTest();

        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SubscribedAssetNames__c='testAsset', Usable_Capacity__c = 30, SBQQ__Product__c = lstProducts[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, GPL__c='NetApp', Product_Level__c='Hardware', Approval_Category__c = 'Hardware (H)'));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SubscribedAssetNames__c='testAsset', Usable_Capacity__c = 30, SBQQ__Product__c = lstProducts[1].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, GPL__c='NetApp', Product_Level__c='AddOn', Approval_Category__c = 'Hardware (H)'));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SubscribedAssetNames__c='testAsset', Usable_Capacity__c = 30, SBQQ__Product__c = lstProducts[2].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = 'Fixed Price', SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = 12, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, GPL__c='NetApp',SBQQ__SubscriptionTerm__c=12, Product_Level__c='Hardware', Approval_Category__c = 'Hardware (H)'));
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SubscribedAssetNames__c='testAsset', Usable_Capacity__c = 30, SBQQ__Product__c = lstProducts[1].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200, GPL__c='NetApp', Product_Level__c='Hardware', Approval_Category__c = 'Hardware (H)',SBQQ__Renewal__c = true, Disposition_Reason__c = 'Renewing'));
        insert lines[0];
        lines[1].SBQQ__RequiredBy__c = lines[0].Id;
        lines[2].SBQQ__RequiredBy__c = lines[0].Id; 
        insert lines[1];
        insert lines[2];
        insert lines[3];
        
            ApexPages.currentPage().getParameters().put('qid',quote.Id);
            NetAppQuoteLinesContr inst = new NetAppQuoteLinesContr();
            inst.init();
        Test.stopTest();
    }
}