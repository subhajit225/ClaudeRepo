/********************************************************************************************************
* Name              : CloudOn_OrderProductNamesTest 
* Purpose           : CloudOn_OrderProductNamesTest is Used for Testing CloudOn_OrderProductNames Class
*********************************************************************************************************/
@isTest(SeeAllData=false)
public class CloudOn_OrderProductNamesTest {
     public static testMethod void CloudonTest() {
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
        
        Product2 newProd = new Product2(Name = 'Test CLON', family = 'CLON', ProductCode='OPTY-SPLIT');
        insert newProd;
        
        PriceBookEntry pbEntry = new PriceBookEntry(
            UnitPrice = 300,
            PriceBook2Id = standardPBId,
            Product2Id = newProd.Id,
            IsActive = true,
            UseStandardPrice=false);
        insert pbEntry ;
        
        OrderItem ordrItem = new OrderItem(

            OrderId = ord.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            Product2Id = newProd.Id,
            UnitPrice = pbEntry.UnitPrice,
            SerialNumber__c = 'Test1234567Asset2',
            Support_End_Date__c = System.Today().addYears(1),
            Support_Start_Date__c = System.Today()
        );
        
        insert ordrItem;
        
        Test.startTest();
        CloudOn_OrderProductNames cls = new CloudOn_OrderProductNames();
        cls.setordid(ord.id);
        cls.getordid();
        cls.CloudOn_OrderProductNames();
        Test.stopTest();
     }
}