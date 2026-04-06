global class MigratePSDataBatch implements Database.Batchable<sObject> {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        list<string> projectIds = new list<string>();
        string query;
        if(label.Bulk_Update_Project_Id == 'All'){
             query = 'SELECT Id FROM PS_Project__c';
        }else {
           projectIds = label.Bulk_Update_Project_Id.split(',');
            query = 'SELECT Id FROM PS_Project__c WHERE ID IN : projectIds';
        }
        system.debug('query___________ '+ query);
        return Database.getQueryLocator(query);
    }
    
    global void execute (Database.BatchableContext bc, List<PS_Project__c> scope) {
        Map<Id, PS_Task__c> allTaskMap = new Map<Id, PS_Task__c>([SELECT Id, Billable_Hours_Expected__c, Comments__c, CSAT__c, Order_Item__c, Project__c, Consult_Quantity__c,
                                    Special_Handling_Instructions__c, End_Date__c, Task_End_date__c,
                                    Task_Label__c, Task_Start_Date__c, Task_Status__c,
                                    Task_Subtype__c, Task_Type__c, Task_Unique_Id__c FROM PS_Task__c WHERE Project__c IN : scope]);

        
        List<PS_Time_Entry__c> PSTEList = [SELECT Id, PS_Task__c, Assignee__c, PS_Subtask__c, PS_Subtask__r.PS_Assignee__c, PS_Subtask__r.Subtask_Type__c, 
                                           PS_Subtask__r.Task_Type__c, PS_Subtask__r.Task__r.Task_Type__c, PS_Subtask__r.Task__c,
                                           PS_Subtask__r.Task__r.Task_Subtype__c, TE_Unique_Id__c FROM PS_Time_Entry__c 
                                           WHERE PS_Subtask__c != null AND PS_Subtask__r.Task__r.Project__c IN : scope];
                                           
        map<Id, map<string, List<PS_Time_Entry__c>>> finalMap = new map<Id, map<string, List<PS_Time_Entry__c>>>();
        list<PS_Task__c> newTask = new list<PS_Task__c>();
        list<PS_Time_Entry__c> teListToUpdate = new list<PS_Time_Entry__c>();
        map<id, set<string>> newTaskIdwithTypeMap = new map<id, set<string>>();
        integer key = 0;
        map<string, string> TaskIdTypewithUniqueIdMap = new map<string, string>();
        for(PS_Time_Entry__c pste : PSTEList){
            key++;
            pste.Assignee__c = pste.PS_Subtask__r.PS_Assignee__c;
            String type;
            String subType;
            String TaskIdType;
            if(pste.PS_Subtask__r.Subtask_Type__c == 'Install' || (pste.PS_Subtask__r.Task_Type__c == 'Install' && pste.PS_Subtask__r.Subtask_Type__c == null)){
                type = 'Install';
            }else if(pste.PS_Subtask__r.Subtask_Type__c == 'Install (Non billable)'){
                type = 'Install - Non Billable';
            }else if(pste.PS_Subtask__r.Subtask_Type__c == 'Advanced Configuration' || pste.PS_Subtask__r.Subtask_Type__c == 'Automation' || pste.PS_Subtask__r.Subtask_Type__c == 'Deep-Dive Training' || pste.PS_Subtask__r.Subtask_Type__c == 'Onsite Resident' || pste.PS_Subtask__r.Subtask_Type__c == 'Documentation' || (pste.PS_Subtask__r.Task_Type__c == 'Consult' && pste.PS_Subtask__r.Subtask_Type__c == null)){
                type = 'Consult';
            }else if(pste.PS_Subtask__r.Subtask_Type__c == 'Consult (Non billable)'){
                type = 'Consult - Non Billable';
            }else if(pste.PS_Subtask__r.Subtask_Type__c == 'Admin' || pste.PS_Subtask__r.Subtask_Type__c == 'Travel' || pste.PS_Subtask__r.Subtask_Type__c == 'PTO' || pste.PS_Subtask__r.Subtask_Type__c == 'Partner Enablement' || (pste.PS_Subtask__r.Task_Type__c == 'Admin' && pste.PS_Subtask__r.Subtask_Type__c == null)) {
                type = 'Admin-';
                if(pste.PS_Subtask__r.Subtask_Type__c == 'Travel'){
                    subType = 'Travel';
                    type += 'Travel';
                }else if(pste.PS_Subtask__r.Subtask_Type__c == 'PTO'){
                    subType = 'PTO';
                    type += 'PTO';
                }else if(pste.PS_Subtask__r.Subtask_Type__c == 'Partner Enablement'){
                    subType = 'Enablement';
                    type += 'Enablement';
                }else {
                    subType = 'Internal';
                    type += 'Internal';
                }
            }else{
                type = 'CSAT';
            }
            TaskIdType = pste.PS_Subtask__r.Task__c+type;
            //system.debug( type+' __________type_____________________ '+TaskIdType);
            //system.debug('finalMap________ '+finalMap);
            if(finalMap.containsKey(pste.PS_Subtask__r.Task__c)){
                map<string, List<PS_Time_Entry__c>> TaskTypeWithTEMap = finalMap.get(pste.PS_Subtask__r.Task__c);
                //system.debug('TaskTypeWithTEMap__________ '+TaskTypeWithTEMap);
                if(TaskTypeWithTEMap.containsKey(TaskIdType)){
                    set<string> typeSet = new set<string>();
                    if(newTaskIdwithTypeMap.containsKey(pste.PS_Subtask__r.Task__c)) {
                        typeSet = newTaskIdwithTypeMap.get(pste.PS_Subtask__r.Task__c);
                    }
                    //typeSet.add(type);
                    //system.debug('typeSet________ '+typeSet);
                    //newTaskIdwithTypeMap.put(pste.PS_Subtask__r.Task__c, typeSet);
                    
                    list<PS_Time_Entry__c> TEList = TaskTypeWithTEMap.get(TaskIdType);
                    system.debug(pste.Id+' ____________'+ key+ '_______________ '+pste.PS_Subtask__r.Task__c+' _________________ '+typeSet);
                    if(!typeSet.contains(type)){
                        pste.PS_Task__c = pste.PS_Subtask__r.Task__c;
                        pste.New_Task_Id__c = pste.PS_Subtask__r.Task__c;
                    }
                    //system.debug('TaskIdTypewithUniqueIdMap ________ '+TaskIdTypewithUniqueIdMap);
                    if(TaskIdTypewithUniqueIdMap.containsKey(pste.PS_Subtask__r.Task__c+type)){
                        pste.TE_Unique_Id__c = TaskIdTypewithUniqueIdMap.get(pste.PS_Subtask__r.Task__c+type);
                    }
                    TEList.add(pste);
                    //system.debug('TEList ________ '+TEList);
                    teListToUpdate.add(pste);
                    //system.debug('teListToUpdate ________ '+teListToUpdate);
                    TaskTypeWithTEMap.put(TaskIdType, TEList);
                    //system.debug('TaskTypeWithTEMap ________ '+TaskTypeWithTEMap);
                }else{
                    PS_Task__c task = allTaskMap.get(pste.PS_Subtask__r.Task__c).clone(false, false, false, false);
                    task.Task_Unique_Id__c = string.ValueOf(key);
                    TaskIdTypewithUniqueIdMap.put(pste.PS_Subtask__r.Task__c+type, string.ValueOf(key));
                    task.Task_Type__c = type;
                    if(type.contains('Admin-')){
                        task.Task_Subtype__c = subType;
                        task.Task_Type__c = 'Admin';
                    }
                    newTask.add(task);
                    set<string> typeSet = new set<string>();
                    //system.debug('newTaskIdwithTypeMap2 ________ '+newTaskIdwithTypeMap);
                    if(newTaskIdwithTypeMap.containsKey(pste.PS_Subtask__r.Task__c)){
                        typeSet = newTaskIdwithTypeMap.get(pste.PS_Subtask__r.Task__c);
                    }
                    typeSet.add(type);
                    newTaskIdwithTypeMap.put(pste.PS_Subtask__r.Task__c, typeSet);
                    list<PS_Time_Entry__c> TEList = new list<PS_Time_Entry__c>();
                    system.debug(pste.Id+' _____________________________222222222222222222____________________________________ '+pste.PS_Subtask__r.Task__c);
                    pste.PS_Task__c = pste.PS_Subtask__r.Task__c;
                    pste.New_Task_Id__c = pste.PS_Subtask__r.Task__c;
                    //system.debug('TaskIdTypewithUniqueIdMap2 ________ '+TaskIdTypewithUniqueIdMap);
                    if(TaskIdTypewithUniqueIdMap.containsKey(pste.PS_Subtask__r.Task__c+type)){
                        pste.TE_Unique_Id__c = TaskIdTypewithUniqueIdMap.get(pste.PS_Subtask__r.Task__c+type);
                    }                               
                    TEList.add(pste);
                    //system.debug('TEList ________ '+TEList);
                    teListToUpdate.add(pste);
                    //system.debug('teListToUpdate ________ '+teListToUpdate);
                    TaskTypeWithTEMap.put(TaskIdType, TEList);
                    //system.debug('TaskTypeWithTEMap ________ '+TaskTypeWithTEMap);
                    
                }
                finalMap.put(pste.PS_Subtask__r.Task__c, TaskTypeWithTEMap);
                //system.debug('finalMap 2222 ________ '+finalMap);
            }else{
                map<string, List<PS_Time_Entry__c>> TaskTypeWithTEMap = new map<string, List<PS_Time_Entry__c>>();
                list<PS_Time_Entry__c> TEList = new list<PS_Time_Entry__c>();
                system.debug(pste.Id+' ___________________________11111111111111______________________________________ '+pste.PS_Subtask__r.Task__c);
                pste.PS_Task__c = pste.PS_Subtask__r.Task__c;
                pste.New_Task_Id__c = pste.PS_Subtask__r.Task__c;
                //system.debug('TaskIdTypewithUniqueIdMap 3333________ '+TaskIdTypewithUniqueIdMap);
                if(TaskIdTypewithUniqueIdMap.containsKey(pste.PS_Subtask__r.Task__c+type)){
                    pste.TE_Unique_Id__c = TaskIdTypewithUniqueIdMap.get(pste.PS_Subtask__r.Task__c+type);
                }
                PS_Task__c task = new PS_Task__c(
                    Id = pste.PS_Subtask__r.Task__c,
                    Task_Type__c = type
                );
                if(type.contains('Admin-')){
                    task.Task_Subtype__c = subType;
                    task.Task_Type__c = 'Admin';
                }
                set<string> typeSet = new set<string>();
                //system.debug('newTaskIdwithTypeMap 3333________ '+newTaskIdwithTypeMap);
                /*if(newTaskIdwithTypeMap.containsKey(pste.PS_Subtask__r.Task__c)){
                    typeSet = newTaskIdwithTypeMap.get(pste.PS_Subtask__r.Task__c);
                }
                typeSet.add(type);
                newTaskIdwithTypeMap.put(pste.PS_Subtask__r.Task__c, typeSet);*/
                newTask.add(task);
                TEList.add(pste);
                teListToUpdate.add(pste);
                TaskTypeWithTEMap.put(TaskIdType, TEList);
                finalMap.put(pste.PS_Subtask__r.Task__c, TaskTypeWithTEMap);
            }
        }
        //system.debug('newTask ______________'+newTask.size());
        //system.debug('teListToUpdate ______________'+teListToUpdate.size());
        //system.debug('Task Count _________ '+finalMap.keyset().size());
        
        if(!newTask.IsEmpty()) upsert newTask;
        
        Map<string, Id> uniqueIDToTaskIdMap = new Map<string, Id>();
        for(PS_Task__c task : newTask){
            //system.debug('task _______' +task);
            if(task.Task_Unique_Id__c != null)
                uniqueIDToTaskIdMap.put(task.Task_Unique_Id__c, task.id);
        }
        //system.debug('uniqueIDToTaskIdMap 4444________ '+uniqueIDToTaskIdMap);
        for(PS_Time_Entry__c te : teListToUpdate){
            system.debug(te.TE_Unique_Id__c + ' _______ ' +uniqueIDToTaskIdMap.get(te.TE_Unique_Id__c));
            If(te.TE_Unique_Id__c != null && uniqueIDToTaskIdMap.containsKey(te.TE_Unique_Id__c)){
                te.PS_Task__c = uniqueIDToTaskIdMap.get(te.TE_Unique_Id__c);
            }
            //system.debug('TE _______' +te);
        }
        if(!teListToUpdate.IsEmpty()) update teListToUpdate;
        
    }
    
    global void finish(Database.BatchableContext bc){
        system.debug('__________ FINISH ________________ ');
    }    
}