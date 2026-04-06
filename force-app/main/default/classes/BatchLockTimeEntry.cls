/* 
* Class Name :- BatchLockTimeEntry
* Author :- Shiva
* Created-Date :- 22-06-2021
* Description : This is a apex class that implement Batch and Schedule interface.
				which will run on every 25 and will block the % completed till 25.
* Test_Class  : BatchLockTimeEntry_Test
// ********************Change Logs ******************************************************************************************************************************************************
* 
* Modified By          Date                     Description 
* 
* 
// ********************Change Logs Ends**************************************************************************************************************************************************
*/
public class BatchLockTimeEntry implements Database.Batchable<sObject>, Schedulable{
    public String query;
    public BatchLockTimeEntry (String query){
        this.query = query;
    }
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchLockTimeEntry(query));
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if(query == ''){
            query = 'select id,Billable_Hours_locked__c from Ps_Task__c where LastModifiedDate >= LAST_N_DAYS:31 AND Approved_Hours__c != 0';
        }
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Ps_Task__c> scope){
        Map<Id,Ps_Task__c> taskIds = new Map<Id,Ps_Task__c>();
        List<Ps_Task__c> taskList = new List<Ps_Task__c>();
        for(Ps_Task__c psTask : scope){
            taskIds.put(psTask.Id,psTask);
        }
        Date date25th = Date.newInstance(System.now().year(), System.now().month(), 25);

        AggregateResult[] groupedResults = [select PS_Task__c taskId,  SUM(Hours_Spent__c) Total from PS_Time_Entry__c  where Billable__c = true and 
                                            Is_Billable__c = true and Status__c ='Approved' AND PS_Task__c IN: taskIds.keyset() AND Time_Entry_Date__c <=: date25th
                                            GROUP BY PS_Task__c ];
        for (AggregateResult ar : groupedResults)  {
            Id taskId = (Id)ar.get('taskId');
            Decimal totalTime = (Decimal)ar.get('Total');
            if(taskIds.get(taskId).Billable_Hours_locked__c != totalTime){
                taskList.add(new PS_task__c(id = taskId,Billable_Hours_locked__c = totalTime));
            }
        }
        
        database.update(taskList,false);
    }    
    public void finish(Database.BatchableContext bc){
    }
}