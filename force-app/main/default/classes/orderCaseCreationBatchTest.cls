@isTest
public class orderCaseCreationBatchTest {
    @testSetup
    static void dataSetup() {
        Account acc = new Account(Name='Test');
        insert acc;
        
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        standardPricebook = [SELECT IsStandard FROM Pricebook2 WHERE Id = :standardPricebook.Id];
        Product2 p = new Product2(Name='RBK-SVC-CMPLT-RMOT', IsActive = true);
        insert p;
        PricebookEntry pbe = new PricebookEntry(UnitPrice=10.0, Product2Id=p.Id, Pricebook2Id=standardPricebook.Id, IsActive=true);
        insert pbe;
        
        //new order entry
        Order ord = new Order(
            Name='Test Order',
            AccountId=acc.Id,
            EffectiveDate=System.today().addDays(-3),
            Status='Draft',
            Type = 'Revenue',
            Pricebook2Id = standardPricebook.Id
        );
        insert ord;
        
        //creating order item
        OrderItem oi = new OrderItem(
            Product2Id=p.Id,
            Quantity=1.0,
            OrderId=ord.Id,
            UnitPrice=10.0,
            PricebookEntryId = pbe.id
        );
        insert oi;
        
        //update order status
        ord.Order_Status__c = 'Shipped';
        ord.Status='Activated';
        update ord;
    }
    
    static testmethod void test(){
        Test.startTest();
        Database.executeBatch(new orderCaseCreationBatch());	
        Test.stopTest();
    }
    
}