@isTest
private class ProcessUnApprovedSEMisalignmentsTest {
    
    @isTest static void test_method_one() {
        ShGl_TestFactoryHelper.insertCustomSettings();
        
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        insert act;
        
        Pricebook2 pbk1 = new Pricebook2(Name = 'Test Pricebook Entry 1', Description = 'Test Pricebook Entry 1', isActive = true);
        insert pbk1;
        
        Product2 prd1 = new Product2(Name = 'Test Product Entry 1', Description = 'Test Product Entry 1', productCode = 'OPTY-SPLIT', isActive = true);
        insert prd1;
        
        PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = prd1.Id, UnitPrice = 40, IsActive = true, UseStandardPrice = false);
        insert standardPrice;
        
        Id standardPBId = test.getStandardPricebookId();
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = standardPBId,
            Product2Id = prd1.Id,
            IsActive = true,
            UseStandardPrice = false);
        
        
        //Generate the Contact
        Map < String, Object > cntMap = new Map < String, Object > {
            'AccountId' => act.Id,
                'Email' => 'leademail@hidden.com'
                };
                    Contact cnt1 = (Contact) ShGl_TestFactory.createSObject(new Contact(), cntMap);
        insert cnt1;
        
        //Generate the Opportunity
        Map < String, Object > oppMap = new Map < String, Object > {
            'AccountId' => act.Id,
                'Initial_Contacts_Name__c' => cnt1.Id,
                'StageName' => '1 Discovery'
                };
                    
        List < Opportunity > opptyList = (List < Opportunity > ) ShGl_TestFactory.createSObjectList(new Opportunity(), 3, oppMap);
        opptyList[0].Lead_Email_Hidden__c = 'leademail@hidden.com';
        opptyList[0].Converted_From_Lead__c = true;
        opptyList[0].Pricebook2Id = Test.getStandardPricebookId();
        opptyList[0].Primary_Competitor__c = 'Other';
        opptyList[0].ForecastCategoryName = 'Best Case';
        opptyList[0].Other_Competitor_Field__c = 'Testing';
        insert opptyList;

        ApexPages.StandardController sc = new ApexPages.StandardController(opptyList[0]);
        RequestSEMisalignmentController controllerObj = new RequestSEMisalignmentController(sc);
        PageReference pageRef = Page.RequestSEMisalignment;
        pageRef.getParameters().put('id', String.valueOf(opptyList[0].Id));
        Test.setCurrentPage(pageRef);

        opptyList[0].SE_Misalignment_User__c = UserInfo.getUserId();
        PageReference successPageRef = controllerObj.save();

        Test.startTest();
        String sch = '0 0 23 * * ?';
        System.schedule('test process', sch, new ProcessUnApprovedSEMisalignments());
        Test.stopTest();
    }
}