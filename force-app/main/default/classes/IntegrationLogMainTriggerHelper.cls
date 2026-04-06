public class IntegrationLogMainTriggerHelper {
    
    public static void updateFieldsOnInsert (List<Error_Logs__c> eliList) {

    Map<Id, Order> ordersToUpdateForGTC = new Map<Id, Order>();
    Map<Id, Order> ordersToUpdateForSync = new Map<Id, Order>();
    list<order> orderWithIntegrationLogs = new list<order>();
    Map<id,List<Error_Logs__c>> mapOrderIdWithFailedErrorLogs = new Map<id,List<Error_Logs__c>>();
    list<id> listOrderId = new list<id>();
        for(Error_Logs__c error : eliList) {
            if(error.Related_Order__c != null){
                listOrderId.add(error.Related_Order__c);
            }
        }    
        if(!listOrderId.isEmpty()){
            orderWithIntegrationLogs = [select id, Sync_To_NetSuite__c, (select id,Type__c,Error_Type__c,Success__c,Error_Message__c from Error_Log__r ) from order where id IN: listOrderId]; 
            for(order ord :orderWithIntegrationLogs){
                for(Error_Logs__c el: ord.Error_Log__r ){
                    if(el.Error_Type__c == 'Order Fulfillment' && el.Type__c == 'Integration' && el.Error_Message__c !=null && el.Error_Message__c.containsIgnoreCase('unable to obtain exclusive access') && !el.Success__c && ord.Sync_To_NetSuite__c ){
                        if(!mapOrderIdWithFailedErrorLogs.containsKey(ord.id))
                            mapOrderIdWithFailedErrorLogs.put(ord.id, new List<Error_Logs__c>());
                        
                        mapOrderIdWithFailedErrorLogs.get(ord.id).add(el);
                    }
                }
                
            }
        }
    for(Error_Logs__c error : eliList) {
        if(error.Error_Type__c == 'Restricted Party Screening' && error.Type__c == 'Integration' && !error.Success__c && error.Related_Order__c != null){
            ordersToUpdateForGTC.put(error.Related_Order__c, new Order(Id=error.Related_Order__c, ScreenStatus__c = 'Internal Error'));
        }
        
// unable to obtain exclusive access
        if(error.Error_Type__c == 'Order Fulfillment' && error.Type__c == 'Integration' && !error.Success__c && error.Related_Order__c != null){
            if((mapOrderIdWithFailedErrorLogs.get(error.Related_Order__c) != null && mapOrderIdWithFailedErrorLogs.get(error.Related_Order__c).size() > integer.valueof(Label.Integration_Failure_Limit)) || error.Error_Message__c == null || !error.Error_Message__c.containsIgnoreCase('unable to obtain exclusive access'))
            	ordersToUpdateForSync.put(error.Related_Order__c, new Order(Id=error.Related_Order__c, Sync_To_NetSuite__c = false));
        }
    }

    if(ordersToUpdateForGTC.size()>0){
        TriggerControl.stopOrderTrigger = true;
        update ordersToUpdateForGTC.values();
        TriggerControl.stopOrderTrigger = false;
    }

    if(ordersToUpdateForSync.size()>0){
        TriggerControl.stopOrderTrigger = true;
        update ordersToUpdateForSync.values();
        TriggerControl.stopOrderTrigger = false;
    }
    //Commented By Gaurav Jain - Redundant Code, no longer in use. Added overhead for system, Already Handled by Jitterbit with V2.0 Integration. Originally was used during V1.0 Integration
    //     Set<Error_Logs__c> errorLogIds = new Set<Error_Logs__c> ();
    //     Set<Id> onSuccessupdateOrderList = new Set<Id> ();
    //     Set<Id> onErrorupdateOrderList = new Set<Id> ();
    //     Set<Id> onSuccessUpdateAccountList = new Set<Id> ();
    //     Set<Id> onErrorupdateAccountList = new Set<Id> ();

    //     Map<Id, Account> updateAccountMap = new Map<Id, Account> ();
    //     //List<Account> updateAccountList = new List<Account> ();

    //     Map<Id, Order> updateOrderMap = new Map<Id, Order> ();
    //     //List<Order> updateOrderList = new List<Order> ();
        
    //     for(Error_Logs__c error : eliList) {
            
    //         // skip sfdc error logs
    //         if(error.Type__c == 'SFDC') 
    //             continue;
            
    //         // NS integration log
    //         if (error.Error_Type__c!= null && error.Related_Order__c != null && error.Success__c == true && error.Error_Type__c.equalsIgnoreCase('Restricted Party Screening')== false) {
    //             onSuccessUpdateOrderList.add(error.Related_Order__c);
    //         } else if (error.Related_Order__c != null && error.Success__c == false) {
    //             onErrorupdateOrderList.add(error.Related_Order__c);
    //         } else if (error.Account__c != null && error.Related_Order__c == null && error.Success__c == true) {
    //             onSuccessUpdateAccountList.add(error.Account__c);
    //         } else if (error.Account__c != null && error.Related_Order__c == null && error.Success__c == false) {
    //             onErrorupdateAccountList.add(error.Account__c);
    //         }
    //     }
        
    //     if(onSuccessUpdateAccountList.size() > 0){
    //         for(Account acc : [SELECT Id, Name, Update_Netsuite__c, Integration_failure__c FROM Account WHERE Id IN: onSuccessUpdateAccountList]) {
    //             acc.Update_Netsuite__c = false;
    //             acc.Integration_failure__c = false;
    //             acc.Sync_To_NetSuite__c = false;
    //             updateAccountMap.put(acc.Id, acc);
    //         }
    //     }
        
    //     if(onErrorupdateAccountList.size() > 0) {
            
    //         for(Account acc : [SELECT Id, Name, Update_Netsuite__c, Integration_failure__c FROM Account WHERE Id IN: onErrorupdateAccountList]) {
    //             acc.Update_Netsuite__c = true;
    //             acc.Integration_failure__c = true;
    //             acc.Sync_To_NetSuite__c = true;
    //             updateAccountMap.put(acc.Id, acc);
    //         }
    //     }
        
    //     if(onSuccessUpdateOrderList.size() > 0) {
    //         for(Order ordr : [SELECT Id, Name, Update_Netsuite__c, Integration_failure__c FROM Order WHERE Id IN: onSuccessUpdateOrderList]) {
    //             ordr.Update_Netsuite__c = false;
    //             ordr.Integration_failure__c = false;
    //             ordr.Sync_To_NetSuite__c = false;
    //             updateOrderMap.put(ordr.id, ordr);
    //         }
    //     }
        
    //     if(onErrorUpdateOrderList.size() > 0) {
    //         for(Order ordr : [SELECT Id, Name, Update_Netsuite__c, Integration_failure__c FROM Order WHERE Id IN: onErrorUpdateOrderList]) {
    //             ordr.Update_Netsuite__c = true;
    //             ordr.Integration_failure__c = true;
    //             ordr.Sync_To_NetSuite__c = true;
    //             updateOrderMap.put(ordr.Id, ordr);
    //         }
    //     }
        
    //     system.debug('Value updateOrderMap--'+updateOrderMap);
    //     system.debug('Value updateAccountMap--'+updateAccountMap);
        
    //     //updateOrderList.addAll(updateOrderSet);
    //     //updateAccountList.addAll(updateAccountSet);
        
    //     //Remove Duplicates
    //     //Set<Account> updateAccSet = new Set<Account> (updateAccountList);
    //     //Set<Order> updateOrdSet = new Set<Order> (updateOrderList);
    //     //updateOrderList.clear();
    //     //updateAccountList.clear();
    //     //updateAccountList.addAll(updateAccSet);
    //     //updateOrderList.addAll(updateOrdSet);
        
    //     if(updateOrderMap.size() > 0)
    //         update updateOrderMap.values();
    //     if(updateAccountMap.size() > 0)
    //         update updateAccountMap.values();
        
    }
    
    
}