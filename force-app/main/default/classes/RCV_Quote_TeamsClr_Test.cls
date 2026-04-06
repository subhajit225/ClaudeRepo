@isTest
public class RCV_Quote_TeamsClr_Test {

    testMethod static void testMethod_1() {

        Opportunity oppty = TestDataFactory.getOpportunity();
        insert oppty;
        Test.startTest();
        
        SBQQ__Quote__c qt = new SBQQ__Quote__c();
        qt.SBQQ__Account__c = oppty.AccountId;
        qt.SBQQ__Opportunity2__c = oppty.Id;
        insert qt; 
        list<Product2> prodlist = new list<Product2>();
        Map<String, Object>  prodMap = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ-CVA',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'Appliance'
                };
        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
        prodlist.add(pd);
        insert prodlist;

        list<Product2> prodlist2 = new list<Product2>();
        Map<String, Object>  prodMap2 = new Map<String, Object> {
            'Name' => 'Pord A',
                'ProductCode' => 'ProductXYZ-CVB',
                'isActive' => true,
                'Family' => 'AIR',
                'Product_Type__c' => 'Appliance'
                };
        Product2 pd2 = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap2);  
        prodlist2.add(pd2);
        insert prodlist2;

        
        List<SBQQ__QuoteLine__c>lines = new List<SBQQ__QuoteLine__c>();
        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prodlist[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Storage_Region_Bundle__c = 'Standard - Zone 1'));

        lines.add(new SBQQ__QuoteLine__c(SBQQ__Quote__c = qt.Id, SBQQ__Product__c = prodlist2[0].Id, SBQQ__Quantity__c = 1, SBQQ__SubscriptionPricing__c = null, SBQQ__StartDate__c = System.today(), SBQQ__EndDate__c = System.today().addMonths(12).addDays(-1), SBQQ__DefaultSubscriptionTerm__c = null, SBQQ__ListPrice__c = 200, SBQQ__NetPrice__c = 200,Storage_Region_Bundle__c = 'Standard - Zone 2'));


        insert lines;
        
        
        
        RCV_Quote_Verbiage_Exception_Override__c cs = new RCV_Quote_Verbiage_Exception_Override__c();
        cs.Name=qt.Name+'';
        cs.Override_CVA_Standard_Zone_1_Verbiage__c=true;
        cs.Override_CVA_Standard_Zone_2_Verbiage__c=true;
        cs.Override_CVB_Standard_Zone_1_Verbiage__c=true;
        cs.Override_CVB_Standard_Zone_2_Verbiage__c=true;
        cs.Overridden_CVA_Standard_Zone_1_Verbiage__c='test';
        cs.Overridden_CVA_Standard_Zone_2_Verbiage__c='test';
        cs.Overridden_CVB_Standard_Zone_1_Verbiage__c='test';
        cs.Overridden_CVB_Standard_Zone_2_Verbiage__c='test';
        insert cs;
        
        ApexPages.currentPage().getParameters().put('qid', qt.id);
        RCV_Quote_TeamsClr SYP = new RCV_Quote_TeamsClr();
        SYP.init() ;
        Test.stopTest();
    }

}