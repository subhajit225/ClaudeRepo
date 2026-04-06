/**
 * @description Test class for OrderRmaEmailTempBuilder
 * @created 2025-09-16
 */
@IsTest
private class OrderRmaEmailTempBuilderTest {
    
    @TestSetup
    static void setupTestData() {
        Account objAcc = new Account(Name = 'testAcc');
        insert objAcc;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        Order testOrder = new Order( AccountId = objAcc.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = stdPricebookId );
        insert testOrder;
        
        Product2 testProduct = new Product2(Name = 'Test RMA Product', IsActive = true);
        insert testProduct;
        
        PricebookEntry testPbe = new PricebookEntry( Product2Id = testProduct.Id, Pricebook2Id = stdPricebookId, UnitPrice = 100.00, IsActive = true );
        insert testPbe;
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true limit 1];
        system.runas(u)
        {
            List<OrderItem> testOrderItems = new List<OrderItem>{
                new OrderItem(
                    OrderId = testOrder.Id,
                    Product2Id = testProduct.Id,
                    PricebookEntryId = testPbe.Id,
                    Quantity = 1,
                    UnitPrice = 100.00,
                    RMA_Component_Type__c = 'Node',
                    Failed_Serial_Number__c = 'FAILED123',
                    SerialNumber__c = 'REPLACE456',
                    Assets__c = 'ASSET789'
                ),
                new OrderItem(
                    OrderId = testOrder.Id,
                    Product2Id = testProduct.Id,
                    PricebookEntryId = testPbe.Id,
                    Quantity = 1,
                    UnitPrice = 50.00,
                    RMA_Component_Type__c = 'CMOS Battery',
                    Failed_Serial_Number__c = null,
                    SerialNumber__c = null,
                    Assets__c = null
                )
            };
            insert testOrderItems;
        }
    }

    @IsTest
    static void testBuildRmaTableSuccess() {
        List<OrderItem> testOrderItems = [SELECT Id, RMA_Component_Type__c, Failed_Serial_Number__c, 
                                         SerialNumber__c, Assets__c FROM OrderItem];
                                         
        OrderRmaEmailTempBuilder.Request request = new OrderRmaEmailTempBuilder.Request();
        request.orderItems = testOrderItems;
        
        List<OrderRmaEmailTempBuilder.Request> requests = new List<OrderRmaEmailTempBuilder.Request>{request};
        
        User u = [select id,name from user where profile.name ='System Administrator' and isactive=true limit 1];
        system.runas(u)
        {
            Test.startTest();
            List<OrderRmaEmailTempBuilder.Response> responses = OrderRmaEmailTempBuilder.buildRmaTable(requests);
            Test.stopTest();
            System.assertEquals(1, responses.size(), 'Should return one response');
            System.assertNotEquals(null, responses[0].htmlTable, 'HTML table should not be null');
        }
    }
}