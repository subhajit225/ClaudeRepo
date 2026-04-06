public with sharing class OrderItemTriggerHandler extends TriggerManager.GenericTriggerHandler {
  public static boolean isDisabledOrderItemTracking = false;
  public static User currentUser = new User();


  public override void onBeforeInsert(List<sObject> newRecords) {
    List<OrderItem> newOrderItemList = (List<OrderItem>) newRecords;
    Set<Id> setOfOrdIds = new Set<Id>();
    Set<Id> qliIdSet = new Set<Id>();
    OrderItemTriggerHelper.isRecentlyInserted = true;
    isDisabledOrderItemTracking = true;
    for (OrderItem newOrderItem : newOrderItemList) {
      OrderItemTriggerHelper.resetValues(newOrderItem, null);
      qliIdSet.add(newOrderItem.SBQQ__QuoteLine__c);
      setOfOrdIds.add(newOrderItem.orderId);
    }
    OrderItemTriggerHelper.OrderItemInit(setOfOrdIds, true);
    OrderItemTriggerHelper.insertTransaction = true;
    OrderItemTriggerHelper.populateEDILInes(newOrderItemList, qliIdSet);
  }

  public override void onAfterInsert(Map<ID, sObject> newRecordsMap) {
    Map<ID, OrderItem> newMap = (Map<ID, OrderItem>) newRecordsMap;
    Set<Id> setOfOrdIds = new Set<Id>();
    for (OrderItem OI : newMap.values()) {
      if (oi.OrderId != null) {
        setOfOrdIds.add(oi.OrderId);
      }
    }
    OrderItemTriggerHelper.OrderItemInit(setOfOrdIds, false);
    OrderItemTriggerHelper.populateValuesOnCreatedOLI(newMap);
  }

  public override void onBeforeUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
    Map<ID, OrderItem> oldMap = (Map<ID, OrderItem>) oldRecordsMap;
    Map<ID, OrderItem> newMap = (Map<ID, OrderItem>) newRecordsMap;
    Set<Id> setOrderIds = new Set<Id>();
    for (OrderItem newOrderItem : newMap.values()) {
      OrderItemTriggerHelper.resetValues(newOrderItem, oldMap.get(newOrderItem.id));
      setOrderIds.add(newOrderItem.OrderId);
    }
    OrderItemTriggerHelper.OrderItemInit(setOrderIds, false);
    validateOrderItemUpdatePermissions(newMap, oldMap); 
    OrderItemTriggerHelper.populateFieldsOnUpdate(newMap, oldMap);
  }

  public override void onAfterUpdate(Map<ID, sObject> oldRecordsMap, Map<ID, sObject> newRecordsMap) {
    Map<ID, OrderItem> oldMap = (Map<ID, OrderItem>) oldRecordsMap;
    Map<ID, OrderItem> newMap = (Map<ID, OrderItem>) newRecordsMap;
    List<Order_Item_Event__e> events = new List<Order_Item_Event__e>();
    List<Duplicate_Entitlement_Handler__e> duplicateEntitlementEventList = new List<Duplicate_Entitlement_Handler__e>();
    Map<ID, Order> updateOrderMap = new Map<ID, Order>();
    Set<Id> setOrderIds = new Set<Id>();
    Boolean isSerialNumberUpdatedForRefresh = false;
    List<OrderItem > nonAssetToAssetWithSerials  = new List<OrderItem>();
    Map<Id, OrderItem> contractedLicenseOrdItemById  = new Map<Id, OrderItem>();
    Boolean hasAspenOrderItems = false;

    for (OrderItem newOrderItem : newMap.values()) {
      OrderItem oldOrderItem = oldMap.get(newOrderItem.id);
      Order relatedOrder;
      if(OrderItemTriggerHelper.mapOfOrders.containskey(newOrderItem.orderId)){
        relatedOrder = OrderItemTriggerHelper.mapOfOrders.get(newOrderItem.orderId);
      }
      if (
        newOrderItem.Support_Start_Date__c != null &&
        newOrderItem.ServiceDate != newOrderItem.Support_Start_Date__c &&
        (newOrderItem.SBQQ__SegmentIndex__c == null ||
        newOrderItem.SBQQ__SegmentIndex__c == 1)
      ) {
        if (!(newOrderItem.is_Amendment__c || newOrderItem.Is_Renewal__c)) {
          events.add(new Order_Item_Event__e(Order_Item_Id__c = newOrderItem.Id, Support_Start_Date__c = newOrderItem.Support_Start_Date__c));
        }
      }
      // PRDOPS24-710 - Auto sync between salesforce and netsuite
      // PRDOPS24-885 - Fix for Debook Oppty Not Moved to Close/Won
      if (
        (newOrderItem.Engagement_Date__c != null &&
        newOrderItem.Engagement_Date__c != oldOrderItem.Engagement_Date__c) ||
        ((newOrderItem.Sales_Price__c != oldOrderItem.Sales_Price__c ||
        newOrderItem.Capacity__c != oldOrderItem.Capacity__c ||
        newOrderItem.List_Total__c != oldOrderItem.List_Total__c ||
        newOrderItem.Line_Type__c != oldOrderItem.Line_Type__c ||
        newOrderItem.SerialNumber__c != oldOrderItem.SerialNumber__c ||
        newOrderItem.Quantity != oldOrderItem.Quantity ||
        newOrderItem.UnitPrice != oldOrderItem.UnitPrice ||
        newOrderItem.SBQQ__SubscriptionTerm__c != oldOrderItem.SBQQ__SubscriptionTerm__c) &&
        newOrderItem.Order_Status__c == 'Order Accepted' &&
        (OrderItemTriggerHelper.mapOfOrders.containskey(newOrderItem.orderId) &&
        (OrderItemTriggerHelper.mapOfOrders.get(newOrderItem.orderId).type == 'Revenue' ||
        OrderItemTriggerHelper.mapOfOrders.get(newOrderItem.orderId).type == 'RMA'))) ||
        (newOrderItem.Failed_Serial_Number__c != oldOrderItem.Failed_Serial_Number__c &&
        (newOrderItem.Order_Status__c == 'Pending' ||
        newOrderItem.Order_Status__c == 'Order Accepted'))
      ) {
        if (!updateOrderMap.containsKey(newOrderItem.orderId)) {
          updateOrderMap.put(newOrderItem.orderId, new order(id = newOrderItem.orderId, Sync_to_NetSuite__c = true));
        }
      }
      if (newOrderItem.SBQQ__Contracted__c && !oldOrderItem.SBQQ__Contracted__c) {
        duplicateEntitlementEventList.add(new Duplicate_Entitlement_Handler__e(Order_Item_Id__c = newOrderItem.Id));
      }
      if (newOrderItem.SBQQSC__ContractLineItem__c != null && (newOrderItem.SBQQSC__ContractLineItem__c != oldOrderItem.SBQQSC__ContractLineItem__c)) {
        setOrderIds.add(newOrderItem.OrderId);
      }
      Boolean isSerialNumberUpdatedForNonAspenOrder = relatedOrder != null && relatedOrder.ProcessType__c != 'Aspen' &&
        String.isBlank(oldOrderItem.SerialNumber__c) &&
        String.isNotBlank(newOrderItem.SerialNumber__c);

      // Handle Aspen-specific serial number updates in OrderItem trigger context. 
      Boolean isSerialNumberUpdatedAspenOrder = false;
      if (relatedOrder != null && relatedOrder.ProcessType__c == 'Aspen'){
         //check isAspen order 
          if(!hasAspenOrderItems){
            hasAspenOrderItems = true;
          }
          //check serial number modified. 
          if (String.isBlank(oldOrderItem.SerialNumber__c) &&
              String.isNotBlank(newOrderItem.SerialNumber__c)){
              isSerialNumberUpdatedAspenOrder = true;
          }
      }
      if (isSerialNumberUpdatedForNonAspenOrder){
        if (newOrderItem.Program__c == CONSTANTS.PROGRAM_REFRESH) {
          isSerialNumberUpdatedForRefresh = true;
        }
        //filtering new Sale Non-aspen order
        if (relatedOrder.Type == Constants.ORDER_TYPE && String.isBlank(relatedOrder?.Order_Sub_Type__c) && String.isBlank(newOrderItem?.Program__c) && newOrderItem?.Line_Type__c == 'New'){
          nonAssetToAssetWithSerials.add(newOrderItem);
          //filtering new Sale order with contracted orderitems 
          if (newOrderItem.SBQQ__Contracted__c) {
            contractedLicenseOrdItemById.put(newOrderItem.id, newOrderItem);
          } 
        }
      }
      //filtering new Sale Non-aspen order
      if (isSerialNumberUpdatedAspenOrder && relatedOrder.Type == Constants.ORDER_TYPE && String.isBlank(relatedOrder?.Order_Sub_Type__c) && String.isBlank(newOrderItem?.Program__c) && newOrderItem?.Line_Type__c == 'New'){
          nonAssetToAssetWithSerials.add(newOrderItem);
      }
    }
    if (!updateOrderMap.isEmpty()) {
      update updateOrderMap.values();
    }
    if (!events.isEmpty()) {
      EventBus.publish(events);
    }
    if (!setOrderIds.isEmpty() || isSerialNumberUpdatedForRefresh || !nonAssetToAssetWithSerials .isempty() || !contractedLicenseOrdItemById .keySet().isEmpty()) {
      OrderItemTriggerHelper.OrderItemInit(setOrderIds, false);
      if (!setOrderIds.isEmpty()) {
      OrderItemTriggerHelper.updateRequiredByLineItemOnCLI();
      }
    }
    OrderItemTriggerHelper.syncAssets(newMap.values(), oldMap);
    //Update the refresh Serial Numbers on the Non-Aspen refresh Order Items based on the HW serial # received from Netsuite
    if (isSerialNumberUpdatedForRefresh) {
        OrderItemTriggerHelper.updateRefreshOrderItemSerialNumbers();
      }
    if (!nonAssetToAssetWithSerials .isEmpty()) {
        OrderItemTriggerHelper.updateSerialNumOnLicenseLine(nonAssetToAssetWithSerials, hasAspenOrderItems);
    }
    if (!contractedLicenseOrdItemById .isEmpty()){
        OrderItemTriggerHelper.createLinkedAssetForLicenseNonAssetToAsset(contractedLicenseOrdItemById);
    }
    if (!duplicateEntitlementEventList.isEmpty()) {
      EventBus.publish(duplicateEntitlementEventList);
    }
    /* Calling trackFieldsHistory method of CustomHistoryTracker class to track the hitsory of fields defined in the Field Set */
    Order_control__mdt DisableCustomHistoryTracker = Order_control__mdt.getInstance('Disable_OrderItem_Custom_History_Tracker');

    if (
      !CustomHistoryTracker.recurssionHandlerSobjectSet.contains('OrderItem') &&
      DisableCustomHistoryTracker?.Value__c != null &&
      !boolean.valueOf(DisableCustomHistoryTracker?.Value__c) &&
       !isDisabledOrderItemTracking
    ) {
      CustomHistoryTracker.trackFieldsHistory(Trigger.new, Trigger.oldMap, 'Order_Product__c');
    }
  }
  public override void onBeforeDelete(Map<ID, sObject> oldRecordsMap) {
    Map<ID, OrderItem> oldMap = (Map<ID, OrderItem>) oldRecordsMap;
    OrderItemTriggerHelper.deleteBookingLineItems(oldMap);
    OrderItemTriggerHelper.updateDeletedLineIds(oldMap); // SETU-11
  }
    /**
   * @description This method checks for the Edit Permissions for Order and OrderItem added for PRDOPS26-958
   * @param newMap
   * @param oldMap
   */
  public static void validateOrderItemUpdatePermissions(Map<Id,OrderItem> newMap, Map<Id,OrderItem> oldMap){
    
    if(currentUser.Id != UserInfo.getUserId()){
      currentUser = [SELECT Id, User_Type__c, RBAC_Group__c, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }
    
    Boolean isUserInValidRBACGroup = currentUser.RBAC_Group__c == null || !new List<String>{'IT Prod Ops Support', 'API', 'System - IT'}.contains(currentUser.RBAC_Group__c);
    Boolean isUserOfValidType = currentUser.User_Type__c != 'API' && currentUser.User_Type__c != 'System';
    Boolean isNonSystemTriggeredTransaction = !System.isFuture() && !System.isBatch() && !System.isScheduled() && !System.isQueueable();
    Boolean isOrderEditValidationDisabled = !Boolean.valueOf(Order_control__mdt.getInstance('Disable_Order_Edit_Validation').Value__c);
    
    for (OrderItem newOrderItem : newMap.values()) {
      Order relatedOrder = OrderItemTriggerHelper.mapOfOrders.get(newOrderItem.OrderId);
      if (isUserInValidRBACGroup && isUserOfValidType && isNonSystemTriggeredTransaction && isOrderEditValidationDisabled && (!OrderHandler.IsInsertTransaction || !OrderItemTriggerHelper.insertTransaction)) {
        if ((relatedOrder.Type == Constants.ORDER_TYPE_REVENUE_INTERNAL) && !Test.isRunningTest()) {
          newOrderItem.addError('You don\'t have permission to Edit the Revenue Internal Order/Order Items');
        }
        }
      }
  }
}