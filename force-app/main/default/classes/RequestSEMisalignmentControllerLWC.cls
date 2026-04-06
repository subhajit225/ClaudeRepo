public without sharing class RequestSEMisalignmentControllerLWC {

    @AuraEnabled
    public static Opportunity getOppDetails(string recId){
        Opportunity opp = new Opportunity();
        opp = [select Id,Name,Rubrik_Sales_Engineer__c,SE_Misalignment_User__c,SE_Misalignment_Manager__c,SE_Misalignment_Requested__c,SE_Misaligned__c,
                SE_Manager_Approved__c,SE_Misalignment_Comments__c from Opportunity where Id =: recId];
        return opp;
    }

    @AuraEnabled
    public static string save(Opportunity oppRecord){
        string msg = 'Success';
        try{
            if(oppRecord.SE_Misalignment_User__c == null) {
                msg = 'Please Choose new Sales Engineer';
                return msg;
            }
    
            User seManager = [Select ManagerId from User where Id = :oppRecord.SE_Misalignment_User__c];
            if(seManager.ManagerId == null){
                msg = 'Manager not found for this User. Please get Manager updated in User record.';
                return msg;
            }
            oppRecord.SE_Misalignment_Manager__c = seManager.ManagerId;
            oppRecord.SE_Misalignment_Requested__c = true;
            oppRecord.SE_Misaligned__c = false;
            oppRecord.SE_Manager_Approved__c = false;
    
            update oppRecord;
    
            addToOpportunityTeam(seManager.ManagerId,oppRecord);
    
            submitForApproval(oppRecord);

            Approval.unlock(oppRecord.Id);

            oppRecord.SE_Misalignment_Requested__c = false;
            update oppRecord;
    		
            
         }catch(Exception e){ //SAL-956 - Added try&catch
            string errorMsg = e.getMessage();
            //if(!errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                msg = e.getMessage();
           // }
            return msg;
        }
        return msg;
    }
    public static void addToOpportunityTeam(Id managerId, Opportunity oppRecord) {
          List<OpportunityTeamMember> members = [Select Id from OpportunityTeamMember 
            where OpportunityId = :oppRecord.Id and UserId = :managerId];

        if(members.size()>0){
            return;
        }
        OpportunityTeamMember member = new OpportunityTeamMember(
            //OpportunityAccessLevel = 'Edit', 
            OpportunityId = oppRecord.Id, 
            TeamMemberRole = 'SE Manager',
            UserId = managerId);
        insert member;

        // get all of the team members' sharing records
        List<OpportunityShare> shares = [select Id, OpportunityAccessLevel, 
          RowCause from OpportunityShare where OpportunityId = :oppRecord.Id 
          and RowCause = 'Team' and UserOrGroupId =:managerId];
          
        // set all team members access to read/write
        for (OpportunityShare share : shares) 
          share.OpportunityAccessLevel = 'Edit';

        update shares;
    }

    private static void submitForApproval(Opportunity oppRecord) {
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        //SAL-1276
        req.setComments(oppRecord.SE_Misalignment_Comments__c);
        req.setObjectId(oppRecord.Id);
        req.setProcessDefinitionNameOrId(System.Label.Request_SE_Misalignment_Process_Name);
        Approval.ProcessResult result = Approval.process(req); 
    }
}