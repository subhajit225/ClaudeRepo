public class PS_ProjectTriggerHandler {
    public static void updateCSATonSubtask(List<PS_Project__c> newprojList, Map<Id,PS_Project__c> oldProjMap){
        List<string> projIds = new List<string>();
        List<PS_SubTask__c> subTaskList = new List<PS_SubTask__c>();
        if(null == oldProjMap){
            for(PS_Project__c proj : newprojList){
                projIds.add(proj.Id);
            }
        }
        if(null != oldProjMap && !oldProjMap.isEmpty()){
            for(PS_Project__c proj : newprojList){
                if(proj.CSAT__c != oldProjMap.get(proj.Id).CSAT__c){
                    projIds.add(proj.Id);
                }
            }
        }
        if(!projIds.isEmpty()){
            for(PS_SubTask__c sub : [select Id,CSAT__c,Task__r.Project__r.CSAT__c from PS_SubTask__c where Project_ID__c IN: projIds]){
                sub.CSAT__c = sub.Task__r.Project__r.CSAT__c;
                subTaskList.add(sub);
            }
        }
        if(!subTaskList.isEmpty()){
            update subTaskList;
        }
    }
    
    /**
     * Updates the Comments_Last_Updated__c field if the Comments__c field has changed.
     *
     * @param newprojList List of new PS_Project__c records being processed.
     * @param oldProjMap Map of old PS_Project__c records (before update), keyed by Id.
     */
    public static void updateCommentDateTime(List<PS_Project__c> newprojList, Map<Id,PS_Project__c> oldProjMap){
        for (PS_Project__c proj : newprojList) {
            PS_Project__c oldProj = (oldProjMap != null) ? oldProjMap.get(proj.Id) : null;
            if (proj.Comments__c != (oldProj?.Comments__c)) {
                proj.Comments_Last_Updated__c = System.now();
            }
        }
    }

    //MKT22-378 PS Project name Change //
    public static void validatePSProjectName(List<PS_Project__c> newprojList, Map<Id,PS_Project__c> oldProjMap){
        Map<Id, List<PS_Project__c>> opptyIdToNewPSProject = new Map<Id, List<PS_Project__c>>();
        for(PS_Project__c proj : newprojList){
            if(
                oldProjMap == null
                || proj.Name != oldProjMap.get(proj.Id).Name
            ){
                if(opptyIdToNewPSProject.containsKey(proj.Opportunity__c)){
                    opptyIdToNewPSProject.get(proj.Opportunity__c).add(proj);
                }
                else {
                    opptyIdToNewPSProject.put(proj.Opportunity__c, new List<PS_Project__c>{proj});
                }
            }
        }
        Set<Id> opptyIds = opptyIdToNewPSProject.keySet();
        Map<Id, Set<String>> opptyToProjectNames = new Map<Id, Set<String>>();
        system.debug('opptyIds>>>'+opptyIds);
        for(PS_Project__c existingPSProject : [SELECT Opportunity__c, Name FROM PS_Project__c WHERE Opportunity__c IN :opptyIds]){
            if(opptyToProjectNames.containsKey(existingPSProject.Opportunity__c)){
                opptyToProjectNames.get(existingPSProject.Opportunity__c).add(existingPSProject.Name);
            }
            else {
                opptyToProjectNames.put(existingPSProject.Opportunity__c, new Set<String>{existingPSProject.Name});
            }
        }
        
        system.debug('opptyToProjectNames::'+opptyToProjectNames);
        for(Id opptyId : opptyIdToNewPSProject.keySet()){
            for(PS_Project__c proj : opptyIdToNewPSProject.get(opptyId)) {
                if(opptyToProjectNames.containsKey(opptyId) && opptyToProjectNames.get(opptyId).contains(proj.Name)) {
                    proj.addError('The name \''+ proj.Name+'\' already exists under teh same Opportunity. Please choose a different name');
                }
            }
        }
    }

    public static void updatePSProjectFlagOnAccount(List<PS_Project__c> newprojList, Map<Id,PS_Project__c> oldProjMap) { 
        Map<Id, Account> mapIdToAccountsToUpdate = new Map<Id, Account>();
        if( oldProjMap == null ) {
            for( PS_Project__c objProject : newprojList ) {
                mapIdToAccountsToUpdate.put( objProject.Account__c, new Account( Id=objProject.Account__c, PS_Projects__c = TRUE ) );
            }
        } else {
            for( PS_Project__c objProject : newprojList ) {
                if( objProject.Project_Status__c != oldProjMap.get( objProject.Id).Project_Status__c ) {mapIdToAccountsToUpdate.put( objProject.Account__c, new Account(Id=objProject.Account__c, PS_Projects__c = FALSE) );}
            }
            for( PS_Project__c objProject: [ Select Id, Account__c, Project_Status__c FROM PS_Project__c Where Account__c IN:mapIdToAccountsToUpdate.keySet() ] ) {
                if( objProject.Project_Status__c == 'Not Started' || objProject.Project_Status__c == 'Open' ) {mapIdToAccountsToUpdate.get( objProject.Account__c ).PS_Projects__c = TRUE;} 
            }
        }
        if( !mapIdToAccountsToUpdate.isEmpty() ) {
            database.update( mapIdToAccountsToUpdate.values(), FALSE ); 
        }
    }
      //MKT22-378 PS Project name Change  End//
     //MKT22-378 PS name   End//

      /**
     * @description method to create Salesforce PS Project Platform Event for Asana Sync Up.
     * @param newProjList List<PS_Project__c>
     */ 
    public static void createAsanaSFPsProjectPlatformEvent(List<PS_Project__c> newProjList){
       
        Set<Id> projectIdsToProcess = new Set<Id>();
        Integer asanaPEDelay = Integer.valueof(Label.AsanaPEDelay);
        for(PS_Project__c psp : newProjList){
            projectIdsToProcess.add(psp.Id);
        }
        
        createAsanaSFPsProjectPlatformEventJob job = new createAsanaSFPsProjectPlatformEventJob(projectIdsToProcess);
        System.enqueueJob(job,asanaPEDelay); 
        
     }
}