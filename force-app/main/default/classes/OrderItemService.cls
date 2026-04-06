/*Created By : SHADAB HUSSAIN
  Purpose : Service class for OrderItemMain Trigger
*/
public class OrderItemService {
    public OrderItemService(){
        
    }
/*
    public static Boolean shouldPopulateRequiredByFields = false;
    public static boolean BYPASS_ORDER_TRIGGER = false;
    static Map<Id,PO_Item_Stage__c> poItemsMap;
    private List<Id> orderIdsToDelte;
    private Map<Id, Date> orderItemsToUpdate;
    public static Map<Id,Booking_Line_Item__c> OrderItemBookingLineItem = new Map<Id, Booking_Line_Item__c>();

    public static void dataCollection(){
         if(Trigger.operationType == System.TriggerOperation.BEFORE_DELETE){
              for(Booking_Line_Item__c BLI : [Select id,OrderProduct__c from Booking_Line_Item__c where OrderProduct__c IN: Trigger.old]){
                OrderItemBookingLineItem.put(BLI.OrderProduct__c,BLI);
            }
         }
        }     
    public static void copyOrderedQuantity(List<OrderItem> newOrderItems, Map<Id, OrderItem> mapOldOrderItems) {
        for(OrderItem oi : newOrderItems) {
            OrderItem oldOi = (mapOldOrderItems != null && mapOldOrderItems.containsKey(oi.Id))
                ? mapOldOrderItems.get(oi.Id)
                : null;

            if(oldOi == null && oi.SBQQ__QuoteLine__c != null && oi.Quantity != null) {
                oi.SBQQ__OrderedQuantity__c = oi.Quantity;
            }
            else if(oldOi != null && oi.SBQQ__QuoteLine__c != null && oi.Quantity != oldOi.Quantity) {
                oi.SBQQ__OrderedQuantity__c = oi.Quantity;
            }
        }
    }

    //Error:Can't update order item's start and end dates at the same time.
    public static void syncOrderItemDates(List<OrderItem> newOrderItems, Map<Id, OrderItem> mapOldOrderItems, Boolean isBefore) {

        //Map<Id, Date> toFutureUpdate = new Map<Id, Date>();
        List<Order_Item_Event__e> events = new List<Order_Item_Event__e>();
        Map<Id,Order> updateOrderMap = new Map<Id,Order>();
        for (OrderItem oi : newOrderItems) {
            system.debug('---for each order item----'+oi);
            OrderItem oldOi = (mapOldOrderItems != null && mapOldOrderItems.containsKey(oi.Id))
                ? mapOldOrderItems.get(oi.Id)
                : null;

             if(!isBefore && oi.Engagement_Date__c!=null && oi.Engagement_Date__c != oldOi.Engagement_Date__c){
                
                updateOrderMap.put(oi.orderId,new order(id=oi.orderId,Sync_to_NetSuite__c=true));
             }

            if(isBefore && oi.EndDate != oi.Support_End_Date__c && oi.SBQQ__SegmentIndex__c==NULL) {
                oi.EndDate = oi.Support_End_Date__c;
            }
            
            else if(!isBefore && oi.Support_Start_Date__c != null  && oi.ServiceDate != oi.Support_Start_Date__c &&  (oi.SBQQ__SegmentIndex__c==NULL ||oi.SBQQ__SegmentIndex__c ==1)  ) {
                //toFutureUpdate.put(oi.Id, oi.Support_Start_Date__c);
                Order_Item_Event__e event = new Order_Item_Event__e(Order_Item_Id__c = oi.Id, Support_Start_Date__c = oi.Support_Start_Date__c);
                if(!(oi.is_Amendment__c || oi.Is_Renewal__c )){
                    events.add(event);
                }
            }
            
            if(isBefore && oi.SBQQ__SegmentIndex__c==NULL && (oi.is_Amendment__c || oi.Is_Renewal__c ) && oi.Support_Start_Date__c != null){
                oi.ServiceDate = oi.Support_Start_Date__c;
            }

            //if(oi.EndDate != oi.Support_End_Date__c) {
            //    oi.EndDate = oi.Support_End_Date__c;
            //}

        }
        //if(!toFutureUpdate.isEmpty() && ((!Test.isRunningTest() || (Test.isRunningTest() && Limits.getQueueableJobs() == 0)))) {
        // if(!toFutureUpdate.isEmpty() && Limits.getQueueableJobs() == 0) {
        //     ID jobID = System.enqueueJob(new OrderItemService(null, toFutureUpdate));
        // }
        system.debug('----events----'+events);
       if(!updateOrderMap.isEmpty()){
          update updateOrderMap.values();
       }
        
        if(!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    public static void deleteDuplicateEntitlements(List<OrderItem> newOrderItems, Map<Id, OrderItem> mapOldOrderItems){
        List<Duplicate_Entitlement_Handler__e> linesToProcess = new List<Duplicate_Entitlement_Handler__e>();
        for(OrderItem oi: newOrderItems){
            if(oi.Is_Renewal__c || oi.is_Amendment__c){
                OrderItem oldOi = mapOldOrderItems.get(oi.Id);
                if(oi.SBQQ__Contracted__c && !oldOi.SBQQ__Contracted__c){
                    linesToProcess.add(new Duplicate_Entitlement_Handler__e(Order_Item_Id__c = oi.Id));
                }
            }
        }

        if(linesToProcess.size()>0){
            EventBus.publish(linesToProcess);
        }
    }
*/
    /*********************************************************

    **********************************************************/
    // public static void updateOrdersChanged(Set<Id> orderIdSet){
    //     system.debug('### ### orderIdSet '+orderIdSet);
    //     List<Order> orderToUpdateAsChanged = [select ID, Update_NetSuite__c from Order where Id =:orderIdSet];
    //     for(Order theOrders : orderToUpdateAsChanged){
    //         theOrders.Update_NetSuite__c=true;
    //         theOrders.Update_Netsuite_Last_Flagged__c=system.now();
    //     }
    //     system.debug('### ### orderToUpdateAsChanged '+orderToUpdateAsChanged.size());
    //     if(orderToUpdateAsChanged.size()>0) update orderToUpdateAsChanged;
    // }


