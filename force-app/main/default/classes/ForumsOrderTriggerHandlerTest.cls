/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   Test class for ForumsOrderTriggerHandler.
*/
@isTest(seeAllData=false)
public class ForumsOrderTriggerHandlerTest {
    @testSetup 
    public static void dataSetup() {
        Catalog__c item = new Catalog__c();
        item.Amount__c = 100;
        item.Description__c = 'Some catalog item';
        item.Name__c = 'Airpods';
        item.Active__c = true;
        insert item;

        CS_Order__c order = new CS_Order__c();
        order.User__c = UserInfo.getUserId();
        order.Catalog_Item__c = item.Id;
        order.Quantity__c = 1;
        order.Amount__c = 100;
        order.Submitted_Date__c = System.today();
        order.Status__c = 'New';
        order.Phone_Number__c = '123456674';
        order.Coins_After_Transaction__c = 180;
        order.Coins_Before_Transaction__c = 280;
        insert order;
    }

    @isTest static void testOrderCreation() {
        Catalog__c item = [SELECT Id FROM Catalog__c LIMIT 1];

        CS_Order__c order = new CS_Order__c();
        order.User__c = UserInfo.getUserId();
        order.Catalog_Item__c = item.Id;
        order.Quantity__c = 1;
        order.Amount__c = 100;
        order.Submitted_Date__c = System.today();
        order.Status__c = 'New';
        order.Phone_Number__c = '123456674';
        order.Coins_After_Transaction__c = 80;
        order.Coins_Before_Transaction__c = 180;
        insert order;
    }

    @isTest static void testSetStatusChangeDates() {
        CS_Order__c order = [SELECT Id, Status__c FROM CS_Order__c LIMIT 1];
        order.Status__c = 'Placed';
        order.Estimated_Delivery_Date__c = System.today() + 10;
        update order;

        order.Status__c = 'Shipped';
        update order;

        order.Status__c = 'Delivered';
        update order;

        order.Status__c = 'Cancelled';
        update order;
    }
}