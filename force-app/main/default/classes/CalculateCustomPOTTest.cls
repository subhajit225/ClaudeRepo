@isTest
global class CalculateCustomPOTTest {
    testMethod static void getPBEDetails(){
        List<Product2> lstProduct = new List<Product2>();
        Test.startTest();
        Map<String, Object> prdMap1 = new Map<String, Object> {
            'Name' => 'Standalone',
                'IsActive' => true,
                'SBQQ__AssetConversion__c' => 'One per unit'
                };
        Map<String, Object> prdMap = new Map<String, Object> {
                        'Name' => 'Subscription', 
                            'IsActive' => true, 
                            'SBQQ__SubscriptionPricing__c' => 'Fixed Price', 
                            'SBQQ__SubscriptionTerm__c' => 12, 
                            'SBQQ__SubscriptionType__c' => 'Renewable'
                            };
                                    
        Product2 prdHW = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap);
        Product2 prdSA = (Product2) ShGl_TestFactory.createSObject(new Product2(), prdMap1);
        SBQQ__ProductOption__c objPO = new SBQQ__ProductOption__c();
        objPO.SBQQ__ConfiguredSKU__c = prdHW.Id;
        objPO.SBQQ__OptionalSKU__c = prdSA.Id;
        objPO.SBQQ__Number__c = 10;
        insert objPO;
        List<String> lstString = new List<String>();
        lstString.add(String.valueOf(objPO));
        lstProduct.add(prdHW);
        CalculateCustomPOT.calculateCustomPOT(lstString);
        Test.stopTest();
    }
}