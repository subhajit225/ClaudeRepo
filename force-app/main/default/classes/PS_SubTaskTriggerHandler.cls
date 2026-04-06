public class PS_SubTaskTriggerHandler {
	public static Boolean noRecurssion = false;
    public static void updateBillable(List<PS_SubTask__c> newPsTasks){
        List<PS_SubTask__c> updateSubTaskList = new List<PS_SubTask__c>();
        for(PS_SubTask__c sub : [select Id,Billable__c,Is_Billable__c from PS_SubTask__c where Id IN: newPsTasks]){
            sub.Billable__c = sub.Is_Billable__c;
            updateSubTaskList.add(sub);
        }
        if(!updateSubTaskList.isEmpty()){
            PS_SubTaskTriggerHandler.noRecurssion = true;
            update updateSubTaskList;
        }
    }
}