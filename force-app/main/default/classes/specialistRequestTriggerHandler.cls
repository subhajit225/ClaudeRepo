public without sharing class specialistRequestTriggerHandler extends TriggerHandler{
    
    public specialistRequestTriggerHandler(){
        
    }
        
    public override void beforeInsert(){
        Specialist_Request__c[] newSpecialistRequests = (Specialist_Request__c[])Trigger.new;
        Set<Id> opportunityIds = new Set<Id>();
        for(Specialist_Request__c sr: newSpecialistRequests){
            if(sr.Opportunity__c != null)
                opportunityIds.add(sr.Opportunity__c);
        }

        Map<Id, Id> opportunityAccountMap = new Map<Id, Id>();
        for(Opportunity opp: [Select Id, AccountId from Opportunity where Id in :opportunityIds]){
            opportunityAccountMap.put(opp.Id, opp.AccountId);
        }

        for(Specialist_Request__c sr: newSpecialistRequests) {
            if(sr.Opportunity__c != null){
                sr.Account__c = opportunityAccountMap.get(sr.Opportunity__c);
            }
        }
        
        // Call method for Approvers logic
        SpecialistRequestTriggerHelper.updateSpecialRequest(newSpecialistRequests);
    }
    
    public override void afterInsert(){
        Specialist_Request__c[] newSpecialistRequests = (Specialist_Request__c[])Trigger.new;
        setSEManager(newSpecialistRequests);
    }
   
    public override void beforeUpdate(){
        Specialist_Request__c[] newSpecialistRequests = (Specialist_Request__c[])Trigger.new;
        Map<Id, Specialist_Request__c> oldMap = (Map<Id, Specialist_Request__c>)Trigger.oldMap;
        Set<Id> opportunityIds = new Set<Id>();
        
        // For Approvers Logic
        List<Specialist_Request__c> listSpecialistRequest = new List<Specialist_Request__c>();
        
        for(Specialist_Request__c sr: newSpecialistRequests){
            Specialist_Request__c oldRequest = oldMap.get(sr.Id);
            if(sr.Opportunity__c != null && oldRequest.Opportunity__c != sr.Opportunity__c)
                opportunityIds.add(sr.Opportunity__c);
            
            if (
                    sr.RecordTypeId != oldRequest.RecordTypeId
                    || sr.Primary_Focus_Area__c != oldRequest.Primary_Focus_Area__c
                    || sr.Secondary_Focus_Area__c != oldRequest.Secondary_Focus_Area__c
            ) {
                listSpecialistRequest.add(sr);
            }
        }

        Map<Id, Id> opportunityAccountMap = new Map<Id, Id>();
        for(Opportunity opp: [Select Id, AccountId from Opportunity where Id in :opportunityIds]){
            opportunityAccountMap.put(opp.Id, opp.AccountId);
        }

        for(Specialist_Request__c sr: newSpecialistRequests) {
            Specialist_Request__c oldRequest = oldMap.get(sr.Id);
            if(sr.Opportunity__c != null && opportunityAccountMap.containsKey(sr.Opportunity__c)){
                sr.Account__c = opportunityAccountMap.get(sr.Opportunity__c);
            }
        }
        
        // Call method for Approvers logic
        if (!listSpecialistRequest.isEmpty()) {
            SpecialistRequestTriggerHelper.updateSpecialRequest(listSpecialistRequest);
        }
    }
    
    public override void afterUpdate(){
        Specialist_Request__c[] updatedSpecialistRequests = (Specialist_Request__c[])Trigger.new;
        Map<Id, Specialist_Request__c> oldMap = (Map<Id, Specialist_Request__c>)Trigger.oldMap;
        //Build new list if meets filter criteria of being accepted, has a resource assiged, and is associated to an Opp
        List<Specialist_Request__c> updatedSpecialistRequestsToProcess = new List<Specialist_Request__c>();
        List<Id> opportunityList = new List<Id>();
        
        List<Specialist_Request__c> SpecialistRequestsToProcessForOpttyChange = new List<Specialist_Request__c>();

        for(Specialist_Request__c sr : updatedSpecialistRequests){
            Specialist_Request__c oldSr = oldMap.get(sr.Id);
            if(sr.Status__c == 'Specialist Accepted' && sr.Specialist_Assigned__c != null && sr.Specialist_Assigned__c != oldSr.Specialist_Assigned__c && sr.Opportunity__c != null){
                updatedSpecialistRequestsToProcess.add(sr);
                opportunityList.add(sr.Opportunity__c);
            }
            
            if(sr.Opportunity__c != null && sr.Opportunity__c != oldSr.Opportunity__c){
                SpecialistRequestsToProcessForOpttyChange.add(sr);
            }
        }

        if(updatedSpecialistRequestsToProcess.size() > 0){
            setOpportunityTeam(updatedSpecialistRequestsToProcess, oldMap);
        }
        
        if(SpecialistRequestsToProcessForOpttyChange.size()>0) {
            setSEManager(SpecialistRequestsToProcessForOpttyChange);
        }
    }
    
    
    public override void beforeDelete(){
        
    }
    
    public override void afterDelete(){
        
    }
    
    public override void afterUndelete(){
        
    }


    public void setOpportunityTeam(List<Specialist_Request__c> specialistRequestList, Map<Id, Specialist_Request__c> oldMap) {
        List<OpportunityTeamMember> opportuntityTeamMemberInsert = new List<OpportunityTeamMember>();

        Map<Id, RecordType> specialistRequestRecordTypeMap = new Map<Id, RecordType>([Select Id, Name from RecordType where SObjectType = 'Specialist_Request__c']);

        for(Specialist_Request__c sr : specialistRequestList){
            Specialist_Request__c srOld = oldMap.get(sr.Id);
            
            String recordTypeName = specialistRequestRecordTypeMap.get(sr.RecordTypeId).Name;
            //Two different sets of logic depending on Opp Record Type
            //Need to verify TeamMemberRole values in prod, I dont have access to see on front or back end
            if(recordTypeName == 'Ranger'){
                OpportunityTeamMember otm = new OpportunityTeamMember();
                otm.UserId = sr.Specialist_Assigned__c;
                otm.OpportunityId = sr.Opportunity__c;
                otm.TeamMemberRole = 'Ranger';
                opportuntityTeamMemberInsert.add(otm);
                
            }
            else if(recordTypeName == 'FCTO'){
                OpportunityTeamMember otm = new OpportunityTeamMember();
                otm.UserId = sr.Specialist_Assigned__c;
                otm.OpportunityId = sr.Opportunity__c;
                otm.TeamMemberRole = 'FCTO';
                opportuntityTeamMemberInsert.add(otm);
            }
        }

        Insert opportuntityTeamMemberInsert;
    }
    
    public void setSEManager(List<Specialist_Request__c> specialistRequestList) {
        try{
            List<Specialist_Request__c> srToUpdate = new List<Specialist_Request__c>();
            for(Specialist_Request__c sr : specialistRequestList){
                Specialist_Request__c newSr = new Specialist_Request__c();
                newSr.SE_Manager__c = sr.SE_Manager_Id__c;
                newSr.Id = sr.Id;
                srToUpdate.add(newSr);
            }
            update srToUpdate;
        }catch(Exception e){
             if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                specialistRequestList[0].addError(e.getMessage().subStringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,').removeEnd(': []'));
            }else if(e.getMessage().contains('FIELD_FILTER_VALIDATION_EXCEPTION')) {
                specialistRequestList[0].addError(e.getMessage().subStringAfter('FIELD_FILTER_VALIDATION_EXCEPTION,').removeEnd(': ['));
            }else {
                specialistRequestList[0].addError(e.getMessage());
            }
            system.debug('@@ Exception occurred '+e.getMessage());
        }
    }
    
}