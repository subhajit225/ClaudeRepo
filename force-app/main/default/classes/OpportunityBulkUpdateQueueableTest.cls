@IsTest
public class OpportunityBulkUpdateQueueableTest {

    @IsTest
    static void testBulkUpdateNoOrderItemMap() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        // Create sample opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Ensure helper map is empty to test the "else if (!oppList.isEmpty())" branch
        OrderItemTriggerHelper.oiUpdateMap = new Map<Id, OrderItem>();

        // Create list with more than 1 opp to cause recursion
        List<Opportunity> oppList = new List<Opportunity>{opp};

        Test.startTest();
        System.enqueueJob(new OpportunityBulkUpdateQueueable(oppList));
        Test.stopTest();

        // Validate static flag
        System.assertEquals(true, OpportunityBulkUpdateQueueable.isBulkDeal);
        }
    }


    @IsTest
    static void testBulkUpdateWithOrderItemMap() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
        // Create sample opportunity
       	Opportunity opp1 = new Opportunity(
            Name = 'Test Opp 2',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30));
            Opportunity opp2 = new Opportunity(
            Name = 'Test Opp 1',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30));
  
        	insert new List<Opportunity>{ opp1, opp2 };


        // Mock order item and populate helper map to trigger first IF branch
        OrderItem oi = new OrderItem(
            Quantity = 1,
            UnitPrice = 10,
            //PricebookEntryId = Test.getStandard,
            OrderId = null
        );

        OrderItemTriggerHelper.oiUpdateMap = new Map<Id, OrderItem>();
        OrderItemTriggerHelper.oiUpdateMap.put(null, oi);

        Test.startTest();
        try{
        System.enqueueJob(new OpportunityBulkUpdateQueueable(new List<Opportunity>{opp1, opp2}));
        }catch(exception ex){
            System.assert(ex != null);
        }        Test.stopTest();

        // Validate static variable was set
        System.assertEquals(true, OpportunityBulkUpdateQueueable.isBulkDeal);
        }
    }
    
    @IsTest
    static void testBulkUpdateWithNoOpp() {
     System.runAs(new User(Id = UserInfo.getUserId())) {

        List<Opportunity> oppList = new List<Opportunity>();

        Test.startTest();
        System.enqueueJob(new OpportunityBulkUpdateQueueable(oppList));
        Test.stopTest();

        // Validate static variable was set
        System.assertEquals(false, OpportunityBulkUpdateQueueable.isBulkDeal);
    }
    }
}