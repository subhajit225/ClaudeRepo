public class PS_TaskTriggerHelper{    
    public static Boolean stopOItemTgrPS_TaskTriggerHandler = false; 
    public static Set<String> permissionSetNameToCheck = new Set<String>{'RubrikProfessionalServicesOperationsNew','RubrikProfessionalServicesPMONew'};
    public static Boolean isPS_OPS_USER = false;
    public void updateHas_PSTaskInsert(List<PS_Task__c > newPsTasks){
        
        Set<String> orderItemId = new Set<String>();
        List<OrderItem> orderItemsList = new List<OrderItem>();
        List<OrderItem> updateorderItemsList = new List<OrderItem>();
        List<Id> relatedOrders = new List<Id>();
        List<Id> taskIds = new List<Id>();
         
        for(PS_Task__c task : newPsTasks){
            orderItemId.add(task.Order_Item__c);
            if(task.Task_Type__c == 'T&E' && task.Required_By_Id__c != null && task.Required_By_Id__c != '') {
                relatedOrders.add(task.Required_By_Id__c);
                taskIds.add(task.Id);
            }
                    }
        
        if(!orderItemId.isEmpty()){
            for(OrderItem orditem : [select Id,Has_PSTask__c from OrderItem where Id IN: orderItemId]){
                if(!orditem.Has_PSTask__c){
                    orditem.Has_PSTask__c = true;
                    updateorderItemsList.add(orditem);
                }
            }
        }
        if(!updateorderItemsList.isEmpty()){
            stopOItemTgrPS_TaskTriggerHandler = true; 
            update updateorderItemsList; 
        }
        
        if(relatedOrders.size() > 0){
            updateRelatedPSTask(relatedOrders, taskIds);
        }
    }
    //MKT24- UTM
    public void updateHas_PSTaskUpdate(List<PS_Task__c > newPsTasks, Map<Id, PS_Task__c > mapOldPsTasks){
        set<String> orderItemId = new Set<String>();
        List<OrderItem> orderItemsList = new List<OrderItem>();
        List<OrderItem> updateorderItemsList = new List<OrderItem>();
        Set<Id> taskIds = new Set<Id>();
        List<Id> taskIdsforrelaetdRecs = new List<Id>();
        for(PS_Task__c task : newPsTasks){
            taskIdsforrelaetdRecs.add(task.Id);
            PS_Task__c oldTaskInstance = (PS_Task__c)mapOldPsTasks.get(task.Id);
            system.debug('Not Started--'+task.Task_Status__c);
            system.debug('Not Started--'+oldTaskInstance.Task_Status__c);
            if(task.Task_Status__c == 'Open' && oldTaskInstance.Task_Status__c != task.Task_Status__c  && task.Task_Type__c == 'Migration'){
                taskIds.add(task.Id);
            }
            orderItemId.add(task.Order_Item__c);
        }
        for(PS_Task__c task : mapOldPsTasks.values()){
            orderItemId.add(task.Order_Item__c);
        }
        if(!orderItemId.isEmpty()){  
            for(OrderItem orditem : [select Id,Has_PSTask__c,(select Id from PS_Tasks__r) from OrderItem where Id IN: orderItemId]){
                if(orditem.PS_Tasks__r.size() == 0){
                    orditem.Has_PSTask__c = false;
                    updateorderItemsList.add(orditem);
                }else if(!orditem.Has_PSTask__c){
                    orditem.Has_PSTask__c = true;
                    updateorderItemsList.add(orditem);
                }
            }
        }
        if(!updateorderItemsList.isEmpty()){
            stopOItemTgrPS_TaskTriggerHandler = true; 
            update updateorderItemsList; 
        }
        if(!taskIds.isEmpty()){
            Set<Id> taskIdSet = new Set<Id>();
            List<PS_Task__c> psTaskList = [SELECT Id, (SELECT Id FROM Cases__r) FROM PS_Task__c WHERE Id =: taskIds];
            for(PS_Task__c eachTask : psTaskList) {
                if(eachTask.Cases__r == null || eachTask.Cases__r.size() == 0)
                    taskIdSet.add(eachTask.Id);
            }
            createCases(taskIdSet);
        }
        if(!taskIdsforrelaetdRecs.isEmpty()){
            updateRelatedPSTaskStatus(taskIdsforrelaetdRecs);
        }
        
    }
    
    public void updateHas_PSTaskDelete(Map<Id,PS_Task__c> mapOldPsTasks){
        set<String> orderItemId = new Set<String>();
        List<OrderItem> orderItemsList = new List<OrderItem>();
        List<OrderItem> updateorderItemsList = new List<OrderItem>();
        for(PS_Task__c task : mapOldPsTasks.values()){
            orderItemId.add(task.Order_Item__c);
        } 
        if(!orderItemId.isEmpty()){
            for(OrderItem orditem : [select Id,Has_PSTask__c,(select Id from PS_Tasks__r) from OrderItem where Id IN: orderItemId]){
                if(orditem.PS_Tasks__r.size() == 0){
                    orditem.Has_PSTask__c = false;
                    updateorderItemsList.add(orditem);
                }
            }
        }
        if(!updateorderItemsList.isEmpty()){
            stopOItemTgrPS_TaskTriggerHandler = true; 
            update updateorderItemsList; 
        }
    }
    
    //Hanlde all before insert trigger actions
    public void BeforeInsertHelper(List<PS_Task__c> newPsTasks){
        Map<String,Order> orderMap = getOrderMap(newPsTasks);
        Boolean hasRequiredPermission = doesUserHaveAnyPermissionSet(UserInfo.getUserId(), permissionSetNameToCheck);
        for(PS_Task__c task : newPsTasks){
            //Update end 6 months later based on start date
            if(task.Task_Start_Date__c != null && (task.Task_Type__c == 'Resident Engineer' || task.Task_Type__c == 'Resident Engineer-PD')){
                task.Task_End_date__c = task.Task_Start_Date__c.addmonths(Integer.valueOf(task.Consult_Quantity__c))-1; 
            }  
            if(task.Task_Type__c != null && (task.Task_Type__c.contains('Non-Billable') || task.Task_Type__c.contains('Non Billable')) ) {
                task.Sync_to_Net_Suite__c = 'No Sync Required';
            } else if( task.Task_Type__c != null && hasRequiredPermission && task.Order_Product__c == null){ task.addError('Non-billable tasks require a non-billable task type.');
            }  
            if(task.Account__c == null && orderMap.containsKey(task.Order__c)){
                task.Account__c = orderMap.get(task.Order__c).AccountId;
            }
        }   
    } 
    
    //Hanlde all before update trigger actions
    public void BeforeUpdateHelper(List<PS_Task__c> newPsTasks, Map<Id, PS_Task__c > mapOldPsTasks){
        Map<String,Order> orderMap = getOrderMap(newPsTasks);
        Map<Id,PS_Task__c> taskIds = new Map<Id,PS_Task__c>();
        Set<Id> setPSCompletedTask = new Set<Id>();
        Date todayDate = Date.today();
        Date cutOffDate = Date.newInstance( todayDate.year() , todayDate.month(), 25);
        Date dayAfterCutOffDate = cutOffDate.addDays(1);
        Map<Id,PS_Task__c> psTasksToBeValidated = new Map<Id,PS_Task__c>();
        Set<Id> setOfMigrationTaskId = new Set<Id>();
        List<String> allNonBillableTaskTypes = new List<String>{'Non-Billable (Product)','Non-Billable (PS)','Non-Billable (Sales)','Non-Billable (Expired)', 'Non-Billable Admin', 'Non-Billable CSAT','Resident Engineer', 'Resident Engineer-PD','Non-Billable PreSales'};
        Boolean hasRequiredPermission = doesUserHaveAnyPermissionSet(UserInfo.getUserId(), permissionSetNameToCheck);

        for(PS_Task__c task : newPsTasks){
            
            // Clear NS Sync Status Message when Sync is marked complete
            if (task.Sync_to_Net_Suite__c == 'Sync Complete' && mapOldPsTasks.get(task.Id).Sync_to_Net_Suite__c != 'Sync Complete') {
                task.NS_Sync_Status_Message__c = null;
            }
            
            if(task.Extended_End_date__c != mapOldPsTasks.get(task.Id).Extended_End_date__c && 
                (task.Task_Status__c == 'Closed Short'|| task.Task_Status__c == 'Completed')){
                    if(!allNonBillableTaskTypes.contains(task.Task_Type__c) && task.Task_Type__c != 'Migration'){
                        if(task.Billable_Hours_Expected__c <= task.Billable_Hours_Approved__c){ task.addError('The task cannot be reopened as the hours are consumed.');
                        }else if(task.Task_Status__c != 'Closed Short' && task.Billable_Hours_Expected__c <= task.Billable_Hours_Approved__c){ task.addError('Only Closed Short task can be reopened by extending the end date.');
                        }else{
                            psTasksToBeValidated.put(task.Id, task);
                        }
                    }else if(task.Task_Type__c == 'Migration'){
                        setOfMigrationTaskId.add(task.Id);
                        psTasksToBeValidated.put(task.Id, task);
                    }
            }
            if(task.Task_Type__c != null && (!task.Task_Type__c.contains('Non-Billable') && !task.Task_Type__c.contains('Non Billable')) && hasRequiredPermission && task.Order_Product__c == null && (!isPS_OPS_USER || (isPS_OPS_USER && task.Task_Status__c != 'Cancelled'))){ task.addError('Non-billable tasks require a non-billable task type.');
            } 
        }
        if(!psTasksToBeValidated.isEmpty()){
            validateReopeningOfTask(psTasksToBeValidated, setOfMigrationTaskId);
        }
        for(PS_Task__c task : newPsTasks ){
            //if( task.Task_Status__c == 'Cancelled' || (task.Task_Type__c != null && task.Task_Type__c.contains('Non-Billable'))) {taskIds.put(task.Id,task); task.Sync_to_Net_Suite__c = 'No Sync Required';continue;}
            if( task.Task_Type__c != null && (task.Task_Type__c.contains('Non-Billable') || task.Task_Type__c.contains('Non Billable') )) {
                taskIds.put(task.Id,task); 
                task.Sync_to_Net_Suite__c = 'No Sync Required';
                continue;
            }else if( task.Task_Status__c == 'Cancelled' && mapOldPsTasks.get(task.Id).Task_Status__c != 'Cancelled' && task.Task_Type__c != null && !task.Task_Type__c.contains('Non-Billable')) {
                taskIds.put(task.Id,task); 
                task.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                continue;
            }
            if(task.Task_Status__c == 'Cancelled'){ continue;
            }
            PS_Task__c oldTaskInstance = mapOldPsTasks.get(task.id);   
            if((task.Billable_Hours_Approved__c != oldTaskInstance.Billable_Hours_Approved__c || (task.Task_Start_Date__c != oldTaskInstance.Task_Start_Date__c && task.Task_Type__c == 'Resident Engineer') || 
               (task.Task_Status__c != oldTaskInstance.Task_Status__c && task.Task_Status__c == 'Closed Short') || (task.Extended_End_date__c != mapOldPsTasks.get(task.Id).Extended_End_date__c)) && trigger.isBefore){  
                //task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                   if(dayAfterCutOffDate == todayDate){ task.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                   }else{
                       task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                   }
            }
            if(task.Extended_End_date__c != mapOldPsTasks.get(task.Id).Extended_End_date__c){
                task.End_Date__c = null;   
            }
            if( trigger.isBefore){
               taskIds.put(task.Id,task); 
            }
            Date actualEndDate = task.Task_End_date__c;
            //Update end 6 months later based on start date
            if(task.Task_Start_Date__c != null && task.Task_Start_Date__c != mapOldPsTasks.get(task.Id).Task_Start_Date__c && (task.Task_Type__c == 'Resident Engineer' || task.Task_Type__c == 'Resident Engineer-PD')){
                task.Task_End_date__c = task.Task_Start_Date__c.addmonths(Integer.valueOf(task.Consult_Quantity__c))-1;
                actualEndDate = task.Task_Start_Date__c.addmonths(Integer.valueOf(task.Consult_Quantity__c))-1;
            }
            actualEndDate = task.Extended_End_date__c != null && actualEndDate < task.Extended_End_date__c ? task.Extended_End_date__c : actualEndDate;
            system.debug('actualEndDate___________________ '+actualEndDate);
            system.debug('Type___________________ '+task.Task_Type__c);
            system.debug('StartDate___________________ '+task.Task_Start_Date__c);
            system.debug('Status___________________ '+task.Task_Status__c );
            system.debug('Purchased Hours___________________ '+task.Billable_Hours_Expected__c);
            system.debug('Approved Hours___________________ '+task.Billable_Hours_Approved__c);
            Set<String> appliedConsult = new Set<String>();
            appliedConsult.add('Rubrik University'); 
            If(task.Task_Type__c != null && (appliedConsult.contains(task.Task_Type__c) || task.Task_Type__c.contains('Resident Engineer') || task.Task_Type__c == 'Install' || task.Task_Type__c == 'Consult' || task.Task_Type__c == 'Consult-Onsite' || task.Task_Type__c == 'Consult-Remote' || task.Task_Type__c == 'T&E' || task.Task_Type__c == 'Accelerator' || task.Project_Expiration_SKU__c)) {
                if(task.Task_Start_Date__c == null && task.Billable_Hours_Expected__c > task.Billable_Hours_Approved__c && task.Task_Status__c == 'Completed'){ task.Task_Status__c = 'Open'; 
                    system.debug('Inside Open:::::3');
                }else if(actualEndDate > system.today() && task.Billable_Hours_Expected__c > task.Billable_Hours_Approved__c && task.Task_Status__c == 'Closed Short'){
                    task.Task_Status__c = 'Open';
                } else if(task.Task_Start_Date__c == null && task.Billable_Hours_Expected__c > 0 && task.Billable_Hours_Expected__c <= task.Billable_Hours_Approved__c && task.Task_Status__c != 'Completed'){
                    task.Task_Status__c = 'Completed';
                    //task.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                    //task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                    if(dayAfterCutOffDate == todayDate){
                        task.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                    }else{
                        task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                    }
                    setPSCompletedTask.add( task.Id );
                    system.debug('Inside Open:::::4');
                } else if(task.Task_Start_Date__c != null && actualEndDate < system.today()) {
                    if( !task.Project_Expiration_SKU__c || ( task.Project_Expiration_SKU__c && ( task.Approved_Hours__c >= 100 || task.Line_Value__c == 0) ) || (task.Task_Type__c != null && task.Task_Type__c.contains('Resident Engineer'))) {
                        task.Task_Status__c = 'Completed';} else {task.Task_Status__c = 'Closed Short';}
                    setPSCompletedTask.add( task.Id );if( task.Task_Status__c != oldTaskInstance.Task_Status__c && ((task.Task_Status__c == 'Closed Short' || task.Task_Status__c == 'Completed')) ) { 
                        //task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                        if(dayAfterCutOffDate == todayDate){ task.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                        }else{
                            task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                        }
                    }
                	//task.End_Date__c = Date.today();
                } else if(task.Task_Start_Date__c != null && actualEndDate > system.today() && task.Task_Status__c == 'Completed' && task.Billable_Hours_Expected__c > task.Billable_Hours_Approved__c && task.Task_Type__c != 'T&E'){ task.Task_Status__c = 'Open'; 
                } else if(task.Approved_Hours__c < 100 && task.Task_Start_Date__c != null && task.Task_Start_Date__c <= system.today() && actualEndDate >= system.today() && (task.Task_Status__c == null || task.Task_Status__c == 'Completed' || task.Task_Status__c == 'Not Started')){ task.Task_Status__c = 'Open'; 
                } else if(task.Task_Type__c == 'Resident Engineer' && task.Task_Status__c ==  'Completed' && actualEndDate >= system.today()){ task.Task_Status__c = 'Open'; 
                }else if(task.Approved_Hours__c >= 100 && task.Task_Status__c !=  'Completed') {
                    if( task.Task_Type__c == 'Resident Engineer' || task.Task_Type__c == 'Resident Engineer-PD') {
                        if( actualEndDate >= system.today() ) {
                            if(task.Task_Start_Date__c > system.today()){
                                task.Task_Status__c = 'Not Started';
                            } else{
                                task.Task_Status__c = 'Open';
                            }
                        } else {
                            task.Task_Status__c = 'Completed';
                        }
                    } else {
                        task.Task_Status__c = 'Completed';
                    }
                    if(dayAfterCutOffDate == todayDate){ task.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                    }else{
                        task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                    }
                    //task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                    if( actualEndDate > system.today() ) {
                        setPSCompletedTask.add( task.Id );
                    }
                }else if(task.Approved_Hours__c < 100 && task.Task_Status__c == 'Completed') {task.Task_Status__c = 'Open';}
            }  
            
            if(task.Task_Type__c != null && task.Task_Type__c.contains('Migration') && task.Task_Status__c != mapOldPsTasks.get(task.Id).Task_Status__c && task.Task_Status__c=='Completed'){
                 //task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                if(dayAfterCutOffDate == todayDate){ task.Sync_to_Net_Suite__c = 'Sync to NetSuite';
                }else{
                    task.Sync_to_Net_Suite__c = ( System.today() > cutOffDate ) ? 'Queued for Net Suite Sync' : 'Sync to NetSuite';
                }
            }
            //Condtion Type add //
            if(task.Account__c == null && orderMap.containsKey(task.Order__c)){task.Account__c = orderMap.get(task.Order__c).AccountId;} 
        }     
        
        if( !setPSCompletedTask.isEmpty() ) {
            Map<Id, PS_Task__c> mapTriggerNew = new Map<Id, PS_Task__c>(newPsTasks);
            for(PS_Task__c objTask : [Select Id, (Select Id, Time_Entry_Date__c From PS_Time_Entries__r Where Billable__c = true and Is_Billable__c = true and Status__c ='Approved'  ORDER BY Time_Entry_Date__c DESC LIMIT 1) From PS_Task__c Where Id In:setPSCompletedTask ] ) {
                Date actualEndDate = (mapTriggerNew.get(objTask.Id).Extended_End_date__c != null && mapTriggerNew.get(objTask.Id).Extended_End_date__c > mapTriggerNew.get(objTask.Id).Task_End_date__c) ? mapTriggerNew.get(objTask.Id).Extended_End_date__c : mapTriggerNew.get(objTask.Id).Task_End_date__c;
                if(mapTriggerNew.get(objTask.Id).Hours_Consumed__c < 100){ mapTriggerNew.get(objTask.Id).End_Date__c = actualEndDate;
                }else{
                    if(objTask.PS_Time_Entries__r != null && objTask.PS_Time_Entries__r.isEmpty() == false && mapTriggerNew.get(objTask.Id).Task_Type__c != null && !mapTriggerNew.get(objTask.Id).Task_Type__c.contains('Resident Engineer')){ mapTriggerNew.get(objTask.Id).End_Date__c = objTask.PS_Time_Entries__r[0].Time_Entry_Date__c;
                    }else{
                        mapTriggerNew.get(objTask.Id).End_Date__c = actualEndDate;
                    }
                }
            }
        	//if( mapTriggerNew.get(objTask.Id).End_Date__c <= cutOffDate ) {mapTriggerNew.get(objTask.Id).Sync_to_Net_Suite__c = 'Sync to NetSuite';}
        } 
        
        Date date25th = Date.newInstance(System.now().year(), System.now().month(), 25);
        AggregateResult[] groupedResults = [select PS_Task__c taskId,  SUM(Hours_Spent__c) Total from PS_Time_Entry__c  where Billable__c = true and 
                                            Is_Billable__c = true and Status__c ='Approved' AND PS_Task__c IN: taskIds.keySet() AND Time_Entry_Date__c <=: date25th
                                            GROUP BY PS_Task__c ];
        Map<id,Decimal> psTaskMap = new Map<id,Decimal>();
       
        for (AggregateResult ar : groupedResults)  {
            Id taskId = (Id)ar.get('taskId');
            Decimal totalTime = (Decimal)ar.get('Total');
            psTaskMap.put(taskId ,totalTime );
        }
        for(PS_Task__c task : newPsTasks ){
            if(psTaskMap.containsKey(task.Id)){ task.Billable_Hours_locked__c = psTaskMap.get(task.Id);
            }else{
                task.Billable_Hours_locked__c =0;
            
            }
        
        }
        
    }

    public static Map<String,Order> getOrderMap(List<PS_Task__c> newPsTasks){
        Map<String,Order> orderMap = new Map<String,Order>();
        for(PS_Task__c task : newPsTasks){
            orderMap.put(task.Order__c, new Order());
        }
        for(Order order : [select OrderNumber,AccountId from Order where OrderNumber IN: orderMap.keySet()]){
            orderMap.put(order.OrderNumber, order);
        }
        return orderMap;
    }
    
    public static void createCases(Set<Id> taskIds){
        List<Case> cases = new List<Case>();
        Id digitalQueueId = [select Id,Name,DeveloperNAME  from Group where  Type = 'Queue' AND DeveloperName ='Unassigned_Cases' LIMIT 1].Id;
        for(PS_Task__c task : [SELECT Id, Name, Project__r.Account__c,Contact__c, Order_Product__c FROM PS_Task__c where id IN: taskIds]){
            cases.add(new Case(
                AccountId = task.Project__r.Account__c,
                ContactId = task.Contact__c,
                OwnerID = digitalQueueId,
                Priority = 'P3',
                Origin = 'PS Project',
                Subject = 'Go Refresh data migration request ('+task.Order_Product__c+')',
                Current_Status__c = System.label.Go_Refresh_Current_Steps,
                Next_Step__c = System.label.Go_Refresh_Next_Steps,
                Platform__c = 'CDM',
                Product_Area__c = 'Cluster Management',
                Problem_Type__c = 'Rubrik CDM Appliance - Cluster',
                Sub_Component__c = 'Decommission',
                Resolution__c = 'Operational Assistance',
                Description = System.label.Go_Refresh_Description,
                PS_Task__c = task.Id
            ));
        }
        insert cases;
    }
    
    public static void updateRelatedPSTask(List<Id> orderIds, List<Id> taskIds){
        system.debug('orderIds_____________________________________ '+orderIds);
        Map<Id, Id> orderTaskMap = new Map<Id, Id>();
        for(OrderItem OrderItm : [SELECT Id, (SELECT Id FROM PS_Tasks__r LIMIT 1) FROM OrderItem WHERE id IN : orderIds]){
                        If(OrderItm.PS_Tasks__r.size() > 0)
                orderTaskMap.put(OrderItm.Id, OrderItm.PS_Tasks__r[0].Id);
        }
        if(orderTaskMap.keyset().Size() > 0){
            List<PS_Task__c> taskToUpdate = new List<PS_Task__c>();
            List<Id>  taskListToUpdate = new List<Id>();
            for(PS_Task__c task : [SELECT Id, Task_Type__c, Required_By_Id__c, Related_PS_Task__c FROM PS_Task__c 
                WHERE Task_Type__c = 'T&E' AND Required_By_Id__c != null AND Id IN : taskIds]){
                if(orderTaskMap.containsKey(task.Required_By_Id__c)) {
                    task.Related_PS_Task__c = orderTaskMap.get(task.Required_By_Id__c);
                    taskListToUpdate.add(orderTaskMap.get(task.Required_By_Id__c));
                    taskToUpdate.add(task);
                }
            }    
            if(taskToUpdate.Size() > 0){
                update taskToUpdate;
                updateRelatedPSTaskStatus(taskListToUpdate);  
            }             
        }
    }

    public static void updateRelatedPSTaskStatus(List<Id> taskIds){
        List<PS_Task__c> taskToUpdate = new List<PS_Task__c>();
        for(PS_Task__c task : [SELECT Id, Related_PS_Task__r.End_Date__c, Task_End_date__c, Task_Start_Date__c, Task_Status__c, Related_PS_Task__c, Related_PS_Task__r.Task_Start_Date__c, Related_PS_Task__r.Task_End_date__c, Related_PS_Task__r.Task_Status__c,Extension_Reason__c,Related_PS_Task__r.Extension_Reason__c,Extended_End_date__c,Sync_to_Net_Suite__c,Related_PS_Task__r.Extended_End_date__c,Related_PS_Task__r.Sync_to_Net_Suite__c
                               FROM PS_Task__c WHERE Task_Type__c = 'T&E' AND Related_PS_Task__c IN : taskIds]){
                                   if(task.Task_Status__c != task.Related_PS_Task__r.Task_Status__c || task.Extended_End_date__c !=task.Related_PS_Task__r.Extended_End_date__c || 
                                      task.Task_Start_Date__c != task.Related_PS_Task__r.Task_Start_Date__c || (task.Sync_to_Net_Suite__c !=task.Related_PS_Task__r.Sync_to_Net_Suite__c && (task.Related_PS_Task__r.Sync_to_Net_Suite__c =='Sync to NetSuite' ||task.Related_PS_Task__r.Sync_to_Net_Suite__c =='Queued for Net Suite Sync'  || task.Related_PS_Task__r.Sync_to_Net_Suite__c =='No Sync Required' ))
                                     )
                                   {
                                       task.Task_Status__c = task.Related_PS_Task__r.Task_Status__c;
                                       task.End_Date__c = task.Related_PS_Task__r.End_Date__c;
                                       task.Extended_End_date__c = task.Related_PS_Task__r.Extended_End_date__c;
                                       task.Extension_Reason__c = task.Related_PS_Task__r.Extension_Reason__c;
                                       task.Sync_to_Net_Suite__c = task.Related_PS_Task__r.Sync_to_Net_Suite__c;
                                       
                                       task.Task_Start_Date__c = task.Related_PS_Task__r.Task_Start_Date__c;
                                       task.Task_End_date__c = task.Related_PS_Task__r.Task_End_date__c;
                                       taskToUpdate.add(task);
                                   }
                               }   
        if(taskToUpdate.Size() > 0) update taskToUpdate;
    }
    public static void validateReopeningOfTask(Map<Id,PS_Task__c> newPsTasksMap, Set<Id> setOfMigrationTaskId){
        if(!setOfMigrationTaskId.isEmpty()){
            for(Case cs: [SELECT Id, PS_Task__c, CreatedDate, Status FROM Case WHERE PS_Task__c IN: setOfMigrationTaskId ORDER BY CreatedDate]){
                if(setOfMigrationTaskId.contains(cs.PS_Task__c)){
                    PS_Task__c task = newPsTasksMap.get(cs.PS_Task__c);
                    if(task.Task_End_date__c > cs.CreatedDate.date()){
                        task.addError('The task cannot be reopened as the task was expired after a support case was associated with it.');
                        newPsTasksMap.remove(cs.PS_Task__c);
                        setOfMigrationTaskId.remove(cs.PS_Task__c);
                    }else if(cs.Status == 'Closed'){
                        task.addError('The task cannot be reopened as the associated support case was closed.');
                        newPsTasksMap.remove(cs.PS_Task__c);
                        setOfMigrationTaskId.remove(cs.PS_Task__c);
                    }
                }
            }
        }
        Boolean hasPermission = FeatureManagement.checkPermission('Allow_PSO_to_Reopen_a_Completed_Task');
        for(PS_Task__c task: newPsTasksMap.values()){
            if(!hasPermission){
                task.addError('You do not have the neccessary permission to Reopen a Completed Task');
            }
        }
    }

    public static Boolean doesUserHaveAnyPermissionSet(Id userId, Set<String> permissionSetNames) {
        Set<String> permissionSetGroupName =  new Set<String>{'PSG_Professional_Services_OPS','PSG_Professional_Services_PMO'};
        List<PermissionSetAssignment> allAssignments = [ SELECT PermissionSet.Name, PermissionSet.PermissionSetGroup.DeveloperName FROM PermissionSetAssignment WHERE AssigneeId = :userId];
        for (PermissionSetAssignment psa : allAssignments) {
            if (permissionSetNames.contains(psa.PermissionSet.Name) || permissionSetGroupName.contains(psa.PermissionSet.PermissionSetGroup.DeveloperName)) {
                if(psa.PermissionSet.Name == 'RubrikProfessionalServicesOperationsNew' || psa.PermissionSet.Name == 'PSG_Professional_Services_OPS'){
                    isPS_OPS_USER = true;
                }
                return true;
            }
        }
        return false;
    }   
}