    //public static void deleteWrapperCPQProducts(List<OrderItem> newOrderItems, Map<Id, OrderItem> mapOldOrderItems) {

        /*List<Id> toDelete = new List<Id>();
        Set<Id> productIds = new Set<Id>();
        Map<Id, Product2> mapProducts = new Map<Id, Product2>();

        for(OrderItem oi : newOrderItems) {
            productIds.add(oi.ProductID__c);
        }

        if(!productIds.isEmpty()) {
            List<Product2> products = [SELECT Id, SBQQ__Hidden__c, SBQQ__ExcludeFromOpportunity__c, Product_Type__c
                                        FROM Product2 WHERE Id IN :productIds];
            if(!products.isEmpty()) {
                mapProducts.putAll(products);
            }
        }

        for(OrderItem oi : newOrderItems) {

            Product2 product = (mapProducts.containsKey(oi.ProductID__c)) ? mapProducts.get(oi.ProductID__c) : null;

            if(product != null && product.SBQQ__Hidden__c
                && product.SBQQ__ExcludeFromOpportunity__c
                && product.Product_Type__c == null) {
                System.debug('---oi.id--'+oi.id);
                System.debug('---oi.ProductID__c--'+oi.ProductID__c);
                System.debug('---product.SBQQ__Hidden__c--'+product.SBQQ__Hidden__c);
                System.debug('---product.SBQQ__ExcludeFromOpportunity__c--'+product.SBQQ__ExcludeFromOpportunity__c);
                System.debug('---product.Product_Type__c--'+product.Product_Type__c);

                toDelete.add(oi.Id);
            }
        }
*/
       /* if(!toDelete.isEmpty()) {
            if(!Test.isRunningTest() || (Test.isRunningTest() && Limits.getQueueableJobs() == 0)) {
                ID jobID = System.enqueueJob(new OrderItemService(toDelete, null));
            }
        }*/

