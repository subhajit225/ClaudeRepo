/********************************************************************************************************
* Name              : OrderLineEntry_Test 
* Purpose           : OrderLineEntry_Test is Used for Testing OrderLineEntry Class
*********************************************************************************************************/
@isTest
public class OrderLineEntry_Test {
    
    static testMethod void testInitWrapper() {
		FlowControll.AccountTrigger = false;
        FlowControll.opportunityTriggerHandler = false;
        testDataFactoryClass.createCustomSettings();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        Account act = (Account) ShGl_TestFactory.createSObject(new Account(), null);
        act.RecordTypeId = partnerRecordTypeId;
        insert act;
        Map<String, Object>  oppMap = new Map<String, Object> {
            'AccountId' => act.Id,
            'CloseDate' => System.Today()+30,
            'Partner_Lookup__c' => act.id,
            'Alliance_Partner_Name__c' =>'Amazon',
            'Alliance_Source_Type__c' => 'Alliance Initiated Deal'
        };
        
        Id standardPBId = test.getStandardPricebookId();
        Opportunity opp1 = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert opp1;

        opp1.Pricebook2Id =standardPBId;
        update opp1;
        
        Map<String, Object>  OrderMap = new Map<String, Object> {
            'Type' => 'Revenue',
            'AccountId' => act.Id,
            'OpportunityId' => opp1.Id,
            'EffectiveDate' => system.today(),
            'Status' => 'Pending'
        };
        Order ord = (Order) ShGl_TestFactory.createSObject(new Order(), OrderMap);
        insert Ord; 
        
        Product2 newProd = new Product2(Name = 'test product', family = 'test family', ProductCode='OPTY-SPLIT');
        insert newProd;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        
        OpportunityLineItem oppLine1 = new OpportunityLineItem(pricebookentryid=pbEntry.id,TotalPrice=2000,Quantity = 2,OpportunityID = opp1.Id);
        insert oppLine1;
        
        OpportunityLineItem oppLine2 = new OpportunityLineItem(pricebookentryid=pbEntry.id,TotalPrice=2000,Quantity = 2,OpportunityID = opp1.Id,Discount=1);
        insert oppLine2;
        
        OrderItem ordrItem = new OrderItem(

            OrderId = ord.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            UnitPrice = pbEntry.UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        
        insert ordrItem;
        
        PageReference pageRef = Page.AddOrderLineItems; // Adding VF page Name here
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('oppid', opp1.id);//for page reference 
        
        Apexpages.StandardController sc = new Apexpages.standardController(Ord);
        OrderLineEntry lineEntry  = new OrderLineEntry(sc);
        Test.startTest();
        lineEntry.initWrapper();
        lineEntry.saveRecord();
        lineEntry.reset();
        List<OrderItem> ordrItemList = lineEntry.deletedOrderItems;
        Set<Id> idSet = lineEntry.productSet;
        Boolean value= lineEntry.lines;
        
        OrderLineEntry.wrapLines lines2 = new OrderLineEntry.wrapLines(newProd.id,10,'Test Name',true,pbEntry.id,10,oppLine2.id,10,10);
        Product2  prd =lines2.oli;
        String lnId =lines2.lineID;
        Test.stopTest();
    }
    
    
}