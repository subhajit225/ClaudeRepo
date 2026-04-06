global class SoftwareFulfilmentTaskBatch implements Database.Batchable<sObject>, Schedulable{

    global void execute(SchedulableContext SC) {
        SoftwareFulfilmentTaskBatch scbat = new SoftwareFulfilmentTaskBatch();
        string jobID =Database.executeBatch(scbat,1);
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    
    {
        
        String QueryStr = 'Select id,orderID,Product_Name__c from orderItem where  Task_Created__c = false and IS_Software_Line_WF__c = true ';
        System.debug('test code '+QueryStr);
        return Database.getQueryLocator(QueryStr);
    
    }
    
     
    
    global void execute(Database.BatchableContext BC,List<OrderItem> orderProducts)
    
    {
    
        List<AsyncApexJob> currentRunningApex  = [select id,ApexClass.name,ExtendedStatus,Status  from AsyncApexJob where (status = 'Holding' OR Status ='Preparing'    OR Status ='Queued') and ApexClass.name='SoftwareFulfilmentTaskBatch' and id =: bc.getJobID()];
        System.debug('test code '+currentRunningApex);
         System.debug('test code '+bc.getJobID());
        if(currentRunningApex == null || (currentRunningApex != null && currentRunningApex.size() ==0))
        {
        
            List<Task> newTasks = new List<Task>();
            List<OrderItem> updateOI = new List<OrderItem>();
            Id taskRecID ;
            if(Schema.SObjectType.Task.getRecordTypeInfosByName() != null && Schema.SObjectType.Task.getRecordTypeInfosByName().get(System.label.Cypress_Task_Record_Type_Label) != null )
                taskRecID = Schema.SObjectType.Task.getRecordTypeInfosByName().get(System.label.Cypress_Task_Record_Type_Label).getRecordTypeId();
            List<Group> que = [ select Id from Group where  Type = 'Queue' AND NAME =: System.label.Cypress_Task_Assign_Queue];
            System.debug('test code ');
            if(que != null && que.size()>0){
                
                for(OrderItem oi : orderProducts){
                
                    Task t = new Task();
                    t.OwnerId = que[0].id;
                    t.Subject = OI.Product_Name__c +' - Fulfilment Request';
                    t.Status = system.label.Cypress_Task_Status;
                    t.Priority = system.label.Cypress_Task_Priority;
                    t.WhatId = oi.orderID;
                    
                    //t.Order_Product__c=oi.id;
                    //t.Order_Number__c = oi.orderID;
                    t.recordTypeID = taskRecID;
                    t.Type = 'Software Fulfillment';
                    newTasks.add(t);
                    OrderItem oiTemp = new OrderItem(id=oi.id,Task_Created__c = true);
                    updateOI.add(oiTemp);
                    System.debug('test code ');
                    
                }
            
                if(newTasks != null && newTasks.size()>0){
                System.debug('test code ');
                   try{
                       insert newTasks;
                       triggerControl.stopOrderItemTrigger = true;
                       update updateOI;
                    
                   }Catch(Exception e){
                       System.debug('test code ');
                        List<Batch_Error_Log__c> belList = new List<Batch_Error_Log__c>();
                        for(OrderItem o : orderProducts){
                            Batch_Error_Log__c bel = new Batch_Error_Log__c();
                            bel.Failure_Job_ID__c = bc.getJobID();
                            bel.Object_ID__c = o.id;
                            bel.Failure_Message__c = e.getMessage();
                            bel.Class_Name__c = 'SoftwareFulfilmentTaskBatch';
                            belList.add(bel);
                        }
                        insert belList;
                   }
                }
                
            }
            
        }
       
        
        
        
    }
    
     
    
    global void finish(Database.BatchableContext BC)
    
    {
    
                  
    
    }
    
    

}