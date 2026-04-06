@isTest
private class BatchUpdateOrderProductTest {
    @testSetup
    static void setup(){
        
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
        
        Product2 p = new Product2();
        p.Name = 'RBK-PS-CNSLT-ONST';
        p.Description='Test Product Entry 1';
        p.productCode = 'ABC';
        p.isActive = true;
        insert p;
        Product2 p1 = new Product2();
        p1.Name = 'RBK-PS-INST';
        p1.Description='Test Product Entry 1';
        p1.productCode = 'ABC';
        p1.isActive = true;
        insert p1;
        
        Id pricebookId = Test.getStandardPricebookId();
    
        PricebookEntry standardPrice = new PricebookEntry();
        standardPrice.Pricebook2Id = pricebookId;
        standardPrice.Product2Id = p.Id;
        standardPrice.UnitPrice = 1;
        standardPrice.IsActive = true;
        standardPrice.UseStandardPrice = false;
        insert standardPrice ;
        
        Order o = new Order();
        o.Name = 'Test Order ';
        o.Status = 'Draft';
        o.EffectiveDate = system.today();
        //o.EndDate = system.today() + 4;
        o.AccountId = a.id;
        o.Pricebook2Id =  pricebookId ;
        insert o;
        
        OrderItem i = new OrderItem();
        i.OrderId = o.id;
        i.Quantity = 2;
        i.UnitPrice = 240;
        i.ServiceDate = system.today();
            //i.Pieces__c = i.Quantity;
        i.Product2id = p.id;
        i.PricebookEntryId=standardPrice.id;
        insert i;
        OrderItem i2 = new OrderItem();
        i2.OrderId = o.id;
        i2.Quantity = 24;
        i2.UnitPrice = 240;
        i2.ServiceDate = system.today();
        i2.Product2id = p1.id;
        i2.PricebookEntryId=standardPrice.id;
        insert i2;
        o.Status = 'Shipped';
        o.Actual_Order_Ship_Date__c = System.today();
        update o;
    }
    static testmethod void test() {        
        Test.startTest();
        BatchUpdateOrderProduct buop = new BatchUpdateOrderProduct();
        Id batchId = Database.executeBatch(buop);
        Test.stopTest();
     }
    static testmethod void test1() {        
        Test.startTest();
        BatchUpdateOrderProduct buop = new BatchUpdateOrderProduct();
        String sch = '0 0 2 * * ?'; 
		system.schedule('Test Territory Check', sch, buop); 
        Test.stopTest();
     }

}