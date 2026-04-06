global class BatchUpdateOrderProduct implements Database.Batchable<sObject>,Schedulable  {  
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchUpdateOrderProduct());
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT ID,Order.Actual_Order_Ship_Date__c , ServiceDate, EndDate, Support_Start_Date__c,Support_End_Date__c FROM OrderItem Where Support_Start_Date__c = null AND Support_End_Date__c = null AND Order.Status = \'Shipped\' AND (Product2.Name =\'RBK-PS-CNSLT-ONST\''+'OR Product2.Name =\'RBK-PS-CNSLT-RMOT\''+ 'OR Product2.Name =\'RBK-PS-INST\''+') ');//
    }
    global void execute(Database.BatchableContext bc, List<OrderItem> scope){
        // process each batch of records
        List<OrderItem> orderList = new List<OrderItem>();
        for(OrderItem odr : scope){
            if(odr.Order.Actual_Order_Ship_Date__c != null){
                OrderItem oi = new OrderItem();
                oi.Id = odr.Id;
                oi.Support_Start_Date__c = odr.Order.Actual_Order_Ship_Date__c ;
                oi.Support_End_Date__c = odr.Order.Actual_Order_Ship_Date__c.addMonths(6)-1;
                orderList.add(oi);
            }
        }
        update orderList;
    }    
    global void finish(Database.BatchableContext bc){
    }
}