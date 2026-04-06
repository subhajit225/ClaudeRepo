public class AssignTasksCmpController{
    @AuraEnabled
    public static List<PSTaskWrapper> getPsTask(String Projid){
        String taskNamePostFix = '';
        List<PSTaskWrapper> PsTaskWrapperList = new List<PSTaskWrapper>();
        for(PS_Task__c tsk :[SELECT Id,Name,Order_Item__r.order.ShippingCity,Order_Item__r.order.ShippingCountryCode,Order_Item__r.order.ShippingStateCode,
                             Task_Type__c,Order_Item__r.Order.OrderNumber
                             FROM PS_Task__c
                             WHERE Project__c =: id.valueof(Projid)]){
                                 taskNamePostFix = '';
                                 if(tsk.Order_Item__r.order.ShippingCity != null ) {
                                     taskNamePostFix += '(' +tsk.Order_Item__r.order.ShippingCity;
                                     system.debug('taskname000--'+taskNamePostFix);
                                 }
                                 if(tsk.Order_Item__r.order.ShippingCountryCode != null && (tsk.Order_Item__r.order.ShippingCountryCode != 'US' && tsk.Order_Item__r.order.ShippingCountryCode != 'CA')){
                                     if(taskNamePostFix == '') {
                                         taskNamePostFix += '('+tsk.Order_Item__r.order.ShippingCountryCode;
                                     }
                                     else {
                                         taskNamePostFix +=  '-'+tsk.Order_Item__r.order.ShippingCountryCode;
                                     }
                                     system.debug('taskname111--'+taskNamePostFix);
                                 }
                                 else {
                                     system.debug('taskname222--'+taskNamePostFix);
                                     if(taskNamePostFix == '') {
                                         taskNamePostFix += '('+tsk.Order_Item__r.order.ShippingStateCode;
                                     }
                                     else {
                                         taskNamePostFix +=  +'-'+tsk.Order_Item__r.order.ShippingStateCode;
                                     }
                                 }
                                 if(taskNamePostFix.contains('(')) {
                                     taskNamePostFix = taskNamePostFix + ')';
                                 }
                                 
                                 String taskName = tsk.Name+'-'+string.valueOf(tsk.Task_Type__c);
                                 if(!string.isBlank(tsk.Order_Item__r.Order.OrderNumber)){
                                     taskName = taskName+'-'+tsk.Order_Item__r.Order.OrderNumber;
                                 }
                                 if(!string.isBlank(taskNamePostFix)){
                                     taskName = taskName+'-'+taskNamePostFix;
                                 }
                                 PSTaskWrapper wrap = new PSTaskWrapper();
                                 wrap.TaskName = taskName;
                                 wrap.Id = tsk.Id;
                                 wrap.selectAll = false;
                                 PsTaskWrapperList.add(wrap);
                                 
                             }
        return PsTaskWrapperList;
    }
    @AuraEnabled
    public static List<PS_SubTask__c> getAllPsSubTask(String Projid){
        List<PS_SubTask__c> PSSTList = new List<PS_SubTask__c>();
        Set<String> uniqueSubtasksSet = new Set<string>();
        string str ='';
        for(PS_SubTask__c ps : [SELECT Id,Name,Task__c,Subtask_Type__c FROM PS_SubTask__c WHERE Project_ID__c =: id.valueof(Projid)]){
            str = ps.Task__c+'-'+ps.Subtask_Type__c;
            if(uniqueSubtasksSet.isEmpty() || !uniqueSubtasksSet.contains(str)){
                uniqueSubtasksSet.add(Str);
                PSSTList.add(ps);
            }
        }  
        system.debug('@@ getAllPsSubTask '+PSSTList);
        return PSSTList;
    }
    @AuraEnabled
    public static List<PSSubTaskWrapper> getPsSubTask(String TaskId, List<string> subTaskIds){
        List<PSSubTaskWrapper> PsWrapperList = new List<PSSubTaskWrapper>();
        PS_SubTask__c PsSub ;
        if(!subTaskIds.isEmpty()){
            for(PS_SubTask__c PSST :[SELECT id,Name,Task__c,Task__r.Name,Subtask_Type__c,
                                     Task_Type__c,Is_Billable__c
                                     FROM PS_SubTask__c
                                     WHERE Task__c =: id.valueof(TaskId) AND Id IN: subTaskIds]){
                                         PsSub = new PS_SubTask__c();
                                         PSSubTaskWrapper PSSTW = new PSSubTaskWrapper();
                                         PSSTW.SubtaskType = PSST.Subtask_Type__c;
                                         PSSTW.TaskType = PSST.Task_Type__c;
                                         PSSTW.TaskName = PSST.Task__r.Name;
                                         PSSTW.Id = PSST.id;
                                         PSSTW.Selected = false;
                                         
                                         PsWrapperList.add(PSSTW);
                                     }
        }
        system.debug('@@ getPsSubTask '+PsWrapperList);
        return PsWrapperList;
    }
    
    @AuraEnabled
    public static String assignSubtasks(String userid, String selectedsubtaskid){      
        List<Id> subtaskids =(List<Id>)System.JSON.deserialize(selectedsubtaskid, List<Id>.class);
        List<PS_SubTask__c> toInsertNewPSSubTaskList = new List<PS_SubTask__c>();
        List<PS_SubTask__c> PSSubTaskList = [SELECT Id, PS_Assignee__c,Task__c,Task_Type__c,
                                             Subtask_End_Date__c,Subtask_Start_Date__c,Subtask_Type__c,
                                             Hours_logged__c,Project_ID__c 
                                             FROM PS_SubTask__c WHERE Id IN : subtaskids ];
        if(PSSubTaskList != null){
            for(Id UsrId : (List<Id>)System.JSON.deserialize(userid, List<id>.class)){
                system.debug('UsrId = '+UsrId);
                for(PS_SubTask__c originalSubtask: PSSubTaskList){
                    PS_SubTask__c sub = new PS_SubTask__c();
                    sub.Task__c = originalSubtask.Task__c;
                    sub.PS_Assignee__c = Id.valueOf(UsrId);
                    sub.Subtask_End_Date__c = originalSubtask.Subtask_End_Date__c;
                    sub.Subtask_Start_Date__c = originalSubtask.Subtask_Start_Date__c;
                    sub.Task_Type__c = originalSubtask.Task_Type__c;
                    sub.Subtask_Type__c = originalSubtask.Subtask_Type__c;
                    sub.Hours_logged__c = originalSubtask.Hours_logged__c;
                    //sub.Billable__c = originalSubtask.Billable__c;
                    //sub.Include_in_Utilization__c = originalSubtask.Billable__c;
                    toInsertNewPSSubTaskList.add(sub);
                }
            }
        }
        if(!toInsertNewPSSubTaskList.isEmpty()){
            insert toInsertNewPSSubTaskList;
        }
        return 'success';
    }
    
    @testVisible
    class PSTaskWrapper{
        public @AuraEnabled string TaskName;
        public @AuraEnabled string Id;
        public @AuraEnabled boolean selectAll;
    }
    
    @testVisible
    class PSSubTaskWrapper{
        public @AuraEnabled String PsSubTask;
        public @AuraEnabled boolean Selected;
        public @AuraEnabled string Id;
        public @AuraEnabled string TaskName;
        public @AuraEnabled string TaskType;
        public @AuraEnabled string SubtaskType;
    }
}