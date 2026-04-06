/**
 * @author Abhishek Mahajan
 * @date 2023-08-15
 * @description Controller to playBooktemplates
 */
public class PlaybookTemplatesController {
    /**
     * @description Retrieves a list of playbook templates that are not associated with the given Account.
     * 
     * @param recordId The ID of the Account for which playbook templates are requested.
     * @return A list of playbook templates not already used for Account.
     */
    @AuraEnabled
    public static List<Playbook_Template__c> getPlaybookTemplates() {
        return [SELECT Id, Name FROM Playbook_Template__c WHERE Active__c = true];
    }

    /**
     * Creates playbook records along with their sub-tasks and checklists.
     * 
     * @description Associates provided templates with the given account creating playbooks, Sub-tasks and checklists
     * @param template Playbook Template
     * @param title Title of Playbook
     * @param accountId The ID of the account associated with the playbooks.
     * @throws DmlException If an error occurs during record insertion.
     */
    @AuraEnabled
    public static void createPlayBookRecords(String templateId, String title, String accountId) {
        Playbook_Template__c  template =  [SELECT Id, Name FROM Playbook_Template__c WHERE Id =: templateId];
        List<Playbook__c> playbooks = new List<Playbook__c>();
        List<Sub_Task__c> subTasks = new List<Sub_Task__c>();
        List<Checklist__c> checklists = new List<Checklist__c> ();
        Map<String,List<Playbook_Sub_Task__c>> playbookToSubTasks = new  Map<String,List<Playbook_Sub_Task__c>>();
        Map<String,Playbook_Sub_Task__c> masterlabelToSubTasks = new  Map<String,Playbook_Sub_Task__c>();

        playbooks.add(new Playbook__c(Name = title, Playbook_Template__c=template.Name, Account__c = accountId));
        insert playbooks;

        for(Playbook_Sub_Task__c st : [SELECT Name,Playbook_Template__r.Name, (SELECT Name FROM Playbook_Checklists__r) FROM Playbook_Sub_Task__c 
                                                    WHERE Playbook_Template__c = :templateId AND Playbook_Template__r.Active__c = true]){            
            if (!playbookToSubTasks.containsKey(st.Playbook_Template__r.Name)) {
                playbookToSubTasks.put(st.Playbook_Template__r.Name, new List<Playbook_Sub_Task__c>());
            }
            playbookToSubTasks.get(st.Playbook_Template__r.Name).add(st);
            masterlabelToSubTasks.put(st.Name,st);
        }
        for(Playbook__c pb : playbooks){
            if(playbookToSubTasks.containsKey(pb.Playbook_Template__c)){
                subTasks.addAll(createSubTasks(pb.Id,playbookToSubTasks.get(pb.Playbook_Template__c)));
            }
            
        }
        insert subTasks;
        for(Sub_Task__c st : subTasks){
             if(masterlabelToSubTasks.containsKey(st.Name)){
                checklists.addAll(createChecklists(st.Id,masterlabelToSubTasks.get(st.Name)));
             }
        }
        insert checklists;
    }

    /**
     * Creates sub-task records based on the provided playbook ID and sub-task metadata.
     * 
     * @param playbookId The ID of the playbook associated with the sub-tasks.
     * @param subTaskMdts The list of sub-task metadata records.
     * @return A list of created sub-task records.
     */
    private static List<Sub_Task__c> createSubTasks(Id playbookId, List<Playbook_Sub_Task__c> subTaskMdts){
        List<Sub_Task__c> subTasks = new List<Sub_Task__c>();
        for (Playbook_Sub_Task__c stmdt : subTaskMdts) {
            subTasks.add(new Sub_Task__c(Name = stmdt.Name, Playbook__c  = playbookId));
        }
        return subTasks;
    }

    /**
     * Creates task records (checklists) based on the provided sub-task ID and sub-task metadata.
     * 
     * @param subtaskId The ID of the sub-task associated with the checklists.
     * @param pbst The sub-task metadata record.
     * @return A list of created task records (checklists).
     */
    private static List<Checklist__c>  createChecklists(Id subtaskId, Playbook_Sub_Task__c pbst){
        List<Checklist__c> checklists = new List<Checklist__c> ();
        for (Playbook_Checklist__c pbc : pbst.Playbook_Checklists__r) {
            checklists.add(new Checklist__c(Name = pbc.Name, Sub_Task__c = subtaskId));
        }
        return checklists;
    }
}