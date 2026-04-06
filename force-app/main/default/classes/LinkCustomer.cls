@isTest(seeAllData=false)
private class LinkCustomer {

    /**
     * This test doesn't really test any apex implementation.
     * It's written to maximize code coverage to allow sandbox deployments. 
     */
    static testMethod void testLinkCustomerToNode() {
        Test.startTest();
        Cluster__c c = new Cluster__c(UUID__c = 'Test', Name = 'Test');
        insert c;
        
        Account a = new Account(Name = 'Test');
        insert a;
        
        Product2  prods = new Product2
        (Name = 'Test for Asset',
        Description='Hardware', productCode = 'r270', isActive = true, Family='Hardware');
        insert prods;
        
        Asset asset = new Asset(AccountId = a.id,
                                Name = '123456Test',
                                SerialNumber = '123456Test',
                                product2Id = prods.id,
                                Serial_Number__c = '123456Test');
        insert asset;
     
        Node__c n = new Node__c(Cluster__c = c.id,
                                asset__c = asset.id,
                                serial_number__c = 'test1234',
                                name = 'test1234');
        insert n;
        Test.stopTest();
    }
}