@isTest
public class CodeCoverageOldTrigger_Test {
    
    //Test - Old Trigger Code Coverage
    static testMethod void testMethod_AccountCreationOldTrigger() {
	
        ShGl_TestFactoryHelper.insertTriggerControls();
        
        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
    }
    /*
    //Test - Old Trigger Code Coverage
    static testMethod void testMethod_OpportunityCreationOldTrigger() {

        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        //Generate the Contact
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt.AccountId = act.Id;
        insert cnt;

        Map<String, Object> prdMap = new Map<String, Object> {
            'Name' => 'Standalone',
            'IsActive' => true,
            'SBQQ__AssetConversion__c' => 'One per unit'
        };

        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        insert prdHW;

        List<PricebookEntry> pBList = new List<PricebookEntry> ();
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;

        //Generate the Opportunity
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = act.Id;
        opp.Lead_Email_Hidden__c = cnt.Email;
        opp.Converted_From_Lead__c = TRUE;
        opp.Pricebook2Id = Test.getStandardPriceBookId();
        
        Test.startTest();
        insert opp;
		system.debug('opp.pricebook2Id!!!!'+opp.pricebook2Id+' -- Test.getStandardPriceBookId() !!!'+Test.getStandardPriceBookId());
        
        OpportunityLineItem oli = new OpportunityLineItem(PricebookEntryId = pbeHW.Id, OpportunityId = opp.Id, Quantity = 1, TotalPrice = 1000);
        //insert oli;
        
        //Opportunity_Service.insertNewOrder(new List<Opportunity> {opp});
            
        List<Order> ordList = [SELECT Id, OrderNumber, OpportunityId FROM Order ORDER BY CreatedDate DESC];
        //Opportunity_Service.updatetExistingOrder(ordList);
        
        Test.stopTest();
        
    }*/
    //Test - Old Trigger Code Coverage
    static testMethod void testMethod_OpportunityServiceOldTrigger() {

        ShGl_TestFactoryHelper.insertTriggerControls();

        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        insert usr;

        Test.startTest();
        Test.stopTest();
        
    }


}