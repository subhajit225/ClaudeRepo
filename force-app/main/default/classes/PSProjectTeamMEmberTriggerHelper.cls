public class PSProjectTeamMEmberTriggerHelper {
    
    public static void cleanTimeEntryRecord(Id projId, Id UserId) {
        //Check if there is any other memeber record on the same project
        List<PS_Project_Team_Member__c> existingTeamMember = [SELECT Id, PS_Project__c FROM PS_Project_Team_Member__c 
                                                              WHERE PS_Project__c =: projId AND Team_Member__c= :UserId];
        system.debug(existingTeamMember.size()+' ____existingTeamMember____ '+existingTeamMember);
        
        if(existingTeamMember.isEmpty()) {
            //fetch all TE on the project
            list<PS_Time_Entry__c> allTimeEntry = [SELECT Id, Assignee__c, PS_Task__c, PS_Task__r.Project__c, Status__c 
                                                   FROM PS_Time_Entry__c WHERE 
                                                   PS_Task__r.Project__c =: projId AND 
                                                   Assignee__c = :UserId AND 
                                                   Status__c != 'Approved'];
            system.debug(allTimeEntry.size()+' ____eallTimeEntry____ '+allTimeEntry);
            if(!allTimeEntry.isEmpty()) 
                delete allTimeEntry;
        }  
    }
    
}