/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   08-08-2022
* @Jira Ticket  :   CS21-1100 - Forums 2.0 Rewards Redemption/Swag Store
* @Description  :   This class is the trigger handler for ForumsOrderTrigger.
* @TestClass    :   ForumsOrderTriggerHandlerTest
*/
public without sharing class ForumsOrderTriggerHandler {

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   08-08-2022
    * @Description  :   Perform updates when order status is changed
    */
    public static void setStatusChangeDates(List<CS_Order__c> newOrderList, Map<Id, CS_Order__c> oldOrderMap){
        List<CS_Order__c> cancelledOrderList = new List<CS_Order__c>();
        for(CS_Order__c order : newOrderList){
            if(order.Status__c.equalsIgnoreCase('Placed') && (oldOrderMap == null || oldOrderMap.get(order.Id).Status__c != order.Status__c)){
                order.Placed_Date__c = System.now();
            }
            else if(order.Status__c.equalsIgnoreCase('Shipped') && (oldOrderMap == null || oldOrderMap.get(order.Id).Status__c != order.Status__c)){
                order.Shipped_Date__c = System.now();
            }
            else if(order.Status__c.equalsIgnoreCase('Delivered') && (oldOrderMap == null || oldOrderMap.get(order.Id).Status__c != order.Status__c)){
                order.Delivered_Date__c = System.now();
            }
            else if(order.Status__c.equalsIgnoreCase('Cancelled') && (oldOrderMap == null || oldOrderMap.get(order.Id).Status__c != order.Status__c)){
                order.Cancellation_Date__c = System.now();
                cancelledOrderList.add(order);
            }
        }

        //Give coins back to the user if the support order is cancelled
        if(!cancelledOrderList.isEmpty()){
            updateCoinsOnUserForCancellation(cancelledOrderList);
        }
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   08-08-2022
    * @Description  :   Update coins on the user record when an order is placed
    */
    public static void updateCoinsOnUser(List<CS_Order__c> newOrderList){
        List<User> userList = new List<User>();
        for(CS_Order__c order : newOrderList){
            User userRecord = new User();
            userRecord.Id = order.User__c;
            userRecord.Coins__c = order.Coins_After_Transaction__c;
            userList.add(userRecord);
        }

        Database.update(userList, false);
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   08-08-2022
    * @Description  :   Update coins on the user record when an order is cancelled
    */
    private static void updateCoinsOnUserForCancellation(List<CS_Order__c> newOrderList){
        List<User> userList = new List<User>();
        for(CS_Order__c order : newOrderList){
            User userRecord = new User();
            userRecord.Id = order.User__c;
            userRecord.Coins__c = userRecord.Coins__c == null ? order.Amount__c : (userRecord.Coins__c + order.Amount__c);
            userList.add(userRecord);
        }

        Database.update(userList, false);
    }

    /**
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   08-08-2022
    * @Description  :   Create a task record for the user when order status is changed to Placed or Shipped. This task for the user
                        to upload the invoice on the order for auditing purposes.
    */
    public static void createTaskForInvoice(List<CS_Order__c> newOrderList, Map<Id, CS_Order__c> oldOrderMap){
        List<Task> taskList = new List<Task>();
        Task taskRecord;
        for(CS_Order__c order : newOrderList){
            if((order.Status__c.equalsIgnoreCase('Placed') || order.Status__c.equalsIgnoreCase('Shipped'))
             && oldOrderMap.get(order.Id).Status__c.equalsIgnoreCase('New')){
                taskRecord = new Task();
                taskRecord.Subject = 'Upload invoice';
                taskRecord.WhatId = order.Id;
                taskRecord.OwnerId = UserInfo.getUserId();
                taskRecord.Status = 'Not Started';
                taskRecord.Priority = 'Normal';
                taskRecord.Description = 'Upload invoice for order ' + order.Name;
                taskRecord.ActivityDate = Date.newinstance(order.Estimated_Delivery_Date__c.year(), order.Estimated_Delivery_Date__c.month(), order.Estimated_Delivery_Date__c.day());
                taskList.add(taskRecord);
            }
        }

        Database.insert(taskList, false);
    }
}