    //}
    //This mthod will populate EDI line Number and BuyersPartNum on Orderlines from POItems
/*    public static void populateEDILInes(List<OrderItem> newOrderItems) {
        Set<Id> quoteLIneIds = new Set<Id>();
        for(OrderItem oi : newOrderItems) {
            if(oi.SBQQ__QuoteLine__c != null && !quoteLIneIds.contains(oi.SBQQ__QuoteLine__c)){
                quoteLIneIds.add(oi.SBQQ__QuoteLine__c);
            }
        }
        System.debug('-----quoteLIneIds-----'+JSON.serializePretty(quoteLIneIds));
        if(quoteLIneIds.isEmpty() == false){
            if(OrderItemService.poItemsMap == null){
                OrderItemService.poItemsMap = new Map<Id,PO_Item_Stage__c>([SELECT Id,Name,QuoteLineId__c,EDI_Line_Number__c,Buyer_Part_Number__c FROM PO_Item_Stage__c WHERE QuoteLineId__c IN :quoteLIneIds AND Stage_po__r.Expected_number_of_POs__c = 1]);
            }
            Map<Id,Map<String,String>> orderDataMap = new Map<Id,Map<String,String>>();
            
            for(PO_Item_Stage__c poitemStage : OrderItemService.poItemsMap.values()){
                if(!orderDataMap.containsKey(poitemStage.QuoteLineId__c)){
                    orderDataMap.put(poitemStage.QuoteLineId__c,new Map<String,String>{'EDI_LINE_NUM'=>poitemStage.EDI_Line_Number__c,'BUYER_PART_NUM'=>poitemStage.Buyer_Part_Number__c});
                }
                else{
                    orderDataMap.get(poitemStage.QuoteLineId__c).put('EDI_LINE_NUM',orderDataMap.get(poitemStage.QuoteLineId__c).get('EDI_LINE_NUM') + ';'+poitemStage.EDI_Line_Number__c);
                    //orderDataMap.get(poitemStage.QuoteLineId__c).get('BUYER_PART_NUM');
                }
            }
            for(OrderItem oi : newOrderItems) {
                if(orderDataMap.containsKey(oi.SBQQ__QuoteLine__c)){
                    System.debug('-----orderDataMap.get(oi.SBQQ__QuoteLine__c)-----'+JSON.serializePretty(orderDataMap.get(oi.SBQQ__QuoteLine__c)));
                    oi.EDI_Line_Number__c = orderDataMap.get(oi.SBQQ__QuoteLine__c).get('EDI_LINE_NUM');
                    oi.Buyer_Part_Number__c = orderDataMap.get(oi.SBQQ__QuoteLine__c).get('BUYER_PART_NUM');
                }
            }
        }
    }
*/
    /*@Description: Populated RequiredBy Field on OrdersItems that are ordered becauses required by other OrderItem*/
    /*@Param      : lstOrderItem {Trigger.new} */
    /*@Return     : void */
 /*   public static void populateRequiredBy(List<OrderItem> lstOrderItem) {  
        
        // Makes the Fuction  execute only when Executed in Before update Context , right after, After Insert Context
        if (!shouldPopulateRequiredByFields) {
            return;
        } else {
            shouldPopulateRequiredByFields = false; 
        }

        // Filters OrderItem That aren't without RequiredBy  & if Noone meets criteria, skip all  
        Map<Id,OrderItem> mapOrderIdOrderItem = filterOrderItemsWithoutRequiredBy(lstOrderItem);
    
        if (mapOrderIdOrderItem.size() == 0) {
            return;
        }
        
        Map<Id,Id> mapQuoteLineIdOrderItemId = new Map<Id,Id>();
        
        for (OrderItem objOrderItem : mapOrderIdOrderItem.values()) {
            mapQuoteLineIdOrderItemId.put(objOrderItem.SBQQ__QuoteLine__c,objOrderItem.Id);
        }
    
        for (SBQQ__QuoteLine__c objQuoteLine :[ SELECT Id, SBQQ__RequiredBy__c
                                                FROM SBQQ__QuoteLine__c
                                                WHERE Id IN :mapQuoteLineIdOrderItemId.keySet()
                                                AND SBQQ__Quote__r.SBQQ__Opportunity2__r.Sell_to_Partner__c != null
                                                ]) {

            if (objQuoteLine.SBQQ__RequiredBy__c != null) {
                
                Id idOrderItemComplemantory; 
                Id idQuoteLineRequiredBy;
                Id idOrderItemRequiredBy;
                OrderItem objOrderItemComplemantory;
                if (mapQuoteLineIdOrderItemId.containsKey(objQuoteLine.Id) && String.isNotBlank( (Id) objQuoteLine.get('SBQQ__RequiredBy__c'))) {
                    
                    idOrderItemComplemantory = mapQuoteLineIdOrderItemId.get(objQuoteLine.Id);
                    idQuoteLineRequiredBy = (Id) objQuoteLine.get('SBQQ__RequiredBy__c');
                    
                    if (mapQuoteLineIdOrderItemId.containsKey(idQuoteLineRequiredBy) && mapOrderIdOrderItem.containsKey(idOrderItemComplemantory)) {
                     */   
                        /*
                            Getting Id of OrderItem that requires Current QuoteLine 
                            From Id get Its OrderItem. 
                            at OrderItem Set RequiredByField
                        */
/*
                        idOrderItemRequiredBy = mapQuoteLineIdOrderItemId.get(idQuoteLineRequiredBy);
                        objOrderItemComplemantory = mapOrderIdOrderItem.get(idOrderItemComplemantory);
                        objOrderItemComplemantory.put('SBQQ__RequiredBy__c', idOrderItemRequiredBy);
                    }
                }
            }
        } 
    }
*/
    /*@Description: Filters OrderItems, & returns Map of OrderItems where all OrderItems doesn't have SBQQ__RequiredBy__c  */
    /*@Param      : lstOrderItem {List<OrderItem>} */
    /*@Return     : Map<Id,OrderItem>  */
  /*  public static Map<Id,OrderItem> filterOrderItemsWithoutRequiredBy(List<OrderItem> lstOrderItem) {
        
        Map<Id,OrderItem> mapOrderIdOrderItemFilterd = new Map<Id,OrderItem>();
        
        for (OrderItem objOrderItem : lstOrderItem) {
            
            if (String.isBlank(objOrderItem.SBQQ__RequiredBy__c)) {

                mapOrderIdOrderItemFilterd.put(objOrderItem.Id, objOrderItem);
            }
        }

        return mapOrderIdOrderItemFilterd;
    }
    public static void deleteBookingLineItems() {
        List<Booking_Line_Item__c>deleteBLI = new List<Booking_Line_Item__c>();
        for(OrderItem OI :(List<OrderItem>) trigger.old){
          if(OrderItemBookingLineItem.get(OI.id)!=null){
            deleteBLI.add(new Booking_Line_Item__c(id = OrderItemBookingLineItem.get(OI.id).id));
}
        }
       if(!deleteBLI.isEmpty()){   
         delete deleteBLI; 
       }  
    }*/
}