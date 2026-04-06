@isTest
public class RubrikPageSecurityPlugin_Test {

    testMethod static void test_PageSecurityPlugin () {
        
        String pageName = 'EditLines';
        
		Schema.DescribeFieldResult F = Product2.SBQQ__SubscriptionTerm__c.getDescribe();
		Schema.sObjectField T = F.getSObjectField();

        RubrikPageSecurityPlugin pgS = new RubrikPageSecurityPlugin();
        pgS.isFieldEditable(pageName, T);
        pgS.isFieldEditable(pageName, T, null);
        pgS.isFieldVisible(pageName, T);
        pgS.isFieldVisible(pageName, T, null);
    }
    
    //Example Test Class Code
    static testMethod void test_PageSecurityPlugin_1 () {

        ShGl_TestFactoryHelper.insertTriggerControls();

        //Generate the Account
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        //Generate the Contact
        Contact cnt = (Contact) ShGl_TestFactory.createSObject(new Contact(), null);
        cnt.AccountId = act.Id;
        insert cnt;

        //Generate the Opportunity
        Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), null);
        opp.AccountId = act.Id;
        insert opp;

        SBQQ__Quote__c qt = (SBQQ__Quote__c) ShGl_TestFactory.createSObject(new SBQQ__Quote__c(), null);
        insert qt;
        
		//SBQQ__QuoteLine__c qtLine = (SBQQ__QuoteLine__c) ShGl_TestFactory.createSObject(new SBQQ__QuoteLine__c(), null);
		//qtLine.SBQQ__Quote__c = qt.Id;
        //insert qtLine;

        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), null);
        insert prdHW;
        
        PricebookEntry pbeHW = (PricebookEntry) ShGl_TestFactory.createSObject(new PricebookEntry(), null);
        pbeHW.Product2Id = prdHW.Id;
        insert pbeHW;

        List<SBQQ__QuoteLine__c> qtLines = new List<SBQQ__QuoteLine__c>();
        qtLines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, 
                                         SBQQ__Product__c = prdHW.Id, 
                                         SBQQ__PricebookEntryId__c = pbeHW.Id,
                                         SBQQ__Quantity__c = 1, 
                                         SBQQ__SubscriptionPricing__c = null, 
                                         SBQQ__StartDate__c = System.today(), 
                                         SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), 
                                         SBQQ__DefaultSubscriptionTerm__c = null, 
                                         SBQQ__ListPrice__c = 200, 
                                         SBQQ__NetPrice__c = 200));
        insert qtLines;
        
        String pageName = 'EditLines';
        
		Schema.DescribeFieldResult F = Product2.SBQQ__SubscriptionTerm__c.getDescribe();
		Schema.sObjectField T = F.getSObjectField();

        RubrikPageSecurityPlugin pgS = new RubrikPageSecurityPlugin();
        pgS.isFieldEditable(pageName, T);
        pgS.isFieldEditable(pageName, T, qtLines.get(0));
        pgS.isFieldVisible(pageName, T);
        pgS.isFieldVisible(pageName, T, qtLines.get(0));
    }

}