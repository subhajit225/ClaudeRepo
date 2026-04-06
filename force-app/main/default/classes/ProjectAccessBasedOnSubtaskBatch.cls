global class ProjectAccessBasedOnSubtaskBatch implements Database.Batchable<sObject>{
    
    global  Database.QueryLocator start(Database.BatchableContext BC) {
        string query = 'Select id from PS_Project__c'; 
        return Database.getQueryLocator(query);  
    }
    
    
    global  void execute(Database.BatchableContext bc,List<PS_Project__c> scope){
        
        // projects with Existing members
        map<id,set<id>> ProjectVsSetOfAssingnee = new map<id,set<id>>();
        for(PS_Project_Team_Member__c PSTeam :[Select id, PS_Project__c,Team_Member__c from PS_Project_Team_Member__c where PS_Project__c in:scope]){
            Set<id> assignIdset = new Set<id>();
            if(ProjectVsSetOfAssingnee.containsKey(PSTeam.PS_Project__c)){
                assignIdset = ProjectVsSetOfAssingnee.get(PSTeam.PS_Project__c);
                
            }
            assignIdset.add(PSTeam.Team_Member__c);
            ProjectVsSetOfAssingnee.put(PSTeam.PS_Project__c,assignIdset);
        }
        System.debug('ProjectVsSetOfAssingnee---------------'+ProjectVsSetOfAssingnee);
        
        //project with users who should have access..
        Map<id,set<id>> ProjectIdVsSetOfSubtask = new Map<id,set<id>>();
        for(PS_SubTask__c st : [Select id, PS_Assignee__c, Task__r.Project__c from PS_SubTask__c where Task__r.Project__c in :Scope AND PS_Assignee__c != null]){
            set<id> assignIdset = new Set<id>();
            if(ProjectIdVsSetOfSubtask.containsKey(st.Task__r.Project__c)){
                assignIdset = ProjectIdVsSetOfSubtask.get(st.Task__r.Project__c); 
            }
            assignIdset.add(st.PS_Assignee__c);
            ProjectIdVsSetOfSubtask.put(st.Task__r.Project__c,assignIdset);   
        }
        System.debug('ProjectIdVsSetOfSubtask---------------'+ProjectIdVsSetOfSubtask);
        
        list<PS_Project_Team_Member__c> PSProjectTeamMemberTobeInserted = new list<PS_Project_Team_Member__c>();
        //looping through map which has user who should be project members
        for(Id projId : ProjectIdVsSetOfSubtask.keyset()) {
            set<id> existingmemberId = new set<id> ();
            if(ProjectVsSetOfAssingnee.ContainsKey(projId))
                existingmemberId = ProjectVsSetOfAssingnee.get(projId);
            for(Id usrId : ProjectIdVsSetOfSubtask.get(projId)) {
                if(!existingmemberId.contains(usrId)){
                    PS_Project_Team_Member__c PsTeam = new PS_Project_Team_Member__c(
                        PS_Project__c  = projId,
                        Team_Member__c = usrId
                    );
                    PSProjectTeamMemberTobeInserted.add(PsTeam); 
                }
            }
        }    
        system.debug('PSProjectTeamMemberTobeInserted-------------'+PSProjectTeamMemberTobeInserted);
        insert PSProjectTeamMemberTobeInserted;
        
    }
    
    global  void finish(Database.BatchableContext bc){
        system.debug(' ___________ FINISH _______________________');
    }
    
}