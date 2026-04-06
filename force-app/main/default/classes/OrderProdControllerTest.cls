@isTest 
private class OrderProdControllerTest {
    static testMethod void OrderProdController() {
        String uniqueUserName = 'SysAdmin' + DateTime.now().getTime() + '@testorg.com';
        system.debug('uniqueUserName'+uniqueUserName);
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User u = new User(Alias = 'standt', Email='Admin@testorg.com',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);
        System.runAs(u) {
            account acct=new account(name='test account',AccountNumber='123456');
            insert acct;
            list<Product2> prodlist = new list<Product2>();
            Map<String, Object>  prodMap = new Map<String, Object> {
                'Name' => 'Pord A',
                    'ProductCode' => 'BookProd',
                    'isActive' => true,
                    'Family' => 'AIR',
                    'Product_Type__c' => 'Appliance'
                    };
                        Product2 pd = (Product2) ShGl_TestFactory.createSObject(new Product2(), prodMap);  
            prodlist.add(pd);
            insert prodlist;
            Order ord = new Order(Status='Draft',Order_Status__c='Pending',AccountId = acct.Id,EffectiveDate = Date.Today(),
                                  RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('POC Order').getRecordTypeId(),Pricebook2Id = Test.getStandardPricebookId());
            insert ord;
            Order_SendEmail.sendemailToFlash(ord.id);
            PricebookEntry pbEntry = new PricebookEntry(
                Pricebook2Id = Test.getStandardPricebookId(),
                Product2Id = prodlist[0].Id,
                UnitPrice = 100.00,
                IsActive = true
            );
            insert pbEntry;
            
            OrderItem oritem = new OrderItem(OrderId=ord.Id, Quantity=10, PricebookEntryId=pbEntry.Id, UnitPrice = 10, Product2Id = prodlist[0].Id, SerialNumber__c = 'AA162403440008,AB162403440009,AC162403440009,AD162403440009');
            insert oritem;
            OrderProdController OP = new OrderProdController();
            List<OrderItem> OIList = OP.getOrdProducts();
        }
    }
}