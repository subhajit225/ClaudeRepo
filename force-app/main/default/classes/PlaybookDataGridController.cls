/**
 * @author Abhishek Mahajan
 * @date 25th September 2023
 * @description Controller to playbookDataGrid
 */
public class PlaybookDataGridController {
    @AuraEnabled
    public static List<Sub_Task__c> getPlaybooks(String accountId){
		List<Sub_Task__c> subTasks = new List<Sub_Task__c>();
        for(Playbook__c pb : [SELECT Id, Name, completion_percentage__c, Total_Sub_Tasks__c, Total_Sub_Tasks_Completed__c FROM Playbook__c WHERE Account__c = :accountId AND Total_Sub_Tasks__c = 0]){
            subTasks.add(new Sub_Task__c(Playbook__c = pb.Id, Playbook__r = pb));
        }
        return subTasks;        
    }

    /**
     * @description Retrieves List of Subtasks for given account
     * 
     * @param accountId Id of Account
     * @return List of Subtasks
     * @throws AuraHandledException If an error occurs.
     */
    @AuraEnabled//(cacheable=true)
    public static List<Sub_Task__c> getTasksBySubtasks(String accountId) {
        List<Sub_Task__c> subTasks = new List<Sub_Task__c>();
        try {
            subTasks = [SELECT Id,Name,completion_percentage__c, Playbook__r.Name, Playbook__r.completion_percentage__c,Playbook__r.Total_Sub_Tasks__c,Playbook__r.Total_Sub_Tasks_Completed__c, (SELECT Id,Name, Due_Date__c, Completed__c, Description__c FROM Checklists__r) FROM Sub_Task__c WHERE Playbook__r.Account__c =:accountId];
        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while deleting the record: Please contact your administrator');
        }
        subTasks.addAll(getPlaybooks(accountId));
        return subTasks;
    }

    /**
     * @description deletes a checklist
     * 
     * @param recordId id of checklist to be deleted
     * @throws AuraHandledException If an error occurs.
     */
    @AuraEnabled
    public static void deleteTask(String recordId) {
        try {
            Checklist__c[] tasksToDelete = [SELECT Id FROM Checklist__c WHERE Id = :recordId LIMIT 1];
            
            if (!tasksToDelete.isEmpty()) {
                delete tasksToDelete;
            } else {
                throw new AuraHandledException('Task not found. Please refresh data.');
            }

        } catch (Exception e) {
            throw new AuraHandledException('An error occurred while deleting the record: Please contact your administrator');
        }
    }
}