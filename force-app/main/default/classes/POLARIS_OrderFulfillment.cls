//SAL-135: Polaris order fulfillment
public with sharing class POLARIS_OrderFulfillment {
    
    //Create Polaris Provision task on Order Activation
    public static void createTaskOnOrderActivation (List<Order> ordList, Map<Id, Order> oldOrdMap, Map<Id, Task> accIdTsksMap) {
        if(oldOrdMap == null){
            return;
        }
        
        Id polarisTaskRT = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Polaris Fullfillment').getRecordTypeId();
        system.debug(accIdTsksMap);
        
        try {
            List<Task> tskListToBeInserted = new List<Task> ();
            
            Map<Id, String> ordOIProductTypeMap = new Map<Id, String> ();
            
            Set<Id> orderPolarisSet = new Set<Id> ();
            Set<Id> opptyIdSet = new Set<Id> ();
            
            Set<Id> oldOrdIdSet = oldOrdMap.keySet();
            
            for (Order ord: ordList) {
                Order oldOrd = oldOrdMap.get(ord.Id);
                if ((ord.Type == 'Revenue' && oldOrd.Order_Status__c != ord.Order_Status__c && ord.Order_Status__c == 'Order Accepted')) {
                            
                	opptyIdSet.add(ord.OpportunityId);
                }
                else if(ord.Type == 'POC' && ord.Order_Status__c == 'Pending') {
                    opptyIdSet.add(ord.POC_Opportunity__c);   
                }
            }
            
            // Task creation for account activation 
            if (!opptyIdSet.isEmpty()) {
                
                Map<Id, Order> ordMap = new Map<Id, Order> ([SELECT Id, AccountId, Account.Name, OpportunityId, Opportunity.Polaris_Region__c, Opportunity.StageName, 
                                                             POC_Request__c, POC_Request__r.POC_Duration__c, POC_Request__r.POC_Completion_Date__c, 
                                                             //SBQQ__Quote__r.SBQQ__SubscriptionTerm__c ,
                                                             ( SELECT Id, OrderId, Product2.Family, Product2.Bundle_Features__c, Product2.Product_Type__c, Product_Code_Formula__c, SBQQ__SubscriptionTerm__c FROM OrderItems )
                                                             FROM Order 
                                                             WHERE Id IN :ordList]);
                
                List<Order> ordQList = new List<Order> ([SELECT Id, AccountId, Account.Name, OpportunityId, Opportunity.Polaris_Region__c, Opportunity.StageName, 
                                                             POC_Request__c, POC_Request__r.POC_Duration__c, POC_Request__r.POC_Completion_Date__c, 
                                                             ( SELECT Id, OrderId, Product2.Family, Product2.Bundle_Features__c, Product2.Product_Type__c, Product_Code_Formula__c, SBQQ__SubscriptionTerm__c FROM OrderItems )
                                                             FROM Order 
                                                             WHERE OpportunityId IN :opptyIdSet or POC_Opportunity__c in :opptyIdSet]);
                
                Map<Id, List<Order>> ordQMap = (Map<Id, List<Order>>) ShGl_CommonUtility.convertListToMap(ordQList, 'AccountId');
                
                
                Map<Id, Id> priOppCntRole = new Map<Id, Id> ();
                for (OpportunityContactRole ocr : [SELECT Id, ContactId, Contact.Name, isPrimary, OpportunityId FROM OpportunityContactRole WHERE OpportunityId = :opptyIdSet AND isPrimary = TRUE]) {
                    priOppCntRole.put(ocr.OpportunityId, ocr.ContactId);
                }
                
                for (Order ord : ordList) {
                    Order oldOrd = oldOrdMap.get(ord.Id);
                    Order ordQ = ordMap.get(ord.Id);
                    
                    if(accIdTsksMap.containsKey(ord.Id)) {
                        continue;
                    }
                    
                    Set<String> polarisPrdCodeSet = new Set<String> ();     
                    //Integer subsTerm = 0;
                    for (OrderItem oItem : ordQ.OrderItems) {
                        String bundleFeature = oItem.Product2.Bundle_Features__c;
                        if (oItem.Product2.Family == 'POLARIS' || ( String.isNotBlank(bundleFeature) && bundleFeature.contains('Polaris') )) {
                            orderPolarisSet.add(oItem.orderId);
                            //subsTerm = oItem.SBQQ__SubscriptionTerm__c;
                            ordOIProductTypeMap.put(oItem.orderid, oItem.Product2.Product_Type__c);
                            polarisPrdCodeSet.add(oItem.Product_Code_Formula__c);
                        }
                    }
                    if(ordQMap.containsKey(ord.AccountId) && ordQMap.get(ord.AccountId).size() > 1) {
                        for(Order tmpOrd : ordQMap.get(ord.AccountId)) {
                            for (OrderItem oItem : tmpOrd.OrderItems) {
                                String bundleFeature = oItem.Product2.Bundle_Features__c;
                                if (oItem.Product2.Family == 'POLARIS' || ( String.isNotBlank(bundleFeature) && bundleFeature.contains('Polaris') )) {
                                    polarisPrdCodeSet.add(oItem.Product_Code_Formula__c);
                                }
                            }
                        }
                    }
                    
                    if (((ord.Type == 'Revenue' && oldOrd.Order_Status__c != ord.Order_Status__c && ord.Order_Status__c == 'Order Accepted') 
                         || (ord.Type == 'POC' && ord.Order_Status__c == 'Pending' && !String.isBlank(ordQ.POC_Request__c))) 
                         && orderPolarisSet.contains(ord.Id)) {
                            
                            system.debug('Inside POLARIS_OrderFulfillment.createTaskOnOrderActivation :: ord : ' + ord);    
                            
                            
                            Task newTsk = new Task();
                            newTsk.WhatId = ord.Id;
                            newTsk.Operation__c = 'Provision';
                            newTsk.Status = 'Assigned';
                            newTsk.Order_Type__c = ord.Type;
                            newTsk.OwnerId = System.Label.Polaris_Infrastructure_Team_User_ID;
                            //newTsk.Order_Number__c = ord.Id;
                            newTsk.RecordTypeId = polarisTaskRT;
                            newTsk.Description = ''+polarisPrdCodeSet;
                            newTsk.Subject = System.Label.Polaris_Task_Subject_Activation + ' ' + ordQ.Account.Name;
                            
                            if (ordQ.Opportunity.Polaris_Region__c != null) {
                                newTsk.Subject = ordQ.Opportunity.Polaris_Region__c + ' - ' + newTsk.Subject;
                            }                      
                            
                            if (ord.Est_Ship_Date__c != null) {
                                Date estDate = Date.today() + 1;
                                if (Date.valueof(ord.Est_Ship_Date__c) < estDate) {
                                    newTsk.ActivityDate = Date.valueof(ord.Est_Ship_Date__c);
                                } else {
                                    newTsk.ActivityDate = Date.valueof(ord.Est_Ship_Date__c) - 1;
                                }
                            }
                            
                            if (ordOIProductTypeMap.containsKey(ord.Id)) {
                                newTsk.Type = ordOIProductTypeMap.get(ord.Id);
                            }
                            /*
                             * As per Manan, this is not a requirement any more
                            if (ord.Type == 'Revenue') {
                                newTsk.Subscription_Term__c = ord.SBQQ__Quote__r.SBQQ__SubscriptionTerm__c;
                            } else if (ord.Type == 'POC') {
                                if (ordQ.POC_Request__r.POC_Duration__c != null) {
                                    String pocTerm = ordQ.POC_Request__r.POC_Duration__c;
                                    pocTerm = pocTerm.replace('Days', '');
                                    pocTerm = pocTerm.replace(' ', '');
                                    if (!String.isBlank(pocTerm)) {
                                        newTsk.Subscription_Term__c = Integer.valueOf((Integer.valueOf(pocTerm) + 7) / 30);
                                    }
                                }
                                
                            }
                            */
                            if(ord.Type == 'Revenue'){
                                if (priOppCntRole.containsKey(ord.OpportunityId)) {
                                    newTsk.Customer_Contact__c = priOppCntRole.get(ord.OpportunityId);
                                    newTsk.WhoId = priOppCntRole.get(ord.OpportunityId);
                                }
                            }
                            else if(ord.Type == 'POC'){
                                if (priOppCntRole.containsKey(ord.POC_Opportunity__c)) {
                                    newTsk.Customer_Contact__c = priOppCntRole.get(ord.POC_Opportunity__c);
                                    newTsk.WhoId = priOppCntRole.get(ord.POC_Opportunity__c);
                                }
                            }

                            tskListToBeInserted.add(newTsk);
                            
                            system.debug('Inside POLARIS_OrderFulfillment.createTaskOnOrderActivation :: tskListToBeInserted : ' + tskListToBeInserted);    
                        }
                }
            }
            
            if (!tskListToBeInserted.isEmpty()) {
                insert tskListToBeInserted;
            }
            
        } catch (Exception e) {
            system.debug('Inside POLARIS_OrderFulfillment.createTaskOnOrderActivation :: e : ' + e);
        } 
    }
    
    public static Map<Id, Task> updateExistingTask (List<Order> ordList, Map<Id, Order> oldOrdMap) {
        Map<Id, Task> ordIdTskMap = new Map<Id, Task> ();
        Map<Id, Task> accIdTskMap = new Map<Id, Task> ();
        
        try {
            Set<Id> ordAccIdSet = new Set<Id> ();
            for (Order ord : ordList) {
                ordAccIdSet.add(ord.AccountId);
            }
            // Checks for existing Activation tasks and if task exists remove from list and map Activation
            system.debug('Inside POLARIS_OrderFulfillment.updateExistingTask :: accIdTskMap : ' + accIdTskMap);
            system.debug('Inside POLARIS_OrderFulfillment.updateExistingTask :: ordIdTskMap : ' + ordIdTskMap);
            
            List<Task> tskListToBeUpdated = new List<Task> ();
            
            for (Order ord: ordList) {
                if(ordIdTskMap.containsKey(ord.Id) ) {
                    Order oldOrd = oldOrdMap.get(ord.Id); 
                    if (ordIdTskMap.containsKey(ord.Id) && ord.Est_Ship_Date__c != oldOrd.Est_Ship_Date__c && ord.Est_Ship_Date__c != null) {
                        Task tskobj = ordIdTskMap.get(ord.Id);
                        date estDate = date.today() + 2;
                        if (date.valueof(ord.Est_Ship_Date__c) < estDate) {
                            tskobj.ActivityDate = date.valueof(ord.Est_Ship_Date__c);
                        } else {
                            tskobj.ActivityDate = date.valueof(ord.Est_Ship_Date__c) - 2;
                        }
                        tskListToBeUpdated.add(tskobj);
                    }
                    if (ord.Order_Status__c != oldOrd.Order_Status__c && (ord.Order_Status__c == 'Cancelled' || ord.Order_Status__c == 'Rejected')) {
                        Task tskobj = ordIdTskMap.get(ord.Id);
                        tskobj.Status = 'Cancelled';
                        tskListToBeUpdated.add(tskobj);
                    }
                }
            }
            if (!tskListToBeUpdated.isEmpty()) {
                update tskListToBeUpdated;
            }
            
        } catch(Exception e) {
            system.debug('Inside POLARIS_OrderFulfillment.updateExistingTask :: e : ' + e);
            return null;
        } 
        return accIdTskMap;
    }
    
    //public static void checkTaskComplete(List<Order> ordList, Map<Id, Order> oldOrderMap) {
    //    try {
    //        Set<Id> ordIdSet = new Set<Id> ();
    //        for (Order ord : ordList) {
    //            Order oldOrd = oldOrderMap.get(ord.Id);
    //            if (ord.Order_Status__c == 'Shipped' && oldOrd.Order_Status__c != ord.Order_Status__c) {
    //                ordIdSet.add(ord.Id);
    //            }
    //        }
            
    //        if(!ordIdSet.isEmpty()) {
    //            Map<Id, Task> mapIdTask = new Map<Id, Task> ();
                
    //            // Checks for existing tasks and if task existing remove from list and map
    //            for (Task tsk: [SELECT Id, Subject, WhatId, Status FROM Task 
    //                            WHERE Subject LIKE '%Polaris Account Activation%'
    //                            AND WhatId IN :ordIdSet]) 
    //            {
    //                mapIdTask.put(tsk.WhatId, tsk);
    //            }
                
    //            for (Order ord : ordList) {
    //                Order oldOrd = oldOrderMap.get(ord.Id);
    //                if (ord.Order_Status__c == 'Shipped' && oldOrd.Order_Status__c != ord.Order_Status__c && mapIdTask.containsKey(ord.Id)) {
    //                    Task tskobj = mapIdTask.get(ord.Id);
    //                    if (tskobj.Status != 'Completed') {
    //                        ord.addError(System.Label.Polaris_Order_Error);
    //                    }
    //                }
    //            }
    //        }
            
    //    } catch (Exception e) {
    //        system.debug('Inside POLARIS_OrderFulfillment.checkTaskComplete :: e : ' + e);
    //    }
    //}
    
}