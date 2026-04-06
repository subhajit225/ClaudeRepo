/***********************************************************************************  
* @description       : This Queueable class Will Update the Segment Start and EndDate from support dates by siabling CPQ package triggers.
* Project            : Scale Utility
* JIRA(s)            : CSU-336
* @author            : Prashant
* @last modified on  : 01-09-2023
* @last modified by  : Prashant
* Testclass          : ScaleUtilityOverageTriggerTest
* Modifications Log
*******************************************************************************/ 
public class UpdateSupportOrderLinesDatesForCSUClass implements Queueable {
  List<OrderItem> oiListUpdate = new List<OrderItem>();

  public UpdateSupportOrderLinesDatesForCSUClass(List<OrderItem> oiForDatesToUpdateCSUList) {
    oiListUpdate.addAll(oiForDatesToUpdateCSUList);
  }

  public void execute(QueueableContext qc) {
    updateStandardDatesOnOrderLine();
    updateOrderLineswithCustomerFacingGCId();
  }
/***********************************************************************************
  * @description       : updateStandardDatesOnOrderLine method which used to update orderitem dates by turn off the OrderItemtrigger. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-336
  * @author            : Prashant
  * @last modified on  : 05-12-2023
  * @last modified by  : Prashant
  * arguments          : NA
  * return             : void
  * Modifications Log
  * 
  *******************************************************************************/
  private void updateStandardDatesOnOrderLine() {
    try {
      if (!oiListUpdate.isEmpty()) {
        Map<Id, Order> ordersById = new Map<Id, Order>();
        for (OrderItem eachOrderItem : oiListUpdate) {
          if (eachOrderItem.Order.EffectiveDate > Date.today() && !ordersById.containsKey(eachOrderItem.OrderId) && eachOrderItem.Order.Order_Sub_Type__c == Constants.ORDER_SUB_TYPE_GC_OFFER) {
            Order orderToUpdate = new Order(Id = eachOrderItem.OrderId, EffectiveDate = Date.today());
            ordersById.put(eachOrderItem.OrderId, orderToUpdate);
          }
        }
        //pass leases to Batch class
        SBQQ.TriggerControl.disable();
        TriggerControl.stopOrderItemTrigger = true;
        update oiListUpdate;
        TriggerControl.stopOrderTrigger = true;
        if (!ordersById.isEmpty()) {
          Database.update(ordersById.values(), false);
        }
        SBQQ.TriggerControl.enable();
        TriggerControl.stopOrderItemTrigger = false;
      }
    } catch (Exception e) {
      UtilityClass.logException(e, 'UpdateSupportOrderLinesDatesForCSUClass', 'updateDates', 'OrderItem', null, 'SFDC', false);
    }
  }
/***********************************************************************************
  * @description       : updateOrderLineswithCustomerFacingGCId method which used to generate customer facing gcId and get this updated in Orderitems. 
  * Project            : Scale Utility
  * JIRA(s)            : CSU-502
  * @author            : NaveenkumarSelvaraj
  * @last modified on  : 05-12-2023
  * @last modified by  : NaveenkumarSelvaraj
  * arguments          : NA
  * return             : void
  * Modifications Log
  * 
  *******************************************************************************/
  public void updateOrderLineswithCustomerFacingGCId(){
    try{
      Map<String, Customer_Facing_GC_ID__c> customerFacingRec = new Map<String, Customer_Facing_GC_ID__c>();
      List<OrderItem> orderItemToUpdate = new List<OrderItem>();
      Map<String, Customer_Facing_GC_ID__c> mapOfGCIdToCustomFacRec = new Map<String, Customer_Facing_GC_ID__c>();
      set<Id> setofOrderIds = new Set<Id>();
      Set<string> setOfglobalCommit = new Set<String>();
      if (!oiListUpdate.isEmpty()) {
        for (OrderItem oi : oiListUpdate) {
          setofOrderIds.add(oi.orderid);
        }
        if (!setofOrderIds.isEmpty()) {
          List<OrderItem> lstOfGCOrderItems = [SELECT id, orderid, order.accountId, Global_Commit_ID__c, Customer_Facing_GC_ID__c FROM OrderItem WHERE orderid IN :setofOrderIds];
          for (OrderItem oi : lstOfGCOrderItems) {
            if (oi.Global_Commit_ID__c != null && oi.Customer_Facing_GC_ID__c == null) {
              setOfglobalCommit.add(oi.Global_Commit_ID__c);
              //customerFacingRec.put(oi.Global_Commit_ID__c, new Customer_Facing_GC_ID__c(Global_Commit_ID__c = oi.Global_Commit_ID__c));
            }
          }
          if (!setOfglobalCommit.isEmpty()) {
            List<Customer_Facing_GC_ID__c> existingCustomerFacingIds = [SELECT id, Name, Global_Commit_ID__c FROM Customer_Facing_GC_ID__c WHERE Global_Commit_ID__c IN :setOfglobalCommit];
            if (!existingCustomerFacingIds.isEmpty()) {
              for (Customer_Facing_GC_ID__c CustFacingRec : existingCustomerFacingIds) {
                mapOfGCIdToCustomFacRec.put(CustFacingRec.Global_Commit_ID__c, CustFacingRec);
              }
            }
          }
          for (OrderItem oi : lstOfGCOrderItems) {
            if (oi.Global_Commit_ID__c != null && oi.Customer_Facing_GC_ID__c == null) {
              if (mapOfGCIdToCustomFacRec != null && !mapOfGCIdToCustomFacRec.containskey(oi.Global_Commit_ID__c)) {
                customerFacingRec.put(oi.Global_Commit_ID__c, new Customer_Facing_GC_ID__c(Global_Commit_ID__c = oi.Global_Commit_ID__c, Order__c = oi.orderId, Account_Name__c = oi.order.AccountId));
              }
            }
          }
          if (!customerFacingRec?.values().IsEmpty()) {
            insert customerFacingRec.values();
          }
          if (!setOfglobalCommit.isEmpty()) {
            for (Customer_Facing_GC_ID__c cusFacRec : [SELECT id, Name, Global_Commit_ID__c FROM Customer_Facing_GC_ID__c WHERE Global_Commit_ID__c IN :setOfglobalCommit]) {
              mapOfGCIdToCustomFacRec.put(cusFacRec.Global_Commit_ID__c, cusFacRec);
            }
          }

          for (OrderItem oi : lstOfGCOrderItems) {
            if (mapOfGCIdToCustomFacRec.containskey(oi.Global_Commit_ID__c)) {
              oi.Customer_Facing_GC_ID__c = Decimal.valueOf(mapOfGCIdToCustomFacRec?.get(oi.Global_Commit_ID__c)?.Name);
              orderItemToUpdate.add(oi);
            }
          }
          SBQQ.TriggerControl.disable();
          TriggerControl.stopOrderItemTrigger = true;
          if (!orderItemToUpdate.isEmpty()) {
            update orderItemToUpdate;
          }
          SBQQ.TriggerControl.enable();
          TriggerControl.stopOrderItemTrigger = false;
        }
      }
    } catch (Exception e) {
      UtilityClass.logException(e, 'updateOrderLines', 'updateDates', 'OrderItem', null, 'SFDC', false);
    }
  }
}