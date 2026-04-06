/********************************************************************************************************
* Name              : Opportunity_Service_Test
* Purpose           : Opportunity_Service_Test is Used for Testing Opportunity_Service Class
*********************************************************************************************************/
@isTest
public class Opportunity_Service_Test{
    static testMethod void testBlank() {
        System.assert(Opportunity_Service.run);
    }
/*
    static testMethod void testInsertNewOrder() {
        testDataFactoryClass.createCustomSettings();
        id rId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), new Map<String, Object> { 'recordTypeId'=>rId, 'Type'=>'Distributor'});
        insert act;
        
        Id standardPBId = test.getStandardPricebookId();
        Opportunity opp = TestDataFactory.getOpportunity(act);
        opp.Pricebook2Id =standardPBId;
        opp.Distributor_Lookup__c =act.id;
        insert opp;
        List<Opportunity> oppList = new List<Opportunity>{opp};
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        
        OpportunityLineItem oppLine = new OpportunityLineItem(pricebookentryid=pbEntry.id,TotalPrice=2000,Quantity = 2,OpportunityID = oppList[0].Id);
        insert oppLine;
        
        Test.startTest();
        Opportunity_Service.insertNewOrder(oppList);
        Test.stopTest();
    }
    
    static testMethod void testUpdatetExistingOrder(){
        testDataFactoryClass.createCustomSettings();
        
        List<Account> actList = new List<Account>();
        
        Account act =new Account(Name = 'TestAcct1',Website='www.test3.com',type='Customer');
        insert act;
        
        actList.add(act);
        
        List<opportunity> oppList =  testDataFactoryClass.createOpporunity(actList);
        Id pricebookId = Test.getStandardPricebookId();
        oppList[0].pricebook2Id = pricebookId;
        update oppList;
        
        Product2 prod = new Product2(
            Name='RBK-SVC-PREM-R344',ProductCode='RBK-SVC-PREM-R344',Family='RBK-R300',
            isActive = true
        );
        insert prod;
        
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = oppList[0].pricebook2Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = oppList[0].Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert oli;
        
        OpportunityLineItem oliWithDiscount = new OpportunityLineItem(
            OpportunityId = oppList[0].Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            Discount = 1,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert oliWithDiscount;
        
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => actList[0].Id,
            'OpportunityId' => oppList[0].Id,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending'
        };
        
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        insert Ord;
        
        OrderItem ordrItem = new OrderItem(
            OrderId = Ord.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = pbEntry.UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        insert ordrItem;

        List<Order> orderList = new List<Order>();
        orderList.add(Ord);
        
        Test.startTest();
        Opportunity_Service.updatetExistingOrder(orderList);
        Test.stopTest();
    }
    
    public static testMethod void testIncreaseHoldoverCount(){
        User usr = (User) ShGl_TestFactory.createSObject(new User(), null);
        insert usr;

        List<Id> userIdList = new List<Id>();
        userIdList.add(usr.id); 
        
        Test.startTest();
        Opportunity_Service.increaseHoldoverCount(userIdList);
        Test.stopTest();
    }
    
    public static testMethod void testDecreaseHoldoverCount(){
        User user1 = (User) ShGl_TestFactory.createSObject(new User(), null);
        insert user1;
        
        User user2 = (User) ShGl_TestFactory.createSObject(new User(), null);
        user2.Holdover_Count__c =1;
        insert user2;

        List<Id> userIdList = new List<Id>();
        userIdList.add(user1.id); 
        userIdList.add(user2.id); 
        
        Test.startTest();
        Opportunity_Service.decreaseHoldoverCount (userIdList);
        Test.stopTest();
    }
*/
}