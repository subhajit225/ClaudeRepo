trigger OrderItemEvent on Order_Item_Event__e (after insert) {
    Map<String, OrderItem> orderItems = new Map<String, OrderItem>();
    
    for(Order_Item_Event__e event: Trigger.new){
        if(event.Order_Item_Id__c != null){
            OrderItem oi = new OrderItem(Id = event.Order_Item_Id__c, ServiceDate = event.Support_Start_Date__c);
            orderItems.put(event.Order_Item_Id__c, oi);
         }
    }
    
    
    if(orderItems != null) {
        List<Order> ordersToUpdate = new List<Order>();
        Map<Id, Date> orderEffectiveDateMap = new Map<Id, Date>();
        
        for(OrderItem oi: [Select Id, Order.EffectiveDate, OrderId from OrderItem where Id in :orderItems.keySet()]){
            Date orderItemStartDate = orderItems.get(oi.Id).ServiceDate;
            if(oi.Order.EffectiveDate > orderItemStartDate){
                if(!orderEffectiveDateMap.containsKey(oi.OrderId)) {
                    orderEffectiveDateMap.put(oi.OrderId, orderItemStartDate);
                }
                else if(orderEffectiveDateMap.get(oi.OrderId) > orderItemStartDate){
                    orderEffectiveDateMap.put(oi.OrderId, orderItemStartDate);
                }
            }
            
        }

        if(orderEffectiveDateMap.size() > 0) {
            for(Id orderId : orderEffectiveDateMap.keySet()){
                ordersToUpdate.add(new Order(Id = orderId, EffectiveDate = orderEffectiveDateMap.get(orderId)));
            }
        }

        if(ordersToUpdate.size() > 0) {
            Database.update(ordersToUpdate, false);
        }
    }
    
    if(orderItems.size()>0){
        update orderItems.values();
    }
}