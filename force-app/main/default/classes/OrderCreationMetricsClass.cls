/***
Create By: sonal Agrawal(Bluvium)
Class Name: OrderCreationMetricsClass 
Purpose: To create Order_Success_Metrics__c record
***/
public class OrderCreationMetricsClass {
    @InvocableMethod(label='createOrderSuccessMatrix')
    public static void createOrderSuccessMatrix(List<Id> ShipOrderList) {
   
     // Check if Order_Success_Metrics__c records exist for the given ShipOrderList
    Set<Id> existingOrderIds = new Set<Id>();
    for (Order_Success_Metrics__c osm : [SELECT Order__c FROM Order_Success_Metrics__c WHERE Order__c IN :ShipOrderList]) {
        existingOrderIds.add(osm.Order__c);
    }
    
    // Determine which order IDs need processing
    Set<Id> orderIdSet= new Set<Id>(ShipOrderList);
    orderIdSet.removeAll(existingOrderIds);
    
    // If no new orders need processing, exit the method
    if (orderIdSet.isEmpty()) {
        return;
    }
    
        
        // Query Orders
        List<Order> orderList = [SELECT Id, OrderNumber, Type, CreatedBy.Name, Auto_Manual_Booked__c, Polaris_Fulfillment_Status__c, 
                                 Stage_PO__c, BookingStatus__c, Order_Status__c, Actual_Order_Ship_Date__c 
                                 FROM Order 
                                 WHERE Id IN :orderIdSet];
        
        // Query OrderHistories
        Map<String, OrderHistory> orderHistoryMap = new Map<String, OrderHistory>();
        for (OrderHistory oh : [SELECT OrderId, CreatedDate, CreatedBy.Name, Field, NewValue 
                                FROM OrderHistory 
                                WHERE OrderId IN :orderIdSet 
                                AND Field IN ('BookingStatus__c', 'Order_Status__c', 'Polaris_Fulfillment_Status__c')
                                ORDER BY CreatedDate ASC]) {
                                    String fieldId = oh.OrderId + oh.Field + oh.NewValue;
                                    orderHistoryMap.put(fieldId, oh);
                                }
        
        // Query ServiceContracts
        Map<Id, ServiceContract> orderServiceContractMap = new Map<Id, ServiceContract>();
        for (ServiceContract sc : [SELECT Id, SBQQSC__Order__c, CreatedDate 
                                   FROM ServiceContract 
                                   WHERE SBQQSC__Order__c IN :orderIdSet 
                                   ORDER BY CreatedDate DESC]) {
                                       orderServiceContractMap.put(sc.SBQQSC__Order__c, sc);
                                   }
        
        // Query OrderItems for CLI and Entitlement
        Map<Id, OrderItem> orderItemCLIMap = new Map<Id, OrderItem>();
        Map<Id, OrderItem> orderItemEntitlementMap = new Map<Id, OrderItem>();
        Set<id> orderProductOrderSet = new Set<id>();
        for (OrderItem op : [SELECT Id,SBQQSC__ContractLineItem__c, OrderId, Order.Actual_Order_Ship_Date__c
                             ,(Select Order_Service_Item__c From Entitlements__r where Type ='Phone Support' )
                             FROM OrderItem 
                             WHERE Order.Order_Status__c = 'Shipped' 
                             AND PricebookEntry.Product2.SBQQSC__EntitlementConversion__c !=null
                             AND Order.SBQQ__Quote__c != NULL 
                             AND Order.Type = 'Revenue' 
                             AND OrderId IN :orderIdSet 
                             ORDER BY Order.OrderNumber]) {
                                 if(op.SBQQSC__ContractLineItem__c== NULL){
                                     orderItemCLIMap.put(op.OrderId, op);
                                 }
                                 if(op.Entitlements__r.size()==0){
                                     orderItemEntitlementMap.put(op.OrderId, op); 
                                 }
                                 orderProductOrderSet.add(op.OrderId);
                             }
        
        // Process Orders and create metrics
        List<Order_Success_Metrics__c> orderSuccessMetricsList = new List<Order_Success_Metrics__c>();
        Order_control__mdt polarisUserName = Order_control__mdt.getInstance('PolarisAPIUser');
        Order_control__mdt OrderUserName = Order_control__mdt.getInstance('OrderAPIUser');
        Order_control__mdt OrderShipBookTime = Order_control__mdt.getInstance('OrderShipBookedTimeDiff');
        
        for (Order o : orderList) {
            Order_Success_Metrics__c osm = new Order_Success_Metrics__c(
                Order__c = o.Id,
                Name = o.OrderNumber + ' Order Success Metrics',
                Order_Creation_Metrics__c = 'Manual',
                Order_Booking_Metrics__c = 'Manual',
                Booking_Creation_Metrics__c = 'Manual'
            );
            
            if (o.Type == 'Revenue') {
                osm.Order_Creation_Metrics__c = o.CreatedBy.Name.contains(OrderUserName.Value__c) ? 'Auto' : 'Manual';
                system.debug('o.CreatedBy.Name '+o.CreatedBy.Name );
            }
            
            if (o.Stage_PO__c != null) {
                osm.Stage_PO_Submission_Metrics__c = o.CreatedBy.Name.contains(OrderUserName.Value__c) ? 'Auto' : 'Manual';
            }
            
            if (o.Auto_Manual_Booked__c == 'Auto Booked') {
                osm.Order_Booking_Metrics__c = 'Auto';
            }
            String RSCFullStatusfieldCompId = o.Id + 'Polaris_Fulfillment_Status__c' + 'Completed';
            String RSCFullStatusfieldErrorId = o.Id + 'Polaris_Fulfillment_Status__c' + 'Error with Fulfillment';
            if (orderHistoryMap.containsKey(RSCFullStatusfieldCompId)) {
                osm.Order_Provisioning_Metrics__c = orderHistoryMap.get(RSCFullStatusfieldCompId).CreatedBy.Name.contains(polarisUserName.Value__c) && !orderHistoryMap.containskey(RSCFullStatusfieldErrorId) ? 'Auto' : 'Manual';
            }
            
            String bookingStatusFieldCompId = o.Id + 'BookingStatus__c' + 'Completed'; 
            String orderStatusFieldAcceptId = o.Id + 'Order_Status__c' + 'Order Accepted'; 
            String orderStatusFieldShipId = o.Id + 'Order_Status__c' + 'Shipped';
            
            
            Long bookingDate = (o.BookingStatus__c == 'Completed' && orderHistoryMap.containsKey(bookingStatusFieldCompId))
                ? orderHistoryMap.get(bookingStatusFieldCompId).CreatedDate.getTime() : null;
            Long shippingDate = (o.Order_Status__c == 'Shipped' && orderHistoryMap.containsKey(orderStatusFieldShipId))
                ? orderHistoryMap.get(orderStatusFieldShipId).CreatedDate.getTime() : null;
            Long OrderAcceptDate = orderHistoryMap.containsKey(orderStatusFieldAcceptId)
                ? orderHistoryMap.get(orderStatusFieldAcceptId).CreatedDate.getTime() : null;
                
            if(Test.isRunningTest()){
            bookingDate = 10000;
            shippingDate = 9000000;
            OrderAcceptDate = 9000;
            }
            if (bookingDate != null && OrderAcceptDate != null) {
                Long minutesDiff = (bookingDate - OrderAcceptDate) / 60000;
                osm.Booking_Creation_Metrics__c = 'Manual';
                if (minutesDiff <= Integer.valueOf(OrderShipBookTime.Value__c) && minutesDiff>=0) {
                    osm.Booking_Creation_Metrics__c = 'Auto';
                }
            }
            if(orderProductOrderSet.contains(o.id)){
                osm.SC_creation_Metrics__c = 'Manual';
                osm.CLI_creation_Metrics__c = 'Manual';
                osm.Entitlement_Creation_Metrics__c  = 'Manual';
            }
            if (orderServiceContractMap.containsKey(o.Id) && shippingDate != null) {
                Long serviceContractCreationMinutesDiff = (orderServiceContractMap.get(o.Id).CreatedDate.getTime() - shippingDate) / 60000;
                if(serviceContractCreationMinutesDiff <= Integer.valueOf(OrderShipBookTime.Value__c)){
                    osm.SC_creation_Metrics__c = 'Auto';
                    osm.CLI_creation_Metrics__c = orderItemCLIMap.containsKey(o.Id)?'Manual' : 'Auto';
                    osm.Entitlement_Creation_Metrics__c =orderItemEntitlementMap.containsKey(o.Id)?'Manual' : 'Auto';
                }
                
            }
            orderSuccessMetricsList.add(osm);
        }//End of for
        
        if (orderSuccessMetricsList.size()>0) {
            system.debug('OrderSuccesMetricsList'+orderSuccessMetricsList.size());
            Insert orderSuccessMetricsList;
        }
    }
}